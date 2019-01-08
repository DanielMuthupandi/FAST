#!/bin/ksh
#### PLEASE ONLY CHANGE THE PARTS WHERE THE LINE STARTS WITH THE WORD "MODIFY" ####

#### Set the APP_NAME to your application name such as for tseffmgr username it will be tseff
#### MODIFY APP NAME
#export APP_NAME=ghoshman

###### INITIATE BLOCK. DO NOT CHANGE ANYTHING IN INITIATE BLOCK #########

#. /app/informatica/env/informatica.env
#. $CODE_BASE/$APP_NAME/env/$APP_NAME.env

###### END INITIATE BLOCK ################

#### You can write you shell code below ###
### Usage of Directory Variables defined in the ISS env is a standard. Please refer to document ISS2.0_Directory_Structers 
### on ISS share point under Best Practices

export DAY1=`date +%d_%m_%Y`
export DAY_TOUCH=`date +%Y%m%d`
export DAYTIME='date +%d-%m-%Y-%H:%M:%S'
#export LOADDIR=/home/omtsmgr/FAST/srcFiles/EXECUTIVE_REPORT
export LOADDIR=/dev/shm/EXECUTIVE_REPORT
export ARCHIVEDIR=/dev/shm/EXECUTIVE_REPORT/Archive
#export ARCHIVEDIR=/home/ghoshman/EXECUTIVE_REPORT/Archive
#export TARGETDIR=/home/omtsmgr/FAST/srcFiles/EXECUTIVE_REPORT
export TARGETDIR=/dev/shm/EXECUTIVE_REPORT
#export JARPATH=/home/omtsmgr/FAST/srcFiles/EXECUTIVE_REPORT
export JARPATH=/home/omtsmgr/EXECUTIVE_REPORT
export LOGPATH=/home/omtsmgr/EXECUTIVE_REPORT/LOG

JAVA_HOME=/opt/java6
PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=PATH

export http_proxy=http://proxy.bbn.hp.com:8080/
export https_proxy=$http_proxy
export ftp_proxy=$http_proxy

echo "start file Downloading"

cd $LOADDIR
curl -k https://www.trilead.com/hpeadminsite/TransactionsV2/?key=KL1djaJJTTmFAWVzTn5w -o transactions.xlsx
	
echo "Completed file  Downloading"

cd $JARPATH

echo "start converting to csv file"

java -jar TRILEADXlsxToCsv.jar

echo "completed converting to csv file"

cd $LOADDIR
echo "start Loading data via VSQL"

/opt/Vertica/bin/vsql -E -e -a --echo-all -h mc4t01045.itcs.softwaregrp.net -p 5433 -d air_pro -U srvc_hpsw_pro_all -w Micro17Focus --echo-all</home/omtsmgr/EXECUTIVE_REPORT/VSQL/EXECUTIVE_REPORT.txt>$LOGPATH/EXECUTIVE_REPORT.log

echo "end data Loading in vertica"


mv 'Transactions.csv' $ARCHIVEDIR/'Transactions.csv'

mv 'transactions.xlsx' $ARCHIVEDIR/'transactions.xlsx'

if [ $? -eq 0 ] 
then 
echo -e " `$DAYTIME` This is an auto generated mail. Please do not respond.\n\n This is just to inform you,The TRILEAD data have been refreshed successfully for EXECUTIVE_REPORT in FAST AIR DB" | mailx -s "TRILEAD DATA REFRESHMENT in FAST AIR DB" manas-kumar.ghosh@hpe.com
fi 
exit 0
