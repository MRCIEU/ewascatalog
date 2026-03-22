"""Function for connecting to the EWAS catalog database. 

Database connection details are obtained from django.conf.settings.
"""

from django.conf import settings
import MySQLdb

def default_connection():
    dbhost = settings.DATABASES['default']['HOST']
    dbuser = settings.DATABASES['default']['USER']
    dbpassword = settings.DATABASES['default']['PASSWORD']
    dbname = settings.DATABASES['default']['NAME']
    return MySQLdb.connect(host=dbhost,user=dbuser,password=dbpassword,db=dbname)
    return(db)
