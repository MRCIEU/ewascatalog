# --------------------------------------------------
# Write emails from template
# --------------------------------------------------

## Aim: Take emails + names + papers from a spreadsheet and insert them into a template email

## Date: 2021-06-23

## NEED TO TALK TO PAUL TO MAKE SURE HE CONTINUES TO PUT A 1 IN THE to_contact COLUMN

## pkgs
import pandas as pd
import os, warnings, sys
from datetime import date

ext_date = sys.argv[1]
# ext_date = "2021-07-26" ## SHOULD CHANGE THIS TO AN ARGUMENT TO PARSE!

## create a new directory for the emails
outdir = 'emails/'+ext_date
if not os.path.isdir(outdir):
	os.makedirs(outdir)
 
## read in the data on author name and title
data_file = "papers-to-add-" + ext_date + ".xlsx"
data_dir = "../recruits-data/Paul Yousefi/" + ext_date
papers = pd.read_excel(data_dir + "/" + data_file)

## Drop duplicates just incase
papers.drop_duplicates(inplace = True)
## Check comments column is all null
coms = papers['comments'].isnull().sum()
if coms != len(papers):
	warnings.warn('There are comments. Make sure you have checked these before sending the emails!')
 
## opening the email template
email_temp = open("email-template")
string_list = email_temp.readlines()

## go through papers and edit the email template for each person
entries = range(0,len(papers))
for line in entries:
	obj = papers.iloc[line]
	name = obj['cor_author']
	title = obj['Title']
	## Skip individuals who shouldn't be contacted
	if obj['to_contact'] != 1:
		msg = 'Not contacting ' + name
		print(msg)
		continue
	outfile= outdir+"/"+obj['email']
	email = string_list.copy()
	email_file = open(outfile, "w")
	## Change name and publication title from email template
	for idx, item in enumerate(email):
		if 'Dear XXX' in item:
			item = email[idx]
			item = item.replace('XXX', name)
			email[idx] = item
		if 'publication "XXX"' in item:
			item = email[idx]
			item = item.replace('XXX', title)
			email[idx] = item
		outline = email[idx]
		email_file.write(outline)
	email_file.close()

## Add in new columns to fill out later
today = date.today()
papers['contacted'] = today.strftime("%Y-%m-%d")
papers['data_received'] = "N"

## Write out papers to spreadsheet to fill out manually later
data_outdir = "data/" + ext_date
if not os.path.isdir(data_outdir):
	os.mkdir(data_outdir)
 
papers.to_excel(data_outdir + "/" + data_file, index = False)
