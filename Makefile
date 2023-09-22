
DOCKERFMRIPREP=nipreps/fmriprep:23.1.2

# input files
JSONS := $(wildcard ../data/BIDS/sub-*/ses-*/func/*_bold.json)
# output files
PREPROC := $(subst _bold.json,_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz,$(subst /BIDS/,/fmriprep/, $(JSONS)))

all: $(PREPROC)

../data/fmriprep_working/db/layout_index.sqlite: $(JSONS)
	dryrun docker \
	   run -it --rm \
	   -v "$(PWD)/../data/BIDS/":/BIDS:ro \
	   -v "$(PWD)/../data/fmriprep_working/db":/db \
	   --entrypoint /opt/conda/envs/fmriprep/bin/pybids \
	   $(DOCKERFMRIPREP) \
	    layout /BIDS /db --no-validate --index-metadata

../data/fmriprep/sub-%_task-guess_run-01_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz: | ../data/fmriprep_working/db
	./03_fmriprep.bash $@

