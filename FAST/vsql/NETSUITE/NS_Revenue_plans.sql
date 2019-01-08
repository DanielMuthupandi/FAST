/******
***** Script Name	  : NS_Revenue_plans.sql
****Description   : Incremental data load for NS_Revenue_plans
****/
/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from swt_rpt_stg.NS_Revenue_plans;

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
select 'NETSUITE','NS_Revenue_plans',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Revenue_plans_Hist SELECT * from "swt_rpt_stg".NS_Revenue_plans;

CREATE LOCAL TEMP TABLE duplicates_Revenue_plans ON COMMIT PRESERVE ROWS AS 
select max(auto_id) as auto_id,plan_id from swt_rpt_stg.NS_Revenue_plans where plan_id in(
select plan_id from swt_rpt_stg.NS_Revenue_plans
group by plan_id,date_last_modified having count(1)>1)
group by plan_id;


delete from swt_rpt_stg.NS_Revenue_plans  where exists(
select 1 from duplicates_Revenue_plans t2 where swt_rpt_stg.NS_Revenue_plans.plan_id=t2.plan_id and swt_rpt_stg.NS_Revenue_plans.auto_id<t2.auto_id);

COMMIT;

CREATE LOCAL TEMP TABLE NS_Revenue_plans_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Revenue_plans)
SEGMENTED BY HASH(plan_id,date_last_modified) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.NS_Revenue_plans;

CREATE LOCAL TEMP TABLE NS_Revenue_plans_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT plan_id,date_last_modified FROM swt_rpt_base.NS_Revenue_plans)
SEGMENTED BY HASH(plan_id,date_last_modified) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Revenue_plans_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT plan_id, max(date_last_modified) as date_last_modified FROM NS_Revenue_plans_stg_Tmp group by plan_id)
SEGMENTED BY HASH(plan_id,date_last_modified) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Revenue_plans_Hist
(
accounting_period_id
,comments
,date_created
,date_last_modified
,end_date
,is_hold_rev_rec
,plan_id
,plan_number
,reforecast_method
,rev_rec_rule_id
,revenue_element_id
,revenue_plan_type
,start_date
,LD_DT
,SWT_INS_DT
,d_source
,SWT_Ins_Date_Backup
)
select
accounting_period_id
,comments
,date_created
,date_last_modified
,end_date
,is_hold_rev_rec
,plan_id
,plan_number
,reforecast_method
,rev_rec_rule_id
,revenue_element_id
,revenue_plan_type
,start_date
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
,SWT_Ins_Date_Backup
FROM "swt_rpt_base".NS_Revenue_plans WHERE plan_id in 
(SELECT STG.plan_id FROM NS_Revenue_plans_stg_Tmp_Key STG JOIN NS_Revenue_plans_base_Tmp
ON STG.plan_id = NS_Revenue_plans_base_Tmp.plan_id AND STG.date_last_modified >= NS_Revenue_plans_base_Tmp.date_last_modified);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Revenue_plans_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Revenue_plans WHERE plan_id in
(SELECT STG.plan_id FROM NS_Revenue_plans_stg_Tmp_Key STG JOIN NS_Revenue_plans_base_Tmp
ON STG.plan_id = NS_Revenue_plans_base_Tmp.plan_id AND STG.date_last_modified >= NS_Revenue_plans_base_Tmp.date_last_modified);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Revenue_plans
(
accounting_period_id
,comments
,date_created
,date_last_modified
,end_date
,is_hold_rev_rec
,plan_id
,plan_number
,reforecast_method
,rev_rec_rule_id
,revenue_element_id
,revenue_plan_type
,start_date
,SWT_INS_DT
,SWT_Ins_Date_Backup
)
SELECT DISTINCT
accounting_period_id
,comments
,date_created
,NS_Revenue_plans_stg_Tmp.date_last_modified
,end_date
,is_hold_rev_rec
,NS_Revenue_plans_stg_Tmp.plan_id
,plan_number
,reforecast_method
,rev_rec_rule_id
,revenue_element_id
,revenue_plan_type
,start_date
,sysdate as SWT_INS_DT
,sysdate as SWT_Ins_Date_Backup
FROM NS_Revenue_plans_stg_Tmp JOIN NS_Revenue_plans_stg_Tmp_Key ON NS_Revenue_plans_stg_Tmp.plan_id= NS_Revenue_plans_stg_Tmp_Key.plan_id AND NS_Revenue_plans_stg_Tmp.date_last_modified=NS_Revenue_plans_stg_Tmp_Key.date_last_modified
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Revenue_plans BASE
WHERE NS_Revenue_plans_stg_Tmp.plan_id = BASE.plan_id);

COMMIT;

