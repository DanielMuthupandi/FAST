#!/bin/ksh
#export APP_NAME=omtsmgr
#Implimented By --Manas
#Date : 17.11.2017

# Script using to extract and upload the files batch wise to take care of memory issue

echo  ---------------------------------------------------------------------------
 echo Loading GL transaction Files `date`
echo ---------------------------------------------------------------------------
 export DAYTIME=`date +%Y%m%d_%H%M%S`
 export LOG=/home/omtsmgr/CORP_BI/GL_Script/LogFiles 
 export SH=/home/omtsmgr/CORP_BI/GL_Script


if [ -f $SH/Views_Name.txt ]
then
	sleep 2000
	ksh $SH/FAST_CORP_BI_GTM_File_Extract_Upload.ksh
	echo " execute successfully"
else
	ksh $SH/FAST_CORP_BI_GTM_File_Extract_Upload.ksh
	echo " execute successfully"
	fi
exit 0
