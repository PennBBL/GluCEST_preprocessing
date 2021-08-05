#!/bin/bash

#This script calculates GluCEST contrast and gray matter density measures

#######################################################################################################
## DEFINE PATHS ##

# structural=/data/jux/BBL/projects/sydnor_glucest/GluCEST_BASReward_Project/Structural #path to processed structural data
cest=/project/bbl_roalf_7tglucestage/sandbox/cest_out #path to processed GluCEST data
outputpath=/project/bbl_roalf_7tglucestage/sandbox/output_measures
#
# while read line
# do
# case=$line
# mkdir $outputpath/$case
# done < /data/jux/BBL/projects/sydnor_glucest/GluCEST_BASReward_Project/GluCEST_BASReward_Caselist_N45.txt

################### JOELLE JEE AUG 3, 2021  #######################
# HARVARD OXFORD
case=153043_108000
mkdir $outputpath/$case
touch $outputpath/GluCEST-HarvardOxford-Measures.csv
echo "Subject	HarvardOxford_CEST_mean	HarvardOxford_CEST_numvoxels	HarvardOxford_CEST_SD" >> $outputpath/GluCEST-HarvardOxford-Measures.csv
# while read line
# do

#quantify GluCEST contrast for each participant
3dROIstats -mask $cest/$case/atlases/$case-2d-HarvardOxford-cort.nii.gz \
-zerofill NaN -nomeanout -nzmean -nzsigma -nzvoxels -nobriklab -1DRformat \
$cest/$case/$case-GluCEST.nii.gz >> $outputpath/$case/$case-HarvardOxfordROI-GluCEST-measures.csv
#format participant-specific csv
sed -i 's/name/Subject/g' $outputpath/$case/$case-HarvardOxfordROI-GluCEST-measures.csv
cut -f2-3 --complement $outputpath/$case/$case-HarvardOxfordROI-GluCEST-measures.csv >> $outputpath/$case/tmp.csv
mv $outputpath/$case/tmp.csv $outputpath/$case/$case-HarvardOxfordROI-GluCEST-measures.csv

#quantify GluCEST contrast for each participant
3dROIstats -mask $cest/$case/atlases/$case-2d-HarvardOxford-cort-bin.nii.gz \
-zerofill NaN -nomeanout -nzmean -nzsigma -nzvoxels -nobriklab -1DRformat \
$cest/$case/$case-GluCEST.nii.gz >> $outputpath/$case/$case-HarvardOxford-GluCEST-measures.csv
#format participant-specific csv
sed -i 's/name/Subject/g' $outputpath/$case/$case-HarvardOxford-GluCEST-measures.csv
cut -f2-3 --complement $outputpath/$case/$case-HarvardOxford-GluCEST-measures.csv >> $outputpath/$case/tmp.csv
mv $outputpath/$case/tmp.csv $outputpath/$case/$case-HarvardOxford-GluCEST-measures.csv
#enter participant GluCEST contrast data into master spreadsheet
#sed -n "2p" $outputpath/$case/$case-HarvardOxford-GluCEST-measures.csv >> $outputpath/GluCEST-HarvardOxford-Measures.csv
# done < /data/jux/BBL/projects/sydnor_glucest/GluCEST_BASReward_Project/GluCEST_BASReward_Caselist_N45.txt
