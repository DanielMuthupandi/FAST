/****
****Script Name   : NO_Projectstage.sql
****Description   : Incremental data load for NO_Projectstage
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
select 'NETSUITEOPENAIR','NO_Projectstage',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_Projectstage") ,null,'N';

Commit;


CREATE LOCAL TEMP TABLE NO_Projectstage_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_Projectstage)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Projectstage_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,Updated FROM swt_rpt_base.NO_Projectstage)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Projectstage_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(Updated) as Updated FROM NO_Projectstage_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,Updated) ALL NODES;

/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_Projectstage_Hist
(
id
,created
,updated
,name
,position
,enable_team
,enable_utilization
,enable_project_assignments
,enable_phase_and_task
,enable_analysis
,enable_billing
,enable_recognition
,enable_pricing
,picklist_label
,netsuite_project_stage_id
,netsuite_push_project_stage_filter
,ns_projStageID
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,created
,updated
,name
,position
,enable_team
,enable_utilization
,enable_project_assignments
,enable_phase_and_task
,enable_analysis
,enable_billing
,enable_recognition
,enable_pricing
,picklist_label
,netsuite_project_stage_id
,netsuite_push_project_stage_filter
,ns_projStageID
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_Projectstage WHERE id in
(SELECT STG.id FROM NO_Projectstage_stg_Tmp_Key STG JOIN NO_Projectstage_base_Tmp
ON STG.id = NO_Projectstage_base_Tmp.id AND STG.updated >= NO_Projectstage_base_Tmp.updated);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_Projectstage_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_Projectstage WHERE id in
(SELECT STG.id FROM NO_Projectstage_stg_Tmp_Key STG JOIN NO_Projectstage_base_Tmp
ON STG.id = NO_Projectstage_base_Tmp.id AND STG.updated >= NO_Projectstage_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_Projectstage
(
id
,created
,updated
,name
,position
,enable_team
,enable_utilization
,enable_project_assignments
,enable_phase_and_task
,enable_analysis
,enable_billing
,enable_recognition
,enable_pricing
,picklist_label
,netsuite_project_stage_id
,netsuite_push_project_stage_filter
,ns_projStageID
,SWT_INS_DT
)
SELECT DISTINCT
NO_Projectstage_stg_Tmp.id
,created
,NO_Projectstage_stg_Tmp.updated
,name
,position
,enable_team
,enable_utilization
,enable_project_assignments
,enable_phase_and_task
,enable_analysis
,enable_billing
,enable_recognition
,enable_pricing
,picklist_label
,netsuite_project_stage_id
,netsuite_push_project_stage_filter
,ns_projStageID
,SYSDATE AS SWT_INS_DT
FROM NO_Projectstage_stg_Tmp JOIN NO_Projectstage_stg_Tmp_Key ON NO_Projectstage_stg_Tmp.Id= NO_Projectstage_stg_Tmp_Key.Id AND NO_Projectstage_stg_Tmp.Updated=NO_Projectstage_stg_Tmp_Key.Updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_Projectstage BASE
WHERE NO_Projectstage_stg_Tmp.Id = BASE.Id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_Projectstage' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_Projectstage' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_Projectstage',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_Projectstage") ,(select count(*) from swt_rpt_base.NO_Projectstage where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

select do_tm_task('mergeout','swt_rpt_stg.NO_Projectstage_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_Projectstage');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_Projectstage');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_Projectstage_Hist SELECT * from swt_rpt_stg.NO_Projectstage;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_Projectstage;
