/****
****Script Name	  : AT_Apttus_Config2__ProductOptionPrice__c.sql
****Description   : Incremental data load for AT_Apttus_Config2__ProductOptionPrice__c
****/

/* Setting timing on**/
\timing

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."AT_Apttus_Config2__ProductOptionPrice__c";

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
select 'APTTUS','AT_Apttus_Config2__ProductOptionPrice__c',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';
Commit;  

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".AT_Apttus_Config2__ProductOptionPrice__c_Hist select * from "swt_rpt_stg".AT_Apttus_Config2__ProductOptionPrice__c;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.AT_Apttus_Config2__ProductOptionPrice__c where id in (
select id from swt_rpt_stg.AT_Apttus_Config2__ProductOptionPrice__c group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);

delete from swt_rpt_stg.AT_Apttus_Config2__ProductOptionPrice__c where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.AT_Apttus_Config2__ProductOptionPrice__c.id=t2.id and swt_rpt_stg.AT_Apttus_Config2__ProductOptionPrice__c.auto_id<t2.auto_id);

commit;

CREATE LOCAL TEMP TABLE AT_Apttus_Config2__ProductOptionPrice__c_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.AT_Apttus_Config2__ProductOptionPrice__c)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.AT_Apttus_Config2__ProductOptionPrice__c;

CREATE LOCAL TEMP TABLE AT_Apttus_Config2__ProductOptionPrice__c_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,LastModifiedDate FROM swt_rpt_base.AT_Apttus_Config2__ProductOptionPrice__c)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE AT_Apttus_Config2__ProductOptionPrice__c_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(LastModifiedDate) as LastModifiedDate FROM AT_Apttus_Config2__ProductOptionPrice__c_stg_Tmp group by id)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;

/* Inserting deleted Stage table data into Historical Table */
INSERT /*+DIRECT*/ INTO "swt_rpt_stg".AT_Apttus_Config2__ProductOptionPrice__c_Hist
(
Id
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,Apttus_Config2__PriceListId__c
,Apttus_Config2__AdjustmentAmount__c
,Apttus_Config2__AdjustmentType__c
,Apttus_Config2__AllocateGroupAdjustment__c
,Apttus_Config2__AllowManualAdjustment__c
,Apttus_Config2__ChargeType__c
,Apttus_Config2__ContractPrice__c
,Apttus_Config2__HideInvoiceDisplay__c
,Apttus_Config2__IsQuantityReadOnly__c
,Apttus_Config2__IsSellingTermReadOnly__c
,Apttus_Config2__PriceIncludedInBundle__c
,Apttus_Config2__PriceOverride__c
,Apttus_Config2__ProductOptionId__c
,Apttus_Config2__RollupPriceMethod__c
,Apttus_Config2__RollupPriceToBundle__c
,Apttus_Config2__Sequence__c
,APTS_Ext_ID__c
,LD_DT
,SWT_INS_DT
,d_source
)
SELECT 
Id
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,Apttus_Config2__PriceListId__c
,Apttus_Config2__AdjustmentAmount__c
,Apttus_Config2__AdjustmentType__c
,Apttus_Config2__AllocateGroupAdjustment__c
,Apttus_Config2__AllowManualAdjustment__c
,Apttus_Config2__ChargeType__c
,Apttus_Config2__ContractPrice__c
,Apttus_Config2__HideInvoiceDisplay__c
,Apttus_Config2__IsQuantityReadOnly__c
,Apttus_Config2__IsSellingTermReadOnly__c
,Apttus_Config2__PriceIncludedInBundle__c
,Apttus_Config2__PriceOverride__c
,Apttus_Config2__ProductOptionId__c
,Apttus_Config2__RollupPriceMethod__c
,Apttus_Config2__RollupPriceToBundle__c
,Apttus_Config2__Sequence__c
,APTS_Ext_ID__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".AT_Apttus_Config2__ProductOptionPrice__c WHERE id in
(SELECT STG.id FROM AT_Apttus_Config2__ProductOptionPrice__c_stg_Tmp_Key STG JOIN AT_Apttus_Config2__ProductOptionPrice__c_base_Tmp
ON STG.id = AT_Apttus_Config2__ProductOptionPrice__c_base_Tmp.id AND STG.LastModifiedDate >= AT_Apttus_Config2__ProductOptionPrice__c_base_Tmp.LastModifiedDate);

/* Deleting before seven days data from current date in the Historical Table */

/*delete /*+DIRECT*/ from "swt_rpt_stg"."AT_Apttus_Config2__ProductOptionPrice__c_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date; */

