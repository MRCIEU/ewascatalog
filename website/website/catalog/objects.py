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

def retrieve_location(db, query, pvalue_threshold):
    """ Search database for genomic location object matching query value. """
    if cpg.matches(db, query):
        return cpg(db, query, pvalue_threshold)
    elif loc.matches(db, query):
        return loc(db, query, pvalue_threshold)
    elif region.matches(db, query):
        return region(db, query, pvalue_threshold)
    elif gene.matches(db, query):
        return gene(db, query, pvalue_threshold)
    else:
        return ""

def retrieve_studies(db, query, pvalue_threshold):
    """ Search database for EWAS catalog object matching query value. """
    if efo_term.matches(db, query):
        return efo_term(db, query, pvalue_threshold)
    elif study.matches(db, query):
        return study(db, query, pvalue_threshold)
    else:
        obj = trait(db, query, pvalue_threshold)
        if len(obj.studies()) > 0:
            return obj
        obj = author(db, query, pvalue_threshold)
        if len(obj.studies()) > 0:
            return obj
    return ""

def retrieve(db, query, pvalue_threshold):
    """ Search database for catalog object matching query value. """
    obj = retrieve_location(db, query, pvalue_threshold)
    if isinstance(obj,catalog_object):
        return obj
    else:
        return retrieve_studies(db, query, pvalue_threshold)

def assocs_sql(variable, where):
    """ Query template for counting the numbers of CpG site associations. """
    where = where.replace("study_id", "results.study_id")
    variable = variable.replace("study_id", "results.study_id")
    return ("SELECT COUNT(DISTINCT "+variable+") "
            "FROM studies JOIN results "
            "ON studies.study_id=results.study_id "
            "WHERE "+where)
    
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
    def __init__(self, db, category, value, pvalue_threshold):
        self.db = db
        self.category = category
        self.value = value
        self.pvalue_threshold = pvalue_threshold
    def advanced_query_url(self):
        """ URL for submitting a query about this catalog object. """
        return "/?"+self.category+"="+self.value
    def basic_query_url(self):
        """ URL for submitting a query about this catalog object. """
        return "/?query="+self.value
    def title(self):
        """ Catalog object name/value/title. """
        return self.value
    def matches(db, text):
        """ Determine whether text specifies this particular catalog object. """
        return True
    def where_sql(self):
        """ SQL for limiting database query to this particular catalog object. """ 
        return ""
    def suggestions(self):
        """ List of catalog objects linked to this catalog object (including itself). """
        return []
    def details(self):
        """ Dictionary providing details about this catalog object. """
        details = OrderedDict()
        return details
    def assocs(self):
        """ The number of CpG site associations. """
        sql = "("+self.where_sql()+") AND p < "+str(self.pvalue_threshold)
        ret = query.singleton_response(self.db, assocs_sql("cpg,study_id", sql))
        return int(ret.value())        


class cached_catalog_object(catalog_object):
    """ Catalog object with saved function outputs.

    Accessor functions return results of database queries.  
    This object executes all such functions and saves the outputs
    as object attributes so they can be used by Django to 
    populate web pages. 
    The only exception is the 'suggestions()' function 
    to avoid infinite recursion!
    """ 
    def __init__(self, obj):
        super().__init__(obj.db, obj.category, obj.value, obj.pvalue_threshold)
        self.cached_advanced_query_url = obj.advanced_query_url()
        self.cached_basic_query_url = obj.basic_query_url()
        self.cached_details = obj.details()
        self.cached_assocs = obj.assocs()
        self.cached_title = obj.title()
        self.cached_sql = obj.where_sql()
    def advanced_query_url(self):
        return self.cached_advanced_query_url
    def basic_query_url(self):
        return self.cached_basic_query_url
    def title(self):
        return self.cached_title
    def matches(db, text):
        return True
    def where_sql(self):
        return self.cached_sql
    def assocs(self):
        return self.cached_assocs
    def suggestions(self):
        return []
    def details(self):
        return self.cached_details

    
