/****
****Script Name   : SF_OpportunityLineItem.sql
****Description   : Incremental data load for SF_OpportunityLineItem
****/

/*Setting timing on */
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

--SET SESSION AUTOCOMMIT TO OFF;

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) as count,sysdate st from swt_rpt_stg.SF_OpportunityLineItem;

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
select 'SFDC','SF_OpportunityLineItem',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+Direct*/ INTO swt_rpt_stg.SF_OpportunityLineItem_Hist SELECT * from swt_rpt_stg.SF_OpportunityLineItem;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_OpportunityLineItem where id in (
select id from swt_rpt_stg.SF_OpportunityLineItem group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);


delete from swt_rpt_stg.SF_OpportunityLineItem where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_OpportunityLineItem.id=t2.id and swt_rpt_stg.SF_OpportunityLineItem.auto_id<t2.auto_id);

commit;

CREATE LOCAL TEMP TABLE SF_OpportunityLineItem_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.SF_OpportunityLineItem)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.SF_OpportunityLineItem;


CREATE LOCAL TEMP TABLE SF_OpportunityLineItem_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,LastModifiedDate FROM swt_rpt_base.SF_OpportunityLineItem)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_OpportunityLineItem_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(LastModifiedDate) as LastModifiedDate FROM SF_OpportunityLineItem_stg_Tmp group by id)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;




