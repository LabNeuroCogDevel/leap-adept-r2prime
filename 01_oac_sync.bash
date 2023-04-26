OACMNT='/mnt/oac_share/Forbes ADEPT/Data/Analysis/raw/completed'
oac_files() {
   find "$OACMNT" \
      -mindepth 3 -type f \
      \( -iname '*nii.gz' -or -iname '*json' \)  \
      -ipath "*anat*" \( -ipath "*mT2*" -or -ipath '*T1w_acq*' \) |
      sed 's:.*completed/::';
}

rsync_pipe(){
  rsync -azvhi\
     "$OACMNT" \
     /Volumes/Hera/Datasets/adept/data/raw --files-from=- "$@"
}

oac_files | rsync_pipe #--dry-run
