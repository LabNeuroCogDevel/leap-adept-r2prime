echo "# remote -> raw"
mkmissing \
   -1 '/mnt/oac_share/Forbes ADEPT/Data/Analysis/raw/completed/ADPEPT*/ses-*/' \
   -2 '../data/raw/ADEPT*/ses-*/' \
   -p '\d{4}/ses-\d+'

echo "# raw -> r2prime"
mkmissing \
   -1 '../data/raw/ADEPT*/ses-*/' \
   -2 '../data/r2prime/ADEPT*/ses-*/r2primeMap_mni_fast_al.nii.gz'\
   -p 'ADEPT\d{4}/ses-\d+'

echo "# bids -> fmriprep"
mkmissing \
   -1 '../data/BIDS/sub-*/ses-*/func/*bold.json' \
   -2 '../data/fmriprep/sub-*/ses-*/func/*bold.nii.gz' \
   -p 'sub-\d+/ses-\d+'
