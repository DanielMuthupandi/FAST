
export DAYTIME=`date +%Y%m%d_%H%M%S`

export DUMMY_PATH=/home/omtsmgr/CORP_BI/DUMMY_SCRIPT
export SH_PATH=/home/omtsmgr/CORP_BI/Dumm2


#Renames the original ksh script to _DUMMY script.

#mv (option) filename1.ext filename2.ext

echo "Renaming the DUUMY file to Original file."

mv $SH_PATH/VRT_TIDAL_TRIGGER_CORP_BI_GTM_DAILY_EXTRACT_AND_UPLOAD_DUMMY.ksh $SH_PATH/VRT_TIDAL_TRIGGER_CORP_BI_GTM_DAILY_EXTRACT_AND_UPLOAD.ksh

echo " Activation completed"

exit 0