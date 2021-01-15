""" Deal with file uploads.

Users can upload their data and it should be checked
and an email sent to them detailing what they've sent
"""

import os, re, shutil, datetime, subprocess
import pandas as pd
from django.core.mail import EmailMessage
from django.shortcuts import render
from .forms import DocumentForm
from . import constants

def create_form(db, post=None, files=None):
    """ Create upload form in views.py 
    """
    arrays = extract_arrays(db)
    tissues = extract_tissues(db)
    if post is None:
        return DocumentForm(array_list=arrays, 
                            tissue_list=tissues)
    else:
        return DocumentForm(post, 
                            files,
                            array_list=arrays, 
                            tissue_list=tissues)

def extract_arrays(db):
    """ Create list of microarray array formats for user to choose from
    """
    cursor = db.cursor()
    return extract_sql_data("array", cursor)

def extract_tissues(db):
    """ Create list of tissues for user to choose from
    """
    cursor = db.cursor()
    return extract_sql_data("tissue", cursor)

def process(db, file_info, upload_info):
    """ Process a study upload

        Processing includes checking for errors, 
        saving uploaded study information and summary statistics, 
        sending a report to the user by email, 
        and finally saving information for generating a zenodo doi.
    """
    if file_info.size > constants.FILE_SIZE_LIMIT:
        return {"error": "File uploaded is too big"}
    if not file_info.name.endswith(".csv"):
        return {"error": "File uploaded is not CSV format"}
    ## extract study info
    study_info = extract_study_info(upload_info)
    ## create study upload dir
    study_dir = constants.UPLOAD_DIR+gen_study_id(study_info)
    create_dir(study_dir)
    ## save study files
    study_file = save_study(study_info, study_dir)
    results_file = save_results(file_info.file, study_dir)
    ## verify study files
    check_result = check_study(study_file, results_file)
    if check_result != 'Good':
        shutil.rmtree(study_dir)
        return {"error": check_result}
    ## send upload report to user
    send_report(upload_info['name'], upload_info['email'], study_file)
    ## save zenodo info
    zenodo_msg = save_zenodo(upload_info, study_dir)
    ## return variables for website response
    return {"email": upload_info['email'],
            "zenodo_msg": zenodo_msg}

def generate_timestamp():
    return datetime.datetime.today().__str__().replace(" ", "_")

def save_study(info, base):
    """ Save uploaded study metadata to a csv file
    """
    dt = generate_timestamp()
    study_file = base+'/'+dt+'_studies.csv'
    info.to_csv(study_file, index=False)
    return study_file

def save_results(filename, base):
    """ Save uploaded study summary statistics to a csv file

        In fact, the data is already in a csv file, 
        the file just needs to be copied to another directory.
    """
    dt = generate_timestamp()
    results_data = pd.read_csv(filename)
    results_file = base+'/'+dt+'_results.csv'
    results_data.to_csv(results_file, index = False)
    # shutil.copyfile(filename, results_file)
    return results_file

def save_zenodo(info, base):
    """ Save information for generating zenodo doi for a study
    """
    if info['zenodo'] == 'Yes':
        zenodo_info = { 'desc': [info['zenodo_desc']], 
                        'title': [info['zenodo_title']],
                        'authors': [info['zenodo_authors']]}
        df = pd.DataFrame(zenodo_info)
        df.to_csv(base+'/zenodo.csv', index=False)
        return 'You indicated you wanted a zenodo doi so we will generate this for you with the information you provided.'
    else:
        return 'You indicated you did not want a zenodo doi.'

def send_report(name, email, study_file):
    """ Send an upload report to the user email address
    """
    report=constants.UPLOAD_DIR+'ewas-catalog-report.html'
    attachments=[study_file, report]
    send_email(name, email, attachments)
    os.remove(report)
    os.remove(constants.UPLOAD_DIR+'ewas-catalog-report.md')
    os.remove(constants.UPLOAD_DIR+'report-output.txt')

def check_study(study_file, results_file):
    """ Verify that uploaded study information satisfies requirements
    """
    command = 'Rscript'
    script = 'database/check-ewas-data.r'
    cmd = [command, script, study_file, results_file, constants.UPLOAD_DIR]
    return subprocess.check_output(cmd, universal_newlines=True)

