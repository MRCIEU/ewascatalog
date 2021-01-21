import re
from collections import OrderedDict
from catalog import query, efo

def cleanup_str(x, spaces=True):
    x = x.replace("\t"," ") ## for some reason '\s' below does not handle tabs
    if spaces:
        x = x.replace(" ", "")
    else:
        x = re.sub('^[\s]+|[\s]+$', "", x, flags=re.UNICODE)    
        x = re.sub('[\s]+', " ", x, flags=re.UNICODE)
    return x


# def retrieve_object(db, query, pthreshold):
#     """ Search database for catalog object matching query value. """    
#     ret = retrieve_location(db, query, pthreshold)
#     if isinstance(ret, catalog_object):
#         return ret
#     else:
#         return retrieve_ewas(db, query, pthreshold)

# def retrieve_location(db, query, pthreshold):
#     """ Search database for genomic location object matching query value. """
#     query = cleanup_str(query, spaces=False)
#     if query == "":
#         return ""
    
#     if cpg.matches(db, query):
#         return cpg.retrieve_object(db, query, pthreshold)
#     elif loc.matches(db, query):
#         return loc.retrieve_object(db, query, pthreshold)
#     elif region.matches(db, query):
#         return region.retrieve_object(db, query, pthreshold)
#     else:
#         return gene.retrieve_object(db, query, pthreshold)

# def retrieve_ewas(db, query, pthreshold):
#     """ Search database for EWAS catalog object matching query value. """
#     query = cleanup_str(query, spaces=False)
#     if query == "":
#         return ""

#     if efo_term.matches(db, query):
#         return efo_term.retrieve_object(db, query, pthreshold)
#     elif study.matches(db, query):
#         return study.retrieve_object(db, query, pthreshold)
#     else:
#         ret = trait.retrieve_object(db, query, pthreshold)
#         if isinstance(ret, catalog_object):
#             return ret
#     return author.retrieve_object(db, query, pthreshold) 

def has_suggestions(x):
    return sum([len(x[k]) for k in x.keys()]) > 0

def retrieve_suggestions(db, query, pthreshold):
    """ Search database for catalog objects linked to query value. """
    ret = retrieve_location_suggestions(db, query, pthreshold)
    if has_suggestions(ret):
        return ret
    return retrieve_ewas_suggestions(db, query, pthreshold)

def retrieve_location_suggestions(db, query, pthreshold):
    """ Search database for genomic location objects linked to query value. """
    query = cleanup_str(query, spaces=False)
    if query != "":
        if cpg.matches(db, query):
            return cpg.retrieve_suggestions(db, query, pthreshold)
        elif loc.matches(db, query):
            return loc.retrieve_suggestions(db, query, pthreshold)
        elif region.matches(db, query):
            return region.retrieve_suggestions(db, query, pthreshold)
        elif gene.matches(db, query):
            return gene.retrieve_suggestions(db, query, pthreshold)    
    return OrderedDict()

def retrieve_ewas_suggestions(db, query, pthreshold):
    """ Search database for EWAS catalog objects linked to query value. """
    query = cleanup_str(query, spaces=False)
    if query != "":    
        if efo_term.matches(db, query):
            return efo_term.retrieve_suggestions(db, query, pthreshold)
        elif study.matches(db, query):
            return study.retrieve_suggestions(db, query, pthreshold)
        else:
            ret = trait.retrieve_suggestions(db, query, pthreshold)
            if has_suggestions(ret):
                return ret
            return author.retrieve_suggestions(db, query, pthreshold)
    return OrderedDict()

