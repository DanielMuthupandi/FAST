/****
****Script Name	  : AT_Apttus_Config2__AgreementPriceRule__c.sql
****Description   : Incremental data load for AT_Apttus_Config2__AgreementPriceRule__c
****/

/* Setting timing on**/
\timing

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."AT_Apttus_Config2__AgreementPriceRule__c";

/* Inserting values into the Audit table  */

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
select 'APTTUS','AT_Apttus_Config2__AgreementPriceRule__c',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;  

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".AT_Apttus_Config2__AgreementPriceRule__c_Hist select * from "swt_rpt_stg".AT_Apttus_Config2__AgreementPriceRule__c;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.AT_Apttus_Config2__AgreementPriceRule__c where id in (
select id from swt_rpt_stg.AT_Apttus_Config2__AgreementPriceRule__c group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);

delete from swt_rpt_stg.AT_Apttus_Config2__AgreementPriceRule__c where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.AT_Apttus_Config2__AgreementPriceRule__c.id=t2.id and swt_rpt_stg.AT_Apttus_Config2__AgreementPriceRule__c.auto_id<t2.auto_id);

commit;


CREATE LOCAL TEMP TABLE AT_Apttus_Config2__AgreementPriceRule__c_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.AT_Apttus_Config2__AgreementPriceRule__c)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.AT_Apttus_Config2__AgreementPriceRule__c;

CREATE LOCAL TEMP TABLE AT_Apttus_Config2__AgreementPriceRule__c_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,LastModifiedDate FROM swt_rpt_base.AT_Apttus_Config2__AgreementPriceRule__c)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE AT_Apttus_Config2__AgreementPriceRule__c_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(LastModifiedDate) as LastModifiedDate FROM AT_Apttus_Config2__AgreementPriceRule__c_stg_Tmp group by id)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


/* Inserting deleted data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.AT_Apttus_Config2__AgreementPriceRule__c_Hist
(
Id
,OwnerId
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,Apttus_Config2__AccountId__c
,Apttus_Config2__ActivatedDate__c
,Apttus_Config2__AdjustmentAmount__c
,Apttus_Config2__AdjustmentType__c
,Apttus_Config2__AllowRemoval__c
,Apttus_Config2__AncestorId__c
,Apttus_Config2__BundleProductId__c
,Apttus_Config2__ChargeType__c
,Apttus_Config2__ConfigurationId__c
,Apttus_Config2__ContractNumber__c
,Apttus_Config2__Criteria__c
,Apttus_Config2__EffectiveDate__c
,Apttus_Config2__ExpirationDate__c
,Apttus_Config2__IsModifiable__c
,Apttus_Config2__PriceListId__c
,Apttus_Config2__PriceListItemId__c
,Apttus_Config2__ProductCategory__c
,Apttus_Config2__ProductFamily__c
,Apttus_Config2__ProductGroupId__c
,Apttus_Config2__ProductId__c
,Apttus_Config2__ProductOptionId__c
,Apttus_Config2__RuleType__c
,Apttus_Config2__Sequence__c
,Apttus_Config2__Status__c
,Apttus_QPConfig__ProposalId__c
,Apttus_CMConfig__AgreementId__c
,SWT_Billing_Frequency__c
,SWT_Term_Length__c
,SWT_Field_1__c
,SWT_Field_2__c
,SWT_Quantity__c
,SWT_Record_Type__c
,SWT_Extended_List_Price__c
,SWT_Net_Price__c
,SWT_Extended_Net_Price__c
,SWT_Tier_Start_Value__c
,SWT_Tier_End_Value__c
,SWT_Tier_Usage_Rate__c
,SWT_Sequence__c
,SWT_Tier_String_Statement__c
,SWT_Customer_Account_Reference__c
,SWT_Start_Date__c
,SWT_Legacy_SAID__c
,SWT_Ship_To_Address__c
,SWT_Sub_Total__c
,SWT_Support_Level__c
,SWT_Support_Monthly_List_Price__c
,SWT_Discount_Types__c
,SWT_Discount_Values__c
,SWT_Support_monthly_Net_Price__c
,SWT_Option__c
,LD_DT
,SWT_INS_DT
,d_source
)
 select 
Id
,OwnerId
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,Apttus_Config2__AccountId__c
,Apttus_Config2__ActivatedDate__c
,Apttus_Config2__AdjustmentAmount__c
,Apttus_Config2__AdjustmentType__c
,Apttus_Config2__AllowRemoval__c
,Apttus_Config2__AncestorId__c
,Apttus_Config2__BundleProductId__c
,Apttus_Config2__ChargeType__c
,Apttus_Config2__ConfigurationId__c
,Apttus_Config2__ContractNumber__c
,Apttus_Config2__Criteria__c
,Apttus_Config2__EffectiveDate__c
,Apttus_Config2__ExpirationDate__c
,Apttus_Config2__IsModifiable__c
,Apttus_Config2__PriceListId__c
,Apttus_Config2__PriceListItemId__c
,Apttus_Config2__ProductCategory__c
,Apttus_Config2__ProductFamily__c
,Apttus_Config2__ProductGroupId__c
,Apttus_Config2__ProductId__c
,Apttus_Config2__ProductOptionId__c
,Apttus_Config2__RuleType__c
,Apttus_Config2__Sequence__c
,Apttus_Config2__Status__c
,Apttus_QPConfig__ProposalId__c
,Apttus_CMConfig__AgreementId__c
,SWT_Billing_Frequency__c
,SWT_Term_Length__c
,SWT_Field_1__c
,SWT_Field_2__c
,SWT_Quantity__c
,SWT_Record_Type__c
,SWT_Extended_List_Price__c
,SWT_Net_Price__c
,SWT_Extended_Net_Price__c
,SWT_Tier_Start_Value__c
,SWT_Tier_End_Value__c
,SWT_Tier_Usage_Rate__c
,SWT_Sequence__c
,SWT_Tier_String_Statement__c
,SWT_Customer_Account_Reference__c
,SWT_Start_Date__c
,SWT_Legacy_SAID__c
,SWT_Ship_To_Address__c
,SWT_Sub_Total__c
,SWT_Support_Level__c
,SWT_Support_Monthly_List_Price__c
,SWT_Discount_Types__c
,SWT_Discount_Values__c
,SWT_Support_monthly_Net_Price__c
,SWT_Option__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".AT_Apttus_Config2__AgreementPriceRule__c WHERE id in
(SELECT STG.id FROM AT_Apttus_Config2__AgreementPriceRule__c_stg_Tmp_Key STG JOIN AT_Apttus_Config2__AgreementPriceRule__c_base_Tmp
ON STG.id = AT_Apttus_Config2__AgreementPriceRule__c_base_Tmp.id AND STG.LastModifiedDate >= AT_Apttus_Config2__AgreementPriceRule__c_base_Tmp.LastModifiedDate);


/* Deleting before seven days data from current date in the Historical Table */  

