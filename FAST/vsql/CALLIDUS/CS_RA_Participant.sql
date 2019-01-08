/****
****Script Name   : Trnc_CS_RA_Participant.sql
****Description   : Truncate and data load for CS_RA_Participant
****/

/* Setting timing on**/
\timing

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select sysdate st from dual;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.FAST_LD_AUDT
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
  select 'CALLIDUS','CS_RA_Participant',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."CS_RA_Participant") ,null,'N';

  Commit;  

TRUNCATE TABLE "swt_rpt_base".CS_RA_Participant;

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from swt_rpt_stg.CS_RA_Participant_Hist  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".CS_RA_Participant
(
	PAYEESEQ
	,EFFECTIVESTARTDATE
	,EFFECTIVEENDDATE
	,CREATEDATE
	,REMOVEDATE
	,PAGENUMBER
	,REPORTATTRIBUTE1
	,REPORTATTRIBUTE2
	,REPORTATTRIBUTE3
	,REPORTATTRIBUTE4
	,REPORTATTRIBUTE5
	,REPORTATTRIBUTE6
	,REPORTATTRIBUTE7
	,REPORTATTRIBUTE8
	,REPORTATTRIBUTE9
	,REPORTATTRIBUTE10
	,REPORTATTRIBUTE11
	,REPORTATTRIBUTE12
	,REPORTATTRIBUTE13
	,REPORTATTRIBUTE14
	,REPORTATTRIBUTE15
	,REPORTATTRIBUTE16
	,REPORTATTRIBUTE17
	,REPORTATTRIBUTE18
	,REPORTATTRIBUTE19
	,REPORTATTRIBUTE20
	,SWT_INS_DT
)
SELECT DISTINCT
	PAYEESEQ
	,EFFECTIVESTARTDATE
	,EFFECTIVEENDDATE
	,CREATEDATE
	,REMOVEDATE
	,PAGENUMBER
	,REPORTATTRIBUTE1
	,REPORTATTRIBUTE2
	,REPORTATTRIBUTE3
	,REPORTATTRIBUTE4
	,REPORTATTRIBUTE5
	,REPORTATTRIBUTE6
	,REPORTATTRIBUTE7
	,REPORTATTRIBUTE8
	,REPORTATTRIBUTE9
	,REPORTATTRIBUTE10
	,REPORTATTRIBUTE11
	,REPORTATTRIBUTE12
	,REPORTATTRIBUTE13
	,REPORTATTRIBUTE14
	,REPORTATTRIBUTE15
	,REPORTATTRIBUTE16
	,REPORTATTRIBUTE17
	,REPORTATTRIBUTE18
	,REPORTATTRIBUTE19
	,REPORTATTRIBUTE20
	,SYSDATE
FROM "swt_rpt_stg".CS_RA_Participant;

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'CALLIDUS' and
TBL_NM = 'CS_RA_Participant' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'CALLIDUS' and  TBL_NM = 'CS_RA_Participant' and  COMPLTN_STAT = 'N');


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
select 'CALLIDUS','CS_RA_Participant',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."CS_RA_Participant") ,(select count(*) from swt_rpt_base.CS_RA_Participant where SWT_INS_DT::date = sysdate::date),'Y';

COMMIT;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.CS_RA_Participant_Hist SELECT * FROM swt_rpt_stg.CS_RA_Participant;

COMMIT;

SELECT PURGE_TABLE('swt_rpt_stg.CS_RA_Participant_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.CS_RA_Participant');
TRUNCATE TABLE swt_rpt_stg.CS_RA_Participant;