class genomic_location(catalog_object):
    def __init__(self, db, category, value, pvalue_threshold):
        super().__init__(db, category, value, pvalue_threshold)
    def cpgs(self):
        cpgs = query.response(self.db, "SELECT DISTINCT cpg FROM cpgs WHERE "+self.where_sql())
        if cpgs.nrow() == 0:
            return []
        return cpgs.col("cpg")
    def genes(self):
        genes = query.response(self.db, "SELECT DISTINCT gene FROM cpgs WHERE "+self.where_sql())
        if genes.nrow() == 0:
            return []
        genes = genes.col("gene")
        for i in range(len(genes)):
            if genes[i] != "-":
                genes[i] = list(set(genes[i].split(";")))
            else:
                genes[i] = []
        genes = set(sum(genes, []))
        return genes
    def studies(self):
        studies = query.response(self.db,
                                 "SELECT study_id FROM results WHERE "
                                 +self.where_sql()
                                 +" AND p <"+str(self.pvalue_threshold))
        studies = list(set(studies.col("study_id")))
        return studies
    
class cpg(genomic_location):
    def __init__(self, db, cpg, pvalue_threshold):
        super().__init__(db, "cpg", cleanup_str(cpg.lower()), pvalue_threshold)
    def matches(db, text):
        text = cleanup_str(text.lower())
        return re.match("^cg[0-9]+$", text) or re.match("^ch[0-9]+$", text)
    def where_sql(self):
        return "cpg='"+self.title()+"'"
    def suggestions(self):
        """ Suggest querying the CpG site or linked genes. """
        ret = OrderedDict()
        ret['cpg'] = [self]
        ret['genes'] = [gene(self.db, name, self.pvalue_threshold) for name in self.genes()]
        ret['studies'] = [study(self.db, study_id, self.pvalue_threshold) for study_id in self.studies()]
        return ret
    def details(self):
        """ Provide CpG site, a linked gene and genic region of the site. """
        details = super().details()
        ret = query.response(self.db, "SELECT chrpos as location, type as region, gene FROM cpgs WHERE " +self.where_sql())
        if ret.nrow() > 0:
            details['location'] = ret.row(0)[0]
            details['gene'] = ret.row(0)[2]
            details['region'] = ret.row(0)[1]
        return details

class loc(genomic_location):
    def __init__(self, db, loc, pvalue_threshold):
        super().__init__(db, "loc", cleanup_str(loc.lower().replace("chr", "")), pvalue_threshold)
        loc = re.split(":|-",self.title())
        self.chr = loc[0]
        self.pos = loc[1]
    def matches(db, text):
        text = cleanup_str(text.lower())
        return re.match("^(chr|)[0-9]+:[0-9]+$", text) 
    def where_sql(self):
        return "chrpos='chr"+self.title()+"'"
    def suggestions(self):
        """ Suggest querying overlapping CpG sites and genes. """
        ret = OrderedDict()
        ret['location'] = [self]
        ret['cpgs'] = [cpg(self.db, name, self.pvalue_threshold) for name in self.cpgs()]
        ret['genes'] = [gene(self.db, name, self.pvalue_threshold) for name in self.genes()]
        ret['studies'] = [study(self.db, study_id, self.pvalue_threshold) for study_id in self.studies()]
        return ret
    def details(self):
        """ Provide location CpG site identifier, linked gene and genic region. """
        details = super().details()
        ret = query.response(self.db, "SELECT cpg, type as region, gene FROM cpgs WHERE " + self.where_sql())
        if ret.nrow() > 0:
            details['identifier'] = ret.row(0)[0]
            details['gene'] = ret.row(0)[1]
            details['region'] = ret.row(0)[2]
        return details
    
class gene(genomic_location):
    def __init__(self, db, gene, pvalue_threshold):
        super().__init__(db, "gene", cleanup_str(gene.upper()), pvalue_threshold)
    def matches(db, text):
        """ Return true if the text matches a gene name in the database. """
        text = cleanup_str(text.upper())
        if not re.match("[A-Z0-9-]+", text):
            return False
        ret = query.response(db, "SELECT gene FROM genes WHERE gene='"+text+"'")
        return ret.nrow() > 0
    def where_sql(self):
        return "gene='"+self.title()+"'"
    def suggestions(self):
        """ Suggest querying the gene itself and CpG sites linked with the gene. """
        ret = OrderedDict()
        ret['gene'] = [self]
        ret['cpgs'] = [cpg(self.db, name, self.pvalue_threshold) for name in self.cpgs()]
        ret['studies'] = [study(self.db, study_id, self.pvalue_threshold) for study_id in self.studies()]
        return ret
    def details(self):
        """ Provide gene coordinates and number of CpG sites linked to the gene. """
        details = super().details()
        ret = query.response(self.db, "SELECT chr,start,end FROM genes WHERE " + self.where_sql())
        if ret.nrow() > 0: 
            coords = ret.row(0)
            details['location'] = coords[0] + ":" + str(coords[1]) + "-" + str(coords[2])
        #ret = query.singleton_response(self.db, "SELECT COUNT(DISTINCT cpg) FROM cpgs WHERE "+self.where_sql())
        ## the line above is correct but very slow so we created a table to store number of CpG sites per gene
        ret = query.singleton_response(self.db, "SELECT nsites FROM gene_details WHERE " + self.where_sql())
        details['CpG sites'] = ret.value()
        return details

