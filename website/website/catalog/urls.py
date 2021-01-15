from django.conf.urls import url
from django.contrib import admin
from django.contrib.auth import views as auth_views
from . import views

# handler404 = 'views.page_not_found'
# handler500 = 'views.error'

urlpatterns = [
    url(r'^$', views.catalog_home, name='catalog_home'),
    url(r'^about/$', views.catalog_info, name='catalog_about'),
    url(r'^documentation/$', views.catalog_documents, name='catalog_documents'),
    url(r'^download/$', views.catalog_download, name='catalog_download'),
    url(r'^upload/$', views.catalog_upload, name='catalog_upload'),
    url(r'^api/$', views.catalog_api, name='catalog_api'),
]
