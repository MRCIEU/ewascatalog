from django import forms
from django.conf import settings
from django.utils.safestring import mark_safe

class ListTextWidget(forms.TextInput):
	""" Custom widget to allow users to choose
	from previous database entries

	This widget is used in the DocumentForm form below
	"""
	def __init__(self, data_list, name, *args, **kwargs):
		super(ListTextWidget, self).__init__(*args, **kwargs)
		self._name = name
		self._list = data_list
		self.attrs.update({'list':'list__%s' % self._name})

	def render(self, name, value, attrs=None, renderer=None):
		text_html = super(ListTextWidget, self).render(name, value, attrs=attrs)
		data_list = '<datalist id="list__%s">' % self._name
		for item in self._list:
			data_list += '<option value="%s">' % item
		data_list += '</datalist>'

		return (text_html + data_list)

COVARIATE_CHOICES = [
	('Age', 'Age'),
	('Sex', 'Sex'), 
	('Smoking', 'Smoking'),
	('Cell composition (reference based)', 'Cell composition (reference based)'),
	('Cell composition (reference free)', 'Cell composition (reference free)'),
	('Batch effects', 'Batch effects'), 
	('Ancestry (genomic PCs)', 'Ancestry (genomic PCs)'), 
	('Ancestry (other)', 'Ancestry (other)'),
	('Body mass index', 'Body mass index'), 
	('Gestational age', 'Gestational age'), 
	('Socio-economic position', 'Socio-economic position'), 
	('Education', 'Education'), 
	('Birthweight', 'Birthweight')
]

AGE_CHOICES = [
	('Infants', 'Infants'),
	('Children', 'Children'),
	('Adults', 'Adults'),
	('Geriatrics', 'Geriatrics')
]

SEX_CHOICES = [
	('Males', 'Males'),
	('Females', 'Females'),
	('Both', 'Both')
]

ETHNICITY_CHOICES = [
	('European', 'European'),
	('East Asian', 'East Asian'), 
	('South Asian', 'South Asian'),
	('African', 'African'),
	('Admixed', 'Admixed'),
	('Other', 'Other'), 
	('Unclear', 'Unclear')
]

class DocumentForm(forms.Form):
	# study information
	name = forms.CharField(max_length=50, label = "Uploader Name*", 
						   widget=forms.TextInput(attrs={'class':'special', 'size': '40'}))
	email = forms.EmailField(label = "Uploader Email*")
	author = forms.CharField(max_length=50, label="First Author*",help_text="In format Surname Initials, e.g. 'Doe J'.")
	consortium = forms.CharField(required=False, max_length=50, label="Cohort(s) or Consortium Name", help_text="Separate by comma if multiple.")
	pmid = forms.CharField(required=False, max_length=20, label="PubMed ID (or DOI)")
	publication_date = forms.DateField(required=False, label="Publication Date (DD/MM/YY)")
	trait = forms.CharField(max_length=100, label="Trait*")
	efo = forms.CharField(required=False, max_length=50, 
			      label='EFO Term',
                              help_text=mark_safe("The corresponding <a href='http://www.ebi.ac.uk/efo/' target='_blank'>ontology term(s)</a> for the trait. In the form 'EFO_ID', e.g. for body mass index, EFO Term = EFO_0004340. If there are multiple terms, separate them with a comma."))
	trait_units = forms.CharField(required=False, max_length=50, label="Trait Units (If categorical trait then leave blank)")
	dnam_as_outcome = forms.ChoiceField(choices=[('Outcome', 'Outcome'), ('Exposure', 'Exposure')],
									    widget=forms.RadioSelect, 
									    label="How was DNA methylation specified in the model?*")
	dnam_units = forms.ChoiceField(choices=[('Beta Values', 'Beta Values'), ('M Values', 'M Values'), ('Other', 'Other')],
								   widget=forms.RadioSelect,
								   label="DNA Methylation Units*")
	analysis = forms.CharField(required=False, max_length=100, label="Analysis",help_text="e.g. Discovery or Discovery and replication")
	source = forms.CharField(required=False, max_length=50, label="Source", help_text="e.g. Table 1, Table S1")
	## analysis information
	covariates = forms.MultipleChoiceField(required=False, label="Covariates", help_text="Select all that apply. For meta-analysis entries select the covariates commonly used across studies.",
								 widget=forms.CheckboxSelectMultiple, choices=COVARIATE_CHOICES)
	other_covariates = forms.CharField(required=False, max_length = 300, label="Other Covariates", help_text="Please separate each with a comma, e.g. a covariate, another covariate.")
	array = forms.CharField(max_length=50, label="Methylation Array*")
	tissue = forms.CharField(max_length=100, label="Tissue*", help_text="Start typing to see some options.")
	further_details = forms.CharField(required=False, max_length=200, label="Additional details about the analysis", help_text="e.g. analysis of twins")
	## participant info
	n = forms.CharField(max_length=20, label="Total Number of Participants*")
	n_studies = forms.CharField(max_length=20, label="Total Number of Cohorts*")
	age = forms.ChoiceField(label="Age group*", help_text="Choose the most prominent age group in your study.", 
							widget=forms.RadioSelect, choices=AGE_CHOICES)
	sex = forms.ChoiceField(label='Sex*', help_text="Individuals with DNA methylation measurements.", widget=forms.RadioSelect, choices=SEX_CHOICES)
	ethnicity = forms.MultipleChoiceField(label='Ethnicity*', help_text="Select all that apply.", 
										  widget=forms.CheckboxSelectMultiple, choices=ETHNICITY_CHOICES)
	## zenodo info
	zenodo = forms.ChoiceField(choices=[('Yes', 'Yes'), ('No', 'No')], widget=forms.RadioSelect, label="Generate zenodo DOI?*")
	zenodo_title = forms.CharField(required = False, max_length=200, label="Title of Manuscript")
	zenodo_desc = forms.CharField(required = False, max_length=5000, widget=forms.Textarea(), label="Description for Zenodo", help_text="e.g. manuscript abstract.")
	zenodo_authors = forms.CharField(required = False, max_length=5000, label="All Authors", help_text="Put in format you wish to see the list to appear on the zenodo website.")
	## results upload
	results = forms.FileField(label = "Results File*")
	## def __init__ for multiple choice lists
	def __init__(self, *args, **kwargs):
		_array_list = kwargs.pop('array_list', None)
		_tissue_list = kwargs.pop('tissue_list', None)
		super(DocumentForm, self).__init__(*args, **kwargs)
		self.fields['array'].widget = ListTextWidget(data_list=_array_list, name='array-list')
		self.fields['tissue'].widget = ListTextWidget(data_list=_tissue_list, name='tissue-list')
		docfields = iter(self.fields)
		for fname in docfields:
			self.fields[fname].widget.attrs['class'] = 'special'
			self.fields[fname].widget.attrs['size'] = '40'
