#!/bin/ksh

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
export COMMONPATH=/opt/FAST
export MULETOUCHPATH=/home/omtsmgr/FAST
export MISCDIR=$COMMONPATH/misc
export SHELLDIR=$COMMONPATH/sh
export CONFIG=$COMMONPATH/config
export TOUCH_FILE_PATH=$MULETOUCHPATH/muleTouchFiles						
export HOST=$(grep $ENV $CONFIG/cred.config | cut -f 4 -d :)
export USER=$(grep $ENV $CONFIG/cred.config | cut -f 2 -d :)
export PASSWORD=$(grep $ENV $CONFIG/cred.config | cut -f 3 -d :)
export DB=$(grep $ENV $CONFIG/cred.config | cut -f 6 -d :)
export PORT=$(grep $ENV $CONFIG/cred.config | cut -f 5 -d :)

for SUB_AREA in `cat $MISCDIR"/"ZERO_BYTE_SUB_AREA.txt`; do
	sub_length1=`echo -n $SUB_AREA | wc -m`
	sub_length=$((sub_length1+2))
	
	for files in `ls $TOUCH_FILE_PATH"/"$SUB_AREA"/"`; do
	file_1=`echo $files | cut -f1 -d .`
	TBL_NM=`echo $file_1 | sed -e s/[^a-zA-Z_]//g | cut -c $sub_length- | sed 's/.$//'`
	echo $TBL_NM
	file_date1=`echo $file_1 | sed -e s/[^0-9]//g | awk '{print substr($0,1,8) }'`
	file_hour=`echo $file_1 | sed -e s/[^0-9]//g | awk '{print substr($0,9,2) }'`
	file_minute=`echo $file_1 | sed -e s/[^0-9]//g | awk '{print substr($0,11,2) }'`
	echo $file_date1
	file_date=`date -d $file_date1 +%Y-%m-%d`
	
	if [ "$SUB_AREA" == "SFDC" ] || [ "$SUB_AREA" == "APTTUS" ]
	then
		if ((10#$file_hour<2))
		then
			export cycle_no=1
		elif ((2<=10#$file_hour && 10#$file_hour<4))
		then
			export cycle_no=2
		elif ((4<=10#$file_hour && 10#$file_hour<6))
		then
			export cycle_no=3
		elif ((6<=10#$file_hour && 10#$file_hour<8))
		then
			export cycle_no=4
		elif ((8<=10#$file_hour && 10#$file_hour<10))
		then
			export cycle_no=5
		elif ((10<=10#$file_hour && 10#$file_hour<12))
		then
			export cycle_no=6
		elif ((12<=10#$file_hour && 10#$file_hour<14))
		then
			export cycle_no=7
		elif ((14<=10#$file_hour && 10#$file_hour<16))
		then
			export cycle_no=8
		elif ((16<=10#$file_hour && 10#$file_hour<18))
		then
			export cycle_no=9
		elif ((18<=10#$file_hour && 10#$file_hour<20))
		then
			export cycle_no=10
		elif ((20<=10#$file_hour && 10#$file_hour<22))
		then
			export cycle_no=11
		elif ((22<=10#$file_hour))
		then
				export cycle_no=12
		else
				export cycle_no=0
		fi
	elif [ "$SUB_AREA" == "NETSUITE" ]
	then
		if ((10#$file_hour<4))
		then
			export cycle_no=1
		elif ((4<=10#$file_hour && 10#$file_hour<8))
		then
			export cycle_no=2
		elif ((8<=10#$file_hour && 10#$file_hour<12))
		then
			export cycle_no=3
		elif ((12<=10#$file_hour && 10#$file_hour<16))
		then
			export cycle_no=4
		elif ((16<=10#$file_hour && 10#$file_hour<20))
		then
			export cycle_no=5
		elif ((20<=10#$file_hour ))
		then
			export cycle_no=6
		else
				export cycle_no=0
		fi
	fi	

	/opt/Vertica/bin/vsql -t -h $HOST -p $PORT -d $DB -U $USER -w $PASSWORD -c "insert into swt_rpt_stg.ZERO_BYTE_FILE_ENTRIES(SUBJECT_AREA,TBL_NM,LD_DT,CYCLE,ZERO_BYTE_FILE_RECEIVED) values ('$SUB_AREA','$TBL_NM','$file_date',$cycle_no,'Yes');commit;"
	done
done
exit 0

