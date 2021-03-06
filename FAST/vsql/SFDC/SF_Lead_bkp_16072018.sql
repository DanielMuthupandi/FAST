
--Script Name   : SF_Lead.sql
--Description   : Incremental data load for SF_Lead


/*Setting timing on */
\timing

--SET SESSION AUTOCOMMIT TO OFF;

--SET SESSION AUTOCOMMIT TO OFF;

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."SF_Lead";

--Inserting values into Audit table 

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
select 'SFDC','SF_Lead',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;  

INSERT /*+Direct*/ INTO swt_rpt_stg.SF_Lead_Hist SELECT * from swt_rpt_stg.SF_Lead;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_Lead where id in (
select id from swt_rpt_stg.SF_Lead group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);


delete from swt_rpt_stg.SF_Lead where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_Lead.id=t2.id and swt_rpt_stg.SF_Lead.auto_id<t2.auto_id);

commit; 

CREATE LOCAL TEMP TABLE SF_Lead_stg_Temp ON COMMIT PRESERVE ROWS AS
( 
SELECT DISTINCT * FROM swt_rpt_stg.SF_Lead)
SEGMENTED BY HASH(id,lastmodifieddate) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.SF_Lead;

CREATE LOCAL TEMP TABLE SF_Lead_base_Temp ON COMMIT PRESERVE ROWS AS
( 
SELECT DISTINCT ID,LASTMODIFIEDDATE FROM swt_rpt_base.SF_Lead)
SEGMENTED BY HASH(ID,LASTMODIFIEDDATE) ALL NODES;

CREATE LOCAL TEMP TABLE SF_Lead_stg_Temp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(lastmodifieddate) as lastmodifieddate FROM SF_Lead_stg_Temp group by id) 
SEGMENTED BY HASH(ID,LASTMODIFIEDDATE) ALL NODES;




