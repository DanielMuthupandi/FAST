#!/bin/ksh
#
#    version         1.2
#    author          Dharmatheja Bhat
#    Updated by      Rajesh Chava


#    HISTORY
#    24/01/2018 : Script Creation
#    16/07/2018 : routing all Logs,VSQL,ERROR Directory,ERRORARCHIVEDIR,CONFIG,ARCHIVE,MULE_TOUCH_FILE_ARCHIVE paths to MOUNTPATH(/opt/FAST) and MULE_TOUCH_FILE_PATH,MULE_TOUCH_ERRORFILE_PATH, Executive Report Path to COMMONPATH(/home/omtsmgr/FAST)
#    20/07/2018 : routing all Logs,VSQL,ERROR Directory,ERRORARCHIVEDIR,CONFIG,ARCHIVE,MULE_TOUCH_FILE_ARCHIVE,MULE_TOUCH_FILE_PATH,MULE_TOUCH_ERRORFILE_PATH paths to new MOUNTPATH(/opt/FAST) from (/home/omtsmgr/FAST)

###################################### DESCRIPTION #########################################
#	This script checks duplicate records in base tables using sql file where vsql queries are written
############################################################################################

###################################   INITIALIZATION  ######################################

export DAY=`date +%d_%m_%Y_%H_%M_%S`
export EXEC_DATE=`date +%Y-%m-%d`
export DAY_TOUCH=`date +%Y%m%d`
export DAYTIME='date +%d-%m-%Y-%H:%M:%S'
export YEAR=`date +%Y`
export SUB_AREA=$1
case "`hostname`" in
        "g2u2002c") ENV=DEV
        ;;
#      "mc4t01126") ENV=DEV
        "mc4t01126.itcs.softwaregrp.net") ENV=DEV
        ;;
#     "mc4t01145") ENV=SIT
        "mc4t01145.itcs.softwaregrp.net") ENV=SIT
        ;;
#      "mc4t01165") ENV=ITG
        "mc4t01165.itcs.softwaregrp.net") ENV=ITG
        ;;
#     "mc4t01146") ENV=PRD
        "mc4t01146.itcs.softwaregrp.net") ENV=PRD
esac
export COMMONPATH=/opt/FAST
#export MULETOUCHPATH=/home/omtsmgr/FAST
export LOGDIR=$COMMONPATH/logs/$SUB_AREA
export LOADDIR=$COMMONPATH/vsql/$SUB_AREA
export ERRORDIR=$COMMONPATH/error/$SUB_AREA
export ERRORARCHIVEDIR=$COMMONPATH/errorArchive/$SUB_AREA
export CONFIG=$COMMONPATH/config
export ARCHIVE=$COMMONPATH/archive/$SUB_AREA
export TOUCH_FILE_PATH=$COMMONPATH/muleTouchFiles/$SUB_AREA	
export TOUCH_FILE_ARCHIVE=$COMMONPATH/muleTouchFilesArchive/$SUB_AREA
export SHELLDIR=$COMMONPATH/sh					
export HOST=$(grep $ENV $CONFIG/cred.config | cut -f 4 -d :)
export USER=$(grep $ENV $CONFIG/cred.config | cut -f 2 -d :)
export PASSWORD=$(grep $ENV $CONFIG/cred.config | cut -f 3 -d :)
export DB=$(grep $ENV $CONFIG/cred.config | cut -f 6 -d :)
export PORT=$(grep $ENV $CONFIG/cred.config | cut -f 5 -d :)
export cycle_no=$2

touch $LOADDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv
echo "`$DAYTIME` : $SUB_AREA : ####################Duplicate check script started########################" >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Directory paths for $SUB_AREA are set." >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Extracted DB login related info from config file." >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log


echo "`$DAYTIME` : $SUB_AREA : Checking database connectivity" >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log

/opt/Vertica/bin/vsql -l -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log                  
if [ $? -eq 0 ]                                                                 						### Checking the result code to check connectivity
then
	echo "`$DAYTIME` : $SUB_AREA : Database connection is successful." >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
	echo "`$DAYTIME` : $SUB_AREA : Executing the vsql for $SUB_AREA to check duplicates" >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
	/opt/Vertica/bin/vsql -h $HOST -p $PORT -d $DB -C -U $USER -w $PASSWORD -t <$LOADDIR/$SUB_AREA"_Duplicate_Check.sql">$LOADDIR"/"$SUB_AREA"_Duplicate_Record_Details_temp_"$DAY.csv 2> $ERRORDIR"/"$SUB_AREA"_Duplicates_Error"$DAY.err
	echo "`$DAYTIME` : $SUB_AREA : Execution duplicate check vsql for $SUB_AREA is complete." >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
	for line in `cat $LOADDIR"/"$SUB_AREA"_Duplicate_Record_Details_temp_"$DAY.csv | tr -d " \t\r"`; do
		export count=`echo $line | cut -d'|' -f2`
		export name=`echo $line | cut -d'|' -f1`
		echo "$EXEC_DATE,$cycle_no,$SUB_AREA,$name,$count">>$LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
		if [ $count -gt 0 ]
		then
			echo "$EXEC_DATE,$cycle_no,$SUB_AREA,$name,$count" >> $LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv
		fi
	done
	echo "`$DAYTIME` : $SUB_AREA : Checking for status of duplicates..." >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
	if [ -s $LOADDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv ]          						### Checking for error details to send status mail
	then
		/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "COPY swt_rpt_stg.DUPLICATE_RECORD_TRACKING from local '$LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv' EXCEPTIONS '$LOGDIR"/"$SUB_AREA"_Duplicate_Record_exc.txt"' REJECTED DATA '$LOGDIR"/"$SUB_AREA"_Duplicate_Record_rej.txt"' ESCAPE AS E'\030' DELIMITER ',' NULL '';" >>$LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log 2>> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
		echo -e " Please Check the attached file for duplicate records present in base tables. \n\n This is an automatic mail. Please do not respond. " | mailx -a $LOADDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv -s "$DAY : Check for duplicates in $SUB_AREA base tables in $ENV is done" `cat $CONFIG/mail_recipient.txt`
		if [ $? -eq 0 ]                                                                 		### Checking the result code to check status of mail 
		then
			echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
		else
			echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
		fi
	else
		echo "`$DAYTIME` : $SUB_AREA : No duplicates found..." >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
	fi

else
	echo "`$DAYTIME` : $SUB_AREA : Unable to establish connection with database." >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
	echo "Unable to establish connection with database. Please check. This is an auto-generated email. Do not reply." | mailx -s "$DAY : Error connecting $ENV Database while trying to load $SUB_AREA" `cat $CONFIG/mail_recipient.txt`
	if [ $? -eq 0 ]                                                                 				### Checking the result code to check status of mail 
	then
		echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
	else
		echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
	fi
fi

echo "`$DAYTIME` : $SUB_AREA : Clean up activity begins..." >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
rm $LOADDIR"/"$SUB_AREA"_Duplicate_Record_Details_temp_"$DAY.csv
mv $LOADDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv $ARCHIVE"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv
echo "`$DAYTIME` : $SUB_AREA : Removing older log/error files from archive." >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log

####### Remove 5 days or older files ########## 

find $ARCHIVE/ -type f -name "*.csv" -mtime +5 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
find $ERRORDIR/ -type f -name "*.err" -mtime +5 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log

echo "`$DAYTIME` : $SUB_AREA : Older log/error files are removed from archive." >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Exiting script....." >> $LOGDIR"/"$SUB_AREA"_Duplicate_Script_Log_"$DAY.log

exit 0







