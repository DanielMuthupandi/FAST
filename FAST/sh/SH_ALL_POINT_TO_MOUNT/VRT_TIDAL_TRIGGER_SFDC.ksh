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
#    18/12/2017 : Addition of special case handling involving deletes in specific tables.
#    03/01/2018 : Duplicate records check in base tables using key columns added
#	 16/07/2018 : routing all Logs,VSQL,ERROR Directory,ERRORARCHIVEDIR,CONFIG,ARCHIVE,MULE_TOUCH_FILE_ARCHIVE paths to MOUNTPATH(/opt/FAST) and MULE_TOUCH_FILE_PATH,MULE_TOUCH_ERRORFILE_PATH, Executive Report Path to COMMONPATH(/home/omtsmgr/FAST)
#	 20/07/2018 : routing all Logs,VSQL,ERROR Directory,ERRORARCHIVEDIR,CONFIG,ARCHIVE,MULE_TOUCH_FILE_ARCHIVE,MULE_TOUCH_FILE_PATH,MULE_TOUCH_ERRORFILE_PATH paths to new MOUNTPATH(/opt/FAST) from (/home/omtsmgr/FAST)

###################################### DESCRIPTION #########################################
#	This script checks load order of SFDC tables from a text file SFDC_LOAD_ORDER.txt
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
export SUB_AREA=SFDC
export TBL_CNT=84
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
export SHELLDIR=$COMMONPATH/sh					
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
	touch $LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv
	while [ $EXC_TBL_CNT -lt $TBL_CNT ] 
	do
		echo "`$DAYTIME` : $SUB_AREA : Checking the time elapsed for this run" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		echo "`$DAYTIME` : $SUB_AREA : $((`date +%s`-START_TIME)) seconds elapsed" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		if [ $((`date +%s`-START_TIME)) -gt 4740 ]
		then
			echo "`$DAYTIME` : $SUB_AREA : Breaking while loop as execution time crossed 1 hour 19 minutes" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
			timeout_flag=1
			break
		else
			if [ $loop_counter -eq 0 ]
			then
				echo "Going for sleep (10 mins) as there were no successful execution in last loop... ">> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
				sleep 600
				echo "Waking up from sleep">> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
			else
				echo "At least one table got executed in last loop or returing from sleep" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
			fi
			loop_counter=0
			echo "`$DAYTIME` : $SUB_AREA : Checking for today's touchfiles and writing to log" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
            ##find $TOUCH_FILE_PATH/*_$DAY_TOUCH*.txt -type f >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log 2>>$LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
            export files_count=`find $TOUCH_FILE_PATH/*_$DAY_TOUCH*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
			export errorfiles_count=`find $TOUCH_ERRORFILE_PATH/Exception*_$DAY_TOUCH*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
			if [ $files_count -gt 0 ] || [ $errorfiles_count -gt 0 ] 
			then
				if [ $rerun_flag -gt 0 ]
				then
					mv pending_tables.txt $SUB_AREA"_LOAD.txt"
				else
					cp $SUB_AREA"_LOAD_ORDER.txt" $SUB_AREA"_LOAD.txt"
				fi
				for line in `cat $SUB_AREA"_LOAD.txt"`; do    ### Reading the filenames in the order for executing respective sqls
					if [ $((`date +%s`-START_TIME)) -gt 4740 ]
			                then
                        			echo "`$DAYTIME` : $SUB_AREA : Breaking while loop as execution time crossed 1 hour 19 minutes" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
                		       		break
					fi
					echo "`$DAYTIME` : Checking for the touch file to proceed further." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
					if [ $line == "SF_OpportunityLineItem.sql" ] 
					then
						echo "`$DAYTIME` : Checking for the touch files for $line and related Id table to proceed further." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
						export file_name=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$DAY_TOUCH
						export file_name1=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_ID_"$DAY_TOUCH
						export file_count=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
						export file_count1=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name1*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
						export error_file_count=`find $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
						export error_file_count1=`find $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"$file_name1*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
						export stg_table_name=`echo $line | cut -f1 -d .`
						if [ $file_count -gt 0 ] && [ $file_count1 -gt 0 ] 
						then
							echo "`$DAYTIME` : Both touch files for $file_name are present." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
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
								LD_TBL_CNT=$((LD_TBL_CNT+1))
								echo "`$DAYTIME` : Executing the vsql using Special_Cases.ksh script in $SHELLDIR" >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
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
							dup_count=`/opt/Vertica/bin/vsql -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -t -c "SELECT COUNT(*) FROM (SELECT ID,count(ID) FROM swt_rpt_base.$stg_table_name group by ID  having count(ID)>1)A;"`
							if [ $dup_count -gt 0 ]
							then
								echo "`$DAYTIME` : $SUB_AREA : $stg_table_name base table has duplicate records." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
								echo "$EXEC_DATE,$cycle_no,$SUB_AREA,$stg_table_name,$dup_count" >> $LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv
							else
								echo "`$DAYTIME` : $SUB_AREA : $stg_table_name base table doesnt have duplicate records." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
							fi
						elif [ $error_file_count -gt 0 ] && [ $file_count -eq 0 ]
						then
							echo "`$DAYTIME` : $SUB_AREA : Error file received for $line and clearing stage table." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
							echo -e " Error touch file recieved for the $stg_table_name and hence truncating the stage table for consistency. " | mailx -s "$DAY : Truncated swt_rpt_stg.$stg_table_name in $ENV" `cat $CONFIG/mail_recipient.txt`
							export stg_table_name=`echo $line | cut -f1 -d .`
							/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "TRUNCATE TABLE swt_rpt_stg.SF_OpportunityLineItem;TRUNCATE TABLE swt_rpt_stg.SF_OpportunityLineItem_ID;" >>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
							loop_counter=$((loop_counter+1))
							EXC_TBL_CNT=$((EXC_TBL_CNT+1))
							mv $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_ERRORFILE_PATH_ARCHIVE/
							mv $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_ID_"$YEAR*.txt $TOUCH_ERRORFILE_PATH_ARCHIVE/
						elif [ $error_file_count1 -gt 0 ] && [ $file_count1 -eq 0 ]
						then
							echo '`$DAYTIME` : $SUB_AREA : Error file received for $line"_ID" and clearing stage table.' >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
							/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "TRUNCATE TABLE swt_rpt_stg.SF_OpportunityLineItem_ID;" >>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
						elif [ $error_file_count -gt 0 ] && [ $file_count -gt 0 ]
						then
							echo "`$DAYTIME` : $SUB_AREA : Both success file and error files received. Not processing stage to base for the $stg_table_name" >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
							echo -e " Both Error touch file and success files recieved for the $stg_table_name and hence manual check is needed. " | mailx -s "$DAY : Please check swt_rpt_stg.$stg_table_name in $ENV" `cat $CONFIG/mail_recipient.txt`
							mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
							mv $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_ERRORFILE_PATH_ARCHIVE/
						else
							echo "`$DAYTIME` : $SUB_AREA : $line or `echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`_ID touch file doesn't exist. Skipping to next sql..." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
							echo $line >> pending_tables.txt
							rerun_flag=1
						fi
						
					else		
						export file_name=`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$DAY_TOUCH
						export file_count=`find $TOUCH_FILE_PATH/$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
						export error_file_count=`find $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"$file_name*.txt -maxdepth 1 -type f | wc -l 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log`
						export stg_table_name=`echo $line | cut -f1 -d .`
						if [ $file_count -gt 0 ] && [ $error_file_count -eq 0 ]
						then
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
									mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
								else
									EXC_TBL_CNT=$((EXC_TBL_CNT+1))
									mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
									echo "`$DAYTIME` : $SUB_AREA : Error in executing $line. Check Vertica Log for error details" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
								fi
							else
								echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Adding an entry into AUDIT table" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
								/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "INSERT INTO swt_rpt_stg.FAST_LD_AUDT ( SUBJECT_AREA ,TBL_NM ,LD_DT ,START_DT_TIME ,END_DT_TIME ,SRC_REC_CNT ,TGT_REC_CNT ,COMPLTN_STAT ) select '$SUB_AREA','$stg_table_name',sysdate::date,sysdate,sysdate,0,0,'Y';commit;" >$LOGDIR/$line"_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err
								EXC_TBL_CNT=$((EXC_TBL_CNT+1))
								echo "`$DAYTIME` : $SUB_AREA : Stage table $stg_table_name does not have any record. Moving touch file to archive" >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
								mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
							fi
							loop_counter=$((loop_counter+1))
							dup_count=`/opt/Vertica/bin/vsql -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -t -c "SELECT COUNT(*) FROM (SELECT ID,count(ID) FROM swt_rpt_base.$stg_table_name group by ID  having count(ID)>1)A;"`
							if [ $dup_count -gt 0 ]
							then
								echo "`$DAYTIME` : $SUB_AREA : $stg_table_name base table has duplicate records." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
								echo "$EXEC_DATE,$cycle_no,$SUB_AREA,$stg_table_name,$dup_count" >> $LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv
							else
								echo "`$DAYTIME` : $SUB_AREA : $stg_table_name base table doesnt have duplicate records." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
							fi
						elif [ $error_file_count -gt 0 ] && [ $file_count -eq 0 ]
						then
							echo "`$DAYTIME` : $SUB_AREA : Error file received for $line and clearing stage table." >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
							echo -e " Error touch file recieved for the $stg_table_name and hence truncating the stage table for consistency. " | mailx -s "$DAY : Truncated swt_rpt_stg.$stg_table_name in $ENV" `cat $CONFIG/mail_recipient.txt`
							export stg_table_name=`echo $line | cut -f1 -d .`
							/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "TRUNCATE TABLE swt_rpt_stg.$stg_table_name;" >>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log 2>>$LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
							loop_counter=$((loop_counter+1))
							EXC_TBL_CNT=$((EXC_TBL_CNT+1))
							mv $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_ERRORFILE_PATH_ARCHIVE/
						elif [ $error_file_count -gt 0 ] && [ $file_count -gt 0 ]
						then
							echo "`$DAYTIME` : $SUB_AREA : Both success file and error files received. Not processing stage to base for the $stg_table_name" >> $LOGDIR/$SUB_AREA"_Script_Log_"$DAY.log
							echo -e " Both Error touch file and success files recieved for the $stg_table_name and hence manual check is needed. " | mailx -s "$DAY : Please check swt_rpt_stg.$stg_table_name in $ENV" `cat $CONFIG/mail_recipient.txt`
							mv $TOUCH_FILE_PATH/$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/
							mv $TOUCH_ERRORFILE_PATH"/Exception_"$SUB_AREA"_"`echo $line | tr '[a-z]' '[A-Z]' | cut -f1 -d .`"_"$YEAR*.txt $TOUCH_ERRORFILE_PATH_ARCHIVE/
						else
							echo "`$DAYTIME` : $SUB_AREA : $line touch file doesn't exist. Skipping to next sql..." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
							echo $line >> pending_tables.txt
							rerun_flag=1
						fi
					fi
					done
			else
				echo "Going for sleep">> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
				sleep 600
				echo "Waking up from sleep">> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
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
	echo "`$DAYTIME` : $SUB_AREA : Sending email regarding the status of sql execution." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	if [ -s $LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv ]
	then
		echo "`$DAYTIME` : $SUB_AREA : Loading duplicate record details to a table" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all -c "COPY swt_rpt_stg.DUPLICATE_RECORD_TRACKING from local '$LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv' EXCEPTIONS '$LOGDIR"/"$SUB_AREA"_Duplicate_Record_exc.txt"' REJECTED DATA '$LOGDIR"/"$SUB_AREA"_Duplicate_Record_rej.txt"' ESCAPE AS E'\030' DELIMITER ',' NULL '';" >>$LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log 2>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		if [ $? -eq 0 ]                                                                 		### Checking the result code to check status of mail 
		then
			echo "`$DAYTIME` : $SUB_AREA : No issues while loadin gthe duplicate details." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		else
			echo -e " Failed loading duplicate records in $SUB_AREA base tables to the table.\n\n This is an automatic mail. Please do not respond. " | mailx -s "$DAY : Failed loading duplicate records in $SUB_AREA base tables to table in $ENV" `cat $CONFIG/mail_recipient.txt`
		fi
		echo -e " There are duplicate records in $SUB_AREA base tables and requires a cleanup.\n\n Please check the attached file.\n\n This is an automatic mail. Please do not respond. " | mailx -a $LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv -s "$DAY : Duplicate records in $SUB_AREA base tables in $ENV" `cat $CONFIG/mail_recipient.txt`
	fi
	if [ -s ERROR_INFO_$DAY.txt ]          															### Checking for error details to send status mail
	then 
		echo -e " This is just to inform you that errors occurred while loading $SUB_AREA data. List of errorful vsql names are attached. Please check $ERRORDIR for the error details.\n\n Total table count in $SUB_AREA = $TBL_CNT \n\nTotal table count with data in stage = $LD_TBL_CNT \n\nActual executed table count = $CMPLT_LD_CNT \n\n \n\n This is an automatic mail. Please do not respond. " | mailx -a $ERRORDIR/ERROR_INFO_$DAY.txt -s "$DAY : Errors occurred while loading $SUB_AREA data in $ENV" `cat $CONFIG/mail_recipient.txt`
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
			echo -e "This is an automatic mail. Please do not respond. This is just to inform you, $SUB_AREA Data Loaded timed out In $ENV waiting for zero byte files. Below is the load status \n\n Total table count in $SUB_AREA = $TBL_CNT \n\n Total table count with data in stage = $LD_TBL_CNT \n\n Actual executed table count = $CMPLT_LD_CNT \n\n "| mailx -s "$DAY : $SUB_AREA Data Loaded successfully In $ENV" `cat $CONFIG/mail_recipient.txt`
			if [ $? -eq 0 ]                                                                 			### Checking the result code to check status of mail 
			then
				echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
			else
				echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
			fi
		else
			echo -e "This is an automatic mail. Please do not respond. This is just to inform you, $SUB_AREA Data Loaded successfully In $ENV for the tables with data in stage.\n\n Total table count in $SUB_AREA = $TBL_CNT \n\n Total table count with data in stage = $LD_TBL_CNT \n\n Actual executed table count = $CMPLT_LD_CNT \n\n " | mailx -s "$DAY : $SUB_AREA Data Loaded successfully In $ENV" `cat $CONFIG/mail_recipient.txt`
            if [ $? -eq 0 ]                                                                               ### Checking the result code to check status of mail
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
mv $LOGDIR"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv $ARCHIVE"/"$SUB_AREA"_Duplicate_Record_Details_"$DAY.csv
echo "`$DAYTIME` : $SUB_AREA : Removing older log/error files from archive." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

