#!/bin/bash

#This script processes 7T Terra MP2RAGE data.
#The processing pipeline includes:
	#UNI and INV2 dicom to nifti conversion
	#structural brain masking
	#ANTS N4 bias field correction
	#FSL FAST (for tissue segmentation and gray matter probability maps)
	#UNI to MNI registration with ANTS SyN (rigid+affine+deformable syn)

#######################################################################################################
## DEFINE PATHS ##
structural=/project/bbl_roalf_7tglucestage/sandbox/structural_out #path for processed structural output
# dicoms=/project/bbl_data/syrp/sandbox/sydnor_pmacsv/GluCEST_BASReward_Project_dummy/Dicoms #path to dicoms
base=/project/bbl_roalf_7tglucestage/sandbox/ #project path
ANTSPATH=/appl/ANTs-2.3.1/bin/
log=/project/bbl_roalf_7tglucestage/sandbox/logs/structural
#######################################################################################################

#######################################################################################################
## IDENTIFY CASES FOR PROCESSING ##

# for i in $(ls $dicoms)
# do

#case=${i##*/}
case=153043_108000
echo "CASE: $case"

# if ! [ -d $structural/$case ] && [ -d $dicoms/$case/*mp2rage_mark_ipat3_0.80mm_INV2 ] && [ -d $dicoms/$case/*mp2rage_mark_ipat3_0.80mm_UNI_Images ]

# then
logfile=$log/$case.log
{
echo "--------Processing structural data for $case---------"
sleep 1.5
# mkdir $structural/$case
mkdir $structural/$case/fast
mkdir $structural/$case/MNI_transforms
mkdir $structural/$case/atlases
mkdir $structural/$case/log_files #Store logfile and intermediate files here.
log_files=$structural/$case/log_files
#######################################################################################################
## STRUCTURAL DICOM CONVERSION ##

#convert UNI
# /project/bbl_projects/apps/melliott/scripts/dicom2nifti.sh -u -F $structural/$case/$case-UNI.nii $dicoms/$case/*mp2rage_mark_ipat3_0.80mm_UNI_Images/*dcm
# gzip $structural/$case/$case-UNI.nii $structural/$case/$case-UNI.nii.gz

#convert INV2
# /project/bbl_projects/apps/melliott/scripts/dicom2nifti.sh -u -F $structural/$case/$case-INV2.nii $dicoms/$case/*mp2rage_mark_ipat3_0.80mm_INV2/*dcm
# gzip $structural/$case/$case-INV2.nii $structural/$case/$case-INV2.nii.gz
#######################################################################################################
## STRUCTURAL BRAIN MASKING ##

#create initial mask with BET using INV2 image
bet $structural/$case/$case-INV2.nii.gz $structural/$case/$case -m -f 0.2
mv -f $structural/$case/$case.nii.gz $log_files/$case.nii.gz

# generate final brain mask
fslmaths $structural/$case/$case-UNI.nii.gz -mul $structural/$case/${case}_mask.nii.gz $structural/$case/$case-UNI-masked.nii.gz
mv -f $structural/$case/${case}_mask.nii.gz $log_files/${case}_mask.nii.gz

fslmaths $structural/$case/$case-UNI-masked.nii.gz -bin $structural/$case/$case-mask.nii.gz
fslmaths $structural/$case/$case-mask.nii.gz -ero -kernel sphere 1 $structural/$case/$case-UNI-mask-er.nii.gz
mv -f $structural/$case/$case-mask.nii.gz $log_files/$case-mask.nii.gz

#Apply finalized eroded mask to UNI image
fslmaths $structural/$case/$case-UNI.nii.gz -mas $structural/$case/$case-UNI-mask-er.nii.gz $structural/$case/$case-UNI-masked.nii.gz
fslmaths $structural/$case/$case-INV2.nii.gz -mas $structural/$case/$case-UNI-mask-er.nii.gz $structural/$case/$case-INV2-masked.nii.gz
#######################################################################################################
## BIAS FIELD CORRECTION ##

N4BiasFieldCorrection -d 3 -i $structural/$case/$case-UNI-masked.nii.gz -o $structural/$case/$case-UNI-processed.nii.gz
N4BiasFieldCorrection -d 3 -i $structural/$case/$case-INV2-masked.nii.gz -o  $structural/$case/$case-INV2-processed.nii.gz
#######################################################################################################
## FAST TISSUE SEGMENTATION ##

fast -n 3 -t 1 -g -p -o $structural/$case/fast/$case $structural/$case/$case-INV2-processed.nii.gz
#######################################################################################################
## UNI TO MNI152 0.8MM BRAIN REGISTRATION ##

#register processed UNI to upsampled MNI T1 template
# MNI152 T1 1mm template was upsampled to match UNI voxel resolution:
# ResampleImage 3 MNI152_T1_1mm_brain.nii.gz MNI152_T1_0.8mm_brain.nii.gz 0.8223684430X0.8223684430X0.8199999928 0 4
antsRegistrationSyN.sh -d 3 -f $structural/MNI_Templates/MNI/MNI152_T1_0.8mm_brain.nii.gz \
-m $structural/$case/$case-UNI-processed.nii.gz -o $structural/$case/MNI_transforms/$case-UNIinMNI-
#######################################################################################################
#clean up

mv $structural/$case/$case-UNI.nii.gz $log_files/$case-UNI.nii.gz
mv $structural/$case/$case-INV2.nii.gz $log_files/$case-INV2.nii.gz
mv $structural/$case/*log  $log_files/


echo -e "\n$case SUCCESFULLY PROCESSED\n\n\n"
} | tee "$logfile"
# else
echo "$case is either missing structural dicoms or already processed. Will not process"
sleep 1.5
# fi

done
