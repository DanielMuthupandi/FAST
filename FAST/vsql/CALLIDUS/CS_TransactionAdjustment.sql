
/****
****Script Name   : CS_TransactionAdjustment.sql
****Description   : Incremental  data load for CS_TransactionAdjustment
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
select 'CALLIDUS','CS_TransactionAdjustment',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."CS_TransactionAdjustment") ,null,'N';

Commit;

CREATE LOCAL TEMP TABLE CS_TransactionAdjustment_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.CS_TransactionAdjustment)
SEGMENTED BY HASH(SALESTRANSACTIONSEQ) ALL NODES;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg"."CS_TransactionAdjustment_Hist"
(
TRANSACTIONADJUSTMENTSEQ
,SALESTRANSACTIONSEQ
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,SALESORDERSEQ
,LINENUMBER
,SUBLINENUMBER
,EVENTTYPESEQ
,ORIGINTYPEID
,COMPENSATIONDATE
,BILLTOADDRESSSEQ
,SHIPTOADDRESSSEQ
,OTHERTOADDRESSSEQ
,ISRUNNABLE
,BUSINESSUNITMAP
,ACCOUNTINGDATE
,PRODUCTID
,PRODUCTNAME
,PRODUCTDESCRIPTION
,NUMBEROFUNITS
,UNITVALUE
,UNITTYPEFORUNITVALUE
,ADJUSTBYVALUE
,UNITTYPEFORADJUSTBYVALUE
,TOTALADJUSTVALUE
,UNITTYPEFORTOTALADJUSTVALUE
,ADJUSTTYPEFLAG
,MODIFICATIONMAP
,NATIVECURRENCY
,NATIVECURRENCYAMOUNT
,DISCOUNTPERCENT
,DISCOUNTTYPE
,PAYMENTTERMS
,PONUMBER
,CHANNEL
,ALTERNATEORDERNUMBER
,DATASOURCE
,REASONSEQ
,COMMENTS
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
,GENERICATTRIBUTE17
,GENERICATTRIBUTE18
,GENERICATTRIBUTE19
,GENERICATTRIBUTE20
,GENERICATTRIBUTE21
,GENERICATTRIBUTE22
,GENERICATTRIBUTE23
,GENERICATTRIBUTE24
,GENERICATTRIBUTE25
,GENERICATTRIBUTE26
,GENERICATTRIBUTE27
,GENERICATTRIBUTE28
,GENERICATTRIBUTE29
,GENERICATTRIBUTE30
,GENERICATTRIBUTE31
,GENERICATTRIBUTE32
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
,PROCESSINGUNITSEQ
,UNITTYPEFORLINENUMBER
,UNITTYPEFORSUBLINENUMBER
,UNITTYPEFORNUMBEROFUNITS
,UNITTYPEFORDISCOUNTPERCENT
,UNITTYPEFORNATIVECURRENCYAMT
,LD_DT
,SWT_INS_DT
,d_source
)
SELECT DISTINCT
TRANSACTIONADJUSTMENTSEQ
,SALESTRANSACTIONSEQ
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,SALESORDERSEQ
,LINENUMBER
,SUBLINENUMBER
,EVENTTYPESEQ
,ORIGINTYPEID
,COMPENSATIONDATE
,BILLTOADDRESSSEQ
,SHIPTOADDRESSSEQ
,OTHERTOADDRESSSEQ
,ISRUNNABLE
,BUSINESSUNITMAP
,ACCOUNTINGDATE
,PRODUCTID
,PRODUCTNAME
,PRODUCTDESCRIPTION
,NUMBEROFUNITS
,UNITVALUE
,UNITTYPEFORUNITVALUE
,ADJUSTBYVALUE
,UNITTYPEFORADJUSTBYVALUE
,TOTALADJUSTVALUE
,UNITTYPEFORTOTALADJUSTVALUE
,ADJUSTTYPEFLAG
,MODIFICATIONMAP
,NATIVECURRENCY
,NATIVECURRENCYAMOUNT
,DISCOUNTPERCENT
,DISCOUNTTYPE
,PAYMENTTERMS
,PONUMBER
,CHANNEL
,ALTERNATEORDERNUMBER
,DATASOURCE
,REASONSEQ
,COMMENTS
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
,GENERICATTRIBUTE17
,GENERICATTRIBUTE18
,GENERICATTRIBUTE19
,GENERICATTRIBUTE20
,GENERICATTRIBUTE21
,GENERICATTRIBUTE22
,GENERICATTRIBUTE23
,GENERICATTRIBUTE24
,GENERICATTRIBUTE25
,GENERICATTRIBUTE26
,GENERICATTRIBUTE27
,GENERICATTRIBUTE28
,GENERICATTRIBUTE29
,GENERICATTRIBUTE30
,GENERICATTRIBUTE31
,GENERICATTRIBUTE32
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
,PROCESSINGUNITSEQ
,UNITTYPEFORLINENUMBER
,UNITTYPEFORSUBLINENUMBER
,UNITTYPEFORNUMBEROFUNITS
,UNITTYPEFORDISCOUNTPERCENT
,UNITTYPEFORNATIVECURRENCYAMT
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base"."CS_TransactionAdjustment" WHERE SALESTRANSACTIONSEQ IN (SELECT SALESTRANSACTIONSEQ FROM CS_TransactionAdjustment_stg_Tmp);

DELETE /*+DIRECT*/ from "swt_rpt_stg"."CS_TransactionAdjustment_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

DELETE /*+DIRECT*/ FROM "swt_rpt_base"."CS_TransactionAdjustment" WHERE SALESTRANSACTIONSEQ IN (SELECT SALESTRANSACTIONSEQ FROM CS_TransactionAdjustment_stg_Tmp);

