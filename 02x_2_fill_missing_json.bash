jqdel(){
   jq '.|del(.ShimSetting,.WipMemBlock,.TxRefAmp,.ImageOrientationPatientDICOM,.AcquisitionTime,.SAR,.ImagingFrequency)' "$@"
}

test -r json_template.json || 
   jqdel  ../data/BIDS/sub-0008/ses-01/func/sub-0008_ses-01_task-guess_run-01_bold.json > json_template.json

for f in ../data/BIDS/sub-*/ses-*/func/*_bold.nii.gz; do
   test -r "${f/.nii.gz/.json}"||
      ln -s "$(pwd)/json_template.json"  "$_"
done

