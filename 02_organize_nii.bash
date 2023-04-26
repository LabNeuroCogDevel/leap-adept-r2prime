#!/usr/bin/env bash
#
# combine dcm2nii single echo niftis and label for r2prime script
#
#  DRYRUN=1 ./02_organize_nii.bash ../data/raw/ADEPT0004/ses-01/
#
# 20230426WF - init
#
mk_outdir(){
   [[ $1 =~ (ADEPT[0-9]{4}).*(ses-[0-9]+) ]] || return 1
   id="${BASH_REMATCH[1]}"
   ses="${BASH_REMATCH[2]}"
   echo "../data/r2prime/${id}/$ses"
}

setup_r2prime() {
   indir="$1"
   outdir=$(mk_outdir "$indir")
   for checkd in "$indir"/anat-{mT2,mT2star{,_1},T1w_acq-mprage}/; do
      ! test -d "$checkd" && echo "ERROR: missing $checkd" && return 1
   done
   # anat-mT2  anat-mT2star  anat-mT2star_1  anat-T1w_acq-mprage
   dryrun mkdir -p "$out"
   test -r "$out"/mtse.nii.gz ||
      dryrun 3dbucket -prefix "$_" "$indir/anat-mT2/"*.nii.gz
   test -r "$out"/mgre_mag.nii.gz ||
      dryrun 3dbucket -prefix "$_" "$indir/anat-mT2star/"*.nii.gz
   test -r "$out"/mgre_pha.nii.gz  ||
      dryrun 3dbucket -prefix "$_" "$indir/anat-mT2star_1/"*.nii.gz
   test -r "$out/anat_fast.nii.gz" ||
      dryrun 3dcopy "$indir/anat-T1w_acq-mprage"/*.nii.gz  "$_"
}

02_organize_nii_main() {
  [ $# -eq 0 ] && echo "USAGE: $0 [all|path/to/rawdir/ path/to/another/]" && exit 1
  [[ "$1" == "all" ]] &&
     indirs=(../data/raw/*/ses-*/) ||
     indirs=("$@")
  for d in "${indirs[@]}"; do
     setup_r2prime "$d" || continue
  done
  return 0
}

# if not sourced (testing), run as command
eval "$(iffmain "02_organize_nii_main")"

####
# testing with bats. use like
#   bats ./02_organize_nii.bash --verbose-run
####
outdir_test() { #@test
  local output
  run mk_outdir a/b/c/data/raw/ADEPT0004/ses-01/
  [[ $output = "../data/r2prime/ADEPT0004/ses-01" ]]
}
02_organize_nii_main_test() { #@test
   DRYRUN=1 run 02_organize_nii_main ../data/raw/ADEPT0004/ses-01/
   [[ $output =~ mkdir ]]
}