class region(genomic_location):
    def __init__(self, db, region, pvalue_threshold):
        super().__init__(db, "region", cleanup_str(region.replace("chr", "").lower()), pvalue_threshold)
        region = re.split(':|-',region)
        self.chr = region[0].replace("chr","")
        self.start = region[1]
        self.end = region[2]
    def matches(db, text):
        text = cleanup_str(text.lower())
        return re.match("^(chr|)[0-9]+:[0-9]+-[0-9]+$", text)
    def where_sql(self):
        return ("chr='"+self.chr+"' "
                "AND pos>="+self.start+" "
                "AND pos<="+self.end)
    def suggestions(self):
        """ Suggest querying the region and genes linked to any CpG site in the region. """
        ret = OrderedDict()
        ret['region'] = [self]
        ret['genes'] = [gene(self.db, name, self.pvalue_threshold) for name in self.genes()]
        ## the following line can very time consuming for a regional query
        #ret['studies'] = [study(self.db, study_id, self.pvalue_threshold) for study_id in self.studies()]
        return ret
    def details(self):
        """ Provide the number of CpG sites inside the region. """
        details = super().details()
        ret = query.singleton_response(self.db, "SELECT COUNT(DISTINCT gene) FROM cpgs WHERE " + self.where_sql())
        details['genes'] = ret.value()
        ret = query.singleton_response(self.db, "SELECT COUNT(DISTINCT cpg) FROM cpgs WHERE "+self.where_sql())
        details['CpG sites'] = ret.value()
        return details

class study_description(catalog_object):
    def __init__(self, db, category, value, pvalue_threshold):
        super().__init__(db, category, value, pvalue_threshold)
    def efo_terms(self):
        ret = query.response(self.db, "SELECT DISTINCT efo FROM studies WHERE " + self.where_sql())
        ret = ret.col("efo")
        ret = [value.replace(" ", "").split(",") for value in ret]
        ret = sum(ret, [])
        return set(ret)
    def studies(self):
        ret = query.response(self.db, "SELECT DISTINCT study_id FROM studies WHERE " + self.where_sql())
        return ret.col("study_id")
        
class efo_term(study_description):
    def __init__(self, db, efo, pvalue_threshold):
        super().__init__(db, "efo", cleanup_str(efo.upper()), pvalue_threshold)
    def matches(db, text):
        text = cleanup_str(text.upper())
        return re.match("^EFO_[0-9]+$", text)
    def where_sql(self):
        return "efo LIKE '%"+self.title()+"%'"
    def suggestions(self):
        """ Suggest EWAS assigned this EFO term and any EFO term assigned to the same EWAS. """
        ret = OrderedDict()
        ret['efo'] = [self]
        ret['studies'] = [study(self.db, study_id, self.pvalue_threshold) for study_id in self.studies()]
        return ret
    def details(self):
        """ Provide the label for this EFO term. """
        details = super().details()
        label = efo.label(self.title())
        if label != "":
            details['label'] = label
        ret = query.singleton_response(self.db, "SELECT COUNT(DISTINCT pmid) FROM studies WHERE " + self.where_sql())
        details['publications'] = ret.value()
        return details

