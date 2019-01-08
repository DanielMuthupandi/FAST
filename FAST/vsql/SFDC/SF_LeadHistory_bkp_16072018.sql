/****
****Script Name   : SF_LeadHistory.sql
****Description   : Append only for SF_LeadHistory
****/

/*Setting timing on */
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
select 'SFDC','SF_LeadHistory',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."SF_LeadHistory") ,null,'N';

Commit;


/* Incremental VSQL script for loading data from Stage to Base */


INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_LeadHistory
(
Field
,IsDeleted
,LeadId
,NewValue
,OldValue
,Id
,CreatedDate
,CreatedById
,SWT_INS_DT
)
SELECT DISTINCT 
Field
,IsDeleted
,LeadId
,NewValue
,OldValue
,Id
,CreatedDate
,CreatedById
,SYSDATE AS SWT_INS_DT
FROM "swt_rpt_stg".SF_LeadHistory;



/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_LeadHistory' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_LeadHistory' and  COMPLTN_STAT = 'N');


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
select 'SFDC','SF_LeadHistory',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."SF_LeadHistory") ,(select count(*) from swt_rpt_base.SF_LeadHistory where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.SF_LeadHistory_Hist SELECT * FROM swt_rpt_stg.SF_LeadHistory;

COMMIT;

select do_tm_task('mergeout','swt_rpt_stg.SF_LeadHistory_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_LeadHistory');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_LeadHistory');

TRUNCATE TABLE swt_rpt_stg.SF_LeadHistory;
