#!/bin/ksh
#export APP_NAME=omts
#Implimented By --Manas
#Date : 17.11.2017

# Script using to extract and upload the files batch wise to take care of memory issue

echo  ---------------------------------------------------------------------------
 echo Loading GL transaction Files `date`
echo ---------------------------------------------------------------------------

 export LOG=/home/omtsmgr/CORP_BI/GL_Script/LogFiles 
 export SH=/home/omtsmgr/CORP_BI/GL_Script

 #ksh $SH/extract1.ksh>$LOG/extract1log.log
 #ksh $SH/SFTP_Upload.ksh>$LOG/upload1log.log

 #ksh $SH/extract2.ksh>$LOG/extract2log.log
 #ksh $SH/SFTP_Upload.ksh>$LOG/upload2log.log
 
 #ksh $SH/extract3.ksh>$LOG/extract3log.log
 #ksh $SH/SFTP_Upload.ksh>$LOG/upload3log.log
 
 #ksh $SH/extract4.ksh>$LOG/extract4log.log
 #ksh $SH/SFTP_Upload.ksh>$LOG/upload4log.log

 #ksh $SH/extract5.ksh>$LOG/extract5log.log
 #ksh $SH/SFTP_Upload.ksh>$LOG/upload5log.log

 #ksh $SH/extract6.ksh>$LOG/extract6log.log
 #ksh $SH/SFTP_Upload_end.ksh>$LOG/upload6log.log

 ksh ISS_Tidal_Trigger_SWAIR_DAILY_EXECUTIVE_REP.ksh>/home/omtsmgr/EXECUTIVE_REPORT/LOG/TriLead_Log.log
