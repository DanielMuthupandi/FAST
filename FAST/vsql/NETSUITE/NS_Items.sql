/****
****Script Name	  : NS_Items.sql
****Description   : Incremental data load for NS_Items
****/

/* Setting timing on**/
\timing
/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Items";

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
select 'NETSUITE','NS_Items',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Items_Hist SELECT * from "swt_rpt_stg".NS_Items;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select item_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Items where item_id in (
select item_id from swt_rpt_stg.NS_Items group by item_id,date_last_modified having count(1)>1)
group by item_id);

delete from swt_rpt_stg.NS_Items where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Items.item_id=t2.item_id and swt_rpt_stg.NS_Items.auto_id<t2. auto_id); 

COMMIT; 


CREATE LOCAL TEMP TABLE NS_Items_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Items)
SEGMENTED BY HASH(item_id,date_last_modified) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.NS_Items;

CREATE LOCAL TEMP TABLE NS_Items_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT item_id,date_last_modified FROM swt_rpt_base.NS_Items)
SEGMENTED BY HASH(item_id,date_last_modified) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Items_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT item_id, max(date_last_modified) as date_last_modified FROM NS_Items_stg_Tmp group by item_id)
SEGMENTED BY HASH(item_id,date_last_modified) ALL NODES;




/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Items_Hist
(
allow_drop_ship
,alt_demand_source_item_id
,asset_account_id
,atp_lead_time
,atp_method
,available_to_partners
,averagecost
,backward_consumption_days
,bill_exch_rate_var_account_id
,bill_price_variance_account_id
,bill_qty_variance_account_id
,build_sub_assemblies
,class_id
,cost_0
,cost_category
,cost_estimate_type
,costing_method
,country_of_manufacture
,create_plan_on_event_type
,created
,current_on_order_count
,custreturn_variance_account_id
,date_last_modified
,date_of_last_transaction
,default_return_cost
,deferred_expense_account_id
,deferred_revenue_account_id
,demand_source
,demand_time_fence
,department_id
,deposit
,displayname
,distribution_category
,distribution_network
,dropship_expense_account_id
,effective_bom_control_type
,expense_account_id
,featureddescription
,featureditem
,fixed_lot_size
,forward_consumption_days
,fraud_risk
,full_name
,gain_loss_account_id
,handling_cost
,hazmat
,hazmat_hazard_class
,hazmat_id
,hazmat_item_units
,hazmat_item_units_qty
,hazmat_packing_group
,hazmat_shipping_name
,include_child_subsidiaries
,income_account_id
,interco_expense_account_id
,interco_income_account_id
,invt_count_classification
,invt_count_interval
,is_cont_rev_handling
,is_enforce_min_qty_internally
,is_hold_rev_rec
,is_moss
,is_phantom
,is_special_order_item
,isinactive
,isonline
,istaxable
,item_defined_cost
,item_extid
,item_id
,item_revenue_category
,last_cogs_correction
,last_invt_count_date
,last_purchase_price
,location_id
,lot_numbered_item
,lot_sizing_method
,manufacturer
,manufacturing_charge_item
,match_bill_to_receipt
,minimum_quantity
,modified
,mpn
,name
,next_invt_count_date
,ns_lead_time
,offersupport
,onspecial
,overhead_type
,parent_id
,payment_method_id
,periodic_lot_size_days
,periodic_lot_size_type
,pref_purchase_tax_id
,pref_sale_tax_id
,pref_stock_level
,prices_include_tax
,pricing_group_id
,print_sub_items
,prod_price_var_account_id
,prod_qty_var_account_id
,purchase_price_var_account_id
,purchase_unit_id
,purchasedescription
,purchaseorderamount
,purchaseorderquantity
,purchaseorderquantitydiff
,quantityavailable
,quantitybackordered
,quantityonhand
,receiptamount
,receiptquantity
,receiptquantitydiff
,reorder_multiple
,reorderpoint
,replenishment_method
,resalable
,reschedule_in_days
,reschedule_out_days
,rev_rec_forecast_rule_id
,rev_rec_rule_id
,revenue_allocation_group
,round_up_as_component
,safety_stock_days
,safety_stock_level
,sale_unit_id
,salesdescription
,salesprice
,scrap_account_id
,serialized_item
,shippingcost
,special_work_order_item
,specialsdescription
,stock_unit_id
,storedescription
,storedetaileddescription
,storedisplayname
,subtype
,supply_time_fence
,supply_type
,tax_item_id
,totalvalue
,transferprice
,type_name
,unbuild_variance_account_id
,units_type_id
,upc_code
,use_component_yield
,vendor_id
,vendorname
,vendreturn_variance_account_id
,vsoe_deferral
,vsoe_delivered
,vsoe_discount
,vsoe_price
,weight
,weight_in_user_defined_unit
,weight_unit_index
,wip_account_id
,wip_cost_variance_account_id
,work_order_lead_time
,billing_plan_id
,business_unit_id
,center_id
,code_of_supply_id
,commodity_code
,default_openair_billing_rul_id
,default_wt_code_id
,deferred_rev_acc_id
,direct_posting
,ex_code
,ex_code_for_purchase_id
,export_to_openair
,export_to_openair_product
,family_id
,for_invoice
,for_purchase
,idt_product_tax_code_descript
,idt_product_tax_code_id
,idt_product_tax_code_name
,intercompany_product
,lcci_id
,mark_up
,nature_of_transaction_codes_id
,openair_export_error
,pillar_id
,product_line_id
,product_subtype_id
,product_type_id
,profit_center_id
,prompt_payment_discount_item
,source_subsidiary_id
,source_system_id
,supplementary_unit__abberviat
,supplementary_unit_id
,support_business_area_id
,type_of_goods_id
,unspsc_code_id
,functional_area_id
,revenue_subtype_id
,fx_adjustment_account_id
,funding_type_id
,LD_DT
,SWT_INS_DT
,d_source
)
select
allow_drop_ship
,alt_demand_source_item_id
,asset_account_id
,atp_lead_time
,atp_method
,available_to_partners
,averagecost
,backward_consumption_days
,bill_exch_rate_var_account_id
,bill_price_variance_account_id
,bill_qty_variance_account_id
,build_sub_assemblies
,class_id
,cost_0
,cost_category
,cost_estimate_type
,costing_method
,country_of_manufacture
,create_plan_on_event_type
,created
,current_on_order_count
,custreturn_variance_account_id
,date_last_modified
,date_of_last_transaction
,default_return_cost
,deferred_expense_account_id
,deferred_revenue_account_id
,demand_source
,demand_time_fence
,department_id
,deposit
,displayname
,distribution_category
,distribution_network
,dropship_expense_account_id
,effective_bom_control_type
,expense_account_id
,featureddescription
,featureditem
,fixed_lot_size
,forward_consumption_days
,fraud_risk
,full_name
,gain_loss_account_id
,handling_cost
,hazmat
,hazmat_hazard_class
,hazmat_id
,hazmat_item_units
,hazmat_item_units_qty
,hazmat_packing_group
,hazmat_shipping_name
,include_child_subsidiaries
,income_account_id
,interco_expense_account_id
,interco_income_account_id
,invt_count_classification
,invt_count_interval
,is_cont_rev_handling
,is_enforce_min_qty_internally
,is_hold_rev_rec
,is_moss
,is_phantom
,is_special_order_item
,isinactive
,isonline
,istaxable
,item_defined_cost
,item_extid
,item_id
,item_revenue_category
,last_cogs_correction
,last_invt_count_date
,last_purchase_price
,location_id
,lot_numbered_item
,lot_sizing_method
,manufacturer
,manufacturing_charge_item
,match_bill_to_receipt
,minimum_quantity
,modified
,mpn
,name
,next_invt_count_date
,ns_lead_time
,offersupport
,onspecial
,overhead_type
,parent_id
,payment_method_id
,periodic_lot_size_days
,periodic_lot_size_type
,pref_purchase_tax_id
,pref_sale_tax_id
,pref_stock_level
,prices_include_tax
,pricing_group_id
,print_sub_items
,prod_price_var_account_id
,prod_qty_var_account_id
,purchase_price_var_account_id
,purchase_unit_id
,purchasedescription
,purchaseorderamount
,purchaseorderquantity
,purchaseorderquantitydiff
,quantityavailable
,quantitybackordered
,quantityonhand
,receiptamount
,receiptquantity
,receiptquantitydiff
,reorder_multiple
,reorderpoint
,replenishment_method
,resalable
,reschedule_in_days
,reschedule_out_days
,rev_rec_forecast_rule_id
,rev_rec_rule_id
,revenue_allocation_group
,round_up_as_component
,safety_stock_days
,safety_stock_level
,sale_unit_id
,salesdescription
,salesprice
,scrap_account_id
,serialized_item
,shippingcost
,special_work_order_item
,specialsdescription
,stock_unit_id
,storedescription
,storedetaileddescription
,storedisplayname
,subtype
,supply_time_fence
,supply_type
,tax_item_id
,totalvalue
,transferprice
,type_name
,unbuild_variance_account_id
,units_type_id
,upc_code
,use_component_yield
,vendor_id
,vendorname
,vendreturn_variance_account_id
,vsoe_deferral
,vsoe_delivered
,vsoe_discount
,vsoe_price
,weight
,weight_in_user_defined_unit
,weight_unit_index
,wip_account_id
,wip_cost_variance_account_id
,work_order_lead_time
,billing_plan_id
,business_unit_id
,center_id
,code_of_supply_id
,commodity_code
,default_openair_billing_rul_id
,default_wt_code_id
,deferred_rev_acc_id
,direct_posting
,ex_code
,ex_code_for_purchase_id
,export_to_openair
,export_to_openair_product
,family_id
,for_invoice
,for_purchase
,idt_product_tax_code_descript
,idt_product_tax_code_id
,idt_product_tax_code_name
,intercompany_product
,lcci_id
,mark_up
,nature_of_transaction_codes_id
,openair_export_error
,pillar_id
,product_line_id
,product_subtype_id
,product_type_id
,profit_center_id
,prompt_payment_discount_item
,source_subsidiary_id
,source_system_id
,supplementary_unit__abberviat
,supplementary_unit_id
,support_business_area_id
,type_of_goods_id
,unspsc_code_id
,functional_area_id
,revenue_subtype_id
,fx_adjustment_account_id
,funding_type_id
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Items WHERE item_id in 
(SELECT STG.item_id FROM NS_Items_stg_Tmp_Key STG JOIN NS_Items_base_Tmp
ON STG.item_id = NS_Items_base_Tmp.item_id AND STG.date_last_modified >= NS_Items_base_Tmp.date_last_modified);




