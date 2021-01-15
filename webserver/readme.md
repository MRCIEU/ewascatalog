# EWAS Catalog web server configuration

The web server receives user requests.
The server handles requests for static files directly. 
The server forwards requests for dynamic content 
vi WSGI to Django running in the 'web' service (see [../docker/readme.md](../docker/readme.md)).

We use the NGINX web server.

It is installed by `Dockerfile` as specified
in [../docker/docker-compose.yml](../docker/docker-compose.yml). 

The server configuration is specified in `ewascatalog.conf`.
It tells the server where 'static' website files can be found
and where to find the 'web' service for dynamic requests.
This configuration file is installed by the `Dockerfile`. 
