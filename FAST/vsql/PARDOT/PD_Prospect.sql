/****
****Script Name   : PD_Prospect.sql
****Description   : Incremental data load for PD_Prospect
****/

/*Setting timing on */
\timing
\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."PD_Prospect";

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
select 'PARDOT','PD_Prospect',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;


CREATE LOCAL TEMP TABLE PD_Prospect_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.PD_Prospect)
SEGMENTED BY HASH(id,updated_at) ALL NODES;
INSERT /*+DIRECT*/ INTO "swt_rpt_stg".PD_Prospect_Hist SELECT * from "swt_rpt_stg".PD_Prospect;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.PD_Prospect;

CREATE LOCAL TEMP TABLE PD_Prospect_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Prospect_Id,Updated_Date FROM swt_rpt_base.PD_Prospect)
SEGMENTED BY HASH(Prospect_Id,Updated_Date) ALL NODES;


CREATE LOCAL TEMP TABLE PD_Prospect_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(updated_at) as updated_at FROM PD_Prospect_stg_Tmp group by id)
SEGMENTED BY HASH(id,updated_at) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.PD_Prospect_Hist
(
 id
,address_one
,address_two
,annual_revenue
,city
,comments
,company
,country
,department
,is_do_not_call
,is_do_not_email
,email
,email_bounced_date
,email_bounced_reason
,employees
,fax
,first_name
,industry
,job_title
,last_name
,source
,opted_out
,pardot_hard_bounced
,phone
,salutation
,last_scored_at
,state
,territory
,website
,years_in_business
,zip
,Activity_Trial_status___Catch_all
,Application_Defender_Trial_Status
,AppPulse_Mobile_Trial_Status
,Big_Data_Partner_Form___Catch_all
,Bio
,SWT_Phone
,Business_Unit
,Campaign_Name
,Company_Year_Founded
,Current_Customer___Products
,Customer_Event
,Customer_Event___Buy
,Data_Volume
,DemoChimp_Comments
,DemoChimp_Demo
,DemoChimp_Details_URL
,Display_Name
,Email_Opt_In
,Event_Registrations
,Form
,Form_comments
,Funding
,Gated_Asset_ID
,Gated_Asset_Name
,Github_URL
,Initial_Campaign_Parameters
,IsAnEmployee
,IsCurrentCustomer
,Job_Level
,Job_Responsibility
,Language
,Lead_Source_Information
,Lead_Status
,Line_of_Business
,LinkedIn_URL
,Marketing_Comment
,Marketplace_Developer_Apps
,Marketplace_Downloads
,Mobile_Opt_Out
,Mobile_Phone
,SWT_Non_converting_Lead
,Package_Type_and_Term
,SFDC_Campaign
,Partner_ID
,Partner_Type
,Personal_Blog
,Picture_URL
,Security_Pillars
,Preferred_Method_of_Contact
,Primary_campaign
,Product_Global_Registration_Question
,Product_Interest
,Website_Referral_Source
,SWT_Region
,SWT_Reset_ADM
,SWT_Reset_BDP
,SWT_Reset_ESP
,SWT_Reset_IM_G
,SWT_Reset_ITOM
,Sales_Representative__filled_by_user_
,Subscribed_HPE_Software_Updates
,Subscribed_TechBeacon
,TB_Customer_Event
,TechBeacon_Area_of_Expertise
,TechBeacon_No__Articles
,TEM_Product
,TESTER__Admin_only_
,Topic_Categories
,TouchGovernance_MarketingCloud
,TouchGovernance_Pardot
,Tracking_ID
,Twitter
,Vertica_Accelerator_Interested_Tier
,ViewArchivedWebinar
,WebinarKey
,Writing_Samples
,Unknown_Phone_Preference
,Unknown_Email_Preference
,sub_industry
,SWT_Phone_Preference_Date
,SWT_Mobile_Preference_Date
,SWT_MDCP_Organization
,marketing_alias
,SWT_Mail_Preference_Date
,SWT_Job_Seniority
,Job_Function_Category
,fortune_1000
,forbes_2000
,SWT_Email_Validity_DTTM
,SWT_Email_Preference_Date
,SWT_DUNS_NUM
,demandbase_sid
,SWT_Company_Phone_Full
,b2c
,b2b
,SWT_Aprimo_Integrated_Campaign_Title
,SWT_Aprimo_Activity_Title
,SWT_Aprimo_Activity_ID
,SWT_AMID
,Score
,Grade
,SFDC_Campaign_ID
,Exclude_from_IP_Warming
,Created_Date
,updated_at
,SWT_INS_DT
,d_source
)
select
Prospect_Id
,address_one
,address_two
,annual_revenue
,city
,comments
,company
,country
,department
,is_do_not_call
,is_do_not_email
,email
,email_bounced_date
,email_bounced_reason
,employees
,fax
,first_name
,industry
,job_title
,last_name
,source
,opted_out
,pardot_hard_bounced
,phone
,salutation
,last_scored_at
,state
,territory
,website
,years_in_business
,zip
,Activity_Trial_status___Catch_all
,Application_Defender_Trial_Status
,AppPulse_Mobile_Trial_Status
,Big_Data_Partner_Form___Catch_all
,Bio
,SWT_Phone
,Business_Unit
,Campaign_Name
,Company_Year_Founded
,Current_Customer___Products
,Customer_Event
,Customer_Event___Buy
,Data_Volume
,DemoChimp_Comments
,DemoChimp_Demo
,DemoChimp_Details_URL
,Display_Name
,Email_Opt_In
,Event_Registrations
,Form
,Form_comments
,Funding
,Gated_Asset_ID
,Gated_Asset_Name
,Github_URL
,Initial_Campaign_Parameters
,IsAnEmployee
,IsCurrentCustomer
,Job_Level
,Job_Responsibility
,Language
,Lead_Source_Information
,Lead_Status
,Line_of_Business
,LinkedIn_URL
,Marketing_Comment
,Marketplace_Developer_Apps
,Marketplace_Downloads
,Mobile_Opt_Out
,Mobile_Phone
,SWT_Non_converting_Lead
,Package_Type_and_Term
,SFDC_Campaign
,Partner_ID
,Partner_Type
,Personal_Blog
,Picture_URL
,Security_Pillars
,Preferred_Method_of_Contact
,Primary_campaign
,Product_Global_Registration_Question
,Product_Interest
,Website_Referral_Source
,SWT_Region
,SWT_Reset_ADM
,SWT_Reset_BDP
,SWT_Reset_ESP
,SWT_Reset_IM_G
,SWT_Reset_ITOM
,Sales_Representative__filled_by_user_
,Subscribed_HPE_Software_Updates
,Subscribed_TechBeacon
,TB_Customer_Event
,TechBeacon_Area_of_Expertise
,TechBeacon_No__Articles
,TEM_Product
,TESTER__Admin_only_
,Topic_Categories
,TouchGovernance_MarketingCloud
,TouchGovernance_Pardot
,Tracking_ID
,Twitter
,Vertica_Accelerator_Interested_Tier
,ViewArchivedWebinar
,WebinarKey
,Writing_Samples
,Unknown_Phone_Preference
,Unknown_Email_Preference
,sub_industry
,SWT_Phone_Preference_Date
,SWT_Mobile_Preference_Date
,SWT_MDCP_Organization
,marketing_alias
,SWT_Mail_Preference_Date
,SWT_Job_Seniority
,Job_Function_Category
,fortune_1000
,forbes_2000
,SWT_Email_Validity_DTTM
,SWT_Email_Preference_Date
,SWT_DUNS_NUM
,demandbase_sid
,SWT_Company_Phone_Full
,b2c
,b2b
,SWT_Aprimo_Integrated_Campaign_Title
,SWT_Aprimo_Activity_Title
,SWT_Aprimo_Activity_ID
,SWT_AMID
,Score
,Grade
,SFDC_Campaign_ID
,Exclude_from_IP_Warming
,Created_Date
,Updated_Date
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".PD_Prospect WHERE Prospect_Id in
(SELECT STG.id FROM PD_Prospect_stg_Tmp_Key STG JOIN PD_Prospect_base_Tmp
ON STG.id = PD_Prospect_base_Tmp.Prospect_Id AND STG.updated_at >= PD_Prospect_base_Tmp.Updated_Date);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."PD_Prospect_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

