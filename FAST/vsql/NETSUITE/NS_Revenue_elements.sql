/*******
******* Script Name	  : Incr_NS_Revenue_elements.sql
****Description   : Incremental data load for NS_Revenue_elements
****/

/* Setting timing on**/
\timing
/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from swt_rpt_stg.NS_Revenue_elements;

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
select 'NETSUITE','NS_Revenue_elements',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;
INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Revenue_elements_Hist SELECT * from "swt_rpt_stg".NS_Revenue_elements;

CREATE LOCAL TEMP TABLE duplicates_Revenue_elements ON COMMIT PRESERVE ROWS AS 
select max(auto_id) as auto_id,revenue_element_id from swt_rpt_stg.NS_Revenue_elements where revenue_element_id in(
select revenue_element_id from swt_rpt_stg.NS_Revenue_elements
group by revenue_element_id,date_last_modified having count(1)>1)
group by revenue_element_id;

delete from swt_rpt_stg.NS_Revenue_elements  where exists(
select 1 from duplicates_Revenue_elements t2 where swt_rpt_stg.NS_Revenue_elements.revenue_element_id=t2.revenue_element_id and swt_rpt_stg.NS_Revenue_elements.auto_id<t2.auto_id);

COMMIT;

CREATE LOCAL TEMP TABLE NS_Revenue_elements_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Revenue_elements)
SEGMENTED BY HASH(revenue_element_id,date_last_modified) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.NS_Revenue_elements;


CREATE LOCAL TEMP TABLE NS_Revenue_elements_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT revenue_element_id,date_last_modified FROM swt_rpt_base.NS_Revenue_elements)
SEGMENTED BY HASH(revenue_element_id,date_last_modified) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Revenue_elements_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT revenue_element_id, max(date_last_modified) as date_last_modified FROM NS_Revenue_elements_stg_Tmp group by revenue_element_id)
SEGMENTED BY HASH(revenue_element_id,date_last_modified) ALL NODES;




