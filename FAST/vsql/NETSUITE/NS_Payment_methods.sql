
/****
****Script Name	  : NS_Payment_methods.sql
****Description   : Truncate and data load for NS_Payment_methods
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
select 'NETSUITE','NS_Payment_methods',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NS_Payment_methods") ,null,'N';

Commit;


 /* Full load VSQL script for loading data from Stage to Base */  


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Payment_methods_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

delete /*+DIRECT*/ from "swt_rpt_base".NS_Payment_methods;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Payment_methods
(
date_last_modified
,default_account_id
,external_0
,isinactive
,name
,payment_method_extid
,payment_method_id
,payment_method_tags
,SWT_INS_DT
)
SELECT DISTINCT 
date_last_modified
,default_account_id
,external_0
,isinactive
,name
,payment_method_extid
,payment_method_id
,payment_method_tags
,sysdate as SWT_INS_DT
FROM "swt_rpt_stg"."NS_Payment_methods";


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Payment_methods' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Payment_methods' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Payment_methods',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NS_Payment_methods") ,(select count(*) from swt_rpt_base.NS_Payment_methods where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Payment_methods_Hist SELECT * from "swt_rpt_stg".NS_Payment_methods;

Commit;

TRUNCATE TABLE swt_rpt_stg.NS_Payment_methods;

SELECT DO_TM_TASK('mergeout', 'swt_rpt_base.NS_Payment_methods');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.NS_Payment_methods_Hist');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.NS_Payment_methods');

