/****
****Script Name   : NO_TagGroupAttribute.sql
****Description   : Incremental data load for NO_TagGroupAttribute
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
select 'NETSUITEOPENAIR','NO_TagGroupAttribute',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_TagGroupAttribute") ,null,'N';

Commit;


CREATE LOCAL TEMP TABLE NO_TagGroupAttribute_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_TagGroupAttribute)
SEGMENTED BY HASH(id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_TagGroupAttribute_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT id,Updated FROM swt_rpt_base.NO_TagGroupAttribute)
SEGMENTED BY HASH(id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_TagGroupAttribute_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(Updated) as Updated FROM NO_TagGroupAttribute_stg_Tmp group by id)
SEGMENTED BY HASH(id,Updated) ALL NODES;

/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_TagGroupAttribute_Hist
(
id
,created
,active
,updated
,name
,tag_groupid
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,created
,active
,updated
,name
,tag_groupid
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_TagGroupAttribute WHERE id in
(SELECT STG.id FROM NO_TagGroupAttribute_stg_Tmp_Key STG JOIN NO_TagGroupAttribute_base_Tmp
ON STG.id = NO_TagGroupAttribute_base_Tmp.id AND STG.updated >= NO_TagGroupAttribute_base_Tmp.updated);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_TagGroupAttribute_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;





/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_TagGroupAttribute WHERE id in
(SELECT STG.id FROM NO_TagGroupAttribute_stg_Tmp_Key STG JOIN NO_TagGroupAttribute_base_Tmp
ON STG.id = NO_TagGroupAttribute_base_Tmp.id AND STG.updated >= NO_TagGroupAttribute_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_TagGroupAttribute
(
id
,created
,active
,updated
,name
,tag_groupid
,SWT_INS_DT
)
SELECT DISTINCT
NO_TagGroupAttribute_stg_Tmp.id
,created
,active
,NO_TagGroupAttribute_stg_Tmp.updated
,name
,tag_groupid
,SYSDATE AS SWT_INS_DT
FROM NO_TagGroupAttribute_stg_Tmp JOIN NO_TagGroupAttribute_stg_Tmp_Key ON NO_TagGroupAttribute_stg_Tmp.id= NO_TagGroupAttribute_stg_Tmp_Key.id AND NO_TagGroupAttribute_stg_Tmp.Updated=NO_TagGroupAttribute_stg_Tmp_Key.Updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_TagGroupAttribute BASE
WHERE NO_TagGroupAttribute_stg_Tmp.id = BASE.id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_TagGroupAttribute' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_TagGroupAttribute' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_TagGroupAttribute',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_TagGroupAttribute") ,(select count(*) from swt_rpt_base.NO_TagGroupAttribute where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

select do_tm_task('mergeout','swt_rpt_stg.NO_TagGroupAttribute_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_TagGroupAttribute');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_TagGroupAttribute');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_TagGroupAttribute_Hist SELECT * from swt_rpt_stg.NO_TagGroupAttribute;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_TagGroupAttribute;