/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Revenue_elements_Hist
(
accounting_book_id
,accounting_period_id
,allocated_contract_cost_amount
,allocation_amount
,allocation_amount_foreign
,allocation_type
,alternate_quantity
,alternate_unit_id
,amortization_end_date
,amortization_schedule_id
,amortization_start_date
,amortization_template_id
,calculated_amount
,calculated_amount_foreign
,class_id
,contract_cost_allocation_pct
,contract_exp_offset_acct_id
,contract_expense_account_id
,cost_amortization_amount
,create_plan_on_event_type
,currency_id
,date_created
,date_last_modified
,deferral_account_id
,department_id
,disc_sales_amount_foreign
,discounted_sales_amount
,end_date
,entity_id
,exchange_rate
,fair_value
,fair_value_foreign
,forecast_end_date
,forecast_start_date
,is_bom_item_type
,is_fair_value_override
,is_fair_value_vsoe
,is_hold_rev_rec
,is_permit_discount
,is_posting_discount_applied
,item_id
,item_labor_cost_amount
,item_resale_cost_amount
,labor_deferred_expense_acct_id
,labor_expense_acct_id
,last_merge_from_arrangement_id
,location_id
,new_standard_migrate_date
,parent_bom_element_id
,pending_action
,quantity
,recognition_account_id
,reference_id
,return_revenue_element_id
,rev_rec_forecast_rule_id
,rev_rec_rule_id
,revenue_allocation_group
,revenue_allocation_ratio
,revenue_element_id
,revenue_element_number
,sales_amount
,sales_amount_foreign
,source_date
,source_id
,source_transaction_id
,source_type
,start_date
,subsidiary_id
,term_in_days
,term_in_months
,expense_migrate_adjust_acct_id
,fx_adjustment_account_id
,revenue_migrate_adjust_acct_id
,unbilled_receivable_group
,LD_DT
,SWT_INS_DT
,d_source
,SWT_Ins_Date_Backup
)
select
accounting_book_id
,accounting_period_id
,allocated_contract_cost_amount
,allocation_amount
,allocation_amount_foreign
,allocation_type
,alternate_quantity
,alternate_unit_id
,amortization_end_date
,amortization_schedule_id
,amortization_start_date
,amortization_template_id
,calculated_amount
,calculated_amount_foreign
,class_id
,contract_cost_allocation_pct
,contract_exp_offset_acct_id
,contract_expense_account_id
,cost_amortization_amount
,create_plan_on_event_type
,currency_id
,date_created
,date_last_modified
,deferral_account_id
,department_id
,disc_sales_amount_foreign
,discounted_sales_amount
,end_date
,entity_id
,exchange_rate
,fair_value
,fair_value_foreign
,forecast_end_date
,forecast_start_date
,is_bom_item_type
,is_fair_value_override
,is_fair_value_vsoe
,is_hold_rev_rec
,is_permit_discount
,is_posting_discount_applied
,item_id
,item_labor_cost_amount
,item_resale_cost_amount
,labor_deferred_expense_acct_id
,labor_expense_acct_id
,last_merge_from_arrangement_id
,location_id
,new_standard_migrate_date
,parent_bom_element_id
,pending_action
,quantity
,recognition_account_id
,reference_id
,return_revenue_element_id
,rev_rec_forecast_rule_id
,rev_rec_rule_id
,revenue_allocation_group
,revenue_allocation_ratio
,revenue_element_id
,revenue_element_number
,sales_amount
,sales_amount_foreign
,source_date
,source_id
,source_transaction_id
,source_type
,start_date
,subsidiary_id
,term_in_days
,term_in_months
,expense_migrate_adjust_acct_id
,fx_adjustment_account_id
,revenue_migrate_adjust_acct_id
,unbilled_receivable_group
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
,SWT_Ins_Date_Backup
FROM "swt_rpt_base".NS_Revenue_elements WHERE revenue_element_id in
(SELECT STG.revenue_element_id FROM NS_Revenue_elements_stg_Tmp_Key STG JOIN NS_Revenue_elements_base_Tmp
ON STG.revenue_element_id = NS_Revenue_elements_base_Tmp.revenue_element_id AND STG.date_last_modified >= NS_Revenue_elements_base_Tmp.date_last_modified);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Revenue_elements_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Revenue_elements WHERE revenue_element_id in
(SELECT STG.revenue_element_id FROM NS_Revenue_elements_stg_Tmp_Key STG JOIN NS_Revenue_elements_base_Tmp
ON STG.revenue_element_id = NS_Revenue_elements_base_Tmp.revenue_element_id AND STG.date_last_modified >= NS_Revenue_elements_base_Tmp.date_last_modified);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Revenue_elements
(
accounting_book_id
,accounting_period_id
,allocated_contract_cost_amount
,allocation_amount
,allocation_amount_foreign
,allocation_type
,alternate_quantity
,alternate_unit_id
,amortization_end_date
,amortization_schedule_id
,amortization_start_date
,amortization_template_id
,calculated_amount
,calculated_amount_foreign
,class_id
,contract_cost_allocation_pct
,contract_exp_offset_acct_id
,contract_expense_account_id
,cost_amortization_amount
,create_plan_on_event_type
,currency_id
,date_created
,date_last_modified
,deferral_account_id
,department_id
,disc_sales_amount_foreign
,discounted_sales_amount
,end_date
,entity_id
,exchange_rate
,fair_value
,fair_value_foreign
,forecast_end_date
,forecast_start_date
,is_bom_item_type
,is_fair_value_override
,is_fair_value_vsoe
,is_hold_rev_rec
,is_permit_discount
,is_posting_discount_applied
,item_id
,item_labor_cost_amount
,item_resale_cost_amount
,labor_deferred_expense_acct_id
,labor_expense_acct_id
,last_merge_from_arrangement_id
,location_id
,new_standard_migrate_date
,parent_bom_element_id
,pending_action
,quantity
,recognition_account_id
,reference_id
,return_revenue_element_id
,rev_rec_forecast_rule_id
,rev_rec_rule_id
,revenue_allocation_group
,revenue_allocation_ratio
,revenue_element_id
,revenue_element_number
,sales_amount
,sales_amount_foreign
,source_date
,source_id
,source_transaction_id
,source_type
,start_date
,subsidiary_id
,term_in_days
,term_in_months
,expense_migrate_adjust_acct_id
,fx_adjustment_account_id
,revenue_migrate_adjust_acct_id
,unbilled_receivable_group
,SWT_INS_DT
,SWT_Ins_Date_Backup
)
SELECT DISTINCT
accounting_book_id
,accounting_period_id
,allocated_contract_cost_amount
,allocation_amount
,allocation_amount_foreign
,allocation_type
,alternate_quantity
,alternate_unit_id
,amortization_end_date
,amortization_schedule_id
,amortization_start_date
,amortization_template_id
,calculated_amount
,calculated_amount_foreign
,class_id
,contract_cost_allocation_pct
,contract_exp_offset_acct_id
,contract_expense_account_id
,cost_amortization_amount
,create_plan_on_event_type
,currency_id
,date_created
,NS_Revenue_elements_stg_Tmp.date_last_modified
,deferral_account_id
,department_id
,disc_sales_amount_foreign
,discounted_sales_amount
,end_date
,entity_id
,exchange_rate
,fair_value
,fair_value_foreign
,forecast_end_date
,forecast_start_date
,is_bom_item_type
,is_fair_value_override
,is_fair_value_vsoe
,is_hold_rev_rec
,is_permit_discount
,is_posting_discount_applied
,item_id
,item_labor_cost_amount
,item_resale_cost_amount
,labor_deferred_expense_acct_id
,labor_expense_acct_id
,last_merge_from_arrangement_id
,location_id
,new_standard_migrate_date
,parent_bom_element_id
,pending_action
,quantity
,recognition_account_id
,reference_id
,return_revenue_element_id
,rev_rec_forecast_rule_id
,rev_rec_rule_id
,revenue_allocation_group
,revenue_allocation_ratio
,NS_Revenue_elements_stg_Tmp.revenue_element_id
,revenue_element_number
,sales_amount
,sales_amount_foreign
,source_date
,source_id
,source_transaction_id
,source_type
,start_date
,subsidiary_id
,term_in_days
,term_in_months
,expense_migrate_adjust_acct_id
,fx_adjustment_account_id
,revenue_migrate_adjust_acct_id
,unbilled_receivable_group
,sysdate as SWT_INS_DT
,sysdate as SWT_Ins_Date_Backup
FROM NS_Revenue_elements_stg_Tmp JOIN NS_Revenue_elements_stg_Tmp_Key ON NS_Revenue_elements_stg_Tmp.revenue_element_id= NS_Revenue_elements_stg_Tmp_Key.revenue_element_id AND NS_Revenue_elements_stg_Tmp.date_last_modified=NS_Revenue_elements_stg_Tmp_Key.date_last_modified
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Revenue_elements BASE
WHERE NS_Revenue_elements_stg_Tmp.revenue_element_id = BASE.revenue_element_id);

