/****
****Script Name	  : HR_Deductions.sql
****Description   : Incremental data load for HR_Deductions
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
select 'HIGHRADIUS','HR_Deductions',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."HR_Deductions") ,null,'N';

Commit;

CREATE LOCAL TEMP TABLE HR_Deductions_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.HR_Deductions)
SEGMENTED BY HASH(pk_deduction_id) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.HR_Deductions_Hist
(
company_code
,account_customer_number
,pk_deduction_id
,reason_code
,create_date
,resolution_date
,closed_date
,owner_user_full_name
,resolution_type
,root_cause
,invoice_number
,LD_DT
,SWT_INS_DT
,d_source
)
select
company_code
,account_customer_number
,pk_deduction_id
,reason_code
,create_date
,resolution_date
,closed_date
,owner_user_full_name
,resolution_type
,root_cause
,invoice_number
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".HR_Deductions WHERE pk_deduction_id in (SELECT pk_deduction_id FROM HR_Deductions_stg_Tmp);

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."HR_Deductions_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".HR_Deductions WHERE  pk_deduction_id in (SELECT pk_deduction_id FROM HR_Deductions_stg_Tmp);


INSERT /*+DIRECT*/ INTO "swt_rpt_base".HR_Deductions
(
company_code
,account_customer_number
,pk_deduction_id
,reason_code
,create_date
,resolution_date
,closed_date
,owner_user_full_name
,resolution_type
,root_cause
,invoice_number
,SWT_INS_DT
)
SELECT DISTINCT 
company_code
,account_customer_number
,pk_deduction_id
,reason_code
,create_date
,resolution_date
,closed_date
,owner_user_full_name
,resolution_type
,root_cause
,invoice_number
,SYSDATE AS SWT_INS_DT
FROM HR_Deductions_stg_Tmp STG
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".HR_Deductions BASE
WHERE STG.pk_deduction_id = BASE.pk_deduction_id );


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'HIGHRADIUS' and
TBL_NM = 'HR_Deductions' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'HIGHRADIUS' and  TBL_NM = 'HR_Deductions' and  COMPLTN_STAT = 'N');
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
select 'HIGHRADIUS','HR_Deductions',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."HR_Deductions") ,(select count(*) from swt_rpt_base.HR_Deductions where SWT_INS_DT::date = sysdate::date),'Y';


Commit;

SELECT PURGE_TABLE('swt_rpt_base.HR_Deductions');
SELECT PURGE_TABLE('swt_rpt_stg.HR_Deductions_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.HR_Deductions');

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".HR_Deductions_Hist SELECT * from "swt_rpt_stg".HR_Deductions;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.HR_Deductions;

