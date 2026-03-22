""" Respond to text queries. 

Unstructured text box queries require further refining. 
The 'execute' function attempts to guess what the user 
is requesting and then provides more specific options/suggestions.

"""

from . import objects

def execute(db, query, max_suggestions, pthreshold):
    """ Basic query entry point. 

    This function is called in views.py to 
    respond to a text query from the EWAS catalog website.
    """
    suggestions = objects.retrieve_suggestions(db, query, pthreshold)

    if len(suggestions) == 0:
        return []

    isfirst = True
    for group in suggestions.keys():
        objs = [obj for obj in suggestions[group] if obj.assocs() > 0]

        ## sort suggested queries by number of CpG site associations
        if not isfirst:
            def byassocs(obj): return obj.assocs()
            suggestions[group] = sorted(objs, key=byassocs, reverse=True)
        isfirst = False

        ## truncate suggestions if there are too many
        if len(suggestions[group]) > max_suggestions:
            #ellipsis = ("... " + str(max_suggestions)
            #            + " of " + str(len(suggestions[group]))
            #            + " " + group)
            suggestions[group] = suggestions[group][0:max_suggestions-1]# + [ellipsis]

    ## convert 'suggestions' from dictionary of lists to list
    suggestions = [suggestions[group] for group in suggestions.keys()]
    suggestions = sum(suggestions, [])
    return suggestions


