/****
****Script Name   : CS_Ruleelement.sql
****Description   : Append data for CS_Ruleelement
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
  select 'CALLIDUS','CS_Ruleelement',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."CS_Ruleelement") ,null,'N';

  Commit; 


TRUNCATE TABLE "swt_rpt_base"."CS_Ruleelement";
/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from swt_rpt_stg.CS_Ruleelement_Hist  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base"."CS_Ruleelement"
(
TENANTID
,RULEELEMENTSEQ
,EFFECTIVESTARTDATE
,EFFECTIVEENDDATE
,ISLAST
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,CALENDARSEQ
,EXPRESSIONTYPEFORRULEUSAGE
,RETURNTYPE
,INPUTSIGNATURE
,DESCRIPTION
,OWNINGELEMENTSEQ
,NOTALLOWUPDATE
,MODELSEQ
,SWT_INS_DT
) 
SELECT DISTINCT 
TENANTID
,RULEELEMENTSEQ
,EFFECTIVESTARTDATE
,EFFECTIVEENDDATE
,ISLAST
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,CALENDARSEQ
,EXPRESSIONTYPEFORRULEUSAGE
,RETURNTYPE
,INPUTSIGNATURE
,DESCRIPTION
,OWNINGELEMENTSEQ
,NOTALLOWUPDATE
,MODELSEQ
,SYSDATE AS SWT_INS_DT FROM "swt_rpt_stg"."CS_Ruleelement";


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'CALLIDUS' and
TBL_NM = 'CS_Ruleelement' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'CALLIDUS' and  TBL_NM = 'CS_Ruleelement' and  COMPLTN_STAT = 'N');


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
select 'CALLIDUS','CS_Ruleelement',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."CS_Ruleelement") ,(select count(*) from swt_rpt_base.CS_Ruleelement where SWT_INS_DT::date = sysdate::date),'Y';

COMMIT;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.CS_Ruleelement_Hist SELECT * FROM swt_rpt_stg.CS_Ruleelement;

COMMIT;

SELECT PURGE_TABLE('swt_rpt_stg.CS_Ruleelement_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.CS_Ruleelement');
TRUNCATE TABLE swt_rpt_stg.CS_Ruleelement;



