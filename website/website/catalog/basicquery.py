""" Respond to text queries. 

Unstructured text box queries require further refining. 
The 'execute' function attempts to guess what the user 
is requesting and then provides more specific options/suggestions.

"""

from . import objects



def execute(db, query, max_suggestions, pvalue_threshold):
    """ Basic query entry point. 

    This function is called in views.py to 
    respond to a text query from the EWAS catalog website.
    It attempts to guess what the user is requesting ('matches' functions)
    and then provides more specific options/suggestions.
    """
    obj = objects.retrieve(db, query, pvalue_threshold)

    if not isinstance(obj, objects.catalog_object):
        return []
    
    ## sort suggested queries by number of CpG site associations
    def byassocs(obj): return obj.assocs()
    suggestions = obj.suggestions()
    for group in suggestions.keys():
        objs = [objects.cached_catalog_object(obj) for obj in suggestions[group]]
        objs = [obj for obj in objs if obj.assocs() > 0]
        suggestions[group] = sorted(objs, key=byassocs, reverse=True)
        if len(suggestions[group]) > max_suggestions:
            ellipsis = ("... " + str(max_suggestions)
                        + " of " + str(len(suggestions[group]))
                        + " " + group)
            suggestions[group] = suggestions[group][0:max_suggestions-1] + [ellipsis]
        
    suggestions = [suggestions[group] for group in suggestions.keys()]
    suggestions = sum(suggestions, [])
    return suggestions
    
