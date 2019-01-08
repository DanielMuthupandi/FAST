	/****
****Script Name   : NS_Transaction_tax_detail.sql
****Description   : Truncate and data load for NS_Transaction_tax_detail
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
  select 'NETSUITE','NS_Transaction_tax_detail',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NS_Transaction_tax_detail") ,null,'N';

  Commit;  


 
 /* Full load VSQL script for loading data from Stage to Base */  


TRUNCATE TABLE "swt_rpt_base".NS_Transaction_tax_detail;


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Transaction_tax_detail_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

CREATE LOCAL TEMP TABLE NS_Transaction_tax_detail_stg_temp ON COMMIT PRESERVE ROWS AS
(SELECT DISTINCT * FROM swt_rpt_stg.NS_Transaction_tax_detail);

INSERT /*+DIRECT*/ INTO "swt_rpt_base"."NS_Transaction_tax_detail"
( 
account_id
,amount
,amount_foreign
,amount_net
,calculation_comment
,tax_basis_amount
,tax_item_id
,tax_rate
,tax_type
,transaction_id
,transaction_line_id
,SWT_INS_DT
)
SELECT
account_id
,amount
,amount_foreign
,amount_net
,calculation_comment
,tax_basis_amount
,tax_item_id
,tax_rate
,tax_type
,transaction_id
,transaction_line_id
,SYSDATE AS SWT_INS_DT
FROM NS_Transaction_tax_detail_stg_temp;


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Transaction_tax_detail' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Transaction_tax_detail' and  COMPLTN_STAT = 'N');


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
select 'NETSUITE','NS_Transaction_tax_detail',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NS_Transaction_tax_detail") ,(select count(*) from swt_rpt_base.NS_Transaction_tax_detail where SWT_INS_DT::date = sysdate::date),'Y';

   Commit;
   
INSERT /*+DIRECT*/ INTO swt_rpt_stg.NS_Transaction_Tax_Detail_Hist SELECT * FROM swt_rpt_stg.NS_Transaction_Tax_Detail;

COMMIT;

SELECT PURGE_TABLE('swt_rpt_stg.NS_Transaction_tax_detail_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Transaction_tax_detail');

TRUNCATE TABLE swt_rpt_stg.NS_Transaction_Tax_Detail;
 