/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.SF_OpportunityLineItem_Hist
(
Id
,OpportunityId
,SortOrder
,PricebookEntryId
,Product2Id
,ProductCode
,Name
,CurrencyIsoCode
,Quantity
,TotalPrice
,UnitPrice
,ListPrice
,ServiceDate
,Description
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,IsDeleted
,Apttus_Approval__Approval_Status__c
,SWT_Product_Type__c
,SWT_Pillar_Description_Text__c
,HPSW_SaaS_Term_Months__c
,HPSW_Total_SaaS_ACV__c
,SWT_Total_Price_USD__c
,SWT_Tier_Based_Discount_Value__c
,SWT_Tier_Based_Discount__c
,SWT_Product_Sub_Type__c
,SWT_Product_Family__c
,SWT_ProductType__c
,SWT_Deal_Reg_Discount__c
,SWT_Deal_Reg_Discount_Value__c
,SWT_TotalPriceUSD__c
,SWT_Sales_Price_USD__c
,SWT_Renewal_M1_Rev_USD__c
,SWT_Renewal_M2_Rev_USD__c
,SWT_Business_Area__c
,SWT_Renewal_M3_Rev_USD__c
,SWT_Renewal_Total_CQ_Rev_USD__c
,SWT_Support_Level__c
,SWT_Renewable__c
,SWT_Account__c
,Discount
,Subtotal
,SWT_Asset_End_Date__c
,SWT_Asset_Start_Date__c
,SWT_AssetLineItem__c
,SWT_Proposal_Line_Item__c
,SWT_Line_Type__c
,OptionId__c
,LineType__c
,SWT_External_ID__c
,SWT_ListPrice_CRM__c
,SWT_Quote_End_Date__c
,SWT_Quote_Start_Date__c
,IsOptionRollupLine__c
,SWT_Business_Unit__c
,SWT_Pillar_Code__c
,SWT_Product_Category__c
,SWT_Product_Config_Type__c
,SWT_ProductPillars__c
,SWT_Quote_Term__c
,SWT_Total_Saas_ACV__c
,SWT_Opportunity_Record_Type__c
,LD_DT
,SWT_INS_DT
,d_source
,SWT_Ins_Date_Backup
)
select
Id
,OpportunityId
,SortOrder
,PricebookEntryId
,Product2Id
,ProductCode
,Name
,CurrencyIsoCode
,Quantity
,TotalPrice
,UnitPrice
,ListPrice
,ServiceDate
,Description
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,IsDeleted
,Apttus_Approval__Approval_Status__c
,SWT_Product_Type__c
,SWT_Pillar_Description_Text__c
,HPSW_SaaS_Term_Months__c
,HPSW_Total_SaaS_ACV__c
,SWT_Total_Price_USD__c
,SWT_Tier_Based_Discount_Value__c
,SWT_Tier_Based_Discount__c
,SWT_Product_Sub_Type__c
,SWT_Product_Family__c
,SWT_ProductType__c
,SWT_Deal_Reg_Discount__c
,SWT_Deal_Reg_Discount_Value__c
,SWT_TotalPriceUSD__c
,SWT_Sales_Price_USD__c
,SWT_Renewal_M1_Rev_USD__c
,SWT_Renewal_M2_Rev_USD__c
,SWT_Business_Area__c
,SWT_Renewal_M3_Rev_USD__c
,SWT_Renewal_Total_CQ_Rev_USD__c
,SWT_Support_Level__c
,SWT_Renewable__c
,SWT_Account__c
,Discount
,Subtotal
,SWT_Asset_End_Date__c
,SWT_Asset_Start_Date__c
,SWT_AssetLineItem__c
,SWT_Proposal_Line_Item__c
,SWT_Line_Type__c
,OptionId__c
,LineType__c
,SWT_External_ID__c
,SWT_ListPrice_CRM__c
,SWT_Quote_End_Date__c
,SWT_Quote_Start_Date__c
,IsOptionRollupLine__c
,SWT_Business_Unit__c
,SWT_Pillar_Code__c
,SWT_Product_Category__c
,SWT_Product_Config_Type__c
,SWT_ProductPillars__c
,SWT_Quote_Term__c
,SWT_Total_Saas_ACV__c
,SWT_Opportunity_Record_Type__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
,SWT_Ins_Date_Backup
FROM "swt_rpt_base".SF_OpportunityLineItem WHERE id in
(SELECT STG.id FROM SF_OpportunityLineItem_stg_Tmp_Key STG JOIN SF_OpportunityLineItem_base_Tmp
ON STG.id = SF_OpportunityLineItem_base_Tmp.id AND STG.LastModifiedDate >= SF_OpportunityLineItem_base_Tmp.LastModifiedDate);

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."SF_OpportunityLineItem_HIST"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_OpportunityLineItem WHERE id in
(SELECT STG.id FROM SF_OpportunityLineItem_stg_Tmp_Key STG JOIN SF_OpportunityLineItem_base_Tmp
ON STG.id = SF_OpportunityLineItem_base_Tmp.id AND STG.LastModifiedDate >= SF_OpportunityLineItem_base_Tmp.LastModifiedDate);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_OpportunityLineItem
(
Id
,OpportunityId
,SortOrder
,PricebookEntryId
,Product2Id
,ProductCode
,Name
,CurrencyIsoCode
,Quantity
,TotalPrice
,UnitPrice
,ListPrice
,ServiceDate
,Description
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,IsDeleted
,Apttus_Approval__Approval_Status__c
,SWT_Product_Type__c
,SWT_Pillar_Description_Text__c
,HPSW_SaaS_Term_Months__c
,HPSW_Total_SaaS_ACV__c
,SWT_Total_Price_USD__c
,SWT_Tier_Based_Discount_Value__c
,SWT_Tier_Based_Discount__c
,SWT_Product_Sub_Type__c
,SWT_Product_Family__c
,SWT_ProductType__c
,SWT_Deal_Reg_Discount__c
,SWT_Deal_Reg_Discount_Value__c
,SWT_TotalPriceUSD__c
,SWT_Sales_Price_USD__c
,SWT_Renewal_M1_Rev_USD__c
,SWT_Renewal_M2_Rev_USD__c
,SWT_Business_Area__c
,SWT_Renewal_M3_Rev_USD__c
,SWT_Renewal_Total_CQ_Rev_USD__c
,SWT_Support_Level__c
,SWT_Renewable__c
,SWT_Account__c
,Discount
,Subtotal
,SWT_Asset_End_Date__c
,SWT_Asset_Start_Date__c
,SWT_AssetLineItem__c
,SWT_Proposal_Line_Item__c
,SWT_Line_Type__c
,OptionId__c
,LineType__c
,SWT_External_ID__c
,SWT_ListPrice_CRM__c
,SWT_Quote_End_Date__c
,SWT_Quote_Start_Date__c
,IsOptionRollupLine__c
,SWT_Business_Unit__c
,SWT_Pillar_Code__c
,SWT_Product_Category__c
,SWT_Product_Config_Type__c
,SWT_ProductPillars__c
,SWT_Quote_Term__c
,SWT_Total_Saas_ACV__c
,SWT_Opportunity_Record_Type__c
,SWT_INS_DT
,SWT_Ins_Date_Backup
)
SELECT DISTINCT 
SF_OpportunityLineItem_stg_Tmp.Id
,OpportunityId
,SortOrder
,PricebookEntryId
,Product2Id
,ProductCode
,Name
,CurrencyIsoCode
,Quantity
,TotalPrice
,UnitPrice
,ListPrice
,ServiceDate
,Description
,CreatedDate
,CreatedById
,SF_OpportunityLineItem_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,IsDeleted
,Apttus_Approval__Approval_Status__c
,SWT_Product_Type__c
,SWT_Pillar_Description_Text__c
,HPSW_SaaS_Term_Months__c
,HPSW_Total_SaaS_ACV__c
,SWT_Total_Price_USD__c
,SWT_Tier_Based_Discount_Value__c
,SWT_Tier_Based_Discount__c
,SWT_Product_Sub_Type__c
,SWT_Product_Family__c
,SWT_ProductType__c
,SWT_Deal_Reg_Discount__c
,SWT_Deal_Reg_Discount_Value__c
,SWT_TotalPriceUSD__c
,SWT_Sales_Price_USD__c
,SWT_Renewal_M1_Rev_USD__c
,SWT_Renewal_M2_Rev_USD__c
,SWT_Business_Area__c
,SWT_Renewal_M3_Rev_USD__c
,SWT_Renewal_Total_CQ_Rev_USD__c
,SWT_Support_Level__c
,SWT_Renewable__c
,SWT_Account__c
,Discount
,Subtotal
,SWT_Asset_End_Date__c
,SWT_Asset_Start_Date__c
,SWT_AssetLineItem__c
,SWT_Proposal_Line_Item__c
,SWT_Line_Type__c
,OptionId__c
,LineType__c
,SWT_External_ID__c
,SWT_ListPrice_CRM__c
,SWT_Quote_End_Date__c
,SWT_Quote_Start_Date__c
,IsOptionRollupLine__c
,SWT_Business_Unit__c
,SWT_Pillar_Code__c
,SWT_Product_Category__c
,SWT_Product_Config_Type__c
,SWT_ProductPillars__c
,SWT_Quote_Term__c
,SWT_Total_Saas_ACV__c
,SWT_Opportunity_Record_Type__c
,SYSDATE AS SWT_INS_DT
,SYSDATE AS SWT_Ins_Date_Backup
FROM SF_OpportunityLineItem_stg_Tmp JOIN SF_OpportunityLineItem_stg_Tmp_Key ON SF_OpportunityLineItem_stg_Tmp.id= SF_OpportunityLineItem_stg_Tmp_Key.id AND SF_OpportunityLineItem_stg_Tmp.LastModifiedDate=SF_OpportunityLineItem_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 from "swt_rpt_base".SF_OpportunityLineItem BASE
WHERE SF_OpportunityLineItem_stg_Tmp.id = BASE.id);

