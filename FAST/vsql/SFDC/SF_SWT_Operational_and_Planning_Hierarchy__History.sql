/****
****Script Name	  : SF_SWT_Operational_and_Planning_Hierarchy__History.sql
****Description   : Append data load for SF_SWT_Operational_and_Planning_Hierarchy__History
****/

/**SET SESSION AUTOCOMMIT TO OFF;**/

/*Setting timing on */
\timing

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
select 'SFDC','SF_SWT_Operational_and_Planning_Hierarchy__History',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."SF_SWT_Operational_and_Planning_Hierarchy__History") ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_SWT_Operational_and_Planning_Hierarchy__History
(
CreatedById
,CreatedDate
,Field
,Id
,IsDeleted
,NewValue
,OldValue
,ParentId
,SWT_INS_DT
)
SELECT DISTINCT
CreatedById
,CreatedDate
,Field
,Id
,IsDeleted
,NewValue
,OldValue
,ParentId
,SYSDATE as SWT_INS_DT
FROM "swt_rpt_stg".SF_SWT_Operational_and_Planning_Hierarchy__History;


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
select 'SFDC','SF_SWT_Operational_and_Planning_Hierarchy__History',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."SF_SWT_Operational_and_Planning_Hierarchy__History") ,(select count(*) from swt_rpt_base.SF_SWT_Operational_and_Planning_Hierarchy__History where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.SF_SWT_Operational_and_Planning_Hierarchy__History_Hist SELECT * FROM swt_rpt_stg.SF_SWT_Operational_and_Planning_Hierarchy__History;

COMMIT;

/* Deleting partial audit entry */

/*DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_SWT_Operational_and_Planning_Hierarchy__History' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_SWT_Operational_and_Planning_Hierarchy__History' and  COMPLTN_STAT = 'N');
commit;
*/

select do_tm_task('mergeout','swt_rpt_stg.SF_SWT_Operational_and_Planning_Hierarchy__History_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_SWT_Operational_and_Planning_Hierarchy__History');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_SWT_Operational_and_Planning_Hierarchy__History');

TRUNCATE TABLE swt_rpt_stg.SF_SWT_Operational_and_Planning_Hierarchy__History;

