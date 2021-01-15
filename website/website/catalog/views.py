from django.shortcuts import render, redirect
import pandas as pd
from django.http import JsonResponse
from django.views.decorators.cache import never_cache
import os, datetime, subprocess, re, shutil
from ratelimit.decorators import ratelimit
from django.conf import settings
from django.core.files.storage import FileSystemStorage
from django.core.mail import EmailMessage

from . import basicquery, advancedquery, database, upload, constants
from .forms import DocumentForm


def clear_directory(directory):
    for file in os.listdir(directory):
        curpath = os.path.join(directory+'/'+file)
        file_modified = datetime.datetime.fromtimestamp(os.path.getmtime(curpath))
        if datetime.datetime.now() - file_modified > datetime.timedelta(hours=5):
            os.remove(curpath)

@never_cache
def catalog_home(request):
    clear_directory(constants.TMP_DIR)
    keys = request.GET.keys()
    if len(keys) > 0:
        if "query" in keys:
            return basicquery_response(request)
        else:
            return advancedquery_response(request)
    else:
        return render(request, 'catalog/catalog_home.html', {})

def basicquery_response(request):
    query = request.GET
    text = next(iter(query.values()))
    db = database.default_connection()
    response = basicquery.execute(db, text, constants.MAX_SUGGESTIONS, constants.PVALUE_THRESHOLD)
    if len(response) > 0:
        return render(request, 'catalog/catalog_queries.html',
                      {'query':text.replace(" ", "_"),
                       'query_label':text,
                       'query_list':response})
    else:
        return render(request, 'catalog/catalog_no_results.html',
                      {'query':text})

def advancedquery_response(request):
    query = request.GET
    db = database.default_connection()
    #response = advancedquery.execute(db, query, constants.MAX_ASSOCIATIONS, constants.PVALUE_THRESHOLD)
    response = advancedquery.execute(db, query, constants.PVALUE_THRESHOLD)
    if isinstance(response, advancedquery.response):        
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
    db = database.default_connection()
    if request.method == 'POST':
        form = upload.create_form(db, request.POST, request.FILES)
        if form.is_valid():
            response = upload.process(db, request.FILES['results'], request.POST.copy())
            if "error" in response.keys():
                return render(request, 'catalog/catalog_bad_upload_message.html', {
                    'x': response['error']
                })
            else:
                return render(request, 'catalog/catalog_upload_message.html', {
                    'email': response['email'], 
                    'zenodo_msg': response['zenodo_msg']
                })
    else:
        form = upload.create_form(db)
    return render(request, 'catalog/catalog_upload.html', {
        'form': form
    })

@ratelimit(key='ip', rate='1000/h', block=True)
def catalog_api(request):
    db = database.default_connection()
    query = request.GET 
    ret = advancedquery.execute(db, query, constants.MAX_ASSOCIATIONS*1000, constants.PVALUE_THRESHOLD)
    if isinstance(ret, advancedquery.response):
        return ret.json()
    else:
        return JsonResponse({})
