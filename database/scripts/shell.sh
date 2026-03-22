#!/bin/bash

set -e

echo "Initiating shell prompt in database container  ..."
apptainer exec instance://app_db_instance /bin/bash