COMMIT;


INSERT /*+DIRECT*/ INTO swt_rpt_base.SF_OpportunityLineItem_ID
( Id,
SWT_INS_DT
)
SELECT
Id,
SYSDATE
FROM swt_rpt_stg.SF_OpportunityLineItem_ID;


CREATE LOCAL TEMP TABLE SF_OpportunityLineItem_base_deleted ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_base.SF_OpportunityLineItem where IsDeleted <> 'true' and Id not in ( select distinct Id from swt_rpt_stg.SF_OpportunityLineItem_ID))
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;

DELETE /*+DIRECT*/ FROM swt_rpt_base.SF_OpportunityLineItem where IsDeleted <> 'true' and Id not in ( select distinct Id from swt_rpt_stg.SF_OpportunityLineItem_ID);

INSERT /*+DIRECT*/ INTO swt_rpt_base.SF_OpportunityLineItem_Deleted_Ids
( Id,
SWT_INS_DT,
status
)
SELECT
Id,
SYSDATE,
'deleted'
FROM SF_OpportunityLineItem_base_deleted;

INSERT /*+DIRECT*/ INTO swt_rpt_base.SF_OpportunityLineItem
(
Id
,OpportunityId
,SortOrder
,PricebookEntryId
,Product2Id
,ProductCode
,Name
,CurrencyIsoCode
,Quantity
,TotalPrice
,UnitPrice
,ListPrice
,ServiceDate
,Description
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,IsDeleted
,Apttus_Approval__Approval_Status__c
,SWT_Product_Type__c
,SWT_Pillar_Description_Text__c
,HPSW_SaaS_Term_Months__c
,HPSW_Total_SaaS_ACV__c
,SWT_Total_Price_USD__c
,SWT_Tier_Based_Discount_Value__c
,SWT_Tier_Based_Discount__c
,SWT_Product_Sub_Type__c
,SWT_Product_Family__c
,SWT_ProductType__c
,SWT_Deal_Reg_Discount__c
,SWT_Deal_Reg_Discount_Value__c
,SWT_TotalPriceUSD__c
,SWT_Sales_Price_USD__c
,SWT_Renewal_M1_Rev_USD__c
,SWT_Renewal_M2_Rev_USD__c
,SWT_Business_Area__c
,SWT_Renewal_M3_Rev_USD__c
,SWT_Renewal_Total_CQ_Rev_USD__c
,SWT_Support_Level__c
,SWT_Renewable__c
,SWT_Account__c
,Subtotal
,Discount
,SWT_INS_DT
,SWT_Asset_End_Date__c
,SWT_Asset_Start_Date__c
,SWT_AssetLineItem__c
,SWT_Proposal_Line_Item__c
,SWT_Line_Type__c
,OptionId__c
,LineType__c
,SWT_External_ID__c
,SWT_ListPrice_CRM__c
,SWT_Quote_End_Date__c
,SWT_Quote_Start_Date__c
,IsOptionRollupLine__c
,SWT_Business_Unit__c
,SWT_Pillar_Code__c
,SWT_Product_Category__c
,SWT_Product_Config_Type__c
,SWT_ProductPillars__c
,SWT_Quote_Term__c
,SWT_Total_Saas_ACV__c
,SWT_Opportunity_Record_Type__c
,SWT_Ins_Date_Backup)
SELECT
Id
,OpportunityId
,SortOrder
,PricebookEntryId
,Product2Id
,ProductCode
,Name
,CurrencyIsoCode
,Quantity
,TotalPrice
,UnitPrice
,ListPrice
,ServiceDate
,Description
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,'true'
,Apttus_Approval__Approval_Status__c
,SWT_Product_Type__c
,SWT_Pillar_Description_Text__c
,HPSW_SaaS_Term_Months__c
,HPSW_Total_SaaS_ACV__c
,SWT_Total_Price_USD__c
,SWT_Tier_Based_Discount_Value__c
,SWT_Tier_Based_Discount__c
,SWT_Product_Sub_Type__c
,SWT_Product_Family__c
,SWT_ProductType__c
,SWT_Deal_Reg_Discount__c
,SWT_Deal_Reg_Discount_Value__c
,SWT_TotalPriceUSD__c
,SWT_Sales_Price_USD__c
,SWT_Renewal_M1_Rev_USD__c
,SWT_Renewal_M2_Rev_USD__c
,SWT_Business_Area__c
,SWT_Renewal_M3_Rev_USD__c
,SWT_Renewal_Total_CQ_Rev_USD__c
,SWT_Support_Level__c
,SWT_Renewable__c
,SWT_Account__c
,Subtotal
,Discount
,sysdate
,SWT_Asset_End_Date__c
,SWT_Asset_Start_Date__c
,SWT_AssetLineItem__c
,SWT_Proposal_Line_Item__c
,SWT_Line_Type__c
,OptionId__c
,LineType__c
,SWT_External_ID__c
,SWT_ListPrice_CRM__c
,SWT_Quote_End_Date__c
,SWT_Quote_Start_Date__c
,IsOptionRollupLine__c
,SWT_Business_Unit__c
,SWT_Pillar_Code__c
,SWT_Product_Category__c
,SWT_Product_Config_Type__c
,SWT_ProductPillars__c
,SWT_Quote_Term__c
,SWT_Total_Saas_ACV__c
,SWT_Opportunity_Record_Type__c
,SWT_INS_DT
FROM 
SF_OpportunityLineItem_base_deleted;



