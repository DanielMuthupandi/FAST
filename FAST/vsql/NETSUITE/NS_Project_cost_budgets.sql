/****
****Script Name   : NS_Project_cost_budgets.sql
****Description   : Truncate and data load for NS_Project_cost_budgets
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
  select 'NETSUITE','NS_Project_cost_budgets',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NS_Project_cost_budgets") ,null,'N';

  Commit;  




 /* Full load VSQL script for loading data from Stage to Base */  


TRUNCATE TABLE "swt_rpt_base".NS_Project_cost_budgets;


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Project_cost_budgets_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Project_cost_budgets
(
amount
,is_calculated
,is_calculated_from_allocations
,month_end
,month_start
,project_cost_category_id
,project_id
,SWT_INS_DT
)
SELECT 
DISTINCT
amount
,is_calculated
,is_calculated_from_allocations
,month_end
,month_start
,project_cost_category_id
,project_id
,SYSDATE AS SWT_INS_DT
FROM "swt_rpt_stg"."NS_Project_cost_budgets";



/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Project_cost_budgets' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Project_cost_budgets' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Project_cost_budgets',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NS_Project_cost_budgets") ,(select count(*) from swt_rpt_base.NS_Project_cost_budgets where SWT_INS_DT::date = sysdate::date),'Y';

   Commit;
   
INSERT /*+DIRECT*/ INTO swt_rpt_stg.NS_Project_Cost_Budgets_Hist SELECT * FROM swt_rpt_stg.NS_Project_Cost_Budgets;

COMMIT;

SELECT PURGE_TABLE('swt_rpt_stg.NS_Project_cost_budgets_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Project_cost_budgets');

TRUNCATE TABLE swt_rpt_stg.NS_Project_Cost_Budgets;
 
