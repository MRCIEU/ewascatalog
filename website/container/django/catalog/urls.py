from django.urls import re_path
from django.contrib import admin
from django.contrib.auth import views as auth_views
from . import views

# handler404 = 'views.page_not_found'
# handler500 = 'views.error'

urlpatterns = [
    re_path(r'^$', views.catalog_home, name='catalog_home'),
    re_path(r'^about/$', views.catalog_info, name='catalog_about'),
    re_path(r'^documentation/$', views.catalog_documents, name='catalog_documents'),
    re_path(r'^download/$', views.catalog_download, name='catalog_download'),
    re_path(r'^upload/$', views.catalog_upload, name='catalog_upload'),
    re_path(r'^api/$', views.catalog_api, name='catalog_api'),
]