####### Remove 3 days or older files ########## 

find $ERRORARCHIVEDIR/ -type f -name "*.err" -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $ERRORARCHIVEDIR/ERROR_INFO*.txt -type f -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $ERRORDIR/ERROR_INFO*.txt -type f -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $LOGDIR/ -type f -name "*.log" -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $ARCHIVE/ -type f -name "*.csv" -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $TOUCH_FILE_ARCHIVE/ -type f -name "*.txt" -mtime +3 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

#echo "Clearing swt_rpt_stg.SF_OpportunityLineItem_ID table for consistency..." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "TRUNCATE TABLE swt_rpt_stg.SF_OpportunityLineItem_ID;" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
mv $TOUCH_FILE_PATH/$SUB_AREA"_SF_OPPORTUNITYLINEITEM_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/
mv $TOUCH_FILE_PATH/$SUB_AREA"_SF_OPPORTUNITYLINEITEM_ID_"$YEAR*.txt $TOUCH_FILE_ARCHIVE/unprocessed/

echo "Invoking data load into swt_rpt_pkg.Opportunity_Line_Item table from views">> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
ksh $COMMONPATH/sh/PACKAGE_LAYER_TABLE_INSERT.ksh 

echo "`$DAYTIME` : $SUB_AREA : Older log/error files are removed from archive." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Exiting script....." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

exit 0





