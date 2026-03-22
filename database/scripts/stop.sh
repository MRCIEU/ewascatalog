#!/bin/bash

set -e

apptainer instance stop app_db_instance &>/dev/null || true
