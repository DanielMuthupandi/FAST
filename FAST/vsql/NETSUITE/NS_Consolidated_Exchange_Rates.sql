/****
****Script Name   : NS_Consolidated_Exchange_Rates.sql
****Description   : Truncate and data load for NS_Consolidated_Exchange_Rates
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
  select 'NETSUITE','NS_Consolidated_Exchange_Rates',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NS_Consolidated_Exchange_Rates") ,null,'N';

  Commit;  


 
 /* Full load VSQL script for loading data from Stage to Base */  


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Consolidated_Exchange_Rates_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

delete /*+DIRECT*/ from "swt_rpt_base".NS_Consolidated_Exchange_Rates;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Consolidated_Exchange_Rates
(
accounting_book_id 
,accounting_period_id
,average_budget_rate
,average_rate
,consolidated_exchange_rate_id
,current_budget_rate
,current_rate
,from_subsidiary_id
,historical_budget_rate
,historical_rate
,to_subsidiary_id
,SWT_INS_DT
)
SELECT
DISTINCT
accounting_book_id
,accounting_period_id
,average_budget_rate
,average_rate
,consolidated_exchange_rate_id
,current_budget_rate
,current_rate
,from_subsidiary_id
,historical_budget_rate
,historical_rate
,to_subsidiary_id
,SYSDATE AS SWT_INS_DT
FROM "swt_rpt_stg"."NS_Consolidated_Exchange_Rates";


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Consolidated_Exchange_Rates' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Consolidated_Exchange_Rates' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Consolidated_Exchange_Rates',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NS_Consolidated_Exchange_Rates") ,(select count(*) from swt_rpt_base.NS_Consolidated_Exchange_Rates where SWT_INS_DT::date = sysdate::date),'Y';

   Commit;
   

INSERT /*+DIRECT*/ INTO swt_rpt_stg.NS_Consolidated_Exchange_Rates_Hist SELECT * FROM swt_rpt_stg.NS_Consolidated_Exchange_Rates;

COMMIT;

TRUNCATE TABLE swt_rpt_stg.NS_Consolidated_Exchange_Rates;


SELECT DO_TM_TASK('mergeout',  'swt_rpt_base.NS_Consolidated_Exchange_Rates');
SELECT DO_TM_TASK('mergeout',  'swt_rpt_stg.NS_Consolidated_Exchange_Rates_Hist');

SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.NS_Consolidated_Exchange_Rates');
 
