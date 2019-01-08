
/****
****Script Name   : ZU_RatePlanCharge.sql
****Description   : Incremental data load for ZU_RatePlanCharge
****/
/* Setting timing on**/
\timing
\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."ZU_RatePlanCharge";

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
select 'ZUORA','ZU_RatePlanCharge',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+Direct*/ INTO swt_rpt_stg.ZU_RatePlanCharge_Hist SELECT * from swt_rpt_stg.ZU_RatePlanCharge;
COMMIT;


CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS 
select max(auto_id) as auto_id,ID from swt_rpt_stg.ZU_RatePlanCharge where ID in(
select ID from swt_rpt_stg.ZU_RatePlanCharge
group by ID,UpdatedDate having count(1)>1)
group by ID;


delete from swt_rpt_stg.ZU_RatePlanCharge  where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.ZU_RatePlanCharge.ID=t2.ID and swt_rpt_stg.ZU_RatePlanCharge.auto_id<t2.auto_id);

COMMIT;

CREATE LOCAL TEMP TABLE ZU_RatePlanCharge_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.ZU_RatePlanCharge)
SEGMENTED BY HASH(ID,UpdatedDate) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.ZU_RatePlanCharge;

CREATE LOCAL TEMP TABLE ZU_RatePlanCharge_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,UpdatedDate FROM swt_rpt_base.ZU_RatePlanCharge)
SEGMENTED BY HASH(ID,UpdatedDate) ALL NODES;


CREATE LOCAL TEMP TABLE ZU_RatePlanCharge_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(UpdatedDate) as UpdatedDate FROM ZU_RatePlanCharge_stg_Tmp group by id)
SEGMENTED BY HASH(ID,UpdatedDate) ALL NODES;



/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.ZU_RatePlanCharge_Hist
(
Id
,AccountingCode
,AdditionalDiscountAmount__c
,AdditionalDiscountPercent__c
,ApplyDiscountTo
,ApttusLineItemId__c
,ApttusOrderLineItemID__c
,BillCycleDay
,BillCycleType
,BillingPeriod
,BillingPeriodAlignment
,BillingTiming
,ChargedThroughDate
,ChargeModel
,ChargeNumber
,ChargeType
,ContractualDiscountAmount__c
,ContractualDiscountPercent__c
,CreatedById
,CreatedDate
,Description
,DiscountLevel
,DMRC
,DTCV
,EffectiveEndDate
,EffectiveStartDate
,EndDateCondition
,ExchangeRate__c
,IsLastSegment
,LineType__c
,ListPriceBase
,MRR
,Name
,NetSuiteBusinessArea__c
,NetSuiteGLAccountItem__c
,NumberOfPeriods
,OriginalId
,OverageCalculationOption
,OverageUnusedUnitsCreditOption
,PartnerDiscountAmount__c
,PartnerDiscountPercent__c
,Price
,PriceChangeOption
,PriceIncreasePercentage
,ProcessedThroughDate
,ProductRatePlanChargeId
,PromotionalDiscountAmount__c
,PromotionalDiscountPercent__c
,Quantity
,RatePlanId
,RevRecCode
,RevRecTriggerCondition
,Segment
,Sequencenumber__c
,LocationAddress__c
,SpecificBillingPeriod
,SpecificEndDate
,TCV
,TriggerDate
,TriggerEvent
,UnitListPrice__c
,UnusedUnitsCreditRates
,UOM
,UpdatedById
,UpdatedDate
,UpToPeriods
,UpToPeriodsType
,UsageRecordRatingOption
,UseDiscountSpecificAccountingCode
,Version
,WeeklyBillCycleDay
,LocationCity__c
,LocationCountry__c
,LocationState__c
,LocationZipCode__c
,ApplianceSerialNumber__c
,PONumber__c
,BillOfLading__c
,LD_DT
,SWT_INS_DT
,d_source
)
SELECT
Id
,AccountingCode
,AdditionalDiscountAmount__c
,AdditionalDiscountPercent__c
,ApplyDiscountTo
,ApttusLineItemId__c
,ApttusOrderLineItemID__c
,BillCycleDay
,BillCycleType
,BillingPeriod
,BillingPeriodAlignment
,BillingTiming
,ChargedThroughDate
,ChargeModel
,ChargeNumber
,ChargeType
,ContractualDiscountAmount__c
,ContractualDiscountPercent__c
,CreatedById
,CreatedDate
,Description
,DiscountLevel
,DMRC
,DTCV
,EffectiveEndDate
,EffectiveStartDate
,EndDateCondition
,ExchangeRate__c
,IsLastSegment
,LineType__c
,ListPriceBase
,MRR
,Name
,NetSuiteBusinessArea__c
,NetSuiteGLAccountItem__c
,NumberOfPeriods
,OriginalId
,OverageCalculationOption
,OverageUnusedUnitsCreditOption
,PartnerDiscountAmount__c
,PartnerDiscountPercent__c
,Price
,PriceChangeOption
,PriceIncreasePercentage
,ProcessedThroughDate
,ProductRatePlanChargeId
,PromotionalDiscountAmount__c
,PromotionalDiscountPercent__c
,Quantity
,RatePlanId
,RevRecCode
,RevRecTriggerCondition
,Segment
,Sequencenumber__c
,LocationAddress__c
,SpecificBillingPeriod
,SpecificEndDate
,TCV
,TriggerDate
,TriggerEvent
,UnitListPrice__c
,UnusedUnitsCreditRates
,UOM
,UpdatedById
,UpdatedDate
,UpToPeriods
,UpToPeriodsType
,UsageRecordRatingOption
,UseDiscountSpecificAccountingCode
,Version
,WeeklyBillCycleDay
,LocationCity__c
,LocationCountry__c
,LocationState__c
,LocationZipCode__c
,ApplianceSerialNumber__c
,PONumber__c
,BillOfLading__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".ZU_RatePlanCharge WHERE id in
(SELECT STG.id FROM ZU_RatePlanCharge_stg_Tmp_Key STG JOIN ZU_RatePlanCharge_base_Tmp
ON STG.id = ZU_RatePlanCharge_base_Tmp.id AND STG.UpdatedDate >= ZU_RatePlanCharge_base_Tmp.UpdatedDate);