/*delete /*+DIRECT*/ from swt_rpt_stg.AT_Apttus_Config2__AgreementPriceRule__c_Hist  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date; */


DELETE /*+DIRECT*/ FROM "swt_rpt_base".AT_Apttus_Config2__AgreementPriceRule__c WHERE id in
(SELECT STG.id FROM AT_Apttus_Config2__AgreementPriceRule__c_stg_Tmp_Key STG JOIN AT_Apttus_Config2__AgreementPriceRule__c_base_Tmp
ON STG.id = AT_Apttus_Config2__AgreementPriceRule__c_base_Tmp.id AND STG.LastModifiedDate >= AT_Apttus_Config2__AgreementPriceRule__c_base_Tmp.LastModifiedDate);


/* Incremental VSQL script for loading data from Stage to Base */

INSERT /*+DIRECT*/ INTO "swt_rpt_base".AT_Apttus_Config2__AgreementPriceRule__c
(
Id
,OwnerId
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,Apttus_Config2__AccountId__c
,Apttus_Config2__ActivatedDate__c
,Apttus_Config2__AdjustmentAmount__c
,Apttus_Config2__AdjustmentType__c
,Apttus_Config2__AllowRemoval__c
,Apttus_Config2__AncestorId__c
,Apttus_Config2__BundleProductId__c
,Apttus_Config2__ChargeType__c
,Apttus_Config2__ConfigurationId__c
,Apttus_Config2__ContractNumber__c
,Apttus_Config2__Criteria__c
,Apttus_Config2__EffectiveDate__c
,Apttus_Config2__ExpirationDate__c
,Apttus_Config2__IsModifiable__c
,Apttus_Config2__PriceListId__c
,Apttus_Config2__PriceListItemId__c
,Apttus_Config2__ProductCategory__c
,Apttus_Config2__ProductFamily__c
,Apttus_Config2__ProductGroupId__c
,Apttus_Config2__ProductId__c
,Apttus_Config2__ProductOptionId__c
,Apttus_Config2__RuleType__c
,Apttus_Config2__Sequence__c
,Apttus_Config2__Status__c
,Apttus_QPConfig__ProposalId__c
,Apttus_CMConfig__AgreementId__c
,SWT_Billing_Frequency__c
,SWT_Term_Length__c
,SWT_Field_1__c
,SWT_Field_2__c
,SWT_Quantity__c
,SWT_Record_Type__c
,SWT_Extended_List_Price__c
,SWT_Net_Price__c
,SWT_Extended_Net_Price__c
,SWT_Tier_Start_Value__c
,SWT_Tier_End_Value__c
,SWT_Tier_Usage_Rate__c
,SWT_Sequence__c
,SWT_Tier_String_Statement__c
,SWT_Customer_Account_Reference__c
,SWT_Start_Date__c
,SWT_Legacy_SAID__c
,SWT_Ship_To_Address__c
,SWT_Sub_Total__c
,SWT_Support_Level__c
,SWT_Support_Monthly_List_Price__c
,SWT_Discount_Types__c
,SWT_Discount_Values__c
,SWT_Support_monthly_Net_Price__c
,SWT_Option__c
,SWT_INS_DT
)
SELECT DISTINCT 
AT_Apttus_Config2__AgreementPriceRule__c_stg_Tmp.Id
,OwnerId
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,AT_Apttus_Config2__AgreementPriceRule__c_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,Apttus_Config2__AccountId__c
,Apttus_Config2__ActivatedDate__c
,Apttus_Config2__AdjustmentAmount__c
,Apttus_Config2__AdjustmentType__c
,Apttus_Config2__AllowRemoval__c
,Apttus_Config2__AncestorId__c
,Apttus_Config2__BundleProductId__c
,Apttus_Config2__ChargeType__c
,Apttus_Config2__ConfigurationId__c
,Apttus_Config2__ContractNumber__c
,Apttus_Config2__Criteria__c
,Apttus_Config2__EffectiveDate__c
,Apttus_Config2__ExpirationDate__c
,Apttus_Config2__IsModifiable__c
,Apttus_Config2__PriceListId__c
,Apttus_Config2__PriceListItemId__c
,Apttus_Config2__ProductCategory__c
,Apttus_Config2__ProductFamily__c
,Apttus_Config2__ProductGroupId__c
,Apttus_Config2__ProductId__c
,Apttus_Config2__ProductOptionId__c
,Apttus_Config2__RuleType__c
,Apttus_Config2__Sequence__c
,Apttus_Config2__Status__c
,Apttus_QPConfig__ProposalId__c
,Apttus_CMConfig__AgreementId__c
,SWT_Billing_Frequency__c
,SWT_Term_Length__c
,SWT_Field_1__c
,SWT_Field_2__c
,SWT_Quantity__c
,SWT_Record_Type__c
,SWT_Extended_List_Price__c
,SWT_Net_Price__c
,SWT_Extended_Net_Price__c
,SWT_Tier_Start_Value__c
,SWT_Tier_End_Value__c
,SWT_Tier_Usage_Rate__c
,SWT_Sequence__c
,SWT_Tier_String_Statement__c
,SWT_Customer_Account_Reference__c
,SWT_Start_Date__c
,SWT_Legacy_SAID__c
,SWT_Ship_To_Address__c
,SWT_Sub_Total__c
,SWT_Support_Level__c
,SWT_Support_Monthly_List_Price__c
,SWT_Discount_Types__c
,SWT_Discount_Values__c
,SWT_Support_monthly_Net_Price__c
,SWT_Option__c
,SYSDATE
FROM AT_Apttus_Config2__AgreementPriceRule__c_stg_Tmp JOIN AT_Apttus_Config2__AgreementPriceRule__c_stg_Tmp_Key ON AT_Apttus_Config2__AgreementPriceRule__c_stg_Tmp.id= AT_Apttus_Config2__AgreementPriceRule__c_stg_Tmp_Key.id AND AT_Apttus_Config2__AgreementPriceRule__c_stg_Tmp.LastModifiedDate=AT_Apttus_Config2__AgreementPriceRule__c_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".AT_Apttus_Config2__AgreementPriceRule__c BASE
WHERE AT_Apttus_Config2__AgreementPriceRule__c_stg_Tmp.id = BASE.id);


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
select 'APTTUS','AT_Apttus_Config2__AgreementPriceRule__c',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.AT_Apttus_Config2__AgreementPriceRule__c where SWT_INS_DT::date = sysdate::date),'Y';

Commit;
		
/* Deleting partial audit entry */

/*DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'APTTUS' and
TBL_NM = 'AT_Apttus_Config2__AgreementPriceRule__c' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'APTTUS' and  TBL_NM = 'AT_Apttus_Config2__AgreementPriceRule__c' and  COMPLTN_STAT = 'N');

Commit;
*/

SELECT DROP_PARTITIONS('swt_rpt_stg.AT_Apttus_Config2__AgreementPriceRule__c_Hist', TIMESTAMPADD(day,-7,getdate())::date);
/*select do_tm_task('mergeout','swt_rpt_stg.AT_Apttus_Config2__AgreementPriceRule__c_Hist');*/
select do_tm_task('mergeout','swt_rpt_base.AT_Apttus_Config2__AgreementPriceRule__c');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.AT_Apttus_Config2__AgreementPriceRule__c');





