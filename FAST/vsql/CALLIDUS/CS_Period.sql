

/****
****Script Name   : CS_Period.sql
****Description   : Incremental  data load for CS_Period
****/

/* Setting timing on**/
\timing

/* SET SESSION AUTOCOMMIT TO OFF; */

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
select 'CALLIDUS','CS_Period',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."CS_Period") ,null,'N';

Commit;

CREATE LOCAL TEMP TABLE CS_Period_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.CS_Period)
SEGMENTED BY HASH(PERIODSEQ) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.CS_Period_Hist
(
PERIODSEQ
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,NAME
,SHORTNAME
,DESCRIPTION
,CALENDARSEQ
,PARENTSEQ
,PERIODTYPESEQ
,STARTDATE
,ENDDATE
,LD_DT
,SWT_INS_DT
,d_source
)
select
PERIODSEQ
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,NAME
,SHORTNAME
,DESCRIPTION
,CALENDARSEQ
,PARENTSEQ
,PERIODTYPESEQ
,STARTDATE
,ENDDATE
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".CS_Period WHERE PERIODSEQ IN (SELECT PERIODSEQ FROM CS_Period_stg_Tmp);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."CS_Period_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */


DELETE /*+DIRECT*/ FROM "swt_rpt_base"."CS_Period" WHERE PERIODSEQ IN (SELECT PERIODSEQ FROM CS_Period_stg_Tmp);

INSERT /*+DIRECT*/ INTO "swt_rpt_base"."CS_Period"
(
PERIODSEQ
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,NAME
,SHORTNAME
,DESCRIPTION
,CALENDARSEQ
,PARENTSEQ
,PERIODTYPESEQ
,STARTDATE
,ENDDATE
,SWT_INS_DT
)
SELECT DISTINCT
PERIODSEQ
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,NAME
,SHORTNAME
,DESCRIPTION
,CALENDARSEQ
,PARENTSEQ
,PERIODTYPESEQ
,STARTDATE
,ENDDATE
,SYSDATE AS SWT_INS_DT
FROM CS_Period_stg_Tmp;


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'CALLIDUS' and
TBL_NM = 'CS_Period' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'CALLIDUS' and  TBL_NM = 'CS_Period' and  COMPLTN_STAT = 'N');


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
select 'CALLIDUS','CS_Period',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."CS_Period") ,(select count(*) from swt_rpt_base.CS_Period where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


SELECT PURGE_TABLE('swt_rpt_base.CS_Period');
SELECT PURGE_TABLE('swt_rpt_stg.CS_Period_Hist');
select ANALYZE_STATISTICS('swt_rpt_base.CS_Period');
INSERT /*+Direct*/ INTO swt_rpt_stg.CS_Period_Hist SELECT * from swt_rpt_stg.CS_Period;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.CS_Period;