/* Incremental VSQL script for loading data from Stage to Base */ 

DELETE /*+DIRECT*/ FROM "swt_rpt_base".AT_Apttus_Config2__ProductOptionPrice__c WHERE id in
(SELECT STG.id FROM AT_Apttus_Config2__ProductOptionPrice__c_stg_Tmp_Key STG JOIN AT_Apttus_Config2__ProductOptionPrice__c_base_Tmp
ON STG.id = AT_Apttus_Config2__ProductOptionPrice__c_base_Tmp.id AND STG.LastModifiedDate >= AT_Apttus_Config2__ProductOptionPrice__c_base_Tmp.LastModifiedDate);


INSERT /*+DIRECT*/ INTO "swt_rpt_base".AT_Apttus_Config2__ProductOptionPrice__c
(
Id
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,Apttus_Config2__PriceListId__c
,Apttus_Config2__AdjustmentAmount__c
,Apttus_Config2__AdjustmentType__c
,Apttus_Config2__AllocateGroupAdjustment__c
,Apttus_Config2__AllowManualAdjustment__c
,Apttus_Config2__ChargeType__c
,Apttus_Config2__ContractPrice__c
,Apttus_Config2__HideInvoiceDisplay__c
,Apttus_Config2__IsQuantityReadOnly__c
,Apttus_Config2__IsSellingTermReadOnly__c
,Apttus_Config2__PriceIncludedInBundle__c
,Apttus_Config2__PriceOverride__c
,Apttus_Config2__ProductOptionId__c
,Apttus_Config2__RollupPriceMethod__c
,Apttus_Config2__RollupPriceToBundle__c
,Apttus_Config2__Sequence__c
,APTS_Ext_ID__c
,SWT_INS_DT
)
SELECT DISTINCT 
AT_Apttus_Config2__ProductOptionPrice__c_stg_Tmp.Id
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,AT_Apttus_Config2__ProductOptionPrice__c_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,Apttus_Config2__PriceListId__c
,Apttus_Config2__AdjustmentAmount__c
,Apttus_Config2__AdjustmentType__c
,Apttus_Config2__AllocateGroupAdjustment__c
,Apttus_Config2__AllowManualAdjustment__c
,Apttus_Config2__ChargeType__c
,Apttus_Config2__ContractPrice__c
,Apttus_Config2__HideInvoiceDisplay__c
,Apttus_Config2__IsQuantityReadOnly__c
,Apttus_Config2__IsSellingTermReadOnly__c
,Apttus_Config2__PriceIncludedInBundle__c
,Apttus_Config2__PriceOverride__c
,Apttus_Config2__ProductOptionId__c
,Apttus_Config2__RollupPriceMethod__c
,Apttus_Config2__RollupPriceToBundle__c
,Apttus_Config2__Sequence__c
,APTS_Ext_ID__c
,SYSDATE
FROM AT_Apttus_Config2__ProductOptionPrice__c_stg_Tmp JOIN AT_Apttus_Config2__ProductOptionPrice__c_stg_Tmp_Key ON AT_Apttus_Config2__ProductOptionPrice__c_stg_Tmp.id= AT_Apttus_Config2__ProductOptionPrice__c_stg_Tmp_Key.id AND AT_Apttus_Config2__ProductOptionPrice__c_stg_Tmp.LastModifiedDate=AT_Apttus_Config2__ProductOptionPrice__c_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".AT_Apttus_Config2__ProductOptionPrice__c BASE
WHERE AT_Apttus_Config2__ProductOptionPrice__c_stg_Tmp.id = BASE.id);


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
select 'APTTUS','AT_Apttus_Config2__ProductOptionPrice__c',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.AT_Apttus_Config2__ProductOptionPrice__c where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

/* Deleting partial audit entry */

/*DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'APTTUS' and
TBL_NM = 'AT_Apttus_Config2__ProductOptionPrice__c' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'APTTUS' and  TBL_NM = 'AT_Apttus_Config2__ProductOptionPrice__c' and  COMPLTN_STAT = 'N');

Commit;
*/

SELECT DROP_PARTITIONS('swt_rpt_stg.AT_Apttus_Config2__ProductOptionPrice__c_Hist', TIMESTAMPADD(day,-7,getdate())::date);
/*select do_tm_task('mergeout','swt_rpt_stg.AT_Apttus_Config2__ProductOptionPrice__c_Hist');*/
select do_tm_task('mergeout','swt_rpt_base.AT_Apttus_Config2__ProductOptionPrice__c');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.AT_Apttus_Config2__ProductOptionPrice__c');






