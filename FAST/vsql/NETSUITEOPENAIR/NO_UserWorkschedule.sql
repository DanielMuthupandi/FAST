/****
****Script Name   : NO_UserWorkschedule.sql
****Description   : Incremental data load for NO_UserWorkschedule
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
select 'NETSUITEOPENAIR','NO_UserWorkschedule',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_UserWorkschedule") ,null,'N';

Commit;



CREATE LOCAL TEMP TABLE NO_UserWorkschedule_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_UserWorkschedule)
SEGMENTED BY HASH(ID,UPDATED) ALL NODES;


CREATE LOCAL TEMP TABLE NO_UserWorkschedule_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,UPDATED FROM swt_rpt_base.NO_UserWorkschedule)
SEGMENTED BY HASH(ID,UPDATED) ALL NODES;


CREATE LOCAL TEMP TABLE NO_UserWorkschedule_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(UPDATED) as UPDATED FROM NO_UserWorkschedule_stg_Tmp group by id)
SEGMENTED BY HASH(ID,UPDATED) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_UserWorkschedule_Hist
(
id
,name
,userid
,use_this_schedule
,account_workscheduleid
,workdays
,workhours
,created
,updated
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,name
,userid
,use_this_schedule
,account_workscheduleid
,workdays
,workhours
,created
,updated
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_UserWorkschedule WHERE id in
(SELECT STG.id FROM NO_UserWorkschedule_stg_Tmp_Key STG JOIN NO_UserWorkschedule_base_Tmp
ON STG.id = NO_UserWorkschedule_base_Tmp.id AND STG.updated >= NO_UserWorkschedule_base_Tmp.updated);

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_UserWorkschedule_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_UserWorkschedule WHERE id in
(SELECT STG.id FROM NO_UserWorkschedule_stg_Tmp_Key STG JOIN NO_UserWorkschedule_base_Tmp
ON STG.id = NO_UserWorkschedule_base_Tmp.id AND STG.updated >= NO_UserWorkschedule_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_UserWorkschedule
(
id
,name
,userid
,use_this_schedule
,account_workscheduleid
,workdays
,workhours
,created
,updated
,SWT_INS_DT
)
SELECT DISTINCT
NO_UserWorkschedule_stg_Tmp.id
,name
,userid
,use_this_schedule
,account_workscheduleid
,workdays
,workhours
,created
,NO_UserWorkschedule_stg_Tmp.updated
,SYSDATE AS SWT_INS_DT
FROM NO_UserWorkschedule_stg_Tmp JOIN NO_UserWorkschedule_stg_Tmp_Key ON NO_UserWorkschedule_stg_Tmp.id= NO_UserWorkschedule_stg_Tmp_Key.id AND NO_UserWorkschedule_stg_Tmp.updated=NO_UserWorkschedule_stg_Tmp_Key.updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_UserWorkschedule BASE
WHERE NO_UserWorkschedule_stg_Tmp.id = BASE.id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_UserWorkschedule' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_UserWorkschedule' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_UserWorkschedule',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_UserWorkschedule") ,(select count(*) from swt_rpt_base.NO_UserWorkschedule where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

select do_tm_task('mergeout','swt_rpt_stg.NO_UserWorkschedule_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_UserWorkschedule');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_UserWorkschedule');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_UserWorkschedule_Hist SELECT * from swt_rpt_stg.NO_UserWorkschedule;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_UserWorkschedule;
