#!/bin/ksh

export DAY1=`date +%d_%m_%Y`
export DAYTIME='date +%Y%m%d_%H_%M_%S'
export SUB_AREA=EXPORT_Revenue_Sales_Legacy_Trx_REFRESH
export SUB_AREA1=EXPORT_Revenue_Adjust_REFRESH
export ENV=PRD
export MISCDIR=/home/omtsmgr/FAST/misc
export SCRIPT_PATH=/home/omtsmgr/FAST/sh
export VSQL_PATH=/home/omtsmgr/FAST/vsql
export CONFIG=/home/omtsmgr/FAST/config
export START_HOUR=`date +%H`
export HOST=$(grep $ENV $CONFIG/cred.config | cut -f 4 -d :)
export USER=$(grep $ENV $CONFIG/cred.config | cut -f 2 -d :)
export PASSWORD=$(grep $ENV $CONFIG/cred.config | cut -f 3 -d :)
export DB=$(grep $ENV $CONFIG/cred.config | cut -f 6 -d :)
export PORT=$(grep $ENV $CONFIG/cred.config | cut -f 5 -d :)

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

export cycle_nm="CYCLE-"$cycle_no
export DAY=$DAY1"_"$cycle_nm

/opt/Vertica/bin/vsql -l -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD >> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log                  
if [ $? -eq 0 ]                                                                 						### Checking the result code to check connectivity
then
		echo "`$DAYTIME` : $SUB_AREA : Database connection is successful." >> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		echo "`$DAYTIME` : $SUB_AREA : Invoking the insert statements." >> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		/opt/Vertica/bin/vsql -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -E -a <$VSQL_PATH/EXPORT_Revenue_Sales_Legacy_Trx_REFRESH.sql >$MISCDIR"/EXPORT_Revenue_Sales_Legacy_Trx_REFRESH"_$DAY.log 2>$MISCDIR"/EXPORT_Revenue_Sales_Legacy_Trx_REFRESH_"$DAY.log
		if [ $? -eq 0 ]
		then
			echo "`$DAYTIME` : $SUB_AREA : Successfully loaded $SUB_AREA ">> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
			echo -e " Data load into $SUB_AREA was successfull. \n\n This is an automated email" | mailx -s "$DAY : Data Loaded for $SUB_AREA" `cat $CONFIG"/"corp_bi_bcc_list.txt`
		else
			echo "`$DAYTIME` : $SUB_AREA : Some error while loading data into $SUB_AREA">> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
			echo -e " Data load into $SUB_AREA encountered some error. Please check the logs for more details. \n\n This is an automated email" | mailx -s "$DAY : Data Load to $SUB_AREA failed!!" `cat $CONFIG"/"corp_bi_bcc_list.txt`
		fi
		/opt/Vertica/bin/vsql -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -E -a <$VSQL_PATH/EXPORT_REV_ADJUST_TBL_REFRESH.sql >$MISCDIR"/EXPORT_REV_ADJUST_TBL_REFRESH"_$DAY.log 2>$MISCDIR"/EXPORT_REV_ADJUST_TBL_REFRESH_"$DAY.log
                if [ $? -eq 0 ]
                then
                        echo "`$DAYTIME` : $SUB_AREA1 : Successfully loaded $SUB_AREA1 ">> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
                        echo -e " Data load into $SUB_AREA1 was successfull. \n\n This is an automated email" | mailx -s "$DAY : Data Loaded for $SUB_AREA1" `cat $CONFIG"/"corp_bi_bcc_list.txt`
                else
                        echo "`$DAYTIME` : $SUB_AREA1 : Some error while loading data into $SUB_AREA1">> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
                        echo -e " Data load into $SUB_AREA1 encountered some error. Please check the logs for more details. \n\n This is an automated email" | mailx -s "$DAY : Data Load to $SUB_AREA1 failed!!" `cat $CONFIG"/"corp_bi_bcc_list.txt`
                fi
else
	echo "`$DAYTIME` : $SUB_AREA : Unable to establish connection with database." >> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	echo "Unable to establish connection with database. Please check. This is an auto-generated email. Do not reply." | mailx -s "$DAY : Error connecting $ENV Database while trying to load $SUB_AREA table" `cat $CONFIG"/"corp_bi_bcc_list.txt`
fi

find $MISCDIR/ -type f -name "*.log" -mtime +3 -exec rm -f {} \;>> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

echo "`$DAYTIME` : $SUB_AREA : Older log/error files are removed from archive." >> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Exiting script....." >> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

exit 0