def get_outcome_and_exposure(rcopy):
    """ Use form to define outcome and exposure and units.
    """
    dnam_as_outcome = rcopy.get('dnam_as_outcome')
    if dnam_as_outcome == 'Outcome':
        outcome = 'DNA methylation'
        outcome_units = rcopy.get('dnam_units')
        exposure = rcopy.get('trait')
        exposure_units = rcopy.get('trait_units')
    else:
        outcome = rcopy.get('trait')
        outcome_units = rcopy.get('trait_units')
        exposure = 'DNA methylation'
        exposure_units = rcopy.get('dnam_units')
    return [outcome, outcome_units, exposure, exposure_units]

def combine_covariates(rcopy):
    """ Extract all covariates from form and combine to one list
    """
    covs = rcopy.getlist('covariates')
    other_covs = rcopy.get('other_covariates')
    covs.append(other_covs)
    covs = ', '.join(covs)
    return covs


def extract_study_info(rcopy):
	""" Extracting study information from POST data.

	This function is called in views.py to
	extract the user input POST data from the upload 
	page. 
	"""
	covs = combine_covariates(rcopy)
	outcome_exposure = get_outcome_and_exposure(rcopy)
	study_dat = {'Author': [rcopy.get('author')],
				 'Consortium': [rcopy.get('consortium')],
				 'PMID': [rcopy.get('pmid')],
				 'Date': [rcopy.get('publication_date')],
				 'Trait': [rcopy.get('trait')],
				 'EFO': [rcopy.get('efo')],
				 'Analysis': [rcopy.get('analysis')],
				 'Source': [rcopy.get('source')],
				 'Outcome': [outcome_exposure[0]],
				 'Exposure': [outcome_exposure[2]],
				 'Covariates': [covs],
				 'Outcome_Units': [outcome_exposure[1]],
				 'Exposure_Units': [outcome_exposure[3]],
				 'Methylation_Array': [rcopy.get('array')],
				 'Tissue': [rcopy.get('tissue')],
				 'Further_Details': [rcopy.get('further_details')],
				 'N': [rcopy.get('n')],
				 'N_Cohorts': [rcopy.get('n_studies')],
				 'Age': [rcopy.get('age')],
				 'Sex': [rcopy.get('sex')],
				 'Ethnicity': [', '.join(rcopy.getlist('ethnicity'))]
				}
	df = pd.DataFrame(study_dat)
	return df

def isNaN(num):
    return num != num

def gen_study_id(study_dat):
    """ Generating a Study ID from the study data.

    This function is called in views.py to
    generate the study ID 
    """    
    df = study_dat
    auth_nam = df.iloc[0]['Author'].replace(" ", "-")
    trait_nam = df.iloc[0]['Trait'].replace(" ", "_").lower()
    if isNaN(df.iloc[0]['PMID']):
        StudyID = auth_nam+"_"+trait_nam
    else:
        StudyID = str(df.iloc[0]['PMID'])+"_"+auth_nam+"_"+trait_nam
    analysis_nam = df.iloc[0]['Analysis'].replace(" ", "_").lower()
    StudyID = StudyID+'_'+analysis_nam
    return StudyID.strip('_')

def extract_sql_data(var, cursor):
	""" Extracting variables from database.

	This function is used in views.py to extract 
	data from the ewascatalog database and this 
	can be used to populate multiple choice options
	on the upload webpage 
	"""    
	sql = "SELECT DISTINCT "+var+" FROM studies"
	cursor.execute(sql)
	results = cursor.fetchall()
	return results

def create_dir(new_dir):
    if not os.path.exists(new_dir):
        os.mkdir(new_dir)

def send_email(name, useremail, attachments):
	""" Send emails to users.

    This function is called in views.py to
    send an email to users who upload data 
    to the catalog.
    """
	email_start = 'Dear '+name+',\n\n'
	email_body = 'Thank you for uploading your results to the EWAS Catalog. Please find attached an initial report on the data you uploaded as well as csv file with the study information provided. We will conduct more checks and if the data looks good we will email you with a zenodo doi if you requested one and we will let you know the data is in the catalog.\n\n'
	email_end = 'Kind regards,\nThe EWAS Catalog team'
	email_full_body = email_start+email_body+email_end
	email_msg = EmailMessage(
	    subject = ['Automated EWAS Catalog Upload message'],
	    body = email_full_body,
	    from_email = 'ewascatalog@outlook.com',
	    to = [useremail],
	    bcc = ['thomas.battram@bristol.ac.uk']
	)    
	for file in attachments:
	    email_msg.attach_file(file)        
	email_msg.send()
