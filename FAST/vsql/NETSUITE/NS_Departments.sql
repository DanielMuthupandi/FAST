/****
****Script Name	  : NS_Departments.sql
****Description   : Incremental data load for NS_Departments
****/

/* Setting timing on**/
\timing
/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Departments";

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
select 'NETSUITE','NS_Departments',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Departments_Hist SELECT * from "swt_rpt_stg".NS_Departments;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select department_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Departments where department_id in (
select department_id from swt_rpt_stg.NS_Departments group by department_id,date_last_modified having count(1)>1)
group by department_id);


delete from swt_rpt_stg.NS_Departments where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Departments.department_id=t2.department_id and swt_rpt_stg.NS_Departments.auto_id<t2.auto_id);

commit;


CREATE LOCAL TEMP TABLE NS_Departments_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Departments)
SEGMENTED BY HASH(department_id,date_last_modified) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.NS_Departments;

CREATE LOCAL TEMP TABLE NS_Departments_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT department_id,date_last_modified FROM swt_rpt_base.NS_Departments)
SEGMENTED BY HASH(department_id,date_last_modified) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Departments_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT department_id, max(date_last_modified) as date_last_modified FROM NS_Departments_stg_Tmp group by department_id)
SEGMENTED BY HASH(department_id,date_last_modified) ALL NODES;

/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Departments_Hist
(
date_last_modified
,department_extid
,department_id
,full_name
,isinactive
,name
,parent_id
,cost_pool_id
,cost_pool_description
,finance_owner
,finance_owner_id
,mru_description
,mru_manager_name_id
,mru_member_class
,mru_region
,mru_hierarchy_level_descripti
,mru_hierarchy_level_id
,LD_DT
,SWT_INS_DT
,d_source
)
select
date_last_modified
,department_extid
,department_id
,full_name
,isinactive
,name
,parent_id
,cost_pool_id
,cost_pool_description
,finance_owner
,finance_owner_id
,mru_description
,mru_manager_name_id
,mru_member_class
,mru_region
,mru_hierarchy_level_descripti
,mru_hierarchy_level_id
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Departments WHERE department_id in
(SELECT STG.department_id FROM NS_Departments_stg_Tmp_Key STG JOIN NS_Departments_base_Tmp
ON STG.department_id = NS_Departments_base_Tmp.department_id AND STG.date_last_modified >= NS_Departments_base_Tmp.date_last_modified);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Departments_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */


DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Departments WHERE department_id in
(SELECT STG.department_id FROM NS_Departments_stg_Tmp_Key STG JOIN NS_Departments_base_Tmp
ON STG.department_id = NS_Departments_base_Tmp.department_id AND STG.date_last_modified >= NS_Departments_base_Tmp.date_last_modified);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Departments
(
date_last_modified
,department_extid
,department_id
,full_name
,isinactive
,name
,parent_id
,cost_pool_id
,cost_pool_description
,finance_owner
,finance_owner_id
,mru_description
,mru_manager_name_id
,mru_member_class
,mru_region
,mru_hierarchy_level_descripti
,mru_hierarchy_level_id
,SWT_INS_DT
)
SELECT DISTINCT 
NS_Departments_stg_Tmp.date_last_modified
,department_extid
,NS_Departments_stg_Tmp.department_id
,full_name
,isinactive
,name
,parent_id
,cost_pool_id
,cost_pool_description
,finance_owner
,finance_owner_id
,mru_description
,mru_manager_name_id
,mru_member_class
,mru_region
,mru_hierarchy_level_descripti
,mru_hierarchy_level_id
,sysdate
FROM NS_Departments_stg_Tmp JOIN NS_Departments_stg_Tmp_Key ON NS_Departments_stg_Tmp.department_id= NS_Departments_stg_Tmp_Key.department_id AND NS_Departments_stg_Tmp.date_last_modified=NS_Departments_stg_Tmp_Key.date_last_modified
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Departments BASE
WHERE NS_Departments_stg_Tmp.department_id = BASE.department_id);


/* Deleting partial audit entry */

/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Departments' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Departments' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Departments',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Departments where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

SELECT DO_TM_TASK('mergeout', 'swt_rpt_base.NS_Departments');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.NS_Departments_Hist');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.NS_Departments');


