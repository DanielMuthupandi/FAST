/****
****Script Name	  : NS_Subsidiaries.sql
****Description   : Incremental data load for NS_Subsidiaries
****/
/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/


\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Subsidiaries";

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
select 'NETSUITE','NS_Subsidiaries',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Subsidiaries_Hist SELECT * from "swt_rpt_stg".NS_Subsidiaries;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select subsidiary_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Subsidiaries where subsidiary_id in (
select subsidiary_id from swt_rpt_stg.NS_Subsidiaries group by subsidiary_id,date_last_modified having count(1)>1)
group by subsidiary_id);


delete from swt_rpt_stg.NS_Subsidiaries where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Subsidiaries.subsidiary_id=t2.subsidiary_id and swt_rpt_stg.NS_Subsidiaries.auto_id<t2.auto_id);

commit;


CREATE LOCAL TEMP TABLE NS_Subsidiaries_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Subsidiaries)
SEGMENTED BY HASH(subsidiary_id,date_last_modified) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.NS_Subsidiaries;

CREATE LOCAL TEMP TABLE NS_Subsidiaries_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT subsidiary_id,date_last_modified FROM swt_rpt_base.NS_Subsidiaries)
SEGMENTED BY HASH(subsidiary_id,date_last_modified) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Subsidiaries_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT subsidiary_id, max(date_last_modified) as date_last_modified FROM NS_Subsidiaries_stg_Tmp group by subsidiary_id)
SEGMENTED BY HASH(subsidiary_id,date_last_modified) ALL NODES;



