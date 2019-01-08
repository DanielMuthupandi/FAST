/****
****Script Name   : NO_Currency.sql
****Description   : Full data load for NO_Currency
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
  select 'NETSUITEOPENAIR','NO_Currency',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_Currency") ,null,'N';

  Commit;  

delete /*+DIRECT*/ from swt_rpt_stg.NO_Currency_Hist  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

truncate table "swt_rpt_base".NO_Currency;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_Currency
(
	 rate
	,created
	,symbol
	,updated
	,SWT_INS_DT
 )
SELECT DISTINCT 
	 rate
	,created
	,symbol
	,updated
	,SYSDATE AS SWT_INS_DT
FROM "swt_rpt_stg".NO_Currency;
		
		
/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_Currency' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_Currency' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_Currency',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_Currency") ,(select count(*) from swt_rpt_base.NO_Currency where SWT_INS_DT::date = sysdate::date),'Y';

   Commit;
   
INSERT /*+DIRECT*/ INTO swt_rpt_stg.NO_Currency_Hist SELECT * FROM swt_rpt_stg.NO_Currency;

COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_Currency;
select do_tm_task('mergeout','swt_rpt_stg.NO_Currency_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_Currency');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_Currency'); 