/* Inserting new audit entry with stg to base */

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
select 'NETSUITE','NS_Revenue_plans',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Revenue_plans where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

CREATE LOCAL TEMP TABLE Start_Time_Tmp_Id ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from swt_rpt_stg.NS_Revenue_plans_Id;

/* Inserting values into Audit table for ID table */

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
select 'NETSUITE','NS_Revenue_plans_Id',sysdate::date,sysdate,null,(select count from Start_Time_Tmp_Id) ,null,'N';

Commit;
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_Revenue_plans_ID
( plan_id,
SWT_INS_DT
)
SELECT
plan_id,
SYSDATE
FROM swt_rpt_stg.NS_Revenue_plans_ID;


CREATE LOCAL TEMP TABLE NS_Revenue_plans_base_deleted ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_base.NS_Revenue_plans where Is_Deleted <> 'true' and plan_id not in ( select distinct plan_id from swt_rpt_stg.NS_Revenue_plans_Id))
SEGMENTED BY HASH(plan_id) ALL NODES;

DELETE /*+DIRECT*/ FROM swt_rpt_base.NS_Revenue_plans where Is_Deleted <> 'true' and plan_id  in ( select distinct plan_id from NS_Revenue_plans_base_deleted );


INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_Revenue_plans_Deleted_Ids
( plan_id,
SWT_INS_DT,
status
)
SELECT
plan_id,
SYSDATE,
'deleted'
FROM NS_Revenue_plans_base_deleted;


INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_Revenue_plans
(
accounting_period_id,
comments,
date_created,
date_last_modified,
end_date,
is_hold_rev_rec,
plan_id,
plan_number,
reforecast_method,
rev_rec_rule_id,
revenue_element_id,
revenue_plan_type,
start_date,
SWT_INS_DT,
Is_Deleted,
SWT_Ins_Date_Backup
)
SELECT 
accounting_period_id,
comments,
date_created,
date_last_modified,
end_date,
is_hold_rev_rec,
plan_id,
plan_number,
reforecast_method,
rev_rec_rule_id,
revenue_element_id,
revenue_plan_type,
start_date,
sysdate as SWT_INS_DT,
'true'
,SWT_INS_DT
FROM NS_Revenue_plans_base_deleted;


CREATE LOCAL TEMP TABLE NS_Revenue_plans_base_active ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_base.NS_Revenue_plans where Is_Deleted ='true' and plan_id in ( select distinct plan_id from swt_rpt_stg.NS_Revenue_plans_Id))
SEGMENTED BY HASH(plan_id) ALL NODES;

DELETE /*+DIRECT*/ FROM swt_rpt_base.NS_Revenue_plans where Is_Deleted ='true' and plan_id in ( select distinct plan_id from NS_Revenue_plans_base_active);


INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_Revenue_plans_Deleted_Ids
(
plan_id,
SWT_INS_DT,
status)
SELECT 
plan_id,
SYSDATE,
'activated'
FROM NS_Revenue_plans_base_active;


INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_Revenue_plans
(
accounting_period_id,
comments,
date_created,
date_last_modified,
end_date,
is_hold_rev_rec,
plan_id,
plan_number,
reforecast_method,
rev_rec_rule_id,
revenue_element_id,
revenue_plan_type,
start_date,
SWT_INS_DT,
Is_Deleted,
SWT_Ins_Date_Backup
)
SELECT 
accounting_period_id,
comments,
date_created,
date_last_modified,
end_date,
is_hold_rev_rec,
plan_id,
plan_number,
reforecast_method,
rev_rec_rule_id,
revenue_element_id,
revenue_plan_type,
start_date,
sysdate as SWT_INS_DT
,'false'
,SWT_INS_DT
FROM NS_Revenue_plans_base_active;


COMMIT;


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Revenue_plans' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Revenue_plans' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Revenue_plans_Id',sysdate::date,(select st from Start_Time_Tmp_Id),sysdate,(select count from Start_Time_Tmp_Id) ,(select count(*) from swt_rpt_base.NS_Revenue_plans where SWT_INS_DT>=(select max(START_DT_TIME) from swt_rpt_stg.FAST_LD_AUDT where TBL_NM='NS_Revenue_plans_Id') and is_deleted='true'),'Y';

Commit;

SELECT DO_TM_TASK('mergeout', 'swt_rpt_base.NS_Revenue_plans');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.NS_Revenue_plans_Hist');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Revenue_plans');

SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Revenue_plans_deleted_IDS');
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TRUNCATE TABLE swt_rpt_stg.NS_Revenue_plans_Id;
delete /*+DIRECT*/ from "swt_rpt_base"."NS_Revenue_plans_id"  where swt_ins_dt::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;
commit;
--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




