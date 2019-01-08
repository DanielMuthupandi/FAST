/****
****Script Name   : CS_Category_Classifiers.sql
****Description   : Incremental  data load for CS_Category_Classifiers
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
select 'CALLIDUS','CS_Category_Classifiers',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."CS_Category_Classifiers") ,null,'N';

Commit;

CREATE LOCAL TEMP TABLE CS_Category_Classifiers_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.CS_Category_Classifiers)
SEGMENTED BY HASH(categoryclassifiersseq,effectivestartdate) ALL NODES;


CREATE LOCAL TEMP TABLE CS_Category_Classifiers_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT categoryclassifiersseq,effectivestartdate FROM swt_rpt_base.CS_Category_Classifiers)
SEGMENTED BY HASH(categoryclassifiersseq,effectivestartdate) ALL NODES;

/* Inserting Stage table data into Historical Table */

INSERT /*+DIRECT*/ INTO "swt_rpt_stg"."CS_Category_Classifiers_Hist"
(
CATEGORYCLASSIFIERSSEQ
,CATEGORYSEQ
,CLASSIFIERSEQ
,CATEGORYTREESEQ
,EFFECTIVESTARTDATE
,EFFECTIVEENDDATE
,ISLAST
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,LD_DT
,SWT_INS_DT
,d_source
)
SELECT DISTINCT
CATEGORYCLASSIFIERSSEQ
,CATEGORYSEQ
,CLASSIFIERSEQ
,CATEGORYTREESEQ
,EFFECTIVESTARTDATE
,EFFECTIVEENDDATE
,ISLAST
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".CS_Category_Classifiers 
where exists(select 1 from CS_Category_Classifiers_stg_Tmp where CS_Category_Classifiers.categoryclassifiersseq=CS_Category_Classifiers_stg_Tmp.categoryclassifiersseq
and CS_Category_Classifiers.effectivestartdate=CS_Category_Classifiers_stg_Tmp.effectivestartdate );



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."CS_Category_Classifiers_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base"."CS_Category_Classifiers" where exists(select 1 from CS_Category_Classifiers_stg_Tmp where CS_Category_Classifiers.categoryclassifiersseq=CS_Category_Classifiers_stg_Tmp.categoryclassifiersseq
and CS_Category_Classifiers.effectivestartdate=CS_Category_Classifiers_stg_Tmp.effectivestartdate );

INSERT /*+DIRECT*/ INTO "swt_rpt_base".CS_Category_Classifiers
(
CATEGORYCLASSIFIERSSEQ
,CATEGORYSEQ
,CLASSIFIERSEQ
,CATEGORYTREESEQ
,EFFECTIVESTARTDATE
,EFFECTIVEENDDATE
,ISLAST
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,SWT_INS_DT
)
SELECT DISTINCT
CATEGORYCLASSIFIERSSEQ
,CATEGORYSEQ
,CLASSIFIERSEQ
,CATEGORYTREESEQ
,EFFECTIVESTARTDATE
,EFFECTIVEENDDATE
,ISLAST
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,SYSDATE
FROM CS_Category_Classifiers_stg_Tmp
where Not exists(select 1 from "swt_rpt_base".CS_Category_Classifiers where CS_Category_Classifiers.categoryclassifiersseq=CS_Category_Classifiers_stg_Tmp.categoryclassifiersseq
and CS_Category_Classifiers.effectivestartdate=CS_Category_Classifiers_stg_Tmp.effectivestartdate )
and RemoveDate = '2200-01-01';

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'CALLIDUS' and
TBL_NM = 'CS_Category_Classifiers' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'CALLIDUS' and  TBL_NM = 'CS_Category_Classifiers' and  COMPLTN_STAT = 'N');


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
select 'CALLIDUS','CS_Category_Classifiers',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."CS_Category_Classifiers") ,(select count(*) from swt_rpt_base.CS_Category_Classifiers where SWT_INS_DT::date = sysdate::date),'Y';

COMMIT;

INSERT /*+Direct*/ INTO swt_rpt_stg.CS_Category_Classifiers_Hist SELECT * from swt_rpt_stg.CS_Category_Classifiers;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.CS_Category_Classifiers;


select do_tm_task('mergeout','swt_rpt_stg.CS_Category_Classifiers_Hist');
select do_tm_task('mergeout','swt_rpt_base.CS_Category_Classifiers');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.CS_Category_Classifiers');

