/****
****Script Name   : NO_Vendor.sql
****Description   : Incremental data load for NO_Vendor
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
select 'NETSUITEOPENAIR','NO_Vendor',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_Vendor") ,null,'N';

Commit;




CREATE LOCAL TEMP TABLE NO_Vendor_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_Vendor)
SEGMENTED BY HASH(ID,UPDATED) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Vendor_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,UPDATED FROM swt_rpt_base.NO_Vendor)
SEGMENTED BY HASH(ID,UPDATED) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Vendor_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(UPDATED) as UPDATED FROM NO_Vendor_stg_Tmp group by id)
SEGMENTED BY HASH(ID,UPDATED) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_Vendor_Hist
(
id
,created
,updated
,terms
,purchaseorder_text
,currency
,web
,code
,attention
,name
,active
,externalid
,tax_locationid
,addr_state
,addr_mobile
,addr_country
,addr_phone
,addr_addr4
,addr_zip
,addr_first
,addr_email
,addr_addr3
,addr_middle
,addr_fax
,addr_salutation
,addr_city
,addr_addr2
,addr_id
,picklist_label
,netsuite_vendor_id__c
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,created
,updated
,terms
,purchaseorder_text
,currency
,web
,code
,attention
,name
,active
,externalid
,tax_locationid
,addr_state
,addr_mobile
,addr_country
,addr_phone
,addr_addr4
,addr_zip
,addr_first
,addr_email
,addr_addr3
,addr_middle
,addr_fax
,addr_salutation
,addr_city
,addr_addr2
,addr_id
,picklist_label
,netsuite_vendor_id__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_Vendor WHERE id in
(SELECT STG.id FROM NO_Vendor_stg_Tmp_Key STG JOIN NO_Vendor_base_Tmp
ON STG.id = NO_Vendor_base_Tmp.id AND STG.updated >= NO_Vendor_base_Tmp.updated);

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_Vendor_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_Vendor WHERE id in
(SELECT STG.id FROM NO_Vendor_stg_Tmp_Key STG JOIN NO_Vendor_base_Tmp
ON STG.id = NO_Vendor_base_Tmp.id AND STG.updated >= NO_Vendor_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_Vendor
(
id
,created
,updated
,terms
,purchaseorder_text
,currency
,web
,code
,attention
,name
,active
,externalid
,tax_locationid
,addr_state
,addr_mobile
,addr_country
,addr_phone
,addr_addr4
,addr_zip
,addr_first
,addr_email
,addr_addr3
,addr_middle
,addr_fax
,addr_salutation
,addr_city
,addr_addr2
,addr_id
,picklist_label
,netsuite_vendor_id__c
,SWT_INS_DT
)
SELECT DISTINCT
NO_Vendor_stg_Tmp.id
,created
,NO_Vendor_stg_Tmp.updated
,terms
,purchaseorder_text
,currency
,web
,code
,attention
,name
,active
,externalid
,tax_locationid
,addr_state
,addr_mobile
,addr_country
,addr_phone
,addr_addr4
,addr_zip
,addr_first
,addr_email
,addr_addr3
,addr_middle
,addr_fax
,addr_salutation
,addr_city
,addr_addr2
,addr_id
,picklist_label
,netsuite_vendor_id__c
,SYSDATE AS SWT_INS_DT
FROM NO_Vendor_stg_Tmp JOIN NO_Vendor_stg_Tmp_Key ON NO_Vendor_stg_Tmp.id= NO_Vendor_stg_Tmp_Key.id AND NO_Vendor_stg_Tmp.updated=NO_Vendor_stg_Tmp_Key.updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_Vendor BASE
WHERE NO_Vendor_stg_Tmp.id = BASE.id);

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_Vendor' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_Vendor' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_Vendor',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_Vendor") ,(select count(*) from swt_rpt_base.NO_Vendor where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

select do_tm_task('mergeout','swt_rpt_stg.NO_Vendor_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_Vendor');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_Vendor');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_Vendor_Hist SELECT * from swt_rpt_stg.NO_Vendor;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_Vendor;
