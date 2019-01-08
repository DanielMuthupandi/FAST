/****
****Script Name	  : NS_Profit_Center.sql
****Description   : Incremental data load for NS_Profit_Center
****/

/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Profit_Center";

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
select 'NETSUITE','NS_Profit_Center',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Profit_Center_Hist SELECT * from "swt_rpt_stg".NS_Profit_Center;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select profit_center_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Profit_Center where profit_center_id in (
select profit_center_id from swt_rpt_stg.NS_Profit_Center group by profit_center_id,last_modified_date having count(1)>1)
group by profit_center_id);


delete from swt_rpt_stg.NS_Profit_Center where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Profit_Center.profit_center_id=t2.profit_center_id and swt_rpt_stg.NS_Profit_Center.auto_id<t2.auto_id);

commit;


CREATE LOCAL TEMP TABLE NS_Profit_Center_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Profit_Center)
SEGMENTED BY HASH(profit_center_id,last_modified_date) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.NS_Profit_Center;

CREATE LOCAL TEMP TABLE NS_Profit_Center_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT profit_center_id,last_modified_date FROM swt_rpt_base.NS_Profit_Center)
SEGMENTED BY HASH(profit_center_id,last_modified_date) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Profit_Center_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT profit_center_id, max(last_modified_date) as last_modified_date FROM NS_Profit_Center_stg_Tmp group by profit_center_id)
SEGMENTED BY HASH(profit_center_id,last_modified_date) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Profit_Center_Hist
(
date_created
,description
,hierarchy_description
,is_inactive
,last_modified_date
,parent_id
,pc_hierarchy_level_id
,profit_center_extid
,profit_center_id
,profit_center_name
,LD_DT
,SWT_INS_DT
,d_source
)
select
date_created
,description
,hierarchy_description
,is_inactive
,last_modified_date
,parent_id
,pc_hierarchy_level_id
,profit_center_extid
,profit_center_id
,profit_center_name
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Profit_Center WHERE profit_center_id in
(SELECT STG.profit_center_id FROM NS_Profit_Center_stg_Tmp_Key STG JOIN NS_Profit_Center_base_Tmp
ON STG.profit_center_id = NS_Profit_Center_base_Tmp.profit_center_id AND STG.last_modified_date >= NS_Profit_Center_base_Tmp.last_modified_date);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Profit_Center_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Profit_Center WHERE profit_center_id in
(SELECT STG.profit_center_id FROM NS_Profit_Center_stg_Tmp_Key STG JOIN NS_Profit_Center_base_Tmp
ON STG.profit_center_id = NS_Profit_Center_base_Tmp.profit_center_id AND STG.last_modified_date >= NS_Profit_Center_base_Tmp.last_modified_date);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Profit_Center
(
date_created
,description
,hierarchy_description
,is_inactive
,last_modified_date
,parent_id
,pc_hierarchy_level_id
,profit_center_extid
,profit_center_id
,profit_center_name
,SWT_INS_DT
)
SELECT DISTINCT 
date_created
,description
,hierarchy_description
,is_inactive
,NS_Profit_Center_stg_Tmp.last_modified_date
,parent_id
,pc_hierarchy_level_id
,profit_center_extid
,NS_Profit_Center_stg_Tmp.profit_center_id
,profit_center_name
,SYSDATE AS SWT_INS_DT
FROM NS_Profit_Center_stg_Tmp JOIN NS_Profit_Center_stg_Tmp_Key ON NS_Profit_Center_stg_Tmp.profit_center_id= NS_Profit_Center_stg_Tmp_Key.profit_center_id AND NS_Profit_Center_stg_Tmp.last_modified_date=NS_Profit_Center_stg_Tmp_Key.last_modified_date
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Profit_Center BASE
WHERE NS_Profit_Center_stg_Tmp.profit_center_id = BASE.profit_center_id);



/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Profit_Center' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Profit_Center' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Profit_Center',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Profit_Center where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

SELECT PURGE_TABLE('swt_rpt_base.NS_Profit_Center');
SELECT PURGE_TABLE('swt_rpt_stg.NS_Profit_Center_Hist');
select ANALYZE_STATISTICS('swt_rpt_base.NS_Profit_Center');