COMMIT;

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
select 'NETSUITE','NS_Revenue_elements',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Revenue_elements where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

CREATE LOCAL TEMP TABLE Start_Time_Tmp_Id ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from swt_rpt_stg.NS_Revenue_elements_Id;

/* Inserting values into Audit table for ID table */

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
select 'NETSUITE','NS_Revenue_elements_Id',sysdate::date,sysdate,null,(select count from Start_Time_Tmp_Id) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_Revenue_elements_ID
( revenue_element_id,
SWT_INS_DT
)
SELECT
revenue_element_id,
SYSDATE
FROM swt_rpt_stg.NS_Revenue_elements_ID;


CREATE LOCAL TEMP TABLE NS_Revenue_elements_base_deleted ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_base.NS_Revenue_elements where Is_Deleted <> 'true' and revenue_element_id not in ( select distinct revenue_element_id from swt_rpt_stg.NS_Revenue_elements_Id))
SEGMENTED BY HASH(revenue_element_id) ALL NODES;

DELETE /*+DIRECT*/ FROM swt_rpt_base.NS_Revenue_elements where Is_Deleted <> 'true' and revenue_element_id  in ( select distinct revenue_element_id from NS_Revenue_elements_base_deleted);

INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_Revenue_elements_Deleted_Ids
( revenue_element_id,
SWT_INS_DT,
status
)
SELECT
revenue_element_id,
SYSDATE,
'deleted'
FROM NS_Revenue_elements_base_deleted;


INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_Revenue_elements
(
accounting_book_id,
accounting_period_id,
allocated_contract_cost_amount,
allocation_amount,
allocation_amount_foreign,
allocation_type,
alternate_quantity,
alternate_unit_id,
amortization_end_date,
amortization_schedule_id,
amortization_start_date,
amortization_template_id,
calculated_amount,
calculated_amount_foreign,
class_id,
contract_cost_allocation_pct,
contract_exp_offset_acct_id,
contract_expense_account_id,
cost_amortization_amount,
create_plan_on_event_type,
currency_id,
date_created,
date_last_modified,
deferral_account_id,
department_id,
disc_sales_amount_foreign,
discounted_sales_amount,
end_date,
entity_id,
exchange_rate,
fair_value,
fair_value_foreign,
forecast_end_date,
forecast_start_date,
is_bom_item_type,
is_fair_value_override,
is_fair_value_vsoe,
is_hold_rev_rec,
is_permit_discount,
is_posting_discount_applied,
item_id,
item_labor_cost_amount,
item_resale_cost_amount,
labor_deferred_expense_acct_id,
labor_expense_acct_id,
last_merge_from_arrangement_id,
location_id,
new_standard_migrate_date,
parent_bom_element_id,
pending_action,
quantity,
recognition_account_id,
reference_id,
return_revenue_element_id,
rev_rec_forecast_rule_id,
rev_rec_rule_id,
revenue_allocation_group,
revenue_allocation_ratio,
revenue_element_id,
revenue_element_number,
sales_amount,
sales_amount_foreign,
source_date,
source_id,
source_transaction_id,
source_type,
start_date,
subsidiary_id,
term_in_days,
term_in_months,
unbilled_receivable_group,
expense_migrate_adjust_acct_id,
fx_adjustment_account_id,
revenue_migrate_adjust_acct_id,
SWT_INS_DT,
Is_Deleted,
SWT_Ins_Date_Backup
)
SELECT 
accounting_book_id,
accounting_period_id,
allocated_contract_cost_amount,
allocation_amount,
allocation_amount_foreign,
allocation_type,
alternate_quantity,
alternate_unit_id,
amortization_end_date,
amortization_schedule_id,
amortization_start_date,
amortization_template_id,
calculated_amount,
calculated_amount_foreign,
class_id,
contract_cost_allocation_pct,
contract_exp_offset_acct_id,
contract_expense_account_id,
cost_amortization_amount,
create_plan_on_event_type,
currency_id,
date_created,
date_last_modified,
deferral_account_id,
department_id,
disc_sales_amount_foreign,
discounted_sales_amount,
end_date,
entity_id,
exchange_rate,
fair_value,
fair_value_foreign,
forecast_end_date,
forecast_start_date,
is_bom_item_type,
is_fair_value_override,
is_fair_value_vsoe,
is_hold_rev_rec,
is_permit_discount,
is_posting_discount_applied,
item_id,
item_labor_cost_amount,
item_resale_cost_amount,
labor_deferred_expense_acct_id,
labor_expense_acct_id,
last_merge_from_arrangement_id,
location_id,
new_standard_migrate_date,
parent_bom_element_id,
pending_action,
quantity,
recognition_account_id,
reference_id,
return_revenue_element_id,
rev_rec_forecast_rule_id,
rev_rec_rule_id,
revenue_allocation_group,
revenue_allocation_ratio,
revenue_element_id,
revenue_element_number,
sales_amount,
sales_amount_foreign,
source_date,
source_id,
source_transaction_id,
source_type,
start_date,
subsidiary_id,
term_in_days,
term_in_months,
unbilled_receivable_group,
expense_migrate_adjust_acct_id,
fx_adjustment_account_id,
revenue_migrate_adjust_acct_id,
sysdate as SWT_INS_DT
,'true'
,SWT_INS_DT
FROM NS_Revenue_elements_base_deleted;

CREATE LOCAL TEMP TABLE NS_Revenue_elements_base_active ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_base.NS_Revenue_elements where Is_Deleted ='true' and revenue_element_id in ( select distinct revenue_element_id from swt_rpt_stg.NS_Revenue_elements_Id))
SEGMENTED BY HASH(revenue_element_id) ALL NODES;

DELETE /*+DIRECT*/ FROM swt_rpt_base.NS_Revenue_elements where Is_Deleted ='true' and revenue_element_id in ( select distinct revenue_element_id from NS_Revenue_elements_base_active);

INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_Revenue_elements_Deleted_Ids
( revenue_element_id,
SWT_INS_DT,
status
)
SELECT
revenue_element_id,
SYSDATE,
'activated'
FROM NS_Revenue_elements_base_active;


INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_Revenue_elements
(
accounting_book_id,
accounting_period_id,
allocated_contract_cost_amount,
allocation_amount,
allocation_amount_foreign,
allocation_type,
alternate_quantity,
alternate_unit_id,
amortization_end_date,
amortization_schedule_id,
amortization_start_date,
amortization_template_id,
calculated_amount,
calculated_amount_foreign,
class_id,
contract_cost_allocation_pct,
contract_exp_offset_acct_id,
contract_expense_account_id,
cost_amortization_amount,
create_plan_on_event_type,
currency_id,
date_created,
date_last_modified,
deferral_account_id,
department_id,
disc_sales_amount_foreign,
discounted_sales_amount,
end_date,
entity_id,
exchange_rate,
fair_value,
fair_value_foreign,
forecast_end_date,
forecast_start_date,
is_bom_item_type,
is_fair_value_override,
is_fair_value_vsoe,
is_hold_rev_rec,
is_permit_discount,
is_posting_discount_applied,
item_id,
item_labor_cost_amount,
item_resale_cost_amount,
labor_deferred_expense_acct_id,
labor_expense_acct_id,
last_merge_from_arrangement_id,
location_id,
new_standard_migrate_date,
parent_bom_element_id,
pending_action,
quantity,
recognition_account_id,
reference_id,
return_revenue_element_id,
rev_rec_forecast_rule_id,
rev_rec_rule_id,
revenue_allocation_group,
revenue_allocation_ratio,
revenue_element_id,
revenue_element_number,
sales_amount,
sales_amount_foreign,
source_date,
source_id,
source_transaction_id,
source_type,
start_date,
subsidiary_id,
term_in_days,
term_in_months,
unbilled_receivable_group,
expense_migrate_adjust_acct_id,
fx_adjustment_account_id,
revenue_migrate_adjust_acct_id,
SWT_INS_DT,
Is_Deleted,
SWT_Ins_Date_Backup
)
SELECT 
accounting_book_id,
accounting_period_id,
allocated_contract_cost_amount,
allocation_amount,
allocation_amount_foreign,
allocation_type,
alternate_quantity,
alternate_unit_id,
amortization_end_date,
amortization_schedule_id,
amortization_start_date,
amortization_template_id,
calculated_amount,
calculated_amount_foreign,
class_id,
contract_cost_allocation_pct,
contract_exp_offset_acct_id,
contract_expense_account_id,
cost_amortization_amount,
create_plan_on_event_type,
currency_id,
date_created,
date_last_modified,
deferral_account_id,
department_id,
disc_sales_amount_foreign,
discounted_sales_amount,
end_date,
entity_id,
exchange_rate,
fair_value,
fair_value_foreign,
forecast_end_date,
forecast_start_date,
is_bom_item_type,
is_fair_value_override,
is_fair_value_vsoe,
is_hold_rev_rec,
is_permit_discount,
is_posting_discount_applied,
item_id,
item_labor_cost_amount,
item_resale_cost_amount,
labor_deferred_expense_acct_id,
labor_expense_acct_id,
last_merge_from_arrangement_id,
location_id,
new_standard_migrate_date,
parent_bom_element_id,
pending_action,
quantity,
recognition_account_id,
reference_id,
return_revenue_element_id,
rev_rec_forecast_rule_id,
rev_rec_rule_id,
revenue_allocation_group,
revenue_allocation_ratio,
revenue_element_id,
revenue_element_number,
sales_amount,
sales_amount_foreign,
source_date,
source_id,
source_transaction_id,
source_type,
start_date,
subsidiary_id,
term_in_days,
term_in_months,
unbilled_receivable_group,
expense_migrate_adjust_acct_id,
fx_adjustment_account_id,
revenue_migrate_adjust_acct_id,
sysdate as SWT_INS_DT,
'false',
SWT_INS_DT
FROM NS_Revenue_elements_base_active;


COMMIT;


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Revenue_elements' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Revenue_elements' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Revenue_elements_Id',sysdate::date,(select st from Start_Time_Tmp_Id),sysdate,(select count from Start_Time_Tmp_Id) ,(select count(*) from swt_rpt_base.NS_Revenue_elements where SWT_INS_DT>=(select max(START_DT_TIME) from swt_rpt_stg.FAST_LD_AUDT where TBL_NM='NS_Revenue_elements_Id') and is_deleted='true'),'Y';

Commit;

SELECT DO_TM_TASK('mergeout', 'swt_rpt_base.NS_Revenue_elements');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.NS_Revenue_elements_Hist');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Revenue_elements');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Revenue_elements_deleted_IDS');
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TRUNCATE TABLE swt_rpt_stg.NS_Revenue_elements_Id;
delete /*+DIRECT*/ from "swt_rpt_base"."NS_Revenue_elements_id"  where swt_ins_dt::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;
commit;
--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<





