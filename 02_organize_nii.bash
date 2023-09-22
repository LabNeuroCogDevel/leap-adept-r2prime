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

echo_times(){
   # save as 1D file with rows for 3dcalc
   # from 3dTstat:
   #  1D files read into 3dXXX programs are interpreted as
   #  having the time direction along the rows rather than down the columns.
   mapfile -t json < <(find "$1" -iname '*json' -not -iname '*_ph.json')
   [ ${#json[@]} -eq 0 ] && return #warn "# no json for $1" && return
   jq -r .EchoTime*1000 "${json[@]}" #|paste -sd' ';
}

rm_not_tr_cnt(){
   ! test -r "$1" && return 0
   ! test -s "$1" && warn "$1 is empty" && dryrun rm "$1" && return 0
   nline=$(wc -l < "$1")
   ntr=$(test -r "$2" && 3dinfo -nt "$2" || echo -1)
   [ "$nline" -ne "$ntr" ] && warn "# WARN: $1 has $nline lines not $ntr of $2" && dryrun rm "$1"
   return 0
}
bucket_expected(){
   nii="$1"; shift
   n="$1"; shift
   [ $# -ne "$n" ] && warn "ERROR: would make '$nii' w/ $# volumes; expect $n ($*)" && return 1
   test -r "$nii" ||
      dryrun 3dbucket -prefix "$_" "$@"
}

setup_r2prime() {
   indir="$1"
   out=$(mk_outdir "$indir")
   for checkd in "$indir"/anat[_-]{mT2,mT2star}/; do
      ! test -d "$checkd" && echo "ERROR: missing $checkd" && return 1
   done
   last_anat=$(find "$indir/anat"[_-]T1w_acq[_-]mprage/*.nii.gz |tail -n1)
   [ -z "$last_anat" ] && echo "ERROR: no anat in $indir!" && return 2

   # anat-mT2  anat-mT2star  anat-mT2star_1  anat-T1w_acq-mprage
   test -d "$out" ||
      dryrun mkdir -p "$out"

   # tse is mt

   bucket_expected "$out"/mtse.nii.gz 3 "$indir/anat"[_-]mT2/*[^h].nii.gz
   # DISABLE SC2010 SC2046
   bucket_expected "$out"/mgre_mag.nii.gz 4 "$indir/anat"[_-]mT2star/*[^h].nii.gz
   if test -d "$indir"/anat[_-]mT2star_1/; then
      bucket_expected "$out"/mgre_pha.nii.gz 4 "$indir/anat"[_-]mT2star_1/*.nii.gz
   else
      bucket_expected "$out"/mgre_pha.nii.gz 4 "$indir/anat"[_-]mT2*/*_ph*.nii.gz
   fi

   test -r "$out/anat_fast.nii.gz" ||
      dryrun 3dcopy "$last_anat" "$_"

   # record echo times
   test -r "$out/gre_echo_times.1D" ||
      echo_times "$indir/"anat[_-]mT2star|drytee "$_"
   test -r "$out/tse_echo_times.1D" ||
      echo_times "$indir/"anat[_-]mT2|drytee "$_"

   # when json is missing, still made empty file
   rm_not_tr_cnt "$out/tse_echo_times.1D" "$out"/mtse.nii.gz
   rm_not_tr_cnt "$out/gre_echo_times.1D" "$out"/mgre_mag.nii.gz

}

02_organize_nii_main() {
  [ $# -eq 0 ] && echo "USAGE: $0 [all|path/to/rawdir/ path/to/another/]" && exit 1
  [[ "$1" == "all" ]] &&
     indirs=(../data/raw/*[0-9][0-9][0-9][0-9]/ses-*/) ||
     indirs=("$@")
  for d in "${indirs[@]}"; do
     echo "# $d"
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

echotime_test() { #@test
 local output
 run echo_times ../data/raw/ADEPT0015/ses-01/anat-mT2star
 [[ "${output//[^0-9.]/ }" == "3.82 8 18 23" ]]
}

