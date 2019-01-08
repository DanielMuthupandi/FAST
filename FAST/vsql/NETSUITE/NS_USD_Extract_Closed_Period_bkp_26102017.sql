/****
****Script Name	  : NS_USD_Extract_Closed_Period.sql
****Description   : Incremental data load for NS_Transaction_lines_USD_Extract using Closed Period data
****/

/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

--SET SESSION AUTOCOMMIT TO OFF;


\set ON_ERROR_STOP on
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
select 'NETSUITE','NS_USD_Extract_Closed_Period',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NS_USD_Extract_Closed_Period") ,null,'N';


commit;


CREATE LOCAL TEMP TABLE NS_USD_Extract_Closed_Period_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_USD_Extract_Closed_Period)
SEGMENTED BY HASH(Period_Name) ALL NODES;


CREATE LOCAL TEMP TABLE NS_USD_Extract_Closed_Period_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_base.NS_Transaction_lines_USD_Extract)
SEGMENTED BY HASH(Period_Name) ALL NODES;



/*moving closed period data also to history table (added on 27.07.2017) */
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
FROM NS_USD_Extract_Closed_Period_base_Tmp WHERE Period_Name in
(SELECT STG.Period_Name FROM NS_USD_Extract_Closed_Period_stg_Tmp STG);


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_USD_Extract_Open_Period_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

/*deleting recods of closed period also from base table(added on 27.07.2017)*/
DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Transaction_lines_USD_Extract WHERE Period_Name in
(SELECT STG.Period_Name FROM NS_USD_Extract_Closed_Period_stg_Tmp STG);

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
Distinct
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
FROM
NS_USD_Extract_Closed_Period_stg_Tmp;


/* Updating Audit status Flag and target table Counts */

update swt_rpt_stg.FAST_LD_AUDT set COMPLTN_STAT='Y',END_DT_TIME = sysdate,TGT_REC_CNT = (select count(*) from swt_rpt_base.NS_Transaction_lines_USD_Extract where SWT_INS_DT::date = sysdate::date)
where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_USD_Extract_Closed_Period' and
COMPLTN_STAT = 'N' and
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_USD_Extract_Closed_Period' and  COMPLTN_STAT = 'N');


Commit;

SELECT PURGE_TABLE('swt_rpt_base.NS_Transaction_lines_USD_Extract');
SELECT PURGE_TABLE('swt_rpt_stg.NS_USD_Extract_Open_Period_Hist');
select ANALYZE_STATISTICS('swt_rpt_base.NS_Transaction_lines_USD_Extract');
TRUNCATE TABLE swt_rpt_stg.NS_USD_Extract_Closed_Period;


