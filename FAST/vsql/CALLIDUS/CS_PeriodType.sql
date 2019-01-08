/****
****Script Name   : CS_PeriodType.sql
****Description   : Incremental  data load for CS_PeriodType
****/

/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

--SET SESSION AUTOCOMMIT TO OFF;

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
select 'CALLIDUS','CS_PeriodType',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."CS_PeriodType") ,null,'N';

Commit;

CREATE LOCAL TEMP TABLE CS_PeriodType_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.CS_PeriodType)
SEGMENTED BY HASH(PERIODTYPESEQ) ALL NODES;

CREATE LOCAL TEMP TABLE CS_Period_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT PERIODTYPESEQ FROM swt_rpt_base.CS_Period)
SEGMENTED BY HASH(PERIODTYPESEQ) ALL NODES;



/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.CS_PeriodType_Hist
(
PERIODTYPESEQ
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,NAME
,DESCRIPTION
,PERIODTYPELEVEL
,LD_DT
,SWT_INS_DT
,d_source
)
select
PERIODTYPESEQ
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,NAME
,DESCRIPTION
,PERIODTYPELEVEL
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".CS_PeriodType WHERE PERIODTYPESEQ IN
(SELECT STG.PERIODTYPESEQ FROM CS_PeriodType_stg_Tmp STG JOIN CS_Period_base_Tmp BASE ON STG.PERIODTYPESEQ=BASE.PERIODTYPESEQ);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."CS_PeriodType_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base"."CS_PeriodType" WHERE PERIODTYPESEQ IN
(SELECT STG.PERIODTYPESEQ FROM CS_PeriodType_stg_Tmp STG JOIN CS_Period_base_Tmp BASE ON STG.PERIODTYPESEQ=BASE.PERIODTYPESEQ);


INSERT /*+DIRECT*/ INTO "swt_rpt_base"."CS_PeriodType"
(
PERIODTYPESEQ
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,NAME
,DESCRIPTION
,PERIODTYPELEVEL
,SWT_INS_DT
)
SELECT DISTINCT
STG.PERIODTYPESEQ
,STG.CREATEDATE
,STG.REMOVEDATE
,STG.CREATEDBY
,STG.MODIFIEDBY
,STG.NAME
,STG.DESCRIPTION
,STG.PERIODTYPELEVEL
,SYSDATE AS SWT_INS_DT
FROM CS_PeriodType_stg_Tmp STG JOIN CS_Period_base_Tmp BASE ON STG.PERIODTYPESEQ=BASE.PERIODTYPESEQ;


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'CALLIDUS' and
TBL_NM = 'CS_PeriodType' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'CALLIDUS' and  TBL_NM = 'CS_PeriodType' and  COMPLTN_STAT = 'N');


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
select 'CALLIDUS','CS_PeriodType',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."CS_PeriodType") ,(select count(*) from swt_rpt_base.CS_PeriodType where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

SELECT PURGE_TABLE('swt_rpt_base.CS_PeriodType');
SELECT PURGE_TABLE('swt_rpt_stg.CS_PeriodType_Hist');
select ANALYZE_STATISTICS('swt_rpt_base.CS_PeriodType');
INSERT /*+Direct*/ INTO swt_rpt_stg.CS_PeriodType_Hist SELECT * from swt_rpt_stg.CS_PeriodType;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.CS_PeriodType;


