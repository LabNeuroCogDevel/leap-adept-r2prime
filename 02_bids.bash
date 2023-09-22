#!/usr/bin/env bash
#
# organize BIDS for fmriprep
#
# 20230622WF - init
#
bids_name(){
   file="$1"; shift
   #../data/raw/ADEPT0143/ses-01/anat-T1w_acq-mprage/1_3_12_2_1107_5_2_43_166114_2023042612043265100937431_0_0_0_anat-T1w_acq-mprage_20230426115726_5.nii.gz
   #../data/raw/ADEPT0143/ses-01/func-bold_task_guess_run-01/1_3_12_2_1107_5_2_43_166114_2023042612070487319639125_0_0_0_func-bold_task_guess_run-01_20230426115726_9.json
   ! [[ $file =~ raw/ADEPT([0-9]{4})/ses-([0-9]+).*(json|nii.gz)$ ]] &&
      warn "'$file': not an ADEPT session nii or json" && return 1
   id=${BASH_REMATCH[1]}
   ses=${BASH_REMATCH[2]}
   ext=${BASH_REMATCH[3]}
   case $file in
      *T1w_acq[_-]mprage*)
         echo "sub-$id/ses-$ses/anat/sub-${id}_ses-${ses}_acq-mprage_T1w.$ext"
         ;;
      *func[_-]bold[_-]task[_-]guess[_-]run*)
         ! [[ $file =~ run[_-]([0-9]+) ]] && warn "$file: func but no run num"
         run=${BASH_REMATCH[1]}
         imgtype=bold
         [[ $file =~ SBRef ]] && imgtype=sbref
         echo "sub-$id/ses-$ses/func/sub-${id}_ses-${ses}_task-guess_run-${run}_$imgtype.$ext"
         ;;
         *)  warn "$file: unexpected filename" && return 1;;
      esac
}
link_bids(){
   from="$1";shift
   to=../data/BIDS/"$1"; shift
   test -e "$to" && return 0

   from_abs=$(readlink -f "$from")
   test ! -r "$from_abs" && warn "'$from_abs' ($from) DNE!?" && return 1
   test -d "$(dirname "$to")" || dryrun mkdir -p "$_"
   dryrun ln -s "$from_abs" "$to"
}

02_bids_main() {
  cd "$(dirname "$0")" || exit 1
  find ../data/raw  \
     -type f \
       \( -ipath '*T1*' -or -ipath '*bold*' \) -and \
       \( -iname '*nii.gz' -or -iname '*.json' \) -and \
       -not -path '*/ADEPT200/*' |
   while read -r f; do
     #echo "# $f"
     new="$(bids_name "$f")" || continue
     #echo "#  -> $new"
     link_bids "$f" "$new"
  done

  /opt/ni_tools/npm/bin/bids-validator ../data/BIDS/
}

# if not sourced (testing), run as command
eval "$(iffmain "02_bids_main")"

####
# testing with bats. use like
#   bats ./02_bids.bash --verbose-run
####
bids_name() { #@test
   local output
   run bids_name ../data/raw/ADEPT0143/ses-01/anat-T1w_acq-mprage/1_3_12_2_1107_5_2_43_166114_2023042612043265100937431_0_0_0_anat-T1w_acq-mprage_20230426115726_5.nii.gz
   [[ $output =~ sub-0143/ses-01/anat/sub-0143_ses-01_acq-mprage_T1w.nii.gz ]]
   run bids_name ../data/raw/ADEPT0143/ses-01/func-bold_task_guess_run-01/1_3_12_2_1107_5_2_43_166114_2023042612070487319639125_0_0_0_func-bold_task_guess_run-01_20230426115726_9.json
   [[ $output =~ sub-0143/ses-01/func/sub-0143_ses-01_task-guess_run-01_bold.json ]]
}
