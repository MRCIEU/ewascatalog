#!/bin/bash

set -e

apptainer instance stop app_website_instance &>/dev/null || true
