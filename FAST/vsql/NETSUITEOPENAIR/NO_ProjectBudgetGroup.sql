/****
****Script Name   : NO_ProjectBudgetGroup.sql
****Description   : Incremental data load for NO_ProjectBudgetGroup
****/
/* Setting timing on**/
\timing
/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select sysdate st from dual;

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
select 'NETSUITEOPENAIR','NO_ProjectBudgetGroup',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_ProjectBudgetGroup") ,null,'N';

Commit;

CREATE LOCAL TEMP TABLE NO_ProjectBudgetGroup_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_ProjectBudgetGroup)
SEGMENTED BY HASH(id,updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_ProjectBudgetGroup_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT id,updated FROM swt_rpt_base.NO_ProjectBudgetGroup)
SEGMENTED BY HASH(id,updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_ProjectBudgetGroup_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(updated) as updated FROM NO_ProjectBudgetGroup_stg_Tmp group by id)
SEGMENTED BY HASH(id,updated) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_ProjectBudgetGroup_Hist
(
id
,name
,customerid
,projectid
,date
,currency
,total
,created
,updated
,total_expected_cost
,total_expected_billing
,total_calculated_cost
,total_calculated_billing
,total_from_funding
,profitability
,funding_total
,internal_total
,calculated_total
,budget_by
,unassigned_task
,userid
,approval_status
,date_submitted
,date_approved
,date_archived
,version
,parentid
,setting
,cf_pes
,cf_opt
,labor_subcategory
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,name
,customerid
,projectid
,date
,currency
,total
,created
,updated
,total_expected_cost
,total_expected_billing
,total_calculated_cost
,total_calculated_billing
,total_from_funding
,profitability
,funding_total
,internal_total
,calculated_total
,budget_by
,unassigned_task
,userid
,approval_status
,date_submitted
,date_approved
,date_archived
,version
,parentid
,setting
,cf_pes
,cf_opt
,labor_subcategory
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_ProjectBudgetGroup WHERE id in
(SELECT STG.id FROM NO_ProjectBudgetGroup_stg_Tmp_Key STG JOIN NO_ProjectBudgetGroup_base_Tmp
ON STG.id = NO_ProjectBudgetGroup_base_Tmp.id AND STG.updated >= NO_ProjectBudgetGroup_base_Tmp.updated);

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_ProjectBudgetGroup_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_ProjectBudgetGroup WHERE id in
(SELECT STG.id FROM NO_ProjectBudgetGroup_stg_Tmp_Key STG JOIN NO_ProjectBudgetGroup_base_Tmp
ON STG.id = NO_ProjectBudgetGroup_base_Tmp.id AND STG.updated >= NO_ProjectBudgetGroup_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_ProjectBudgetGroup
(
id
,name
,customerid
,projectid
,date
,currency
,total
,created
,updated
,total_expected_cost
,total_expected_billing
,total_calculated_cost
,total_calculated_billing
,total_from_funding
,profitability
,funding_total
,internal_total
,calculated_total
,budget_by
,unassigned_task
,userid
,approval_status
,date_submitted
,date_approved
,date_archived
,version
,parentid
,setting
,cf_pes
,cf_opt
,labor_subcategory
,SWT_INS_DT
)
SELECT DISTINCT
NO_ProjectBudgetGroup_stg_Tmp.id
,name
,customerid
,projectid
,date
,currency
,total
,created
,NO_ProjectBudgetGroup_stg_Tmp.updated
,total_expected_cost
,total_expected_billing
,total_calculated_cost
,total_calculated_billing
,total_from_funding
,profitability
,funding_total
,internal_total
,calculated_total
,budget_by
,unassigned_task
,userid
,approval_status
,date_submitted
,date_approved
,date_archived
,version
,parentid
,setting
,cf_pes
,cf_opt
,labor_subcategory
,SYSDATE AS SWT_INS_DT
FROM NO_ProjectBudgetGroup_stg_Tmp JOIN NO_ProjectBudgetGroup_stg_Tmp_Key ON NO_ProjectBudgetGroup_stg_Tmp.id= NO_ProjectBudgetGroup_stg_Tmp_Key.id AND NO_ProjectBudgetGroup_stg_Tmp.updated=NO_ProjectBudgetGroup_stg_Tmp_Key.updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_ProjectBudgetGroup BASE
WHERE NO_ProjectBudgetGroup_stg_Tmp.id = BASE.id);

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_ProjectBudgetGroup' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_ProjectBudgetGroup' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_ProjectBudgetGroup',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_ProjectBudgetGroup") ,(select count(*) from swt_rpt_base.NO_ProjectBudgetGroup where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

select do_tm_task('mergeout','swt_rpt_stg.NO_ProjectBudgetGroup_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_ProjectBudgetGroup');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_ProjectBudgetGroup');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_ProjectBudgetGroup_Hist SELECT * from swt_rpt_stg.NO_ProjectBudgetGroup;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_ProjectBudgetGroup;
