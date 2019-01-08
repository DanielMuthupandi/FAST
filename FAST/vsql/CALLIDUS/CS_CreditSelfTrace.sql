/****
****Script Name   : CS_CreditSelfTrace.sql
****Description   : Full load for CS_CreditSelfTrace 
****/

/* Setting timing on**/
\timing

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select sysdate st from dual;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.FAST_LD_AUDT
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
  select 'CALLIDUS','CS_CreditSelfTrace',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."CS_CreditSelfTrace") ,null,'N';

  Commit;  

TRUNCATE TABLE "swt_rpt_base"."CS_CreditSelfTrace";

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from swt_rpt_stg.CS_CreditSelfTrace_Hist  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base"."CS_CreditSelfTrace"
(SOURCECREDITSEQ
,TARGETCREDITSEQ
,RULESEQ
,PIPELINERUNSEQ
,SOURCEPERIODSEQ
,TARGETPERIODSEQ
,CONTRIBUTIONVALUE
,UNITTYPEFORCONTRIBUTIONVALUE
,SOURCEORIGINTYPEID
,BUSINESSUNITMAP
,PROCESSINGUNITSEQ
,SWT_INS_DT
) 
SELECT DISTINCT 
SOURCECREDITSEQ
,TARGETCREDITSEQ
,RULESEQ
,PIPELINERUNSEQ
,SOURCEPERIODSEQ
,TARGETPERIODSEQ
,CONTRIBUTIONVALUE
,UNITTYPEFORCONTRIBUTIONVALUE
,SOURCEORIGINTYPEID
,BUSINESSUNITMAP
,PROCESSINGUNITSEQ
,SYSDATE AS SWT_INS_DT 
FROM "swt_rpt_stg"."CS_CreditSelfTrace";

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'CALLIDUS' and
TBL_NM = 'CS_CreditSelfTrace' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'CALLIDUS' and  TBL_NM = 'CS_CreditSelfTrace' and  COMPLTN_STAT = 'N');


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
select 'CALLIDUS','CS_CreditSelfTrace',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."CS_CreditSelfTrace") ,(select count(*) from swt_rpt_base.CS_CreditSelfTrace where SWT_INS_DT::date = sysdate::date),'Y';

COMMIT;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.CS_CreditSelfTrace_Hist SELECT * FROM swt_rpt_stg.CS_CreditSelfTrace;

COMMIT;


TRUNCATE TABLE swt_rpt_stg.CS_CreditSelfTrace;

select do_tm_task('mergeout','swt_rpt_stg.CS_CreditSelfTrace_Hist');
select do_tm_task('mergeout','swt_rpt_base.CS_CreditSelfTrace');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.CS_CreditSelfTrace');
