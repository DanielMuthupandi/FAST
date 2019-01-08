/****
****Script Name	  : SF_SWT_Addresses__c.sql
****Description   : Incremental data load for SF_SWT_Addresses__c
****/

/*Setting timing on */
\timing

/* SET SESSION AUTOCOMMIT TO OFF; */

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."SF_SWT_Addresses__c";

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
  select 'SFDC','SF_SWT_Addresses__c',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

  Commit; 
  
INSERT /*+Direct*/ INTO swt_rpt_stg.SF_SWT_Addresses__c_Hist SELECT * from swt_rpt_stg.SF_SWT_Addresses__c;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_SWT_Addresses__c where id in (
select id from swt_rpt_stg.SF_SWT_Addresses__c group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);


delete from swt_rpt_stg.SF_SWT_Addresses__c where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_SWT_Addresses__c.id=t2.id and swt_rpt_stg.SF_SWT_Addresses__c.auto_id<t2.auto_id);

commit;

CREATE LOCAL TEMP TABLE SF_SWT_Addresses__c_stg_Tmp ON COMMIT PRESERVE ROWS AS
( 
SELECT DISTINCT * FROM swt_rpt_stg.SF_SWT_Addresses__c)
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.SF_SWT_Addresses__c;

CREATE LOCAL TEMP TABLE SF_SWT_Addresses__c_base_Tmp ON COMMIT PRESERVE ROWS AS
( 
SELECT DISTINCT Id,LastModifiedDate FROM swt_rpt_base.SF_SWT_Addresses__c)
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_SWT_Addresses__c_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(LastModifiedDate) as LastModifiedDate FROM SF_SWT_Addresses__c_stg_Tmp group by id) 
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;
  

 /* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.SF_SWT_Addresses__c_Hist
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
,LastViewedDate
,LastReferencedDate
,SWT_AccountID__c
,SWT_Street__c
,SWT_City__c
,SWT_State__c
,SWT_Postal_Code__c
,SWT_Country__c
,SWT_Ship_to_Indicator__c
,SWT_Bill_to_Indicator__c
,SWT_Sold_to_Indicator__c
,SWT_Address_Validation_Fail_Reason__c
,SWT_Primary_Bill_To__c
,SWT_Primary_Ship_To__c
,SWT_Account_Address_Indicator__c
,Address_Verified__c
,SWT_Process_Status_Value__c
,SWT_Address_Validation_Status__c
,SWT_Account_Update__c
,SWT_City_Area__c
,SWT_Legacy_Address_Name__c
,SWT_Inactive__c
,SWT_Last_Used__c
,SWT_Address_Name__c
,SWT_Country_Group__c
,SWT_Country_ISO_Code__c
,SWT_for_Address_Name__c
,SWT_City_Area_Non_Latin__c
,SWT_Address_Country_Non_Latin__c
,SWT_Address_Zip_Postal_Code_Non_Latin__c
,SWT_Address_State_Province_Non_Latin__c
,SWT_Address_City_Non_Latin__c
,SWT_Address_Street_Non_Latin__c
,SWT_External_ID__c
,LD_DT
,SWT_INS_DT
,d_source
)
 select 
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
,LastViewedDate
,LastReferencedDate
,SWT_AccountID__c
,SWT_Street__c
,SWT_City__c
,SWT_State__c
,SWT_Postal_Code__c
,SWT_Country__c
,SWT_Ship_to_Indicator__c
,SWT_Bill_to_Indicator__c
,SWT_Sold_to_Indicator__c
,SWT_Address_Validation_Fail_Reason__c
,SWT_Primary_Bill_To__c
,SWT_Primary_Ship_To__c
,SWT_Account_Address_Indicator__c
,Address_Verified__c
,SWT_Process_Status_Value__c
,SWT_Address_Validation_Status__c
,SWT_Account_Update__c
,SWT_City_Area__c
,SWT_Legacy_Address_Name__c
,SWT_Inactive__c
,SWT_Last_Used__c
,SWT_Address_Name__c
,SWT_Country_Group__c
,SWT_Country_ISO_Code__c
,SWT_for_Address_Name__c
,SWT_City_Area_Non_Latin__c
,SWT_Address_Country_Non_Latin__c
,SWT_Address_Zip_Postal_Code_Non_Latin__c
,SWT_Address_State_Province_Non_Latin__c
,SWT_Address_City_Non_Latin__c
,SWT_Address_Street_Non_Latin__c
,SWT_External_ID__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".SF_SWT_Addresses__c WHERE id in
(SELECT STG.id FROM SF_SWT_Addresses__c_stg_Tmp_Key STG JOIN SF_SWT_Addresses__c_base_Tmp
ON STG.id = SF_SWT_Addresses__c_base_Tmp.id AND STG.LastModifiedDate >= SF_SWT_Addresses__c_base_Tmp.LastModifiedDate);


 /* Deleting before seven days data from current date in the Historical Table */  

