#!/bin/bash

FILES_DIR=$1

FILE=${FILES_DIR}/cpg_annotation.txt
if [ ! -f ${FILE} ]; then
    echo "Creating ${FILE}"
    Rscript --vanilla create-cpg-annotation.r ${FILE}
fi

FILE=${FILES_DIR}/gene_annotation.txt
if [ ! -f ${FILE} ]; then
    echo "Creating ${FILE}"
    Rscript --vanilla create-gene-annotation.r ${FILE}
fi
