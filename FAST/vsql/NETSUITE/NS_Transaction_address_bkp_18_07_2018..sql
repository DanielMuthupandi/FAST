/****
****Script Name   : NS_Transaction_address.sql
****Description   : Incremental data load for NS_Transaction_address
****/


/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Transaction_address";

/* Inserting values into Audit table  */

INSERT INTO swt_rpt_stg.FAST_LD_AUDT
 (
       SUBJECT_AREA
      ,TBL_NM
      ,LD_DT
      ,START_DT_TIME
      ,END_DT_TIME
      ,SRC_REC_CNT
      ,TGT_REC_CNT
      ,COMPLTN_STAT
      )
  select 'NETSUITE','NS_Transaction_address',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

  Commit;  

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Transaction_address_Hist SELECT * from "swt_rpt_stg".NS_Transaction_address;
COMMIT;


CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select transaction_address_id,transaction_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Transaction_address where (transaction_address_id,transaction_id) in (
select transaction_address_id,transaction_id from swt_rpt_stg.NS_Transaction_address group by transaction_address_id,transaction_id,date_last_modified having count(1)>1)
group by transaction_address_id,transaction_id);


delete from swt_rpt_stg.NS_Transaction_address where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Transaction_address.transaction_address_id=t2.transaction_address_id and swt_rpt_stg.NS_Transaction_address.transaction_id=t2.transaction_id and swt_rpt_stg.NS_Transaction_address.auto_id<t2.auto_id);

commit;


CREATE LOCAL TEMP TABLE NS_Transaction_address_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Transaction_address)
SEGMENTED BY HASH(transaction_address_id,transaction_id,date_last_modified) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.NS_Transaction_address;

CREATE LOCAL TEMP TABLE NS_Transaction_address_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT transaction_address_id,transaction_id,date_last_modified FROM swt_rpt_base.NS_Transaction_address)
SEGMENTED BY HASH(transaction_address_id,transaction_id,date_last_modified) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Transaction_address_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT transaction_address_id,transaction_id, max(date_last_modified) as date_last_modified FROM NS_Transaction_address_stg_Tmp group by transaction_address_id,transaction_id)
SEGMENTED BY HASH(transaction_address_id,transaction_id,date_last_modified) ALL NODES; 

insert /*+DIRECT*/ into swt_rpt_stg.NS_Transaction_address_Hist
(
bill_address_line_1
,bill_address_line_2
,bill_address_line_3
,bill_city
,bill_company
,bill_country
,bill_name
,bill_phone_number
,bill_state
,bill_zip
,return_address_line_1
,return_address_line_2
,return_city
,return_country
,return_state
,return_zipcode
,ship_address_line_1
,ship_address_line_2
,ship_address_line_3
,ship_attention
,ship_city
,ship_company
,ship_country
,ship_name
,ship_phone_number
,ship_state
,ship_zip
,transaction_address_id
,created_by_id
,date_created
,date_last_modified
,last_modified_by_id
,transaction_id
,LD_DT
,SWT_INS_DT
,d_source
,SWT_Ins_Date_Backup
)
select
bill_address_line_1
,bill_address_line_2
,bill_address_line_3
,bill_city
,bill_company
,bill_country
,bill_name
,bill_phone_number
,bill_state
,bill_zip
,return_address_line_1
,return_address_line_2
,return_city
,return_country
,return_state
,return_zipcode
,ship_address_line_1
,ship_address_line_2
,ship_address_line_3
,ship_attention
,ship_city
,ship_company
,ship_country
,ship_name
,ship_phone_number
,ship_state
,ship_zip
,transaction_address_id
,created_by_id
,date_created
,date_last_modified
,last_modified_by_id
,transaction_id
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
,SWT_Ins_Date_Backup
FROM "swt_rpt_base".NS_Transaction_address WHERE EXISTS
(SELECT 1 FROM NS_Transaction_address_stg_Tmp_Key STG
WHERE STG.transaction_address_id = NS_Transaction_address.transaction_address_id AND STG.transaction_id = NS_Transaction_address.transaction_id AND STG.date_last_modified >= NS_Transaction_address.date_last_modified);


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Transaction_address_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

/* Incremental VSQL script for loading data from Stage to Base */


DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Transaction_address WHERE EXISTS
(SELECT 1 FROM NS_Transaction_address_stg_Tmp_Key STG
WHERE STG.transaction_address_id = "swt_rpt_base".NS_Transaction_address.transaction_address_id  AND STG.transaction_id = "swt_rpt_base".NS_Transaction_address.transaction_id  AND STG.date_last_modified >= "swt_rpt_base".NS_Transaction_address.date_last_modified);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Transaction_address
(
bill_address_line_1
,bill_address_line_2
,bill_address_line_3
,bill_city
,bill_company
,bill_country
,bill_name
,bill_phone_number
,bill_state
,bill_zip
,return_address_line_1
,return_address_line_2
,return_city
,return_country
,return_state
,return_zipcode
,ship_address_line_1
,ship_address_line_2
,ship_address_line_3
,ship_attention
,ship_city
,ship_company
,ship_country
,ship_name
,ship_phone_number
,ship_state
,ship_zip
,transaction_address_id
,created_by_id
,date_created
,date_last_modified
,last_modified_by_id
,transaction_id
,SWT_INS_DT
,SWT_Ins_Date_Backup
)
SELECT DISTINCT 
bill_address_line_1
,bill_address_line_2
,bill_address_line_3
,bill_city
,bill_company
,bill_country
,bill_name
,bill_phone_number
,bill_state
,bill_zip
,return_address_line_1
,return_address_line_2
,return_city
,return_country
,return_state
,return_zipcode
,ship_address_line_1
,ship_address_line_2
,ship_address_line_3
,ship_attention
,ship_city
,ship_company
,ship_country
,ship_name
,ship_phone_number
,ship_state
,ship_zip
,NS_Transaction_address_stg_Tmp.transaction_address_id
,created_by_id
,date_created
,NS_Transaction_address_stg_Tmp.date_last_modified
,last_modified_by_id
,NS_Transaction_address_stg_Tmp.transaction_id
,SYSDATE AS SWT_INS_DT
,sysdate as SWT_Ins_Date_Backup
FROM NS_Transaction_address_stg_Tmp JOIN NS_Transaction_address_stg_Tmp_Key ON NS_Transaction_address_stg_Tmp.transaction_address_id= NS_Transaction_address_stg_Tmp_Key.transaction_address_id 
AND NS_Transaction_address_stg_Tmp.transaction_id= NS_Transaction_address_stg_Tmp_Key.transaction_id 
AND NS_Transaction_address_stg_Tmp.date_last_modified=NS_Transaction_address_stg_Tmp_Key.date_last_modified
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Transaction_address BASE
WHERE NS_Transaction_address_stg_Tmp.transaction_address_id= BASE.transaction_address_id and NS_Transaction_address_stg_Tmp.transaction_id= BASE.transaction_id);


COMMIT;

INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_Transaction_address_ID
( 
transaction_address_id,
transaction_id,
SWT_INS_DT
)
SELECT
transaction_address_id,
transaction_id,
SYSDATE
FROM swt_rpt_stg.NS_Transaction_address_ID;

CREATE LOCAL TEMP TABLE NS_Transaction_address_base_deleted ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_base.NS_Transaction_address where Is_Deleted <> 'true' and not exists ( select 1 from swt_rpt_stg.NS_Transaction_address_ID
where swt_rpt_base.NS_Transaction_address.transaction_address_id = swt_rpt_stg.NS_Transaction_address_ID.transaction_address_id
and swt_rpt_base.NS_Transaction_address.transaction_id = swt_rpt_stg.NS_Transaction_address_ID.transaction_id))
SEGMENTED BY HASH(transaction_address_id,transaction_id) ALL NODES;


DELETE /*+DIRECT*/ FROM swt_rpt_base.NS_Transaction_address where Is_Deleted <> 'true' and not exists ( select 1 from swt_rpt_stg.NS_Transaction_address_ID
where swt_rpt_base.NS_Transaction_address.transaction_address_id = swt_rpt_stg.NS_Transaction_address_ID.transaction_address_id
and swt_rpt_base.NS_Transaction_address.transaction_id = swt_rpt_stg.NS_Transaction_address_ID.transaction_id);

INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_Transaction_address_Deleted_Ids
( 
transaction_address_id,
transaction_id,
SWT_INS_DT,
status
)
SELECT
transaction_address_id,
transaction_id,
SYSDATE,
'deleted'
FROM NS_Transaction_address_base_deleted;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Transaction_address
(
bill_address_line_1
,bill_address_line_2
,bill_address_line_3
,bill_city
,bill_company
,bill_country
,bill_name
,bill_phone_number
,bill_state
,bill_zip
,return_address_line_1
,return_address_line_2
,return_city
,return_country
,return_state
,return_zipcode
,ship_address_line_1
,ship_address_line_2
,ship_address_line_3
,ship_attention
,ship_city
,ship_company
,ship_country
,ship_name
,ship_phone_number
,ship_state
,ship_zip
,transaction_address_id
,created_by_id
,date_created
,date_last_modified
,last_modified_by_id
,transaction_id
,SWT_INS_DT
,Is_Deleted
,SWT_Ins_Date_Backup
)
select
bill_address_line_1
,bill_address_line_2
,bill_address_line_3
,bill_city
,bill_company
,bill_country
,bill_name
,bill_phone_number
,bill_state
,bill_zip
,return_address_line_1
,return_address_line_2
,return_city
,return_country
,return_state
,return_zipcode
,ship_address_line_1
,ship_address_line_2
,ship_address_line_3
,ship_attention
,ship_city
,ship_company
,ship_country
,ship_name
,ship_phone_number
,ship_state
,ship_zip
,transaction_address_id
,created_by_id
,date_created
,date_last_modified
,last_modified_by_id
,transaction_id
,sysdate as SWT_INS_DT
,'true'
,SWT_INS_DT
FROM NS_Transaction_address_base_deleted;

