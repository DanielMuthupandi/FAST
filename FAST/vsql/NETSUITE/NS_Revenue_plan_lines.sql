/******
**** Script Name	  : NS_Revenue_plan_lines.sql
****Description   : Incremental data load for NS_Revenue_plan_lines
****/
/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Revenue_plan_lines";

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
select 'NETSUITE','NS_Revenue_plan_lines',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Revenue_plan_lines_Hist SELECT * from "swt_rpt_stg".NS_Revenue_plan_lines;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select plan_id,accounting_period_id,isnull(journal_id,1) as journal_id ,max(auto_id) as auto_id from swt_rpt_stg.NS_Revenue_plan_lines where (plan_id,accounting_period_id,isnull(journal_id,1)) in (
select plan_id,accounting_period_id,isnull(journal_id,1) from swt_rpt_stg.NS_Revenue_plan_lines group by plan_id,accounting_period_id,isnull(journal_id,1),date_last_modified having count(1)>1)
group by plan_id,accounting_period_id,isnull(journal_id,1));


delete from swt_rpt_stg.NS_Revenue_plan_lines  where exists(
select 1  from duplicates_records t2 where swt_rpt_stg.NS_Revenue_plan_lines.plan_id=t2.plan_id 
and  swt_rpt_stg.NS_Revenue_plan_lines.accounting_period_id=t2.accounting_period_id 
and isnull(swt_rpt_stg.NS_Revenue_plan_lines.journal_id,1) =t2.journal_id
and swt_rpt_stg.NS_Revenue_plan_lines.auto_id<t2.auto_id);

COMMIT;

CREATE LOCAL TEMP TABLE NS_Revenue_plan_lines_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Revenue_plan_lines)
SEGMENTED BY HASH(plan_id,accounting_period_id,journal_id,date_last_modified) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.NS_Revenue_plan_lines;

CREATE LOCAL TEMP TABLE NS_Revenue_plan_lines_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT plan_id,accounting_period_id,journal_id,date_last_modified FROM swt_rpt_base.NS_Revenue_plan_lines)
SEGMENTED BY HASH(plan_id,accounting_period_id,journal_id,date_last_modified) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Revenue_plan_lines_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT plan_id,accounting_period_id,journal_id, max(date_last_modified) as date_last_modified FROM NS_Revenue_plan_lines_stg_Tmp group by plan_id,accounting_period_id,journal_id)
SEGMENTED BY HASH(plan_id,accounting_period_id,journal_id,date_last_modified) ALL NODES;



