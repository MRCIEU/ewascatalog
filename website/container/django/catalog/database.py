"""Function for connecting to the EWAS catalog database. 

Database connection details are obtained from django.conf.settings.
"""

from django.conf import settings
import MySQLdb

def default_connection():
    dbuser = settings.DATABASES['default']['USER']
    dbpassword = settings.DATABASES['default']['PASSWORD']
    dbname = settings.DATABASES['default']['NAME']
    dbsocket = settings.DATABASES['default']['OPTIONS']['unix_socket']
    return MySQLdb.connect(
        user=dbuser,
        password=dbpassword,
        db=dbname,
        unix_socket=dbsocket)
    return(db)
