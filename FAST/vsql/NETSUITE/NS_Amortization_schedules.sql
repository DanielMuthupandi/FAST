/****
****Script Name   : NS_Amortization_schedules.sql
****Description   : Truncate and data load for NS_Amortization_schedules
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
  select 'NETSUITE','NS_Amortization_schedules',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NS_Amortization_schedules") ,null,'N';

  Commit;  



 /* Full load VSQL script for loading data from Stage to Base */  

TRUNCATE TABLE "swt_rpt_base".NS_Amortization_schedules;


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Amortization_schedules_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Amortization_schedules
( 
amount
,initial_amount
,is_template
,name
,period_offset
,residual
,schedule_id
,schedule_method
,schedule_number
,schedule_type
,start_offset
,term_source
,SWT_INS_DT
)
SELECT
DISTINCT 
amount
,initial_amount
,is_template
,name
,period_offset
,residual
,schedule_id
,schedule_method
,schedule_number
,schedule_type
,start_offset
,term_source
,SYSDATE AS SWT_INS_DT
FROM "swt_rpt_stg"."NS_Amortization_schedules";



/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Amortization_schedules' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Amortization_schedules' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Amortization_schedules',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NS_Amortization_schedules") ,(select count(*) from swt_rpt_base.NS_Amortization_schedules where SWT_INS_DT::date = sysdate::date),'Y';

   Commit;
   
INSERT /*+DIRECT*/ INTO swt_rpt_stg.NS_Amortization_schedules_Hist SELECT * FROM swt_rpt_stg.NS_Amortization_schedules;

COMMIT;

SELECT DO_TM_TASK('mergeout',  'swt_rpt_stg.NS_Amortization_schedules_Hist');

SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Amortization_schedules');

TRUNCATE TABLE swt_rpt_stg.NS_Amortization_schedules;
 
