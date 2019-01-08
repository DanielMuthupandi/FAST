/****
****Script Name	  : SF_AccountHistory.sql
****Description   : Append data load for SF_AccountHistory
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
select 'SFDC','SF_AccountHistory',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."SF_AccountHistory") ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.SF_AccountHistory_Hist SELECT * FROM swt_rpt_stg.SF_AccountHistory;

COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_AccountHistory where id in (
select id from swt_rpt_stg.SF_AccountHistory group by id,CreatedDate having count(1)>1)
group by id);
delete from swt_rpt_stg.SF_AccountHistory where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_AccountHistory.id=t2.id and swt_rpt_stg.SF_AccountHistory.auto_id<t2.auto_id);

Commit;

CREATE LOCAL TEMP TABLE SF_AccountHistory_stg_temp ON COMMIT PRESERVE ROWS AS (
select distinct * from swt_rpt_stg.SF_AccountHistory);


TRUNCATE TABLE swt_rpt_stg.SF_AccountHistory;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_AccountHistory
(
Id
,IsDeleted
,AccountId
,CreatedById
,CreatedDate
,Field
,OldValue
,NewValue
,SWT_INS_DT
)
SELECT DISTINCT
Id
,IsDeleted
,AccountId
,CreatedById
,CreatedDate
,Field
,OldValue
,NewValue
,SYSDATE as SWT_INS_DT
FROM SF_AccountHistory_stg_temp;




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
select 'SFDC','SF_AccountHistory',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."SF_AccountHistory") ,(select count(*) from swt_rpt_base.SF_AccountHistory where SWT_INS_DT::date = sysdate::date),'Y';

Commit;
/* Deleting partial audit entry */

/*DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_AccountHistory' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_AccountHistory' and  COMPLTN_STAT = 'N');

commit;
*/

select do_tm_task('mergeout','swt_rpt_stg.SF_AccountHistory_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_AccountHistory');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS ('swt_rpt_base.SF_AccountHistory');




