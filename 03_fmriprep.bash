#!/usr/bin/env bash
#
# run fmriprep on ADEPT/LEAP
#
# 20230622WF - init
# 20230919WF - input arg can be anything with sub+ses to run (but not rerun)
#              see Makefile for running
#
args=""
[ $# -gt 1 ] && warn "cannot run on more than one ses. no args is al" && exit 1

if [[ $* =~ (sub-[0-9]{4}).*ses-([0-9]+) ]]; then
   subj="${BASH_REMATCH[1]}"
   ses="${BASH_REMATCH[2]}"
   if ! test -r "txt/filters/ses-$ses.json"; then
     mkdir -p txt/filters/
     bids-filter "$ses" '*' 'guess' | drytee "txt/filters/ses-$ses.json"
   fi
   args="--participant-label $subj --bids-filter /filters/ses-$ses.json"

    out_file="../data/fmriprep/$subj/ses-$ses/func/${subj}_ses-${ses}_task-guess_run-01_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz"
   if [ -r "$out_file" ]; then
      echo "# $out_file already exists!"
      exit 0
   else 
      echo "# making $out_file"
   fi


   [ "$(pgrep -af "docker.*fmriprep.*$subj.*ses-$ses" |wc -l)" -gt 0 ] &&
      warn "already running, skipping" &&
      exit 0
else
   [ $# -ne 0 ] && warn "no sub-.*ses- in input arg '$1'" && exit 1
fi

! test -r ../data/fmriprep_working/db/layout_index.sqlite &&
 dryrun docker \
   run  --rm \
   -v "$PWD/../data/BIDS/":/BIDS:ro \
   -v "$PWD/../data/fmriprep_working/db":/db \
   --entrypoint /opt/conda/envs/fmriprep/bin/pybids \
   nipreps/fmriprep:23.1.2 \
    layout /BIDS /db --no-validate --index-metadata

# want args to be split 
# shellcheck disable=SC2086
dryrun docker \
   run --rm \
   -v /Volumes/Hera/:/Volumes/Hera/:ro \
   -v "$PWD/../data/BIDS/":/BIDS:ro \
   -v "$PWD/txt/filters/":/filters:ro \
   -v "$PWD/../data/fmriprep/":/out \
   -v "$PWD/../data/fmriprep_working/":/working \
   -v "$PWD/../data/fmriprep_working/db":/db \
   -v ~/.cache/templateflow/:/home/fmriprep/.cache/templateflow \
   -v /opt/ni_tools/freesurfer/license.txt:/opt/freesurfer/license.txt \
   nipreps/fmriprep:23.1.2 \
   /BIDS /out participant \
   -w /working --nproc 16 --skip_bids_validation \
   `# --bids-database-dir /db` \
   $args

#mkmissing    -1 '../data/BIDS/sub-*/ses-*/func/*bold.json'    -2 '../data/fmriprep/sub-*/ses-*/func/*bold.nii.gz'    -p 'sub-\d+/ses-\d+'|parallel -j1 ./03_fmriprep.bash

