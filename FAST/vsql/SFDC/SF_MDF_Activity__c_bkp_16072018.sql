/****
****Script Name   : SF_MDF_Activity__c.sql
****Description   : Incremental data load for SF_MDF_Activity__c
****/

/*Setting timing on */
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

--SET SESSION AUTOCOMMIT TO OFF;

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."SF_MDF_Activity__c";

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
select 'SFDC','SF_MDF_Activity__c',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+Direct*/ INTO swt_rpt_stg.SF_MDF_Activity__c_Hist SELECT * from swt_rpt_stg.SF_MDF_Activity__c;
COMMIT;


CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_MDF_Activity__c where id in (
select id from swt_rpt_stg.SF_MDF_Activity__c group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);


delete from swt_rpt_stg.SF_MDF_Activity__c where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_MDF_Activity__c.id=t2.id and swt_rpt_stg.SF_MDF_Activity__c.auto_id<t2.auto_id);

commit;

CREATE LOCAL TEMP TABLE SF_MDF_Activity__c_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.SF_MDF_Activity__c)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.SF_MDF_Activity__c;

CREATE LOCAL TEMP TABLE SF_MDF_Activity__c_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,LastModifiedDate FROM swt_rpt_base.SF_MDF_Activity__c)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_MDF_Activity__c_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(LastModifiedDate) as LastModifiedDate FROM SF_MDF_Activity__c_stg_Tmp group by id)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.SF_MDF_Activity__c_Hist
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
,LastViewedDate
,LastReferencedDate
,SWT_joint_business_plan_mdf__c
,SWT_Activity_Type__c
,SWT_Account_mdf__c
,SWT_Activity_mdf__c
,SWT_Description_mdf__c
,SWT_Status__c
,SWT_HPE_mdf_Funds_Requested__c
,SWT_Partner_Investment_mdf__c
,SWT_Business_Unit_mdf__c
,SWT_Industry_Audience_mdf__c
,SWT_Strategic_Initiative__c
,SWT_Activity_Start_Date_mdf__c
,SWT_Activity_End_Date_mdf__c
,SWT_MDF_Fund__c
,SWT_Target_Customers_Touched_mdf__c
,SWT_Target_Incremental_Pipeline_mdf__c
,SWT_Target_New_Opportunities_mdf__c
,SWT_Target_Partners_Trained_mdf__c
,SWT_Quota_Assigned_to_Champion_mdf__c
,SWT_Actual_Customers_Touched__c
,SWT_Actual_Incremental_Pipeline_mdf__c
,SWT_Actual_New_Opportunities__c
,SWT_Actual_Partners_Trained__c
,SWT_Actual_Achieved_by_Champion_mdf__c
,SWT_Activity_Quarter_mdf__c
,SWT_HPE_MDF_Funds_Granted__c
,SWT_Partner_Account_Number__c
,SWT_My_Owned_Approvals_checkbox__c
,SWT_Approver_1__c
,SWT_Approver_2__c
,SWT_Approver_3__c
,SWT_Approver_4__c
,SWT_Approver_5__c
,SWT_Approver_6__c
,SWT_Country__c
,SWT_Address_ID__c
,SWT_Active__c
,SWT_Activity_Name__c
,SWT_Notified_L3__c
,SWT_Partner_Role__c
,SWT_ITOM_Fund__c
,SWT_ITOM_Fund_Granted__c
,SWT_MSA_MDF_activity__c
,SWT_MSA_Account__c
,SWT_Account_Name__c
,SWT_ADM_Fund__c
,SWT_ADM_Fund_Granted__c
,SWT_BDP_Fund__c
,SWT_BDP_Fund_Granted__c
,SWT_Claim_Expiration_Date__c
,SWT_ESP_Fund__c
,SWT_ESP_Fund_Granted__c
,SWT_IMG_Fund__c
,SWT_IMG_Fund_Granted__c
,SWT_IsApproved__c
,SWT_Owner_Name__c
,SWT_Region__c
,SWT_Rejected_Comment__c
,SWT_HPE_MDF_Funds_Granted_Obsolete__c
,SWT_HPE_mdf_Funds_Requested_Obsolete__c
,RecordTypeId
,Strategic_Initiative__c
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
,LastViewedDate
,LastReferencedDate
,SWT_joint_business_plan_mdf__c
,SWT_Activity_Type__c
,SWT_Account_mdf__c
,SWT_Activity_mdf__c
,SWT_Description_mdf__c
,SWT_Status__c
,SWT_HPE_mdf_Funds_Requested__c
,SWT_Partner_Investment_mdf__c
,SWT_Business_Unit_mdf__c
,SWT_Industry_Audience_mdf__c
,SWT_Strategic_Initiative__c
,SWT_Activity_Start_Date_mdf__c
,SWT_Activity_End_Date_mdf__c
,SWT_MDF_Fund__c
,SWT_Target_Customers_Touched_mdf__c
,SWT_Target_Incremental_Pipeline_mdf__c
,SWT_Target_New_Opportunities_mdf__c
,SWT_Target_Partners_Trained_mdf__c
,SWT_Quota_Assigned_to_Champion_mdf__c
,SWT_Actual_Customers_Touched__c
,SWT_Actual_Incremental_Pipeline_mdf__c
,SWT_Actual_New_Opportunities__c
,SWT_Actual_Partners_Trained__c
,SWT_Actual_Achieved_by_Champion_mdf__c
,SWT_Activity_Quarter_mdf__c
,SWT_HPE_MDF_Funds_Granted__c
,SWT_Partner_Account_Number__c
,SWT_My_Owned_Approvals_checkbox__c
,SWT_Approver_1__c
,SWT_Approver_2__c
,SWT_Approver_3__c
,SWT_Approver_4__c
,SWT_Approver_5__c
,SWT_Approver_6__c
,SWT_Country__c
,SWT_Address_ID__c
,SWT_Active__c
,SWT_Activity_Name__c
,SWT_Notified_L3__c
,SWT_Partner_Role__c
,SWT_ITOM_Fund__c
,SWT_ITOM_Fund_Granted__c
,SWT_MSA_MDF_activity__c
,SWT_MSA_Account__c
,SWT_Account_Name__c
,SWT_ADM_Fund__c
,SWT_ADM_Fund_Granted__c
,SWT_BDP_Fund__c
,SWT_BDP_Fund_Granted__c
,SWT_Claim_Expiration_Date__c
,SWT_ESP_Fund__c
,SWT_ESP_Fund_Granted__c
,SWT_IMG_Fund__c
,SWT_IMG_Fund_Granted__c
,SWT_IsApproved__c
,SWT_Owner_Name__c
,SWT_Region__c
,SWT_Rejected_Comment__c
,SWT_HPE_MDF_Funds_Granted_Obsolete__c
,SWT_HPE_mdf_Funds_Requested_Obsolete__c
,RecordTypeId
,Strategic_Initiative__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".SF_MDF_Activity__c WHERE id in
(SELECT STG.id FROM SF_MDF_Activity__c_stg_Tmp_Key STG JOIN SF_MDF_Activity__c_base_Tmp
ON STG.id = SF_MDF_Activity__c_base_Tmp.id AND STG.LastModifiedDate >= SF_MDF_Activity__c_base_Tmp.LastModifiedDate);


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."SF_MDF_Activity__c_HIST"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_MDF_Activity__c WHERE id in
(SELECT STG.id FROM SF_MDF_Activity__c_stg_Tmp_Key STG JOIN SF_MDF_Activity__c_base_Tmp
ON STG.id = SF_MDF_Activity__c_base_Tmp.id AND STG.LastModifiedDate >= SF_MDF_Activity__c_base_Tmp.LastModifiedDate);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_MDF_Activity__c
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
,LastViewedDate
,LastReferencedDate
,SWT_joint_business_plan_mdf__c
,SWT_Activity_Type__c
,SWT_Account_mdf__c
,SWT_Activity_mdf__c
,SWT_Description_mdf__c
,SWT_Status__c
,SWT_HPE_mdf_Funds_Requested__c
,SWT_Partner_Investment_mdf__c
,SWT_Business_Unit_mdf__c
,SWT_Industry_Audience_mdf__c
,SWT_Strategic_Initiative__c
,SWT_Activity_Start_Date_mdf__c
,SWT_Activity_End_Date_mdf__c
,SWT_MDF_Fund__c
,SWT_Target_Customers_Touched_mdf__c
,SWT_Target_Incremental_Pipeline_mdf__c
,SWT_Target_New_Opportunities_mdf__c
,SWT_Target_Partners_Trained_mdf__c
,SWT_Quota_Assigned_to_Champion_mdf__c
,SWT_Actual_Customers_Touched__c
,SWT_Actual_Incremental_Pipeline_mdf__c
,SWT_Actual_New_Opportunities__c
,SWT_Actual_Partners_Trained__c
,SWT_Actual_Achieved_by_Champion_mdf__c
,SWT_Activity_Quarter_mdf__c
,SWT_HPE_MDF_Funds_Granted__c
,SWT_Partner_Account_Number__c
,SWT_My_Owned_Approvals_checkbox__c
,SWT_Approver_1__c
,SWT_Approver_2__c
,SWT_Approver_3__c
,SWT_Approver_4__c
,SWT_Approver_5__c
,SWT_Approver_6__c
,SWT_Country__c
,SWT_Address_ID__c
,SWT_Active__c
,SWT_Activity_Name__c
,SWT_Notified_L3__c
,SWT_Partner_Role__c
,SWT_ITOM_Fund__c
,SWT_ITOM_Fund_Granted__c
,SWT_MSA_MDF_activity__c
,SWT_MSA_Account__c
,SWT_Account_Name__c
,SWT_ADM_Fund__c
,SWT_ADM_Fund_Granted__c
,SWT_BDP_Fund__c
,SWT_BDP_Fund_Granted__c
,SWT_Claim_Expiration_Date__c
,SWT_ESP_Fund__c
,SWT_ESP_Fund_Granted__c
,SWT_IMG_Fund__c
,SWT_IMG_Fund_Granted__c
,SWT_IsApproved__c
,SWT_Owner_Name__c
,SWT_Region__c
,SWT_Rejected_Comment__c
,SWT_HPE_MDF_Funds_Granted_Obsolete__c
,SWT_HPE_mdf_Funds_Requested_Obsolete__c
,RecordTypeId
,Strategic_Initiative__c
,SWT_INS_DT
)
SELECT DISTINCT
SF_MDF_Activity__c_stg_Tmp.Id
,OwnerId
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,SF_MDF_Activity__c_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,LastViewedDate
,LastReferencedDate
,SWT_joint_business_plan_mdf__c
,SWT_Activity_Type__c
,SWT_Account_mdf__c
,SWT_Activity_mdf__c
,SWT_Description_mdf__c
,SWT_Status__c
,SWT_HPE_mdf_Funds_Requested__c
,SWT_Partner_Investment_mdf__c
,SWT_Business_Unit_mdf__c
,SWT_Industry_Audience_mdf__c
,SWT_Strategic_Initiative__c
,SWT_Activity_Start_Date_mdf__c
,SWT_Activity_End_Date_mdf__c
,SWT_MDF_Fund__c
,SWT_Target_Customers_Touched_mdf__c
,SWT_Target_Incremental_Pipeline_mdf__c
,SWT_Target_New_Opportunities_mdf__c
,SWT_Target_Partners_Trained_mdf__c
,SWT_Quota_Assigned_to_Champion_mdf__c
,SWT_Actual_Customers_Touched__c
,SWT_Actual_Incremental_Pipeline_mdf__c
,SWT_Actual_New_Opportunities__c
,SWT_Actual_Partners_Trained__c
,SWT_Actual_Achieved_by_Champion_mdf__c
,SWT_Activity_Quarter_mdf__c
,SWT_HPE_MDF_Funds_Granted__c
,SWT_Partner_Account_Number__c
,SWT_My_Owned_Approvals_checkbox__c
,SWT_Approver_1__c
,SWT_Approver_2__c
,SWT_Approver_3__c
,SWT_Approver_4__c
,SWT_Approver_5__c
,SWT_Approver_6__c
,SWT_Country__c
,SWT_Address_ID__c
,SWT_Active__c
,SWT_Activity_Name__c
,SWT_Notified_L3__c
,SWT_Partner_Role__c
,SWT_ITOM_Fund__c
,SWT_ITOM_Fund_Granted__c
,SWT_MSA_MDF_activity__c
,SWT_MSA_Account__c
,SWT_Account_Name__c
,SWT_ADM_Fund__c
,SWT_ADM_Fund_Granted__c
,SWT_BDP_Fund__c
,SWT_BDP_Fund_Granted__c
,SWT_Claim_Expiration_Date__c
,SWT_ESP_Fund__c
,SWT_ESP_Fund_Granted__c
,SWT_IMG_Fund__c
,SWT_IMG_Fund_Granted__c
,SWT_IsApproved__c
,SWT_Owner_Name__c
,SWT_Region__c
,SWT_Rejected_Comment__c
,SWT_HPE_MDF_Funds_Granted_Obsolete__c
,SWT_HPE_mdf_Funds_Requested_Obsolete__c
,RecordTypeId
,Strategic_Initiative__c
,SYSDATE AS SWT_INS_DT
FROM SF_MDF_Activity__c_stg_Tmp JOIN SF_MDF_Activity__c_stg_Tmp_Key ON SF_MDF_Activity__c_stg_Tmp.id= SF_MDF_Activity__c_stg_Tmp_Key.id AND SF_MDF_Activity__c_stg_Tmp.LastModifiedDate=SF_MDF_Activity__c_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 from "swt_rpt_base".SF_MDF_Activity__c BASE
WHERE SF_MDF_Activity__c_stg_Tmp.id = BASE.id);



/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_MDF_Activity__c' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_MDF_Activity__c' and  COMPLTN_STAT = 'N');


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
select 'SFDC','SF_MDF_Activity__c',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.SF_MDF_Activity__c where SWT_INS_DT::date = sysdate::date),'Y';

commit;

select do_tm_task('mergeout','swt_rpt_stg.SF_MDF_Activity__c_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_MDF_Activity__c');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_MDF_Activity__c');

