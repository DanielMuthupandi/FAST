/****
****Script Name   : AN_Budget.sql
****Description   : Incremental Load
****/

/*Setting timing on */
\timing
--SET SESSION AUTOCOMMIT TO OFF;
\set ON_ERROR_STOP on
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
select 'ANAPLAN','AN_Budget',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."AN_Budget") ,null,'N';

Commit;

CREATE LOCAL TEMP TABLE AN_Budget_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.AN_Budget)
SEGMENTED BY HASH(version) ALL NODES;

delete /*+DIRECT*/ from "swt_rpt_stg"."AN_Budget_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg"."AN_Budget_Hist"
(MRU
,BA
,FA
,PC
,Version
,Period
,USDAmount
,AcctID
,DocumentType
,CostPool
,FinancialOwner
,Quarter
)
SELECT
MRU
,BA
,FA
,PC
,Version
,Period
,USDAmount
,AcctID
,DocumentType
,CostPool
,FinancialOwner
,Quarter
FROM "swt_rpt_base"."AN_Budget" WHERE version in (SELECT distinct Version FROM AN_Budget_stg_Tmp);


delete /*+DIRECT*/ from "swt_rpt_base"."AN_Budget" where version in (SELECT distinct Version FROM AN_Budget_stg_Tmp);

INSERT /*+DIRECT*/ INTO "swt_rpt_base"."AN_Budget"
(MRU
,BA
,FA
,PC
,Version
,Period
,USDAmount
,AcctID
,DocumentType
,CostPool
,FinancialOwner
,Quarter
,SWT_INS_DT)
SELECT DISTINCT
MRU
,BA
,FA
,PC
,Version
,Period
,USDAmount
,AcctID
,DocumentType
,CostPool
,FinancialOwner
,Quarter
,SYSDATE AS SWT_INS_DT
FROM AN_Budget_stg_Tmp;

update swt_rpt_stg.FAST_LD_AUDT set COMPLTN_STAT='Y',END_DT_TIME = sysdate,TGT_REC_CNT = (select count(*) from swt_rpt_base.AN_Budget where SWT_INS_DT::date = sysdate::date)
where SUBJECT_AREA = 'ANAPLAN' and
TBL_NM = 'AN_Budget' and
COMPLTN_STAT = 'N' and
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'ANAPLAN' and  TBL_NM = 'AN_Budget' and  COMPLTN_STAT = 'N');

Commit;


SELECT PURGE_TABLE('swt_rpt_base.AN_Budget');
SELECT PURGE_TABLE('swt_rpt_stg.AN_Budget_Hist');
select ANALYZE_STATISTICS('swt_rpt_base.AN_Budget');
TRUNCATE TABLE swt_rpt_stg.AN_Budget;