DELETE /*+DIRECT*/ FROM "swt_rpt_base".PD_Prospect WHERE Prospect_Id in
(SELECT STG.id FROM PD_Prospect_stg_Tmp_Key STG JOIN PD_Prospect_base_Tmp
ON STG.id = PD_Prospect_base_Tmp.Prospect_Id AND STG.updated_at >= PD_Prospect_base_Tmp.Updated_Date);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".PD_Prospect
(
Prospect_Id
,address_one
,address_two
,annual_revenue
,city
,comments
,company
,country
,department
,is_do_not_call
,is_do_not_email
,email
,email_bounced_date
,email_bounced_reason
,employees
,fax
,first_name
,industry
,job_title
,last_name
,source
,opted_out
,pardot_hard_bounced
,phone
,salutation
,last_scored_at
,state
,territory
,website
,years_in_business
,zip
,Activity_Trial_status___Catch_all
,Application_Defender_Trial_Status
,AppPulse_Mobile_Trial_Status
,Big_Data_Partner_Form___Catch_all
,Bio
,SWT_Phone
,Business_Unit
,Campaign_Name
,Company_Year_Founded
,Current_Customer___Products
,Customer_Event
,Customer_Event___Buy
,Data_Volume
,DemoChimp_Comments
,DemoChimp_Demo
,DemoChimp_Details_URL
,Display_Name
,Email_Opt_In
,Event_Registrations
,Form
,Form_comments
,Funding
,Gated_Asset_ID
,Gated_Asset_Name
,Github_URL
,Initial_Campaign_Parameters
,IsAnEmployee
,IsCurrentCustomer
,Job_Level
,Job_Responsibility
,Language
,Lead_Source_Information
,Lead_Status
,Line_of_Business
,LinkedIn_URL
,Marketing_Comment
,Marketplace_Developer_Apps
,Marketplace_Downloads
,Mobile_Opt_Out
,Mobile_Phone
,SWT_Non_converting_Lead
,Package_Type_and_Term
,SFDC_Campaign
,Partner_ID
,Partner_Type
,Personal_Blog
,Picture_URL
,Security_Pillars
,Preferred_Method_of_Contact
,Primary_campaign
,Product_Global_Registration_Question
,Product_Interest
,Website_Referral_Source
,SWT_Region
,SWT_Reset_ADM
,SWT_Reset_BDP
,SWT_Reset_ESP
,SWT_Reset_IM_G
,SWT_Reset_ITOM
,Sales_Representative__filled_by_user_
,Subscribed_HPE_Software_Updates
,Subscribed_TechBeacon
,TB_Customer_Event
,TechBeacon_Area_of_Expertise
,TechBeacon_No__Articles
,TEM_Product
,TESTER__Admin_only_
,Topic_Categories
,TouchGovernance_MarketingCloud
,TouchGovernance_Pardot
,Tracking_ID
,Twitter
,Vertica_Accelerator_Interested_Tier
,ViewArchivedWebinar
,WebinarKey
,Writing_Samples
,Unknown_Phone_Preference
,Unknown_Email_Preference
,sub_industry
,SWT_Phone_Preference_Date
,SWT_Mobile_Preference_Date
,SWT_MDCP_Organization
,marketing_alias
,SWT_Mail_Preference_Date
,SWT_Job_Seniority
,Job_Function_Category
,fortune_1000
,forbes_2000
,SWT_Email_Validity_DTTM
,SWT_Email_Preference_Date
,SWT_DUNS_NUM
,demandbase_sid
,SWT_Company_Phone_Full
,b2c
,b2b
,SWT_Aprimo_Integrated_Campaign_Title
,SWT_Aprimo_Activity_Title
,SWT_Aprimo_Activity_ID
,SWT_AMID
,Score
,Grade
,SFDC_Campaign_ID
,Exclude_from_IP_Warming
,Created_Date
,Updated_Date
,SWT_INS_DT
)
SELECT DISTINCT 
PD_Prospect_stg_Tmp.id
,address_one
,address_two
,annual_revenue
,city
,comments
,company
,country
,department
,is_do_not_call
,is_do_not_email
,email
,email_bounced_date
,email_bounced_reason
,employees
,fax
,first_name
,industry
,job_title
,last_name
,source
,opted_out
,pardot_hard_bounced
,phone
,salutation
,last_scored_at
,state
,territory
,website
,years_in_business
,zip
,Activity_Trial_status___Catch_all
,Application_Defender_Trial_Status
,AppPulse_Mobile_Trial_Status
,Big_Data_Partner_Form___Catch_all
,Bio
,SWT_Phone
,Business_Unit
,Campaign_Name
,Company_Year_Founded
,Current_Customer___Products
,Customer_Event
,Customer_Event___Buy
,Data_Volume
,DemoChimp_Comments
,DemoChimp_Demo
,DemoChimp_Details_URL
,Display_Name
,Email_Opt_In
,Event_Registrations
,Form
,Form_comments
,Funding
,Gated_Asset_ID
,Gated_Asset_Name
,Github_URL
,Initial_Campaign_Parameters
,IsAnEmployee
,IsCurrentCustomer
,Job_Level
,Job_Responsibility
,Language
,Lead_Source_Information
,Lead_Status
,Line_of_Business
,LinkedIn_URL
,Marketing_Comment
,Marketplace_Developer_Apps
,Marketplace_Downloads
,Mobile_Opt_Out
,Mobile_Phone
,SWT_Non_converting_Lead
,Package_Type_and_Term
,SFDC_Campaign
,Partner_ID
,Partner_Type
,Personal_Blog
,Picture_URL
,Security_Pillars
,Preferred_Method_of_Contact
,Primary_campaign
,Product_Global_Registration_Question
,Product_Interest
,Website_Referral_Source
,SWT_Region
,SWT_Reset_ADM
,SWT_Reset_BDP
,SWT_Reset_ESP
,SWT_Reset_IM_G
,SWT_Reset_ITOM
,Sales_Representative__filled_by_user_
,Subscribed_HPE_Software_Updates
,Subscribed_TechBeacon
,TB_Customer_Event
,TechBeacon_Area_of_Expertise
,TechBeacon_No__Articles
,TEM_Product
,TESTER__Admin_only_
,Topic_Categories
,TouchGovernance_MarketingCloud
,TouchGovernance_Pardot
,Tracking_ID
,Twitter
,Vertica_Accelerator_Interested_Tier
,ViewArchivedWebinar
,WebinarKey
,Writing_Samples
,Unknown_Phone_Preference
,Unknown_Email_Preference
,sub_industry
,SWT_Phone_Preference_Date
,SWT_Mobile_Preference_Date
,SWT_MDCP_Organization
,marketing_alias
,SWT_Mail_Preference_Date
,SWT_Job_Seniority
,Job_Function_Category
,fortune_1000
,forbes_2000
,SWT_Email_Validity_DTTM
,SWT_Email_Preference_Date
,SWT_DUNS_NUM
,demandbase_sid
,SWT_Company_Phone_Full
,b2c
,b2b
,SWT_Aprimo_Integrated_Campaign_Title
,SWT_Aprimo_Activity_Title
,SWT_Aprimo_Activity_ID
,SWT_AMID
,Score
,Grade
,SFDC_Campaign_ID
,Exclude_from_IP_Warming
,Created_Date
,PD_Prospect_stg_Tmp.updated_at
,SYSDATE AS SWT_INS_DT
FROM PD_Prospect_stg_Tmp JOIN PD_Prospect_stg_Tmp_Key ON PD_Prospect_stg_Tmp.id= PD_Prospect_stg_Tmp_Key.id AND PD_Prospect_stg_Tmp.updated_at=PD_Prospect_stg_Tmp_Key.updated_at
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".PD_Prospect BASE
WHERE PD_Prospect_stg_Tmp.id = BASE.Prospect_Id);


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'PARDOT' and
TBL_NM = 'PD_Prospect' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'PARDOT' and  TBL_NM = 'PD_Prospect' and  COMPLTN_STAT = 'N');
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
select 'PARDOT','PD_Prospect',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.PD_Prospect where SWT_INS_DT::date = sysdate::date),'Y';


Commit;
SELECT DO_TM_TASK('mergeout', 'swt_rpt_base.PD_Prospect');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.PD_Prospect_Hist');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.PD_Prospect');