CREATE LOCAL TEMP TABLE NS_Transaction_address_base_active ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_base.NS_Transaction_address where Is_Deleted = 'true' and exists ( select 1 from swt_rpt_stg.NS_Transaction_address_ID
where swt_rpt_base.NS_Transaction_address.transaction_address_id = swt_rpt_stg.NS_Transaction_address_ID.transaction_address_id
and swt_rpt_base.NS_Transaction_address.transaction_id = swt_rpt_stg.NS_Transaction_address_ID.transaction_id))
SEGMENTED BY HASH(transaction_address_id,transaction_id) ALL NODES;


DELETE /*+DIRECT*/ FROM swt_rpt_base.NS_Transaction_address where Is_Deleted = 'true' and exists ( select 1 from swt_rpt_stg.NS_Transaction_address_ID
where swt_rpt_base.NS_Transaction_address.transaction_address_id = swt_rpt_stg.NS_Transaction_address_ID.transaction_address_id
and swt_rpt_base.NS_Transaction_address.transaction_id = swt_rpt_stg.NS_Transaction_address_ID.transaction_id);

INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_Transaction_address_Deleted_Ids
( 
transaction_address_id,
transaction_id,
SWT_INS_DT,
status
)
SELECT
transaction_address_id,
transaction_id,
SYSDATE,
'activated'
FROM NS_Transaction_address_base_active;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Transaction_address
(
bill_address_line_1
,bill_address_line_2
,bill_address_line_3
,bill_city
,bill_company
,bill_country
,bill_name
,bill_phone_number
,bill_state
,bill_zip
,return_address_line_1
,return_address_line_2
,return_city
,return_country
,return_state
,return_zipcode
,ship_address_line_1
,ship_address_line_2
,ship_address_line_3
,ship_attention
,ship_city
,ship_company
,ship_country
,ship_name
,ship_phone_number
,ship_state
,ship_zip
,transaction_address_id
,created_by_id
,date_created
,date_last_modified
,last_modified_by_id
,transaction_id
,SWT_INS_DT
,Is_Deleted
,SWT_Ins_Date_Backup
)
select
bill_address_line_1
,bill_address_line_2
,bill_address_line_3
,bill_city
,bill_company
,bill_country
,bill_name
,bill_phone_number
,bill_state
,bill_zip
,return_address_line_1
,return_address_line_2
,return_city
,return_country
,return_state
,return_zipcode
,ship_address_line_1
,ship_address_line_2
,ship_address_line_3
,ship_attention
,ship_city
,ship_company
,ship_country
,ship_name
,ship_phone_number
,ship_state
,ship_zip
,transaction_address_id
,created_by_id
,date_created
,date_last_modified
,last_modified_by_id
,transaction_id
,sysdate as SWT_INS_DT
,'false'
,SWT_INS_DT
FROM NS_Transaction_address_base_active;


COMMIT;

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Transaction_address' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Transaction_address' and  COMPLTN_STAT = 'N');


/* Inserting new audit entry with all stats */

INSERT INTO swt_rpt_stg.FAST_LD_AUDT
(
SUBJECT_AREA
,TBL_NM
,LD_DT
,START_DT_TIME
,END_DT_TIME
,SRC_REC_CNT
,TGT_REC_CNT
,COMPLTN_STAT
)
select 'NETSUITE','NS_Transaction_address',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Transaction_address where SWT_INS_DT::date = sysdate::date),'Y';

   Commit;

SELECT DO_TM_TASK('mergeout', 'swt_rpt_base.NS_Transaction_address');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.NS_Transaction_address_Hist');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');   
select ANALYZE_STATISTICS('swt_rpt_base.NS_Transaction_address');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Transaction_address_deleted_IDS');
truncate table swt_rpt_stg.NS_Transaction_address_ID;



