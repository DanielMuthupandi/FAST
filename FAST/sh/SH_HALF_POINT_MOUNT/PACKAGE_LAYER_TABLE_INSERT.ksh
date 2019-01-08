#!/bin/ksh


### This script will insert data into swt_rpt_pkg.Opportunity_Line_Item table from views Opportunity_Line_Item_Vw and Opportunity_Line_Item_PS_Vw

export DAY1=`date +%d_%m_%Y`
export DAYTIME='date +%Y%m%d_%H_%M_%S'
export SUB_AREA=PKG
export ENV=PRD
export MISCDIR=/opt/FAST/misc
export SCRIPT_PATH=/opt/FAST/sh
export VSQL_PATH=/opt/FAST/vsql
export CONFIG=/opt/FAST/config
export START_HOUR=`date +%H`
export HOST=$(grep $ENV $CONFIG/cred.config | cut -f 4 -d :)
export USER=$(grep $ENV $CONFIG/cred.config | cut -f 2 -d :)
export PASSWORD=$(grep $ENV $CONFIG/cred.config | cut -f 3 -d :)
export DB=$(grep $ENV $CONFIG/cred.config | cut -f 6 -d :)
export PORT=$(grep $ENV $CONFIG/cred.config | cut -f 5 -d :)

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

/opt/Vertica/bin/vsql -l -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD >> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log                  
if [ $? -eq 0 ]                                                                 						### Checking the result code to check connectivity
then
		echo "`$DAYTIME` : $SUB_AREA : Database connection is successful." >> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		echo "`$DAYTIME` : $SUB_AREA : Invoking the insert statements." >> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
		/opt/Vertica/bin/vsql -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -E -a <$VSQL_PATH/PKG_TBL_INSERT.sql >$MISCDIR"/PKG_TBL_INSERT"_$DAY.log 2>$MISCDIR"/PKG_TBL_INSERT_"$DAY.log
		if [ $? -eq 0 ]
		then
			echo "`$DAYTIME` : $SUB_AREA : Successfully loaded data into swt_rpt_pkg.Opportunity_Line_Item table ">> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
			echo -e " Data load into swt_rpt_pkg.Opportunity_Line_Item was successfull. \n\n This is an automated email" | mailx -s "$DAY : Data Loaded to swt_rpt_pkg.Opportunity_Line_Item" `cat $CONFIG"/"corp_bi_bcc_list.txt`
		else
			echo "`$DAYTIME` : $SUB_AREA : Some error while loading data into swt_rpt_pkg.Opportunity_Line_Item table">> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
			echo -e " Data load into swt_rpt_pkg.Opportunity_Line_Item encountered some error. Please check the logs for more details. \n\n This is an automated email" | mailx -s "$DAY : Data Load to swt_rpt_pkg.Opportunity_Line_Item failed!!" `cat $CONFIG"/"corp_bi_bcc_list.txt`
		fi
else
	echo "`$DAYTIME` : $SUB_AREA : Unable to establish connection with database." >> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
	echo "Unable to establish connection with database. Please check. This is an auto-generated email. Do not reply." | mailx -s "$DAY : Error connecting $ENV Database while trying to load swt_rpt_pkg.Opportunity_Line_Item table" `cat $CONFIG"/"corp_bi_bcc_list.txt`
fi

find $MISCDIR/ -type f -name "*.log" -mtime +3 -exec rm -f {} \;>> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

echo "`$DAYTIME` : $SUB_AREA : Older log/error files are removed from archive." >> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log
echo "`$DAYTIME` : $SUB_AREA : Exiting script....." >> $MISCDIR"/"$SUB_AREA"_Script_Log_"$DAY.log

exit 0

