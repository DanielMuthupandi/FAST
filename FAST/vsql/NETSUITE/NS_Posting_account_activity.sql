/****
****Script Name   : NS_Posting_account_activity.sql
****Description   : Truncate and data load for NS_Posting_account_activity
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
  select 'NETSUITE','NS_Posting_account_activity',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NS_Posting_account_activity") ,null,'N';

  Commit;  



 /* Full load VSQL script for loading data from Stage to Base */  


TRUNCATE TABLE "swt_rpt_base".NS_Posting_account_activity;

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Posting_account_activity_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Posting_account_activity
(
account_id
,accounting_book_id
,accounting_period_id
,activity_date
,amount
,amount_foreign
,class_id
,department_id
,entity_id
,item_id
,location_id
,partner_id
,promotion_code_id
,quantity
,sales_rep_id
,subsidiary_id
,SWT_INS_DT
)
SELECT 
DISTINCT
account_id
,accounting_book_id
,accounting_period_id
,activity_date
,amount
,amount_foreign
,class_id
,department_id
,entity_id
,item_id
,location_id
,partner_id
,promotion_code_id
,quantity
,sales_rep_id
,subsidiary_id
,SYSDATE AS SWT_INS_DT
FROM "swt_rpt_stg"."NS_Posting_account_activity";

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Posting_account_activity' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Posting_account_activity' and  COMPLTN_STAT = 'N');


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
select 'NETSUITE','NS_Posting_account_activity',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NS_Posting_account_activity") ,(select count(*) from swt_rpt_base.NS_Posting_account_activity where SWT_INS_DT::date = sysdate::date),'Y';

   Commit;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.NS_Posting_account_activity_Hist SELECT * FROM swt_rpt_stg.NS_Posting_account_activity;

COMMIT;

SELECT PURGE_TABLE('swt_rpt_stg.NS_Posting_account_activity_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Posting_account_activity');

TRUNCATE TABLE swt_rpt_stg.NS_Posting_account_activity;
 