INSERT /*+DIRECT*/ INTO "swt_rpt_base"."CS_TransactionAdjustment"
(
TRANSACTIONADJUSTMENTSEQ
,SALESTRANSACTIONSEQ
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,SALESORDERSEQ
,LINENUMBER
,SUBLINENUMBER
,EVENTTYPESEQ
,ORIGINTYPEID
,COMPENSATIONDATE
,BILLTOADDRESSSEQ
,SHIPTOADDRESSSEQ
,OTHERTOADDRESSSEQ
,ISRUNNABLE
,BUSINESSUNITMAP
,ACCOUNTINGDATE
,PRODUCTID
,PRODUCTNAME
,PRODUCTDESCRIPTION
,NUMBEROFUNITS
,UNITVALUE
,UNITTYPEFORUNITVALUE
,ADJUSTBYVALUE
,UNITTYPEFORADJUSTBYVALUE
,TOTALADJUSTVALUE
,UNITTYPEFORTOTALADJUSTVALUE
,ADJUSTTYPEFLAG
,MODIFICATIONMAP
,NATIVECURRENCY
,NATIVECURRENCYAMOUNT
,DISCOUNTPERCENT
,DISCOUNTTYPE
,PAYMENTTERMS
,PONUMBER
,CHANNEL
,ALTERNATEORDERNUMBER
,DATASOURCE
,REASONSEQ
,COMMENTS
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
,GENERICATTRIBUTE17
,GENERICATTRIBUTE18
,GENERICATTRIBUTE19
,GENERICATTRIBUTE20
,GENERICATTRIBUTE21
,GENERICATTRIBUTE22
,GENERICATTRIBUTE23
,GENERICATTRIBUTE24
,GENERICATTRIBUTE25
,GENERICATTRIBUTE26
,GENERICATTRIBUTE27
,GENERICATTRIBUTE28
,GENERICATTRIBUTE29
,GENERICATTRIBUTE30
,GENERICATTRIBUTE31
,GENERICATTRIBUTE32
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
,PROCESSINGUNITSEQ
,UNITTYPEFORLINENUMBER
,UNITTYPEFORSUBLINENUMBER
,UNITTYPEFORNUMBEROFUNITS
,UNITTYPEFORDISCOUNTPERCENT
,UNITTYPEFORNATIVECURRENCYAMT
,SWT_INS_DT
)
SELECT DISTINCT
TRANSACTIONADJUSTMENTSEQ
,SALESTRANSACTIONSEQ
,CREATEDATE
,REMOVEDATE
,CREATEDBY
,MODIFIEDBY
,SALESORDERSEQ
,LINENUMBER
,SUBLINENUMBER
,EVENTTYPESEQ
,ORIGINTYPEID
,COMPENSATIONDATE
,BILLTOADDRESSSEQ
,SHIPTOADDRESSSEQ
,OTHERTOADDRESSSEQ
,ISRUNNABLE
,BUSINESSUNITMAP
,ACCOUNTINGDATE
,PRODUCTID
,PRODUCTNAME
,PRODUCTDESCRIPTION
,NUMBEROFUNITS
,UNITVALUE
,UNITTYPEFORUNITVALUE
,ADJUSTBYVALUE
,UNITTYPEFORADJUSTBYVALUE
,TOTALADJUSTVALUE
,UNITTYPEFORTOTALADJUSTVALUE
,ADJUSTTYPEFLAG
,MODIFICATIONMAP
,NATIVECURRENCY
,NATIVECURRENCYAMOUNT
,DISCOUNTPERCENT
,DISCOUNTTYPE
,PAYMENTTERMS
,PONUMBER
,CHANNEL
,ALTERNATEORDERNUMBER
,DATASOURCE
,REASONSEQ
,COMMENTS
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
,GENERICATTRIBUTE17
,GENERICATTRIBUTE18
,GENERICATTRIBUTE19
,GENERICATTRIBUTE20
,GENERICATTRIBUTE21
,GENERICATTRIBUTE22
,GENERICATTRIBUTE23
,GENERICATTRIBUTE24
,GENERICATTRIBUTE25
,GENERICATTRIBUTE26
,GENERICATTRIBUTE27
,GENERICATTRIBUTE28
,GENERICATTRIBUTE29
,GENERICATTRIBUTE30
,GENERICATTRIBUTE31
,GENERICATTRIBUTE32
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
,PROCESSINGUNITSEQ
,UNITTYPEFORLINENUMBER
,UNITTYPEFORSUBLINENUMBER
,UNITTYPEFORNUMBEROFUNITS
,UNITTYPEFORDISCOUNTPERCENT
,UNITTYPEFORNATIVECURRENCYAMT
,SYSDATE AS SWT_INS_DT
FROM CS_TransactionAdjustment_stg_Tmp;


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'CALLIDUS' and
TBL_NM = 'CS_TransactionAdjustment' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'CALLIDUS' and  TBL_NM = 'CS_TransactionAdjustment' and  COMPLTN_STAT = 'N');


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
select 'CALLIDUS','CS_TransactionAdjustment',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."CS_TransactionAdjustment") ,(select count(*) from swt_rpt_base.CS_TransactionAdjustment where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


SELECT PURGE_TABLE('swt_rpt_base.CS_TransactionAdjustment');
SELECT PURGE_TABLE('swt_rpt_stg.CS_TransactionAdjustment_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.CS_TransactionAdjustment');
INSERT /*+Direct*/ INTO swt_rpt_stg.CS_TransactionAdjustment_Hist SELECT * from swt_rpt_stg.CS_TransactionAdjustment;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.CS_TransactionAdjustment;