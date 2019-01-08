#!/bin/ksh
#
#    version         1.9
#    author          Dharmatheja Bhat
#    Updated by      Rajesh Chava

#    HISTORY
#    18/05/2017 : Script Creation
#    19/05/2017 : SQL level logs, error files
#	 22/05/2017 : Updation of logic
#	 23/05/2017 : Addition of script level logging
#	 13/06/2017	: Additional checks
#	 26/07/2017 : Additional logic to handle touchfiles and stage tables with no data
#    09/01/2018 : Addition of special case handling involving deletes in specific tables.
#	 16/07/2018 : routing all Logs,VSQL,ERROR Directory,ERRORARCHIVEDIR,CONFIG,ARCHIVE,MULE_TOUCH_FILE_ARCHIVE paths to MOUNTPATH(/opt/FAST) and MULE_TOUCH_FILE_PATH,MULE_TOUCH_ERRORFILE_PATH, Executive Report Path to COMMONPATH(/home/omtsmgr/FAST)
#	 20/07/2018 : routing all Logs,VSQL,ERROR Directory,ERRORARCHIVEDIR,CONFIG,ARCHIVE,MULE_TOUCH_FILE_ARCHIVE,MULE_TOUCH_FILE_PATH,MULE_TOUCH_ERRORFILE_PATH paths to new MOUNTPATH(/opt/FAST) from (/home/omtsmgr/FAST)
#    08/08/2018 : implementing parallel run

###################################### DESCRIPTION #########################################
#	This script checks load order of NETSUITE tables from a text file NETSUITE_LOAD_ORDER.txt
#	and executes corresponding vsql commands written in sql files when it finds out an empty 
#   file placed in a specific directory which indicates loading to stage table is complete 
#   from Mulesoft. Logging the outcome of each step is done to help debugging and an email 
#   is sent to support mail group with the exact status of execution.
############################################################################################

###################################   INITIALIZATION  ######################################
#if [ -f /home/omtsmgr/FAST/sh/one_time_file.txt ]
#then
#	rm /home/omtsmgr/FAST/sh/one_time_file.txt
#	exit 0
#fi
##sleep 1800

