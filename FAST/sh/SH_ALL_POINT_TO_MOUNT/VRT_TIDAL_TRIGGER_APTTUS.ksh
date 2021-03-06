#!/bin/ksh
#
#    version         1.8
#    author          Dharmatheja Bhat
#    Updated by      Rajesh Chava

#    HISTORY
#    18/05/2017 : Script Creation
#    19/05/2017 : SQL level logs, error files
#	 22/05/2017 : Updation of logic
#	 23/05/2017 : Addition of script level logging
#	 13/06/2017	: Additional checks
#	 26/07/2017 : Additional logic to handle touchfiles and stage tables with no data
#    03/01/2018 : Duplicate records check in base tables using key columns added
#	 16/07/2018 : routing all Logs,VSQL,ERROR Directory,ERRORARCHIVEDIR,CONFIG,ARCHIVE,MULE_TOUCH_FILE_ARCHIVE paths to MOUNTPATH(/opt/FAST) and MULE_TOUCH_FILE_PATH,MULE_TOUCH_ERRORFILE_PATH, Executive Report Path to COMMONPATH(/home/omtsmgr/FAST)
#	 20/07/2018 : routing all Logs,VSQL,ERROR Directory,ERRORARCHIVEDIR,CONFIG,ARCHIVE,MULE_TOUCH_FILE_ARCHIVE,MULE_TOUCH_FILE_PATH,MULE_TOUCH_ERRORFILE_PATH paths to new MOUNTPATH(/opt/FAST) from (/home/omtsmgr/FAST)

###################################### DESCRIPTION #########################################
#	This script checks load order of APTTUS tables from a text file APTTUS_LOAD_ORDER.txt
#	and executes corresponding vsql commands written in sql files when it finds out an empty 
#   file placed in a specific directory which indicates loading to stage table is complete 
#   from Mulesoft. Logging the outcome of each step is done to help debugging and an email 
#   is sent to support mail group with the exact status of execution.
############################################################################################

###################################   INITIALIZATION  ######################################
export DAY1=`date +%d_%m_%Y`
export EXEC_DATE=`date +%Y-%m-%d`
export DAY_TOUCH=`date +%Y%m%d`
export DAYTIME='date +%d-%m-%Y-%H:%M:%S'
export YEAR=`date +%Y`
export START_TIME=`date +%s`
export START_HOUR=`date +%H`
#export START_HOUR=`echo $(($(date '+(%H*60+%M)*60+%S')))`
export SUB_AREA=APTTUS
export TBL_CNT=60
export EXC_TBL_CNT=0
export LD_TBL_CNT=0
export CMPLT_LD_CNT=0
export dup_count=0
case "`hostname`" in 
	"g2u2002c") ENV=DEV
	;;
	"mc4t01126") ENV=DEV
	;;
	"mc4t01145") ENV=SIT
	;;
	"mc4t01165") ENV=ITG
	;;
	"mc4t01146") ENV=PRD
