#!/bin/ksh
#export APP_NAME=omtsmgr
#Implimented By --Manas
#Date : 17.11.2017

# Script using to extract and upload the files batch wise to take care of memory issue

#exit 0

echo  ---------------------------------------------------------------------------
 echo Loading GL transaction Files `date`
echo ---------------------------------------------------------------------------
 export DAYTIME=`date +%Y%m%d_%H%M%S`
 export LOG=/opt/FAST/CORP_BI/GL_Script/LogFiles 
 export SH=/opt/FAST/CORP_BI/GL_Script
export CONFIG=/opt/FAST/config
  
#ksh /home/omtsmgr/FAST/sh/EXPORT_REV_TBL_REFRESH.ksh
#if [ $? -gt 0 ]                                                                 		### Checking the result code to check status of mail 
#then	
#		echo -e "Error Occurred while loading REVENUE intermediate table " | mailx -s "$DAY : REVENUE Intermediate Data Load failed In $ENV" `cat $CONFIG/corp_bi_bcc_list.txt`
#fi
sleep 900

ksh $SH/FAST_CORP_BI_GL_File_Extract_Upload.ksh
echo "execute successfully" 
exit 0