/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from swt_rpt_stg.ZU_RatePlanCharge_Hist  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */


DELETE /*+DIRECT*/ FROM "swt_rpt_base".ZU_RatePlanCharge WHERE id in
(SELECT STG.id FROM ZU_RatePlanCharge_stg_Tmp_Key STG JOIN ZU_RatePlanCharge_base_Tmp
ON STG.id = ZU_RatePlanCharge_base_Tmp.id AND STG.UpdatedDate >= ZU_RatePlanCharge_base_Tmp.UpdatedDate);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".ZU_RatePlanCharge
(
Id
,AccountingCode
,AdditionalDiscountAmount__c
,AdditionalDiscountPercent__c
,ApplyDiscountTo
,ApttusLineItemId__c
,ApttusOrderLineItemID__c
,BillCycleDay
,BillCycleType
,BillingPeriod
,BillingPeriodAlignment
,BillingTiming
,ChargedThroughDate
,ChargeModel
,ChargeNumber
,ChargeType
,ContractualDiscountAmount__c
,ContractualDiscountPercent__c
,CreatedById
,CreatedDate
,Description
,DiscountLevel
,DMRC
,DTCV
,EffectiveEndDate
,EffectiveStartDate
,EndDateCondition
,ExchangeRate__c
,IsLastSegment
,LineType__c
,ListPriceBase
,MRR
,Name
,NetSuiteBusinessArea__c
,NetSuiteGLAccountItem__c
,NumberOfPeriods
,OriginalId
,OverageCalculationOption
,OverageUnusedUnitsCreditOption
,PartnerDiscountAmount__c
,PartnerDiscountPercent__c
,Price
,PriceChangeOption
,PriceIncreasePercentage
,ProcessedThroughDate
,ProductRatePlanChargeId
,PromotionalDiscountAmount__c
,PromotionalDiscountPercent__c
,Quantity
,RatePlanId
,RevRecCode
,RevRecTriggerCondition
,Segment
,Sequencenumber__c
,LocationAddress__c
,SpecificBillingPeriod
,SpecificEndDate
,TCV
,TriggerDate
,TriggerEvent
,UnitListPrice__c
,UnusedUnitsCreditRates
,UOM
,UpdatedById
,UpdatedDate
,UpToPeriods
,UpToPeriodsType
,UsageRecordRatingOption
,UseDiscountSpecificAccountingCode
,Version
,WeeklyBillCycleDay
,LocationCity__c
,LocationCountry__c
,LocationState__c
,LocationZipCode__c
,ApplianceSerialNumber__c
,PONumber__c
,BillOfLading__c
,SWT_INS_DT
)
SELECT DISTINCT 
ZU_RatePlanCharge_stg_Tmp.Id
,AccountingCode
,AdditionalDiscountAmount__c
,AdditionalDiscountPercent__c
,ApplyDiscountTo
,ApttusLineItemId__c
,ApttusOrderLineItemID__c
,BillCycleDay
,BillCycleType
,BillingPeriod
,BillingPeriodAlignment
,BillingTiming
,ChargedThroughDate
,ChargeModel
,ChargeNumber
,ChargeType
,ContractualDiscountAmount__c
,ContractualDiscountPercent__c
,CreatedById
,CreatedDate
,Description
,DiscountLevel
,DMRC
,DTCV
,EffectiveEndDate
,EffectiveStartDate
,EndDateCondition
,ExchangeRate__c
,IsLastSegment
,LineType__c
,ListPriceBase
,MRR
,Name
,NetSuiteBusinessArea__c
,NetSuiteGLAccountItem__c
,NumberOfPeriods
,OriginalId
,OverageCalculationOption
,OverageUnusedUnitsCreditOption
,PartnerDiscountAmount__c
,PartnerDiscountPercent__c
,Price
,PriceChangeOption
,PriceIncreasePercentage
,ProcessedThroughDate
,ProductRatePlanChargeId
,PromotionalDiscountAmount__c
,PromotionalDiscountPercent__c
,Quantity
,RatePlanId
,RevRecCode
,RevRecTriggerCondition
,Segment
,Sequencenumber__c
,LocationAddress__c
,SpecificBillingPeriod
,SpecificEndDate
,TCV
,TriggerDate
,TriggerEvent
,UnitListPrice__c
,UnusedUnitsCreditRates
,UOM
,UpdatedById
,ZU_RatePlanCharge_stg_Tmp.UpdatedDate
,UpToPeriods
,UpToPeriodsType
,UsageRecordRatingOption
,UseDiscountSpecificAccountingCode
,Version
,WeeklyBillCycleDay
,LocationCity__c
,LocationCountry__c
,LocationState__c
,LocationZipCode__c
,ApplianceSerialNumber__c
,PONumber__c
,BillOfLading__c
,SYSDATE AS SWT_INS_DT
FROM ZU_RatePlanCharge_stg_Tmp JOIN ZU_RatePlanCharge_stg_Tmp_Key ON ZU_RatePlanCharge_stg_Tmp.id= ZU_RatePlanCharge_stg_Tmp_Key.id AND ZU_RatePlanCharge_stg_Tmp.UpdatedDate=ZU_RatePlanCharge_stg_Tmp_Key.UpdatedDate
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".ZU_RatePlanCharge BASE
WHERE ZU_RatePlanCharge_stg_Tmp.id = BASE.id);


/*DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'ZUORA' and
TBL_NM = 'ZU_RatePlanCharge' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'ZUORA' and  TBL_NM = 'ZU_RatePlanCharge' and  COMPLTN_STAT = 'N');
*/


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
select 'ZUORA','ZU_RatePlanCharge',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.ZU_RatePlanCharge where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

SELECT DO_TM_TASK('mergeout', 'swt_rpt_base.ZU_RatePlanCharge');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.ZU_RatePlanCharge_Hist');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.ZU_RatePlanCharge');


