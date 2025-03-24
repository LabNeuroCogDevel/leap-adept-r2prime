OACMNT='/mnt/oac_share/Forbes ADEPT/Data/Analysis/raw/completed'
oac_files() {
   find "${1:-$OACMNT}" \
      -mindepth 3 -type f \
      \( -iname '*nii.gz' -or -iname '*.nii' -or -iname '*json' \)  \
      \( -ipath "*mT2**" -or \
         -ipath '*T1w_acq*' -or \
         -ipath "*func*task_guess*" \
       \) |
   sed 's:.*completed/::';
}

rsync_pipe(){
  [ -n "${DRYRUN:-}" ] && dryrun="--dry-run" || dryrun=""
  # dryrun can be empty for none , dont want to quote that shellcheck disable=SC2086
  rsync -azvhi $dryrun \
     "$OACMNT" \
     /Volumes/Hera/Datasets/adept/data/raw --ignore-existing --files-from=- "$@"
}

sync_all(){
   test -d txt || mkdir txt
   oac_files "${1:-$OACMNT}" |tee txt/rsync.ls | rsync_pipe "$@" #--dry-run
}

eval "$(iffmain sync_all "$@")"
# debug
# source 01_oac_sync.bash
# grep ADEPT0164/ses-02 txt/rsync.ls | rsync_pipe --dry-run