class catalog_object:
    """ Abstract EWAS catalog object
    
    An EWAS catalog object consists of a category 
    (CpG, genomic location, gene, genomic region, 
    study, EFO or trait)
    and corresponding value submitted by the user
    (CpG identifier, genomic coordinates, gene name, 
    PMID, EFO identifier, or trait name).
    
    Attributes:
    db: Database connection object.
    category: Object category (see above).
    value: Object value (see above).
    """ 
    def __init__(self, category, value, assocs=0):
        self.category = category
        self.value = value
        self.number_assocs = int(assocs)
        self.detail_list = OrderedDict()
    def extract_value(text):
        """ Clean up text to obtain value for this object type by for example removing white space """
        return cleanup_str(text.lower())
    def matches(db, text):
        """ Determine whether text specifies this particular catalog object. """
        return True
    def retrieve_where(value):
        """ SQL for limiting database query to this particular catalog object. """ 
        return ""
    def retrieve_object(db, value, pthreshold):
        """ Retrieve an instance of this object matching the 'value' """
        return ""
    def retrieve_matching(db, where, pthreshold, sig=False):
        """ Retrieve instances of this object that satisfy SQL query condition 'where' (catalog_object).
            If sig is true, then links should involve associations the pass the p-value threshold. """
        return []
    def retrieve_suggestions(db, value, pthreshold):
        """ Retrieve catalog objects related to the object specified by 'value' """
        return OrderedDict()
    def url(self):
        """ URL for submitting a query about this catalog object. """
        return "/?"+self.category+"="+self.value
    def add_detail(self, name, value):
        self.detail_list[name] = value
    def details(self):
        """ Dictionary providing details about this catalog object. """
        return self.detail_list
    def assocs(self):
        """ The number of CpG site associations. """
        return self.number_assocs
    def where(self):
        return ""

class cpg(catalog_object):
    def __init__(self, name, location, gene, region, assocs):
        super().__init__("cpg", name, assocs)
        self.value = cpg.extract_value(name)
        self.add_detail("location", location)
        self.add_detail("gene", gene)
        self.add_detail("region", region)
    def extract_value(text):
        return catalog_object.extract_value(text)
    def matches(db, text):
        text = cpg.extract_value(text)
        return re.match("^cg[0-9]+$", text) or re.match("^ch[0-9]+$", text) 
    def retrieve_where(value):
        return "cpgs.cpg='"+cpg.extract_value(value)+"'"
    def retrieve_object(db, value, pthreshold):
        ret = cpg.retrieve_matching(db, cpg.retrieve_where(value), pthreshold)
        if len(ret) > 0:
            return ret[0]
        else:
            return ""
    def retrieve_matching(db, where, pthreshold, sig=False):
        ret = query.response(db,
                             "SELECT cpg, chrpos, gene, type, ifnull(assocs,0) as assocs "
                             + "FROM cpgs WHERE "+where)
        return [cpg(ret.element("cpg", i),
                    ret.element("chrpos", i),
                    ret.element("gene", i),
                    ret.element("type", i),
                    ret.element("assocs", i))
                for i in range(ret.nrow())]                                 
    def retrieve_suggestions(db, value, pthreshold):
        suggestions = OrderedDict()
        where = cpg.retrieve_where(value)
        suggestions['cpg'] = cpg.retrieve_matching(db, where, pthreshold)
        suggestions['genes'] = gene.retrieve_matching(db, where, pthreshold)
        suggestions['studies'] = study.retrieve_matching(db, where, pthreshold, sig=True)
        return suggestions
    def where(self):
        return cpg.retrieve_where(self.value)
        

