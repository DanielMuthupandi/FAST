/****Script Name   : SF_SWT_Payment_Status__c.sql
****Description   : Truncate and data load for SF_SWT_Payment_Status__c
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
select 'SFDC','SF_SWT_Payment_Status__c',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."SF_SWT_Payment_Status__c") ,null,'N';

Commit;


 
 /* Full load VSQL script for loading data from Stage to Base */ 
 
TRUNCATE TABLE "swt_rpt_base".SF_SWT_Payment_Status__c;
 
 /* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."SF_SWT_Payment_Status__c_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_SWT_Payment_Status__c
(
CreatedById
,CreatedDate
,CurrencyIsoCode
,Id
,IsDeleted
,LastModifiedById
,LastModifiedDate
,LastReferencedDate
,LastViewedDate
,Name
,OwnerId
,SWT_Account__c
,SWT_Bank_Country__c
,SWT_Batch_Sharing_executed__c
,SWT_Claim_ID__c
,SWT_Deal_Registration__c
,SWT_Last_Status_Modified_Date__c
,SWT_MDF_Claim_ID__c
,SWT_MF_Entity_Issuing_Payment__c
,SWT_Net_Claim_Value__c
,SWT_Partner_Recipient_Bank_Name__c
,SWT_Payment_Description__c
,SWT_Payment_Status__c
,SWT_Tax_Value__c
,SWT_Total_Payment_Value__c
,SWT_Type_of_Benefit__c
,SystemModstamp
,SWT_INS_DT
)
SELECT DISTINCT
CreatedById
,CreatedDate
,CurrencyIsoCode
,Id
,IsDeleted
,LastModifiedById
,LastModifiedDate
,LastReferencedDate
,LastViewedDate
,Name
,OwnerId
,SWT_Account__c
,SWT_Bank_Country__c
,SWT_Batch_Sharing_executed__c
,SWT_Claim_ID__c
,SWT_Deal_Registration__c
,SWT_Last_Status_Modified_Date__c
,SWT_MDF_Claim_ID__c
,SWT_MF_Entity_Issuing_Payment__c
,SWT_Net_Claim_Value__c
,SWT_Partner_Recipient_Bank_Name__c
,SWT_Payment_Description__c
,SWT_Payment_Status__c
,SWT_Tax_Value__c
,SWT_Total_Payment_Value__c
,SWT_Type_of_Benefit__c
,SystemModstamp
,SYSDATE AS SWT_INS_DT
 FROM "swt_rpt_stg"."SF_SWT_Payment_Status__c";

/* Deleting partial audit entry */

/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_SWT_Payment_Status__c' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_SWT_Payment_Status__c' and  COMPLTN_STAT = 'N');
*/

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
select 'SFDC','SF_SWT_Payment_Status__c',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."SF_SWT_Payment_Status__c") ,(select count(*) from swt_rpt_base.SF_SWT_Payment_Status__c where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.SF_SWT_Payment_Status__c_Hist SELECT * FROM swt_rpt_stg.SF_SWT_Payment_Status__c;

COMMIT;

TRUNCATE TABLE swt_rpt_stg.SF_SWT_Payment_Status__c;

SELECT PURGE_TABLE('swt_rpt_base.SF_SWT_Payment_Status__c');
SELECT PURGE_TABLE('swt_rpt_stg.SF_SWT_Payment_Status__c_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.SF_SWT_Payment_Status__c');