insert /*+DIRECT*/ into swt_rpt_stg.SF_Lead_Hist
(
Id
,IsDeleted
,MasterRecordId
,LastName
,FirstName
,Salutation
,MiddleName
,Suffix
,Name
,RecordTypeId
,Title
,Company
,Street
,City
,State
,PostalCode
,Country
,Latitude
,Longitude
,GeocodeAccuracy
,Phone
,MobilePhone
,Email
,Website
,PhotoUrl
,LeadSource
,Status
,Industry
,Rating
,CurrencyIsoCode
,AnnualRevenue
,NumberOfEmployees
,OwnerId
,HasOptedOutOfEmail
,IsConverted
,ConvertedDate
,ConvertedAccountId
,ConvertedContactId
,ConvertedOpportunityId
,IsUnreadByOwner
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,DoNotCall
,LastViewedDate
,LastReferencedDate
,Jigsaw
,JigsawContactId
,CleanStatus
,CompanyDunsNumber
,DandbCompanyId
,EmailBouncedReason
,EmailBouncedDate
,SWT_Projected_Budget__c
,SWT_Business_Unit__c
,SWT_Projected_Budget_Amount__c
,SWT_Lead_Address_Checkbox__c
,SWT_Purchaser_Role__c
,SWT_Timeframe_to_Buy__c
,SWT_Lead_Currency_Formula__c
,SWT_Last_Contacted_Date__c
,SWT_Business_Phone__c
,SWT_Number_of_Employees__c
,SWT_Mobile_Phone__c
,SWT_Extension_Number__c
,SWT_Region__c
,SWT_Preferred_Method_of_Contact__c
,SWT_Lead_Qualifier__c
,ringdna100__Call_Attempts__c
,SWT_Number_of_Locations__c
,SWT_Reason_for_Close__c
,SWT_Activity_Trial_Status__c
,SWT_Lead_Currency__c
,SWT_Externally_Qualified__c
,SWT_Lead_Source_Map__c
,SWT_DemoChimp_Demo__c
,SWT_Job_Level__c
,SWT_Partner_Type__c
,SWT_Sales_Qualified_Lead__c
,SWT_BANT_Qualified_Lead__c
,ringdna100__Days_Since_Last_Attempt__c
,SWT_Pillar__c
,ringdna100__Email_Attempts__c
,ringdna100__First_Inbound_Call__c
,ringdna100__First_Outbound_Call__c
,ringdna100__Last_Email_Attempt__c
,ringdna100__Last_Inbound_Call__c
,ringdna100__Last_Outbound_Call__c
,DSE__DS_Account__c
,DSE__DS_Contact__c
,DSE__DS_Country_ISO_Code__c
,DSE__DS_DataScout_Process__c
,DSE__DS_Legal_Form__c
,DSE__DS_Synchronize__c
,DSE__Demo_Classifications__c
,DSE__Demo_ID__c
,DSE__Domain__c
,DSE__VAT_ID__c
,SWT_Authorized_Buyer__c
,ringdna100__Response_Type__c
,ringdna100__Time_Since_Last_Call_Attempt_Days__c
,pi__Needs_Score_Synced__c
,pi__Pardot_Last_Scored_At__c
,pi__campaign__c
,pi__comments__c
,pi__conversion_date__c
,pi__conversion_object_name__c
,pi__conversion_object_type__c
,pi__created_date__c
,pi__first_activity__c
,pi__first_search_term__c
,pi__first_search_type__c
,pi__first_touch_url__c
,pi__grade__c
,pi__last_activity__c
,pi__notes__c
,pi__pardot_hard_bounced__c
,pi__score__c
,pi__url__c
,pi__utm_campaign__c
,pi__utm_content__c
,pi__utm_medium__c
,pi__utm_source__c
,pi__utm_term__c
,SWT_Lead_Source_Information__c
,ringdna100__Time_Since_Last_Call_Attempt_Minutes__c
,ringdna100__Time_Since_Last_Email_Attempt_Days__c
,ringdna100__Time_Since_Last_Email_Attempt_Minutes__c
,ringdna100__Time_to_First_Dial_Minutes__c
,ringdna100__Time_to_Respond__c
,SWT_Last_Update_on_Privacy_Information__c
,SWT_Also_exist_in_HP_Passport__c
,SWT_First_Sales_Touch_Date__c
,SWT_Previous_Lead_Owner_Role__c
,SWT_Days_Since_Assigned_w_out_Conversion__c
,SWT_Lead_Age__c
,SWT_Owner_role_formula__c
,SWT_CMT_1__c
,SWT_CMT_2__c
,SWT_Product_Interest__c
,SWT_Lead_owner_type_User__c
,SWT_Lead_Qualifier_Role_Type__c
,SWT_Primary_campaign__c
,SWT_Last_Assignment_Date__c
,SWT_Website__c
,SWT_Lead_Qualified_Date__c
,SWT_Lead_Qualifier_Role__c
,SWT_Primary_campaign_check__c
,SWT_TEM_Trial__c
,SWT_Account__c
,SWT_Customer_Comments__c
,SWT_Marketing_Comments__c
,Initial_Campaign__c
,SWT_Subscribed_TechBeacon__c
,SWT_Subscribed_All_Applications_Product__c
,SWT_Subscribed_Big_Data_Marketplace__c
,SWT_Subscribed_HPE_Software_Updates__c
,SWT_Parent_Contact__c
,SWT_Parent_Lead__c
,et4ae5__HasOptedOutOfMobile__c
,et4ae5__Mobile_Country_Code__c
,SWT_Business_Area__c
,SWT_DemoChimp_Comments__c
,SWT_External_ID__c
,SWT_ForecastCategory__c
,SWT_TouchGovernance_Marketing_Cloud__c
,SWT_TouchGovernance_Pardot__c
,Address
,fax
,SWT_Existing_Contact__c
,SWT_Lead_Score__c
,SWT_Case_Safe_ID__c
,SWT_Online_Purchase_Type_Term__c
,FCRM__FCR_Created_By_Lead_Conversion__c
,FCRM__FCR_Response_Score__c
,CampaignId
,CFCR_Account_ID__c
,CFCR_Admin_Score_Increment__c
,CFCR_Admin_Score_Increment_Audit__c
,CFCR_FCCRM_Threshold__c
,FCMM__LAM_AccountMatchAttempted__c
,FCMM__LAM_AccountMatchDate__c
,FCMM__LAM_AccountMatchRejected__c
,FCMM__LAM_AccountMatchRejectedDate__c
,FCMM__LAM_AssignDate__c
,FCMM__LAM_AutoConverted__c
,FCMM__LAM_MatchedAccount__c
,FCMM__LAM_MatchedContactID__c
,FCMM__LAM_PotentialAccountMatch__c
,FCMM__LAM_PotentialAccountMatchDate__c
,FCRM__FCR_Admin_Update_Counter__c
,FCRM__FCR_Defer_Assignment__c
,FCRM__FCR_Name_Created_Date__c
,FCRM__FCR_Nurture_Timeout__c
,FCRM__FCR_PostAssignNotificationPending__c
,FCRM__FCR_Prior_Lead_Score__c
,FCRM__FCR_Stage_Age__c
,FCRM__FCR_Status_Last_Set__c
,FCRM__FCR_Status_Synced_From_Response__c
,FCRM__FCR_Superpower_Field__c
,FCRM__FCR_Take_Scoring_Snapshot__c
,Influenced_Opportunity__c
,Merge_Lead__c
,Source_Campaign_ID__c
,SWT_CreatedByMule__c
,SWT_GOV_LLC__c
,SWT_Lead_converted_to_opporty__c
,SWT_Lead_Owner_Manager__c
,LD_DT
,SWT_INS_DT
,d_source
)
 select 
 Id
