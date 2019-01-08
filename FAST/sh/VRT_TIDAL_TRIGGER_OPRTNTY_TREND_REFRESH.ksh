#!/bin/ksh

export SUB_AREA=OPP_TREND
export DAY=`date +%d_%m_%Y`
export DAY_TOUCH=`date +%Y%m%d`
export DAYTIME='date +%d-%m-%Y-%H:%M:%S'
export YEAR=`date +%Y`
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
export LOADDIR=$COMMONPATH/misc
export CONFIG=$COMMONPATH/config
export HOST=$(grep $ENV $CONFIG/cred.config | cut -f 4 -d :)
export USER=$(grep $ENV $CONFIG/cred.config | cut -f 2 -d :)
export PASSWORD=$(grep $ENV $CONFIG/cred.config | cut -f 3 -d :)
export DB=$(grep $ENV $CONFIG/cred.config | cut -f 6 -d :)
export PORT=$(grep $ENV $CONFIG/cred.config | cut -f 5 -d :)

echo "`$DAYTIME` :  ####################Script started########################" >> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` :  Directory paths are set." >> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` :  Extracted DB login related info from config file." >> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log


echo "`$DAYTIME` :  Checking database connectivity" >> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

/opt/Vertica/bin/vsql -l -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD >> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
if [ $? -eq 0 ]                                                                                                                 ### Checking the result code to check connectivity
then
        echo "`$DAYTIME` :  Database connection is successful." >> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		/opt/Vertica/bin/vsql -E -e -a --echo-all -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD --echo-all<$LOADDIR/opportunity_trend_table.sql>$LOADDIR/"opportunity_trend_table_"$DAY.log 2> $LOADDIR/"opportunity_trend_table_"$DAY.err
		if [ $? -eq 0 ]
		then
			echo "Successfully executed the query for $SUB_AREA. Please check the logs for more details. This is an auto-generated email. Do not reply." | mailx -s "$DAY : $SUB_AREA updated succesfully in $ENV" `cat $CONFIG/mail_recipient.txt`
		else
			echo "Encountered some error while updating $SUB_AREA. Please check the logs for more details. This is an auto-generated email. Do not reply." | mailx -s "$DAY : Error in updating $SUB_AREA in $ENV" `cat $CONFIG/mail_recipient.txt`
		fi
else
	echo "`$DAYTIME` : $SUB_AREA : Unable to establish connection with database." >> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	echo "Unable to establish connection with database. Please check. This is an auto-generated email. Do not reply." | mailx -s "$DAY : Error connecting $ENV Database while trying to load $SUB_AREA" `cat $CONFIG/mail_recipient.txt`
	if [ $? -eq 0 ]                                                                 				### Checking the result code to check status of mail 
	then
		echo "`$DAYTIME` : $SUB_AREA : Status email has been sent." >> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	else
		echo "`$DAYTIME` : $SUB_AREA : Error in sending mail. Please check mail functionality" >> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	fi
fi

echo "`$DAYTIME` : $SUB_AREA : Clean up activity begins..." >> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Removing older log/error files from archive." >> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

####### Remove 5 days or older files ########## 

find $LOADDIR/ -type f -name "*.err" -mtime +5 -exec rm -f {} \;>> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
find $LOADDIR/ -type f -name "*.log" -mtime +5 -exec rm -f {} \;>> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

echo "`$DAYTIME` : $SUB_AREA : Older log/error files are removed from archive." >> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Exiting script....." >> $LOADDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

exit 0




