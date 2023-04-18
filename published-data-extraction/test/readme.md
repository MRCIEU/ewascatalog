# Testing data upload checks

Some files to test some of the checks performed when uploading data to The EWAS Catalog database. 

* [`good.csv`](good.csv) - results file that should upload
* [`test-bad-col-class`](test-bad-col-class) - contains a results file with a column with the wrong datatype
* [`test-bad-colnames`](test-bad-colnames) - contains results files with good and bad column names
* [`test-only-good`](test-only-good) - contains results files with different amounts of information, but shouldn't produce any errors when uploaded.