#!/bin/bash

open recruits-data/data-checklist.xlsx

date="2021-08-23"
filename="papers-to-add-${date}.xlsx"
find ./recruits-data -name $filename