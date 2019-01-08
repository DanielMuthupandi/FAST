/****
****Script Name   : NO_Customer_PO.sql
****Description   : Incremental data load for NO_Customerpo
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
select 'NETSUITEOPENAIR','NO_Customerpo',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_Customerpo") ,null,'N';

Commit;

CREATE LOCAL TEMP TABLE NO_Customerpo_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_Customerpo)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Customerpo_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,Updated FROM swt_rpt_base.NO_Customerpo)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Customerpo_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(Updated) as Updated FROM NO_Customerpo_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,Updated) ALL NODES;

/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_Customerpo_Hist
(
id
,number
,date
,name
,active
,externalid
,total
,created
,currency
,notes
,customerid
,updated
,code
,acct_date
,picklist_label
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,number
,date
,name
,active
,externalid
,total
,created
,currency
,notes
,customerid
,updated
,code
,acct_date
,picklist_label
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_Customerpo WHERE id in
(SELECT STG.id FROM NO_Customerpo_stg_Tmp_Key STG JOIN NO_Customerpo_base_Tmp
ON STG.id = NO_Customerpo_base_Tmp.id AND STG.updated >= NO_Customerpo_base_Tmp.updated);


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_Customerpo_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_Customerpo WHERE id in
(SELECT STG.id FROM NO_Customerpo_stg_Tmp_Key STG JOIN NO_Customerpo_base_Tmp
ON STG.id = NO_Customerpo_base_Tmp.id AND STG.updated >= NO_Customerpo_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_Customerpo
(
id
,number
,date
,name
,active
,externalid
,total
,created
,currency
,notes
,customerid
,updated
,code
,acct_date
,picklist_label
,SWT_INS_DT
)
SELECT DISTINCT
NO_Customerpo_stg_Tmp.id
,number
,date
,name
,active
,externalid
,total
,created
,currency
,notes
,customerid
,NO_Customerpo_stg_Tmp.updated
,code
,acct_date
,picklist_label
,SYSDATE AS SWT_INS_DT
FROM NO_Customerpo_stg_Tmp JOIN NO_Customerpo_stg_Tmp_Key ON NO_Customerpo_stg_Tmp.Id= NO_Customerpo_stg_Tmp_Key.Id AND NO_Customerpo_stg_Tmp.Updated=NO_Customerpo_stg_Tmp_Key.Updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_Customerpo BASE
WHERE NO_Customerpo_stg_Tmp.Id = BASE.Id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_Customerpo' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_Customerpo' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_Customerpo',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_Customerpo") ,(select count(*) from swt_rpt_base.NO_Customerpo where SWT_INS_DT::date = sysdate::date),'Y';

Commit;



select do_tm_task('mergeout','swt_rpt_stg.NO_Customerpo_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_Customerpo');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_Customerpo');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_Customerpo_Hist SELECT * from swt_rpt_stg.NO_Customerpo;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_Customerpo;
