/****
****Script Name   : HR_Credit_Information.sql
****Description   : Truncate and data load for HR_Credit_Information
****/
/*Setting timing on */
\timing

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
  select 'HIGHRADIUS','HR_Credit_Information',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."HR_Credit_Information") ,null,'N';

  Commit;  

CREATE LOCAL TEMP TABLE HR_Credit_Information_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.HR_Credit_Information)
SEGMENTED BY HASH(account_customer_number) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.HR_Credit_Information_Hist
(
company_code
,account_customer_number
,credit_limit
,risk_class
,last_review_date_approval	
,last_review_date
,next_review_date
,updated_by
,processor_user_full_name
,fk_owner_user_full_name
,credit_hold
,credit_hold_reason
,scoring_strategy_name
,field1
,sic_code
,high_risk_status
,global_account_flag
,hq_duns
,LD_DT
,SWT_INS_DT
,d_source
)
select
company_code
,account_customer_number
,credit_limit
,risk_class
,last_review_date_approval	
,last_review_date
,next_review_date
,updated_by
,processor_user_full_name
,fk_owner_user_full_name
,credit_hold
,credit_hold_reason
,scoring_strategy_name
,field1
,sic_code
,high_risk_status
,global_account_flag
,hq_duns
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".HR_Credit_Information WHERE account_customer_number in (SELECT account_customer_number FROM HR_Credit_Information_stg_Tmp);


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."HR_Credit_Information_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".HR_Credit_Information WHERE account_customer_number in (SELECT account_customer_number FROM HR_Credit_Information_stg_Tmp);


INSERT /*+DIRECT*/ INTO "swt_rpt_base".HR_Credit_Information
(
company_code
,account_customer_number
,credit_limit
,risk_class
,last_review_date_approval	
,last_review_date
,next_review_date
,updated_by
,processor_user_full_name
,fk_owner_user_full_name
,credit_hold
,credit_hold_reason
,scoring_strategy_name
,field1
,sic_code
,high_risk_status
,global_account_flag
,hq_duns
,SWT_INS_DT
)
SELECT DISTINCT 
company_code
,account_customer_number
,credit_limit
,risk_class
,last_review_date_approval	
,last_review_date
,next_review_date
,updated_by
,processor_user_full_name
,fk_owner_user_full_name
,credit_hold
,credit_hold_reason
,scoring_strategy_name
,field1
,sic_code
,high_risk_status
,global_account_flag
,hq_duns
,SYSDATE AS SWT_INS_DT
FROM HR_Credit_Information_stg_Tmp STG 
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".HR_Credit_Information BASE
WHERE STG.account_customer_number = BASE.account_customer_number );


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'HIGHRADIUS' and
TBL_NM = 'HR_Credit_Information' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'HIGHRADIUS' and  TBL_NM = 'HR_Credit_Information' and  COMPLTN_STAT = 'N');
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
select 'HIGHRADIUS','HR_Credit_Information',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."HR_Credit_Information") ,(select count(*) from swt_rpt_base.HR_Credit_Information where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

SELECT PURGE_TABLE('swt_rpt_base.HR_Credit_Information');
SELECT PURGE_TABLE('swt_rpt_stg.HR_Credit_Information_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.HR_Credit_Information');

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".HR_Credit_Information_Hist SELECT * from "swt_rpt_stg".HR_Credit_Information;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.HR_Credit_Information;


