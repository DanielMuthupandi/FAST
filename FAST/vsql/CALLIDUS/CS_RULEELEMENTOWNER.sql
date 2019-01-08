/****
****Script Name   : CS_RULEELEMENTOWNER.sql
****Description   : Append data for CS_RULEELEMENTOWNER
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
  select 'CALLIDUS','CS_RULEELEMENTOWNER',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."CS_RULEELEMENTOWNER") ,null,'N';

  Commit; 


TRUNCATE TABLE "swt_rpt_base"."CS_RULEELEMENTOWNER";
/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from swt_rpt_stg.CS_RULEELEMENTOWNER_Hist  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base"."CS_RULEELEMENTOWNER"
(
TENANTID
,RULEELEMENTOWNERSEQ
,EFFECTIVESTARTDATE
,EFFECTIVEENDDATE
,ISLAST
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,BUSINESSUNITMAP
,DESCRIPTION
,MODELSEQ
,SWT_INS_DT
) 
SELECT DISTINCT 
TENANTID
,RULEELEMENTOWNERSEQ
,EFFECTIVESTARTDATE
,EFFECTIVEENDDATE
,ISLAST
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,BUSINESSUNITMAP
,DESCRIPTION
,MODELSEQ
,SYSDATE AS SWT_INS_DT FROM "swt_rpt_stg"."CS_RULEELEMENTOWNER";


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'CALLIDUS' and
TBL_NM = 'CS_RULEELEMENTOWNER' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'CALLIDUS' and  TBL_NM = 'CS_RULEELEMENTOWNER' and  COMPLTN_STAT = 'N');


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
select 'CALLIDUS','CS_RULEELEMENTOWNER',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."CS_RULEELEMENTOWNER") ,(select count(*) from swt_rpt_base.CS_RULEELEMENTOWNER where SWT_INS_DT::date = sysdate::date),'Y';

COMMIT;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.CS_RULEELEMENTOWNER_Hist SELECT * FROM swt_rpt_stg.CS_RULEELEMENTOWNER;

COMMIT;
TRUNCATE TABLE swt_rpt_stg.CS_RULEELEMENTOWNER;

select do_tm_task('mergeout','swt_rpt_stg.CS_RULEELEMENTOWNER_Hist');
select do_tm_task('mergeout','swt_rpt_base.CS_RULEELEMENTOWNER');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.CS_RULEELEMENTOWNER');