/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Subsidiaries_Hist
(
address
,address1
,address2
,base_currency_id
,branch_id
,city
,country
,date_last_modified
,duns_number
,edition
,federal_number
,fiscal_calendar_id
,full_name
,idt__account_id
,individual_bill_payment
,inquiry_email_address
,inquiry_phone_number
,invoice_printer_address
,invoice_printer_name
,invoice_printer_phone
,invoice_printer_tax_id
,is_elimination
,is_moss
,isinactive
,legal_name
,moss_nexus_id
,name
,onesource_company_id
,parent_id
,payment_terms_link
,purchaseorderamount
,purchaseorderquantity
,purchaseorderquantitydiff
,receiptamount
,receiptquantity
,receiptquantitydiff
,return_address
,return_address1
,return_address2
,return_city
,return_country
,return_state
,return_zipcode
,settlement_type_id
,shipping_address
,shipping_address1
,shipping_address2
,shipping_city
,shipping_country
,shipping_state
,shipping_zipcode
,state
,state_tax_number
,subsidiary_attribute_id
,subsidiary_clearing_bank_acco
,subsidiary_code
,subsidiary_extid
,subsidiary_id
,tran_num_prefix
,url
,disable_country_field
,edocument_country_for_free__id
,edocument_sender_id
,hr_country_id
,payment_purpose_code_ppc_id
,region_id
,state_full_name
,tax_id_rfc_mexico_only
,zipcode
,RECIPIENT_OF_EDOCUMENT_NOTIFI
,LD_DT
,SWT_INS_DT
,d_source
)
select
address
,address1
,address2
,base_currency_id
,branch_id
,city
,country
,date_last_modified
,duns_number
,edition
,federal_number
,fiscal_calendar_id
,full_name
,idt__account_id
,individual_bill_payment
,inquiry_email_address
,inquiry_phone_number
,invoice_printer_address
,invoice_printer_name
,invoice_printer_phone
,invoice_printer_tax_id
,is_elimination
,is_moss
,isinactive
,legal_name
,moss_nexus_id
,name
,onesource_company_id
,parent_id
,payment_terms_link
,purchaseorderamount
,purchaseorderquantity
,purchaseorderquantitydiff
,receiptamount
,receiptquantity
,receiptquantitydiff
,return_address
,return_address1
,return_address2
,return_city
,return_country
,return_state
,return_zipcode
,settlement_type_id
,shipping_address
,shipping_address1
,shipping_address2
,shipping_city
,shipping_country
,shipping_state
,shipping_zipcode
,state
,state_tax_number
,subsidiary_attribute_id
,subsidiary_clearing_bank_acco
,subsidiary_code
,subsidiary_extid
,subsidiary_id
,tran_num_prefix
,url
,disable_country_field
,edocument_country_for_free__id
,edocument_sender_id
,hr_country_id
,payment_purpose_code_ppc_id
,region_id
,state_full_name
,tax_id_rfc_mexico_only
,zipcode
,RECIPIENT_OF_EDOCUMENT_NOTIFI
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Subsidiaries WHERE subsidiary_id in
(SELECT STG.subsidiary_id FROM NS_Subsidiaries_stg_Tmp_Key STG JOIN NS_Subsidiaries_base_Tmp
ON STG.subsidiary_id = NS_Subsidiaries_base_Tmp.subsidiary_id AND STG.date_last_modified >= NS_Subsidiaries_base_Tmp.date_last_modified);


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Subsidiaries_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Subsidiaries WHERE subsidiary_id in
(SELECT STG.subsidiary_id FROM NS_Subsidiaries_stg_Tmp_Key STG JOIN NS_Subsidiaries_base_Tmp
ON STG.subsidiary_id = NS_Subsidiaries_base_Tmp.subsidiary_id AND STG.date_last_modified >= NS_Subsidiaries_base_Tmp.date_last_modified);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Subsidiaries
(
address
,address1
,address2
,base_currency_id
,branch_id
,city
,country
,date_last_modified
,duns_number
,edition
,federal_number
,fiscal_calendar_id
,full_name
,idt__account_id
,individual_bill_payment
,inquiry_email_address
,inquiry_phone_number
,invoice_printer_address
,invoice_printer_name
,invoice_printer_phone
,invoice_printer_tax_id
,is_elimination
,is_moss
,isinactive
,legal_name
,moss_nexus_id
,name
,onesource_company_id
,parent_id
,payment_terms_link
,purchaseorderamount
,purchaseorderquantity
,purchaseorderquantitydiff
,receiptamount
,receiptquantity
,receiptquantitydiff
,return_address
,return_address1
,return_address2
,return_city
,return_country
,return_state
,return_zipcode
,settlement_type_id
,shipping_address
,shipping_address1
,shipping_address2
,shipping_city
,shipping_country
,shipping_state
,shipping_zipcode
,state
,state_tax_number
,subsidiary_attribute_id
,subsidiary_clearing_bank_acco
,subsidiary_code
,subsidiary_extid
,subsidiary_id
,tran_num_prefix
,url
,disable_country_field
,edocument_country_for_free__id
,edocument_sender_id
,hr_country_id
,payment_purpose_code_ppc_id
,region_id
,state_full_name
,tax_id_rfc_mexico_only
,zipcode
,RECIPIENT_OF_EDOCUMENT_NOTIFI
,SWT_INS_DT
)
SELECT DISTINCT 
address
,address1
,address2
,base_currency_id
,branch_id
,city
,country
,NS_Subsidiaries_stg_Tmp.date_last_modified
,duns_number
,edition
,federal_number
,fiscal_calendar_id
,full_name
,idt__account_id
,individual_bill_payment
,inquiry_email_address
,inquiry_phone_number
,invoice_printer_address
,invoice_printer_name
,invoice_printer_phone
,invoice_printer_tax_id
,is_elimination
,is_moss
,isinactive
,legal_name
,moss_nexus_id
,name
,onesource_company_id
,parent_id
,payment_terms_link
,purchaseorderamount
,purchaseorderquantity
,purchaseorderquantitydiff
,receiptamount
,receiptquantity
,receiptquantitydiff
,return_address
,return_address1
,return_address2
,return_city
,return_country
,return_state
,return_zipcode
,settlement_type_id
,shipping_address
,shipping_address1
,shipping_address2
,shipping_city
,shipping_country
,shipping_state
,shipping_zipcode
,state
,state_tax_number
,subsidiary_attribute_id
,subsidiary_clearing_bank_acco
,subsidiary_code
,subsidiary_extid
,NS_Subsidiaries_stg_Tmp.subsidiary_id
,tran_num_prefix
,url
,disable_country_field
,edocument_country_for_free__id
,edocument_sender_id
,hr_country_id
,payment_purpose_code_ppc_id
,region_id
,state_full_name
,tax_id_rfc_mexico_only
,zipcode
,RECIPIENT_OF_EDOCUMENT_NOTIFI
,SYSDATE AS SWT_INS_DT
FROM NS_Subsidiaries_stg_Tmp JOIN NS_Subsidiaries_stg_Tmp_Key ON NS_Subsidiaries_stg_Tmp.subsidiary_id= NS_Subsidiaries_stg_Tmp_Key.subsidiary_id AND NS_Subsidiaries_stg_Tmp.date_last_modified=NS_Subsidiaries_stg_Tmp_Key.date_last_modified
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Subsidiaries BASE
WHERE NS_Subsidiaries_stg_Tmp.subsidiary_id = BASE.subsidiary_id);




/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Subsidiaries' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Subsidiaries' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Subsidiaries',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Subsidiaries where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

SELECT PURGE_TABLE('swt_rpt_base.NS_Subsidiaries');
SELECT PURGE_TABLE('swt_rpt_stg.NS_Subsidiaries_Hist');
select ANALYZE_STATISTICS('swt_rpt_base.NS_Subsidiaries');