#exit 0
export DAY1=`date +%d_%m_%Y`
export EXEC_DATE=`date +%Y-%m-%d`
export DAY_TOUCH=`date +%Y%m%d`
export DAYTIME='date +%d-%m-%Y-%H:%M:%S'
export YEAR=`date +%Y`
export START_TIME=`date +%s`
export START_HOUR=`date +%H%M`
export SUB_AREA=NETSUITE
export SUB_AREA1=NETSUITESS
export TBL_CNT=69
export EXC_TBL_CNT=0
export LD_TBL_CNT=0
export CMPLT_LD_CNT=0
export touch_file_count=0
export touch_file_count1=0
export transaction_run=0
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
if ((030<=10#$START_HOUR && 10#$START_HOUR<430))
then
    export cycle_no=1
elif ((430<=10#$START_HOUR && 10#$START_HOUR<830))
then
    export cycle_no=3
elif ((830<=10#$START_HOUR && 10#$START_HOUR<1230))
then
    export cycle_no=5
elif ((1230<=10#$START_HOUR && 10#$START_HOUR<1630))
then
    export cycle_no=7
elif ((1630<=10#$START_HOUR && 10#$START_HOUR<2030))
then
    export cycle_no=9
elif ((2030<=10#$START_HOUR ))
then
    export cycle_no=11
else
        export cycle_no=0
fi

export cycle_nm=CYCLE$cycle_no
#export cycle_nm1=CYCLE$((cycle_no+1))
export DAY=$DAY1"_"$cycle_nm
export COMMONPATH=/opt/FAST
#export MULETOUCHPATH=/home/omtsmgr/FAST
export SCRIPT_PATH=$COMMONPATH/sh
export LOGDIR=$COMMONPATH/logs/$SUB_AREA
export LOADDIR=$COMMONPATH/vsql/$SUB_AREA
export ERRORDIR=$COMMONPATH/error/$SUB_AREA
export SHELLDIR=$COMMONPATH/sh
export ERRORARCHIVEDIR=$COMMONPATH/errorArchive/$SUB_AREA
export CONFIG=$COMMONPATH/config
export ARCHIVE=$COMMONPATH/archive/$SUB_AREA
export TOUCH_FILE_PATH=$COMMONPATH/muleTouchFiles/$SUB_AREA
export TOUCH_FILE_PATH1=$COMMONPATH/muleTouchFiles/$SUB_AREA1
export TOUCH_ERRORFILE_PATH=$COMMONPATH/muleErrorTouchFiles/$SUB_AREA
export TOUCH_ERRORFILE_PATH1=$COMMONPATH/muleErrorTouchFiles/$SUB_AREA1
export TOUCH_FILE_ARCHIVE=$COMMONPATH/muleTouchFilesArchive/$SUB_AREA
export TOUCH_ERRORFILE_PATH_ARCHIVE=$COMMONPATH/muleErrorTouchFilesArchive/$SUB_AREA
#export CORPBI_GLDIR=/home/omtsmgr/CORP_BI/VERTICA_TOUCHFILE_GL
#export CORPBI_GTMDIR=/home/omtsmgr/CORP_BI/VERTICA_TOUCHFILE_GTM						
export HOST=$(grep $ENV $CONFIG/cred.config | cut -f 4 -d :)
export USER=$(grep $ENV $CONFIG/cred.config | cut -f 2 -d :)
export PASSWORD=$(grep $ENV $CONFIG/cred.config | cut -f 3 -d :)
export DB=$(grep $ENV $CONFIG/cred.config | cut -f 6 -d :)
export PORT=$(grep $ENV $CONFIG/cred.config | cut -f 5 -d :)
export timeout_flag=0
export rerun_flag=0
export loop_counter=1
echo "`$DAYTIME` : $SUB_AREA : ####################Script started########################" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : PID: $$" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Directory paths for $SUB_AREA are set." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Extracted DB login related info from config file." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

for line in `cat $LOADDIR"/"$SUB_AREA"_LOAD_ORDER.txt"`; do    ### Reading the filenames in the order for executing respective sqls
	#Calling child script for each table
	export stg_table_name=`echo $line | cut -f1 -d .`
	echo "`$DAYTIME` : calling child script for $stg_table_name" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	ksh $SCRIPT_PATH/NETSUITE_SUB_SCRIPT.ksh $line $DAY1 $EXEC_DATE $DAY_TOUCH $YEAR $START_TIME $START_HOUR &
done

#Waiting for all child scripts to finish/cycle time elapsed
while [ $EXC_TBL_CNT -lt $TBL_CNT ] #this loop will be alive till all child scripts exits / cycle time elapse
do
	if [ $((`date +%s`-START_TIME)) -gt 13500 ]
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



echo "`$DAYTIME` : $SUB_AREA : Execution vsql for $SUB_AREA is complete." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
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
#	if [ -f $TOUCH_FILE_PATH"/NETSUITE_NS_TRANSACTION_LINES_"$YEAR*.txt ]
#	then
#        	/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.NS_Transaction_lines_Archive select * from swt_rpt_stg.NS_Transaction_lines;commit;truncate table swt_rpt_stg.NS_Transaction_lines;" >>$LOGDIR/NS_Transaction_lines_$DAY.log 2>> $ERRORDIR/NS_Transaction_lines_$DAY.err
#       		mv $TOUCH_FILE_PATH"/NETSUITE_NS_TRANSACTION_LINES_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/
#	fi
#	if [ -f $TOUCH_FILE_PATH"/NETSUITE_NS_TRANSACTION_LINKS_"$YEAR*.txt ]
#        then
#                /opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.NS_Transaction_links_Archive select * from swt_rpt_stg.NS_Transaction_links;commit;truncate table swt_rpt_stg.NS_Transaction_links;" >>$LOGDIR/NS_Transaction_links_$DAY.log 2>> $ERRORDIR/NS_Transaction_links_$DAY.err
#                mv $TOUCH_FILE_PATH"/NETSUITE_NS_TRANSACTION_LINKS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/
#        fi
#	if [ -f $TOUCH_FILE_PATH"/NETSUITE_NS_REVENUE_PLANS_"$YEAR*.txt ]
#	then
#        	/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.NS_REVENUE_PLANS_Archive select * from swt_rpt_stg.NS_REVENUE_PLANS;commit;truncate table swt_rpt_stg.NS_REVENUE_PLANS;" >>$LOGDIR/NS_REVENUE_PLANS_$DAY.log 2>> $ERRORDIR/NS_REVENUE_PLANS_$DAY.err
#      		mv $TOUCH_FILE_PATH"/NETSUITE_NS_REVENUE_PLANS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/
#	fi
	
#	if [ -f $TOUCH_FILE_PATH"/NETSUITE_NS_REVENUE_ELEMENTS_"$YEAR*.txt ]
#	then
#        	/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.NS_REVENUE_ELEMENTS_Archive select * from swt_rpt_stg.NS_REVENUE_ELEMENTS;commit;truncate table swt_rpt_stg.NS_REVENUE_ELEMENTS;" >>$LOGDIR/NS_REVENUE_ELEMENTS_$DAY.log 2>> $ERRORDIR/NS_REVENUE_ELEMENTS_$DAY.err
#       		mv $TOUCH_FILE_PATH"/NETSUITE_NS_REVENUE_ELEMENTS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/
#	fi
	
#	if [ -f $TOUCH_FILE_PATH"/NETSUITE_NS_TRANSACTIONS_"$YEAR*.txt ]
#	then
#        	/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.NS_TRANSACTIONS_Archive select * from swt_rpt_stg.NS_TRANSACTIONS;commit;truncate table swt_rpt_stg.NS_TRANSACTIONS;" >>$LOGDIR/NS_TRANSACTIONS_$DAY.log 2>> $ERRORDIR/NS_TRANSACTIONS_$DAY.err
#       		mv $TOUCH_FILE_PATH"/NETSUITE_NS_TRANSACTIONS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/
#	fi
	
#	if [ -f $TOUCH_FILE_PATH"/NETSUITE_NS_ENTITY_"$YEAR*.txt ]
#	then
#        	/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.NS_ENTITY_Archive select * from swt_rpt_stg.NS_ENTITY;commit;truncate table swt_rpt_stg.NS_ENTITY;" >>$LOGDIR/NS_ENTITY_$DAY.log 2>> $ERRORDIR/NS_ENTITY_$DAY.err
#       		mv $TOUCH_FILE_PATH"/NETSUITE_NS_ENTITY_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/
#	fi
	
#	if [ -f $TOUCH_FILE_PATH"/NETSUITE_NS_CUSTOMERS_"$YEAR*.txt ]
#	then
#        	/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.NS_CUSTOMERS_Archive select * from swt_rpt_stg.NS_CUSTOMERS;commit;truncate table swt_rpt_stg.NS_CUSTOMERS;" >>$LOGDIR/NS_CUSTOMERS_$DAY.log 2>> $ERRORDIR/NS_CUSTOMERS_$DAY.err
#       		mv $TOUCH_FILE_PATH"/NETSUITE_NS_CUSTOMERS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/
#	fi

echo "`$DAYTIME` : $SUB_AREA : Invoking the duplicate check script..." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
ksh $SHELLDIR/Duplicate_Checker.ksh $SUB_AREA $cycle_no
echo "`$DAYTIME` : $SUB_AREA : Sending email regarding the status of sql execution." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
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
		echo -e "This is an automatic mail. Please do not respond. This is just to inform you, $SUB_AREA Data Loaded timed out In $ENV waiting for zero byte files. Below is the load status \n\n Total table count in $SUB_AREA = $TBL_CNT \n\n Total table count with data in stage = $LD_TBL_CNT \n\n Actual executed table count = $CMPLT_LD_CNT \n\n " | mailx -s "$DAY : $SUB_AREA Data Loaded successfully In $ENV" `cat $CONFIG/mail_recipient.txt`
		if [ $? -eq 0 ]                                                                 			### Checking the result code to check status of mail 
		then
			echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		else
			echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		fi
	else
		echo -e "This is an automatic mail. Please do not respond. This is just to inform you, $SUB_AREA Data Loaded successfully In $ENV for the tables with data in stage.\n\n Total table count in $SUB_AREA = $TBL_CNT \n\n Total table count with data in stage = $LD_TBL_CNT \n\n Actual executed table count = $CMPLT_LD_CNT \n\n " | mailx -s "$DAY : $SUB_AREA Data Loaded successfully In $ENV" `cat $CONFIG/mail_recipient.txt`
                       if [ $? -eq 0 ]                                                                                         ### Checking the result code to check status of mail
                       then
                               echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
                       else
                               echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
                       fi
	fi
fi

	
echo "`$DAYTIME` : $SUB_AREA : Clean up activity begins..." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Removing older log/error files from archive." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

####### Remove 3 days or older files ########## 

find $ERRORARCHIVEDIR/ -type f -name "*.err" -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $ERRORARCHIVEDIR/ERROR_INFO*.txt -type f -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $ERRORDIR/ERROR_INFO*.txt -type f -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $LOGDIR/ -type f -name "*.log" -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $TOUCH_FILE_ARCHIVE/ -type f -name "*.txt" -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $ARCHIVE/ -type f -name "*.csv" -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Older log/error files are removed from archive." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Exiting script....." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

echo "Clearing ID tables for consistency..." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
#/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "TRUNCATE TABLE swt_rpt_stg.NS_Revenue_elements_ID; TRUNCATE TABLE swt_rpt_stg.NS_Revenue_plans_ID; TRUNCATE TABLE swt_rpt_stg.NS_Customers_ID; TRUNCATE TABLE swt_rpt_stg.NS_Entity_ID; TRUNCATE TABLE swt_rpt_stg.NS_Transaction_address_ID; TRUNCATE TABLE swt_rpt_stg.NS_FAM_Depreciation_History_ID;" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_TRANSACTIONS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/"NETSUITE_NS_SS_DELETED_RECORDS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH1/"NETSUITESS_NS_MISSING_TRANSACTION_TYPES_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
#mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_TRANSACTIONS_ID_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_TRANSACTION_LINES_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
#mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_TRANSACTION_LINES_ID_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_TRANSACTION_LINKS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
#mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_TRANSACTION_LINKS_ID_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_REVENUE_ELEMENTS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_REVENUE_ELEMENTS_ID_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_REVENUE_PLANS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_REVENUE_PLANS_ID_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_CUSTOMERS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_CUSTOMERS_ID_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_ENTITY_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_ENTITY_ID_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_TRANSACTION_ADDRESS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_TRANSACTION_ADDRESS_ID_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_FAM_DEPRECIATION_HISTORY_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_NS_FAM_DEPRECIATION_HISTORY_ID_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/ 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

ksh $COMMONPATH/sh/PKG_ATDF_INTER_REFRESH.ksh
#if [ $? -gt 0 ]                                                                 		### Checking the result code to check status of mail 
#then	
#		echo -e "Error Occurred while loading ATDF intermediate table " | mailx -s "$DAY : ATDF Intermediate Data Load failed In $ENV" `cat $CONFIG/corp_bi_bcc_list.txt`
#fi
#ksh $COMMONPATH/sh/EXPORT_REV_TBL_REFRESH.ksh
#if [ $? -gt 0 ]                                                                 		### Checking the result code to check status of mail 
#then	
#		echo -e "Error Occurred while loading REVENUE intermediate table " | mailx -s "$DAY : REVENUE Intermediate Data Load failed In $ENV" `cat $CONFIG/corp_bi_bcc_list.txt`
#fi

ksh $SHELLDIR/DAILY_AUDIT_REPORT.ksh
exit 0






