/****
****Script Name   : NO_Projecttask.sql
****Description   : Incremental data load for NO_Projecttask
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
select 'NETSUITEOPENAIR','NO_Projecttask',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_Projecttask") ,null,'N';

Commit;


CREATE LOCAL TEMP TABLE NO_Projecttask_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_Projecttask)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Projecttask_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,Updated FROM swt_rpt_base.NO_Projecttask)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Projecttask_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(Updated) as Updated FROM NO_Projecttask_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,Updated) ALL NODES;

/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_Projecttask_Hist
(
id
,created
,updated
,name
,priority
,percent_complete
,task_budget_cost
,is_a_phase
,seq
,non_billable
,externalid
,default_category
,all_can_assign
,predecessors
,customer_name
,parentid
,projecttask_typeid
,calculated_finishes
,predecessors_lag
,currency
,cost_centerid
,calculated_starts
,estimated_hours
,project_name
,id_number
,closed
,task_budget_revenue
,planned_hours
,use_project_assignment
,projectid
,assign_user_names
,starts
,fnlt_date
,customerid
,predecessors_type
,default_category_1
,default_category_2
,default_category_3
,default_category_4
,default_category_5
,manual_task_budget
,timetype_filter
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,created
,updated
,name
,priority
,percent_complete
,task_budget_cost
,is_a_phase
,seq
,non_billable
,externalid
,default_category
,all_can_assign
,predecessors
,customer_name
,parentid
,projecttask_typeid
,calculated_finishes
,predecessors_lag
,currency
,cost_centerid
,calculated_starts
,estimated_hours
,project_name
,id_number
,closed
,task_budget_revenue
,planned_hours
,use_project_assignment
,projectid
,assign_user_names
,starts
,fnlt_date
,customerid
,predecessors_type
,default_category_1
,default_category_2
,default_category_3
,default_category_4
,default_category_5
,manual_task_budget
,timetype_filter
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_Projecttask WHERE id in
(SELECT STG.id FROM NO_Projecttask_stg_Tmp_Key STG JOIN NO_Projecttask_base_Tmp
ON STG.id = NO_Projecttask_base_Tmp.id AND STG.updated >= NO_Projecttask_base_Tmp.updated);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_Projecttask_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_Projecttask WHERE id in
(SELECT STG.id FROM NO_Projecttask_stg_Tmp_Key STG JOIN NO_Projecttask_base_Tmp
ON STG.id = NO_Projecttask_base_Tmp.id AND STG.updated >= NO_Projecttask_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_Projecttask
(
id
,created
,updated
,name
,priority
,percent_complete
,task_budget_cost
,is_a_phase
,seq
,non_billable
,externalid
,default_category
,all_can_assign
,predecessors
,customer_name
,parentid
,projecttask_typeid
,calculated_finishes
,predecessors_lag
,currency
,cost_centerid
,calculated_starts
,estimated_hours
,project_name
,id_number
,closed
,task_budget_revenue
,planned_hours
,use_project_assignment
,projectid
,assign_user_names
,starts
,fnlt_date
,customerid
,predecessors_type
,default_category_1
,default_category_2
,default_category_3
,default_category_4
,default_category_5
,manual_task_budget
,timetype_filter
,SWT_INS_DT
)
SELECT DISTINCT
NO_Projecttask_stg_Tmp.id
,created
,NO_Projecttask_stg_Tmp.updated
,name
,priority
,percent_complete
,task_budget_cost
,is_a_phase
,seq
,non_billable
,externalid
,default_category
,all_can_assign
,predecessors
,customer_name
,parentid
,projecttask_typeid
,calculated_finishes
,predecessors_lag
,currency
,cost_centerid
,calculated_starts
,estimated_hours
,project_name
,id_number
,closed
,task_budget_revenue
,planned_hours
,use_project_assignment
,projectid
,assign_user_names
,starts
,fnlt_date
,customerid
,predecessors_type
,default_category_1
,default_category_2
,default_category_3
,default_category_4
,default_category_5
,manual_task_budget
,timetype_filter
,SYSDATE AS SWT_INS_DT
FROM NO_Projecttask_stg_Tmp JOIN NO_Projecttask_stg_Tmp_Key ON NO_Projecttask_stg_Tmp.Id= NO_Projecttask_stg_Tmp_Key.Id AND NO_Projecttask_stg_Tmp.Updated=NO_Projecttask_stg_Tmp_Key.Updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_Projecttask BASE
WHERE NO_Projecttask_stg_Tmp.Id = BASE.Id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_Projecttask' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_Projecttask' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_Projecttask',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_Projecttask") ,(select count(*) from swt_rpt_base.NO_Projecttask where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

select do_tm_task('mergeout','swt_rpt_stg.NO_Projecttask_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_Projecttask');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_Projecttask');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_Projecttask_Hist SELECT * from swt_rpt_stg.NO_Projecttask;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_Projecttask;