class loc(catalog_object):
    def __init__(self, name, cpg, gene, region, assocs):
        super().__init__("loc", name, assocs)
        self.loc = loc.extract_value(name)
        self.add_detail("cpg", cpg)
        self.add_detail("gene", gene)
        self.add_detail("region", region)
    def extract_value(text):
        return cleanup_str(text.lower().replace("chr", ""))
    def matches(db, text):
        text = loc.extract_value(text)
        return re.match("^(chr|)[0-9]+:[0-9]+$", text) 
    def retrieve_where(value):
        return "cpgs.chrpos='chr" + loc.extract_value(value) + "'"
    def retrieve_object(db, value, pthreshold):
        ret = loc.retrieve_matching(db, loc.retrieve_where(value), pthreshold)
        if len(ret) > 0:
            return ret[0]
        else:
            return ""
    def retrieve_matching(db, where, pthreshold, sig=False):
        ret = query.response(db,
                             "SELECT cpg, chrpos, gene, type, ifnull(assocs,0) as assocs "
                             + "FROM cpgs WHERE "+where)
        return [loc(ret.element("chrpos", i),
                    ret.element("cpg", i),
                    ret.element("gene", i),
                    ret.element("type", i),
                    ret.element("assocs", i))
                for i in range(ret.nrow())]                                 
    def retrieve_suggestions(db, value, pthreshold):
        suggestions = OrderedDict()
        where = loc.retrieve_where(value)
        suggestions['location'] = loc.retrieve_matching(db, where, pthreshold)
        suggestions['cpgs'] = cpg.retrieve_matching(db, where, pthreshold)
        suggestions['genes'] = gene.retrieve_matching(db, where, pthreshold)
        suggestions['studies'] = study.retrieve_matching(db, where, pthreshold, sig=True)
        return suggestions
    def where(self):
        return loc.retrieve_where(self.value)

class gene(catalog_object):
    def __init__(self, name, chr, start, end, sites, assocs):
        super().__init__("gene", name, assocs)
        self.value = gene.extract_value(name)
        self.add_detail("location", chr+":"+str(start)+"-"+str(end))
        self.add_detail("sites", str(sites))
    def extract_value(text):
        return cleanup_str(text.upper())
    def matches(db, text):
        text = gene.extract_value(text)
        if not re.match("[A-Z0-9-]+", text):
            return False
        ret = query.response(db, "SELECT gene FROM genes WHERE gene='"+text+"'")
        return ret.nrow() > 0
    def retrieve_where(value):
        return "cpgs.gene='"+gene.extract_value(value)+"'"
    def retrieve_object(db, value, pthreshold):
        ret = gene.retrieve_matching(db, gene.retrieve_where(value), pthreshold)
        if len(ret) > 0:
            return ret[0]
        else:
            return ""
    def retrieve_matching(db, where, pthreshold, sig=False):
        ret = query.response(db,
                             "SELECT DISTINCT genes.gene as gene, "
                             + "genes.chr as chr, "
                             + "start, end, sites, "
                             + "ifnull(genes.assocs,0) as assocs "
                             + "FROM genes "
                             + "JOIN cpgs ON cpgs.gene = genes.gene "
                             + "WHERE "+where)
        return [gene(ret.element("gene", i),
                    ret.element("chr", i),
                    ret.element("start", i),
                    ret.element("end", i),
                    ret.element("sites", i),
                    ret.element("assocs", i))
                for i in range(ret.nrow())]        
    def retrieve_suggestions(db, value, pthreshold):
        ret = OrderedDict()
        where = gene.retrieve_where(value)
        ret['gene'] = gene.retrieve_matching(db, where, pthreshold)
        ret['cpgs'] = cpg.retrieve_matching(db, where, pthreshold)
        ret['studies'] = cpg.retrieve_matching(db, where, pthreshold, sig=True)
        return ret
    def where(self):
        return gene.retrieve_where(self.value)

