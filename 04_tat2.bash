#!/usr/bin/env bash
#
# time averate T2*
#
# 20230721WF - init
#

root=/Volumes/Hera/Datasets/adept
get_ses(){ perl -pe 's:.*(sub-[^_]*)([_/])(ses-[^_/]*).*:\1_\3:' <<< "$*"; }

FDTHRES=0.3
mkcen(){
   local in="${1:?fmriprep confounds tsv file}"
   local out=${in/desc-confounds_timeseries.tsv/desc-fd${FDTHRES}_timeseries.1D}
   [ -s "$out" ] && echo "$out" && return 0
   [[ "$in" == "$out" ]] && warn "bad fmriprep confounds file name. cannot name fd out" && return 1
   mlr --tsv  --ho cut -f trans_x,trans_y,trans_z,rot_x,rot_y,rot_z "$in" |
      fd_calc 1:3 4:6 rad $FDTHRES |
      drytee "$out"
   echo "$out"
}
tat2_dir(){
   local dir sess
   dir="${1:?tat2_dir() needs fmriprep func dir arg}"
   sess=$(get_ses "$dir")
   for f in "$dir"/*desc-confounds_timeseries.tsv; do
      mkcen "$f"
   done
   dryrun tat2 -output "$root/data/tat2/${sess}_tat2.nii.gz" \
        -mask_rel s/desc-preproc_bold/desc-brain_mask/  \
        -censor_rel "s/space.*desc-.*/desc-fd${FDTHRES}_timeseries.1D/" \
        -mean_time -median_vol \
        "$dir/*space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz"
}

04_tat2_main() {
  mkdir -p /Volumes/Hera/Datasets/adept/tat2/
  mapfile -t DIRS < <(args-or-all-glob "$root"/data/fmriprep/'sub-*/ses-*/func' "$@")
  for d in "${DIRS[@]}"; do
     tat2_dir "$d"
  done
  return 0
}

# if not sourced (testing), run as command
eval "$(iffmain "04_tat2_main")"

getses_test() { #@test
   local output
   run get_ses /Volumes/Hera/Datasets/adept/data/fmriprep/sub-0008/ses-01/func/
   [[ $output == sub-0008_ses-01 ]]
}
