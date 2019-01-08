/****
****Script Name	  : SF_OpportunityHistory.sql
****Description   : Append data load for SF_OpportunityHistory
****/

/*Setting timing on */
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
  select 'SFDC','SF_OpportunityHistory',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."SF_OpportunityHistory") ,null,'N';

  Commit;


INSERT /*DIRECT*/ INTO "swt_rpt_base".SF_OpportunityHistory
(
 Amount
,CloseDate
,ExpectedRevenue
,ForecastCategory
,IsDeleted
,OpportunityId
,Probability
,StageName
,Id
,CreatedDate
,CreatedById
,CurrencyIsoCode
,SystemModStamp
,SWT_INS_DT
)
SELECT DISTINCT
Amount
,CloseDate
,ExpectedRevenue
,ForecastCategory
,IsDeleted
,OpportunityId
,Probability
,StageName
,Id
,CreatedDate
,CreatedById
,CurrencyIsoCode
,SystemModStamp
,SYSDATE as SWT_INS_DT
FROM "swt_rpt_stg".SF_OpportunityHistory;




/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_OpportunityHistory' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_OpportunityHistory' and  COMPLTN_STAT = 'N');


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
select 'SFDC','SF_OpportunityHistory',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."SF_OpportunityHistory") ,(select count(*) from swt_rpt_base.SF_OpportunityHistory where SWT_INS_DT::date = sysdate::date),'Y';

   Commit;
  
INSERT /*+DIRECT*/ INTO swt_rpt_stg.SF_OpportunityHistory_Hist SELECT * FROM swt_rpt_stg.SF_OpportunityHistory;

COMMIT;

select do_tm_task('mergeout','swt_rpt_stg.SF_OpportunityHistory_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_OpportunityHistory');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_OpportunityHistory');

TRUNCATE TABLE swt_rpt_stg.SF_OpportunityHistory;
 
