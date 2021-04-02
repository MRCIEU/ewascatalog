""" Respond to structured queries.

Structured queries provide a query 
category (cpg, loc, region, gene, study, trait)
and corresponding value
(CpG identifier, genomic location, genomic region, 
gene name, PMID, EFO identifier, trait).

The response to a query is a table listing 
information for corresponding CpG site associations.
That table is made available to be viewed on a 
web page (via Django) and as a TSV file
for download.
"""

import re
from math import log10, floor
from catalog import query
from catalog import efo
import time
from django.http import JsonResponse

from . import objects

HTML_FIELDS = ["author","pmid","outcome","exposure","tissue","analysis","n",
               "cpg","chrpos","gene","beta","p"]

TSV_FIELDS = ["author","consortium","pmid","date","trait","efo",
              "analysis","source","outcome","exposure","covariates",
              "outcome_unit","exposure_unit","array","tissue",
              "further_details","n","n_studies",
              "age","sex", "ancestry", 
              "cpg","chrpos","chr","pos","gene","type",
              "beta","se","p","details","study_id"]


def execute(db, query, pthreshold):
    """ Structured query entry point. 

    This function is called in views.py to 
    execute a structured query of the EWAS catalog.
    """
    category = next(iter(query.keys()))
    value = query[category]
    obj = ""
    ret = ""
    if category=="cpg":
        obj = objects.cpg.retrieve_object(db, value, pthreshold)
    elif category=="loc":
        obj = objects.loc.retrieve_object(db, value, pthreshold)
    elif category=="region":
        obj = objects.region.retrieve_object(db, value, pthreshold)
    elif category=="gene":
        obj = objects.gene.retrieve_object(db, value, pthreshold)
    elif category=="efo":
        obj = objects.efo_term.retrieve_object(db, value, pthreshold)
    elif category=="trait":
        obj = objects.trait.retrieve_object(db, value, pthreshold)
    elif category=="study":
        obj = objects.study.retrieve_object(db, value, pthreshold)
    elif category=="author":
        obj = objects.author.retrieve_object(db, value, pthreshold)
    elif category=="location" or category=="ewas":
        obj = objects.complex(db, query['location'], query['ewas'])
    if isinstance(obj, objects.catalog_object):
        sql = response_sql("("+obj.where()+") AND p<"+str(pthreshold))
        ret = response(db, obj.value, sql)
    return ret

def response_sql(where):
    """ The basic SQL query syntax. 
    
    The query category/value pair determines 
    how the resulting table is restricted. 
    """
    return ("SELECT DISTINCT studies.*,results.* "
            "FROM results "
            "LEFT JOIN studies ON results.study_id=studies.study_id "
            "LEFT JOIN cpgs ON results.cpg=cpgs.cpg "
            "WHERE "+where+" LIMIT 500000")

class response(query.response):
    """ Query response object. 

    Performs the query and provides functions for accessing 
    and manipulating the resulting table. 
    """
    def __init__(self, db, value, sql):
        super().__init__(db, sql)
        self.value = value
        self.sort() ## sort ascending by p-value.
    def sort(self):
        pvx = self.cols.index("p")
        self.data.sort(key=lambda x: (float(x[pvx])))
        #aux = self.cols.index("author")
        #pmx = self.cols.index("pmid")
        #self.data.sort(key=lambda x: (x[aux], x[pmx], float(x[pvx])))
    def table(self):
        """ Returns the query table as a tuple of rows with formatted values. """
        cols = HTML_FIELDS
        html_copy = self.copy()
        html_copy.subset(cols=cols)
        formatted_p = [format_pval(pval) for pval in html_copy.col("p")]
        html_copy.set_col("p", formatted_p)
        formatted_beta = [format_beta(beta) for beta in html_copy.col("beta")]
        html_copy.set_col("beta", formatted_beta)
        return tuple(html_copy.data)
    def save(self, path):
        """ Saves the query table to a TSV file and returns the filename. """
        tsv_copy = subset_tsv_cols(self)
        ts = str(time.time()).replace(".","")
        filename = self.value.replace(" ", "_")+'_'+ts+'.tsv'
        f = open(path+'/'+filename, 'w')
        f.write('\t'.join(tsv_copy.colnames())+'\n')
        for idx in range(tsv_copy.nrow()):
            f.write('\t'.join(str(x) for x in tsv_copy.row(idx))+'\n')
        return filename
    def json(self):
        """ Subsets query table and returns as a JSON response object. """
        tab_copy = subset_tsv_cols(self)
        return JsonResponse({'results':tab_copy.data, 'fields':tab_copy.cols})


def round_sig(x, sig=2):
    if x>0:
        return round(x, sig-int(floor(log10(abs(x))))-1)
    else:
        return x 

def format_e(n):
    a = '%E' % n
    return a.split('E')[0].rstrip('0').rstrip('.') + 'E' + a.split('E')[1]

def format_pval(p):
    return str(format_e(round_sig(float(p))))

def format_beta(b):
    try:
        b = float(b)
        if b == 0:
            return 'NA'
        else:
            return str(round_sig(b))
    except (ValueError, TypeError):
        return 'NA'

def subset_tsv_cols(tab):
    """ Subsets query table using TSV file columns. """
    cols = TSV_FIELDS
    tab_copy = tab.copy()
    tab_copy.subset(cols=cols)
    return tab_copy
