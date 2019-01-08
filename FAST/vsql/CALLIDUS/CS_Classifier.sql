/*Script Name   : CS_Classifier.sql
****Description   : Incremental  data load for CS_Classifier
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
select 'CALLIDUS','CS_Classifier',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."CS_Classifier") ,null,'N';

Commit;

CREATE LOCAL TEMP TABLE CS_Classifier_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.CS_Classifier)
SEGMENTED BY HASH(classifierseq,effectivestartdate) ALL NODES;


CREATE LOCAL TEMP TABLE CS_Classifier_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT classifierseq,effectivestartdate FROM swt_rpt_base.CS_Classifier)
SEGMENTED BY HASH(classifierseq,effectivestartdate) ALL NODES;

/* Inserting Stage table data into Historical Table */

INSERT /*+DIRECT*/ INTO "swt_rpt_stg"."CS_Classifier_Hist"
(
CLASSIFIERSEQ
,EFFECTIVESTARTDATE
,EFFECTIVEENDDATE
,ISLAST
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,CLASSIFIERID
,NAME
,SELECTORID
,BUSINESSUNITMAP
,DESCRIPTION
,LD_DT
,SWT_INS_DT
,d_source
)
SELECT DISTINCT
CLASSIFIERSEQ
,EFFECTIVESTARTDATE
,EFFECTIVEENDDATE
,ISLAST
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,CLASSIFIERID
,NAME
,SELECTORID
,BUSINESSUNITMAP
,DESCRIPTION
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".CS_Classifier
where exists(select 1 from CS_Classifier_stg_Tmp where CS_Classifier.classifierseq=CS_Classifier_stg_Tmp.classifierseq
and CS_Classifier.effectivestartdate=CS_Classifier_stg_Tmp.effectivestartdate );



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."CS_Classifier_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base"."CS_Classifier" where exists(select 1 from CS_Classifier_stg_Tmp where CS_Classifier.classifierseq=CS_Classifier_stg_Tmp.classifierseq
and CS_Classifier.effectivestartdate=CS_Classifier_stg_Tmp.effectivestartdate );


INSERT /*+DIRECT*/ INTO "swt_rpt_base".CS_Classifier
(
CLASSIFIERSEQ
,EFFECTIVESTARTDATE
,EFFECTIVEENDDATE
,ISLAST
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,CLASSIFIERID
,NAME
,SELECTORID
,BUSINESSUNITMAP
,DESCRIPTION
,SWT_INS_DT
)
SELECT DISTINCT
CLASSIFIERSEQ
,EFFECTIVESTARTDATE
,EFFECTIVEENDDATE
,ISLAST
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,CLASSIFIERID
,NAME
,SELECTORID
,BUSINESSUNITMAP
,DESCRIPTION
,SYSDATE AS SWT_INS_DT
FROM CS_Classifier_stg_Tmp 
where NOT exists(select 1 from "swt_rpt_base".CS_Classifier where CS_Classifier.classifierseq=CS_Classifier_stg_Tmp.classifierseq
and CS_Classifier.effectivestartdate=CS_Classifier_stg_Tmp.effectivestartdate)
and RemoveDate = '2200-01-01';

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'CALLIDUS' and
TBL_NM = 'CS_Classifier' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'CALLIDUS' and  TBL_NM = 'CS_Classifier' and  COMPLTN_STAT = 'N');


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
select 'CALLIDUS','CS_Classifier',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."CS_Classifier") ,(select count(*) from swt_rpt_base.CS_Classifier where SWT_INS_DT::date = sysdate::date),'Y';

COMMIT;

INSERT /*+Direct*/ INTO swt_rpt_stg.CS_Classifier_Hist SELECT * from swt_rpt_stg.CS_Classifier;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.CS_Classifier;

select do_tm_task('mergeout','swt_rpt_stg.CS_Classifier_Hist');
select do_tm_task('mergeout','swt_rpt_base.CS_Classifier');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.CS_Classifier');

