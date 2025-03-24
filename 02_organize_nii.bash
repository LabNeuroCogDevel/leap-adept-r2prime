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

seqnum(){ printf "%s\n" "$@" | grep -Po '[0-9]+$'; }
is_sequential(){ 
  local first second
  first=$(seqnum "${1:?first seq}")
  second=$(seqnum "${2:?second seq}")
  seq_diff=$(( "$second" - "$first" ))
  #echo " $second - $first = $seq_diff" >&2
  [ $seq_diff -eq 1 ]
}
order_seqnum(){
   for d in "$@"; do
      seqnum "$d" |sed "s:$:\t$d:"
   done | sort -rn | cut -f2 
}
last_seqnum(){
   order_seqnum "$@" |sed 1q
}

setup_r2prime() {
   indir="$1"
   out=$(mk_outdir "$indir")

   # skip if looks complete
   test -r "$out"/mgre_pha.nii.gz -a\
        -r "$out"/mgre_mag.nii.gz -a \
        -r "$out"/mtse.nii.gz -a \
        -r "$out"/anat_fast.nii.gz &&
        echo "# have all inputs for '$out'; skipping" && return 0

   if [ -n "$(find "$indir"/mT2star*_256x256.*/ -maxdepth 1 -type d 2>/dev/null)" ]; then
      echo "WARN: $indir not anat-mT2star but 'mT2star_256x256.[0-9]*' (20241015)"
      # ../data/raw/ADEPT0312/ses-02/mT2_256x256.21
      # ../data/raw/ADEPT0312/ses-02/mT2-repeat_256x256.25
      # ../data/raw/ADEPT0312/ses-02/mT2star_256x256.22
      # ../data/raw/ADEPT0312/ses-02/mT2star_256x256.23
      mt2=$(last_seqnum "$indir"/mT2[^s]*)
      mt2_star_mag=$(order_seqnum "$indir"/mT2star* | sed '2q'|sed -n '$p') 
      mt2_star_ph=$(last_seqnum "$indir"/mT2star*)
      echo -e "    mt2: $mt2;\n    mag: $mt2_star_mag;\n    pha: $mt2_star_ph;" >&2
      if [ -z "$mt2" ] || [ -z "$mt2_star_mag" ]; then
         echo "ERROR: $indir missing mt2 ($mt2) or t2s ($mt2_star_mag)";
         return 2
      fi
      [[ "$mt2_star_ph" == "$mt2_star_mag" ]] && echo "ERROR missing mag or phase (only have $mt2_star_mag)" && return 3
      [ -z "${OKAY_NONSEQ:-}" ] && ! is_sequential "$mt2" "$mt2_star_mag"  &&
         echo "ERROR: not sequential '$mt2' '$mt2_star_mag'; retry with OKAY_NONSEQ=1 $0 $*" && return 3

      echo "T2ODD: mt2:'$mt2' mag:'$mt2_star_mag' pha:'$mt2_star_ph'" >> txt/org_log.txt
      ! test -r "$indir"/anat-mT2 &&  dryrun ln -fs "$(realpath "$mt2")" "$_"
      ! test -r "$indir"/anat-mT2star && dryrun ln -fs "$(realpath "$mt2_star_mag")" "$_"
      ! test -r "$indir"/anat-mT2star_1 && dryrun ln -fs "$(realpath "$mt2_star_ph")" "$_"

   fi

   odd_mprage=$(last_seqnum "$indir"/anat*mprage_320x300.* 2>/dev/null)
   if [ -n "$odd_mprage" ] && [ -r "$odd_mprage" ]; then
      echo "# WARNING: odd mprage: $odd_mprage"
      ! test -r "$indir"/anat-T1w_acq-mprage &&  dryrun ln -fs "$(realpath "$odd_mprage")" "$_"
      echo "MPRAGE: $odd_mprage" >> txt/org_log.txt
   fi

   # have mT2 instead of anat-mT2
   # ERROR: missing ../data/raw/ADEPT0026/ses-02//anat[-_]*mT2/
   for d in mT2{,star,star_1}; do
      expected="$indir/anat-$d"
      [ -r "$expected" ] && continue
      noanat="$indir/$d"
      [ ! -d "$noanat" ] && continue
      dryrun ln -s "$(readlink -f "$noanat")" "$expected"
   done

   for checkd in "$indir"/anat[-_]*{mT2,mT2star}/; do
      ! test -d "$checkd" && echo "ERROR: missing $checkd (have $(ls -d "$indir"/*/))" && return 1
   done

   for d in "$indir"/anat[-_]{mT2,mT2star,mT2star_1,T1w_acq[-_]mprage}; do
      if [ -z "$(find -L "$d" -iname '*nii.gz' -print -quit)" ]; then
         echo "# WARNING: missing nifti '$d'";
         d=${d/\[-_]/-} # default to e.g. 'anat-mT2' if niehter '_' or '-' matched
         rawdir="$(readlink -f "$d"|sed s:.*/raw/:/mnt/oac_share/Forbes\ ADEPT/Data/Analysis/raw/completed/:)"
         [ ! -d "$rawdir" ] && echo "ERROR: no nii.gz and no '$rawdir'" && return 2
         [ -z "$(find -L "$rawdir" -iname 'MR*' -print -quit)" ] && echo "NO DICOM in $rawdir" && return 4
         (dryrun dcm2niix -o "$d" "$rawdir" )
         echo "DICOM: '$rawdir' '$d'" >> txt/org_log.txt
      fi
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

   echo "# $out"

}

02_organize_nii_main() {
  [ $# -eq 0 ] && echo "USAGE: $0 [all|../data/raw/ADEPT0015/ses-01/ path/to/rawdir/ path/to/another/]" && exit 1
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

seq_num_test() { #@test
 local output
 run seqnum xyz.10x20.4
 [[ $output == "4" ]]

 run seqnum abc.40x20.130
 [[ $output == "130" ]]
}

is_sequential_test() { #@test
   local status
   run is_sequential abc.9 zyx.10
   [[ $status -eq 0 ]]
   run is_sequential abc.12 xyz.9
   [[ $status -ne 0 ]]
   run is_sequential abc.3 xyz.5 
   [[ $status -ne 0 ]]
}
