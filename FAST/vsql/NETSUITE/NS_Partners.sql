/*****
**** Script Name	  : NS_Partners.sql
****Description   : Incremental data load for NS_Partners
****/

/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Partners";

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
select 'NETSUITE','NS_Partners',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Partners_Hist SELECT * from "swt_rpt_stg".NS_Partners;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select partner_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Partners where partner_id in (
select partner_id from swt_rpt_stg.NS_Partners group by partner_id,last_modified_date having count(1)>1)
group by partner_id);

delete from swt_rpt_stg.NS_Partners where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Partners.partner_id=t2.partner_id and swt_rpt_stg.NS_Partners.auto_id<t2. auto_id); 

COMMIT; 

CREATE LOCAL TEMP TABLE NS_Partners_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Partners)
SEGMENTED BY HASH(partner_id,last_modified_date) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.NS_Partners;

CREATE LOCAL TEMP TABLE NS_Partners_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT partner_id,last_modified_date FROM swt_rpt_base.NS_Partners)
SEGMENTED BY HASH(partner_id,last_modified_date) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Partners_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT partner_id, max(last_modified_date) as last_modified_date FROM NS_Partners_stg_Tmp group by partner_id)
SEGMENTED BY HASH(partner_id,last_modified_date) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Partners_Hist
(
account_name
,account_number
,actual_cost_migration
,address
,address1
,address2
,address3
,altemail
,altphone
,ariba_network_id
,ariba_system_id
,asian_name_1st
,asian_name_2nd
,assigntasks
,bank_account_currency_id
,bank_account_number
,bank_address_1
,bank_address_2
,bank_city
,bank_country_id
,bank_name
,bank_routingswift_code
,bank_routing_number
,bank_state
,bank_zip
,baseline_cost
,baseline_hours
,baseline_revenue
,bic
,bmc_cumulus_pmo_user
,bulstat_number
,business_area_id
,central_bank_id
,check_bill
,city
,client_principal_id
,code
,comments
,companyname
,country
,create_date
,cumulative__completed
,customer_fiscal_representativ
,customer_fiscal_representati_0
,customer_fiscal_representati_1
,customer_fiscal_representati_2
,customer_fiscal_representati_3
,customer_subsidiary_sub_code
,date_last_modified
,default_transaction_type_id
,delivery_manager_id
,dic
,domestic_parent_duns_
,domestic_parent_name
,duns_
,duplicate_cost_types
,duplicate_dashboard_settings
,duplicate_expense_policy
,duplicate_invoice_layout_sett
,duplicate_issues
,duplicate_loaded_costs
,duplicate_notification_settin
,duplicate_phase_and_task_cust
,duplicate_project_approvers
,duplicate_project_autobill_se
,duplicate_project_billing_rul
,duplicate_project_budget
,duplicate_project_pricing
,duplicate_recognition_autorun
,duplicate_revenue_recognition
,dwo_cost_budget
,email
,estimated_actual_cost
,estimate_at_completion_eac
,expected_order_close_dwo
,export_to_openair
,fax
,fte
,full_name
,functional_area_id
,global_parent_duns_
,global_parent_name
,home_phone
,custom_legal_name
,ico
,identifier_type
,identifier_value
,immediate_parent_duns_
,immediate_parent_name
,individual_bill_payment
,intermediary_bank
,intermediary_bic
,isinactive
,is_engagement
,is_person
,je_approval_routing_id
,je_approver_id
,kyriba_entity_name
,last_modified_date
,last_sales_activity
,lcci_id
,loginaccess
,lsa_link
,lsa_link_name
,mobile_phone
,mru_id
,name
,national_identification
,ns_actual_cost_calculation
,openair_create_project_worksp
,openair_employee_is_ns_purcha
,openair_export_error
,openair_internal_id
,openair_map_exp__rep__to_pare
,openair_map_exp__rep__to_vend
,openair_opportunity_id
,openair_parent_vendor_id
,openair_percent_complete_over
,openair_project_currency_id
,openair_project_rate_card_id
,openair_project_stage_id
,openair_project_template_id
,openair_sfa_id
,openair_user_currency
,openair_user_or_vendor_id
,openair_user_tax_nexus_type_id
,parent_customer_id
,partner_extid
,partner_id
,payment_hold
,payment_method_id
,phone
,physical_work_location
,pmo_toolkit_user
,prepaid
,print_on_check_as
,procurement_organization_id
,profit_center_id
,project_billing_type_id
,project_category_id
,project_id
,project_program_id
,project_revenue_type_id
,project_type_id
,proj_functional_area_id
,proj_lcci_id
,proj_profit_center_id
,reason_for_hold
,remittance_purpose_code
,resource_type_id
,shipping_address
,source_system_id
,state
,statutory_bank_payment_code
,subsidiary
,tax_contact_first_name
,tax_contact_id
,tax_contact_last_name
,tax_contact_middle_name
,tax_number
,url
,vat_registration_no
,vsoe_customer_type_id
,zipcode
,business_style_id
,ctc
,default_wt_code_id
,is_vat_id
,philhealth
,account_timezone
,cmt_1_id
,cmt_2_id
,corporate_status_id
,country_iso_code_id
,edi
,einvoicing
,email_0
,english_name
,federal
,federal_tax_id
,industry_segment_id
,industry_vertical_id
,language_iso_code
,person_type_id
,po_required
,primary_city_area_nonlatin
,print
,private_0
,project_cmt_id
,project_manager_id
,project_market_offering_id
,project_region_id
,project_service_offering_id
,project_type_labor_costing_id
,receipts_required
,region_id
,sled
,state_tax_id
,tin
,ACCOUNT_NAME_NONLATIN
,COUNTRY_GROUP
,ECO_ID
,EDOCUMENT_PACKAGE_ID
,FINANCE_MANAGER_ID
,JOB_CODE
,JOB_LEVEL
,OPENAIR_PROGPROJ_STAGE_ID
,SENDER_EMAIL_DOMAIN
,USE_SENDER_EMAIL_LIST
,LD_DT
,SWT_INS_DT
,d_source
)
select
account_name
,account_number
,actual_cost_migration
,address
,address1
,address2
,address3
,altemail
,altphone
,ariba_network_id
,ariba_system_id
,asian_name_1st
,asian_name_2nd
,assigntasks
,bank_account_currency_id
,bank_account_number
,bank_address_1
,bank_address_2
,bank_city
,bank_country_id
,bank_name
,bank_routingswift_code
,bank_routing_number
,bank_state
,bank_zip
,baseline_cost
,baseline_hours
,baseline_revenue
,bic
,bmc_cumulus_pmo_user
,bulstat_number
,business_area_id
,central_bank_id
,check_bill
,city
,client_principal_id
,code
,comments
,companyname
,country
,create_date
,cumulative__completed
,customer_fiscal_representativ
,customer_fiscal_representati_0
,customer_fiscal_representati_1
,customer_fiscal_representati_2
,customer_fiscal_representati_3
,customer_subsidiary_sub_code
,date_last_modified
,default_transaction_type_id
,delivery_manager_id
,dic
,domestic_parent_duns_
,domestic_parent_name
,duns_
,duplicate_cost_types
,duplicate_dashboard_settings
,duplicate_expense_policy
,duplicate_invoice_layout_sett
,duplicate_issues
,duplicate_loaded_costs
,duplicate_notification_settin
,duplicate_phase_and_task_cust
,duplicate_project_approvers
,duplicate_project_autobill_se
,duplicate_project_billing_rul
,duplicate_project_budget
,duplicate_project_pricing
,duplicate_recognition_autorun
,duplicate_revenue_recognition
,dwo_cost_budget
,email
,estimated_actual_cost
,estimate_at_completion_eac
,expected_order_close_dwo
,export_to_openair
,fax
,fte
,full_name
,functional_area_id
,global_parent_duns_
,global_parent_name
,home_phone
,custom_legal_name
,ico
,identifier_type
,identifier_value
,immediate_parent_duns_
,immediate_parent_name
,individual_bill_payment
,intermediary_bank
,intermediary_bic
,isinactive
,is_engagement
,is_person
,je_approval_routing_id
,je_approver_id
,kyriba_entity_name
,last_modified_date
,last_sales_activity
,lcci_id
,loginaccess
,lsa_link
,lsa_link_name
,mobile_phone
,mru_id
,name
,national_identification
,ns_actual_cost_calculation
,openair_create_project_worksp
,openair_employee_is_ns_purcha
,openair_export_error
,openair_internal_id
,openair_map_exp__rep__to_pare
,openair_map_exp__rep__to_vend
,openair_opportunity_id
,openair_parent_vendor_id
,openair_percent_complete_over
,openair_project_currency_id
,openair_project_rate_card_id
,openair_project_stage_id
,openair_project_template_id
,openair_sfa_id
,openair_user_currency
,openair_user_or_vendor_id
,openair_user_tax_nexus_type_id
,parent_customer_id
,partner_extid
,partner_id
,payment_hold
,payment_method_id
,phone
,physical_work_location
,pmo_toolkit_user
,prepaid
,print_on_check_as
,procurement_organization_id
,profit_center_id
,project_billing_type_id
,project_category_id
,project_id
,project_program_id
,project_revenue_type_id
,project_type_id
,proj_functional_area_id
,proj_lcci_id
,proj_profit_center_id
,reason_for_hold
,remittance_purpose_code
,resource_type_id
,shipping_address
,source_system_id
,state
,statutory_bank_payment_code
,subsidiary
,tax_contact_first_name
,tax_contact_id
,tax_contact_last_name
,tax_contact_middle_name
,tax_number
,url
,vat_registration_no
,vsoe_customer_type_id
,zipcode
,business_style_id
,ctc
,default_wt_code_id
,is_vat_id
,philhealth
,account_timezone
,cmt_1_id
,cmt_2_id
,corporate_status_id
,country_iso_code_id
,edi
,einvoicing
,email_0
,english_name
,federal
,federal_tax_id
,industry_segment_id
,industry_vertical_id
,language_iso_code
,person_type_id
,po_required
,primary_city_area_nonlatin
,print
,private_0
,project_cmt_id
,project_manager_id
,project_market_offering_id
,project_region_id
,project_service_offering_id
,project_type_labor_costing_id
,receipts_required
,region_id
,sled
,state_tax_id
,tin
,ACCOUNT_NAME_NONLATIN
,COUNTRY_GROUP
,ECO_ID
,EDOCUMENT_PACKAGE_ID
,FINANCE_MANAGER_ID
,JOB_CODE
,JOB_LEVEL
,OPENAIR_PROGPROJ_STAGE_ID
,SENDER_EMAIL_DOMAIN
,USE_SENDER_EMAIL_LIST
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Partners WHERE partner_id in
(SELECT STG.partner_id FROM NS_Partners_stg_Tmp_Key STG JOIN NS_Partners_base_Tmp
ON STG.partner_id = NS_Partners_base_Tmp.partner_id AND STG.last_modified_date >= NS_Partners_base_Tmp.last_modified_date);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Partners_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Partners WHERE partner_id in
(SELECT STG.partner_id FROM NS_Partners_stg_Tmp_Key STG JOIN NS_Partners_base_Tmp
ON STG.partner_id = NS_Partners_base_Tmp.partner_id AND STG.last_modified_date >= NS_Partners_base_Tmp.last_modified_date);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Partners
(
account_name
,account_number
,actual_cost_migration
,address
,address1
,address2
,address3
,altemail
,altphone
,ariba_network_id
,ariba_system_id
,asian_name_1st
,asian_name_2nd
,assigntasks
,bank_account_currency_id
,bank_account_number
,bank_address_1
,bank_address_2
,bank_city
,bank_country_id
,bank_name
,bank_routingswift_code
,bank_routing_number
,bank_state
,bank_zip
,baseline_cost
,baseline_hours
,baseline_revenue
,bic
,bmc_cumulus_pmo_user
,bulstat_number
,business_area_id
,central_bank_id
,check_bill
,city
,client_principal_id
,code
,comments
,companyname
,country
,create_date
,cumulative__completed
,customer_fiscal_representativ
,customer_fiscal_representati_0
,customer_fiscal_representati_1
,customer_fiscal_representati_2
,customer_fiscal_representati_3
,customer_subsidiary_sub_code
,date_last_modified
,default_transaction_type_id
,delivery_manager_id
,dic
,domestic_parent_duns_
,domestic_parent_name
,duns_
,duplicate_cost_types
,duplicate_dashboard_settings
,duplicate_expense_policy
,duplicate_invoice_layout_sett
,duplicate_issues
,duplicate_loaded_costs
,duplicate_notification_settin
,duplicate_phase_and_task_cust
,duplicate_project_approvers
,duplicate_project_autobill_se
,duplicate_project_billing_rul
,duplicate_project_budget
,duplicate_project_pricing
,duplicate_recognition_autorun
,duplicate_revenue_recognition
,dwo_cost_budget
,email
,estimated_actual_cost
,estimate_at_completion_eac
,expected_order_close_dwo
,export_to_openair
,fax
,fte
,full_name
,functional_area_id
,global_parent_duns_
,global_parent_name
,home_phone
,custom_legal_name
,ico
,identifier_type
,identifier_value
,immediate_parent_duns_
,immediate_parent_name
,individual_bill_payment
,intermediary_bank
,intermediary_bic
,isinactive
,is_engagement
,is_person
,je_approval_routing_id
,je_approver_id
,kyriba_entity_name
,last_modified_date
,last_sales_activity
,lcci_id
,loginaccess
,lsa_link
,lsa_link_name
,mobile_phone
,mru_id
,name
,national_identification
,ns_actual_cost_calculation
,openair_create_project_worksp
,openair_employee_is_ns_purcha
,openair_export_error
,openair_internal_id
,openair_map_exp__rep__to_pare
,openair_map_exp__rep__to_vend
,openair_opportunity_id
,openair_parent_vendor_id
,openair_percent_complete_over
,openair_project_currency_id
,openair_project_rate_card_id
,openair_project_stage_id
,openair_project_template_id
,openair_sfa_id
,openair_user_currency
,openair_user_or_vendor_id
,openair_user_tax_nexus_type_id
,parent_customer_id
,partner_extid
,partner_id
,payment_hold
,payment_method_id
,phone
,physical_work_location
,pmo_toolkit_user
,prepaid
,print_on_check_as
,procurement_organization_id
,profit_center_id
,project_billing_type_id
,project_category_id
,project_id
,project_program_id
,project_revenue_type_id
,project_type_id
,proj_functional_area_id
,proj_lcci_id
,proj_profit_center_id
,reason_for_hold
,remittance_purpose_code
,resource_type_id
,shipping_address
,source_system_id
,state
,statutory_bank_payment_code
,subsidiary
,tax_contact_first_name
,tax_contact_id
,tax_contact_last_name
,tax_contact_middle_name
,tax_number
,url
,vat_registration_no
,vsoe_customer_type_id
,zipcode
,business_style_id
,ctc
,default_wt_code_id
,is_vat_id
,philhealth
,account_timezone
,cmt_1_id
,cmt_2_id
,corporate_status_id
,country_iso_code_id
,edi
,einvoicing
,email_0
,english_name
,federal
,federal_tax_id
,industry_segment_id
,industry_vertical_id
,language_iso_code
,person_type_id
,po_required
,primary_city_area_nonlatin
,print
,private_0
,project_cmt_id
,project_manager_id
,project_market_offering_id
,project_region_id
,project_service_offering_id
,project_type_labor_costing_id
,receipts_required
,region_id
,sled
,state_tax_id
,tin
,ACCOUNT_NAME_NONLATIN
,COUNTRY_GROUP
,ECO_ID
,EDOCUMENT_PACKAGE_ID
,FINANCE_MANAGER_ID
,JOB_CODE
,JOB_LEVEL
,OPENAIR_PROGPROJ_STAGE_ID
,SENDER_EMAIL_DOMAIN
,USE_SENDER_EMAIL_LIST
,SWT_INS_DT
)
SELECT DISTINCT
account_name
,account_number
,actual_cost_migration
,address
,address1
,address2
,address3
,altemail
,altphone
,ariba_network_id
,ariba_system_id
,asian_name_1st
,asian_name_2nd
,assigntasks
,bank_account_currency_id
,bank_account_number
,bank_address_1
,bank_address_2
,bank_city
,bank_country_id
,bank_name
,bank_routingswift_code
,bank_routing_number
,bank_state
,bank_zip
,baseline_cost
,baseline_hours
,baseline_revenue
,bic
,bmc_cumulus_pmo_user
,bulstat_number
,business_area_id
,central_bank_id
,check_bill
,city
,client_principal_id
,code
,comments
,companyname
,country
,create_date
,cumulative__completed
,customer_fiscal_representativ
,customer_fiscal_representati_0
,customer_fiscal_representati_1
,customer_fiscal_representati_2
,customer_fiscal_representati_3
,customer_subsidiary_sub_code
,date_last_modified
,default_transaction_type_id
,delivery_manager_id
,dic
,domestic_parent_duns_
,domestic_parent_name
,duns_
,duplicate_cost_types
,duplicate_dashboard_settings
,duplicate_expense_policy
,duplicate_invoice_layout_sett
,duplicate_issues
,duplicate_loaded_costs
,duplicate_notification_settin
,duplicate_phase_and_task_cust
,duplicate_project_approvers
,duplicate_project_autobill_se
,duplicate_project_billing_rul
,duplicate_project_budget
,duplicate_project_pricing
,duplicate_recognition_autorun
,duplicate_revenue_recognition
,dwo_cost_budget
,email
,estimated_actual_cost
,estimate_at_completion_eac
,expected_order_close_dwo
,export_to_openair
,fax
,fte
,full_name
,functional_area_id
,global_parent_duns_
,global_parent_name
,home_phone
,custom_legal_name
,ico
,identifier_type
,identifier_value
,immediate_parent_duns_
,immediate_parent_name
,individual_bill_payment
,intermediary_bank
,intermediary_bic
,isinactive
,is_engagement
,is_person
,je_approval_routing_id
,je_approver_id
,kyriba_entity_name
,NS_Partners_stg_Tmp.last_modified_date
,last_sales_activity
,lcci_id
,loginaccess
,lsa_link
,lsa_link_name
,mobile_phone
,mru_id
,name
,national_identification
,ns_actual_cost_calculation
,openair_create_project_worksp
,openair_employee_is_ns_purcha
,openair_export_error
,openair_internal_id
,openair_map_exp__rep__to_pare
,openair_map_exp__rep__to_vend
,openair_opportunity_id
,openair_parent_vendor_id
,openair_percent_complete_over
,openair_project_currency_id
,openair_project_rate_card_id
,openair_project_stage_id
,openair_project_template_id
,openair_sfa_id
,openair_user_currency
,openair_user_or_vendor_id
,openair_user_tax_nexus_type_id
,parent_customer_id
,partner_extid
,NS_Partners_stg_Tmp.partner_id
,payment_hold
,payment_method_id
,phone
,physical_work_location
,pmo_toolkit_user
,prepaid
,print_on_check_as
,procurement_organization_id
,profit_center_id
,project_billing_type_id
,project_category_id
,project_id
,project_program_id
,project_revenue_type_id
,project_type_id
,proj_functional_area_id
,proj_lcci_id
,proj_profit_center_id
,reason_for_hold
,remittance_purpose_code
,resource_type_id
,shipping_address
,source_system_id
,state
,statutory_bank_payment_code
,subsidiary
,tax_contact_first_name
,tax_contact_id
,tax_contact_last_name
,tax_contact_middle_name
,tax_number
,url
,vat_registration_no
,vsoe_customer_type_id
,zipcode
,business_style_id
,ctc
,default_wt_code_id
,is_vat_id
,philhealth
,account_timezone
,cmt_1_id
,cmt_2_id
,corporate_status_id
,country_iso_code_id
,edi
,einvoicing
,email_0
,english_name
,federal
,federal_tax_id
,industry_segment_id
,industry_vertical_id
,language_iso_code
,person_type_id
,po_required
,primary_city_area_nonlatin
,print
,private_0
,project_cmt_id
,project_manager_id
,project_market_offering_id
,project_region_id
,project_service_offering_id
,project_type_labor_costing_id
,receipts_required
,region_id
,sled
,state_tax_id
,tin
,ACCOUNT_NAME_NONLATIN
,COUNTRY_GROUP
,ECO_ID
,EDOCUMENT_PACKAGE_ID
,FINANCE_MANAGER_ID
,JOB_CODE
,JOB_LEVEL
,OPENAIR_PROGPROJ_STAGE_ID
,SENDER_EMAIL_DOMAIN
,USE_SENDER_EMAIL_LIST
,SYSDATE AS SWT_INS_DT
FROM NS_Partners_stg_Tmp JOIN NS_Partners_stg_Tmp_Key ON NS_Partners_stg_Tmp.partner_id= NS_Partners_stg_Tmp_Key.partner_id AND NS_Partners_stg_Tmp.last_modified_date=NS_Partners_stg_Tmp_Key.last_modified_date
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Partners BASE
WHERE NS_Partners_stg_Tmp.partner_id = BASE.partner_id);



/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Partners' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Partners' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Partners',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Partners where SWT_INS_DT::date = sysdate::date),'Y';

Commit;



SELECT PURGE_TABLE('swt_rpt_base.NS_Partners');
SELECT PURGE_TABLE('swt_rpt_stg.NS_Partners_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Partners');



