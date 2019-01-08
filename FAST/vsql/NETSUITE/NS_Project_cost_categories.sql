/****
****Script Name   : NS_Project_cost_categories.sql
****Description   : Truncate and data load for NS_Project_cost_categories
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
  select 'NETSUITE','NS_Project_cost_categories',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NS_Project_cost_categories") ,null,'N';

  Commit;  





 /* Full load VSQL script for loading data from Stage to Base */  


TRUNCATE TABLE "swt_rpt_base".NS_Project_cost_categories;


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Project_cost_categories_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Project_cost_categories
( 
category_name
,category_type
,expense_category_id
,full_name
,is_other_category
,is_selected
,project_cost_category_id
,service_item_id
,supplier_category_id
,use_subcategories
,SWT_INS_DT
)
SELECT
DISTINCT
category_name
,category_type
,expense_category_id
,full_name
,is_other_category
,is_selected
,project_cost_category_id
,service_item_id
,supplier_category_id
,use_subcategories
,SYSDATE AS SWT_INS_DT
FROM "swt_rpt_stg"."NS_Project_cost_categories";



/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Project_cost_categories' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Project_cost_categories' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Project_cost_categories',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NS_Project_cost_categories") ,(select count(*) from swt_rpt_base.NS_Project_cost_categories where SWT_INS_DT::date = sysdate::date),'Y';

   Commit;
   
INSERT /*+DIRECT*/ INTO swt_rpt_stg.NS_Project_Cost_Categories_Hist SELECT * FROM swt_rpt_stg.NS_Project_Cost_Categories;

COMMIT;

SELECT PURGE_TABLE('swt_rpt_stg.NS_Project_cost_categories_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Project_cost_categories');

TRUNCATE TABLE swt_rpt_stg.NS_Project_Cost_Categories;
 
