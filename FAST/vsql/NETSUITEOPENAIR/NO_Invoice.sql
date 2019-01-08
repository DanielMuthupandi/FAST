/****
****Script Name   : NO_Projectstage.sql
****Description   : Incremental data load for NO_Invoice
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
select 'NETSUITEOPENAIR','NO_Invoice',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_Invoice") ,null,'N';

Commit;


CREATE LOCAL TEMP TABLE NO_Invoice_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_Invoice)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Invoice_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,Updated FROM swt_rpt_base.NO_Invoice)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Invoice_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(Updated) as Updated FROM NO_Invoice_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,Updated) ALL NODES;

/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_Invoice_Hist
(
id
,created
,draw_date
,number
,status
,date
,terms
,invoice_layoutid
,credit_reason
,currency
,tax_state
,tax_federal
,tax_gst
,tax_pst
,draw
,contactid
,shipping_contactid
,approval_status
,access_log
,credit
,tax_hst
,tax
,total
,updated
,balance
,paperrequest
,accounting
,acct_date
,papersend
,credit_rebill_status
,original_invoiceid
,attachmentid
,submitted
,approved
,customerid
,emailed
,TransId
,custbody_hpe_editransaction
,custbody_deliverywithoutapproval
,custbody_dwoprojectid
,custbody_influencer
,custbody_hpe_incoterm
,custbody_hpe_bill_of_lading_number
,custcol_hpe_box_number
,custcol_hpe_ship_date
,custbody_hpe_exchangeratetousd
,InvoiceIntegrationErrorCode_c
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,created
,draw_date
,number
,status
,date
,terms
,invoice_layoutid
,credit_reason
,currency
,tax_state
,tax_federal
,tax_gst
,tax_pst
,draw
,contactid
,shipping_contactid
,approval_status
,access_log
,credit
,tax_hst
,tax
,total
,updated
,balance
,paperrequest
,accounting
,acct_date
,papersend
,credit_rebill_status
,original_invoiceid
,attachmentid
,submitted
,approved
,customerid
,emailed
,TransId
,custbody_hpe_editransaction
,custbody_deliverywithoutapproval
,custbody_dwoprojectid
,custbody_influencer
,custbody_hpe_incoterm
,custbody_hpe_bill_of_lading_number
,custcol_hpe_box_number
,custcol_hpe_ship_date
,custbody_hpe_exchangeratetousd
,InvoiceIntegrationErrorCode_c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_Invoice WHERE id in
(SELECT STG.id FROM NO_Invoice_stg_Tmp_Key STG JOIN NO_Invoice_base_Tmp
ON STG.id = NO_Invoice_base_Tmp.id AND STG.updated >= NO_Invoice_base_Tmp.updated);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_Invoice_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_Invoice WHERE id in
(SELECT STG.id FROM NO_Invoice_stg_Tmp_Key STG JOIN NO_Invoice_base_Tmp
ON STG.id = NO_Invoice_base_Tmp.id AND STG.updated >= NO_Invoice_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_Invoice
(
id
,created
,draw_date
,number
,status
,date
,terms
,invoice_layoutid
,credit_reason
,currency
,tax_state
,tax_federal
,tax_gst
,tax_pst
,draw
,contactid
,shipping_contactid
,approval_status
,access_log
,credit
,tax_hst
,tax
,total
,updated
,balance
,paperrequest
,accounting
,acct_date
,papersend
,credit_rebill_status
,original_invoiceid
,attachmentid
,submitted
,approved
,customerid
,emailed
,TransId
,custbody_hpe_editransaction
,custbody_deliverywithoutapproval
,custbody_dwoprojectid
,custbody_influencer
,custbody_hpe_incoterm
,custbody_hpe_bill_of_lading_number
,custcol_hpe_box_number
,custcol_hpe_ship_date
,custbody_hpe_exchangeratetousd
,InvoiceIntegrationErrorCode_c
,SWT_INS_DT
)
SELECT DISTINCT
NO_Invoice_stg_Tmp.id
,created
,draw_date
,number
,status
,date
,terms
,invoice_layoutid
,credit_reason
,currency
,tax_state
,tax_federal
,tax_gst
,tax_pst
,draw
,contactid
,shipping_contactid
,approval_status
,access_log
,credit
,tax_hst
,tax
,total
,NO_Invoice_stg_Tmp.updated
,balance
,paperrequest
,accounting
,acct_date
,papersend
,credit_rebill_status
,original_invoiceid
,attachmentid
,submitted
,approved
,customerid
,emailed
,TransId
,custbody_hpe_editransaction
,custbody_deliverywithoutapproval
,custbody_dwoprojectid
,custbody_influencer
,custbody_hpe_incoterm
,custbody_hpe_bill_of_lading_number
,custcol_hpe_box_number
,custcol_hpe_ship_date
,custbody_hpe_exchangeratetousd
,InvoiceIntegrationErrorCode_c
,SYSDATE AS SWT_INS_DT
FROM NO_Invoice_stg_Tmp JOIN NO_Invoice_stg_Tmp_Key ON NO_Invoice_stg_Tmp.Id= NO_Invoice_stg_Tmp_Key.Id AND NO_Invoice_stg_Tmp.Updated=NO_Invoice_stg_Tmp_Key.Updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_Invoice BASE
WHERE NO_Invoice_stg_Tmp.Id = BASE.Id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_Invoice' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_Invoice' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_Invoice',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_Invoice") ,(select count(*) from swt_rpt_base.NO_Invoice where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

select do_tm_task('mergeout','swt_rpt_stg.NO_Invoice_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_Invoice');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_Invoice');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_Invoice_Hist SELECT * from swt_rpt_stg.NO_Invoice;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_Invoice;
