/****
****Script Name   : Trun_CS_MdltCell.sql
****Description   : Truncate and data load for CS_MdltCell
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
  select 'CALLIDUS','CS_MdltCell',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."CS_MdltCell") ,null,'N';

  Commit;  

TRUNCATE TABLE "swt_rpt_base".CS_MdltCell;

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from swt_rpt_stg.CS_MdltCell_Hist  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".CS_MdltCell
(
	MDLTCELLSEQ
	,MDLTSEQ
	,EFFECTIVESTARTDATE
	,EFFECTIVEENDDATE
	,CREATEDATE
	,REMOVEDATE
	,CREATEDBY
	,MODIFIEDBY
	,USEUSERTIME
	,USERTIMESTARTDATE
	,USERTIMEENDDATE
	,USERTIMEENDPOINTISINRANGE
	,VALUE
	,UNITTYPEFORVALUE
	,RULEELEMENTSEQ
	,VALUETYPE
	,DIM0INDEX
	,DIM1INDEX
	,DIM2INDEX
	,DIM3INDEX
	,DIM4INDEX
	,DIM5INDEX
	,DIM6INDEX
	,DIM7INDEX
	,DIM8INDEX
	,DIM9INDEX
	,DIM10INDEX
	,DIM11INDEX
	,DIM12INDEX
	,DIM13INDEX
	,DIM14INDEX
	,DIM15INDEX
	,SWT_INS_DT
)
SELECT DISTINCT 
	MDLTCELLSEQ
	,MDLTSEQ
	,EFFECTIVESTARTDATE
	,EFFECTIVEENDDATE
	,CREATEDATE
	,REMOVEDATE
	,CREATEDBY
	,MODIFIEDBY
	,USEUSERTIME
	,USERTIMESTARTDATE
	,USERTIMEENDDATE
	,USERTIMEENDPOINTISINRANGE
	,VALUE
	,UNITTYPEFORVALUE
	,RULEELEMENTSEQ
	,VALUETYPE
	,DIM0INDEX
	,DIM1INDEX
	,DIM2INDEX
	,DIM3INDEX
	,DIM4INDEX
	,DIM5INDEX
	,DIM6INDEX
	,DIM7INDEX
	,DIM8INDEX
	,DIM9INDEX
	,DIM10INDEX
	,DIM11INDEX
	,DIM12INDEX
	,DIM13INDEX
	,DIM14INDEX
	,DIM15INDEX
	,SYSDATE
FROM "swt_rpt_stg".CS_MdltCell;


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'CALLIDUS' and
TBL_NM = 'CS_MdltCell' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'CALLIDUS' and  TBL_NM = 'CS_MdltCell' and  COMPLTN_STAT = 'N');


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
select 'CALLIDUS','CS_MdltCell',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."CS_MdltCell") ,(select count(*) from swt_rpt_base.CS_MdltCell where SWT_INS_DT::date = sysdate::date),'Y';

COMMIT;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.CS_MdltCell_Hist SELECT * FROM swt_rpt_stg.CS_MdltCell;

COMMIT;

SELECT PURGE_TABLE('swt_rpt_stg.CS_MdltCell_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.CS_MdltCell');
TRUNCATE TABLE swt_rpt_stg.CS_MdltCell;