class region(catalog_object):
    def __init__(self, name, genes, sites, assocs):
        super().__init__("region", name, assocs)
        self.value = region.extract_value(name)
        self.add_detail("genes", genes)
        self.add_detail("CpG sites", str(sites))
    def extract_value(text):
        return cleanup_str(text.replace("chr", "").lower())
    def matches(db, text):
        text = region.extract_value(text)
        return re.match("^(chr|)[0-9]+:[0-9]+-[0-9]+$", text)
    def retrieve_where(text):
        text = region.extract_value(text)
        text = re.split(':|-',text)
        return ("cpgs.chr='"+text[0]+"' "
                "AND cpgs.pos>="+text[1]+" "
                "AND cpgs.pos<="+text[2])
    def retrieve_object(db, value, pthreshold):
        where = region.retrieve_where(value)
        ret = query.singleton_response(db, "SELECT COUNT(DISTINCT gene) FROM cpgs WHERE " + where)
        genes = ret.value()
        ret = query.singleton_response(db, "SELECT COUNT(DISTINCT cpg) FROM cpgs WHERE " + where)
        sites = ret.value()
        ret = query.singleton_response(db,
                                       "SELECT COUNT(DISTINCT results.cpg,study_id) "
                                       + "FROM results "
                                       + "JOIN cpgs ON cpgs.cpg = results.cpg "
                                       + "WHERE " + where + " AND p < " + str(pthreshold))
        assocs = ret.value()
        return region(value, genes, sites, assocs)
    def retrieve_suggestions(db, value, pthreshold):
        where = region.retrieve_where(value)
        suggestions = OrderedDict()
        suggestions['region'] = [region.retrieve_object(db, value, pthreshold)]
        suggestions['genes'] = gene.retrieve_matching(db, where, pthreshold)
        suggestions['studies'] = study.retrieve_matching(db, where, pthreshold, sig=True)
        return suggestions
    def where(self):
        return region.retrieve_where(self.value)

class efo_term(catalog_object):
    def __init__(self, name, pubs, assocs):
        super().__init__("efo", name, assocs)
        self.value = efo_term.extract_value(name)
        self.add_detail("label", efo.label(self.value))
        self.add_detail("publications", str(pubs))
    def extract_value(text):
        return cleanup_str(text.upper())
    def matches(db, text):
        text = efo_term.extract_value(text)
        return re.match("^EFO_[0-9]+$", text)
    def retrieve_where(value):
        value = efo_term.extract_value(value)
        return "studies.efo LIKE '%"+value+"%'"
    def retrieve_object(db, value, pthreshold):
        value = efo_term.extract_value(value)
        ret = query.response(db, "SELECT efo, pubs, ifnull(assocs,0) as assocs FROM efo_terms where efo='"+value+"'")
        if ret.nrow() > 0:
            return efo_term(ret.element("efo",0), ret.element("pubs",0), ret.element("assocs",0))
        else:
            return ""
    def retrieve_matching(db, where, pthreshold, sig=False):
        ret = query.response(db,
                             "SELECT DISTINCT efo_terms.efo as efo, "
                             + "efo_terms.pubs as pubs, "
                             + "ifnull(efo_terms.assocs,0) as assocs "
                             + "FROM efo_terms "
                             + "JOIN study_efo ON efo_terms.efo = study_efo.efo "
                             + "JOIN studies ON study_efo.study_id = studies.study_id "
                             + "WHERE " + where)
        return [efo_term(ret.element("efo", i),
                         ret.element("pubs", i),
                         ret.element("assocs", i))
                for i in range(ret.nrow())]
    def retrieve_suggestions(db, value, pthreshold):
        where = efo_term.retrieve_where(value)
        suggestions = OrderedDict()
        suggestions['efo'] = [efo_term.retrieve_object(db, value, pthreshold)]
        suggestions['studies'] = study.retrieve_matching(db, where, pthreshold)
        return suggestions
    def where(self):
        return efo_term.retrieve_where(self.value)