delete /*+DIRECT*/ from "swt_rpt_stg"."SF_SWT_Addresses__c_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

 
 /* Incremental VSQL script for loading data from Stage to Base */  

DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_SWT_Addresses__c WHERE id in
(SELECT STG.id FROM SF_SWT_Addresses__c_stg_Tmp_Key STG JOIN SF_SWT_Addresses__c_base_Tmp
ON STG.id = SF_SWT_Addresses__c_base_Tmp.id AND STG.LastModifiedDate >= SF_SWT_Addresses__c_base_Tmp.LastModifiedDate);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_SWT_Addresses__c
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
,LastViewedDate
,LastReferencedDate
,SWT_AccountID__c
,SWT_Street__c
,SWT_City__c
,SWT_State__c
,SWT_Postal_Code__c
,SWT_Country__c
,SWT_Ship_to_Indicator__c
,SWT_Bill_to_Indicator__c
,SWT_Sold_to_Indicator__c
,SWT_Address_Validation_Fail_Reason__c
,SWT_Primary_Bill_To__c
,SWT_Primary_Ship_To__c
,SWT_Account_Address_Indicator__c
,Address_Verified__c
,SWT_Process_Status_Value__c
,SWT_Address_Validation_Status__c
,SWT_Account_Update__c
,SWT_City_Area__c
,SWT_Legacy_Address_Name__c
,SWT_Inactive__c
,SWT_Last_Used__c
,SWT_Address_Name__c
,SWT_Country_Group__c
,SWT_Country_ISO_Code__c
,SWT_for_Address_Name__c
,SWT_City_Area_Non_Latin__c
,SWT_Address_Country_Non_Latin__c
,SWT_Address_Zip_Postal_Code_Non_Latin__c
,SWT_Address_State_Province_Non_Latin__c
,SWT_Address_City_Non_Latin__c
,SWT_Address_Street_Non_Latin__c
,SWT_External_ID__c
,SWT_INS_DT

)
SELECT DISTINCT 
SF_SWT_Addresses__c_stg_Tmp.Id
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,SF_SWT_Addresses__c_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,LastViewedDate
,LastReferencedDate
,SWT_AccountID__c
,SWT_Street__c
,SWT_City__c
,SWT_State__c
,SWT_Postal_Code__c
,SWT_Country__c
,SWT_Ship_to_Indicator__c
,SWT_Bill_to_Indicator__c
,SWT_Sold_to_Indicator__c
,SWT_Address_Validation_Fail_Reason__c
,SWT_Primary_Bill_To__c
,SWT_Primary_Ship_To__c
,SWT_Account_Address_Indicator__c
,Address_Verified__c
,SWT_Process_Status_Value__c
,SWT_Address_Validation_Status__c
,SWT_Account_Update__c
,SWT_City_Area__c
,SWT_Legacy_Address_Name__c
,SWT_Inactive__c
,SWT_Last_Used__c
,SWT_Address_Name__c
,SWT_Country_Group__c
,SWT_Country_ISO_Code__c
,SWT_for_Address_Name__c
,SWT_City_Area_Non_Latin__c
,SWT_Address_Country_Non_Latin__c
,SWT_Address_Zip_Postal_Code_Non_Latin__c
,SWT_Address_State_Province_Non_Latin__c
,SWT_Address_City_Non_Latin__c
,SWT_Address_Street_Non_Latin__c
,SWT_External_ID__c
,SYSDATE AS SWT_INS_DT
FROM SF_SWT_Addresses__c_stg_Tmp JOIN SF_SWT_Addresses__c_stg_Tmp_Key ON SF_SWT_Addresses__c_stg_Tmp.id= SF_SWT_Addresses__c_stg_Tmp_Key.id AND SF_SWT_Addresses__c_stg_Tmp.LastModifiedDate=SF_SWT_Addresses__c_stg_Tmp_Key.LastModifiedDate
	WHERE NOT EXISTS
	(SELECT 1 from "swt_rpt_base".SF_SWT_Addresses__c BASE
		WHERE SF_SWT_Addresses__c_stg_Tmp.id = BASE.id);

		
/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_SWT_Addresses__c' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_SWT_Addresses__c' and  COMPLTN_STAT = 'N');


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
select 'SFDC','SF_SWT_Addresses__c',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.SF_SWT_Addresses__c where SWT_INS_DT::date = sysdate::date),'Y';

   Commit;
    
select do_tm_task('mergeout','swt_rpt_stg.SF_SWT_Addresses__c_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_SWT_Addresses__c');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_SWT_Addresses__c');