/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Revenue_plan_lines_Hist
(
accounting_period_id
,additional_discount_
,additional_discount_amount
,adjustment_field
,adjustment_tax_code_id
,amount
,appliance_drop_ship_po_
,apply_wh_tax
,asset_id
,authority_currency_code
,billable_engagement_name
,billable_expense_category
,billable_expense_engagement
,billable_item_name
,billable_units_of_measure
,billing_frequency_id
,bill_of_lading_number
,booking_date
,box_number
,charge_type_id
,code_of_supply_id
,contractual_discount_
,contractual_discount_amount
,contract_end_date
,contract_start_date
,contract_term
,course_type_id
,date_created
,date_last_modified
,deferral_account_id
,display_quantity
,employee_token_id
,end_user_id
,eu_triangulation
,exempt_id
,expense_account_id
,export_to_openair
,fixed_asset_id
,functional_area_id
,goods_and_services_indicato_id
,gross_list_price
,custom_functional_area_id
,custom_lcci_id
,custom_profit_center_id
,ic_item
,ic_je_number_id
,idt_product_tax_code
,intercompany
,intercompany_discount_
,is_recognized
,je_expense_type
,journal_id
,jurisdiction_text
,lcci_id
,line_item_id
,markup_amount
,notc_id
,openair_assigned_users
,openair_billing_rule_id
,openair_charge_type_id
,openair_expense_report_line_i
,openair_gsthst
,openair_invoice_line_id
,openair_journal_entry_creatio
,openair_journal_entry_error
,openair_journal_entry_error_m
,openair_line_from_openair
,openair_loaded_cost_class_id
,openair_loaded_cost_credit__id
,openair_loaded_cost_debit_a_id
,openair_loaded_cost_departm_id
,openair_loaded_cost_locatio_id
,openair_loaded_cost_subsidi_id
,openair_phases_ancestry
,openair_phase_name
,openair_primary_loaded_cost
,openair_primary_loaded_cost_id
,openair_project_task_id
,openair_project_task_id_numbe
,openair_pst
,openair_quantity_from__invoic
,openair_rate
,openair_rev_rec_rule_id
,openair_secondary_loaded_cost
,openair_secondary_loaded_co_id
,openair_task_assignment_id
,openair_task_assignment_plann
,openair_task_id
,openair_task_name
,openair_tax
,openair_tertiary_loaded_cost
,openair_tertiary_loaded_cos_id
,openair_timesheet_start_date
,openair_time_entry_id
,originator_journal_tran_typ_id
,originator_transaction_intern
,partner_discount_
,partner_discount_amount
,pid
,planned_revenue_type
,plan_id
,pl_id
,posted
,pretax_amt
,pretax_amt_quantity
,product_subtype
,product_type
,profit_center_id
,project_task_type_id
,promotional_discount_
,promotional_discount_amount
,reason_id
,recognition_account_id
,registration_unique_id
,related_asset_id
,related_license_id
,schedule_id
,serial_number
,ship_date
,statistical_procedure_for_p_id
,statistical_procedure_for_s_id
,statistical_value
,statistical_value__base_curre
,task_type_id
,tax_amt
,tax_exemption_reason_code_id
,tax_rate
,tax_rate_code
,tax_type
,trade_discount_
,trade_item_code_id
,trade_item_description
,user_quantity
,vendor_tax
,vsoe_customer_type_id
,vsoe_deal_size_id
,vsoe_geography_id
,vsoe_lower_band_
,vsoe_pricing_method_id
,vsoe_related_line_item_number
,vsoe_upper_band_
,wdem_settlement_id
,withholding_tax_amount
,withholding_tax_amount__expen
,withholding_tax_base_amount
,withholding_tax_base_amount__
,withholding_tax_code_id
,withholding_tax_code__expen_id
,withholding_tax_line
,withholding_tax_line__expense
,withholding_tax_rate
,withholding_tax_rate__expense
,wt_customer_id
,wt_employee_id
,wt_vendor_id
,apttus_line_id
,apttus_order_
,apttus_order_id
,billing_plan_id
,ela_agreement_name
,item_id
,item_name
,item_units_name
,legacy_equipment_
,legacy_sales_doc_id
,mark_up_
,nibs_id
,po_
,product_revenue_subtype
,revenue_element_id
,unit_list_price
,uplift_
,uplift_amount
,CREDIT_REBILL_REQUIRES_UNBILL
,PRODUCT_SUBTYPE_EXTERNAL_ID
,PRODUCT_TYPE_EXTERNAL_ID
,REBILLED_LINE
,SWT_INS_DT
,LD_DT
,d_source
)
select
accounting_period_id
,additional_discount_
,additional_discount_amount
,adjustment_field
,adjustment_tax_code_id
,amount
,appliance_drop_ship_po_
,apply_wh_tax
,asset_id
,authority_currency_code
,billable_engagement_name
,billable_expense_category
,billable_expense_engagement
,billable_item_name
,billable_units_of_measure
,billing_frequency_id
,bill_of_lading_number
,booking_date
,box_number
,charge_type_id
,code_of_supply_id
,contractual_discount_
,contractual_discount_amount
,contract_end_date
,contract_start_date
,contract_term
,course_type_id
,date_created
,date_last_modified
,deferral_account_id
,display_quantity
,employee_token_id
,end_user_id
,eu_triangulation
,exempt_id
,expense_account_id
,export_to_openair
,fixed_asset_id
,functional_area_id
,goods_and_services_indicato_id
,gross_list_price
,custom_functional_area_id
,custom_lcci_id
,custom_profit_center_id
,ic_item
,ic_je_number_id
,idt_product_tax_code
,intercompany
,intercompany_discount_
,is_recognized
,je_expense_type
,journal_id
,jurisdiction_text
,lcci_id
,line_item_id
,markup_amount
,notc_id
,openair_assigned_users
,openair_billing_rule_id
,openair_charge_type_id
,openair_expense_report_line_i
,openair_gsthst
,openair_invoice_line_id
,openair_journal_entry_creatio
,openair_journal_entry_error
,openair_journal_entry_error_m
,openair_line_from_openair
,openair_loaded_cost_class_id
,openair_loaded_cost_credit__id
,openair_loaded_cost_debit_a_id
,openair_loaded_cost_departm_id
,openair_loaded_cost_locatio_id
,openair_loaded_cost_subsidi_id
,openair_phases_ancestry
,openair_phase_name
,openair_primary_loaded_cost
,openair_primary_loaded_cost_id
,openair_project_task_id
,openair_project_task_id_numbe
,openair_pst
,openair_quantity_from__invoic
,openair_rate
,openair_rev_rec_rule_id
,openair_secondary_loaded_cost
,openair_secondary_loaded_co_id
,openair_task_assignment_id
,openair_task_assignment_plann
,openair_task_id
,openair_task_name
,openair_tax
,openair_tertiary_loaded_cost
,openair_tertiary_loaded_cos_id
,openair_timesheet_start_date
,openair_time_entry_id
,originator_journal_tran_typ_id
,originator_transaction_intern
,partner_discount_
,partner_discount_amount
,pid
,planned_revenue_type
,plan_id
,pl_id
,posted
,pretax_amt
,pretax_amt_quantity
,product_subtype
,product_type
,profit_center_id
,project_task_type_id
,promotional_discount_
,promotional_discount_amount
,reason_id
,recognition_account_id
,registration_unique_id
,related_asset_id
,related_license_id
,schedule_id
,serial_number
,ship_date
,statistical_procedure_for_p_id
,statistical_procedure_for_s_id
,statistical_value
,statistical_value__base_curre
,task_type_id
,tax_amt
,tax_exemption_reason_code_id
,tax_rate
,tax_rate_code
,tax_type
,trade_discount_
,trade_item_code_id
,trade_item_description
,user_quantity
,vendor_tax
,vsoe_customer_type_id
,vsoe_deal_size_id
,vsoe_geography_id
,vsoe_lower_band_
,vsoe_pricing_method_id
,vsoe_related_line_item_number
,vsoe_upper_band_
,wdem_settlement_id
,withholding_tax_amount
,withholding_tax_amount__expen
,withholding_tax_base_amount
,withholding_tax_base_amount__
,withholding_tax_code_id
,withholding_tax_code__expen_id
,withholding_tax_line
,withholding_tax_line__expense
,withholding_tax_rate
,withholding_tax_rate__expense
,wt_customer_id
,wt_employee_id
,wt_vendor_id
,apttus_line_id
,apttus_order_
,apttus_order_id
,billing_plan_id
,ela_agreement_name
,item_id
,item_name
,item_units_name
,legacy_equipment_
,legacy_sales_doc_id
,mark_up_
,nibs_id
,po_
,product_revenue_subtype
,revenue_element_id
,unit_list_price
,uplift_
,uplift_amount
,CREDIT_REBILL_REQUIRES_UNBILL
,PRODUCT_SUBTYPE_EXTERNAL_ID
,PRODUCT_TYPE_EXTERNAL_ID
,REBILLED_LINE
,SWT_INS_DT
,SYSDATE AS LD_DT
,'base'
FROM swt_rpt_base.NS_Revenue_plan_lines WHERE EXISTS
(SELECT 1 FROM NS_Revenue_plan_lines_stg_Tmp_Key STG
WHERE STG.accounting_period_id = NS_Revenue_plan_lines.accounting_period_id AND nvl(STG.journal_id,0) = nvl(NS_Revenue_plan_lines.journal_id,'0') AND STG.plan_id = NS_Revenue_plan_lines.plan_id AND STG.date_last_modified >= NS_Revenue_plan_lines.date_last_modified);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Revenue_plan_lines_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,now())::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Revenue_plan_lines WHERE EXISTS
(SELECT 1 FROM NS_Revenue_plan_lines_stg_Tmp_Key STG
WHERE STG.accounting_period_id = NS_Revenue_plan_lines.accounting_period_id AND nvl(STG.journal_id,0) = nvl(NS_Revenue_plan_lines.journal_id,0) AND STG.plan_id = NS_Revenue_plan_lines.plan_id AND STG.date_last_modified >= NS_Revenue_plan_lines.date_last_modified);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Revenue_plan_lines
(
accounting_period_id
,additional_discount_
,additional_discount_amount
,adjustment_field
,adjustment_tax_code_id
,amount
,appliance_drop_ship_po_
,apply_wh_tax
,asset_id
,authority_currency_code
,billable_engagement_name
,billable_expense_category
,billable_expense_engagement
,billable_item_name
,billable_units_of_measure
,billing_frequency_id
,bill_of_lading_number
,booking_date
,box_number
,charge_type_id
,code_of_supply_id
,contractual_discount_
,contractual_discount_amount
,contract_end_date
,contract_start_date
,contract_term
,course_type_id
,date_created
,date_last_modified
,deferral_account_id
,display_quantity
,employee_token_id
,end_user_id
,eu_triangulation
,exempt_id
,expense_account_id
,export_to_openair
,fixed_asset_id
,functional_area_id
,goods_and_services_indicato_id
,gross_list_price
,custom_functional_area_id
,custom_lcci_id
,custom_profit_center_id
,ic_item
,ic_je_number_id
,idt_product_tax_code
,intercompany
,intercompany_discount_
,is_recognized
,je_expense_type
,journal_id
,jurisdiction_text
,lcci_id
,line_item_id
,markup_amount
,notc_id
,openair_assigned_users
,openair_billing_rule_id
,openair_charge_type_id
,openair_expense_report_line_i
,openair_gsthst
,openair_invoice_line_id
,openair_journal_entry_creatio
,openair_journal_entry_error
,openair_journal_entry_error_m
,openair_line_from_openair
,openair_loaded_cost_class_id
,openair_loaded_cost_credit__id
,openair_loaded_cost_debit_a_id
,openair_loaded_cost_departm_id
,openair_loaded_cost_locatio_id
,openair_loaded_cost_subsidi_id
,openair_phases_ancestry
,openair_phase_name
,openair_primary_loaded_cost
,openair_primary_loaded_cost_id
,openair_project_task_id
,openair_project_task_id_numbe
,openair_pst
,openair_quantity_from__invoic
,openair_rate
,openair_rev_rec_rule_id
,openair_secondary_loaded_cost
,openair_secondary_loaded_co_id
,openair_task_assignment_id
,openair_task_assignment_plann
,openair_task_id
,openair_task_name
,openair_tax
,openair_tertiary_loaded_cost
,openair_tertiary_loaded_cos_id
,openair_timesheet_start_date
,openair_time_entry_id
,originator_journal_tran_typ_id
,originator_transaction_intern
,partner_discount_
,partner_discount_amount
,pid
,planned_revenue_type
,plan_id
,pl_id
,posted
,pretax_amt
,pretax_amt_quantity
,product_subtype
,product_type
,profit_center_id
,project_task_type_id
,promotional_discount_
,promotional_discount_amount
,reason_id
,recognition_account_id
,registration_unique_id
,related_asset_id
,related_license_id
,schedule_id
,serial_number
,ship_date
,statistical_procedure_for_p_id
,statistical_procedure_for_s_id
,statistical_value
,statistical_value__base_curre
,task_type_id
,tax_amt
,tax_exemption_reason_code_id
,tax_rate
,tax_rate_code
,tax_type
,trade_discount_
,trade_item_code_id
,trade_item_description
,user_quantity
,vendor_tax
,vsoe_customer_type_id
,vsoe_deal_size_id
,vsoe_geography_id
,vsoe_lower_band_
,vsoe_pricing_method_id
,vsoe_related_line_item_number
,vsoe_upper_band_
,wdem_settlement_id
,withholding_tax_amount
,withholding_tax_amount__expen
,withholding_tax_base_amount
,withholding_tax_base_amount__
,withholding_tax_code_id
,withholding_tax_code__expen_id
,withholding_tax_line
,withholding_tax_line__expense
,withholding_tax_rate
,withholding_tax_rate__expense
,wt_customer_id
,wt_employee_id
,wt_vendor_id
,apttus_line_id
,apttus_order_
,apttus_order_id
,billing_plan_id
,ela_agreement_name
,item_id
,item_name
,item_units_name
,legacy_equipment_
,legacy_sales_doc_id
,mark_up_
,nibs_id
,po_
,product_revenue_subtype
,revenue_element_id
,unit_list_price
,uplift_
,uplift_amount
,CREDIT_REBILL_REQUIRES_UNBILL
,PRODUCT_SUBTYPE_EXTERNAL_ID
,PRODUCT_TYPE_EXTERNAL_ID
,REBILLED_LINE
,SWT_INS_DT
)
SELECT DISTINCT
S.accounting_period_id
,additional_discount_
,additional_discount_amount
,adjustment_field
,adjustment_tax_code_id
,amount
,appliance_drop_ship_po_
,apply_wh_tax
,asset_id
,authority_currency_code
,billable_engagement_name
,billable_expense_category
,billable_expense_engagement
,billable_item_name
,billable_units_of_measure
,billing_frequency_id
,bill_of_lading_number
,booking_date
,box_number
,charge_type_id
,code_of_supply_id
,contractual_discount_
,contractual_discount_amount
,contract_end_date
,contract_start_date
,contract_term
,course_type_id
,date_created
,S.date_last_modified
,deferral_account_id
,display_quantity
,employee_token_id
,end_user_id
,eu_triangulation
,exempt_id
,expense_account_id
,export_to_openair
,fixed_asset_id
,functional_area_id
,goods_and_services_indicato_id
,gross_list_price
,custom_functional_area_id
,custom_lcci_id
,custom_profit_center_id
,ic_item
,ic_je_number_id
,idt_product_tax_code
,intercompany
,intercompany_discount_
,is_recognized
,je_expense_type
,S.journal_id
,jurisdiction_text
,lcci_id
,line_item_id
,markup_amount
,notc_id
,openair_assigned_users
,openair_billing_rule_id
,openair_charge_type_id
,openair_expense_report_line_i
,openair_gsthst
,openair_invoice_line_id
,openair_journal_entry_creatio
,openair_journal_entry_error
,openair_journal_entry_error_m
,openair_line_from_openair
,openair_loaded_cost_class_id
,openair_loaded_cost_credit__id
,openair_loaded_cost_debit_a_id
,openair_loaded_cost_departm_id
,openair_loaded_cost_locatio_id
,openair_loaded_cost_subsidi_id
,openair_phases_ancestry
,openair_phase_name
,openair_primary_loaded_cost
,openair_primary_loaded_cost_id
,openair_project_task_id
,openair_project_task_id_numbe
,openair_pst
,openair_quantity_from__invoic
,openair_rate
,openair_rev_rec_rule_id
,openair_secondary_loaded_cost
,openair_secondary_loaded_co_id
,openair_task_assignment_id
,openair_task_assignment_plann
,openair_task_id
,openair_task_name
,openair_tax
,openair_tertiary_loaded_cost
,openair_tertiary_loaded_cos_id
,openair_timesheet_start_date
,openair_time_entry_id
,originator_journal_tran_typ_id
,originator_transaction_intern
,partner_discount_
,partner_discount_amount
,pid
,planned_revenue_type
,S.plan_id
,pl_id
,posted
,pretax_amt
,pretax_amt_quantity
,product_subtype
,product_type
,profit_center_id
,project_task_type_id
,promotional_discount_
,promotional_discount_amount
,reason_id
,recognition_account_id
,registration_unique_id
,related_asset_id
,related_license_id
,schedule_id
,serial_number
,ship_date
,statistical_procedure_for_p_id
,statistical_procedure_for_s_id
,statistical_value
,statistical_value__base_curre
,task_type_id
,tax_amt
,tax_exemption_reason_code_id
,tax_rate
,tax_rate_code
,tax_type
,trade_discount_
,trade_item_code_id
,trade_item_description
,user_quantity
,vendor_tax
,vsoe_customer_type_id
,vsoe_deal_size_id
,vsoe_geography_id
,vsoe_lower_band_
,vsoe_pricing_method_id
,vsoe_related_line_item_number
,vsoe_upper_band_
,wdem_settlement_id
,withholding_tax_amount
,withholding_tax_amount__expen
,withholding_tax_base_amount
,withholding_tax_base_amount__
,withholding_tax_code_id
,withholding_tax_code__expen_id
,withholding_tax_line
,withholding_tax_line__expense
,withholding_tax_rate
,withholding_tax_rate__expense
,wt_customer_id
,wt_employee_id
,wt_vendor_id
,apttus_line_id
,apttus_order_
,apttus_order_id
,billing_plan_id
,ela_agreement_name
,item_id
,item_name
,item_units_name
,legacy_equipment_
,legacy_sales_doc_id
,mark_up_
,nibs_id
,po_
,product_revenue_subtype
,revenue_element_id
,unit_list_price
,uplift_
,uplift_amount
,CREDIT_REBILL_REQUIRES_UNBILL
,PRODUCT_SUBTYPE_EXTERNAL_ID
,PRODUCT_TYPE_EXTERNAL_ID
,REBILLED_LINE
,SYSDATE as SWT_INS_DT
FROM NS_Revenue_plan_lines_stg_Tmp S JOIN NS_Revenue_plan_lines_stg_Tmp_Key SK ON S.plan_id=SK.plan_id AND S.accounting_period_id=SK.accounting_period_id AND nvl(S.journal_id,0)=nvl(SK.journal_id,0) AND S.date_last_modified=SK.date_last_modified
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Revenue_plan_lines BASE
WHERE S.plan_id = BASE.plan_id AND S.accounting_period_id = BASE.accounting_period_id AND nvl(S.journal_id,0) = nvl(BASE.journal_id,0));



/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Revenue_plan_lines' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Revenue_plan_lines' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Revenue_plan_lines',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Revenue_plan_lines where SWT_INS_DT::date = sysdate::date),'Y';


Commit;

 
/*SELECT PURGE_TABLE('swt_rpt_base.NS_Revenue_plan_lines');
SELECT PURGE_TABLE('swt_rpt_stg.NS_Revenue_plan_lines_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Revenue_plan_lines');
*/