class study(catalog_object):
    def __init__(self, name, author, pmid, trait, tissue, array, n, assocs):
        super().__init__("study", name, assocs)
        self.value = study.extract_value(name)
        self.add_detail('author', author)
        self.add_detail('PMID', pmid)
        self.add_detail('trait', trait)
        self.add_detail('tissue', tissue)
        self.add_detail('array', array)
        self.add_detail('n', n)
    def extract_value(text):
        return catalog_object.extract_value(text)
    def matches(db, text):
        text = study.extract_value(text)
        return re.match("^[0-9]+(_.+|)$", text) 
    def retrieve_where(value):
        value = study.extract_value(value)
        return "studies.pmid='"+value+"' OR studies.study_id='"+value+"'"
    def retrieve_object(db, value, pthreshold):
        ret = study.retrieve_matching(db, study.retrieve_where(value), pthreshold)
        if len(ret) > 0:
            return ret[0]
        else:
            return ""
    def retrieve_matching(db, where, pthreshold, sig=False):
        if not sig:
            ret = query.response(db, "SELECT study_id, n, pmid, author, trait, tissue, array, "
                                 + "ifnull(assocs,0) as assocs "
                                 + "FROM studies WHERE " + where)
        else:
            ret = query.response(db,
                                 "SELECT DISTINCT "
                                 + "studies.study_id as study_id, "
                                 + "n, pmid, author, trait, tissue, array, "
                                 + "ifnull(studies.assocs,0) as assocs "
                                 + "FROM studies "
                                 + "JOIN results ON studies.study_id=results.study_id "
                                 + "JOIN cpgs ON cpgs.cpg=results.cpg "
                                 + "WHERE " + where + " AND p < " + str(pthreshold))
        return [study(ret.element("study_id", i),
                      ret.element("author", i),
                      ret.element("pmid", i),
                      ret.element("trait", i),
                      ret.element("tissue", i),
                      ret.element("array", i),
                      ret.element("n", i),
                      ret.element("assocs", i))
                for i in range(ret.nrow())]
    def retrieve_suggestions(db, value, pthreshold):
        where = study.retrieve_where(value)
        suggestions = OrderedDict()
        suggestions['study'] = study.retrieve_matching(db, where, pthreshold)
        suggestions['EFO terms'] = efo_term.retrieve_matching(db, where, pthreshold)
        return suggestions
    def where(self):
        return study.retrieve_where(self.value)

class trait(catalog_object):
    def __init__(self, name, pubs, efo_terms, assocs):
        super().__init__("trait", name, assocs)
        self.value = trait.extract_value(name)
        self.add_detail('publications', str(pubs))
        #self.add_detail('EFO term(s)', ", ".join(efo_terms))
    def extract_value(text):
        return cleanup_str(text.lower(), spaces=False)
    def matches(db, text):
        return True
    def retrieve_where(value):
        value = trait.extract_value(value)
        return "studies.trait LIKE '%"+value+"%'"
    def retrieve_traits(db, value, pthreshold):
        value = trait.extract_value(value)
        efo_terms = list(efo.lookup(value).keys())
        where = trait.retrieve_where(value)
        if len(efo_terms) > 0:
            where += " OR (efo LIKE '%"+ "%' OR efo LIKE '%".join(efo_terms) + "%') "
        ret = query.response(db, "SELECT DISTINCT traits.trait as trait, "
                             #+ "studies.efo as efo, "
                             + "traits.pubs as pubs, ifnull(traits.assocs,0) as assocs "
                             + "FROM traits JOIN studies ON traits.trait = studies.trait "
                             + "WHERE " + where)
        ret = [trait(ret.element("trait", i),
                     ret.element("pubs", i),
                     [],#re.split(r'\W+', ret.element("efo", i)),
                     ret.element("assocs", i))
               for i in range(ret.nrow())]
        ## sort matches by how closely they match the query value
        ret.sort(key=lambda x: -float(value in x.value) - float(len(value))/len(x.value)) 
        return ret
    def retrieve_object(db, value, pthreshold):
        efo_terms = list(efo.lookup(value).keys())
        ret = query.response(db, "SELECT DISTINCT trait, pubs, "
                             + "ifnull(traits.assocs,0) as assocs "
                             + "FROM traits "
                             + "WHERE trait='"+value+"'")
        if ret.nrow() > 0:
            return trait(ret.element("trait",0), ret.element("pubs",0), efo_terms, ret.element("assocs",0))
        else:
            return ""
    def retrieve_suggestions(db, value, pthreshold):
        where = trait.retrieve_where(value)
        suggestions = OrderedDict()
        suggestions['trait'] = trait.retrieve_traits(db, value, pthreshold)
        suggestions['EFO terms'] = efo_term.retrieve_matching(db, where, pthreshold)
        suggestions['studies'] = study.retrieve_matching(db, where, pthreshold)
        return suggestions
    def where(self):
        return "studies.trait='"+self.value+"'"
    

