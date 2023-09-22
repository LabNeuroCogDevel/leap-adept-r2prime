OACMNT='/mnt/oac_share/Forbes ADEPT/Data/Analysis/raw/completed'
oac_files() {
   find "$OACMNT" \
      -mindepth 3 -type f \
      \( -iname '*nii.gz' -or -iname '*json' \)  \
      \( -ipath "*anat*" \
         \( -ipath "*mT2*" -or \
            -ipath '*T1w_acq*' \) \
         -or \
         -ipath "*func*task_guess*" \
       \) |
   sed 's:.*completed/::';
}

rsync_pipe(){
  rsync -azvhi\
     "$OACMNT" \
     /Volumes/Hera/Datasets/adept/data/raw --files-from=- "$@"
}

sync_all(){
   test -d txt || mkdir txt
   oac_files |tee txt/rsync.ls | rsync_pipe #--dry-run
}

eval "$(iffmain sync_all)"
# debug
# source 01_oac_sync.bash
# grep ADEPT0164/ses-02 txt/rsync.ls | rsync_pipe --dry-run
