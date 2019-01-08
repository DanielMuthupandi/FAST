/****
****Script Name	  : NS_Currencies.sql
****Description   : Truncate and data load for NS_Currencies
****/
/* Setting timing on**/
\timing
/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select  count(*) count, sysdate st from "swt_rpt_stg"."NS_Currencies";

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
select 'NETSUITE','NS_Currencies',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

 
 /* Full load VSQL script for loading data from Stage to Base */  



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Currencies_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

delete /*+DIRECT*/ from  "swt_rpt_base".NS_Currencies;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Currencies
(
currency_extid
,currency_id
,date_last_modified
,is_inactive
,name
,precision_0
,symbol
,SWT_INS_DT
)
SELECT DISTINCT 
currency_extid
,currency_id
,date_last_modified
,is_inactive
,name
,precision_0
,symbol
,sysdate as SWT_INS_DT
FROM "swt_rpt_stg"."NS_Currencies";


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Currencies' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Currencies' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Currencies',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Currencies where SWT_INS_DT::date = sysdate::date),'Y';

Commit;
INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Currencies_Hist SELECT * from "swt_rpt_stg".NS_Currencies;
COMMIT;

TRUNCATE TABLE swt_rpt_stg.NS_Currencies;

SELECT DO_TM_TASK('mergeout', 'swt_rpt_base.NS_Currencies');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.NS_Currencies_Hist');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.NS_Currencies');

