#!/bin/ksh
#
#    version         1.6
#    author          Dharmatheja Bhat

#    HISTORY
#    18/05/2017 : Script Creation
#    19/05/2017 : SQL level logs, error files
#	 22/05/2017 : Updation of logic
#	 23/05/2017 : Addition of script level logging
#	 13/06/2017	: Additional checks
#	 25/07/2017 : Check and load the data only when data present in stage

###################################### DESCRIPTION #########################################
#	This script checks load order of NETSUITEOPENAIR tables from a text file NETSUITEOPENAIR_LOAD_ORDER.txt
#	and executes corresponding vsql commands written in sql files. Logging the outcome of 
#	each step is done to help debugging and an email is sent to support mail group with the
#	exact status of execution.
############################################################################################

###################################   INITIALIZATION  ######################################
#sleep 2700
export DAY=`date +%d_%m_%Y`
export DAYTIME='date +%d-%m-%Y-%H:%M:%S'
export SUB_AREA=NETSUITEOPENAIR
export TOTAL_TBL_CNT=74
export LD_TBL_CNT=0
export EXC_TBL_CNT=0
export ENV=SIT
export COMMONPATH=/home/omtsmgr/FAST
export LOGDIR=$COMMONPATH/logs/$SUB_AREA
export LOADDIR=$COMMONPATH/vsql/$SUB_AREA
export ERRORDIR=$COMMONPATH/error/$SUB_AREA
export ERRORARCHIVEDIR=$COMMONPATH/errorArchive/$SUB_AREA
export CONFIG=$COMMONPATH/config
export ARCHIVE=$COMMONPATH/archive/$SUB_AREA
#export TOUCH_FILE_PATH=$COMMONPATH/touchFiles/$SUB_AREA								
export HOST=$(grep $ENV $CONFIG/cred.config | cut -f 4 -d :)
export USER=$(grep $ENV $CONFIG/cred.config | cut -f 2 -d :)
export PASSWORD=$(grep $ENV $CONFIG/cred.config | cut -f 3 -d :)
export DB=$(grep $ENV $CONFIG/cred.config | cut -f 6 -d :)
export PORT=$(grep $ENV $CONFIG/cred.config | cut -f 5 -d :)

##############################################################################################

echo "`$DAYTIME` : $SUB_AREA : ####################Script started########################" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Directory paths for $SUB_AREA are set." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Extracted DB login related info from config file." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Checking database connectivity" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

/opt/Vertica/bin/vsql -l -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log      						###Checking Database Connection            
if [ $? -eq 0 ]                                                                 													### Checking the result code to check connectivity
then
	echo "`$DAYTIME` : $SUB_AREA : Database connection is successful." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	echo "`$DAYTIME` : $SUB_AREA : Executing the vsql for $SUB_AREA one by one" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	cd $LOADDIR
	for line in `cat $SUB_AREA"_LOAD_ORDER.txt"`; do    ### Reading the filenames in the order for executing respective sqls
		echo "`$DAYTIME` : $SUB_AREA : Checking for the $line file to proceed further." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		if [ -s $LOADDIR/$line ]
		then
			export stg_table_name=`echo $line | cut -f1 -d .`
			export stg_table_count=`/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "select count(*) from swt_rpt_stg."$stg_table_name;`
			if [ $stg_table_count -gt 0 ]
			then
				LD_TBL_CNT=$((LD_TBL_CNT+1))
				echo "`$DAYTIME` : $SUB_AREA : Executing $line" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
				/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all<$LOADDIR/$line>>$LOGDIR"/Vertica_Log_"$DAY.log 2> $ERRORDIR/$line"_"$DAY.err 
				if [ $? -eq 0 ]                                                                 			### Checking the result code to check connectivity
				then
					EXC_TBL_CNT=$((EXC_TBL_CNT+1))
				else
					:
				fi
			else
				echo "`$DAYTIME` : $SUB_AREA : Skipping execution of $line as the stage table does not have any record" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
			fi
		else
			echo "`$DAYTIME` : $SUB_AREA : $line file doesn't exist. sql execution stopped due to the dependency constraints." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		fi
	done	
	echo "`$DAYTIME` : $SUB_AREA : Execution vsql for $SUB_AREA is complete." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	echo "`$DAYTIME` : $SUB_AREA : Checking for vsql related errors" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	cd $ERRORDIR
	touch ERROR_INFO_$DAY.txt
	for file in *.err								 													### Check for error files wrt to sql files
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
	if [ -s ERROR_INFO_$DAY.txt ]          																							### Checking for error details to send status mail
	then 
		echo -e " This is just to inform you that errors occurred while loading $SUB_AREA data. List of errorful vsql names are attached. Please check $ERRORDIR for the error details.\n\n Total table count in $SUB_AREA = $TOTAL_TBL_CNT \n\n Total table count with data in stage = $LD_TBL_CNT \n\n Actual executed table count = $EXC_TBL_CNT \n\n\n\n This is an automatic mail. Please do not respond. " | mailx -a $ERRORDIR/ERROR_INFO_$DAY.txt -s "$DAY : Errors occurred while loading $SUB_AREA data" `cat $CONFIG/mail_recipient.txt`
		if [ $? -eq 0 ]                                                                 											### Checking the result code to check status of mail 
		then
			echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		else
			echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		fi
	else 
		if [ $EXC_TBL_CNT -eq $LD_TBL_CNT ] 
		then
			echo -e "This is an automatic mail. Please do not respond. This is just to inform you, $SUB_AREA Data Loaded successfully In $ENV.\n\n Total table count in $SUB_AREA = $TOTAL_TBL_CNT \n\n Total table count with data in stage = $LD_TBL_CNT \n\n Actual executed table count = $EXC_TBL_CNT \n\n" | mailx -s "$DAY : $SUB_AREA Data Loaded successfully In $ENV" `cat $CONFIG/mail_recipient.txt`
			if [ $? -eq 0 ]                                                                 										### Checking the result code to check status of mail 
			then
				echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
			else
				echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
			fi
		else
			echo -e "This is an automatic mail. Please do not respond. This is just to inform you, $SUB_AREA Data Loaded successfully In $ENV for the available vsql scripts.\n\n Total table count in $SUB_AREA = $TOTAL_TBL_CNT \n\n Total table count with data in stage = $LD_TBL_CNT \n\n Actual executed table count = $EXC_TBL_CNT \n\n " | mailx -s "$DAY : $SUB_AREA Data Loaded successfully In $ENV" `cat $CONFIG/mail_recipient.txt`
			if [ $? -eq 0 ]                                                                 										### Checking the result code to check status of mail 
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
	if [ $? -eq 0 ]                                                                 										### Checking the result code to check status of mail 
	then
		echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	else
		echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	fi
fi

echo "`$DAYTIME` : $SUB_AREA : Clean up activity begins..." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Removing older log/error files from archive." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

##### Remove 5 days or older files ########## 

find $ERRORARCHIVEDIR/*.err -type f -mtime +5 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $ERRORDIR/ERROR_INFO*.txt -type f -mtime +5 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $LOGDIR/*.log -type f -mtime +5 -exec rm -f {} \;>> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

echo "`$DAYTIME` : $SUB_AREA : Older log/error files are removed from archive." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Exiting script....." >> $LOGDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

exit 0