esac
if ((1<=10#$START_HOUR && 10#$START_HOUR<3))
then
    export cycle_no=1
elif ((3<=10#$START_HOUR && 10#$START_HOUR<5))
then
    export cycle_no=2
elif ((5<=10#$START_HOUR && 10#$START_HOUR<7))
then
    export cycle_no=3
elif ((7<=10#$START_HOUR && 10#$START_HOUR<9))
then
    export cycle_no=4
elif ((9<=10#$START_HOUR && 10#$START_HOUR<11))
then
    export cycle_no=5
elif ((11<=10#$START_HOUR && 10#$START_HOUR<13))
then
    export cycle_no=6
elif ((13<=10#$START_HOUR && 10#$START_HOUR<15))
then
    export cycle_no=7
elif ((15<=10#$START_HOUR && 10#$START_HOUR<17))
then
    export cycle_no=8
elif ((17<=10#$START_HOUR && 10#$START_HOUR<19))
then
    export cycle_no=9
elif ((19<=10#$START_HOUR && 10#$START_HOUR<21))
then
    export cycle_no=10
elif ((21<=10#$START_HOUR && 10#$START_HOUR<23))
then
    export cycle_no=11
elif ((23<=10#$START_HOUR))
then
        export cycle_no=12
else
        export cycle_no=0
fi
export cycle_nm="CYCLE-"$cycle_no
export DAY=$DAY1"_"$cycle_nm
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
export TOUCH_ERRORFILE_PATH=$COMMONPATH/muleErrorTouchFiles/$SUB_AREA
export TOUCH_ERRORFILE_PATH_ARCHIVE=$COMMONPATH/muleErrorTouchFilesArchive/$SUB_AREA	
export SCRIPT_PATH=$COMMONPATH/sh				
export HOST=$(grep $ENV $CONFIG/cred.config | cut -f 4 -d :)
export USER=$(grep $ENV $CONFIG/cred.config | cut -f 2 -d :)
export PASSWORD=$(grep $ENV $CONFIG/cred.config | cut -f 3 -d :)
export DB=$(grep $ENV $CONFIG/cred.config | cut -f 6 -d :)
export PORT=$(grep $ENV $CONFIG/cred.config | cut -f 5 -d :)
export timeout_flag=0
export rerun_flag=0
export loop_counter=1

echo "`$DAYTIME` : $SUB_AREA : ####################Main Script started########################" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

#find $LOADDIR/$SUB_AREA"_LOAD.txt" -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
#find $LOADDIR/pending_tables.txt -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
touch $LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv

for line in `cat $LOADDIR"/"$SUB_AREA"_LOAD_ORDER.txt"`; do    ### Reading the filenames in the order for executing respective sqls
	#Calling child script for each table
	export stg_table_name=`echo $line | cut -f1 -d .`
	echo "`$DAYTIME` : calling child script for $stg_table_name" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	ksh $SCRIPT_PATH/APTTUS_SUB_SCRIPT.ksh $line $DAY1 $EXEC_DATE $DAY_TOUCH $YEAR $START_TIME $START_HOUR &
done

#Waiting for all child scripts to finish/cycle time elapsed
while [ $EXC_TBL_CNT -lt $TBL_CNT ] #this loop will be alive till all child scripts exits / cycle time elapse
do
	if [ $((`date +%s`-START_TIME)) -gt 4740 ]
	then
		echo "`$DAYTIME` : $SUB_AREA : Breaking while loop as execution time crossed 1 hour 19 minutes" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		timeout_flag=1
		break
	fi
	echo "`$DAYTIME` : TBL_CNT $TBL_CNT" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	echo "`$DAYTIME` : EXC_TBL_CNT $EXC_TBL_CNT" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	echo "`$DAYTIME` : Sleep for 600 seconds" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	sleep 600
	EXC_TBL_CNT=`find $LOGDIR"/"*"END_EXECUTED.txt" -maxdepth 1 -type f | wc -l` 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
done

#checking if any child process still running
export start_process_count=`find $LOGDIR"/"*"_"$EXEC_DATE"_"$cycle_no"_START_EXECUTED.txt" -maxdepth 1 -type f | wc -l` 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
export end_process_count=`find $LOGDIR"/"*"_"$EXEC_DATE"_"$cycle_no"_END_EXECUTED.txt" -maxdepth 1 -type f | wc -l` 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

while [ $end_process_count -lt $start_process_count ] #this loop will be alive till all child scripts exits / cycle time elapse
do
	echo "`$DAYTIME` : Sleep for 300 seconds" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	sleep 300
	export start_process_count=`find $LOGDIR"/"*"_"$EXEC_DATE"_"$cycle_no"_START_EXECUTED.txt" -maxdepth 1 -type f | wc -l` 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	export end_process_count=`find $LOGDIR"/"*"_"$EXEC_DATE"_"$cycle_no"_END_EXECUTED.txt" -maxdepth 1 -type f | wc -l` 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
done

#checking audit table for count of tables successfully executed
LD_TBL_CNT=`/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "select count(1) from swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA='"$SUB_AREA"' and SRC_REC_CNT<>0 and LD_DT='"$EXEC_DATE"' and CYCLE="$cycle_no;`
CMPLT_LD_CNT=`/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "select count(1) from swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA='"$SUB_AREA"' and SRC_REC_CNT<>0 and LD_DT='"$EXEC_DATE"' and CYCLE="$cycle_no" and COMPLTN_STAT='Y'";`

echo "`$DAYTIME` : $SUB_AREA : Checking for vsql related errors" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
cd $ERRORDIR
touch ERROR_INFO_$DAY.txt
for file in *.err	 																				### Check for error files wrt to sql files
do 
	if [ -s $file ]
	then 
		echo $file>>ERROR_INFO_$DAY.txt
	else
		rm $file
	fi
	if [ -f $file ]
	then 
		mv $file $ERRORARCHIVEDIR/$file
	else
		:
	fi
done
echo "`$DAYTIME` : $SUB_AREA : Sending email regarding the status of sql execution." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
if [ -s $LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv ]
then
	echo "`$DAYTIME` : $SUB_AREA : Loading duplicate record details to a table" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "COPY swt_rpt_stg.DUPLICATE_RECORD_TRACKING from local '$LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv' EXCEPTIONS '$LOGDIR"/"$SUB_AREA"_Duplicate_Record_exc.txt"' REJECTED DATA '$LOGDIR"/"$SUB_AREA"_Duplicate_Record_rej.txt"' ESCAPE AS E'\030' DELIMITER ',' NULL '';" >>$LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	if [ $? -eq 0 ]                                                                 		### Checking the result code to check status of mail 
	then
		echo "`$DAYTIME` : $SUB_AREA : No issues while loading the duplicate details." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	else
		echo -e " Failed loading duplicate records in $SUB_AREA base tables to the table.\n\n This is an automatic mail. Please do not respond. " | mailx -s "$DAY : Failed loading duplicate records in $SUB_AREA base tables to table in $ENV" `cat $CONFIG/mail_recipient.txt`
	fi
	echo -e " There are duplicate records in $SUB_AREA base tables and requires a cleanup.\n\n Please check the attached file.\n\n This is an automatic mail. Please do not respond. " | mailx -a $LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv -s "$DAY : Duplicate records in $SUB_AREA base tables in $ENV" `cat $CONFIG/mail_recipient.txt`
fi
if [ -s ERROR_INFO_$DAY.txt ]          															### Checking for error details to send status mail
then 
	echo -e " This is just to inform you that errors occurred while loading $SUB_AREA data. List of errorful vsql names are attached. Please check $ERRORDIR for the error details.\n\n Total table count in $SUB_AREA = $TBL_CNT \n\nTotal table count with data in stage = $LD_TBL_CNT \n\nActual executed table count = $CMPLT_LD_CNT \n\n\n\n This is an automatic mail. Please do not respond. " | mailx -a $ERRORDIR/ERROR_INFO_$DAY.txt -s "$DAY : Errors occurred while loading $SUB_AREA data in $ENV" `cat $CONFIG/mail_recipient.txt`
	if [ $? -eq 0 ]                                                                 		### Checking the result code to check status of mail 
	then	
		echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		mv ERROR_INFO_$DAY.txt $ERRORARCHIVEDIR/ERROR_INFO_`$DAYTIME`.txt
	else
		echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	fi
else 
	if [ $EXC_TBL_CNT -eq $TBL_CNT ] 
	then
		echo -e "This is an automatic mail. Please do not respond. This is just to inform you, $SUB_AREA Data Loaded successfully In $ENV.\n\n Total table count in $SUB_AREA = $TBL_CNT \n\n Total table count with data in stage = $LD_TBL_CNT \n\n Actual executed table count = $CMPLT_LD_CNT \n\n" | mailx -s "$DAY : $SUB_AREA Data Loaded successfully In $ENV" `cat $CONFIG/mail_recipient.txt`
		if [ $? -eq 0 ]                                                                 			### Checking the result code to check status of mail 
		then
			echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		else
			echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		fi
	elif [ $timeout_flag -eq 1 ]
	then
		echo -e "This is an automatic mail. Please do not respond. This is just to inform you, $SUB_AREA Data Loaded timed out In $ENV waiting for zero byte files. Below is the load status \n\n Total table count in $SUB_AREA = $TBL_CNT \n\n Total table count with data in stage = $LD_TBL_CNT \n\n Actual executed table count = $CMPLT_LD_CNT \n\n" | mailx -s "$DAY : $SUB_AREA Data Loaded successfully In $ENV" `cat $CONFIG/mail_recipient.txt`
		if [ $? -eq 0 ]                                                                 			### Checking the result code to check status of mail 
		then
			echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		else
			echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		fi
	else
		echo -e "This is an automatic mail. Please do not respond. This is just to inform you, $SUB_AREA Data Loaded successfully In $ENV for the tables with data in stage.\n\n Total table count in $SUB_AREA = $TBL_CNT \n\n Total table count with data in stage = $LD_TBL_CNT \n\n Actual executed table count = $CMPLT_LD_CNT \n\n" | mailx -s "$DAY : $SUB_AREA Data Loaded successfully In $ENV" `cat $CONFIG/mail_recipient.txt`
           		if [ $? -eq 0 ]                                                                         ### Checking the result code to check status of mail
       	   	then
			echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		else
			echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
           		fi
	fi
fi

echo "`$DAYTIME` : $SUB_AREA : Clean up activity begins..." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv $ARCHIVE"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv>>$LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

#removing the _EXECUTED touch files for this cycle
find $LOGDIR"/"*"_"$EXEC_DATE"_"$cycle_no"_START_EXECUTED.txt" -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $LOGDIR"/"*"_"$EXEC_DATE"_"$cycle_no"_END_EXECUTED.txt" -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

echo "`$DAYTIME` : $SUB_AREA : Removing older log/error files from archive." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
####### Remove 3 days or older files ########## 
find $ERRORARCHIVEDIR/ -type f -name "*.err" -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $ERRORARCHIVEDIR/ERROR_INFO*.txt -type f -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $ERRORDIR/ERROR_INFO*.txt -type f -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $LOGDIR/ -type f -name "*.log" -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $ARCHIVE/ -type f -name "*.csv" -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $TOUCH_FILE_ARCHIVE/ -type f -name "*.txt" -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $TOUCH_ERRORFILE_PATH_ARCHIVE/ -type f -name "*.txt" -mtime +5 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

echo "`$DAYTIME` : $SUB_AREA : Older log/error files are removed from archive." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Exiting main script....." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

exit 0




