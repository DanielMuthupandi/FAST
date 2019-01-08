/****
****Script Name   : NO_Contact.sql
****Description   : Incremental data load for NO_Contact
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
select 'NETSUITEOPENAIR','NO_Contact',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_Contact") ,null,'N';

Commit;


CREATE LOCAL TEMP TABLE NO_Contact_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_Contact)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Contact_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,Updated FROM swt_rpt_base.NO_Contact)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Contact_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(Updated) as Updated FROM NO_Contact_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_Contact_Hist
(
id
,customer_company
,job_title
,updated
,can_bill_to
,code
,name
,active
,externalid
,can_sold_to
,created
,customerid
,customer_externalid
,exported
,can_ship_to
,addr_state
,addr_mobile
,addr_country
,addr_phone
,addr_addr4
,addr_zip
,addr_first
,addr_last
,addr_email
,addr_addr3
,addr_addr1
,addr_fax
,addr_city
,addr_addr2
,picklist_label
,addr_id
,addr_salutation
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,customer_company
,job_title
,updated
,can_bill_to
,code
,name
,active
,externalid
,can_sold_to
,created
,customerid
,customer_externalid
,exported
,can_ship_to
,addr_state
,addr_mobile
,addr_country
,addr_phone
,addr_addr4
,addr_zip
,addr_first
,addr_last
,addr_email
,addr_addr3
,addr_addr1
,addr_fax
,addr_city
,addr_addr2
,picklist_label
,addr_id
,addr_salutation
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_Contact WHERE id in
(SELECT STG.id FROM NO_Contact_stg_Tmp_Key STG JOIN NO_Contact_base_Tmp
ON STG.id = NO_Contact_base_Tmp.id AND STG.updated >= NO_Contact_base_Tmp.updated);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_Contact_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_Contact WHERE id in
(SELECT STG.id FROM NO_Contact_stg_Tmp_Key STG JOIN NO_Contact_base_Tmp
ON STG.id = NO_Contact_base_Tmp.id AND STG.updated >= NO_Contact_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_Contact
(
id
,customer_company
,job_title
,updated
,can_bill_to
,code
,name
,active
,externalid
,can_sold_to
,created
,customerid
,customer_externalid
,exported
,can_ship_to
,addr_state
,addr_mobile
,addr_country
,addr_phone
,addr_addr4
,addr_zip
,addr_first
,addr_last
,addr_email
,addr_addr3
,addr_addr1
,addr_fax
,addr_city
,addr_addr2
,picklist_label
,addr_id
,addr_salutation
,SWT_INS_DT
)
SELECT DISTINCT
NO_Contact_stg_Tmp.id
,customer_company
,job_title
,NO_Contact_stg_Tmp.updated
,can_bill_to
,code
,name
,active
,externalid
,can_sold_to
,created
,customerid
,customer_externalid
,exported
,can_ship_to
,addr_state
,addr_mobile
,addr_country
,addr_phone
,addr_addr4
,addr_zip
,addr_first
,addr_last
,addr_email
,addr_addr3
,addr_addr1
,addr_fax
,addr_city
,addr_addr2
,picklist_label
,addr_id
,addr_salutation
,SYSDATE AS SWT_INS_DT
FROM NO_Contact_stg_Tmp JOIN NO_Contact_stg_Tmp_Key ON NO_Contact_stg_Tmp.Id= NO_Contact_stg_Tmp_Key.Id AND NO_Contact_stg_Tmp.Updated=NO_Contact_stg_Tmp_Key.Updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_Contact BASE
WHERE NO_Contact_stg_Tmp.Id = BASE.Id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_Contact' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_Contact' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_Contact',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_Contact") ,(select count(*) from swt_rpt_base.NO_Contact where SWT_INS_DT::date = sysdate::date),'Y';

Commit;



select do_tm_task('mergeout','swt_rpt_stg.NO_Contact_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_Contact');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_Contact');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');

INSERT /*+Direct*/ INTO swt_rpt_stg.NO_Contact_Hist SELECT * from swt_rpt_stg.NO_Contact;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_Contact;
