#!/bin/ksh
#
#    version         1.0
#    author          Sathees Mohan

#    HISTORY
#    08/08/2018 : Script Creation


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
export line=$1
export DAY1=$2
export EXEC_DATE=$3
export DAY_TOUCH=$4
export DAYTIME='date +%d-%m-%Y-%H:%M:%S'
export YEAR=$5
export START_TIME=$6
export START_HOUR=$7
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
#export COMMONPATH=/home/omtsmgr/FAST
export COMMONPATH=/opt/FAST
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
export CORPBI_GLDIR=/home/omtsmgr/CORP_BI/VERTICA_TOUCHFILE_GL
export CORPBI_GTMDIR=/home/omtsmgr/CORP_BI/VERTICA_TOUCHFILE_GTM						
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
	
	find $LOADDIR/$SUB_AREA"_LOAD.txt" -exec rm -f {} \;>> $LOGDIR/$line"_"$DAY.log 2>&1
	find $LOADDIR/pending_tables.txt -exec rm -f {} \;>> $LOGDIR/$line"_"$DAY.log 2>&1
	while [ $loop_counter -eq 1 ] #this loop will be alive till we get a touch file / cycle time elapse 
	do
		echo "`$DAYTIME` : $SUB_AREA : Checking the time elapsed for this run" >> $LOGDIR/$line"_"$DAY.log
		echo "`$DAYTIME` : $SUB_AREA : $((`date +%s`-START_TIME)) seconds elapsed" >> $LOGDIR/$line"_"$DAY.log
		if [ $((`date +%s`-START_TIME)) -gt 13500 ]
		then
			echo "`$DAYTIME` : $SUB_AREA : Breaking while loop as execution time crossed 3 hours 19 minutes" >> $LOGDIR/$line"_"$DAY.log
			timeout_flag=1
			break
		else
			echo "`$DAYTIME` : $SUB_AREA : Checking for today's touchfiles and writing to log" >> $LOGDIR/$line"_"$DAY.log
        	##find $TOUCH_FILE_PATH/*_$DAY_TOUCH*.txt -type f >> $LOGDIR/$line"_"$DAY.log 2>>$LOGDIR/$line"_"$DAY.log
			export file_name=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$DAY_TOUCH
            export NS_files_count=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
			export NSSS_files_count=`find $TOUCH_FILE_PATH1/$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
			export NS_errorfiles_count=`find $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
			export NSSS_errorfiles_count=`find $TOUCH_ERRORFILE_PATH1"/Exception_"$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
		
        	if [ $NS_files_count -gt 0 ] || [ $NSSS_files_count -gt 0 ] || [ $NS_errorfiles_count -gt 0 ] || [ $NSSS_errorfiles_count -gt 0 ]
			then
				if [ $rerun_flag -gt 0 ]
				then
					mv pending_tables.txt $SUB_AREA"_LOAD.txt"
				else
					cp $SUB_AREA"_LOAD_ORDER.txt" $SUB_AREA"_LOAD.txt"
				fi
				echo "`$DAYTIME` : Checking for the touch file to proceed further." >> $LOGDIR/$line"_"$DAY.log
				export file_name=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$DAY_TOUCH
				if [ "$line" == "NS_USD_Extract_Open_Period.sql" ] || [ "$line" == "NS_USD_Extract_Closed_Period.sql" ]
				then
					file_count=`find $TOUCH_FILE_PATH1/$SUB_AREA1"_"$file_name*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
					export error_file_count=`find $TOUCH_ERRORFILE_PATH1"/Exception_"$SUB_AREA1"_"$file_name*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
				else
					file_count=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
					export error_file_count=`find $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
				fi
				if [ $file_count -gt 0 ] && [ $error_file_count -eq 0 ]
				then
					if [ "$line" == "NS_Revenue_elements.sql" ] ||  [ "$line" == "NS_Revenue_plans.sql" ] || [ "$line" == "NS_Customers.sql" ] || [ "$line" == "NS_Entity.sql" ] || [ "$line" == "NS_Transaction_address.sql" ] || [ "$line"  == "NS_FAM_Depreciation_History.sql" ]
					then
						echo "`$DAYTIME` : Checking for the touch files for $line and related Id table to proceed further." >> $LOGDIR/$line"_"$DAY.log
						export file_name=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$DAY_TOUCH
						export file_name1=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_ID_"$DAY_TOUCH
						export touch_file_count=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
						export touch_file_count1=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name1*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
						if [ $touch_file_count -gt 0 ] && [ $touch_file_count1 -gt 0 ] 
						then
							echo "`$DAYTIME` : Both touch files for $file_name are present." >> $LOGDIR/$line"_"$DAY.log
							export stg_table_name=`echo $line | cut -f1 -d .`
							export stg_id_table_name=`echo $stg_table_name"_ID"`
							export stg_table_count=`/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "select count(*) from swt_rpt_stg."$stg_table_name;`
							export stg_id_table_count=`/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "select count(*) from swt_rpt_stg."$stg_id_table_name;`
							if [ $stg_id_table_count -eq 0 ]
							then
								echo "`$DAYTIME` : $stg_id_table_name doesn't have any record. Skipping stage to base to avoid data loss." >> $LOGDIR/$line"_"$DAY.log
								echo -e " $stg_id_table_name doesn't have any record. Skipping stage to base to avoid data loss. Please check \n\n This is an automatic mail. Please do not respond. " | mailx -s "$DAY : ID table doesn't have any record while loading $stg_table_name data in $ENV" `cat $CONFIG/mail_recipient.txt`
								mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
                                   mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_ID_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
							elif [ $stg_table_count -gt 0 ]
							then
								echo " $stg_table_name count =  $stg_table_count , $stg_id_table_name count = $stg_id_table_count " >>$LOGDIR/$line"_"$DAY.log

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
								echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Adding an entry into AUDIT table" >> $LOGDIR/$line"_"$DAY.log
								/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.FAST_LD_AUDT ( SUBJECT_AREA ,TBL_NM ,LD_DT ,START_DT_TIME ,END_DT_TIME ,SRC_REC_CNT ,TGT_REC_CNT ,COMPLTN_STAT ) select '$SUB_AREA','$stg_table_name',sysdate::date,sysdate,sysdate,0,0,'Y';commit;" >$LOGDIR/$line"_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err
								EXC_TBL_CNT=$((EXC_TBL_CNT+1))
								echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Moving touch file to archive" >> $LOGDIR/$line"_"$DAY.log
								mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
								mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_ID_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
								fi
						#loop_counter=$((loop_counter+1))
						loop_counter=0
						else
							echo "`$DAYTIME` : $SUB_AREA : $line or `echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`_ID touch file doesn't exist. Skipping to next sql..." >> $LOGDIR/$line"_"$DAY.log
							echo $line >> pending_tables.txt
							sleep 60
							rerun_flag=1
						fi
					elif [ "$line" == "NS_Transactions.sql" ]
					then
						echo "`$DAYTIME` : Checking for the touch files for $line and related deleted table to proceed further." >> $LOGDIR/$line"_"$DAY.log
						export file_name=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$DAY_TOUCH
						export file_name1="NETSUITE_NS_SS_DELETED_RECORDS_"$DAY_TOUCH
						export file_name2="NETSUITESS_NS_MISSING_TRANSACTION_TYPES_"$DAY_TOUCH
						export touch_file_count=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
						export touch_file_count1=`find $TOUCH_FILE_PATH/$file_name1*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
						export touch_file_count2=`find $TOUCH_FILE_PATH1/$file_name2*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
						if [ $touch_file_count -gt 0 ] && [ $touch_file_count1 -gt 0 ] && [ $touch_file_count2 -gt 0 ] 
						then
							echo "`$DAYTIME` : All three touch files for $file_name are present." >> $LOGDIR/$line"_"$DAY.log
							export stg_table_name=`echo $line | cut -f1 -d .`
							export stg_table_count=`/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "select count(*) from swt_rpt_stg."$stg_table_name;`
							if [ $stg_table_count -gt 0 ]
							then
								echo " $stg_table_name count =  $stg_table_count " >>$LOGDIR/$line"_"$DAY.log
								LD_TBL_CNT=$((LD_TBL_CNT+1))
								echo "`$DAYTIME` : Executing $line" >> $LOGDIR/$line"_"$DAY.log
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
									echo "`$DAYTIME` : $SUB_AREA : Error in executing $line. Check Vertica Log for error details" >> $LOGDIR/$line"_"$DAY.log
									echo -e "`$DAYTIME` : $SUB_AREA : Error in executing $line. Dependent tables might not get executed. \n\n" | mailx -s "$DAY : Error runnin $line In $ENV" `cat $CONFIG/mail_recipient.txt`
								fi
							else
								transaction_run=1
								echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Adding an entry into AUDIT table" >> $LOGDIR/$line"_"$DAY.log
								/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.FAST_LD_AUDT ( SUBJECT_AREA ,TBL_NM ,LD_DT ,START_DT_TIME ,END_DT_TIME ,SRC_REC_CNT ,TGT_REC_CNT ,COMPLTN_STAT ) select '$SUB_AREA','$stg_table_name',sysdate::date,sysdate,sysdate,0,0,'Y';commit;" >$LOGDIR/$line"_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err
								EXC_TBL_CNT=$((EXC_TBL_CNT+1))
								echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Moving touch file to archive" >> $LOGDIR/$line"_"$DAY.log
								mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
								mv $TOUCH_FILE_PATH/"NETSUITE_NS_SS_DELETED_RECORDS_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
								mv $TOUCH_FILE_PATH1/"NETSUITESS_NS_MISSING_TRANSACTION_TYPES_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
							fi
						#loop_counter=$((loop_counter+1))
						loop_counter=0
						else
							echo "`$DAYTIME` : $SUB_AREA : Any one or more touch file doesn't exist. Skipping to next sql..." >> $LOGDIR/$line"_"$DAY.log
							echo $line >> pending_tables.txt
							sleep 60
							rerun_flag=1
						fi
					elif [ "$line" == "NS_Transaction_lines.sql" ]
					then
						echo "`$DAYTIME` : Checking for the touch files for $line and master table stage to base execution to proceed further." >> $LOGDIR/$line"_"$DAY.log
						export file_name=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$DAY_TOUCH
						export touch_file_count=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l` 2>>$LOGDIR/$line"_"$DAY.log
						transaction_run=`find $LOGDIR"/NS_Transactions.sql_"$EXEC_DATE"_"$cycle_no"_END_EXECUTED.txt" -maxdepth 1 -type f | wc -l` 2>> $LOGDIR/$line"_"$DAY.log
						if [ $touch_file_count -gt 0 ] && [ $transaction_run -eq 1 ] 
						then
							echo "`$DAYTIME` : Touch files is present for $file_name and master table has been executed." >> $LOGDIR/$line"_"$DAY.log
							export stg_table_name=`echo $line | cut -f1 -d .`
							export stg_table_count=`/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "select count(*) from swt_rpt_stg."$stg_table_name;`
							if [ $stg_table_count -gt 0 ]
							then
								echo " $stg_table_name count =  $stg_table_count " >>$LOGDIR/$line"_"$DAY.log
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
									echo "`$DAYTIME` : $SUB_AREA : Error in executing $line. Check Vertica Log for error details" >> $LOGDIR/$line"_"$DAY.log
									echo -e "`$DAYTIME` : $SUB_AREA : Error in executing $line. Dependent tables might not get executed. \n\n" | mailx -s "$DAY : Error running $line In $ENV" `cat $CONFIG/mail_recipient.txt`
								fi
							else
								echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Adding an entry into AUDIT table" >> $LOGDIR/$line"_"$DAY.log
								/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.FAST_LD_AUDT ( SUBJECT_AREA ,TBL_NM ,LD_DT ,START_DT_TIME ,END_DT_TIME ,SRC_REC_CNT ,TGT_REC_CNT ,COMPLTN_STAT ) select '$SUB_AREA','$stg_table_name',sysdate::date,sysdate,sysdate,0,0,'Y';commit;" >$LOGDIR/$line"_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err
								EXC_TBL_CNT=$((EXC_TBL_CNT+1))
								echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Moving touch file to archive" >> $LOGDIR/$line"_"$DAY.log
								mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
							fi
						#loop_counter=$((loop_counter+1))
						loop_counter=0
						else
							echo "`$DAYTIME` : $SUB_AREA : $line touch file doesn't exist or master table stage to base execution not run. Skipping to next sql..." >> $LOGDIR/$line"_"$DAY.log
							echo $line >> pending_tables.txt
							sleep 60
							rerun_flag=1
						fi
					else
						export stg_table_name=`echo $line | cut -f1 -d .`
						export stg_table_count=`/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "select count(*) from swt_rpt_stg."$stg_table_name;`
						if [ $stg_table_count -gt 0 ]
						then
							LD_TBL_CNT=$((LD_TBL_CNT+1))
							echo "`$DAYTIME` : Executing $line" >> $LOGDIR/$line"_"$DAY.log
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
								echo "`$DAYTIME` : $SUB_AREA : Error in executing $line. Check Vertica Log for error details" >> $LOGDIR/$line"_"$DAY.log
							fi
						else
							echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Adding an entry into AUDIT table" >> $LOGDIR/$line"_"$DAY.log
							/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.FAST_LD_AUDT ( SUBJECT_AREA ,TBL_NM ,LD_DT ,START_DT_TIME ,END_DT_TIME ,SRC_REC_CNT ,TGT_REC_CNT ,COMPLTN_STAT ) select '$SUB_AREA','$stg_table_name',sysdate::date,sysdate,sysdate,0,0,'Y';commit;" >$LOGDIR/$line"_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err
							EXC_TBL_CNT=$((EXC_TBL_CNT+1))
							echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Moving touch file to archive" >> $LOGDIR/$line"_"$DAY.log
							if [ "$line" == "NS_USD_Extract_Open_Period.sql" ] || [ "$line" == "NS_USD_Extract_Closed_Period.sql" ]
							then
								mv $TOUCH_FILE_PATH1/$SUB_AREA1"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
							else
								mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
							fi
						fi
						#loop_counter=$((loop_counter+1))
						loop_counter=0
					fi
				elif [ $error_file_count -gt 0 ] 
				then
					export stg_table_name=`echo $line | cut -f1 -d .`
					echo "`$DAYTIME` : $SUB_AREA : $line error touch file exists. moving error files to archive" >> $LOGDIR/$line"_"$DAY.log
					if [ "$line" == "NS_USD_Extract_Open_Period.sql" ] || [ "$line" == "NS_USD_Extract_Closed_Period.sql" ]
					then
						mv $TOUCH_ERRORFILE_PATH1"/Exception_"$SUB_AREA1"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_ERRORFILE_PATH_ARCHIVE/
						EXC_TBL_CNT=$((EXC_TBL_CNT+1))
					else
						mv $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_ERRORFILE_PATH_ARCHIVE/
						EXC_TBL_CNT=$((EXC_TBL_CNT+1))
					fi
					
					#loop_counter=$((loop_counter+1))
					loop_counter=0
				else
					echo "`$DAYTIME` : $SUB_AREA : $line neither touch file nor error file exists. Skipping to next sql..." >> $LOGDIR/$line"_"$DAY.log
					echo $line >> pending_tables.txt
					sleep 60
					rerun_flag=1
				fi
			else
				sleep 60
				loop_counter=1
			fi
		fi
	done
else
	echo "`$DAYTIME` : $SUB_AREA : Unable to establish connection with database." >> $LOGDIR/$line"_"$DAY.log
	echo "Unable to establish connection with database. Please check. This is an auto-generated email. Do not reply." | mailx -s "$DAY : Error connecting $ENV Database while trying to load $SUB_AREA" `cat $CONFIG/mail_recipient.txt`
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