CREATE LOCAL TEMP TABLE SF_OpportunityLineItem_base_active ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_base.SF_OpportunityLineItem where IsDeleted ='true' and Id in ( select distinct Id from swt_rpt_stg.SF_OpportunityLineItem_ID))
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;

DELETE /*+DIRECT*/ FROM swt_rpt_base.SF_OpportunityLineItem where IsDeleted ='true' and Id in ( select distinct Id from swt_rpt_stg.SF_OpportunityLineItem_ID);

INSERT /*+DIRECT*/ INTO swt_rpt_base.SF_OpportunityLineItem_Deleted_Ids
( Id,
SWT_INS_DT,
status
)
SELECT
Id,
SYSDATE,
'activated'
FROM SF_OpportunityLineItem_base_active;

INSERT /*+DIRECT*/ INTO swt_rpt_base.SF_OpportunityLineItem
(
Id
,OpportunityId
,SortOrder
,PricebookEntryId
,Product2Id
,ProductCode
,Name
,CurrencyIsoCode
,Quantity
,TotalPrice
,UnitPrice
,ListPrice
,ServiceDate
,Description
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,IsDeleted
,Apttus_Approval__Approval_Status__c
,SWT_Product_Type__c
,SWT_Pillar_Description_Text__c
,HPSW_SaaS_Term_Months__c
,HPSW_Total_SaaS_ACV__c
,SWT_Total_Price_USD__c
,SWT_Tier_Based_Discount_Value__c
,SWT_Tier_Based_Discount__c
,SWT_Product_Sub_Type__c
,SWT_Product_Family__c
,SWT_ProductType__c
,SWT_Deal_Reg_Discount__c
,SWT_Deal_Reg_Discount_Value__c
,SWT_TotalPriceUSD__c
,SWT_Sales_Price_USD__c
,SWT_Renewal_M1_Rev_USD__c
,SWT_Renewal_M2_Rev_USD__c
,SWT_Business_Area__c
,SWT_Renewal_M3_Rev_USD__c
,SWT_Renewal_Total_CQ_Rev_USD__c
,SWT_Support_Level__c
,SWT_Renewable__c
,SWT_Account__c
,Subtotal
,Discount
,SWT_INS_DT
,SWT_Asset_End_Date__c
,SWT_Asset_Start_Date__c
,SWT_AssetLineItem__c
,SWT_Proposal_Line_Item__c
,SWT_Line_Type__c
,OptionId__c
,LineType__c
,SWT_External_ID__c
,SWT_ListPrice_CRM__c
,SWT_Quote_End_Date__c
,SWT_Quote_Start_Date__c
,IsOptionRollupLine__c
,SWT_Business_Unit__c
,SWT_Pillar_Code__c
,SWT_Product_Category__c
,SWT_Product_Config_Type__c
,SWT_ProductPillars__c
,SWT_Quote_Term__c
,SWT_Total_Saas_ACV__c
,SWT_Opportunity_Record_Type__c
,SWT_Ins_Date_Backup)
SELECT
Id
,OpportunityId
,SortOrder
,PricebookEntryId
,Product2Id
,ProductCode
,Name
,CurrencyIsoCode
,Quantity
,TotalPrice
,UnitPrice
,ListPrice
,ServiceDate
,Description
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,'false'
,Apttus_Approval__Approval_Status__c
,SWT_Product_Type__c
,SWT_Pillar_Description_Text__c
,HPSW_SaaS_Term_Months__c
,HPSW_Total_SaaS_ACV__c
,SWT_Total_Price_USD__c
,SWT_Tier_Based_Discount_Value__c
,SWT_Tier_Based_Discount__c
,SWT_Product_Sub_Type__c
,SWT_Product_Family__c
,SWT_ProductType__c
,SWT_Deal_Reg_Discount__c
,SWT_Deal_Reg_Discount_Value__c
,SWT_TotalPriceUSD__c
,SWT_Sales_Price_USD__c
,SWT_Renewal_M1_Rev_USD__c
,SWT_Renewal_M2_Rev_USD__c
,SWT_Business_Area__c
,SWT_Renewal_M3_Rev_USD__c
,SWT_Renewal_Total_CQ_Rev_USD__c
,SWT_Support_Level__c
,SWT_Renewable__c
,SWT_Account__c
,Subtotal
,Discount
,sysdate
,SWT_Asset_End_Date__c
,SWT_Asset_Start_Date__c
,SWT_AssetLineItem__c
,SWT_Proposal_Line_Item__c
,SWT_Line_Type__c
,OptionId__c
,LineType__c
,SWT_External_ID__c
,SWT_ListPrice_CRM__c
,SWT_Quote_End_Date__c
,SWT_Quote_Start_Date__c
,IsOptionRollupLine__c
,SWT_Business_Unit__c
,SWT_Pillar_Code__c
,SWT_Product_Category__c
,SWT_Product_Config_Type__c
,SWT_ProductPillars__c
,SWT_Quote_Term__c
,SWT_Total_Saas_ACV__c
,SWT_Opportunity_Record_Type__c
,SWT_INS_DT
FROM 
SF_OpportunityLineItem_base_active;


COMMIT;

Update swt_rpt_base.SF_OpportunityLineItem set IsDeleted = 'true' where id in
('00k4100000KJTkxAAH','00k4100000KJTkyAAH','00k4100000KJTkzAAH','00k4100000LQYEDAA5','00k4100000LQYEEAA5','00k4100000KpcX4AAJ','00k4100000KpcX5AAJ','00k4100000KpcX6AAJ','00k4100000KpcX7AAJ','00k4100000KpcX8AAJ','00k4100000IqiPYAAZ');

COMMIT;

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_OpportunityLineItem' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_OpportunityLineItem' and  COMPLTN_STAT = 'N');


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
select 'SFDC','SF_OpportunityLineItem',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.SF_OpportunityLineItem where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


select do_tm_task('mergeout','swt_rpt_stg.SF_OpportunityLineItem_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_OpportunityLineItem');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_OpportunityLineItem');
select ANALYZE_STATISTICS('swt_rpt_base.SF_OpportunityLineItem_Deleted_Ids');
TRUNCATE TABLE swt_rpt_stg.SF_OpportunityLineItem_Id;


