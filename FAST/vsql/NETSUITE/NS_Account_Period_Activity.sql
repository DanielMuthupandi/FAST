/****
****Script Name   : NS_Account_Period_Activity.sql
****Description   : Truncate and data load for NS_Account_Period_Activity
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
  select 'NETSUITE','NS_Account_Period_Activity',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NS_Account_Period_Activity") ,null,'N';

  Commit;  


 


 /* Full load VSQL script for loading data from Stage to Base */  


TRUNCATE TABLE "swt_rpt_base".NS_Account_Period_Activity;


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Account_Period_Activity_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Account_Period_Activity
(
accounting_book_id
,accounting_period_id
,account_id
,amount
,department_id
,is_hidden_custom_line
,subsidiary_id
,SWT_INS_DT
)
SELECT  DISTINCT
accounting_book_id
,accounting_period_id
,account_id
,amount
,department_id
,is_hidden_custom_line
,subsidiary_id
,SYSDATE AS SWT_INS_DT
FROM "swt_rpt_stg"."NS_Account_Period_Activity";


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Account_Period_Activity' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Account_Period_Activity' and  COMPLTN_STAT = 'N');
*/

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
select 'NETSUITE','NS_Account_Period_Activity',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NS_Account_Period_Activity") ,(select count(*) from swt_rpt_base.NS_Account_Period_Activity where SWT_INS_DT::date = sysdate::date),'Y';

   Commit;
   
INSERT /*+DIRECT*/ INTO swt_rpt_stg.NS_Account_Period_Activity_Hist SELECT * FROM swt_rpt_stg.NS_Account_Period_Activity;

COMMIT;

SELECT DO_TM_TASK('mergeout',  'swt_rpt_base.NS_Account_Period_Activity');
SELECT DO_TM_TASK('mergeout',  'swt_rpt_stg.NS_Account_Period_Activity_Hist');

SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Account_Period_Activity');

TRUNCATE TABLE swt_rpt_stg.NS_Account_Period_Activity;
 
