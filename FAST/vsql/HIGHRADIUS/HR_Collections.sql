/****
****Script Name   : HR_Collections.sql
****Description   : Truncate and data load for HR_Collections
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
  select 'HIGHRADIUS','HR_Collections',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."HR_Collections") ,null,'N';

  Commit;  

CREATE LOCAL TEMP TABLE HR_Collections_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.HR_Collections)
SEGMENTED BY HASH(account_customer_number) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.HR_Collections_Hist
(
company_code
,account_customer_number
,processor_user_full_name
,customer_segment
,processor_supervisor
,LD_DT
,SWT_INS_DT
,d_source
)
select
 company_code
,account_customer_number
,processor_user_full_name
,customer_segment
,processor_supervisor
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".HR_Collections WHERE account_customer_number in (SELECT account_customer_number FROM HR_Collections_stg_Tmp);

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."HR_Collections_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".HR_Collections WHERE account_customer_number in (SELECT account_customer_number FROM HR_Collections_stg_Tmp);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".HR_Collections
(
 company_code
,account_customer_number
,processor_user_full_name
,customer_segment
,processor_supervisor
,SWT_INS_DT
)
SELECT DISTINCT 
company_code
,STG.account_customer_number
,processor_user_full_name
,customer_segment
,processor_supervisor
,SYSDATE AS SWT_INS_DT
FROM HR_Collections_stg_Tmp STG 
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".HR_Collections BASE
WHERE STG.account_customer_number = BASE.account_customer_number );


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'HIGHRADIUS' and
TBL_NM = 'HR_Collections' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'HIGHRADIUS' and  TBL_NM = 'HR_Collections' and  COMPLTN_STAT = 'N');
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
select 'HIGHRADIUS','HR_Collections',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."HR_Collections") ,(select count(*) from swt_rpt_base.HR_Collections where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

SELECT PURGE_TABLE('swt_rpt_base.HR_Collections');
SELECT PURGE_TABLE('swt_rpt_stg.HR_Collections_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.HR_Collections');

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".HR_Collections_Hist SELECT * from "swt_rpt_stg".HR_Collections;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.HR_Collections;


