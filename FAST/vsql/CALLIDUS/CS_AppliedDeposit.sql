/****
****Script Name   : CS_AppliedDeposit.sql
****Description   : Incremental  data load for CS_AppliedDeposit
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
select 'CALLIDUS','CS_AppliedDeposit',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."CS_AppliedDeposit") ,null,'N';

Commit;

CREATE LOCAL TEMP TABLE CS_AppliedDeposit_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.CS_AppliedDeposit)
SEGMENTED BY HASH(PERIODSEQ) ALL NODES;


INSERT /*+DIRECT*/ INTO "swt_rpt_stg"."CS_AppliedDeposit_Hist"
(
APPLIEDDEPOSITSEQ
,PAYEESEQ
,POSITIONSEQ
,PERIODSEQ
,ENTRYNUMBER
,EARNINGGROUPID
,EARNINGCODEID
,TRIALPIPELINERUNSEQ
,TRIALPIPELINERUNDATE
,POSTPIPELINERUNSEQ
,POSTPIPELINERUNDATE
,BUSINESSUNITMAP
,VALUE
,UNITTYPEFORVALUE
,PROCESSINGUNITSEQ
,LD_DT
,SWT_INS_DT
,d_source
)
SELECT DISTINCT
APPLIEDDEPOSITSEQ
,PAYEESEQ
,POSITIONSEQ
,PERIODSEQ
,ENTRYNUMBER
,EARNINGGROUPID
,EARNINGCODEID
,TRIALPIPELINERUNSEQ
,TRIALPIPELINERUNDATE
,POSTPIPELINERUNSEQ
,POSTPIPELINERUNDATE
,BUSINESSUNITMAP
,VALUE
,UNITTYPEFORVALUE
,PROCESSINGUNITSEQ
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base"."CS_AppliedDeposit" WHERE PERIODSEQ IN (SELECT PERIODSEQ FROM CS_AppliedDeposit_stg_Tmp);


delete /*+DIRECT*/ from "swt_rpt_stg"."CS_AppliedDeposit_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


DELETE /*+DIRECT*/ FROM "swt_rpt_base"."CS_AppliedDeposit" WHERE PERIODSEQ IN (SELECT PERIODSEQ FROM CS_AppliedDeposit_stg_Tmp);

INSERT /*+DIRECT*/ INTO "swt_rpt_base"."CS_AppliedDeposit"
(
APPLIEDDEPOSITSEQ
,PAYEESEQ
,POSITIONSEQ
,PERIODSEQ
,ENTRYNUMBER
,EARNINGGROUPID
,EARNINGCODEID
,TRIALPIPELINERUNSEQ
,TRIALPIPELINERUNDATE
,POSTPIPELINERUNSEQ
,POSTPIPELINERUNDATE
,BUSINESSUNITMAP
,VALUE
,UNITTYPEFORVALUE
,PROCESSINGUNITSEQ
,SWT_INS_DT
)
SELECT DISTINCT
APPLIEDDEPOSITSEQ
,PAYEESEQ
,POSITIONSEQ
,PERIODSEQ
,ENTRYNUMBER
,EARNINGGROUPID
,EARNINGCODEID
,TRIALPIPELINERUNSEQ
,TRIALPIPELINERUNDATE
,POSTPIPELINERUNSEQ
,POSTPIPELINERUNDATE
,BUSINESSUNITMAP
,VALUE
,UNITTYPEFORVALUE
,PROCESSINGUNITSEQ
,SYSDATE AS SWT_INS_DT
FROM CS_AppliedDeposit_stg_Tmp;

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'CALLIDUS' and
TBL_NM = 'CS_AppliedDeposit' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'CALLIDUS' and  TBL_NM = 'CS_AppliedDeposit' and  COMPLTN_STAT = 'N');


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
select 'CALLIDUS','CS_AppliedDeposit',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."CS_AppliedDeposit") ,(select count(*) from swt_rpt_base.CS_AppliedDeposit where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


INSERT /*+Direct*/ INTO swt_rpt_stg.CS_AppliedDeposit_Hist SELECT * from swt_rpt_stg.CS_AppliedDeposit;
COMMIT;

TRUNCATE TABLE swt_rpt_stg.CS_AppliedDeposit;

select do_tm_task('mergeout','swt_rpt_stg.CS_AppliedDeposit_Hist');
select do_tm_task('mergeout','swt_rpt_base.CS_AppliedDeposit');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.CS_AppliedDeposit');
