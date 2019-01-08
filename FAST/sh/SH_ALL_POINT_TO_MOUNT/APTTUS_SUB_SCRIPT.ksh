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

export line=$1
export DAY1=$2
export EXEC_DATE=$3
export DAY_TOUCH=$4
export DAYTIME='date +%d-%m-%Y-%H:%M:%S'
export YEAR=$5
export START_TIME=$6
export START_HOUR=$7
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
export HOST=$(grep $ENV $CONFIG/cred.config | cut -f 4 -d :)
export USER=$(grep $ENV $CONFIG/cred.config | cut -f 2 -d :)
export PASSWORD=$(grep $ENV $CONFIG/cred.config | cut -f 3 -d :)
export DB=$(grep $ENV $CONFIG/cred.config | cut -f 6 -d :)
export PORT=$(grep $ENV $CONFIG/cred.config | cut -f 5 -d :)
export timeout_flag=0
export rerun_flag=0
export loop_counter=1

#creating a touch file to indicate child script started
touch $LOGDIR"/"$line"_"$EXEC_DATE"_"$cycle_no"_START_EXECUTED.txt"

echo "`$DAYTIME` : $SUB_AREA : ####################Child script started########################" >> $LOGDIR/$line"_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Directory paths for $SUB_AREA are set." >> $LOGDIR/$line"_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Extracted DB login related info from config file." >> $LOGDIR/$line"_"$DAY.log


echo "`$DAYTIME` : $SUB_AREA : Checking database connectivity" >> $LOGDIR/$line"_"$DAY.log

