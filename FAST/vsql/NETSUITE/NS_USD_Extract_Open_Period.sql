/****
****Script Name	  : NS_USD_Extract_Open_Period.sql
****Description   : Incremental data load for NS_Transaction_lines_USD_Extract using Open Period data
****/

/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_USD_Extract_Open_Period";

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
select 'NETSUITE','NS_USD_Extract_Open_Period',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;


CREATE LOCAL TEMP TABLE NS_USD_Extract_Open_Period_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_USD_Extract_Open_Period)
SEGMENTED BY HASH(Period_internalid) ALL NODES;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_USD_Extract_Open_Period_Hist SELECT * from "swt_rpt_stg".NS_USD_Extract_Open_Period;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NS_USD_Extract_Open_Period;

CREATE LOCAL TEMP TABLE NS_USD_Extract_Open_Period_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Period_internalid FROM swt_rpt_base.NS_Transaction_lines_USD_Extract)
SEGMENTED BY HASH(Period_internalid) ALL NODES;




/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_USD_Extract_Open_Period_Hist
(
General_Ledger_Account_Code
,GL_Group_Account_Code
,Account_name
,USD_Amount
,Amount_credit
,Amount_debit
,Amount_foreign_currency
,Currency
,Currency_code
,Period_Name
,Period_internalid
,Fiscal_qtr_yr
,Transaction_Type_Desc
,Finance_Owner
,Cost_Pool_ID
,Cost_Pool_Description
,Subsidiary_country
,Subsidiary_code
,Account_Type
,Report_time_stamp
,Transaction_internalid
,Transaction_lineid
,MRU_InternalID
,MRU_ExternalID
,MRU_Description
,Profit_Center_InternalID
,Profit_Center_ExternalID
,Profit_Center_Description
,BA_InternalID
,BA_ExternalID
,BA_Description
,FA_ExternalID
,FA_Description
,FA_InternalID
,Internal_ID
,LD_DT
,SWT_INS_DT
,d_source
)
SELECT DISTINCT 
General_Ledger_Account_Code
,GL_Group_Account_Code
,Account_name
,USD_Amount
,Amount_credit
,Amount_debit
,Amount_foreign_currency
,Currency
,Currency_code
,Period_Name
,Period_internalid
,Fiscal_qtr_yr
,Transaction_Type_Desc
,Finance_Owner
,Cost_Pool_ID
,Cost_Pool_Description
,Subsidiary_country
,Subsidiary_code
,Account_Type
,Report_time_stamp
,Transaction_internalid
,Transaction_lineid
,MRU_InternalID
,MRU_ExternalID
,MRU_Description
,Profit_Center_InternalID
,Profit_Center_ExternalID
,Profit_Center_Description
,BA_InternalID
,BA_ExternalID
,BA_Description
,FA_ExternalID
,FA_Description
,FA_InternalID
,Internal_ID
,SYSDATE AS LD_DT
,SWT_INS_DT 
,'base'
FROM "swt_rpt_base".NS_Transaction_lines_USD_Extract WHERE Period_internalid in
(SELECT STG.Period_internalid FROM NS_USD_Extract_Open_Period_stg_Tmp STG);




/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_USD_Extract_Open_Period_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Transaction_lines_USD_Extract WHERE Period_internalid in
(SELECT STG.Period_internalid FROM NS_USD_Extract_Open_Period_stg_Tmp STG);


/* Incremental VSQL script for loading data from Stage to Base */

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Transaction_lines_USD_Extract
(
General_Ledger_Account_Code
,GL_Group_Account_Code
,Account_name
,USD_Amount
,Amount_credit
,Amount_debit
,Amount_foreign_currency
,Currency
,Currency_code
,Period_Name
,Period_internalid
,Fiscal_qtr_yr
,Transaction_Type_Desc
,Finance_Owner
,Cost_Pool_ID
,Cost_Pool_Description
,Subsidiary_country
,Subsidiary_code
,Account_Type
,Report_time_stamp
,Transaction_internalid
,Transaction_lineid
,MRU_InternalID
,MRU_ExternalID
,MRU_Description
,Profit_Center_InternalID
,Profit_Center_ExternalID
,Profit_Center_Description
,BA_InternalID
,BA_ExternalID
,BA_Description
,FA_ExternalID
,FA_Description
,FA_InternalID
,Internal_ID
,SWT_INS_DT
)
SELECT
DISTINCT
General_Ledger_Account_Code
,GL_Group_Account_Code
,Account_name
,USD_Amount
,Amount_credit
,Amount_debit
,Amount_foreign_currency
,Currency
,Currency_code
,Period_Name
,Period_internalid
,Fiscal_qtr_yr
,Transaction_Type_Desc
,Finance_Owner
,Cost_Pool_ID
,Cost_Pool_Description
,Subsidiary_country
,Subsidiary_code
,Account_Type
,Report_time_stamp
,Transaction_internalid
,Transaction_lineid
,MRU_InternalID
,MRU_ExternalID
,MRU_Description
,Profit_Center_InternalID
,Profit_Center_ExternalID
,Profit_Center_Description
,BA_InternalID
,BA_ExternalID
,BA_Description
,FA_ExternalID
,FA_Description
,FA_InternalID
,Internal_ID
,SYSDATE
FROM NS_USD_Extract_Open_Period_stg_Tmp;


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_USD_Extract_Open_Period' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_USD_Extract_Open_Period' and  COMPLTN_STAT = 'N');


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
select 'NETSUITE','NS_USD_Extract_Open_Period',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Transaction_lines_USD_Extract where SWT_INS_DT::date = sysdate::date),'Y';


Commit;
SELECT PURGE_TABLE('swt_rpt_base.NS_Transaction_lines_USD_Extract');
SELECT PURGE_TABLE('swt_rpt_stg.NS_USD_Extract_Open_Period_Hist');
select ANALYZE_STATISTICS('swt_rpt_base.NS_Transaction_lines_USD_Extract');


