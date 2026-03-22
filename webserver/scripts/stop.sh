#!/bin/bash

set -e

apptainer instance stop app_webserver_instance &>/dev/null || true
