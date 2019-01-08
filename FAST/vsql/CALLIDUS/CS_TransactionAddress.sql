/****
****Script Name   : CS_TransactionAddress.sql
****Description   : Incremental  data load for CS_TransactionAddress
****/

/* Setting timing on**/
\timing

/* SET SESSION AUTOCOMMIT TO OFF; */

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select sysdate st from dual;

\set ON_ERROR_STOP on

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
select 'CALLIDUS','CS_TransactionAddress',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."CS_TransactionAddress") ,null,'N';

Commit;

CREATE LOCAL TEMP TABLE CS_TransactionAddress_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.CS_TransactionAddress)
SEGMENTED BY HASH(SALESTRANSACTIONSEQ) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.CS_TransactionAddress_Hist
(
TRANSACTIONADDRESSSEQ
,SALESTRANSACTIONSEQ
,ADDRESSTYPESEQ
,CUSTID
,CONTACT
,COMPANY
,AREACODE
,PHONE
,FAX
,ADDRESS1
,ADDRESS2
,ADDRESS3
,CITY
,STATE
,COUNTRY
,POSTALCODE
,INDUSTRY
,GEOGRAPHY
,LD_DT
,SWT_INS_DT
,d_source
)
select
TRANSACTIONADDRESSSEQ
,SALESTRANSACTIONSEQ
,ADDRESSTYPESEQ
,CUSTID
,CONTACT
,COMPANY
,AREACODE
,PHONE
,FAX
,ADDRESS1
,ADDRESS2
,ADDRESS3
,CITY
,STATE
,COUNTRY
,POSTALCODE
,INDUSTRY
,GEOGRAPHY
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".CS_TransactionAddress WHERE SALESTRANSACTIONSEQ IN
(
SELECT DISTINCT  SALESTRANSACTIONSEQ from "swt_rpt_base".CS_SALESTRANSACTION
WHERE COMPENSATIONDATE >= (SELECT MIN(StartDate) from "swt_rpt_stg".CS_PERIOD WHERE PERIODSEQ IN (SELECT DISTINCT PERIODSEQ from "swt_rpt_stg".CS_CREDIT))
AND COMPENSATIONDATE <= (SELECT  MAX(EndDate)-1 from "swt_rpt_stg".CS_PERIOD WHERE PERIODSEQ IN (SELECT DISTINCT PERIODSEQ from "swt_rpt_stg".CS_CREDIT))
);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."CS_TransactionAddress_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */


DELETE /*+DIRECT*/ FROM "swt_rpt_base".CS_TransactionAddress
WHERE SALESTRANSACTIONSEQ IN
(
SELECT DISTINCT  SALESTRANSACTIONSEQ from "swt_rpt_base".CS_SALESTRANSACTION
WHERE COMPENSATIONDATE >= (SELECT MIN(StartDate) from "swt_rpt_stg".CS_PERIOD WHERE PERIODSEQ IN (SELECT DISTINCT PERIODSEQ from "swt_rpt_stg".CS_CREDIT))
AND COMPENSATIONDATE <= (SELECT  MAX(EndDate)-1 from "swt_rpt_stg".CS_PERIOD WHERE PERIODSEQ IN (SELECT DISTINCT PERIODSEQ from "swt_rpt_stg".CS_CREDIT))
);

INSERT /*+DIRECT*/ INTO "swt_rpt_base"."CS_TransactionAddress"
(
TRANSACTIONADDRESSSEQ
,SALESTRANSACTIONSEQ
,ADDRESSTYPESEQ
,CUSTID
,CONTACT
,COMPANY
,AREACODE
,PHONE
,FAX
,ADDRESS1
,ADDRESS2
,ADDRESS3
,CITY
,STATE
,COUNTRY
,POSTALCODE
,INDUSTRY
,GEOGRAPHY
,SWT_INS_DT
)
SELECT DISTINCT
TRANSACTIONADDRESSSEQ
,SALESTRANSACTIONSEQ
,ADDRESSTYPESEQ
,CUSTID
,CONTACT
,COMPANY
,AREACODE
,PHONE
,FAX
,ADDRESS1
,ADDRESS2
,ADDRESS3
,CITY
,STATE
,COUNTRY
,POSTALCODE
,INDUSTRY
,GEOGRAPHY
,SYSDATE as SWT_INS_DT
FROM CS_TransactionAddress_stg_Tmp;



/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'CALLIDUS' and
TBL_NM = 'CS_TransactionAddress' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'CALLIDUS' and  TBL_NM = 'CS_TransactionAddress' and  COMPLTN_STAT = 'N');


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
select 'CALLIDUS','CS_TransactionAddress',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."CS_TransactionAddress") ,(select count(*) from swt_rpt_base.CS_TransactionAddress where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


SELECT PURGE_TABLE('swt_rpt_base.CS_TransactionAddress');
SELECT PURGE_TABLE('swt_rpt_stg.CS_TransactionAddress_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.CS_TransactionAddress');
INSERT /*+Direct*/ INTO swt_rpt_stg.CS_TransactionAddress_Hist SELECT * from swt_rpt_stg.CS_TransactionAddress;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.CS_TransactionAddress;
