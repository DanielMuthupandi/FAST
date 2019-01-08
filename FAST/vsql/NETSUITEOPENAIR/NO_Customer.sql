/****
****Script Name   : NO_Customer.sql
****Description   : Incremental data load for NO_Customer
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
select 'NETSUITEOPENAIR','NO_Customer',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_Customer") ,null,'N';

Commit;

CREATE LOCAL TEMP TABLE NO_Customer_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_Customer)
SEGMENTED BY HASH(ID,UPDATED) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Customer_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,UPDATED FROM swt_rpt_base.NO_Customer)
SEGMENTED BY HASH(ID,UPDATED) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Customer_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(UPDATED) as UPDATED FROM NO_Customer_stg_Tmp group by id)
SEGMENTED BY HASH(ID,UPDATED) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_Customer_Hist
(
id
,invoice_layoutid
,rate
,bus_typeid
,code
,name
,tb_approver
,territoryid
,hierarchy_node_ids
,hear_aboutid
,statements
,company_sizeid
,web
,currency
,cost_centerid
,billingaddr
,billing_contact_id
,notes
,tb_approvalprocess
,primary_contactid
,filterset_ids
,active
,externalid
,invoice_prefix
,type
,userid
,terms
,invoice_text
,company
,shipping_contactid
,sold_to_contact_id
,billing_code
,ta_include
,te_include
,updated
,addr_addr1
,addr_addr2
,addr_addr3
,addr_addr4
,addr_city
,addr_contact_id
,addr_country
,addr_email
,addr_fax
,addr_first
,addr_id
,addr_last
,addr_middle
,addr_mobile
,addr_phone
,addr_salutation
,addr_state
,addr_zip
,billing_addr_addr1
,billing_addr_addr2
,billing_addr_addr3
,billing_addr_addr4
,billing_addr_city
,billing_addr_contact_id
,billing_addr_country
,billing_addr_email
,billing_addr_fax
,billing_addr_first
,billing_addr_id
,billing_addr_last
,billing_addr_middle
,billing_addr_mobile
,billing_addr_phone
,billing_addr_salutation
,billing_addr_state
,billing_addr_zip
,contact_addr_addr1
,contact_addr_addr2
,contact_addr_addr3
,contact_addr_addr4
,contact_addr_city
,contact_addr_contact_id
,contact_addr_country
,contact_addr_email
,contact_addr_fax
,contact_addr_first
,contact_addr_id
,contact_addr_last
,contact_addr_middle
,contact_addr_mobile
,contact_addr_phone
,contact_addr_salutation
,contact_addr_state
,contact_addr_zip
,createtime
,customer_locationid
,picklist_label
,netsuite_customer_id
,netsuite_subsidiary_id
,customer_sf_id__c
,subsidiary_code__c
,account_number__c
,customer_legacy_id__c
,cust_dunsnumber__c
,cust_globalparentname__c
,cust_globalparentdunsnumber__c
,cust_domesticparentname__c
,cust_domesticparentdunsnumber__c
,cust_immediateparentname__c
,cust_immediateparentdunsnumber__c
,cust_hpe_bulstat_number__c
,cust_accountname__c
,cust_parentcust__c
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,invoice_layoutid
,rate
,bus_typeid
,code
,name
,tb_approver
,territoryid
,hierarchy_node_ids
,hear_aboutid
,statements
,company_sizeid
,web
,currency
,cost_centerid
,billingaddr
,billing_contact_id
,notes
,tb_approvalprocess
,primary_contactid
,filterset_ids
,active
,externalid
,invoice_prefix
,type
,userid
,terms
,invoice_text
,company
,shipping_contactid
,sold_to_contact_id
,billing_code
,ta_include
,te_include
,updated
,addr_addr1
,addr_addr2
,addr_addr3
,addr_addr4
,addr_city
,addr_contact_id
,addr_country
,addr_email
,addr_fax
,addr_first
,addr_id
,addr_last
,addr_middle
,addr_mobile
,addr_phone
,addr_salutation
,addr_state
,addr_zip
,billing_addr_addr1
,billing_addr_addr2
,billing_addr_addr3
,billing_addr_addr4
,billing_addr_city
,billing_addr_contact_id
,billing_addr_country
,billing_addr_email
,billing_addr_fax
,billing_addr_first
,billing_addr_id
,billing_addr_last
,billing_addr_middle
,billing_addr_mobile
,billing_addr_phone
,billing_addr_salutation
,billing_addr_state
,billing_addr_zip
,contact_addr_addr1
,contact_addr_addr2
,contact_addr_addr3
,contact_addr_addr4
,contact_addr_city
,contact_addr_contact_id
,contact_addr_country
,contact_addr_email
,contact_addr_fax
,contact_addr_first
,contact_addr_id
,contact_addr_last
,contact_addr_middle
,contact_addr_mobile
,contact_addr_phone
,contact_addr_salutation
,contact_addr_state
,contact_addr_zip
,createtime
,customer_locationid
,picklist_label
,netsuite_customer_id
,netsuite_subsidiary_id
,customer_sf_id__c
,subsidiary_code__c
,account_number__c
,customer_legacy_id__c
,cust_dunsnumber__c
,cust_globalparentname__c
,cust_globalparentdunsnumber__c
,cust_domesticparentname__c
,cust_domesticparentdunsnumber__c
,cust_immediateparentname__c
,cust_immediateparentdunsnumber__c
,cust_hpe_bulstat_number__c
,cust_accountname__c
,cust_parentcust__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_Customer WHERE id in
(SELECT STG.id FROM NO_Customer_stg_Tmp_Key STG JOIN NO_Customer_base_Tmp
ON STG.id = NO_Customer_base_Tmp.id AND STG.updated >= NO_Customer_base_Tmp.updated);

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_Customer_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_Customer WHERE id in
(SELECT STG.id FROM NO_Customer_stg_Tmp_Key STG JOIN NO_Customer_base_Tmp
ON STG.id = NO_Customer_base_Tmp.id AND STG.updated >= NO_Customer_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_Customer
(
id
,invoice_layoutid
,rate
,bus_typeid
,code
,name
,tb_approver
,territoryid
,hierarchy_node_ids
,hear_aboutid
,statements
,company_sizeid
,web
,currency
,cost_centerid
,billingaddr
,billing_contact_id
,notes
,tb_approvalprocess
,primary_contactid
,filterset_ids
,active
,externalid
,invoice_prefix
,type
,userid
,terms
,invoice_text
,company
,shipping_contactid
,sold_to_contact_id
,billing_code
,ta_include
,te_include
,updated
,addr_addr1
,addr_addr2
,addr_addr3
,addr_addr4
,addr_city
,addr_contact_id
,addr_country
,addr_email
,addr_fax
,addr_first
,addr_id
,addr_last
,addr_middle
,addr_mobile
,addr_phone
,addr_salutation
,addr_state
,addr_zip
,billing_addr_addr1
,billing_addr_addr2
,billing_addr_addr3
,billing_addr_addr4
,billing_addr_city
,billing_addr_contact_id
,billing_addr_country
,billing_addr_email
,billing_addr_fax
,billing_addr_first
,billing_addr_id
,billing_addr_last
,billing_addr_middle
,billing_addr_mobile
,billing_addr_phone
,billing_addr_salutation
,billing_addr_state
,billing_addr_zip
,contact_addr_addr1
,contact_addr_addr2
,contact_addr_addr3
,contact_addr_addr4
,contact_addr_city
,contact_addr_contact_id
,contact_addr_country
,contact_addr_email
,contact_addr_fax
,contact_addr_first
,contact_addr_id
,contact_addr_last
,contact_addr_middle
,contact_addr_mobile
,contact_addr_phone
,contact_addr_salutation
,contact_addr_state
,contact_addr_zip
,createtime
,customer_locationid
,picklist_label
,netsuite_customer_id
,netsuite_subsidiary_id
,customer_sf_id__c
,subsidiary_code__c
,account_number__c
,customer_legacy_id__c
,cust_dunsnumber__c
,cust_globalparentname__c
,cust_globalparentdunsnumber__c
,cust_domesticparentname__c
,cust_domesticparentdunsnumber__c
,cust_immediateparentname__c
,cust_immediateparentdunsnumber__c
,cust_hpe_bulstat_number__c
,cust_accountname__c
,cust_parentcust__c
,SWT_INS_DT
)
SELECT DISTINCT
NO_Customer_stg_Tmp.id
,invoice_layoutid
,rate
,bus_typeid
,code
,name
,tb_approver
,territoryid
,hierarchy_node_ids
,hear_aboutid
,statements
,company_sizeid
,web
,currency
,cost_centerid
,billingaddr
,billing_contact_id
,notes
,tb_approvalprocess
,primary_contactid
,filterset_ids
,active
,externalid
,invoice_prefix
,type
,userid
,terms
,invoice_text
,company
,shipping_contactid
,sold_to_contact_id
,billing_code
,ta_include
,te_include
,NO_Customer_stg_Tmp.updated
,addr_addr1
,addr_addr2
,addr_addr3
,addr_addr4
,addr_city
,addr_contact_id
,addr_country
,addr_email
,addr_fax
,addr_first
,addr_id
,addr_last
,addr_middle
,addr_mobile
,addr_phone
,addr_salutation
,addr_state
,addr_zip
,billing_addr_addr1
,billing_addr_addr2
,billing_addr_addr3
,billing_addr_addr4
,billing_addr_city
,billing_addr_contact_id
,billing_addr_country
,billing_addr_email
,billing_addr_fax
,billing_addr_first
,billing_addr_id
,billing_addr_last
,billing_addr_middle
,billing_addr_mobile
,billing_addr_phone
,billing_addr_salutation
,billing_addr_state
,billing_addr_zip
,contact_addr_addr1
,contact_addr_addr2
,contact_addr_addr3
,contact_addr_addr4
,contact_addr_city
,contact_addr_contact_id
,contact_addr_country
,contact_addr_email
,contact_addr_fax
,contact_addr_first
,contact_addr_id
,contact_addr_last
,contact_addr_middle
,contact_addr_mobile
,contact_addr_phone
,contact_addr_salutation
,contact_addr_state
,contact_addr_zip
,createtime
,customer_locationid
,picklist_label
,netsuite_customer_id
,netsuite_subsidiary_id
,customer_sf_id__c
,subsidiary_code__c
,account_number__c
,customer_legacy_id__c
,cust_dunsnumber__c
,cust_globalparentname__c
,cust_globalparentdunsnumber__c
,cust_domesticparentname__c
,cust_domesticparentdunsnumber__c
,cust_immediateparentname__c
,cust_immediateparentdunsnumber__c
,cust_hpe_bulstat_number__c
,cust_accountname__c
,cust_parentcust__c
,SYSDATE AS SWT_INS_DT
FROM NO_Customer_stg_Tmp JOIN NO_Customer_stg_Tmp_Key ON NO_Customer_stg_Tmp.id= NO_Customer_stg_Tmp_Key.id AND NO_Customer_stg_Tmp.updated=NO_Customer_stg_Tmp_Key.updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_Customer BASE
WHERE NO_Customer_stg_Tmp.id = BASE.id);



/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_Customer' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_Customer' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_Customer',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_Customer") ,(select count(*) from swt_rpt_base.NO_Customer where SWT_INS_DT::date = sysdate::date),'Y';

Commit;



select do_tm_task('mergeout','swt_rpt_stg.NO_Customer_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_Customer');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_Customer');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_Customer_Hist SELECT * from swt_rpt_stg.NO_Customer;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_Customer;
