from django import template

register = template.Library()

@register.filter
def is_string(val):
    """ To check if a variable is a string in the HTML templates. """
    return isinstance(val, str)
