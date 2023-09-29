# Adept R2'
[R2'](https://github.com/LabNeuroCogDevel/r2prime-prisma) and [tat2](https://lncd.github.io/lncdtools/tat2) for [Wellcome Leap](https://wellcomeleap.org/) ADEPT

## Data

The numbered scripts create files in `../data`. `make` (see [`Makefile`](Makefile)) will run only needed scripts for updates in raw.

```
../data
├── raw        # 01_oac_sync.bash (rsync)
├── BIDS       # 02_bids.bash, 02x_2_fill_missing_json.bash
├── r2prime    # 03_r2prime.bash
├── fmriprep   # 03_fmriprep.bash
└── tat2       # 04_tat2.bash
```

