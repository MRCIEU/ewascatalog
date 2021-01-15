# Searching PubMed for published EWAS

## Search terms
(epigenome-wide) OR (epigenome wide) OR (EWAS) OR (genome-wide AND methylation) OR (genome wide AND methylation)

## pubmed2xlsx
A python command line tool to convert the text file of results from PubMed to an excel spreadsheet.

## Process
1. Query PubMed using the search terms in the andanced toolbar setting.
2. Download results in text format (with abstract).
3. Use pubmed2xlsx to create the excel spreadsheet: `./pubmed2xlsx --file=pubmed_result.txt`
