# Adept R2'
[R2'](https://github.com/LabNeuroCogDevel/r2prime-prisma) and [tat2](https://lncd.github.io/lncdtools/tat2) for [Wellcome Leap](https://wellcomeleap.org/) ADEPT

## Data

The numbered scripts create files in `../data`. `make` (see [`Makefile`](Makefile)) will run only needed scripts for updates in raw.

```
../data
├── raw        # 01_oac_sync.bash (rsync)
├── BIDS       # 02_bids.bash, 02x_2_fill_missing_json.bash
├── r2prime    # 02_organize_nii.bash, 03_r2prime.bash
├── fmriprep   # 03_fmriprep.bash
└── tat2       # 04_tat2.bash
```

## Local
This repository's primary home is `rhea:/Volumes/Hera/Datasets/adept/scripts`

## R2'

R2Prime here does not take advantage of the newer BIDS-capable [main pipeline](https://github.com/LabNeuroCogDevel/r2prime-prisma). `02_organize_nii.bash` subverts the BIDS input that would be handled by `r2prime-bids`. Instead `03_r2prime.bash` uses the r2prime repo's internal `r2prime` script on Olafsson's original file structure.

## nT2\*\/tat2

`tat2` should be inversely correlated to `R2'`. To compare, we need minimally processed BOLD. Using task ("guess") only and avoiding multi-echo rest until we can confirm ME tat2 looks like single echo.

### template json
Raw is nifti with sometimes missing `.json` side car. `02x_2_fill_missing_json.bash` creates a template json to use when missing. Scan specific keys to remove were idnetified with

```
diff \
  <(jq . ../data/BIDS/sub-0008/ses-01/func/sub-*_task-guess_run-01_bold.json)\
  <(jq . ../data/BIDS/sub-0015/ses-01/func/sub-*task-guess_run-01_bold.json)
```
