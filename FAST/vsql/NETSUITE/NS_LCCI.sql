/****
****Script Name	  : NS_LCCI.sql
****Description   : Incremental data load for NS_LCCI
****/

/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_LCCI";

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
select 'NETSUITE','NS_LCCI',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_LCCI_Hist SELECT * from "swt_rpt_stg".NS_LCCI;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select lcci_id,max(auto_id) as auto_id from swt_rpt_stg.NS_LCCI where lcci_id in (
select lcci_id from swt_rpt_stg.NS_LCCI group by lcci_id,last_modified_date having count(1)>1)
group by lcci_id);


delete from swt_rpt_stg.NS_LCCI where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_LCCI.lcci_id=t2.lcci_id and swt_rpt_stg.NS_LCCI.auto_id<t2.auto_id);

commit;


CREATE LOCAL TEMP TABLE NS_LCCI_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_LCCI)
SEGMENTED BY HASH(lcci_id,last_modified_date) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.NS_LCCI;

CREATE LOCAL TEMP TABLE NS_LCCI_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT lcci_id,last_modified_date FROM swt_rpt_base.NS_LCCI)
SEGMENTED BY HASH(lcci_id,last_modified_date) ALL NODES;


CREATE LOCAL TEMP TABLE NS_LCCI_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT lcci_id, max(last_modified_date) as last_modified_date FROM NS_LCCI_stg_Tmp group by lcci_id)
SEGMENTED BY HASH(lcci_id,last_modified_date) ALL NODES;



/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_LCCI_Hist
(
date_created
,is_inactive
,last_modified_date
,lcci_extid
,lcci_id
,lcci_name
,parent_id
,LD_DT
,SWT_INS_DT
,d_source
)
select
date_created
,is_inactive
,last_modified_date
,lcci_extid
,lcci_id
,lcci_name
,parent_id
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_LCCI WHERE lcci_id in
(SELECT STG.lcci_id FROM NS_LCCI_stg_Tmp_Key STG JOIN NS_LCCI_base_Tmp
ON STG.lcci_id = NS_LCCI_base_Tmp.lcci_id AND STG.last_modified_date >= NS_LCCI_base_Tmp.last_modified_date);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_LCCI_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_LCCI WHERE lcci_id in
(SELECT STG.lcci_id FROM NS_LCCI_stg_Tmp_Key STG JOIN NS_LCCI_base_Tmp
ON STG.lcci_id = NS_LCCI_base_Tmp.lcci_id AND STG.last_modified_date >= NS_LCCI_base_Tmp.last_modified_date);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_LCCI
(
date_created
,is_inactive
,last_modified_date
,lcci_extid
,lcci_id
,lcci_name
,parent_id
,SWT_INS_DT
)
SELECT DISTINCT 
date_created
,is_inactive
,NS_LCCI_stg_Tmp.last_modified_date
,lcci_extid
,NS_LCCI_stg_Tmp.lcci_id
,lcci_name
,parent_id
,SYSDATE AS SWT_INS_DT
FROM NS_LCCI_stg_Tmp JOIN NS_LCCI_stg_Tmp_Key ON NS_LCCI_stg_Tmp.lcci_id= NS_LCCI_stg_Tmp_Key.lcci_id AND NS_LCCI_stg_Tmp.last_modified_date=NS_LCCI_stg_Tmp_Key.last_modified_date
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_LCCI BASE
WHERE NS_LCCI_stg_Tmp.lcci_id = BASE.lcci_id);



/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_LCCI' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_LCCI' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_LCCI',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_LCCI where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


SELECT PURGE_TABLE('swt_rpt_base.NS_LCCI');
SELECT PURGE_TABLE('swt_rpt_stg.NS_LCCI_Hist');
select ANALYZE_STATISTICS('swt_rpt_base.NS_LCCI');


