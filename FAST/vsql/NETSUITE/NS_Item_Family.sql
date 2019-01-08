/****
****Script Name	  : NS_Item_Family.sql
****Description   : Incremental data load for NS_Item_Family
****/

/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Item_Family";

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
select 'NETSUITE','NS_Item_Family',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Item_Family_Hist SELECT * from "swt_rpt_stg".NS_Item_Family;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select item_family_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Item_Family where item_family_id in (
select item_family_id from swt_rpt_stg.NS_Item_Family group by item_family_id,last_modified_date having count(1)>1)
group by item_family_id);

delete from swt_rpt_stg.NS_Item_Family where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Item_Family.item_family_id=t2.item_family_id and swt_rpt_stg.NS_Item_Family.auto_id<t2. auto_id);

COMMIT;

CREATE LOCAL TEMP TABLE NS_Item_Family_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Item_Family)
SEGMENTED BY HASH(item_family_id,last_modified_date) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.NS_Item_Family;

CREATE LOCAL TEMP TABLE NS_Item_Family_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT item_family_id,last_modified_date FROM swt_rpt_base.NS_Item_Family)
SEGMENTED BY HASH(item_family_id,last_modified_date) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Item_Family_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT item_family_id, max(last_modified_date) as last_modified_date FROM NS_Item_Family_stg_Tmp group by item_family_id)
SEGMENTED BY HASH(item_family_id,last_modified_date) ALL NODES;



/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Item_Family_Hist
(
date_created
,functional_area_id
,is_inactive
,is_multiple_decrement
,item_family_extid
,item_family_id
,item_family_name
,last_modified_date
,lcci_id
,parent_id
,test_date
,test_datetime
,send_to_mit
,LD_DT
,SWT_INS_DT
,d_source
)
select
date_created
,functional_area_id
,is_inactive
,is_multiple_decrement
,item_family_extid
,item_family_id
,item_family_name
,last_modified_date
,lcci_id
,parent_id
,test_date
,test_datetime
,send_to_mit
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Item_Family WHERE item_family_id in
(SELECT STG.item_family_id FROM NS_Item_Family_stg_Tmp_Key STG JOIN NS_Item_Family_base_Tmp
ON STG.item_family_id = NS_Item_Family_base_Tmp.item_family_id AND STG.last_modified_date >= NS_Item_Family_base_Tmp.last_modified_date);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Item_Family_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Item_Family WHERE item_family_id in
(SELECT STG.item_family_id FROM NS_Item_Family_stg_Tmp_Key STG JOIN NS_Item_Family_base_Tmp
ON STG.item_family_id = NS_Item_Family_base_Tmp.item_family_id AND STG.last_modified_date >= NS_Item_Family_base_Tmp.last_modified_date);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Item_Family
(
date_created
,functional_area_id
,is_inactive
,is_multiple_decrement
,item_family_extid
,item_family_id
,item_family_name
,last_modified_date
,lcci_id
,parent_id
,test_date
,test_datetime
,send_to_mit
,SWT_INS_DT
)
SELECT DISTINCT
date_created
,functional_area_id
,is_inactive
,is_multiple_decrement
,item_family_extid
,NS_Item_Family_stg_Tmp.item_family_id
,item_family_name
,NS_Item_Family_stg_Tmp.last_modified_date
,lcci_id
,parent_id
,test_date
,test_datetime
,send_to_mit
,SYSDATE AS SWT_INS_DT
FROM NS_Item_Family_stg_Tmp JOIN NS_Item_Family_stg_Tmp_Key ON NS_Item_Family_stg_Tmp.item_family_id= NS_Item_Family_stg_Tmp_Key.item_family_id AND NS_Item_Family_stg_Tmp.last_modified_date=NS_Item_Family_stg_Tmp_Key.last_modified_date
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Item_Family BASE
WHERE NS_Item_Family_stg_Tmp.item_family_id = BASE.item_family_id);



/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Item_Family' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Item_Family' and  COMPLTN_STAT = 'N');
*/

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
select 'NETSUITE','NS_Item_Family',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Item_Family where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

SELECT DO_TM_TASK('mergeout', 'swt_rpt_base.NS_Item_Family');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.NS_Item_Family_Hist');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Item_Family');


