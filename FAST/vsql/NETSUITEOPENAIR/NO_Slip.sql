/****
****Script Name   : NO_Slip.sql
****Description   : Incremental data load for NO_Slip
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
select 'NETSUITEOPENAIR','NO_Slip',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_Slip") ,null,'N';

Commit;



CREATE LOCAL TEMP TABLE NO_Slip_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_Slip)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Slip_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,Updated FROM swt_rpt_base.NO_Slip)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Slip_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(Updated) as Updated FROM NO_Slip_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,Updated) ALL NODES;

/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_Slip_Hist
(
id
,created
,updated
,hour
,date
,unitm
,rate
,slip_stageid
,project_billing_ruleid
,cost
,tax_location_name
,sold_to_contactid
,description
,total
,categoryid
,timer_start
,minute
,customerid
,type
,agreementid
,total_tax
,customerpoid
,userid
,invoiceid
,currency
,city
,decimal_hours
,payment_typeid
,total_with_tax
,shipping_contactid
,itemid
,timetypeid
,quantity
,billing_contactid
,projectid
,projecttaskid
,productid
,cost_centerid
,acct_date
,projecttask_type_id
,job_code_id
,payroll_typeid
,ref_slipid
,portfolio_projectid
,originating_id
,category_1id
,category_2id
,category_3id
,category_4id
,category_5id
,gl_code
,skip_recognition
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,created
,updated
,hour
,date
,unitm
,rate
,slip_stageid
,project_billing_ruleid
,cost
,tax_location_name
,sold_to_contactid
,description
,total
,categoryid
,timer_start
,minute
,customerid
,type
,agreementid
,total_tax
,customerpoid
,userid
,invoiceid
,currency
,city
,decimal_hours
,payment_typeid
,total_with_tax
,shipping_contactid
,itemid
,timetypeid
,quantity
,billing_contactid
,projectid
,projecttaskid
,productid
,cost_centerid
,acct_date
,projecttask_type_id
,job_code_id
,payroll_typeid
,ref_slipid
,portfolio_projectid
,originating_id
,category_1id
,category_2id
,category_3id
,category_4id
,category_5id
,gl_code
,skip_recognition
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_Slip WHERE id in
(SELECT STG.id FROM NO_Slip_stg_Tmp_Key STG JOIN NO_Slip_base_Tmp
ON STG.id = NO_Slip_base_Tmp.id AND STG.updated >= NO_Slip_base_Tmp.updated);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_Slip_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;





/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_Slip WHERE id in
(SELECT STG.id FROM NO_Slip_stg_Tmp_Key STG JOIN NO_Slip_base_Tmp
ON STG.id = NO_Slip_base_Tmp.id AND STG.updated >= NO_Slip_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_Slip
(
id
,created
,updated
,hour
,date
,unitm
,rate
,slip_stageid
,project_billing_ruleid
,cost
,tax_location_name
,sold_to_contactid
,description
,total
,categoryid
,timer_start
,minute
,customerid
,type
,agreementid
,total_tax
,customerpoid
,userid
,invoiceid
,currency
,city
,decimal_hours
,payment_typeid
,total_with_tax
,shipping_contactid
,itemid
,timetypeid
,quantity
,billing_contactid
,projectid
,projecttaskid
,productid
,cost_centerid
,acct_date
,projecttask_type_id
,job_code_id
,payroll_typeid
,ref_slipid
,portfolio_projectid
,originating_id
,category_1id
,category_2id
,category_3id
,category_4id
,category_5id
,gl_code
,skip_recognition
,SWT_INS_DT
)
SELECT DISTINCT
NO_Slip_stg_Tmp.id
,created
,NO_Slip_stg_Tmp.updated
,hour
,date
,unitm
,rate
,slip_stageid
,project_billing_ruleid
,cost
,tax_location_name
,sold_to_contactid
,description
,total
,categoryid
,timer_start
,minute
,customerid
,type
,agreementid
,total_tax
,customerpoid
,userid
,invoiceid
,currency
,city
,decimal_hours
,payment_typeid
,total_with_tax
,shipping_contactid
,itemid
,timetypeid
,quantity
,billing_contactid
,projectid
,projecttaskid
,productid
,cost_centerid
,acct_date
,projecttask_type_id
,job_code_id
,payroll_typeid
,ref_slipid
,portfolio_projectid
,originating_id
,category_1id
,category_2id
,category_3id
,category_4id
,category_5id
,gl_code
,skip_recognition
,SYSDATE AS SWT_INS_DT
FROM NO_Slip_stg_Tmp JOIN NO_Slip_stg_Tmp_Key ON NO_Slip_stg_Tmp.Id= NO_Slip_stg_Tmp_Key.Id AND NO_Slip_stg_Tmp.Updated=NO_Slip_stg_Tmp_Key.Updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_Slip BASE
WHERE NO_Slip_stg_Tmp.Id = BASE.Id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_Slip' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_Slip' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_Slip',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_Slip") ,(select count(*) from swt_rpt_base.NO_Slip where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

select do_tm_task('mergeout','swt_rpt_stg.NO_Slip_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_Slip');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_Slip');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_Slip_Hist SELECT * from swt_rpt_stg.NO_Slip;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_Slip;
