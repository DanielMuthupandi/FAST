#!/bin/ksh
#
#    version         1.7
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
export DAY1=`date +%d_%m_%Y`
export DAY_TOUCH=`date +%Y%m%d`
export DAYTIME='date +%d-%m-%Y-%H:%M:%S'
export YEAR=`date +%Y`
export START_TIME=`date +%s`
export START_HOUR=`date +%H`
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
	"mc4t01126") ENV=DEV
	;;
	"mc4t01145") ENV=SIT
	;;
	"mc4t01165") ENV=ITG
	;;
	"mc4t01146") ENV=PRD
esac

if ((1<=10#$START_HOUR && 10#$START_HOUR<5))
then
    export cycle_no=1
elif ((5<=10#$START_HOUR && 10#$START_HOUR<9))
then
    export cycle_no=3
elif ((9<=10#$START_HOUR && 10#$START_HOUR<13))
then
    export cycle_no=5
elif ((13<=10#$START_HOUR && 10#$START_HOUR<17))
then
    export cycle_no=7
elif ((17<=10#$START_HOUR && 10#$START_HOUR<21))
then
    export cycle_no=9
elif ((21<=10#$START_HOUR ))
then
    export cycle_no=11
else
        export cycle_no=0
fi

export cycle_nm=CYCLE$cycle_no
#export cycle_nm1=CYCLE$((cycle_no+1))
export DAY=$DAY1"_"$cycle_nm
export COMMONPATH=/opt/FAST
export MULETOUCHPATH=/home/omtsmgr/FAST
export LOGDIR=$COMMONPATH/logs/$SUB_AREA
export LOADDIR=$COMMONPATH/vsql/$SUB_AREA
export ERRORDIR=$COMMONPATH/error/$SUB_AREA
export SHELLDIR=$COMMONPATH/sh
export ERRORARCHIVEDIR=$COMMONPATH/errorArchive/$SUB_AREA
export CONFIG=$COMMONPATH/config
export ARCHIVE=$COMMONPATH/archive/$SUB_AREA
export TOUCH_FILE_PATH=$MULETOUCHPATH/muleTouchFiles/$SUB_AREA
export TOUCH_FILE_PATH1=$MULETOUCHPATH/muleTouchFiles/$SUB_AREA1
export TOUCH_ERRORFILE_PATH=$MULETOUCHPATH/muleErrorTouchFiles/$SUB_AREA
export TOUCH_ERRORFILE_PATH1=$MULETOUCHPATH/muleErrorTouchFiles/$SUB_AREA1
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
echo "`$DAYTIME` : $SUB_AREA : Directory paths for $SUB_AREA are set." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Extracted DB login related info from config file." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log


echo "`$DAYTIME` : $SUB_AREA : Checking database connectivity" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

/opt/Vertica/bin/vsql -l -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log                  
if [ $? -eq 0 ]                                                                 						### Checking the result code to check connectivity
then
	echo "`$DAYTIME` : $SUB_AREA : Database connection is successful." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	echo "`$DAYTIME` : $SUB_AREA : Executing the vsql for $SUB_AREA one by one" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	cd $LOADDIR
	
	find $LOADDIR/$SUB_AREA"_LOAD.txt" -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	find $LOADDIR/pending_tables.txt -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	while [ $EXC_TBL_CNT -lt $TBL_CNT ] 
	do
		echo "`$DAYTIME` : $SUB_AREA : Checking the time elapsed for this run" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		echo "`$DAYTIME` : $SUB_AREA : $((`date +%s`-START_TIME)) seconds elapsed" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		if [ $((`date +%s`-START_TIME)) -gt 11700 ]
		then
			echo "`$DAYTIME` : $SUB_AREA : Breaking while loop as execution time crossed 3 hours 19 minutes" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
			timeout_flag=1
			break
		else
			if [ $loop_counter -eq 0 ]
			then
				sleep 600
			else
				echo "At least one table got executed in last loop or returing from sleep" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
			fi
			loop_counter=0
			echo "`$DAYTIME` : $SUB_AREA : Checking for today's touchfiles and writing to log" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
        	##find $TOUCH_FILE_PATH/*_$DAY_TOUCH*.txt -type f >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log 2>>$LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
            export NS_files_count=`find $TOUCH_FILE_PATH/*_$DAY_TOUCH*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
			export NSSS_files_count=`find $TOUCH_FILE_PATH1/*_$DAY_TOUCH*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
			export NS_errorfiles_count=`find $TOUCH_ERRORFILE_PATH/Exception*_$DAY_TOUCH*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
			export NSSS_errorfiles_count=`find $TOUCH_ERRORFILE_PATH1/Exception*_$DAY_TOUCH*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
        	if [ $NS_files_count -gt 0 ] || [ $NSSS_files_count -gt 0 ] || [ $NS_errorfiles_count -gt 0 ] || [ $NSSS_errorfiles_count -gt 0 ]
			then
				if [ $rerun_flag -gt 0 ]
				then
					mv pending_tables.txt $SUB_AREA"_LOAD.txt"
				else
					cp $SUB_AREA"_LOAD_ORDER.txt" $SUB_AREA"_LOAD.txt"
				fi
				for line in `cat $SUB_AREA"_LOAD.txt"`; do    ### Reading the filenames in the order for executing respective sqls
					echo "`$DAYTIME` : Checking for the touch file to proceed further." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
					export file_name=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$DAY_TOUCH
					if [ "$line" == "NS_USD_Extract_Open_Period.sql" ] || [ "$line" == "NS_USD_Extract_Closed_Period.sql" ]
					then
						file_count=`find $TOUCH_FILE_PATH1/$SUB_AREA1"_"$file_name*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
						export error_file_count=`find $TOUCH_ERRORFILE_PATH1"/Exception_"$SUB_AREA1"_"$file_name*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
					else
						file_count=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
						export error_file_count=`find $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
					fi
					if [ $file_count -gt 0 ] && [ $error_file_count -eq 0 ]
					then
						if [ "$line" == "NS_Revenue_elements.sql" ] ||  [ "$line" == "NS_Revenue_plans.sql" ] || [ "$line" == "NS_Customers.sql" ] || [ "$line" == "NS_Entity.sql" ] || [ "$line" == "NS_Transaction_address.sql" ] || [ "$line"  == "NS_FAM_Depreciation_History.sql" ]
						then
							echo "`$DAYTIME` : Checking for the touch files for $line and related Id table to proceed further." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
							export file_name=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$DAY_TOUCH
							export file_name1=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_ID_"$DAY_TOUCH
							export touch_file_count=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
							export touch_file_count1=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name1*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
							if [ $touch_file_count -gt 0 ] && [ $touch_file_count1 -gt 0 ] 
							then
								echo "`$DAYTIME` : Both touch files for $file_name are present." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
								export stg_table_name=`echo $line | cut -f1 -d .`
								export stg_id_table_name=`echo $stg_table_name"_ID"`
								export stg_table_count=`/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "select count(*) from swt_rpt_stg."$stg_table_name;`
								export stg_id_table_count=`/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "select count(*) from swt_rpt_stg."$stg_id_table_name;`
								if [ $stg_id_table_count -eq 0 ]
								then
									echo "`$DAYTIME` : $stg_id_table_name doesn't have any record. Skipping stage to base to avoid data loss." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
									echo -e " $stg_id_table_name doesn't have any record. Skipping stage to base to avoid data loss. Please check \n\n This is an automatic mail. Please do not respond. " | mailx -s "$DAY : ID table doesn't have any record while loading $stg_table_name data in $ENV" `cat $CONFIG/mail_recipient.txt`
									mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
                                    mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_ID_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
								elif [ $stg_table_count -gt 0 ]
								then
									echo " $stg_table_name count =  $stg_table_count , $stg_id_table_name count = $stg_id_table_count " >>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log

									LD_TBL_CNT=$((LD_TBL_CNT+1))
									ksh $SHELLDIR/Special_Cases.ksh $line $SUB_AREA $DAY
									if [ $? -eq 0 ]
									then
										EXC_TBL_CNT=$((EXC_TBL_CNT+1))
										CMPLT_LD_CNT=$((CMPLT_LD_CNT+1))
									else
										EXC_TBL_CNT=$((EXC_TBL_CNT+1))
									fi
								else
									echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Adding an entry into AUDIT table" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
									/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.FAST_LD_AUDT ( SUBJECT_AREA ,TBL_NM ,LD_DT ,START_DT_TIME ,END_DT_TIME ,SRC_REC_CNT ,TGT_REC_CNT ,COMPLTN_STAT ) select '$SUB_AREA','$stg_table_name',sysdate::date,sysdate,sysdate,0,0,'Y';commit;" >$LOGDIR/$line"_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err
									EXC_TBL_CNT=$((EXC_TBL_CNT+1))
									echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Moving touch file to archive" >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
									mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
									mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_ID_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
									fi
							loop_counter=$((loop_counter+1))
							else
								echo "`$DAYTIME` : $SUB_AREA : $line or `echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`_ID touch file doesn't exist. Skipping to next sql..." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
								echo $line >> pending_tables.txt
								rerun_flag=1
							fi
						elif [ "$line" == "NS_Transactions.sql" ]
						then
							echo "`$DAYTIME` : Checking for the touch files for $line and related deleted table to proceed further." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
							export file_name=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$DAY_TOUCH
							export file_name1="NETSUITE_NS_SS_DELETED_RECORDS_"$DAY_TOUCH
							export file_name2="NETSUITESS_NS_MISSING_TRANSACTION_TYPES_"$DAY_TOUCH
							export touch_file_count=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
							export touch_file_count1=`find $TOUCH_FILE_PATH/$file_name1*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
							export touch_file_count2=`find $TOUCH_FILE_PATH1/$file_name2*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
							if [ $touch_file_count -gt 0 ] && [ $touch_file_count1 -gt 0 ] && [ $touch_file_count2 -gt 0 ] 
							then
								echo "`$DAYTIME` : All three touch files for $file_name are present." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
								export stg_table_name=`echo $line | cut -f1 -d .`
								export stg_table_count=`/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "select count(*) from swt_rpt_stg."$stg_table_name;`
								if [ $stg_table_count -gt 0 ]
								then
									echo " $stg_table_name count =  $stg_table_count " >>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
									LD_TBL_CNT=$((LD_TBL_CNT+1))
									echo "`$DAYTIME` : Executing $line" >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
									/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all<$LOADDIR/$line>$LOGDIR/$line"_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err
									if [ $? -eq 0 ]
									then
										transaction_run=1
										EXC_TBL_CNT=$((EXC_TBL_CNT+1))
										CMPLT_LD_CNT=$((CMPLT_LD_CNT+1))
										mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
										mv $TOUCH_FILE_PATH/"NETSUITE_NS_SS_DELETED_RECORDS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
										mv $TOUCH_FILE_PATH1/"NETSUITESS_NS_MISSING_TRANSACTION_TYPES_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
									else
										EXC_TBL_CNT=$((EXC_TBL_CNT+1))
										mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
										mv $TOUCH_FILE_PATH/"NETSUITE_NS_SS_DELETED_RECORDS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
										mv $TOUCH_FILE_PATH1/"NETSUITESS_NS_MISSING_TRANSACTION_TYPES_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
										echo "`$DAYTIME` : $SUB_AREA : Error in executing $line. Check Vertica Log for error details" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
										echo -e "`$DAYTIME` : $SUB_AREA : Error in executing $line. Dependent tables might not get executed. \n\n" | mailx -s "$DAY : Error runnin $line In $ENV" `cat $CONFIG/mail_recipient.txt`
									fi
								else
									transaction_run=1
									echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Adding an entry into AUDIT table" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
									/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.FAST_LD_AUDT ( SUBJECT_AREA ,TBL_NM ,LD_DT ,START_DT_TIME ,END_DT_TIME ,SRC_REC_CNT ,TGT_REC_CNT ,COMPLTN_STAT ) select '$SUB_AREA','$stg_table_name',sysdate::date,sysdate,sysdate,0,0,'Y';commit;" >$LOGDIR/$line"_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err
									EXC_TBL_CNT=$((EXC_TBL_CNT+1))
									echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Moving touch file to archive" >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
									mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
									mv $TOUCH_FILE_PATH/"NETSUITE_NS_SS_DELETED_RECORDS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
									mv $TOUCH_FILE_PATH1/"NETSUITESS_NS_MISSING_TRANSACTION_TYPES_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
								fi
							loop_counter=$((loop_counter+1))
							else
								echo "`$DAYTIME` : $SUB_AREA : Any one or more touch file doesn't exist. Skipping to next sql..." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
								echo $line >> pending_tables.txt
								rerun_flag=1
							fi
						elif [ "$line" == "NS_Transaction_lines.sql" ]
						then
							echo "`$DAYTIME` : Checking for the touch files for $line and master table stage to base execution to proceed further." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
							export file_name=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$DAY_TOUCH
							export touch_file_count=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
							if [ $touch_file_count -gt 0 ] && [ $transaction_run -eq 1 ] 
							then
								echo "`$DAYTIME` : Touch files is present for $file_name and master table has been executed." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
								export stg_table_name=`echo $line | cut -f1 -d .`
								export stg_table_count=`/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "select count(*) from swt_rpt_stg."$stg_table_name;`
								if [ $stg_table_count -gt 0 ]
								then
									echo " $stg_table_name count =  $stg_table_count " >>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
									LD_TBL_CNT=$((LD_TBL_CNT+1))
									/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all<$LOADDIR/$line>$LOGDIR/$line"_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err
									if [ $? -eq 0 ]
									then
										EXC_TBL_CNT=$((EXC_TBL_CNT+1))
										CMPLT_LD_CNT=$((CMPLT_LD_CNT+1))
										mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
									else
										EXC_TBL_CNT=$((EXC_TBL_CNT+1))
										mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
										echo "`$DAYTIME` : $SUB_AREA : Error in executing $line. Check Vertica Log for error details" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
										echo -e "`$DAYTIME` : $SUB_AREA : Error in executing $line. Dependent tables might not get executed. \n\n" | mailx -s "$DAY : Error running $line In $ENV" `cat $CONFIG/mail_recipient.txt`
									fi
								else
									echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Adding an entry into AUDIT table" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
									/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.FAST_LD_AUDT ( SUBJECT_AREA ,TBL_NM ,LD_DT ,START_DT_TIME ,END_DT_TIME ,SRC_REC_CNT ,TGT_REC_CNT ,COMPLTN_STAT ) select '$SUB_AREA','$stg_table_name',sysdate::date,sysdate,sysdate,0,0,'Y';commit;" >$LOGDIR/$line"_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err
									EXC_TBL_CNT=$((EXC_TBL_CNT+1))
									echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Moving touch file to archive" >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
									mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
								fi
							loop_counter=$((loop_counter+1))
							else
								echo "`$DAYTIME` : $SUB_AREA : $line touch file doesn't exist or master table stage to base execution not run. Skipping to next sql..." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
								echo $line >> pending_tables.txt
								rerun_flag=1
							fi
						else
							export stg_table_name=`echo $line | cut -f1 -d .`
							export stg_table_count=`/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "select count(*) from swt_rpt_stg."$stg_table_name;`
							if [ $stg_table_count -gt 0 ]
							then
								LD_TBL_CNT=$((LD_TBL_CNT+1))
								echo "`$DAYTIME` : Executing $line" >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
								/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all<$LOADDIR/$line>$LOGDIR/$line"_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err
								if [ $? -eq 0 ]
								then
									EXC_TBL_CNT=$((EXC_TBL_CNT+1))
									CMPLT_LD_CNT=$((CMPLT_LD_CNT+1))
									if [ "$line" == "NS_USD_Extract_Open_Period.sql" ] || [ "$line" == "NS_USD_Extract_Closed_Period.sql" ]
									then
										mv $TOUCH_FILE_PATH1/$SUB_AREA1"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
									else
										mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
									fi
								else
									EXC_TBL_CNT=$((EXC_TBL_CNT+1))
									if [ "$line" == "NS_USD_Extract_Open_Period.sql" ] || [ "$line" == "NS_USD_Extract_Closed_Period.sql" ]
									then
										mv $TOUCH_FILE_PATH1/$SUB_AREA1"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
									else
										mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
									fi
									echo "`$DAYTIME` : $SUB_AREA : Error in executing $line. Check Vertica Log for error details" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
								fi
							else
								echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Adding an entry into AUDIT table" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
								/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.FAST_LD_AUDT ( SUBJECT_AREA ,TBL_NM ,LD_DT ,START_DT_TIME ,END_DT_TIME ,SRC_REC_CNT ,TGT_REC_CNT ,COMPLTN_STAT ) select '$SUB_AREA','$stg_table_name',sysdate::date,sysdate,sysdate,0,0,'Y';commit;" >$LOGDIR/$line"_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err
								EXC_TBL_CNT=$((EXC_TBL_CNT+1))
								echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Moving touch file to archive" >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
								if [ "$line" == "NS_USD_Extract_Open_Period.sql" ] || [ "$line" == "NS_USD_Extract_Closed_Period.sql" ]
								then
									mv $TOUCH_FILE_PATH1/$SUB_AREA1"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
								else
									mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
								fi
							fi
							loop_counter=$((loop_counter+1))
						fi
					elif [ $error_file_count -gt 0 ] 
					then
						export stg_table_name=`echo $line | cut -f1 -d .`
						echo "`$DAYTIME` : $SUB_AREA : $line error touch file exists. moving error files to archive" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
						if [ "$line" == "NS_USD_Extract_Open_Period.sql" ] || [ "$line" == "NS_USD_Extract_Closed_Period.sql" ]
						then
							mv $TOUCH_ERRORFILE_PATH1"/Exception_"$SUB_AREA1"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_ERRORFILE_PATH_ARCHIVE/
							EXC_TBL_CNT=$((EXC_TBL_CNT+1))
						else
							mv $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_ERRORFILE_PATH_ARCHIVE/
							EXC_TBL_CNT=$((EXC_TBL_CNT+1))
						fi
						
						loop_counter=$((loop_counter+1))
					else
						echo "`$DAYTIME` : $SUB_AREA : $line neither touch file nor error file exists. Skipping to next sql..." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
						echo $line >> pending_tables.txt
						rerun_flag=1
					fi
					done
			else
				sleep 600
				loop_counter=1
			fi
		fi
	done
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

else
	echo "`$DAYTIME` : $SUB_AREA : Unable to establish connection with database." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	echo "Unable to establish connection with database. Please check. This is an auto-generated email. Do not reply." | mailx -s "$DAY : Error connecting $ENV Database while trying to load $SUB_AREA" `cat $CONFIG/mail_recipient.txt`
	if [ $? -eq 0 ]                                                                 				### Checking the result code to check status of mail 
	then
		echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	else
		echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
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

#ksh $COMMONPATH/sh/PKG_ATDF_INTER_REFRESH.ksh
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