class study(study_description):
    def __init__(self, db, study, pvalue_threshold):
        super().__init__(db, "study", cleanup_str(study.lower()), pvalue_threshold)
    def matches(db, text):
        text = cleanup_str(text.lower())
        return re.match("^[0-9]+(_.+|)$", text) 
    def where_sql(self):
        """ Match any EWAS whose PMID or study id matches the input text. """
        return "pmid='"+self.title()+"' OR study_id='"+self.title()+"'"
    def suggestions(self):
        """ Suggest querying this EWAS or any EFO term linked to this EWAS. """
        ret = OrderedDict()
        ret['study'] = [self]
        ret['EFO terms'] = [efo_term(self.db, term, self.pvalue_threshold) for term in self.efo_terms()]
        return ret
    def details(self):
        """ Provide the PMID, authors and number of samples for this EWAS. """
        details = super().details()
        ret = query.response(self.db, "SELECT n, pmid, author, trait, tissue, array FROM studies WHERE " + self.where_sql())
        if ret.nrow() > 0:
            details['author'] = ret.col("author")[0]
            details['PMID'] = ret.col("pmid")[0]
            details['trait'] = ret.col("trait")[0]
            details['tissue'] = ret.col("tissue")[0]
            details['array'] = ret.col("array")[0]
            n = ret.col("n")
            if ret.nrow() > 1:
                n = [int(v) for v in n]
                if min(n) < max(n):
                    n = str(min(n)) + ".." + str(max(n))
                else:
                    n = n[0]
            else:
                n = n[0]
            details['n'] = str(n)
        return details

class trait(study_description):
    def __init__(self, db, trait, pvalue_threshold):
        super().__init__(db, "trait", cleanup_str(trait.lower(), spaces=False), pvalue_threshold)
        self.efo_term_list = list(efo.lookup(self.title()).keys()) ## lookup EFO terms for this text
    def efo_terms(self):
        return self.efo_term_list
    def matches(db, text):
        return True
    def where_sql(self):
        """ Match any trait containing the supplied text and any associated EFO term. """
        ret = "trait LIKE '%"+self.title()+"%'"
        if len(self.efo_terms()) > 0:
            ret = (ret + "OR (efo LIKE '%"+ "%' OR efo LIKE '%".join(self.efo_terms()) + "%') ")
        return ret
    def suggestions(self):
        """ Suggest querying any EWAS with a matching trait or EFO term. """
        ret = OrderedDict()
        ret['trait'] = [self]
        ret['EFO terms'] = [efo_term(self.db, term, self.pvalue_threshold) for term in self.efo_terms()]
        ret['studies'] = [study(self.db, study_id, self.pvalue_threshold) for study_id in self.studies()]
        return ret
    def details(self):
        """ Provide matching EFO terms. """ 
        details = super().details()
        ret = query.singleton_response(self.db, "SELECT COUNT(DISTINCT pmid) FROM studies WHERE " + self.where_sql())
        details['publications'] = ret.value()
        if len(self.efo_terms()) > 0:
            details['term(s)'] = ", ".join(self.efo_terms())
        return details

class author(study_description):
    def __init__(self, db, author, pvalue_threshold):
        super().__init__(db, "author", cleanup_str(author.lower(),spaces=False), pvalue_threshold)
    def matches(db, text):
        return re.match("^[a-z ]+$", cleanup_str(text.lower(), spaces=False)) 
    def where_sql(self):
        return "author LIKE '%"+self.title()+"%'"
    def suggestions(self):
        ret = OrderedDict()
        ret['author'] = [self]
        ret['studies'] = [study(self.db, study_id, self.pvalue_threshold) for study_id in self.studies()]
        return ret
    def details(self):
        """ Provide matching EFO terms. """ 
        details = super().details()
        ret = query.singleton_response(self.db, "SELECT COUNT(DISTINCT pmid) FROM studies WHERE " + self.where_sql())
        details['publications'] = ret.value()
        return details
    
class complex(catalog_object):
    def __init__(self, loc, ewas):
        super().__init__(loc.db,
                         loc.category + "-" + ewas.category,
                         loc.value + " AND " + ewas.value,
                         loc.pvalue_threshold)
        self.loc=loc
        self.ewas=ewas
    def advanced_query_url(self):
        """ URL for submitting a query about this catalog object. """
        return "/?location="+self.loc.value+"&ewas="+self.ewas.value
    def basic_query_url(self):
        """ URL for submitting a query about this catalog object. """
        return ""
    def where_sql(self):
        return "("+self.loc.where_sql() + ") AND (" + self.ewas.where_sql() +")"

    