,IsDeleted
,MasterRecordId
,LastName
,FirstName
,Salutation
,MiddleName
,Suffix
,Name
,RecordTypeId
,Title
,Company
,Street
,City
,State
,PostalCode
,Country
,Latitude
,Longitude
,GeocodeAccuracy
,Phone
,MobilePhone
,Email
,Website
,PhotoUrl
,LeadSource
,Status
,Industry
,Rating
,CurrencyIsoCode
,AnnualRevenue
,NumberOfEmployees
,OwnerId
,HasOptedOutOfEmail
,IsConverted
,ConvertedDate
,ConvertedAccountId
,ConvertedContactId
,ConvertedOpportunityId
,IsUnreadByOwner
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,DoNotCall
,LastViewedDate
,LastReferencedDate
,Jigsaw
,JigsawContactId
,CleanStatus
,CompanyDunsNumber
,DandbCompanyId
,EmailBouncedReason
,EmailBouncedDate
,SWT_Projected_Budget__c
,SWT_Business_Unit__c
,SWT_Projected_Budget_Amount__c
,SWT_Lead_Address_Checkbox__c
,SWT_Purchaser_Role__c
,SWT_Timeframe_to_Buy__c
,SWT_Lead_Currency_Formula__c
,SWT_Last_Contacted_Date__c
,SWT_Business_Phone__c
,SWT_Number_of_Employees__c
,SWT_Mobile_Phone__c
,SWT_Extension_Number__c
,SWT_Region__c
,SWT_Preferred_Method_of_Contact__c
,SWT_Lead_Qualifier__c
,ringdna100__Call_Attempts__c
,SWT_Number_of_Locations__c
,SWT_Reason_for_Close__c
,SWT_Activity_Trial_Status__c
,SWT_Lead_Currency__c
,SWT_Externally_Qualified__c
,SWT_Lead_Source_Map__c
,SWT_DemoChimp_Demo__c
,SWT_Job_Level__c
,SWT_Partner_Type__c
,SWT_Sales_Qualified_Lead__c
,SWT_BANT_Qualified_Lead__c
,ringdna100__Days_Since_Last_Attempt__c
,SWT_Pillar__c
,ringdna100__Email_Attempts__c
,ringdna100__First_Inbound_Call__c
,ringdna100__First_Outbound_Call__c
,ringdna100__Last_Email_Attempt__c
,ringdna100__Last_Inbound_Call__c
,ringdna100__Last_Outbound_Call__c
,DSE__DS_Account__c
,DSE__DS_Contact__c
,DSE__DS_Country_ISO_Code__c
,DSE__DS_DataScout_Process__c
,DSE__DS_Legal_Form__c
,DSE__DS_Synchronize__c
,DSE__Demo_Classifications__c
,DSE__Demo_ID__c
,DSE__Domain__c
,DSE__VAT_ID__c
,SWT_Authorized_Buyer__c
,ringdna100__Response_Type__c
,ringdna100__Time_Since_Last_Call_Attempt_Days__c
,pi__Needs_Score_Synced__c
,pi__Pardot_Last_Scored_At__c
,pi__campaign__c
,pi__comments__c
,pi__conversion_date__c
,pi__conversion_object_name__c
,pi__conversion_object_type__c
,pi__created_date__c
,pi__first_activity__c
,pi__first_search_term__c
,pi__first_search_type__c
,pi__first_touch_url__c
,pi__grade__c
,pi__last_activity__c
,pi__notes__c
,pi__pardot_hard_bounced__c
,pi__score__c
,pi__url__c
,pi__utm_campaign__c
,pi__utm_content__c
,pi__utm_medium__c
,pi__utm_source__c
,pi__utm_term__c
,SWT_Lead_Source_Information__c
,ringdna100__Time_Since_Last_Call_Attempt_Minutes__c
,ringdna100__Time_Since_Last_Email_Attempt_Days__c
,ringdna100__Time_Since_Last_Email_Attempt_Minutes__c
,ringdna100__Time_to_First_Dial_Minutes__c
,ringdna100__Time_to_Respond__c
,SWT_Last_Update_on_Privacy_Information__c
,SWT_Also_exist_in_HP_Passport__c
,SWT_First_Sales_Touch_Date__c
,SWT_Previous_Lead_Owner_Role__c
,SWT_Days_Since_Assigned_w_out_Conversion__c
,SWT_Lead_Age__c
,SWT_Owner_role_formula__c
,SWT_CMT_1__c
,SWT_CMT_2__c
,SWT_Product_Interest__c
,SWT_Lead_owner_type_User__c
,SWT_Lead_Qualifier_Role_Type__c
,SWT_Primary_campaign__c
,SWT_Last_Assignment_Date__c
,SWT_Website__c
,SWT_Lead_Qualified_Date__c
,SWT_Lead_Qualifier_Role__c
,SWT_Primary_campaign_check__c
,SWT_TEM_Trial__c
,SWT_Account__c
,SWT_Customer_Comments__c
,SWT_Marketing_Comments__c
,Initial_Campaign__c
,SWT_Subscribed_TechBeacon__c
,SWT_Subscribed_All_Applications_Product__c
,SWT_Subscribed_Big_Data_Marketplace__c
,SWT_Subscribed_HPE_Software_Updates__c
,SWT_Parent_Contact__c
,SWT_Parent_Lead__c
,et4ae5__HasOptedOutOfMobile__c
,et4ae5__Mobile_Country_Code__c
,SWT_Business_Area__c
,SWT_DemoChimp_Comments__c
,SWT_External_ID__c
,SWT_ForecastCategory__c
,SWT_TouchGovernance_Marketing_Cloud__c
,SWT_TouchGovernance_Pardot__c
,Address
,fax
,SWT_Existing_Contact__c
,SWT_Lead_Score__c
,SWT_Case_Safe_ID__c
,SWT_Online_Purchase_Type_Term__c
,FCRM__FCR_Created_By_Lead_Conversion__c
,FCRM__FCR_Response_Score__c
,CampaignId
,CFCR_Account_ID__c
,CFCR_Admin_Score_Increment__c
,CFCR_Admin_Score_Increment_Audit__c
,CFCR_FCCRM_Threshold__c
,FCMM__LAM_AccountMatchAttempted__c
,FCMM__LAM_AccountMatchDate__c
,FCMM__LAM_AccountMatchRejected__c
,FCMM__LAM_AccountMatchRejectedDate__c
,FCMM__LAM_AssignDate__c
,FCMM__LAM_AutoConverted__c
,FCMM__LAM_MatchedAccount__c
,FCMM__LAM_MatchedContactID__c
,FCMM__LAM_PotentialAccountMatch__c
,FCMM__LAM_PotentialAccountMatchDate__c
,FCRM__FCR_Admin_Update_Counter__c
,FCRM__FCR_Defer_Assignment__c
,FCRM__FCR_Name_Created_Date__c
,FCRM__FCR_Nurture_Timeout__c
,FCRM__FCR_PostAssignNotificationPending__c
,FCRM__FCR_Prior_Lead_Score__c
,FCRM__FCR_Stage_Age__c
,FCRM__FCR_Status_Last_Set__c
,FCRM__FCR_Status_Synced_From_Response__c
,FCRM__FCR_Superpower_Field__c
,FCRM__FCR_Take_Scoring_Snapshot__c
,Influenced_Opportunity__c
,Merge_Lead__c
,Source_Campaign_ID__c
,SWT_CreatedByMule__c
,SWT_GOV_LLC__c
,SWT_Lead_converted_to_opporty__c
,SWT_Lead_Owner_Manager__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".SF_Lead WHERE id in
(SELECT STG.id FROM SF_Lead_stg_Temp_Key STG JOIN SF_Lead_base_Temp
ON STG.id = SF_Lead_base_Temp.id AND STG.LastModifiedDate >= SF_Lead_base_Temp.LastModifiedDate);


