/****
****Script Name   : NO_Entitytag.sql
****Description   : Incremental data load for NO_Entitytag
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
select 'NETSUITEOPENAIR','NO_Entitytag',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_Entitytag") ,null,'N';

Commit;



CREATE LOCAL TEMP TABLE NO_Entitytag_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_Entitytag)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Entitytag_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,Updated FROM swt_rpt_base.NO_Entitytag)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Entitytag_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(Updated) as Updated FROM NO_Entitytag_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_Entitytag_Hist
(
id
,default_for_entity
,userid
,projectid
,created
,tag_group_attributeid
,end_date
,customerid
,updated
,start_date
,tag_group_attribute_name
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,default_for_entity
,userid
,projectid
,created
,tag_group_attributeid
,end_date
,customerid
,updated
,start_date
,tag_group_attribute_name
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_Entitytag WHERE id in
(SELECT STG.id FROM NO_Entitytag_stg_Tmp_Key STG JOIN NO_Entitytag_base_Tmp
ON STG.id = NO_Entitytag_base_Tmp.id AND STG.updated >= NO_Entitytag_base_Tmp.updated);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_Entitytag_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;





/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_Entitytag WHERE id in
(SELECT STG.id FROM NO_Entitytag_stg_Tmp_Key STG JOIN NO_Entitytag_base_Tmp
ON STG.id = NO_Entitytag_base_Tmp.id AND STG.updated >= NO_Entitytag_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_Entitytag
(
id
,default_for_entity
,userid
,projectid
,created
,tag_group_attributeid
,end_date
,customerid
,updated
,start_date
,tag_group_attribute_name
,SWT_INS_DT

)
SELECT DISTINCT
NO_Entitytag_stg_Tmp.id
,default_for_entity
,userid
,projectid
,created
,tag_group_attributeid
,end_date
,customerid
,NO_Entitytag_stg_Tmp.updated
,start_date
,tag_group_attribute_name
,SYSDATE AS SWT_INS_DT
FROM NO_Entitytag_stg_Tmp JOIN NO_Entitytag_stg_Tmp_Key ON NO_Entitytag_stg_Tmp.Id= NO_Entitytag_stg_Tmp_Key.Id AND NO_Entitytag_stg_Tmp.Updated=NO_Entitytag_stg_Tmp_Key.Updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_Entitytag BASE
WHERE NO_Entitytag_stg_Tmp.Id = BASE.Id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_Entitytag' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_Entitytag' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_Entitytag',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_Entitytag") ,(select count(*) from swt_rpt_base.NO_Entitytag where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


select do_tm_task('mergeout','swt_rpt_stg.NO_Entitytag_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_Entitytag');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_Entitytag');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_Entitytag_Hist SELECT * from swt_rpt_stg.NO_Entitytag;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_Entitytag;
