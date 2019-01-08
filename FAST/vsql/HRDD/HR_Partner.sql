/*rpt Name   : HR_Partner.sql
****Description   : Truncate and data load for HR_Partner
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
select 'HRDD','HR_Partner',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."HR_Partner") ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".HR_Partner_Hist select * from "swt_rpt_stg".HR_Partner;
COMMIT;

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."HR_Partner_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".HR_Partner;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".HR_Partner
(
acquired_on
,assigned_on
,cert_descr
,cert_held_status
,cert_id
,cert_name
,cert_status
,country
,domain
,first_name
,headquarters_id
,hpp_lrnr_id
,last_name
,middle_name
,org_name
,person_email
,person_no
,reseller_id
,siebel_contact_id
,siebel_partner_id
,SWT_INS_DT
)
SELECT DISTINCT 
acquired_on
,assigned_on
,cert_descr
,cert_held_status
,cert_id
,cert_name
,cert_status
,country
,domain
,first_name
,headquarters_id
,hpp_lrnr_id
,last_name
,middle_name
,org_name
,person_email
,person_no
,reseller_id
,siebel_contact_id
,siebel_partner_id
,SYSDATE AS SWT_INS_DT
FROM "swt_rpt_stg"."HR_Partner";

/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'HRDD' and
TBL_NM = 'HR_Partner' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'HRDD' and  TBL_NM = 'HR_Partner' and  COMPLTN_STAT = 'N');
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
select 'HRDD','HR_Partner',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."HR_Partner") ,(select count(*) from swt_rpt_base.HR_Partner where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

TRUNCATE TABLE swt_rpt_stg.HR_Partner;

/*SELECT DROP_PARTITION('swt_rpt_stg.HR_Partner_Hist', TIMESTAMPADD(day,-7,getdate())::date);*/
select do_tm_task('mergeout','swt_rpt_stg.HR_Partner_Hist');
select do_tm_task('mergeout','swt_rpt_base.HR_Partner');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.HR_Partner');




