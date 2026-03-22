# -------------------------------------------------------
# Generating PCs in ARIES
# -------------------------------------------------------

source filepaths.sh

# Set directory
cd $bc_home_dir/data/alspac/$timepoints/

# Extract all the ALNs from the timepoint
grep ${timepoints} ../${aries_ids_file} | awk ' { print $1$3" "$1$3 }' > ${timepoints}.txt

if [[ ${timepoints} != "FOF" ]]; then
	gendir=$mum_gendir
	data=$mum_gendata
	ld_data=$mum_ld_data
elif [[ ${timepoints} == "FOF" ]]; then
	gendir=$dad_gendir
	data=$dad_gendata
	ld_data=$dad_ld_data
fi

# Get snp list with no long range LD regions
awk -f ${ld_data} ${data}.bim > nold.txt

# Get independent SNPs excluding any long range LD regions
plink --bfile $data --exclude nold.txt --indep 100 5 1.01 --out indep

# Calculate PCs
plink --bfile $data --keep ${timepoints}.txt --extract indep.prune.in --pca 20 --out ${timepoints}_pcs
