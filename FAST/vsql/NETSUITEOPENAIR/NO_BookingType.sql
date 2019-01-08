/****
****Script Name   : NO_BookingType.sql
****Description   : Incremental data load for NO_BookingType
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
select 'NETSUITEOPENAIR','NO_BookingType',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_BookingType") ,null,'N';

Commit;


CREATE LOCAL TEMP TABLE NO_BookingType_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_BookingType)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_BookingType_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,Updated FROM swt_rpt_base.NO_BookingType)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_BookingType_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(Updated) as Updated FROM NO_BookingType_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,Updated) ALL NODES;



/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_BookingType_Hist
(
id
,priority
,created
,name
,active
,updated
,default_for_approval_status
,approval_status
,picklist_label
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,priority
,created
,name
,active
,updated
,default_for_approval_status
,approval_status
,picklist_label
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_BookingType WHERE id in
(SELECT STG.id FROM NO_BookingType_stg_Tmp_Key STG JOIN NO_BookingType_base_Tmp
ON STG.id = NO_BookingType_base_Tmp.id AND STG.updated >= NO_BookingType_base_Tmp.updated);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_BookingType_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_BookingType WHERE id in
(SELECT STG.id FROM NO_BookingType_stg_Tmp_Key STG JOIN NO_BookingType_base_Tmp
ON STG.id = NO_BookingType_base_Tmp.id AND STG.updated >= NO_BookingType_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_BookingType
(
id
,priority
,created
,name
,active
,updated
,default_for_approval_status
,approval_status
,picklist_label
,SWT_INS_DT
)
SELECT DISTINCT
NO_BookingType_stg_Tmp.id
,priority
,created
,name
,active
,NO_BookingType_stg_Tmp.updated
,default_for_approval_status
,approval_status
,picklist_label
,SYSDATE AS SWT_INS_DT
FROM NO_BookingType_stg_Tmp JOIN NO_BookingType_stg_Tmp_Key ON NO_BookingType_stg_Tmp.Id= NO_BookingType_stg_Tmp_Key.Id AND NO_BookingType_stg_Tmp.Updated=NO_BookingType_stg_Tmp_Key.Updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_BookingType BASE
WHERE NO_BookingType_stg_Tmp.Id = BASE.Id);

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_BookingType' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_BookingType' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_BookingType',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_BookingType") ,(select count(*) from swt_rpt_base.NO_BookingType where SWT_INS_DT::date = sysdate::date),'Y';

Commit;



select do_tm_task('mergeout','swt_rpt_stg.NO_BookingType_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_BookingType');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_BookingType');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');

INSERT /*+Direct*/ INTO swt_rpt_stg.NO_BookingType_Hist SELECT * from swt_rpt_stg.NO_BookingType;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_BookingType;