/opt/Vertica/bin/vsql -l -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD >> $LOGDIR/$line"_"$DAY.log                  
if [ $? -eq 0 ]                                                                 						### Checking the result code to check connectivity
then
	echo "`$DAYTIME` : $SUB_AREA : Database connection is successful." >> $LOGDIR/$line"_"$DAY.log
	echo "`$DAYTIME` : $SUB_AREA : Executing the vsql for $SUB_AREA one by one" >> $LOGDIR/$line"_"$DAY.log
	cd $LOADDIR

	while [ $loop_counter -eq 1 ] #this loop will be alive till we get a touch file / cycle time elapse
	do
		echo "`$DAYTIME` : $SUB_AREA : Checking the time elapsed for this run" >> $LOGDIR/$line"_"$DAY.log
		echo "`$DAYTIME` : $SUB_AREA : $((`date +%s`-START_TIME)) seconds elapsed" >> $LOGDIR/$line"_"$DAY.log
		
		if [ $((`date +%s`-START_TIME)) -gt 5400 ]
		then
			echo "`$DAYTIME` : $SUB_AREA : Breaking while loop as execution time crossed 1 hour 29 minutes" >> $LOGDIR/$line"_"$DAY.log
			timeout_flag=1
			break
		fi
		echo "`$DAYTIME` : Checking for the touch file to proceed further." >> $LOGDIR/$line"_"$DAY.log
		export file_name=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$DAY_TOUCH
		export file_count=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
		export error_file_count=`find $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
		export stg_table_name=`echo $line | cut -f1 -d .`
		if [ $file_count -gt 0 ] && [ $error_file_count -eq 0 ]
		then
			export stg_table_count=`/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "select count(*) from swt_rpt_stg."$stg_table_name;`
			if [ $stg_table_count -gt 0 ]
			then
				LD_TBL_CNT=$((LD_TBL_CNT+1))
				echo "`$DAYTIME` : Executing $line" >> $LOGDIR/$line"_"$DAY.log
				/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all<$LOADDIR/$line>>$LOGDIR/$line"_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err
				if [ $? -eq 0 ]
				then
					mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
					else
					mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
					echo "`$DAYTIME` : $SUB_AREA : Error in executing $line. Check Vertica Log for error details" >> $LOGDIR/$line"_"$DAY.log
				fi
				else
					echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Adding an entry into AUDIT table" >> $LOGDIR/$line"_"$DAY.log
					/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.FAST_LD_AUDT ( SUBJECT_AREA ,TBL_NM ,LD_DT ,START_DT_TIME ,END_DT_TIME ,SRC_REC_CNT ,TGT_REC_CNT ,COMPLTN_STAT ) select '$SUB_AREA','$stg_table_name',sysdate::date,sysdate,sysdate,0,0,'Y';commit;" >>$LOGDIR/$line"_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err
					echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Moving touch file to archive" >> $LOGDIR/$line"_"$DAY.log
					mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
			fi
			dup_count=`/opt/Vertica/bin/vsql -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -t -c "SELECT COUNT(*) FROM (SELECT ID,count(ID) FROM swt_rpt_base.$stg_table_name group by ID  having count(ID)>1)A;"`
			if [ $dup_count -gt 0 ]
			then
				echo "`$DAYTIME` : $SUB_AREA : $stg_table_name base table has duplicate records." >> $LOGDIR/$line"_"$DAY.log
				echo "$EXEC_DATE,$cycle_no,$SUB_AREA,$stg_table_name,$dup_count" >> $LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv
				else
					echo "`$DAYTIME` : $SUB_AREA : $stg_table_name base table doesnt have duplicate records." >> $LOGDIR/$line"_"$DAY.log
			fi
			loop_counter=0
		elif [ $error_file_count -gt 0 ] && [ $file_count -eq 0 ]
		then
			echo "`$DAYTIME` : $SUB_AREA : Error file received for $line and clearing stage table." >> $LOGDIR/$line"_"$DAY.log
			echo -e " Error touch file recieved for the $stg_table_name and hence truncating the stage table for consistency. " | mailx -s "$DAY : Truncated swt_rpt_stg.$stg_table_name in $ENV" `cat $CONFIG/mail_recipient.txt`
			/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "TRUNCATE TABLE swt_rpt_stg.$stg_table_name;" >>$LOGDIR/$line"_"$DAY.log 2>>$LOGDIR/$line"_"$DAY.log
			mv $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_ERRORFILE_PATH_ARCHIVE/
			loop_counter=0
		elif [ $error_file_count -gt 0 ] && [ $file_count -gt 0 ]
		then
			echo "`$DAYTIME` : $SUB_AREA : Both success file and error files received. Not processing stage to base for the $stg_table_name" >> $LOGDIR/$line"_"$DAY.log
			echo -e " Both Error touch file and success files recieved for the $stg_table_name and hence manual check is needed. " | mailx -s "$DAY : Please check swt_rpt_stg.$stg_table_name in $ENV" `cat $CONFIG/mail_recipient.txt`
			mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
			mv $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_ERRORFILE_PATH_ARCHIVE/
			loop_counter=0
		else
			echo "`$DAYTIME` : $SUB_AREA : $line touch file doesn't exist, sleep for a while..." >> $LOGDIR/$line"_"$DAY.log
			if [ $((`date +%s`-START_TIME)) -gt 4800 ]
			then
				sleep 60
			else
				sleep 600
			fi
			loop_counter=1
		fi
	done
	echo "`$DAYTIME` : $SUB_AREA : Execution vsql for $line is complete." >> $LOGDIR/$line"_"$DAY.log
else
	echo "`$DAYTIME` : $SUB_AREA : Unable to establish connection with database." >> $LOGDIR/$line"_"$DAY.log
	echo "Unable to establish connection with database. Please check. This is an auto-generated email. Do not reply." | mailx -s "$DAY : Error connecting $ENV Database while trying to load $SUB_AREA in $ENV" `cat $CONFIG/mail_recipient.txt`
	if [ $? -eq 0 ]                                                                 				### Checking the result code to check status of mail 
	then
		echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOGDIR/$line"_"$DAY.log
	else
		echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOGDIR/$line"_"$DAY.log
	fi
fi

touch $LOGDIR"/"$line"_"$EXEC_DATE"_"$cycle_no"_END_EXECUTED.txt"

echo "`$DAYTIME` : $SUB_AREA : Exiting child script....." >> $LOGDIR/$line"_"$DAY.log

exit 0




