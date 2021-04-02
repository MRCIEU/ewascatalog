""" Functions for lookup of EFO terms and labels

Uses ZOOMA to obtain EFO terms for traits.
Uses EMBL-EBI Ontology Lookup Service to obtain labels for EFO terms.
""" 

import re, requests, string

def unlist(x):
    return sum(x,[])

def basic(text, filters=None):
    """ Retrieve EFO terms matching the input text. """
    ## format text from user input to something queriable
    text = re.sub('[^a-zA-Z\d\s]', '', text).replace(" ", "+")

    ## construct EFO query url
    url = 'http://www.ebi.ac.uk/spot/zooma/v2/api/services/annotate?propertyValue='
    url = url + text
    if not filters is None:
        url = url + "&filter=required:["+",".join(filters)+"]"

    ## run query, if zooma failure, then return nothing
    try:
        responses = requests.get(url).json()
    except:
        return dict()

    ## parse xml for results
    natural = [response['annotatedProperty']['propertyValue'] for response in responses]
    efo_urls = [response['semanticTags'] for response in responses]
    efo_urls = unlist(efo_urls)
    efo_pattern = re.compile('EFO_[0-9]+')
    efo_terms = [efo_pattern.findall(url) for url in efo_urls] 
    efo_terms = unlist(efo_terms)
    return dict(zip(efo_terms, natural))

def lookup(text):
    """ Retrieve EFO terms with and without the 'gwas' filter. """
    ret = basic(text)
    ret.update(basic(text, "gwas"))
    return ret

def label(efo):
    """ Retrieve the EFO term label. """
    url = 'https://www.ebi.ac.uk/ols/api/ontologies/efo/terms?iri=http://www.ebi.ac.uk/efo/'+efo
    response = requests.get(url).json()
    if 'error' in response.keys():
        return ""
    return response['_embedded']['terms'][0]['label']