class author(catalog_object):
    def __init__(self, name, pubs, assocs):
        super().__init__("author", name, assocs)        
        self.value = author.extract_value(name)
        self.add_detail('publications', str(pubs))
    def extract_value(text):
        return cleanup_str(text.lower(),spaces=False)
    def matches(db, text):
        return re.match("^[a-z ]+$", author.extract_value(text))
    def retrieve_where(value):
        value = author.extract_value(value)
        return "studies.author LIKE '%"+value+"%'"
    def retrieve_object(db, value, pthreshold):
        ret = author.retrieve_matching(db, author.retrieve_where(value), pthreshold)
        if len(ret) > 0:
            return ret[0]
        else:
            return ""
    def retrieve_matching(db, where, pvaluethreshold, sig=False):
        ret = query.response(db,
                             "SELECT DISTINCT authors.author as author, "
                             + "authors.pubs as pubs, "
                             + "ifnull(authors.assocs,0) as assocs "         
                             + "FROM authors "
                             + "JOIN studies ON authors.author = studies.author "
                             + "WHERE " + where)
        return [author(ret.element("author",i),
                       ret.element("pubs",i),
                       ret.element("assocs",i))
                for i in range(ret.nrow())]
    def retrieve_suggestions(db, value, pthreshold):
        where = author.retrieve_where(value)
        suggestions = OrderedDict()
        suggestions['author'] = author.retrieve_matching(db, where, pthreshold)
        suggestions['studies'] = study.retrieve_matching(db, where, pthreshold)
        return suggestions
    def where(self):
        return author.retrieve_where(self.value)

    
class complex(catalog_object):
    def __init__(self, db, loc_text, ewas_text):
        super().__init__("complex",
                         loc_text + " and " + ewas_text)
        ## obtain SQL conditions for the location search (cpg, location, region or gene)
        if cpg.matches(db, loc_text):
            self.loc_where =  cpg.retrieve_where(loc_text)
        elif loc.matches(db, loc_text):
            self.loc_where = loc.retrieve_where(loc_text)
        elif region.matches(db, loc_text):
            self.loc_where = region.retrieve_where(loc_text)
        else:
            self.loc_where = gene.retrieve_where(loc_text)
        ## obtain SQL conditions for the ewas search (efo, study, trait or author)
        if (efo_term.matches(db, ewas_text)):
            self.ewas_where = efo_term.retrieve_where(ewas_text)
        elif (study.matches(db, ewas_text)):
            self.ewas_where = study.retrieve_where(ewas_text)
        else:
            self.ewas_where = ("(" + trait.retrieve_where(ewas_text) + ")"
                               + " OR "
                               + "(" + author.retrieve_where(ewas_text) + ")")
        ## combine both together unless one is invalid
        if cleanup_str(loc_text) != "":
            if cleanup_str(ewas_text) != "":
                self.both_where = "("+self.loc_where + ") AND (" + self.ewas_where +")"
            else:
                self.both_where = self.loc_where
        elif cleanup_str(ewas_text):
            self.both_where = self.ewas_where
        else:
            self.both_where = "(1=2)"
    def where(self):
        return self.both_where
    def url(self):
        return "complex-error"
    def extract_value(text):
        return "complex-error"
    def matches(db, text):
        return False
    def retrieve_where(value):
        return "complex-error"
    def retrieve_object(db, value, pthreshold):
        return "complex-error"
    def retrieve_matching(db, where, pthreshold):
        return []
    def retrieve_suggestions(db, value, pthreshold):
        return OrderedDict()

