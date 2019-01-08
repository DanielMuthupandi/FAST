/****
****Script Name   : NO_Purchase_item.sql
****Description   : Incremental data load for NO_Purchase_item
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
select 'NETSUITEOPENAIR','NO_Purchase_item',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_Purchase_item") ,null,'N';

Commit;


CREATE LOCAL TEMP TABLE NO_Purchase_item_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_Purchase_item)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Purchase_item_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,Updated FROM swt_rpt_base.NO_Purchase_item)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Purchase_item_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(Updated) as Updated FROM NO_Purchase_item_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,Updated) ALL NODES;

/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_Purchase_item_Hist
(
id
,created
,updated
,date
,um
,purchaserid
,attachmentid
,approved_cost
,manufacturer_part
,cost
,tax_location_name
,non_po
,name
,total
,quantity_payable
,customerid
,request_itemid
,vendor_quote_number
,userid
,purchaserequestid
,manufacturerid
,currency
,quantity_fulfilled
,date_fulfilled
,purchaseorderid
,allow_vendor_substitution
,order_reference_number
,total_with_tax
,quantity
,projectid
,vendor_sku
,vendorid
,productid
,acct_date
,external_id_2__c
,netsuite_purchase_item_tax__c
,netsuite_vb_billable__c
,netsuite_vendorbill_purchase_item_id__c
,ns_transaction_number__c
,purch_AribaPOnum__c
,purch_NSJEnum__c
,purch_legacy_id__c
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,created
,updated
,date
,um
,purchaserid
,attachmentid
,approved_cost
,manufacturer_part
,cost
,tax_location_name
,non_po
,name
,total
,quantity_payable
,customerid
,request_itemid
,vendor_quote_number
,userid
,purchaserequestid
,manufacturerid
,currency
,quantity_fulfilled
,date_fulfilled
,purchaseorderid
,allow_vendor_substitution
,order_reference_number
,total_with_tax
,quantity
,projectid
,vendor_sku
,vendorid
,productid
,acct_date
,external_id_2__c
,netsuite_purchase_item_tax__c
,netsuite_vb_billable__c
,netsuite_vendorbill_purchase_item_id__c
,ns_transaction_number__c
,purch_AribaPOnum__c
,purch_NSJEnum__c
,purch_legacy_id__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_Purchase_item WHERE id in
(SELECT STG.id FROM NO_Purchase_item_stg_Tmp_Key STG JOIN NO_Purchase_item_base_Tmp
ON STG.id = NO_Purchase_item_base_Tmp.id AND STG.updated >= NO_Purchase_item_base_Tmp.updated);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_Purchase_item_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_Purchase_item WHERE id in
(SELECT STG.id FROM NO_Purchase_item_stg_Tmp_Key STG JOIN NO_Purchase_item_base_Tmp
ON STG.id = NO_Purchase_item_base_Tmp.id AND STG.updated >= NO_Purchase_item_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_Purchase_item
(
id
,created
,updated
,date
,um
,purchaserid
,attachmentid
,approved_cost
,manufacturer_part
,cost
,tax_location_name
,non_po
,name
,total
,quantity_payable
,customerid
,request_itemid
,vendor_quote_number
,userid
,purchaserequestid
,manufacturerid
,currency
,quantity_fulfilled
,date_fulfilled
,purchaseorderid
,allow_vendor_substitution
,order_reference_number
,total_with_tax
,quantity
,projectid
,vendor_sku
,vendorid
,productid
,acct_date
,external_id_2__c
,netsuite_purchase_item_tax__c
,netsuite_vb_billable__c
,netsuite_vendorbill_purchase_item_id__c
,ns_transaction_number__c
,purch_AribaPOnum__c
,purch_NSJEnum__c
,purch_legacy_id__c
,SWT_INS_DT
)
SELECT DISTINCT
NO_Purchase_item_stg_Tmp.id
,created
,NO_Purchase_item_stg_Tmp.updated
,date
,um
,purchaserid
,attachmentid
,approved_cost
,manufacturer_part
,cost
,tax_location_name
,non_po
,name
,total
,quantity_payable
,customerid
,request_itemid
,vendor_quote_number
,userid
,purchaserequestid
,manufacturerid
,currency
,quantity_fulfilled
,date_fulfilled
,purchaseorderid
,allow_vendor_substitution
,order_reference_number
,total_with_tax
,quantity
,projectid
,vendor_sku
,vendorid
,productid
,acct_date
,external_id_2__c
,netsuite_purchase_item_tax__c
,netsuite_vb_billable__c
,netsuite_vendorbill_purchase_item_id__c
,ns_transaction_number__c
,purch_AribaPOnum__c
,purch_NSJEnum__c
,purch_legacy_id__c
,SYSDATE AS SWT_INS_DT
FROM NO_Purchase_item_stg_Tmp JOIN NO_Purchase_item_stg_Tmp_Key ON NO_Purchase_item_stg_Tmp.Id= NO_Purchase_item_stg_Tmp_Key.Id AND NO_Purchase_item_stg_Tmp.Updated=NO_Purchase_item_stg_Tmp_Key.Updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_Purchase_item BASE
WHERE NO_Purchase_item_stg_Tmp.Id = BASE.Id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_Purchase_item' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_Purchase_item' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_Purchase_item',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_Purchase_item") ,(select count(*) from swt_rpt_base.NO_Purchase_item where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

select do_tm_task('mergeout','swt_rpt_stg.NO_Purchase_item_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_Purchase_item');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_Purchase_item');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_Purchase_item_Hist SELECT * from swt_rpt_stg.NO_Purchase_item;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_Purchase_item;
