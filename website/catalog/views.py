from django.shortcuts import render, redirect
import pandas as pd
from django.http import JsonResponse
from django.views.decorators.cache import never_cache
import os, datetime, subprocess, re, shutil
from ratelimit.decorators import ratelimit
from django.conf import settings
from django.core.files.storage import FileSystemStorage
from django.core.mail import EmailMessage

from . import firstquery, finalquery, database, upload, constants
from .forms import DocumentForm


def clear_directory(directory):
    for file in os.listdir(directory):
        curpath = os.path.join(directory+'/'+file)
        file_modified = datetime.datetime.fromtimestamp(os.path.getmtime(curpath))
        if datetime.datetime.now() - file_modified > datetime.timedelta(hours=5):
            os.remove(curpath)

def get_database_mod_date():
    studies_file = constants.BASE_DIR + "/../files/ewas-sum-stats/combined_data/studies.txt"
    mod_dt = datetime.datetime.fromtimestamp(os.path.getmtime(studies_file))
    date = str(mod_dt.year) + "-" + str(mod_dt.month) + "-" + str(mod_dt.day)
    return date

@never_cache
def catalog_home(request):
    clear_directory(constants.TMP_DIR)
    db_date = get_database_mod_date()
    keys = request.GET.keys()
    if len(keys) > 0:
        if "query" in keys:
            return firstquery_response(request)
        else:
            return finalquery_response(request)
    else:
        return render(request, 'catalog/catalog_home.html', {'db_date': db_date})

def firstquery_response(request):
    query = request.GET
    text = next(iter(query.values()))
    db = database.default_connection()
    response = firstquery.execute(db, text, constants.MAX_SUGGESTIONS, constants.PVALUE_THRESHOLD)
    if len(response) > 0:
        return render(request, 'catalog/catalog_queries.html',
                      {'query':text.replace(" ", "_"),
                       'query_label':text,
                       'query_list':response})
    else:
        return render(request, 'catalog/catalog_no_results.html',
                      {'query':text})

def finalquery_response(request):
    query = request.GET
    db = database.default_connection()
    response = finalquery.execute(db, query, constants.PVALUE_THRESHOLD)
    if isinstance(response, finalquery.response):        
        filename = response.save(constants.TMP_DIR)
        total=response.nrow()
        toomuch=response.nrow() > constants.MAX_ASSOCIATIONS
        if toomuch:
            response.subset(rows=range(constants.MAX_ASSOCIATIONS))
        return render(request, 'catalog/catalog_results.html',
                      {'response':response.table(),
                       'subset': response.nrow(),
                       'total': total,
                       'query':response.value.replace(" ", "_"),
                       'query_label':response.value,
                       'filename':filename})
    else:
        return render(request, 'catalog/catalog_no_results.html',
                      {'query':[key+"="+value for key,value in query.items()]})

@never_cache
def catalog_info(request):
    clear_directory(constants.TMP_DIR)
    return render(request, 'catalog/catalog_about.html', {})

@never_cache
def catalog_documents(request):
    clear_directory(constants.TMP_DIR)
    return render(request, 'catalog/catalog_documents.html', {})

@never_cache
def catalog_download(request):
    clear_directory(constants.TMP_DIR)
    return render(request, 'catalog/catalog_download.html', {})

@never_cache
def catalog_upload(request):
    clear_directory(constants.TMP_DIR)
    return render(request, 'catalog/catalog_upload.html')

@ratelimit(key='ip', rate='1000/h', block=True)
def catalog_api(request):
    db = database.default_connection()
    query = request.GET 
    ret = finalquery.execute(db, query, constants.PVALUE_THRESHOLD)
    if isinstance(ret, finalquery.response):
        return ret.json()
    else:
        return JsonResponse({})
