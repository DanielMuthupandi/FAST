/****
****Script Name   : SF_Contact.sql
****Description   : Incremental data load for SF_Contact
****/

/*Setting timing on */
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."SF_Contact";

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
select 'SFDC','SF_Contact',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+Direct*/ INTO swt_rpt_stg.SF_Contact_Hist SELECT * from swt_rpt_stg.SF_Contact;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_Contact where id in (
select id from swt_rpt_stg.SF_Contact group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);
delete from swt_rpt_stg.SF_Contact where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_Contact.id=t2.id and swt_rpt_stg.SF_Contact.auto_id<t2.auto_id);

Commit;


CREATE LOCAL TEMP TABLE SF_Contact_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.SF_Contact)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.SF_Contact;

CREATE LOCAL TEMP TABLE SF_Contact_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,LastModifiedDate FROM swt_rpt_base.SF_Contact)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_Contact_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(LastModifiedDate) as LastModifiedDate FROM SF_Contact_stg_Tmp group by id)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;



/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.SF_Contact_Hist
(
Id
,IsDeleted
,MasterRecordId
,AccountId
,LastName
,FirstName
,Salutation
,MiddleName
,Suffix
,Name
,MailingStreet
,MailingCity
,MailingState
,MailingPostalCode
,MailingCountry
,MailingLatitude
,MailingLongitude
,MailingGeocodeAccuracy
,Phone
,Fax
,MobilePhone
,HomePhone
,ReportsToId
,Email
,Title
,Department
,Description
,CurrencyIsoCode
,OwnerId
,HasOptedOutOfEmail
,HasOptedOutOfFax
,DoNotCall
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,LastCURequestDate
,LastCUUpdateDate
,LastViewedDate
,LastReferencedDate
,EmailBouncedReason
,EmailBouncedDate
,IsEmailBounced
,PhotoUrl
,Jigsaw
,JigsawContactId
,CleanStatus
,SWT_Group_Indicator__c
,SWT_Mail_Opt_Out__c
,SWT_Mobile_Opt_Out__c
,SWT_Phone_Opt_Out__c
,SWT_Private__c
,SWT_Standardized_Title__c
,SWT_ContactLinkedInURL__c
,SWT_Subsidiary__c
,SWT_BU_Relationship__c
,SWT_Job_Seniority__c
,SWT_Job_Role__c
,SWT_SFDC_Refresh_Date__c
,SWT_Source__c
,SWT_Clean_Status__c
,SWT_Preferred_Method_of_contact__c
,SWT_Preferred_Customer_language__c
,SWT_Region__c
,SWT_Contact_Verified__c
,SWT_Address_Validation_Status__c
,SWT_Address_Validation_Fail_Reason__c
,DSE__DS_Company__c
,DSE__DS_Country_ISO_Code__c
,DSE__DS_DataScout_Process__c
,DSE__DS_Legal_Form__c
,DSE__DS_Synchronize__c
,DSE__Domain__c
,SWT_Process_Status_Value__c
,SWT_Contact_Role__c
,SWT_Opportunity__c
,SWT_External_ID__c
,ringdna100__Call_Attempts__c
,ringdna100__Days_Since_Last_Attempt__c
,ringdna100__Email_Attempts__c
,ringdna100__First_Inbound_Call__c
,ringdna100__First_Outbound_Call__c
,ringdna100__Last_Email_Attempt__c
,ringdna100__Last_Inbound_Call__c
,ringdna100__Last_Outbound_Call__c
,ringdna100__Response_Type__c
,ringdna100__Time_Since_Last_Call_Attempt_Days__c
,ringdna100__Time_Since_Last_Call_Attempt_Minutes__c
,ringdna100__Time_Since_Last_Email_Attempt_Days__c
,ringdna100__Time_Since_Last_Email_Attempt_Minutes__c
,ringdna100__Time_to_First_Dial_Minutes__c
,ringdna100__Time_to_First_Response__c
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
,SWT_ACCmap_Region__c
,SWT_Last_Update_on_Privacy_Information__c
,SWT_Also_exist_in_HP_Passport__c
,SWT_Profile_ID__c
,SWT_Extension_Number__c
,SWT_Purchaser_Role__c
,SWT_Business_Phone__c
,SWT_Is_Partner_Contact__c
,SWT_Partner_Contact_Relationship__c
,SWT_User_Set_Up_in_Salesforce__c
,SWT_Is_Customer_Contact__c
,MailingAddress
,Mailing_Country_Non_Latin__c
,SWT_First_Name_Non_Latin__c
,SWT_Group__c
,SWT_Inactive__c
,SWT_Last_Name_Non_Latin__c
,SWT_Learner_ID__c
,SWT_Mailing_City_Non_Latin__c
,SWT_Mailing_State_Province_Non_Latin__c
,SWT_Mailing_Street_Non_Latin__c
,SWT_Mailing_Zip_Postal_Code_Non_Latin__c
,SWT_Middle_Name_Non_Latin__c
,SWT_Subscribed_All_Applications__c
,SWT_Subscribed_Big_Data_Marketplace__c
,SWT_Subscribed_HPE_Software_Updates__c
,SWT_Subscribed_TechBeacon__c
,SWT_TouchGovernance_Marketing_Cloud__c
,SWT_TouchGovernance_Pardot__c
,Source__c
,et4ae5__HasOptedOutOfMobile__c
,et4ae5__Mobile_Country_Code__c
,LeadSource
,SWT_Account_Name__c
,SWT_Business_Unit__c
,SWT_Contact_Score__c
,SWT_Edu_Admin__c
,SWT_HPE_Passport_Id__c
,SWT_Portal_Admin__c
,SWT_Self_Registered_Contact__c
,SWT_Training_Admin__c
,SWT_Passport_CountryISOCode__c
,SWT_Passport_LanguageCode__c
,SWT_PDAPI_Eval_Merchant_Codes__c
,FCRM__FCR_Created_By_Lead_Conversion__c
,FCRM__FCR_Name_Created_Date__c
,FCRM__FCR_Response_Score__c
,FCRM__FCR_Status__c
,Birthdate
,CFCR_Exclude_From_Campaign_Influence__c
,CFCR_FCCRM_Threshold__c
,CFCR_TEM_Trial__c
,Contact_BU_History__c
,FCMM__LAM_EmailDomain__c
,FCRM__FCR_Admin_Person_RecordType__c
,FCRM__FCR_Admin_Update_Counter__c
,FCRM__FCR_Nurture_Timeout__c
,FCRM__FCR_PostAssignNotificationPending__c
,FCRM__FCR_Prior_Contact_Score__c
,FCRM__FCR_Stage_Age__c
,FCRM__FCR_Status_Last_Set__c
,FCRM__FCR_Status_Synced_From_Response__c
,FCRM__FCR_Superpower_Field__c
,FCRM__FCR_Take_Scoring_Snapshot__c
,FCRM__FCR_Temp_Lead_Created_Date__c
,Initial_Campaign__c
,Source_Campaign_ID__c
,SWT_Country__c
,SWT_Customer_Comments__c
,SWT_Federal__c
,SWT_Marketing_Comments__c
,SWT_Original_BU__c
,LD_DT
,SWT_INS_DT
,d_source
)
select
Id
,IsDeleted
,MasterRecordId
,AccountId
,LastName
,FirstName
,Salutation
,MiddleName
,Suffix
,Name
,MailingStreet
,MailingCity
,MailingState
,MailingPostalCode
,MailingCountry
,MailingLatitude
,MailingLongitude
,MailingGeocodeAccuracy
,Phone
,Fax
,MobilePhone
,HomePhone
,ReportsToId
,Email
,Title
,Department
,Description
,CurrencyIsoCode
,OwnerId
,HasOptedOutOfEmail
,HasOptedOutOfFax
,DoNotCall
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,LastCURequestDate
,LastCUUpdateDate
,LastViewedDate
,LastReferencedDate
,EmailBouncedReason
,EmailBouncedDate
,IsEmailBounced
,PhotoUrl
,Jigsaw
,JigsawContactId
,CleanStatus
,SWT_Group_Indicator__c
,SWT_Mail_Opt_Out__c
,SWT_Mobile_Opt_Out__c
,SWT_Phone_Opt_Out__c
,SWT_Private__c
,SWT_Standardized_Title__c
,SWT_ContactLinkedInURL__c
,SWT_Subsidiary__c
,SWT_BU_Relationship__c
,SWT_Job_Seniority__c
,SWT_Job_Role__c
,SWT_SFDC_Refresh_Date__c
,SWT_Source__c
,SWT_Clean_Status__c
,SWT_Preferred_Method_of_contact__c
,SWT_Preferred_Customer_language__c
,SWT_Region__c
,SWT_Contact_Verified__c
,SWT_Address_Validation_Status__c
,SWT_Address_Validation_Fail_Reason__c
,DSE__DS_Company__c
,DSE__DS_Country_ISO_Code__c
,DSE__DS_DataScout_Process__c
,DSE__DS_Legal_Form__c
,DSE__DS_Synchronize__c
,DSE__Domain__c
,SWT_Process_Status_Value__c
,SWT_Contact_Role__c
,SWT_Opportunity__c
,SWT_External_ID__c
,ringdna100__Call_Attempts__c
,ringdna100__Days_Since_Last_Attempt__c
,ringdna100__Email_Attempts__c
,ringdna100__First_Inbound_Call__c
,ringdna100__First_Outbound_Call__c
,ringdna100__Last_Email_Attempt__c
,ringdna100__Last_Inbound_Call__c
,ringdna100__Last_Outbound_Call__c
,ringdna100__Response_Type__c
,ringdna100__Time_Since_Last_Call_Attempt_Days__c
,ringdna100__Time_Since_Last_Call_Attempt_Minutes__c
,ringdna100__Time_Since_Last_Email_Attempt_Days__c
,ringdna100__Time_Since_Last_Email_Attempt_Minutes__c
,ringdna100__Time_to_First_Dial_Minutes__c
,ringdna100__Time_to_First_Response__c
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
,SWT_ACCmap_Region__c
,SWT_Last_Update_on_Privacy_Information__c
,SWT_Also_exist_in_HP_Passport__c
,SWT_Profile_ID__c
,SWT_Extension_Number__c
,SWT_Purchaser_Role__c
,SWT_Business_Phone__c
,SWT_Is_Partner_Contact__c
,SWT_Partner_Contact_Relationship__c
,SWT_User_Set_Up_in_Salesforce__c
,SWT_Is_Customer_Contact__c
,MailingAddress
,Mailing_Country_Non_Latin__c
,SWT_First_Name_Non_Latin__c
,SWT_Group__c
,SWT_Inactive__c
,SWT_Last_Name_Non_Latin__c
,SWT_Learner_ID__c
,SWT_Mailing_City_Non_Latin__c
,SWT_Mailing_State_Province_Non_Latin__c
,SWT_Mailing_Street_Non_Latin__c
,SWT_Mailing_Zip_Postal_Code_Non_Latin__c
,SWT_Middle_Name_Non_Latin__c
,SWT_Subscribed_All_Applications__c
,SWT_Subscribed_Big_Data_Marketplace__c
,SWT_Subscribed_HPE_Software_Updates__c
,SWT_Subscribed_TechBeacon__c
,SWT_TouchGovernance_Marketing_Cloud__c
,SWT_TouchGovernance_Pardot__c
,Source__c
,et4ae5__HasOptedOutOfMobile__c
,et4ae5__Mobile_Country_Code__c
,LeadSource
,SWT_Account_Name__c
,SWT_Business_Unit__c
,SWT_Contact_Score__c
,SWT_Edu_Admin__c
,SWT_HPE_Passport_Id__c
,SWT_Portal_Admin__c
,SWT_Self_Registered_Contact__c
,SWT_Training_Admin__c
,SWT_Passport_CountryISOCode__c
,SWT_Passport_LanguageCode__c
,SWT_PDAPI_Eval_Merchant_Codes__c
,FCRM__FCR_Created_By_Lead_Conversion__c
,FCRM__FCR_Name_Created_Date__c
,FCRM__FCR_Response_Score__c
,FCRM__FCR_Status__c
,Birthdate
,CFCR_Exclude_From_Campaign_Influence__c
,CFCR_FCCRM_Threshold__c
,CFCR_TEM_Trial__c
,Contact_BU_History__c
,FCMM__LAM_EmailDomain__c
,FCRM__FCR_Admin_Person_RecordType__c
,FCRM__FCR_Admin_Update_Counter__c
,FCRM__FCR_Nurture_Timeout__c
,FCRM__FCR_PostAssignNotificationPending__c
,FCRM__FCR_Prior_Contact_Score__c
,FCRM__FCR_Stage_Age__c
,FCRM__FCR_Status_Last_Set__c
,FCRM__FCR_Status_Synced_From_Response__c
,FCRM__FCR_Superpower_Field__c
,FCRM__FCR_Take_Scoring_Snapshot__c
,FCRM__FCR_Temp_Lead_Created_Date__c
,Initial_Campaign__c
,Source_Campaign_ID__c
,SWT_Country__c
,SWT_Customer_Comments__c
,SWT_Federal__c
,SWT_Marketing_Comments__c
,SWT_Original_BU__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".SF_Contact WHERE id in
(SELECT STG.id FROM SF_Contact_stg_Tmp_Key STG JOIN SF_Contact_base_Tmp
ON STG.id = SF_Contact_base_Tmp.id AND STG.LastModifiedDate >= SF_Contact_base_Tmp.LastModifiedDate);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."SF_Contact_HIST"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_Contact WHERE id in
(SELECT STG.id FROM SF_Contact_stg_Tmp_Key STG JOIN SF_Contact_base_Tmp
ON STG.id = SF_Contact_base_Tmp.id AND STG.LastModifiedDate >= SF_Contact_base_Tmp.LastModifiedDate);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_Contact
(
Id
,IsDeleted
,MasterRecordId
,AccountId
,LastName
,FirstName
,Salutation
,MiddleName
,Suffix
,Name
,MailingStreet
,MailingCity
,MailingState
,MailingPostalCode
,MailingCountry
,MailingLatitude
,MailingLongitude
,MailingGeocodeAccuracy
,Phone
,Fax
,MobilePhone
,HomePhone
,ReportsToId
,Email
,Title
,Department
,Description
,CurrencyIsoCode
,OwnerId
,HasOptedOutOfEmail
,HasOptedOutOfFax
,DoNotCall
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,LastCURequestDate
,LastCUUpdateDate
,LastViewedDate
,LastReferencedDate
,EmailBouncedReason
,EmailBouncedDate
,IsEmailBounced
,PhotoUrl
,Jigsaw
,JigsawContactId
,CleanStatus
,SWT_Group_Indicator__c
,SWT_Mail_Opt_Out__c
,SWT_Mobile_Opt_Out__c
,SWT_Phone_Opt_Out__c
,SWT_Private__c
,SWT_Standardized_Title__c
,SWT_ContactLinkedInURL__c
,SWT_Subsidiary__c
,SWT_BU_Relationship__c
,SWT_Job_Seniority__c
,SWT_Job_Role__c
,SWT_SFDC_Refresh_Date__c
,SWT_Source__c
,SWT_Clean_Status__c
,SWT_Preferred_Method_of_contact__c
,SWT_Preferred_Customer_language__c
,SWT_Region__c
,SWT_Contact_Verified__c
,SWT_Address_Validation_Status__c
,SWT_Address_Validation_Fail_Reason__c
,DSE__DS_Company__c
,DSE__DS_Country_ISO_Code__c
,DSE__DS_DataScout_Process__c
,DSE__DS_Legal_Form__c
,DSE__DS_Synchronize__c
,DSE__Domain__c
,SWT_Process_Status_Value__c
,SWT_Contact_Role__c
,SWT_Opportunity__c
,SWT_External_ID__c
,ringdna100__Call_Attempts__c
,ringdna100__Days_Since_Last_Attempt__c
,ringdna100__Email_Attempts__c
,ringdna100__First_Inbound_Call__c
,ringdna100__First_Outbound_Call__c
,ringdna100__Last_Email_Attempt__c
,ringdna100__Last_Inbound_Call__c
,ringdna100__Last_Outbound_Call__c
,ringdna100__Response_Type__c
,ringdna100__Time_Since_Last_Call_Attempt_Days__c
,ringdna100__Time_Since_Last_Call_Attempt_Minutes__c
,ringdna100__Time_Since_Last_Email_Attempt_Days__c
,ringdna100__Time_Since_Last_Email_Attempt_Minutes__c
,ringdna100__Time_to_First_Dial_Minutes__c
,ringdna100__Time_to_First_Response__c
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
,SWT_ACCmap_Region__c
,SWT_Last_Update_on_Privacy_Information__c
,SWT_Also_exist_in_HP_Passport__c
,SWT_Profile_ID__c
,SWT_Extension_Number__c
,SWT_Purchaser_Role__c
,SWT_Business_Phone__c
,SWT_Is_Partner_Contact__c
,SWT_Partner_Contact_Relationship__c
,SWT_User_Set_Up_in_Salesforce__c
,SWT_Is_Customer_Contact__c
,MailingAddress
,Mailing_Country_Non_Latin__c
,SWT_First_Name_Non_Latin__c
,SWT_Group__c
,SWT_Inactive__c
,SWT_Last_Name_Non_Latin__c
,SWT_Learner_ID__c
,SWT_Mailing_City_Non_Latin__c
,SWT_Mailing_State_Province_Non_Latin__c
,SWT_Mailing_Street_Non_Latin__c
,SWT_Mailing_Zip_Postal_Code_Non_Latin__c
,SWT_Middle_Name_Non_Latin__c
,SWT_Subscribed_All_Applications__c
,SWT_Subscribed_Big_Data_Marketplace__c
,SWT_Subscribed_HPE_Software_Updates__c
,SWT_Subscribed_TechBeacon__c
,SWT_TouchGovernance_Marketing_Cloud__c
,SWT_TouchGovernance_Pardot__c
,Source__c
,et4ae5__HasOptedOutOfMobile__c
,et4ae5__Mobile_Country_Code__c
,LeadSource
,SWT_Account_Name__c
,SWT_Business_Unit__c
,SWT_Contact_Score__c
,SWT_Edu_Admin__c
,SWT_HPE_Passport_Id__c
,SWT_Portal_Admin__c
,SWT_Self_Registered_Contact__c
,SWT_Training_Admin__c
,SWT_Passport_CountryISOCode__c
,SWT_Passport_LanguageCode__c
,SWT_PDAPI_Eval_Merchant_Codes__c
,FCRM__FCR_Created_By_Lead_Conversion__c
,FCRM__FCR_Name_Created_Date__c
,FCRM__FCR_Response_Score__c
,FCRM__FCR_Status__c
,Birthdate
,CFCR_Exclude_From_Campaign_Influence__c
,CFCR_FCCRM_Threshold__c
,CFCR_TEM_Trial__c
,Contact_BU_History__c
,FCMM__LAM_EmailDomain__c
,FCRM__FCR_Admin_Person_RecordType__c
,FCRM__FCR_Admin_Update_Counter__c
,FCRM__FCR_Nurture_Timeout__c
,FCRM__FCR_PostAssignNotificationPending__c
,FCRM__FCR_Prior_Contact_Score__c
,FCRM__FCR_Stage_Age__c
,FCRM__FCR_Status_Last_Set__c
,FCRM__FCR_Status_Synced_From_Response__c
,FCRM__FCR_Superpower_Field__c
,FCRM__FCR_Take_Scoring_Snapshot__c
,FCRM__FCR_Temp_Lead_Created_Date__c
,Initial_Campaign__c
,Source_Campaign_ID__c
,SWT_Country__c
,SWT_Customer_Comments__c
,SWT_Federal__c
,SWT_Marketing_Comments__c
,SWT_Original_BU__c
,SWT_INS_DT
)
SELECT DISTINCT 
SF_Contact_stg_Tmp.Id
,IsDeleted
,MasterRecordId
,AccountId
,LastName
,FirstName
,Salutation
,MiddleName
,Suffix
,Name
,MailingStreet
,MailingCity
,MailingState
,MailingPostalCode
,MailingCountry
,MailingLatitude
,MailingLongitude
,MailingGeocodeAccuracy
,Phone
,Fax
,MobilePhone
,HomePhone
,ReportsToId
,Email
,Title
,Department
,Description
,CurrencyIsoCode
,OwnerId
,HasOptedOutOfEmail
,HasOptedOutOfFax
,DoNotCall
,CreatedDate
,CreatedById
,SF_Contact_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,LastCURequestDate
,LastCUUpdateDate
,LastViewedDate
,LastReferencedDate
,EmailBouncedReason
,EmailBouncedDate
,IsEmailBounced
,PhotoUrl
,Jigsaw
,JigsawContactId
,CleanStatus
,SWT_Group_Indicator__c
,SWT_Mail_Opt_Out__c
,SWT_Mobile_Opt_Out__c
,SWT_Phone_Opt_Out__c
,SWT_Private__c
,SWT_Standardized_Title__c
,SWT_ContactLinkedInURL__c
,SWT_Subsidiary__c
,SWT_BU_Relationship__c
,SWT_Job_Seniority__c
,SWT_Job_Role__c
,SWT_SFDC_Refresh_Date__c
,SWT_Source__c
,SWT_Clean_Status__c
,SWT_Preferred_Method_of_contact__c
,SWT_Preferred_Customer_language__c
,SWT_Region__c
,SWT_Contact_Verified__c
,SWT_Address_Validation_Status__c
,SWT_Address_Validation_Fail_Reason__c
,DSE__DS_Company__c
,DSE__DS_Country_ISO_Code__c
,DSE__DS_DataScout_Process__c
,DSE__DS_Legal_Form__c
,DSE__DS_Synchronize__c
,DSE__Domain__c
,SWT_Process_Status_Value__c
,SWT_Contact_Role__c
,SWT_Opportunity__c
,SWT_External_ID__c
,ringdna100__Call_Attempts__c
,ringdna100__Days_Since_Last_Attempt__c
,ringdna100__Email_Attempts__c
,ringdna100__First_Inbound_Call__c
,ringdna100__First_Outbound_Call__c
,ringdna100__Last_Email_Attempt__c
,ringdna100__Last_Inbound_Call__c
,ringdna100__Last_Outbound_Call__c
,ringdna100__Response_Type__c
,ringdna100__Time_Since_Last_Call_Attempt_Days__c
,ringdna100__Time_Since_Last_Call_Attempt_Minutes__c
,ringdna100__Time_Since_Last_Email_Attempt_Days__c
,ringdna100__Time_Since_Last_Email_Attempt_Minutes__c
,ringdna100__Time_to_First_Dial_Minutes__c
,ringdna100__Time_to_First_Response__c
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
,SWT_ACCmap_Region__c
,SWT_Last_Update_on_Privacy_Information__c
,SWT_Also_exist_in_HP_Passport__c
,SWT_Profile_ID__c
,SWT_Extension_Number__c
,SWT_Purchaser_Role__c
,SWT_Business_Phone__c
,SWT_Is_Partner_Contact__c
,SWT_Partner_Contact_Relationship__c
,SWT_User_Set_Up_in_Salesforce__c
,SWT_Is_Customer_Contact__c
,MailingAddress
,Mailing_Country_Non_Latin__c
,SWT_First_Name_Non_Latin__c
,SWT_Group__c
,SWT_Inactive__c
,SWT_Last_Name_Non_Latin__c
,SWT_Learner_ID__c
,SWT_Mailing_City_Non_Latin__c
,SWT_Mailing_State_Province_Non_Latin__c
,SWT_Mailing_Street_Non_Latin__c
,SWT_Mailing_Zip_Postal_Code_Non_Latin__c
,SWT_Middle_Name_Non_Latin__c
,SWT_Subscribed_All_Applications__c
,SWT_Subscribed_Big_Data_Marketplace__c
,SWT_Subscribed_HPE_Software_Updates__c
,SWT_Subscribed_TechBeacon__c
,SWT_TouchGovernance_Marketing_Cloud__c
,SWT_TouchGovernance_Pardot__c
,Source__c
,et4ae5__HasOptedOutOfMobile__c
,et4ae5__Mobile_Country_Code__c
,LeadSource
,SWT_Account_Name__c
,SWT_Business_Unit__c
,SWT_Contact_Score__c
,SWT_Edu_Admin__c
,SWT_HPE_Passport_Id__c
,SWT_Portal_Admin__c
,SWT_Self_Registered_Contact__c
,SWT_Training_Admin__c
,SWT_Passport_CountryISOCode__c
,SWT_Passport_LanguageCode__c
,SWT_PDAPI_Eval_Merchant_Codes__c
,FCRM__FCR_Created_By_Lead_Conversion__c
,FCRM__FCR_Name_Created_Date__c
,FCRM__FCR_Response_Score__c
,FCRM__FCR_Status__c
,Birthdate
,CFCR_Exclude_From_Campaign_Influence__c
,CFCR_FCCRM_Threshold__c
,CFCR_TEM_Trial__c
,Contact_BU_History__c
,FCMM__LAM_EmailDomain__c
,FCRM__FCR_Admin_Person_RecordType__c
,FCRM__FCR_Admin_Update_Counter__c
,FCRM__FCR_Nurture_Timeout__c
,FCRM__FCR_PostAssignNotificationPending__c
,FCRM__FCR_Prior_Contact_Score__c
,FCRM__FCR_Stage_Age__c
,FCRM__FCR_Status_Last_Set__c
,FCRM__FCR_Status_Synced_From_Response__c
,FCRM__FCR_Superpower_Field__c
,FCRM__FCR_Take_Scoring_Snapshot__c
,FCRM__FCR_Temp_Lead_Created_Date__c
,Initial_Campaign__c
,Source_Campaign_ID__c
,SWT_Country__c
,SWT_Customer_Comments__c
,SWT_Federal__c
,SWT_Marketing_Comments__c
,SWT_Original_BU__c
,SYSDATE AS SWT_INS_DT
FROM SF_Contact_stg_Tmp JOIN SF_Contact_stg_Tmp_Key ON SF_Contact_stg_Tmp.id= SF_Contact_stg_Tmp_Key.id AND SF_Contact_stg_Tmp.LastModifiedDate=SF_Contact_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 from "swt_rpt_base".SF_Contact BASE
WHERE SF_Contact_stg_Tmp.id = BASE.id);



/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_Contact' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_Contact' and  COMPLTN_STAT = 'N');


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
select 'SFDC','SF_Contact',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.SF_Contact where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


select do_tm_task('mergeout','swt_rpt_stg.SF_Contact_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_Contact');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.SF_Contact');



