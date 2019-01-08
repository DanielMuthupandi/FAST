/****
****Script Name   : NO_RevenueProjection.sql
****Description   : Incremental data load for NO_RevenueProjection
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
select 'NETSUITEOPENAIR','NO_RevenueProjection',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_RevenueProjection") ,null,'N';

Commit;


CREATE LOCAL TEMP TABLE NO_RevenueProjection_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_RevenueProjection)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_RevenueProjection_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,Updated FROM swt_rpt_base.NO_RevenueProjection)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_RevenueProjection_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(Updated) as Updated FROM NO_RevenueProjection_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_RevenueProjection_Hist
(
id
,created
,updated
,hour
,date
,um
,rate
,slip_stage_id
,project_billing_rule_id
,cost
,total
,category_id
,timer_start
,minute
,customer_id
,type
,agreement_id
,total_tax_paid
,customerpo_id
,user_id
,invoice_id
,currency
,city
,payment_type_id
,item_id
,timetype_id
,quantity
,project_id
,project_task_id
,product_id
,cost_center_id
,acct_date
,projecttask_type_id
,job_code_id
,payroll_type_id
,ref_slip_id
,portfolio_project_id
,category_1_id
,category_2_id
,category_3_id
,category_4_id
,category_5_id
,revenue_recognition_rule_id
,revenue_projection_type
,total_hp
,slip_projection_id
,slip_projection_type
,booking_type_id
,revenue_stage_id
,transaction_id
,incomplete
,name
,slip_type_id
,originating_id
,repeat_id
,vehicle_id
,cost_includes_tax
,exported
,description
,Time_Start
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
,um
,rate
,slip_stage_id
,project_billing_rule_id
,cost
,total
,category_id
,timer_start
,minute
,customer_id
,type
,agreement_id
,total_tax_paid
,customerpo_id
,user_id
,invoice_id
,currency
,city
,payment_type_id
,item_id
,timetype_id
,quantity
,project_id
,project_task_id
,product_id
,cost_center_id
,acct_date
,projecttask_type_id
,job_code_id
,payroll_type_id
,ref_slip_id
,portfolio_project_id
,category_1_id
,category_2_id
,category_3_id
,category_4_id
,category_5_id
,revenue_recognition_rule_id
,revenue_projection_type
,total_hp
,slip_projection_id
,slip_projection_type
,booking_type_id
,revenue_stage_id
,transaction_id
,incomplete
,name
,slip_type_id
,originating_id
,repeat_id
,vehicle_id
,cost_includes_tax
,exported
,description
,Time_Start
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_RevenueProjection WHERE id in
(SELECT STG.id FROM NO_RevenueProjection_stg_Tmp_Key STG JOIN NO_RevenueProjection_base_Tmp
ON STG.id = NO_RevenueProjection_base_Tmp.id AND STG.updated >= NO_RevenueProjection_base_Tmp.updated);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_RevenueProjection_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_RevenueProjection WHERE id in
(SELECT STG.id FROM NO_RevenueProjection_stg_Tmp_Key STG JOIN NO_RevenueProjection_base_Tmp
ON STG.id = NO_RevenueProjection_base_Tmp.id AND STG.updated >= NO_RevenueProjection_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_RevenueProjection
(
id
,created
,updated
,hour
,date
,um
,rate
,slip_stage_id
,project_billing_rule_id
,cost
,total
,category_id
,timer_start
,minute
,customer_id
,type
,agreement_id
,total_tax_paid
,customerpo_id
,user_id
,invoice_id
,currency
,city
,payment_type_id
,item_id
,timetype_id
,quantity
,project_id
,project_task_id
,product_id
,cost_center_id
,acct_date
,projecttask_type_id
,job_code_id
,payroll_type_id
,ref_slip_id
,portfolio_project_id
,category_1_id
,category_2_id
,category_3_id
,category_4_id
,category_5_id
,revenue_recognition_rule_id
,revenue_projection_type
,total_hp
,slip_projection_id
,slip_projection_type
,booking_type_id
,revenue_stage_id
,transaction_id
,incomplete
,name
,slip_type_id
,originating_id
,repeat_id
,vehicle_id
,cost_includes_tax
,exported
,description
,Time_Start
,SWT_INS_DT
)
SELECT DISTINCT
NO_RevenueProjection_stg_Tmp.id
,created
,NO_RevenueProjection_stg_Tmp.updated
,hour
,date
,um
,rate
,slip_stage_id
,project_billing_rule_id
,cost
,total
,category_id
,timer_start
,minute
,customer_id
,type
,agreement_id
,total_tax_paid
,customerpo_id
,user_id
,invoice_id
,currency
,city
,payment_type_id
,item_id
,timetype_id
,quantity
,project_id
,project_task_id
,product_id
,cost_center_id
,acct_date
,projecttask_type_id
,job_code_id
,payroll_type_id
,ref_slip_id
,portfolio_project_id
,category_1_id
,category_2_id
,category_3_id
,category_4_id
,category_5_id
,revenue_recognition_rule_id
,revenue_projection_type
,total_hp
,slip_projection_id
,slip_projection_type
,booking_type_id
,revenue_stage_id
,transaction_id
,incomplete
,name
,slip_type_id
,originating_id
,repeat_id
,vehicle_id
,cost_includes_tax
,exported
,description
,Time_Start
,SYSDATE AS SWT_INS_DT
FROM NO_RevenueProjection_stg_Tmp JOIN NO_RevenueProjection_stg_Tmp_Key ON NO_RevenueProjection_stg_Tmp.Id= NO_RevenueProjection_stg_Tmp_Key.Id AND NO_RevenueProjection_stg_Tmp.Updated=NO_RevenueProjection_stg_Tmp_Key.Updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_RevenueProjection BASE
WHERE NO_RevenueProjection_stg_Tmp.Id = BASE.Id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_RevenueProjection' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_RevenueProjection' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_RevenueProjection',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_RevenueProjection") ,(select count(*) from swt_rpt_base.NO_RevenueProjection where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

select do_tm_task('mergeout','swt_rpt_stg.NO_RevenueProjection_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_RevenueProjection');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_RevenueProjection');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_RevenueProjection_Hist SELECT * from swt_rpt_stg.NO_RevenueProjection;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_RevenueProjection;
