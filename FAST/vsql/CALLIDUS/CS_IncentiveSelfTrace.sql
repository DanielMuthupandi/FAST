/****
****Script Name   : App_CS_IncentiveSelfTrace.sql
****Description   : Append data for CS_IncentiveSelfTrace
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
  select 'CALLIDUS','CS_IncentiveSelfTrace',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."CS_IncentiveSelfTrace") ,null,'N';

  Commit; 

TRUNCATE TABLE "swt_rpt_base".CS_IncentiveSelfTrace;

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from swt_rpt_stg.CS_IncentiveSelfTrace_Hist  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".CS_IncentiveSelfTrace
(
	SOURCEINCENTIVESEQ
	,TARGETINCENTIVESEQ
	,PIPELINERUNSEQ
	,SOURCEPERIODSEQ
	,TARGETPERIODSEQ
	,CONTRIBUTIONVALUE
	,UNITTYPEFORCONTRIBUTIONVALUE
	,BUSINESSUNITMAP
	,PROCESSINGUNITSEQ
	,SWT_INS_DT
)
SELECT DISTINCT 
	SOURCEINCENTIVESEQ
	,TARGETINCENTIVESEQ
	,PIPELINERUNSEQ
	,SOURCEPERIODSEQ
	,TARGETPERIODSEQ
	,CONTRIBUTIONVALUE
	,UNITTYPEFORCONTRIBUTIONVALUE
	,BUSINESSUNITMAP
	,PROCESSINGUNITSEQ
	,SYSDATE
FROM "swt_rpt_stg".CS_IncentiveSelfTrace;

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'CALLIDUS' and
TBL_NM = 'CS_IncentiveSelfTrace' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'CALLIDUS' and  TBL_NM = 'CS_IncentiveSelfTrace' and  COMPLTN_STAT = 'N');


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
select 'CALLIDUS','CS_IncentiveSelfTrace',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."CS_IncentiveSelfTrace") ,(select count(*) from swt_rpt_base.CS_IncentiveSelfTrace where SWT_INS_DT::date = sysdate::date),'Y';

COMMIT;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.CS_IncentiveSelfTrace_Hist SELECT * FROM swt_rpt_stg.CS_IncentiveSelfTrace;

COMMIT;

SELECT PURGE_TABLE('swt_rpt_stg.CS_IncentiveSelfTrace_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.CS_IncentiveSelfTrace');
TRUNCATE TABLE swt_rpt_stg.CS_IncentiveSelfTrace;