/*Deleting before seven days data from current date in the Historical Table */  

delete /*+DIRECT*/ from "swt_rpt_stg"."SF_Lead_HIST"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

/*Incremental VSQL script for loading data from Stage to Base */  

DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_Lead WHERE id in
(SELECT STG.id FROM SF_Lead_stg_Temp_Key STG JOIN SF_Lead_base_Temp
ON STG.id = SF_Lead_base_Temp.id AND STG.LastModifiedDate >= SF_Lead_base_Temp.LastModifiedDate);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_Lead
(
Id
,IsDeleted
,MasterRecordId
,LastName
,FirstName
,Salutation
,MiddleName
,Suffix
,Name
,RecordTypeId
,Title
,Company
,Street
,City
,State
,PostalCode
,Country
,Latitude
,Longitude
,GeocodeAccuracy
,Phone
,MobilePhone
,Email
,Website
,PhotoUrl
,LeadSource
,Status
,Industry
,Rating
,CurrencyIsoCode
,AnnualRevenue
,NumberOfEmployees
,OwnerId
,HasOptedOutOfEmail
,IsConverted
,ConvertedDate
,ConvertedAccountId
,ConvertedContactId
,ConvertedOpportunityId
,IsUnreadByOwner
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,DoNotCall
,LastViewedDate
,LastReferencedDate
,Jigsaw
,JigsawContactId
,CleanStatus
,CompanyDunsNumber
,DandbCompanyId
,EmailBouncedReason
,EmailBouncedDate
,SWT_Projected_Budget__c
,SWT_Business_Unit__c
,SWT_Projected_Budget_Amount__c
,SWT_Lead_Address_Checkbox__c
,SWT_Purchaser_Role__c
,SWT_Timeframe_to_Buy__c
,SWT_Lead_Currency_Formula__c
,SWT_Last_Contacted_Date__c
,SWT_Business_Phone__c
,SWT_Number_of_Employees__c
,SWT_Mobile_Phone__c
,SWT_Extension_Number__c
,SWT_Region__c
,SWT_Preferred_Method_of_Contact__c
,SWT_Lead_Qualifier__c
,ringdna100__Call_Attempts__c
,SWT_Number_of_Locations__c
,SWT_Reason_for_Close__c
,SWT_Activity_Trial_Status__c
,SWT_Lead_Currency__c
,SWT_Externally_Qualified__c
,SWT_Lead_Source_Map__c
,SWT_DemoChimp_Demo__c
,SWT_Job_Level__c
,SWT_Partner_Type__c
,SWT_Sales_Qualified_Lead__c
,SWT_BANT_Qualified_Lead__c
,ringdna100__Days_Since_Last_Attempt__c
,SWT_Pillar__c
,ringdna100__Email_Attempts__c
,ringdna100__First_Inbound_Call__c
,ringdna100__First_Outbound_Call__c
,ringdna100__Last_Email_Attempt__c
,ringdna100__Last_Inbound_Call__c
,ringdna100__Last_Outbound_Call__c
,DSE__DS_Account__c
,DSE__DS_Contact__c
,DSE__DS_Country_ISO_Code__c
,DSE__DS_DataScout_Process__c
,DSE__DS_Legal_Form__c
,DSE__DS_Synchronize__c
,DSE__Demo_Classifications__c
,DSE__Demo_ID__c
,DSE__Domain__c
,DSE__VAT_ID__c
,SWT_Authorized_Buyer__c
,ringdna100__Response_Type__c
,ringdna100__Time_Since_Last_Call_Attempt_Days__c
,pi__Needs_Score_Synced__c
,pi__Pardot_Last_Scored_At__c
,pi__campaign__c
,pi__comments__c
,pi__conversion_date__c
,pi__conversion_object_name__c
,pi__conversion_object_type__c
,pi__created_date__c
,pi__first_activity__c
,pi__first_search_term__c
,pi__first_search_type__c
,pi__first_touch_url__c
,pi__grade__c
,pi__last_activity__c
,pi__notes__c
,pi__pardot_hard_bounced__c
,pi__score__c
,pi__url__c
,pi__utm_campaign__c
,pi__utm_content__c
,pi__utm_medium__c
,pi__utm_source__c
,pi__utm_term__c
,SWT_Lead_Source_Information__c
,ringdna100__Time_Since_Last_Call_Attempt_Minutes__c
,ringdna100__Time_Since_Last_Email_Attempt_Days__c
,ringdna100__Time_Since_Last_Email_Attempt_Minutes__c
,ringdna100__Time_to_First_Dial_Minutes__c
,ringdna100__Time_to_Respond__c
,SWT_Last_Update_on_Privacy_Information__c
,SWT_Also_exist_in_HP_Passport__c
,SWT_First_Sales_Touch_Date__c
,SWT_Previous_Lead_Owner_Role__c
,SWT_Days_Since_Assigned_w_out_Conversion__c
,SWT_Lead_Age__c
,SWT_Owner_role_formula__c
,SWT_CMT_1__c
,SWT_CMT_2__c
,SWT_Product_Interest__c
,SWT_Lead_owner_type_User__c
,SWT_Lead_Qualifier_Role_Type__c
,SWT_Primary_campaign__c
,SWT_Last_Assignment_Date__c
,SWT_Website__c
,SWT_Lead_Qualified_Date__c
,SWT_Lead_Qualifier_Role__c
,SWT_Primary_campaign_check__c
,SWT_TEM_Trial__c
,SWT_Account__c
,SWT_Customer_Comments__c
,SWT_Marketing_Comments__c
,Initial_Campaign__c
,SWT_Subscribed_TechBeacon__c
,SWT_Subscribed_All_Applications_Product__c
,SWT_Subscribed_Big_Data_Marketplace__c
,SWT_Subscribed_HPE_Software_Updates__c
,SWT_Parent_Contact__c
,SWT_Parent_Lead__c
,et4ae5__HasOptedOutOfMobile__c
,et4ae5__Mobile_Country_Code__c
,SWT_Business_Area__c
,SWT_DemoChimp_Comments__c
,SWT_External_ID__c
,SWT_ForecastCategory__c
,SWT_TouchGovernance_Marketing_Cloud__c
,SWT_TouchGovernance_Pardot__c
,Address
,fax
,SWT_Existing_Contact__c
,SWT_Lead_Score__c
,SWT_Case_Safe_ID__c
,SWT_Online_Purchase_Type_Term__c
,FCRM__FCR_Created_By_Lead_Conversion__c
,FCRM__FCR_Response_Score__c
,CampaignId
,CFCR_Account_ID__c
,CFCR_Admin_Score_Increment__c
,CFCR_Admin_Score_Increment_Audit__c
,CFCR_FCCRM_Threshold__c
,FCMM__LAM_AccountMatchAttempted__c
,FCMM__LAM_AccountMatchDate__c
,FCMM__LAM_AccountMatchRejected__c
,FCMM__LAM_AccountMatchRejectedDate__c
,FCMM__LAM_AssignDate__c
,FCMM__LAM_AutoConverted__c
,FCMM__LAM_MatchedAccount__c
,FCMM__LAM_MatchedContactID__c
,FCMM__LAM_PotentialAccountMatch__c
,FCMM__LAM_PotentialAccountMatchDate__c
,FCRM__FCR_Admin_Update_Counter__c
,FCRM__FCR_Defer_Assignment__c
,FCRM__FCR_Name_Created_Date__c
,FCRM__FCR_Nurture_Timeout__c
,FCRM__FCR_PostAssignNotificationPending__c
,FCRM__FCR_Prior_Lead_Score__c
,FCRM__FCR_Stage_Age__c
,FCRM__FCR_Status_Last_Set__c
,FCRM__FCR_Status_Synced_From_Response__c
,FCRM__FCR_Superpower_Field__c
,FCRM__FCR_Take_Scoring_Snapshot__c
,Influenced_Opportunity__c
,Merge_Lead__c
,Source_Campaign_ID__c
,SWT_CreatedByMule__c
,SWT_GOV_LLC__c
,SWT_Lead_converted_to_opporty__c
,SWT_Lead_Owner_Manager__c
,SWT_INS_DT
)

