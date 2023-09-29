DOCKERFMRIPREP=nipreps/fmriprep:23.1.2

# disable implict rules for easier -d debugging
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

# dont remove any intermediates
.SECONDARY:


# input files
JSONS := $(wildcard ../data/BIDS/sub-*/ses-*/func/*_bold.json)
# output files
PREPROC := $(subst _bold.json,_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz,$(subst /BIDS/,/fmriprep/, $(JSONS)))

# 'all' depends on PREPROC which is created from json names
# this will then run specific frmprep for each prerpoc file
# echoing all depends for debug/verbose. has no effect
all: $(PREPROC)
	echo $^|grep -Po 'task-[^_]*' | sort |uniq -c

# DICOM DATABASE
# changes when we get a new json file
../data/fmriprep_working/db/layout_index.sqlite: $(JSONS)
	dryrun docker \
	   run -it --rm \
	   -v "$(PWD)/../data/BIDS/":/BIDS:ro \
	   -v "$(PWD)/../data/fmriprep_working/db":/db \
	   --entrypoint /opt/conda/envs/fmriprep/bin/pybids \
	   $(DOCKERFMRIPREP) \
	    layout /BIDS /db --no-validate --index-metadata --reset-db

# fmriprep. only running on guess_run*. use run-01 to check if done
# depends on json (and nii.gz), but will almost certanly not need to be rurun if output already exisits (json shouldn't change)
# but does depend on db existing
#  DB will change, but dont need to rerun b/c of update
../data/fmriprep/sub-%_task-guess_run-01_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz: | ../data/fmriprep_working/db
	./03_fmriprep.bash $@

# tat2 depends on func directory.
# right now we are only buiding guess bold.
# but future might want mutliecho rest as well
# need secondary expansion b/c we would otheriwse repeat %
.SECONDEXPANSION:
../data/fmriprep/sub-%/func/: ../data/fmriprep/sub-$(subst _,/,$$*)/func/sub-$(subst /,_,$$*)_task-guess_run-01_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz
	echo $@: $^

# % => sub-0004_ses-01
.SECONDEXPANSION:
../data/tat2/%_tat2.nii.gz: ../data/fmriprep/$(subst _,/,$$*)/func/
	echo ./04_tat2.bash  $^