/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Items_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Items WHERE item_id in
(SELECT STG.item_id FROM NS_Items_stg_Tmp_Key STG JOIN NS_Items_base_Tmp
ON STG.item_id = NS_Items_base_Tmp.item_id AND STG.date_last_modified >= NS_Items_base_Tmp.date_last_modified);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Items
(
allow_drop_ship
,alt_demand_source_item_id
,asset_account_id
,atp_lead_time
,atp_method
,available_to_partners
,averagecost
,backward_consumption_days
,bill_exch_rate_var_account_id
,bill_price_variance_account_id
,bill_qty_variance_account_id
,build_sub_assemblies
,class_id
,cost_0
,cost_category
,cost_estimate_type
,costing_method
,country_of_manufacture
,create_plan_on_event_type
,created
,current_on_order_count
,custreturn_variance_account_id
,date_last_modified
,date_of_last_transaction
,default_return_cost
,deferred_expense_account_id
,deferred_revenue_account_id
,demand_source
,demand_time_fence
,department_id
,deposit
,displayname
,distribution_category
,distribution_network
,dropship_expense_account_id
,effective_bom_control_type
,expense_account_id
,featureddescription
,featureditem
,fixed_lot_size
,forward_consumption_days
,fraud_risk
,full_name
,gain_loss_account_id
,handling_cost
,hazmat
,hazmat_hazard_class
,hazmat_id
,hazmat_item_units
,hazmat_item_units_qty
,hazmat_packing_group
,hazmat_shipping_name
,include_child_subsidiaries
,income_account_id
,interco_expense_account_id
,interco_income_account_id
,invt_count_classification
,invt_count_interval
,is_cont_rev_handling
,is_enforce_min_qty_internally
,is_hold_rev_rec
,is_moss
,is_phantom
,is_special_order_item
,isinactive
,isonline
,istaxable
,item_defined_cost
,item_extid
,item_id
,item_revenue_category
,last_cogs_correction
,last_invt_count_date
,last_purchase_price
,location_id
,lot_numbered_item
,lot_sizing_method
,manufacturer
,manufacturing_charge_item
,match_bill_to_receipt
,minimum_quantity
,modified
,mpn
,name
,next_invt_count_date
,ns_lead_time
,offersupport
,onspecial
,overhead_type
,parent_id
,payment_method_id
,periodic_lot_size_days
,periodic_lot_size_type
,pref_purchase_tax_id
,pref_sale_tax_id
,pref_stock_level
,prices_include_tax
,pricing_group_id
,print_sub_items
,prod_price_var_account_id
,prod_qty_var_account_id
,purchase_price_var_account_id
,purchase_unit_id
,purchasedescription
,purchaseorderamount
,purchaseorderquantity
,purchaseorderquantitydiff
,quantityavailable
,quantitybackordered
,quantityonhand
,receiptamount
,receiptquantity
,receiptquantitydiff
,reorder_multiple
,reorderpoint
,replenishment_method
,resalable
,reschedule_in_days
,reschedule_out_days
,rev_rec_forecast_rule_id
,rev_rec_rule_id
,revenue_allocation_group
,round_up_as_component
,safety_stock_days
,safety_stock_level
,sale_unit_id
,salesdescription
,salesprice
,scrap_account_id
,serialized_item
,shippingcost
,special_work_order_item
,specialsdescription
,stock_unit_id
,storedescription
,storedetaileddescription
,storedisplayname
,subtype
,supply_time_fence
,supply_type
,tax_item_id
,totalvalue
,transferprice
,type_name
,unbuild_variance_account_id
,units_type_id
,upc_code
,use_component_yield
,vendor_id
,vendorname
,vendreturn_variance_account_id
,vsoe_deferral
,vsoe_delivered
,vsoe_discount
,vsoe_price
,weight
,weight_in_user_defined_unit
,weight_unit_index
,wip_account_id
,wip_cost_variance_account_id
,work_order_lead_time
,billing_plan_id
,business_unit_id
,center_id
,code_of_supply_id
,commodity_code
,default_openair_billing_rul_id
,default_wt_code_id
,deferred_rev_acc_id
,direct_posting
,ex_code
,ex_code_for_purchase_id
,export_to_openair
,export_to_openair_product
,family_id
,for_invoice
,for_purchase
,idt_product_tax_code_descript
,idt_product_tax_code_id
,idt_product_tax_code_name
,intercompany_product
,lcci_id
,mark_up
,nature_of_transaction_codes_id
,openair_export_error
,pillar_id
,product_line_id
,product_subtype_id
,product_type_id
,profit_center_id
,prompt_payment_discount_item
,source_subsidiary_id
,source_system_id
,supplementary_unit__abberviat
,supplementary_unit_id
,support_business_area_id
,type_of_goods_id
,unspsc_code_id
,functional_area_id
,revenue_subtype_id
,fx_adjustment_account_id
,funding_type_id
,SWT_INS_DT
)
SELECT DISTINCT 
allow_drop_ship
,alt_demand_source_item_id
,asset_account_id
,atp_lead_time
,atp_method
,available_to_partners
,averagecost
,backward_consumption_days
,bill_exch_rate_var_account_id
,bill_price_variance_account_id
,bill_qty_variance_account_id
,build_sub_assemblies
,class_id
,cost_0
,cost_category
,cost_estimate_type
,costing_method
,country_of_manufacture
,create_plan_on_event_type
,created
,current_on_order_count
,custreturn_variance_account_id
,NS_Items_stg_Tmp.date_last_modified
,date_of_last_transaction
,default_return_cost
,deferred_expense_account_id
,deferred_revenue_account_id
,demand_source
,demand_time_fence
,department_id
,deposit
,displayname
,distribution_category
,distribution_network
,dropship_expense_account_id
,effective_bom_control_type
,expense_account_id
,featureddescription
,featureditem
,fixed_lot_size
,forward_consumption_days
,fraud_risk
,full_name
,gain_loss_account_id
,handling_cost
,hazmat
,hazmat_hazard_class
,hazmat_id
,hazmat_item_units
,hazmat_item_units_qty
,hazmat_packing_group
,hazmat_shipping_name
,include_child_subsidiaries
,income_account_id
,interco_expense_account_id
,interco_income_account_id
,invt_count_classification
,invt_count_interval
,is_cont_rev_handling
,is_enforce_min_qty_internally
,is_hold_rev_rec
,is_moss
,is_phantom
,is_special_order_item
,isinactive
,isonline
,istaxable
,item_defined_cost
,item_extid
,NS_Items_stg_Tmp.item_id
,item_revenue_category
,last_cogs_correction
,last_invt_count_date
,last_purchase_price
,location_id
,lot_numbered_item
,lot_sizing_method
,manufacturer
,manufacturing_charge_item
,match_bill_to_receipt
,minimum_quantity
,modified
,mpn
,name
,next_invt_count_date
,ns_lead_time
,offersupport
,onspecial
,overhead_type
,parent_id
,payment_method_id
,periodic_lot_size_days
,periodic_lot_size_type
,pref_purchase_tax_id
,pref_sale_tax_id
,pref_stock_level
,prices_include_tax
,pricing_group_id
,print_sub_items
,prod_price_var_account_id
,prod_qty_var_account_id
,purchase_price_var_account_id
,purchase_unit_id
,purchasedescription
,purchaseorderamount
,purchaseorderquantity
,purchaseorderquantitydiff
,quantityavailable
,quantitybackordered
,quantityonhand
,receiptamount
,receiptquantity
,receiptquantitydiff
,reorder_multiple
,reorderpoint
,replenishment_method
,resalable
,reschedule_in_days
,reschedule_out_days
,rev_rec_forecast_rule_id
,rev_rec_rule_id
,revenue_allocation_group
,round_up_as_component
,safety_stock_days
,safety_stock_level
,sale_unit_id
,salesdescription
,salesprice
,scrap_account_id
,serialized_item
,shippingcost
,special_work_order_item
,specialsdescription
,stock_unit_id
,storedescription
,storedetaileddescription
,storedisplayname
,subtype
,supply_time_fence
,supply_type
,tax_item_id
,totalvalue
,transferprice
,type_name
,unbuild_variance_account_id
,units_type_id
,upc_code
,use_component_yield
,vendor_id
,vendorname
,vendreturn_variance_account_id
,vsoe_deferral
,vsoe_delivered
,vsoe_discount
,vsoe_price
,weight
,weight_in_user_defined_unit
,weight_unit_index
,wip_account_id
,wip_cost_variance_account_id
,work_order_lead_time
,billing_plan_id
,business_unit_id
,center_id
,code_of_supply_id
,commodity_code
,default_openair_billing_rul_id
,default_wt_code_id
,deferred_rev_acc_id
,direct_posting
,ex_code
,ex_code_for_purchase_id
,export_to_openair
,export_to_openair_product
,family_id
,for_invoice
,for_purchase
,idt_product_tax_code_descript
,idt_product_tax_code_id
,idt_product_tax_code_name
,intercompany_product
,lcci_id
,mark_up
,nature_of_transaction_codes_id
,openair_export_error
,pillar_id
,product_line_id
,product_subtype_id
,product_type_id
,profit_center_id
,prompt_payment_discount_item
,source_subsidiary_id
,source_system_id
,supplementary_unit__abberviat
,supplementary_unit_id
,support_business_area_id
,type_of_goods_id
,unspsc_code_id
,functional_area_id
,revenue_subtype_id
,fx_adjustment_account_id
,funding_type_id
,sysdate as SWT_INS_DT
FROM NS_Items_stg_Tmp JOIN NS_Items_stg_Tmp_Key ON NS_Items_stg_Tmp.item_id= NS_Items_stg_Tmp_Key.item_id AND NS_Items_stg_Tmp.date_last_modified=NS_Items_stg_Tmp_Key.date_last_modified
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Items BASE
WHERE NS_Items_stg_Tmp.item_id = BASE.item_id);





/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Items' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Items' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Items',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Items where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


SELECT PURGE_TABLE('swt_rpt_base.NS_Items');
SELECT PURGE_TABLE('swt_rpt_stg.NS_Items_Hist');
select ANALYZE_STATISTICS('swt_rpt_base.NS_Items');


