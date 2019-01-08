/****
****Script Name   : Trnc_CS_Position.sql
****Description   : Full data load for CS_Position 
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
  select 'CALLIDUS','CS_Position',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."CS_Position") ,null,'N';

  Commit;  


TRUNCATE TABLE "swt_rpt_base".CS_Position ;


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from swt_rpt_stg.CS_Position_Hist  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".CS_Position 
(
		 RULEELEMENTOWNERSEQ
		,EFFECTIVESTARTDATE
		,EFFECTIVEENDDATE
		,ISLAST
		,CREATEDATE
		,REMOVEDATE
		,PAYEESEQ
		,MANAGERSEQ
		,TITLESEQ
		,POSITIONGROUPSEQ
		,NAME
		,TARGETCOMPENSATION
		,UNITTYPEFORTARGETCOMPENSATION
		,GENERICATTRIBUTE1
		,GENERICATTRIBUTE2
		,GENERICATTRIBUTE3
		,GENERICATTRIBUTE4
		,GENERICATTRIBUTE5
		,GENERICATTRIBUTE6
		,GENERICATTRIBUTE7
		,GENERICATTRIBUTE8
		,GENERICATTRIBUTE9
		,GENERICATTRIBUTE10
		,GENERICATTRIBUTE11
		,GENERICATTRIBUTE12
		,GENERICATTRIBUTE13
		,GENERICATTRIBUTE14
		,GENERICATTRIBUTE15
		,GENERICATTRIBUTE16
		,GENERICNUMBER1
		,UNITTYPEFORGENERICNUMBER1
		,GENERICNUMBER2
		,UNITTYPEFORGENERICNUMBER2
		,GENERICNUMBER3
		,UNITTYPEFORGENERICNUMBER3
		,GENERICNUMBER4
		,UNITTYPEFORGENERICNUMBER4
		,GENERICNUMBER5
		,UNITTYPEFORGENERICNUMBER5
		,GENERICNUMBER6
		,UNITTYPEFORGENERICNUMBER6
		,GENERICDATE1
		,GENERICDATE2
		,GENERICDATE3
		,GENERICDATE4
		,GENERICDATE5
		,GENERICDATE6
		,GENERICBOOLEAN1
		,GENERICBOOLEAN2
		,GENERICBOOLEAN3
		,GENERICBOOLEAN4
		,GENERICBOOLEAN5
		,GENERICBOOLEAN6
		,CREDITSTARTDATE
		,CREDITENDDATE
		,PROCESSINGSTARTDATE
		,PROCESSINGENDDATE
		,PROCESSINGUNITSEQ
		,SWT_INS_DT
)
SELECT DISTINCT
	
		RULEELEMENTOWNERSEQ
		,EFFECTIVESTARTDATE
		,EFFECTIVEENDDATE
		,ISLAST
		,CREATEDATE
		,REMOVEDATE
		,PAYEESEQ
		,MANAGERSEQ
		,TITLESEQ
		,POSITIONGROUPSEQ
		,NAME
		,TARGETCOMPENSATION
		,UNITTYPEFORTARGETCOMPENSATION
		,GENERICATTRIBUTE1
		,GENERICATTRIBUTE2
		,GENERICATTRIBUTE3
		,GENERICATTRIBUTE4
		,GENERICATTRIBUTE5
		,GENERICATTRIBUTE6
		,GENERICATTRIBUTE7
		,GENERICATTRIBUTE8
		,GENERICATTRIBUTE9
		,GENERICATTRIBUTE10
		,GENERICATTRIBUTE11
		,GENERICATTRIBUTE12
		,GENERICATTRIBUTE13
		,GENERICATTRIBUTE14
		,GENERICATTRIBUTE15
		,GENERICATTRIBUTE16
		,GENERICNUMBER1
		,UNITTYPEFORGENERICNUMBER1
		,GENERICNUMBER2
		,UNITTYPEFORGENERICNUMBER2
		,GENERICNUMBER3
		,UNITTYPEFORGENERICNUMBER3
		,GENERICNUMBER4
		,UNITTYPEFORGENERICNUMBER4
		,GENERICNUMBER5
		,UNITTYPEFORGENERICNUMBER5
		,GENERICNUMBER6
		,UNITTYPEFORGENERICNUMBER6
		,GENERICDATE1
		,GENERICDATE2
		,GENERICDATE3
		,GENERICDATE4
		,GENERICDATE5
		,GENERICDATE6
		,GENERICBOOLEAN1
		,GENERICBOOLEAN2
		,GENERICBOOLEAN3
		,GENERICBOOLEAN4
		,GENERICBOOLEAN5
		,GENERICBOOLEAN6
		,CREDITSTARTDATE
		,CREDITENDDATE
		,PROCESSINGSTARTDATE
		,PROCESSINGENDDATE
		,PROCESSINGUNITSEQ
		,SYSDATE
FROM "swt_rpt_stg".CS_Position ;


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'CALLIDUS' and
TBL_NM = 'CS_Position' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'CALLIDUS' and  TBL_NM = 'CS_Position' and  COMPLTN_STAT = 'N');


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
select 'CALLIDUS','CS_Position',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."CS_Position") ,(select count(*) from swt_rpt_base.CS_Position where SWT_INS_DT::date = sysdate::date),'Y';

COMMIT;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.CS_Position_Hist SELECT * FROM swt_rpt_stg.CS_Position;

COMMIT;

TRUNCATE TABLE swt_rpt_stg.CS_Position;
SELECT PURGE_TABLE('swt_rpt_stg.CS_Position_Hist');
select ANALYZE_STATISTICS('swt_rpt_base.CS_Position');
	
