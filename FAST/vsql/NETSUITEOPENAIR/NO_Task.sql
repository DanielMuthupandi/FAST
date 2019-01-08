/****
****Script Name   : NO_Task.sql
****Description   : Incremental data load for NO_Task
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
select 'NETSUITEOPENAIR','NO_Task',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_Task") ,null,'N';

Commit;

CREATE LOCAL TEMP TABLE NO_Task_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_Task)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Task_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,Updated FROM swt_rpt_base.NO_Task)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Task_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(Updated) as Updated FROM NO_Task_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_Task_Hist
(
id
,created
,updated
,projecttask_typeid
,userid
,date
,decimal_hours
,cost_centerid
,slipid
,hours
,timetypeid
,minutes
,projectid
,description
,categoryid
,projecttaskid
,timesheetid
,customerid
,payroll_typeid
,job_codeid
,loaded_cost
,loaded_cost_2
,loaded_cost_3
,project_loaded_cost
,project_loaded_cost_2
,project_loaded_cost_3
,acct_date
,category_1id
,category_2id
,category_3id
,category_4id
,category_5id
,thin_client_id
,task_training_units
,task_training_units_status
,task_training_attendees
,Priority
,po_number__c
,task_legacy_id__c
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,created
,updated
,projecttask_typeid
,userid
,date
,decimal_hours
,cost_centerid
,slipid
,hours
,timetypeid
,minutes
,projectid
,description
,categoryid
,projecttaskid
,timesheetid
,customerid
,payroll_typeid
,job_codeid
,loaded_cost
,loaded_cost_2
,loaded_cost_3
,project_loaded_cost
,project_loaded_cost_2
,project_loaded_cost_3
,acct_date
,category_1id
,category_2id
,category_3id
,category_4id
,category_5id
,thin_client_id
,task_training_units
,task_training_units_status
,task_training_attendees
,Priority
,po_number__c
,task_legacy_id__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_Task WHERE id in
(SELECT STG.id FROM NO_Task_stg_Tmp_Key STG JOIN NO_Task_base_Tmp
ON STG.id = NO_Task_base_Tmp.id AND STG.updated >= NO_Task_base_Tmp.updated);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_Task_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_Task WHERE id in
(SELECT STG.id FROM NO_Task_stg_Tmp_Key STG JOIN NO_Task_base_Tmp
ON STG.id = NO_Task_base_Tmp.id AND STG.updated >= NO_Task_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_Task
(
id
,created
,updated
,projecttask_typeid
,userid
,date
,decimal_hours
,cost_centerid
,slipid
,hours
,timetypeid
,minutes
,projectid
,description
,categoryid
,projecttaskid
,timesheetid
,customerid
,payroll_typeid
,job_codeid
,loaded_cost
,loaded_cost_2
,loaded_cost_3
,project_loaded_cost
,project_loaded_cost_2
,project_loaded_cost_3
,acct_date
,category_1id
,category_2id
,category_3id
,category_4id
,category_5id
,thin_client_id
,task_training_units
,task_training_units_status
,task_training_attendees
,Priority
,po_number__c
,task_legacy_id__c
,SWT_INS_DT
)
SELECT DISTINCT
NO_Task_stg_Tmp.id
,created
,NO_Task_stg_Tmp.updated
,projecttask_typeid
,userid
,date
,decimal_hours
,cost_centerid
,slipid
,hours
,timetypeid
,minutes
,projectid
,description
,categoryid
,projecttaskid
,timesheetid
,customerid
,payroll_typeid
,job_codeid
,loaded_cost
,loaded_cost_2
,loaded_cost_3
,project_loaded_cost
,project_loaded_cost_2
,project_loaded_cost_3
,acct_date
,category_1id
,category_2id
,category_3id
,category_4id
,category_5id
,thin_client_id
,task_training_units
,task_training_units_status
,task_training_attendees
,Priority
,po_number__c
,task_legacy_id__c
,SYSDATE AS SWT_INS_DT
FROM NO_Task_stg_Tmp JOIN NO_Task_stg_Tmp_Key ON NO_Task_stg_Tmp.Id= NO_Task_stg_Tmp_Key.Id AND NO_Task_stg_Tmp.Updated=NO_Task_stg_Tmp_Key.Updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_Task BASE
WHERE NO_Task_stg_Tmp.Id = BASE.Id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_Task' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_Task' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_Task',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_Task") ,(select count(*) from swt_rpt_base.NO_Task where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

select do_tm_task('mergeout','swt_rpt_stg.NO_Task_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_Task');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_Task');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_Task_Hist SELECT * from swt_rpt_stg.NO_Task;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_Task;
