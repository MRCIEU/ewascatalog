The website code can be found in the `website/` directory.

All that is missing from there is the downloadable
EWAS summary statistics file and `settings.env`.
These files are copied into position when the website
is setup in the project [catalog](../catalog) script.

## How to modify the website

The guts of the website are in `website/catalog`, mostly
in the `urls.py` and `views.py` files and the `templates` directory.
`urls.py` lists the web pages and references functions
in `views.py` that define the behavior of each page.
The the `views.py` functions link to the appropriate
html templates files in the `templates` directory.

## How to debug database queries in python

The following example show the first 10 p-values in the
results table of the EWAS catalog database.

First step is to start a bash session in the
running docker container. 
```
docker exec -it dev.ewascatalog bash
```

Start python.
```
python
```

Finally, import the necessary libraries, connect to the database,
execute the query, obtain the query table column names,
extract the query table as a list of table rows,
and print out the p-values.
```
>>> import MySQLdb
>>> import MySQLdb.cursors
>>> db = MySQLdb.connect(host=${DATABASE_HOST}, user=${DATABASE_USER}, password=${DATABASE_PASSWORD},db=${DATBASE_NAME})
>>> cur = db.cursor()
>>> cur.execute("select * from results limit 10")
10
>>> cols = [x[0] for x in cur.description]
>>> cols
['cpg', 'chrpos', 'chr', 'pos', 'gene', 'type', 'beta', 'se', 'p', 'details', 'study_id', 'p_rank']
>>> data = list(cur.fetchall())
>>> px = cols.index("p")
>>> for x in data:
...     print(x[px])
...
2.06e-06
4.6e-07
1.41e-11
0.000111
0.000129
2.3e-05
4.72e-13
1.37e-06
3.42e-06
5.7e-48
```

Below we continue the sample showing how to
use code from `website/catalog/objects.py`
to query a genomic region.
```
## make catalog Python modules importable in the Python session
>>> import sys
>>> sys.path = sys.path + [".."]
  ## note: assumes [repository directory]/website/website is the current directory
## load the module in objects.py
>>> from catalog import objects
## query the genomic region
>>> r = objects.retrieve_location(db, "6:15000000-25000000", 1e-4)
## construct a list of CpG sites and genes inside the region
>>> s = r.suggestions()
## how many genes are there
>>> len(s['genes'])
## look at the first gene
>>> s['genes'][0].title()
>>> s['genes'][0].category
>>> s['genes'][0].details()
```

## Origins of the website files

The basic template for the website was created using Django:
```
django-admin startproject website
```

The SECRET_KEY in `website/website/settings.py` was then copied
into `settings.env` for security reasons.

The `website/website/settings.py` file was then edited to its current form.

The `catalog` app was added.
```
cd website
python manage.py startapp catalog
```

The app was then added to the list of 'INSTALLED_APPS'
in `website/website/settings.py`.
```
INSTALLED_APPS = [
    ...
    'catalog',
]
```

Access to the database was tested:
```
python website/manage.py inspectdb
```

Additional files and code were added to the
`website/catalog` directory 
to define the EWAS Catalog website.