SELECT DISTINCT  
 SF_Lead_stg_Temp.Id
,IsDeleted
,MasterRecordId
,LastName
,FirstName
,Salutation
,MiddleName
,Suffix
,Name
,RecordTypeId
,Title
,Company
,Street
,City
,State
,PostalCode
,Country
,Latitude
,Longitude
,GeocodeAccuracy
,Phone
,MobilePhone
,Email
,Website
,PhotoUrl
,LeadSource
,Status
,Industry
,Rating
,CurrencyIsoCode
,AnnualRevenue
,NumberOfEmployees
,OwnerId
,HasOptedOutOfEmail
,IsConverted
,ConvertedDate
,ConvertedAccountId
,ConvertedContactId
,ConvertedOpportunityId
,IsUnreadByOwner
,CreatedDate
,CreatedById
,SF_Lead_stg_Temp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,DoNotCall
,LastViewedDate
,LastReferencedDate
,Jigsaw
,JigsawContactId
,CleanStatus
,CompanyDunsNumber
,DandbCompanyId
,EmailBouncedReason
,EmailBouncedDate
,SWT_Projected_Budget__c
,SWT_Business_Unit__c
,SWT_Projected_Budget_Amount__c
,SWT_Lead_Address_Checkbox__c
,SWT_Purchaser_Role__c
,SWT_Timeframe_to_Buy__c
,SWT_Lead_Currency_Formula__c
,SWT_Last_Contacted_Date__c
,SWT_Business_Phone__c
,SWT_Number_of_Employees__c
,SWT_Mobile_Phone__c
,SWT_Extension_Number__c
,SWT_Region__c
,SWT_Preferred_Method_of_Contact__c
,SWT_Lead_Qualifier__c
,ringdna100__Call_Attempts__c
,SWT_Number_of_Locations__c
,SWT_Reason_for_Close__c
,SWT_Activity_Trial_Status__c
,SWT_Lead_Currency__c
,SWT_Externally_Qualified__c
,SWT_Lead_Source_Map__c
,SWT_DemoChimp_Demo__c
,SWT_Job_Level__c
,SWT_Partner_Type__c
,SWT_Sales_Qualified_Lead__c
,SWT_BANT_Qualified_Lead__c
,ringdna100__Days_Since_Last_Attempt__c
,SWT_Pillar__c
,ringdna100__Email_Attempts__c
,ringdna100__First_Inbound_Call__c
,ringdna100__First_Outbound_Call__c
,ringdna100__Last_Email_Attempt__c
,ringdna100__Last_Inbound_Call__c
,ringdna100__Last_Outbound_Call__c
,DSE__DS_Account__c
,DSE__DS_Contact__c
,DSE__DS_Country_ISO_Code__c
,DSE__DS_DataScout_Process__c
,DSE__DS_Legal_Form__c
,DSE__DS_Synchronize__c
,DSE__Demo_Classifications__c
,DSE__Demo_ID__c
,DSE__Domain__c
,DSE__VAT_ID__c
,SWT_Authorized_Buyer__c
,ringdna100__Response_Type__c
,ringdna100__Time_Since_Last_Call_Attempt_Days__c
,pi__Needs_Score_Synced__c
,pi__Pardot_Last_Scored_At__c
,pi__campaign__c
,pi__comments__c
,pi__conversion_date__c
,pi__conversion_object_name__c
,pi__conversion_object_type__c
,pi__created_date__c
,pi__first_activity__c
,pi__first_search_term__c
,pi__first_search_type__c
,pi__first_touch_url__c
,pi__grade__c
,pi__last_activity__c
,pi__notes__c
,pi__pardot_hard_bounced__c
,pi__score__c
,pi__url__c
,pi__utm_campaign__c
,pi__utm_content__c
,pi__utm_medium__c
,pi__utm_source__c
,pi__utm_term__c
,SWT_Lead_Source_Information__c
,ringdna100__Time_Since_Last_Call_Attempt_Minutes__c
,ringdna100__Time_Since_Last_Email_Attempt_Days__c
,ringdna100__Time_Since_Last_Email_Attempt_Minutes__c
,ringdna100__Time_to_First_Dial_Minutes__c
,ringdna100__Time_to_Respond__c
,SWT_Last_Update_on_Privacy_Information__c
,SWT_Also_exist_in_HP_Passport__c
,SWT_First_Sales_Touch_Date__c
,SWT_Previous_Lead_Owner_Role__c
,SWT_Days_Since_Assigned_w_out_Conversion__c
,SWT_Lead_Age__c
,SWT_Owner_role_formula__c
,SWT_CMT_1__c
,SWT_CMT_2__c
,SWT_Product_Interest__c
,SWT_Lead_owner_type_User__c
,SWT_Lead_Qualifier_Role_Type__c
,SWT_Primary_campaign__c
,SWT_Last_Assignment_Date__c
,SWT_Website__c
,SWT_Lead_Qualified_Date__c
,SWT_Lead_Qualifier_Role__c
,SWT_Primary_campaign_check__c
,SWT_TEM_Trial__c
,SWT_Account__c
,SWT_Customer_Comments__c
,SWT_Marketing_Comments__c
,Initial_Campaign__c
,SWT_Subscribed_TechBeacon__c
,SWT_Subscribed_All_Applications_Product__c
,SWT_Subscribed_Big_Data_Marketplace__c
,SWT_Subscribed_HPE_Software_Updates__c
,SWT_Parent_Contact__c
,SWT_Parent_Lead__c
,et4ae5__HasOptedOutOfMobile__c
,et4ae5__Mobile_Country_Code__c
,SWT_Business_Area__c
,SWT_DemoChimp_Comments__c
,SWT_External_ID__c
,SWT_ForecastCategory__c
,SWT_TouchGovernance_Marketing_Cloud__c
,SWT_TouchGovernance_Pardot__c
,Address
,fax
,SWT_Existing_Contact__c
,SWT_Lead_Score__c
,SWT_Case_Safe_ID__c
,SWT_Online_Purchase_Type_Term__c
,FCRM__FCR_Created_By_Lead_Conversion__c
,FCRM__FCR_Response_Score__c
,CampaignId
,CFCR_Account_ID__c
,CFCR_Admin_Score_Increment__c
,CFCR_Admin_Score_Increment_Audit__c
,CFCR_FCCRM_Threshold__c
,FCMM__LAM_AccountMatchAttempted__c
,FCMM__LAM_AccountMatchDate__c
,FCMM__LAM_AccountMatchRejected__c
,FCMM__LAM_AccountMatchRejectedDate__c
,FCMM__LAM_AssignDate__c
,FCMM__LAM_AutoConverted__c
,FCMM__LAM_MatchedAccount__c
,FCMM__LAM_MatchedContactID__c
,FCMM__LAM_PotentialAccountMatch__c
,FCMM__LAM_PotentialAccountMatchDate__c
,FCRM__FCR_Admin_Update_Counter__c
,FCRM__FCR_Defer_Assignment__c
,FCRM__FCR_Name_Created_Date__c
,FCRM__FCR_Nurture_Timeout__c
,FCRM__FCR_PostAssignNotificationPending__c
,FCRM__FCR_Prior_Lead_Score__c
,FCRM__FCR_Stage_Age__c
,FCRM__FCR_Status_Last_Set__c
,FCRM__FCR_Status_Synced_From_Response__c
,FCRM__FCR_Superpower_Field__c
,FCRM__FCR_Take_Scoring_Snapshot__c
,Influenced_Opportunity__c
,Merge_Lead__c
,Source_Campaign_ID__c
,SWT_CreatedByMule__c
,SWT_GOV_LLC__c
,SWT_Lead_converted_to_opporty__c
,SWT_Lead_Owner_Manager__c
,SYSDATE AS SWT_INS_DT
FROM SF_Lead_stg_Temp join SF_Lead_stg_Temp_Key 
ON SF_Lead_stg_Temp.id=SF_Lead_stg_Temp_Key.id and SF_Lead_stg_Temp.lastmodifieddate=SF_Lead_stg_Temp_Key.lastmodifieddate
WHERE NOT EXISTS
(SELECT 1 FROM swt_rpt_base.SF_Lead BASE WHERE SF_Lead_stg_Temp_Key.id = BASE.id);
		
		

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_Lead' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_Lead' and  COMPLTN_STAT = 'N');


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
select 'SFDC','SF_Lead',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.SF_Lead where SWT_INS_DT::date = sysdate::date),'Y';

Commit;
    
select do_tm_task('mergeout','swt_rpt_stg.SF_Lead_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_Lead');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_Lead');


