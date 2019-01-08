/****
****Script Name	  : NS_Fam_Asset.sql
****Description   : Incremental data load for NS_Fam_Asset
****/


/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Fam_Asset";

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
select 'NETSUITE','NS_Fam_Asset',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Fam_Asset_Hist SELECT * from "swt_rpt_stg".NS_Fam_Asset;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select fam_asset_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Fam_Asset where fam_asset_id in (
select fam_asset_id from swt_rpt_stg.NS_Fam_Asset group by fam_asset_id,last_modified_date having count(1)>1)
group by fam_asset_id);

delete from swt_rpt_stg.NS_Fam_Asset where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Fam_Asset.fam_asset_id=t2.fam_asset_id and swt_rpt_stg.NS_Fam_Asset.auto_id<t2. auto_id);

COMMIT;

CREATE LOCAL TEMP TABLE NS_Fam_Asset_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Fam_Asset)
SEGMENTED BY HASH(fam_asset_id,last_modified_date) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.NS_Fam_Asset;

CREATE LOCAL TEMP TABLE NS_Fam_Asset_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT fam_asset_id,last_modified_date FROM swt_rpt_base.NS_Fam_Asset)
SEGMENTED BY HASH(fam_asset_id,last_modified_date) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Fam_Asset_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT fam_asset_id, max(last_modified_date) as last_modified_date FROM NS_Fam_Asset_stg_Tmp group by fam_asset_id)
SEGMENTED BY HASH(fam_asset_id,last_modified_date) ALL NODES;



/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Fam_Asset_Hist
(
depreciation_method_id
,acquisition_deprecated
,alternate_asset_number
,annual_method_entry_id
,asset_account_id
,asset_current_cost
,asset_description
,asset_is_leased
,asset_lifetime
,asset_lifetime_usage
,asset_original_cost
,asset_serial_number
,asset_status_id
,asset_type_id
,averaging_convention_id
,balloon_payment_amount
,class_id
,component_of_id
,create_from
,cumulative_depreciation
,current_net_book_value
,custodian_id
,customer_id
,customer_location_id
,date_created
,date_of_manufacture
,department_id
,depreciation_account_id
,depreciation_active_id
,depreciation_charge_account_id
,depreciation_end_date
,depreciation_period_id
,depreciation_rules_id
,depreciation_start_date
,disposal_cost_account_id
,disposal_date
,disposal_item_id
,disposal_reason_id
,disposal_type_id
,fam_asset_extid
,fam_asset_id
,fam_asset_name
,fam_asset_number
,finance_lease_hp
,financial_year_start_id
,first_payment_due_date
,fixed_rate
,functional_area_id
,profit_center_id
,include_in_reports
,initial_lease_cost
,inspection_interval
,inspection_required
,insurance_company_id
,insurance_policy_number
,insurance_value
,interest_rate
,is_compound
,is_inactive
,last_depreciation_amount
,last_depreciation_date
,last_depreciation_period
,last_inspection_date
,last_modified_date
,last_payment_due_date
,lcci_id
,lease_company_id
,lease_contract_number
,lease_end_date
,lease_start_date
,legacy_asset_number
,location_id
,maintenance_company_id
,maintenance_contract
,manufacturer
,next_inspection_date
,parent_asset_id
,parent_id
,parent_transaction_id
,payment_amount
,payment_frequency
,period_convention_id
,physical_location
,physical_location_code_id
,policy_end_date
,policy_start_date
,prior_year_nbv
,project_id
,proposal_id
,purchase_date
,purchase_order_id
,quantity
,quantity_disposed
,rental_amount
,rental_frequency
,repair__maintenance_categor_id
,repair__maint_subcategory_a_id
,repair__maint_subcategory_b_id
,residual_value
,residual_value_percentage
,revision_rules_id
,sales_amount
,sales_invoice_id
,ship_to_address
,store_history
,subsidiary_id
,supplier
,target_depreciation_date
,warranty
,warranty_end_date
,warranty_period
,warranty_start_date
,write_down_account_id
,eval_1_tax_code_id
,eval_2_tax_code_id
,invoice_number
,parent_transaction_line
,write_off_account_id
,LD_DT
,SWT_INS_DT
,d_source
)
select
depreciation_method_id
,acquisition_deprecated
,alternate_asset_number
,annual_method_entry_id
,asset_account_id
,asset_current_cost
,asset_description
,asset_is_leased
,asset_lifetime
,asset_lifetime_usage
,asset_original_cost
,asset_serial_number
,asset_status_id
,asset_type_id
,averaging_convention_id
,balloon_payment_amount
,class_id
,component_of_id
,create_from
,cumulative_depreciation
,current_net_book_value
,custodian_id
,customer_id
,customer_location_id
,date_created
,date_of_manufacture
,department_id
,depreciation_account_id
,depreciation_active_id
,depreciation_charge_account_id
,depreciation_end_date
,depreciation_period_id
,depreciation_rules_id
,depreciation_start_date
,disposal_cost_account_id
,disposal_date
,disposal_item_id
,disposal_reason_id
,disposal_type_id
,fam_asset_extid
,fam_asset_id
,fam_asset_name
,fam_asset_number
,finance_lease_hp
,financial_year_start_id
,first_payment_due_date
,fixed_rate
,functional_area_id
,profit_center_id
,include_in_reports
,initial_lease_cost
,inspection_interval
,inspection_required
,insurance_company_id
,insurance_policy_number
,insurance_value
,interest_rate
,is_compound
,is_inactive
,last_depreciation_amount
,last_depreciation_date
,last_depreciation_period
,last_inspection_date
,last_modified_date
,last_payment_due_date
,lcci_id
,lease_company_id
,lease_contract_number
,lease_end_date
,lease_start_date
,legacy_asset_number
,location_id
,maintenance_company_id
,maintenance_contract
,manufacturer
,next_inspection_date
,parent_asset_id
,parent_id
,parent_transaction_id
,payment_amount
,payment_frequency
,period_convention_id
,physical_location
,physical_location_code_id
,policy_end_date
,policy_start_date
,prior_year_nbv
,project_id
,proposal_id
,purchase_date
,purchase_order_id
,quantity
,quantity_disposed
,rental_amount
,rental_frequency
,repair__maintenance_categor_id
,repair__maint_subcategory_a_id
,repair__maint_subcategory_b_id
,residual_value
,residual_value_percentage
,revision_rules_id
,sales_amount
,sales_invoice_id
,ship_to_address
,store_history
,subsidiary_id
,supplier
,target_depreciation_date
,warranty
,warranty_end_date
,warranty_period
,warranty_start_date
,write_down_account_id
,eval_1_tax_code_id
,eval_2_tax_code_id
,invoice_number
,parent_transaction_line
,write_off_account_id
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Fam_Asset WHERE fam_asset_id in 
(SELECT STG.fam_asset_id FROM NS_Fam_Asset_stg_Tmp_Key STG JOIN NS_Fam_Asset_base_Tmp
ON STG.fam_asset_id = NS_Fam_Asset_base_Tmp.fam_asset_id AND STG.last_modified_date >= NS_Fam_Asset_base_Tmp.last_modified_date);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Fam_Asset_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */


DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Fam_Asset WHERE fam_asset_id in
(SELECT STG.fam_asset_id FROM NS_Fam_Asset_stg_Tmp_Key STG JOIN NS_Fam_Asset_base_Tmp
ON STG.fam_asset_id = NS_Fam_Asset_base_Tmp.fam_asset_id AND STG.last_modified_date >= NS_Fam_Asset_base_Tmp.last_modified_date);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Fam_Asset
(
depreciation_method_id
,acquisition_deprecated
,alternate_asset_number
,annual_method_entry_id
,asset_account_id
,asset_current_cost
,asset_description
,asset_is_leased
,asset_lifetime
,asset_lifetime_usage
,asset_original_cost
,asset_serial_number
,asset_status_id
,asset_type_id
,averaging_convention_id
,balloon_payment_amount
,class_id
,component_of_id
,create_from
,cumulative_depreciation
,current_net_book_value
,custodian_id
,customer_id
,customer_location_id
,date_created
,date_of_manufacture
,department_id
,depreciation_account_id
,depreciation_active_id
,depreciation_charge_account_id
,depreciation_end_date
,depreciation_period_id
,depreciation_rules_id
,depreciation_start_date
,disposal_cost_account_id
,disposal_date
,disposal_item_id
,disposal_reason_id
,disposal_type_id
,fam_asset_extid
,fam_asset_id
,fam_asset_name
,fam_asset_number
,finance_lease_hp
,financial_year_start_id
,first_payment_due_date
,fixed_rate
,functional_area_id
,profit_center_id
,include_in_reports
,initial_lease_cost
,inspection_interval
,inspection_required
,insurance_company_id
,insurance_policy_number
,insurance_value
,interest_rate
,is_compound
,is_inactive
,last_depreciation_amount
,last_depreciation_date
,last_depreciation_period
,last_inspection_date
,last_modified_date
,last_payment_due_date
,lcci_id
,lease_company_id
,lease_contract_number
,lease_end_date
,lease_start_date
,legacy_asset_number
,location_id
,maintenance_company_id
,maintenance_contract
,manufacturer
,next_inspection_date
,parent_asset_id
,parent_id
,parent_transaction_id
,payment_amount
,payment_frequency
,period_convention_id
,physical_location
,physical_location_code_id
,policy_end_date
,policy_start_date
,prior_year_nbv
,project_id
,proposal_id
,purchase_date
,purchase_order_id
,quantity
,quantity_disposed
,rental_amount
,rental_frequency
,repair__maintenance_categor_id
,repair__maint_subcategory_a_id
,repair__maint_subcategory_b_id
,residual_value
,residual_value_percentage
,revision_rules_id
,sales_amount
,sales_invoice_id
,ship_to_address
,store_history
,subsidiary_id
,supplier
,target_depreciation_date
,warranty
,warranty_end_date
,warranty_period
,warranty_start_date
,write_down_account_id
,eval_1_tax_code_id
,eval_2_tax_code_id
,invoice_number
,parent_transaction_line
,write_off_account_id
,SWT_INS_DT
)
SELECT DISTINCT
depreciation_method_id
,acquisition_deprecated
,alternate_asset_number
,annual_method_entry_id
,asset_account_id
,asset_current_cost
,asset_description
,asset_is_leased
,asset_lifetime
,asset_lifetime_usage
,asset_original_cost
,asset_serial_number
,asset_status_id
,asset_type_id
,averaging_convention_id
,balloon_payment_amount
,class_id
,component_of_id
,create_from
,cumulative_depreciation
,current_net_book_value
,custodian_id
,customer_id
,customer_location_id
,date_created
,date_of_manufacture
,department_id
,depreciation_account_id
,depreciation_active_id
,depreciation_charge_account_id
,depreciation_end_date
,depreciation_period_id
,depreciation_rules_id
,depreciation_start_date
,disposal_cost_account_id
,disposal_date
,disposal_item_id
,disposal_reason_id
,disposal_type_id
,fam_asset_extid
,NS_Fam_Asset_stg_Tmp.fam_asset_id
,fam_asset_name
,fam_asset_number
,finance_lease_hp
,financial_year_start_id
,first_payment_due_date
,fixed_rate
,functional_area_id
,profit_center_id
,include_in_reports
,initial_lease_cost
,inspection_interval
,inspection_required
,insurance_company_id
,insurance_policy_number
,insurance_value
,interest_rate
,is_compound
,is_inactive
,last_depreciation_amount
,last_depreciation_date
,last_depreciation_period
,last_inspection_date
,NS_Fam_Asset_stg_Tmp.last_modified_date
,last_payment_due_date
,lcci_id
,lease_company_id
,lease_contract_number
,lease_end_date
,lease_start_date
,legacy_asset_number
,location_id
,maintenance_company_id
,maintenance_contract
,manufacturer
,next_inspection_date
,parent_asset_id
,parent_id
,parent_transaction_id
,payment_amount
,payment_frequency
,period_convention_id
,physical_location
,physical_location_code_id
,policy_end_date
,policy_start_date
,prior_year_nbv
,project_id
,proposal_id
,purchase_date
,purchase_order_id
,quantity
,quantity_disposed
,rental_amount
,rental_frequency
,repair__maintenance_categor_id
,repair__maint_subcategory_a_id
,repair__maint_subcategory_b_id
,residual_value
,residual_value_percentage
,revision_rules_id
,sales_amount
,sales_invoice_id
,ship_to_address
,store_history
,subsidiary_id
,supplier
,target_depreciation_date
,warranty
,warranty_end_date
,warranty_period
,warranty_start_date
,write_down_account_id
,eval_1_tax_code_id
,eval_2_tax_code_id
,invoice_number
,parent_transaction_line
,write_off_account_id
,SYSDATE AS SWT_INS_DT
FROM NS_Fam_Asset_stg_Tmp JOIN NS_Fam_Asset_stg_Tmp_Key ON NS_Fam_Asset_stg_Tmp.fam_asset_id= NS_Fam_Asset_stg_Tmp_Key.fam_asset_id AND NS_Fam_Asset_stg_Tmp.last_modified_date=NS_Fam_Asset_stg_Tmp_Key.last_modified_date
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Fam_Asset BASE
WHERE NS_Fam_Asset_stg_Tmp.fam_asset_id = BASE.fam_asset_id);

/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Fam_Asset' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Fam_Asset' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Fam_Asset',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Fam_Asset where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

SELECT DO_TM_TASK('mergeout', 'swt_rpt_base.NS_Fam_Asset');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.NS_Fam_Asset_Hist');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Fam_Asset');


