/****
****Script Name   : SF_Campaign.sql
****Description   : Incremental data load for SF_Campaign
****/

/*Setting timing on */
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

--SET SESSION AUTOCOMMIT TO OFF;

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."SF_Campaign";
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
select 'SFDC','SF_Campaign',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;


INSERT /*+Direct*/ INTO swt_rpt_stg.SF_Campaign_Hist SELECT * from swt_rpt_stg.SF_Campaign;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_Campaign where id in (
select id from swt_rpt_stg.SF_Campaign group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);

delete from swt_rpt_stg.SF_Campaign where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_Campaign.id=t2.id and swt_rpt_stg.SF_Campaign.auto_id<t2.auto_id);

commit;


CREATE LOCAL TEMP TABLE SF_Campaign_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.SF_Campaign)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.SF_Campaign;

CREATE LOCAL TEMP TABLE SF_Campaign_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,LastModifiedDate FROM swt_rpt_base.SF_Campaign)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_Campaign_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(LastModifiedDate) as LastModifiedDate FROM SF_Campaign_stg_Tmp group by id)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;



/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.SF_Campaign_Hist
(
Id
,IsDeleted
,Name
,ParentId
,Type
,RecordTypeId
,Status
,StartDate
,EndDate
,CurrencyIsoCode
,ExpectedRevenue
,BudgetedCost
,ActualCost
,ExpectedResponse
,NumberSent
,IsActive
,Description
,NumberOfLeads
,NumberOfConvertedLeads
,NumberOfContacts
,NumberOfResponses
,NumberOfOpportunities
,NumberOfWonOpportunities
,AmountAllOpportunities
,AmountWonOpportunities
,HierarchyNumberOfLeads
,HierarchyNumberOfConvertedLeads
,HierarchyNumberOfContacts
,HierarchyNumberOfResponses
,HierarchyNumberOfOpportunities
,HierarchyNumberOfWonOpportunities
,HierarchyAmountAllOpportunities
,HierarchyAmountWonOpportunities
,HierarchyNumberSent
,HierarchyExpectedRevenue
,HierarchyBudgetedCost
,HierarchyActualCost
,OwnerId
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,LastViewedDate
,LastReferencedDate
,CampaignMemberRecordTypeId
,SWT_Expected_Leads__c
,SWT_Landing_Page__c
,SWT_Business_Unit__c
,SWT_Partner_Marketing_Campaign__c
,SWT_Status__c
,SWT_Qualification_Team_Name__c
,SWT_Vertical_Industries__c
,SWT_Marketing_Campaign_Owner__c
,SWT_Marketing_Generated__c
,SWT_Program_Name__c
,SWT_City__c
,SWT_Campaign_Country__c
,SWT_Email_Bouncebacks__c
,SWT_Email_Click_Throughs__c
,SWT_Email_Unsubscribers__c
,SWT_Emails_Opened__c
,SWT_Emails_Sent__c
,SWT_Possible_Email_Forwards__c
,SWT_Unique_Email_Visitors__c
,SWT_Call_Center_Calls__c
,SWT_Forms_Submitted__c
,SWT_Print_Mail_Sends__c
,SWT_Surveys_Completed__c
,SWT_Hypersite_Visits__c
,SWT_Online_Referral_Visits__c
,SWT_Campaign_Search_Visits__c
,SWT_Workgroup__c
,SWT_Funding_Account__c
,SWT_Budget_Type__c
,SWT_GTM_Programs__c
,SWT_Plan_vs_Total_Leads_Received__c
,SWT_Sub_Business_Unit__c
,SWT_Total_Closed_Won_Conversion__c
,SWT_Total_Closed_Won_Conversion_value__c
,SWT_Vendor__c
,SWT_New_Business_Opportunity__c
,SWT_Pipeline_Matrix_Sales_Plays__c
,SWT_Campaign_Name_Formula__c
,SWT_Pillar__c
,SWT_Product_Type__c
,SWT_Benefit_Platinum__c
,SWT_Benefit_Gold__c
,SWT_Benefit_Silver__c
,SWT_Benefit__c
,SWT_Discount_Applied__c
,SWT_Tier_Service_Provider_Applicable__c
,SWT_Stackable__c
,SWT_Exclusions__c
,SWT_Quarter__c
,SWT_Product__c
,SWT_Fiscal_Year__c
,SWT_Sourced__c
,SWT_Industry_vertical__c
,Industry_Segment__c
,SWT_Region__c
,SWT_Campaign_Activity_Type__c
,HPSW_Activity__c
,HPSW_Program_Description__c
,HPSW_Campaign_Kit_Link__c
,HPSW_Total_Generated_Pipeline_MGO_MIO__c
,HPSW_Mktg_Actual_Attendance__c
,HPSW_Audience_Target_Size__c
,HPSW_Campaign_with_Education__c
,HPSW_Campaign_with_Professional_Services__c
,HPSW_MDF_Activity_ID__c
,HPSW_Mktg_Expected_Attendance__c
,HPSW_MGO_Planned_Total__c
,HPSW_Outcome_Summary__c
,HPSW_Campaign_Partners__c
,HPSW_Portfolio__c
,HPSW_Target_Audience_Level__c
,HPSW_Sales_Play__c
,HPSW_Target_Account_Type__c
,HPSW_Tweet_Sheet__c
,HPSW_LinkedIn_FB_Post__c
,HPSW_Promo_URL__c
,HPSW_Twitter_Hastag_1__c
,HPSW_Twitter_Hastag_2__c
,HPSW_Twitter_Hastag_3__c
,HPSW_Reg_link__c
,HPSW_MIO_Planned_Total__c
,HPSW_Campaign_Code_Report_Link__c
,HPSW_ADM_Budget__c
,HPSW_ESP_Budget__c
,HPSW_IMG_Budget__c
,HPSW_ITOM_Budget__c
,HPSW_Platform_Budget__c
,HPSW_Total_Budget__c
,HPSW_Aprimo_Activity_Name__c
,HPSW_Bridgeplan_Activity_Name__c
,HPSW_MGO_Planned_ESP__c
,HPSW_MGO_Planned_IMG__c
,HPSW_MGO_Planned_ITOM__c
,HPSW_MGO_Planned_Platform__c
,HPSW_MIO_Planned_ADM__c
,HPSW_MIO_Planned_ESP__c
,HPSW_MIO_Planned_IMG__c
,HPSW_MIO_Planned_ITOM__c
,HPSW_MIO_PLANNED_PLATFORM_C__c
,HPSW_ToGo__c
,HPSW_Total_Expected_Pipeline_MGO_MIO__c
,HPSW_Campaign_State__c
,HPSW_Sales_Rep_Campaign_Participation__c
,HPSW_Sales_Target_Customer_Attendance__c
,HPSW_Sales_Total_Target_Pipeline_Build__c
,HPSW_Campaign_Fiscal_Quarter__c
,HPSW_Campaign_Quarter__c
,SWT_Campaign_Activity_Sub_Type__c
,SWT_Program_Type__c
,SWT_Requires_Claim__c
,SWT_Membership_Specialization_Benefit__c
,SWT_Direct_Indirect_Opportunity__c
,SWT_External_Id__c
,SWT_Aprimo_Id__c
,SWT_Marketing_Business_Unit__c
,SWT_Product_Line__c
,HPSW_Pipeline_Source__c
,SWT_Campaign_External_ID__c
,SWT_Final_Approver__c
,SWT_Lead_Generated_Pipeline__c
,SWT_Marketing_Contributed_Pipeline__c
,SWT_Marketing_Influenced_Pipeline__c
,SWT_URL__c
,HPSW_MGO_Planned_ADM__c
,HPSW_Pillar__c
,SWT_Case_Safe_ID__c
,SWT_Fiscal_Year_Date__c
,Campaign_Owner__c
,SWT_Heirarchy_level__c
,Is_PMX__c
,SWT_Parent_Integrated_Campaign__c
,CFCR_Campaign_Business_Unit_Text__c
,CFCR_Count__c
,FCRM__FCR_Campaign_Sourced_By__c
,FCRM__FCR_QR_s__c
,FCRM__FCR_Qualified_Responses_With_Repeats__c
,SWT_All_Child_Budget__c
,SWT_Campaign_Business_Area__c
,SWT_Campaign_CMT_L1__c
,SWT_Campaign_CMT_L2__c
,Language_Availability__c
,SWT_Sales_Initiative_Type__c
,SWT_Total_Budget__c
,Campaign_CMT_L1__c
,CFCR_Exclude_From_Campaign_Influence__c
,CFCR_FCCRM_Campaign_Threshold__c
,FCRM__FCR_Bypass_Nurture_Timeout__c
,FCRM__FCR_Campaign_Notification_Override__c
,FCRM__FCR_Campaign_Precedence__c
,FCRM__FCR_Cascade_Parent_ID__c
,FCRM__FCR_CascadeParent__c
,FCRM__FCR_ClosedOpRevenueModel1__c
,FCRM__FCR_ClosedOpRevenueModel2__c
,FCRM__FCR_ClosedOpRevenueModel3__c
,FCRM__FCR_Cost_Per_Response__c
,FCRM__FCR_Cost_Per_Response_With_Repeats__c
,FCRM__FCR_LostOpRevenueModel1__c
,FCRM__FCR_LostOpRevenueModel2__c
,FCRM__FCR_LostOpRevenueModel3__c
,FCRM__FCR_Marketing_Region__c
,FCRM__FCR_Net_New_Names__c
,FCRM__FCR_Net_New_Response_Ratio__c
,FCRM__FCR_OpenOpRevenueModel1__c
,FCRM__FCR_OpenOpRevenueModel2__c
,FCRM__FCR_OpenOpRevenueModel3__c
,FCRM__FCR_QR_to_Opportunity_Ratio__c
,FCRM__FCR_Repeat_Campaign_Number__c
,FCRM__FCR_Repeat_Response_Timeout_Segments__c
,FCRM__FCR_Repeat_Responses_Allowed__c
,FCRM__FCR_Responses_to_Won__c
,FCRM__FCR_Sales_Information__c
,FCRM__FCR_Total_Responses_With_Repeats__c
,FCRM__FCR_TotalOpRevenueModel1__c
,FCRM__FCR_TotalOpRevenueModel2__c
,FCRM__FCR_TotalOpRevenueModel3__c
,FCRM__ME_Default_Responded_Member_Status__c
,FCRM__ME_Exclude_From_Reactivation__c
,SWT_Post_Event_New_Promoter_Score__c
,SWT_Pre_Event_Net_Promoter_Score__c
,LD_DT
,SWT_INS_DT
,d_source
)
select
Id
,IsDeleted
,Name
,ParentId
,Type
,RecordTypeId
,Status
,StartDate
,EndDate
,CurrencyIsoCode
,ExpectedRevenue
,BudgetedCost
,ActualCost
,ExpectedResponse
,NumberSent
,IsActive
,Description
,NumberOfLeads
,NumberOfConvertedLeads
,NumberOfContacts
,NumberOfResponses
,NumberOfOpportunities
,NumberOfWonOpportunities
,AmountAllOpportunities
,AmountWonOpportunities
,HierarchyNumberOfLeads
,HierarchyNumberOfConvertedLeads
,HierarchyNumberOfContacts
,HierarchyNumberOfResponses
,HierarchyNumberOfOpportunities
,HierarchyNumberOfWonOpportunities
,HierarchyAmountAllOpportunities
,HierarchyAmountWonOpportunities
,HierarchyNumberSent
,HierarchyExpectedRevenue
,HierarchyBudgetedCost
,HierarchyActualCost
,OwnerId
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,LastViewedDate
,LastReferencedDate
,CampaignMemberRecordTypeId
,SWT_Expected_Leads__c
,SWT_Landing_Page__c
,SWT_Business_Unit__c
,SWT_Partner_Marketing_Campaign__c
,SWT_Status__c
,SWT_Qualification_Team_Name__c
,SWT_Vertical_Industries__c
,SWT_Marketing_Campaign_Owner__c
,SWT_Marketing_Generated__c
,SWT_Program_Name__c
,SWT_City__c
,SWT_Campaign_Country__c
,SWT_Email_Bouncebacks__c
,SWT_Email_Click_Throughs__c
,SWT_Email_Unsubscribers__c
,SWT_Emails_Opened__c
,SWT_Emails_Sent__c
,SWT_Possible_Email_Forwards__c
,SWT_Unique_Email_Visitors__c
,SWT_Call_Center_Calls__c
,SWT_Forms_Submitted__c
,SWT_Print_Mail_Sends__c
,SWT_Surveys_Completed__c
,SWT_Hypersite_Visits__c
,SWT_Online_Referral_Visits__c
,SWT_Campaign_Search_Visits__c
,SWT_Workgroup__c
,SWT_Funding_Account__c
,SWT_Budget_Type__c
,SWT_GTM_Programs__c
,SWT_Plan_vs_Total_Leads_Received__c
,SWT_Sub_Business_Unit__c
,SWT_Total_Closed_Won_Conversion__c
,SWT_Total_Closed_Won_Conversion_value__c
,SWT_Vendor__c
,SWT_New_Business_Opportunity__c
,SWT_Pipeline_Matrix_Sales_Plays__c
,SWT_Campaign_Name_Formula__c
,SWT_Pillar__c
,SWT_Product_Type__c
,SWT_Benefit_Platinum__c
,SWT_Benefit_Gold__c
,SWT_Benefit_Silver__c
,SWT_Benefit__c
,SWT_Discount_Applied__c
,SWT_Tier_Service_Provider_Applicable__c
,SWT_Stackable__c
,SWT_Exclusions__c
,SWT_Quarter__c
,SWT_Product__c
,SWT_Fiscal_Year__c
,SWT_Sourced__c
,SWT_Industry_vertical__c
,Industry_Segment__c
,SWT_Region__c
,SWT_Campaign_Activity_Type__c
,HPSW_Activity__c
,HPSW_Program_Description__c
,HPSW_Campaign_Kit_Link__c
,HPSW_Total_Generated_Pipeline_MGO_MIO__c
,HPSW_Mktg_Actual_Attendance__c
,HPSW_Audience_Target_Size__c
,HPSW_Campaign_with_Education__c
,HPSW_Campaign_with_Professional_Services__c
,HPSW_MDF_Activity_ID__c
,HPSW_Mktg_Expected_Attendance__c
,HPSW_MGO_Planned_Total__c
,HPSW_Outcome_Summary__c
,HPSW_Campaign_Partners__c
,HPSW_Portfolio__c
,HPSW_Target_Audience_Level__c
,HPSW_Sales_Play__c
,HPSW_Target_Account_Type__c
,HPSW_Tweet_Sheet__c
,HPSW_LinkedIn_FB_Post__c
,HPSW_Promo_URL__c
,HPSW_Twitter_Hastag_1__c
,HPSW_Twitter_Hastag_2__c
,HPSW_Twitter_Hastag_3__c
,HPSW_Reg_link__c
,HPSW_MIO_Planned_Total__c
,HPSW_Campaign_Code_Report_Link__c
,HPSW_ADM_Budget__c
,HPSW_ESP_Budget__c
,HPSW_IMG_Budget__c
,HPSW_ITOM_Budget__c
,HPSW_Platform_Budget__c
,HPSW_Total_Budget__c
,HPSW_Aprimo_Activity_Name__c
,HPSW_Bridgeplan_Activity_Name__c
,HPSW_MGO_Planned_ESP__c
,HPSW_MGO_Planned_IMG__c
,HPSW_MGO_Planned_ITOM__c
,HPSW_MGO_Planned_Platform__c
,HPSW_MIO_Planned_ADM__c
,HPSW_MIO_Planned_ESP__c
,HPSW_MIO_Planned_IMG__c
,HPSW_MIO_Planned_ITOM__c
,HPSW_MIO_PLANNED_PLATFORM_C__c
,HPSW_ToGo__c
,HPSW_Total_Expected_Pipeline_MGO_MIO__c
,HPSW_Campaign_State__c
,HPSW_Sales_Rep_Campaign_Participation__c
,HPSW_Sales_Target_Customer_Attendance__c
,HPSW_Sales_Total_Target_Pipeline_Build__c
,HPSW_Campaign_Fiscal_Quarter__c
,HPSW_Campaign_Quarter__c
,SWT_Campaign_Activity_Sub_Type__c
,SWT_Program_Type__c
,SWT_Requires_Claim__c
,SWT_Membership_Specialization_Benefit__c
,SWT_Direct_Indirect_Opportunity__c
,SWT_External_Id__c
,SWT_Aprimo_Id__c
,SWT_Marketing_Business_Unit__c
,SWT_Product_Line__c
,HPSW_Pipeline_Source__c
,SWT_Campaign_External_ID__c
,SWT_Final_Approver__c
,SWT_Lead_Generated_Pipeline__c
,SWT_Marketing_Contributed_Pipeline__c
,SWT_Marketing_Influenced_Pipeline__c
,SWT_URL__c
,HPSW_MGO_Planned_ADM__c
,HPSW_Pillar__c
,SWT_Case_Safe_ID__c
,SWT_Fiscal_Year_Date__c
,Campaign_Owner__c
,SWT_Heirarchy_level__c
,Is_PMX__c
,SWT_Parent_Integrated_Campaign__c
,CFCR_Campaign_Business_Unit_Text__c
,CFCR_Count__c
,FCRM__FCR_Campaign_Sourced_By__c
,FCRM__FCR_QR_s__c
,FCRM__FCR_Qualified_Responses_With_Repeats__c
,SWT_All_Child_Budget__c
,SWT_Campaign_Business_Area__c
,SWT_Campaign_CMT_L1__c
,SWT_Campaign_CMT_L2__c
,Language_Availability__c
,SWT_Sales_Initiative_Type__c
,SWT_Total_Budget__c
,Campaign_CMT_L1__c
,CFCR_Exclude_From_Campaign_Influence__c
,CFCR_FCCRM_Campaign_Threshold__c
,FCRM__FCR_Bypass_Nurture_Timeout__c
,FCRM__FCR_Campaign_Notification_Override__c
,FCRM__FCR_Campaign_Precedence__c
,FCRM__FCR_Cascade_Parent_ID__c
,FCRM__FCR_CascadeParent__c
,FCRM__FCR_ClosedOpRevenueModel1__c
,FCRM__FCR_ClosedOpRevenueModel2__c
,FCRM__FCR_ClosedOpRevenueModel3__c
,FCRM__FCR_Cost_Per_Response__c
,FCRM__FCR_Cost_Per_Response_With_Repeats__c
,FCRM__FCR_LostOpRevenueModel1__c
,FCRM__FCR_LostOpRevenueModel2__c
,FCRM__FCR_LostOpRevenueModel3__c
,FCRM__FCR_Marketing_Region__c
,FCRM__FCR_Net_New_Names__c
,FCRM__FCR_Net_New_Response_Ratio__c
,FCRM__FCR_OpenOpRevenueModel1__c
,FCRM__FCR_OpenOpRevenueModel2__c
,FCRM__FCR_OpenOpRevenueModel3__c
,FCRM__FCR_QR_to_Opportunity_Ratio__c
,FCRM__FCR_Repeat_Campaign_Number__c
,FCRM__FCR_Repeat_Response_Timeout_Segments__c
,FCRM__FCR_Repeat_Responses_Allowed__c
,FCRM__FCR_Responses_to_Won__c
,FCRM__FCR_Sales_Information__c
,FCRM__FCR_Total_Responses_With_Repeats__c
,FCRM__FCR_TotalOpRevenueModel1__c
,FCRM__FCR_TotalOpRevenueModel2__c
,FCRM__FCR_TotalOpRevenueModel3__c
,FCRM__ME_Default_Responded_Member_Status__c
,FCRM__ME_Exclude_From_Reactivation__c
,SWT_Post_Event_New_Promoter_Score__c
,SWT_Pre_Event_Net_Promoter_Score__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".SF_Campaign WHERE id in
(SELECT STG.id FROM SF_Campaign_stg_Tmp_Key STG JOIN SF_Campaign_base_Tmp
ON STG.id = SF_Campaign_base_Tmp.id AND STG.LastModifiedDate >= SF_Campaign_base_Tmp.LastModifiedDate);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."SF_Campaign_HIST"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;





/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_Campaign WHERE id in 
(SELECT STG.id FROM SF_Campaign_stg_Tmp_Key STG JOIN SF_Campaign_base_Tmp
ON STG.id = SF_Campaign_base_Tmp.id AND STG.LastModifiedDate >= SF_Campaign_base_Tmp.LastModifiedDate);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_Campaign
(
Id
,IsDeleted
,Name
,ParentId
,Type
,RecordTypeId
,Status
,StartDate
,EndDate
,CurrencyIsoCode
,ExpectedRevenue
,BudgetedCost
,ActualCost
,ExpectedResponse
,NumberSent
,IsActive
,Description
,NumberOfLeads
,NumberOfConvertedLeads
,NumberOfContacts
,NumberOfResponses
,NumberOfOpportunities
,NumberOfWonOpportunities
,AmountAllOpportunities
,AmountWonOpportunities
,HierarchyNumberOfLeads
,HierarchyNumberOfConvertedLeads
,HierarchyNumberOfContacts
,HierarchyNumberOfResponses
,HierarchyNumberOfOpportunities
,HierarchyNumberOfWonOpportunities
,HierarchyAmountAllOpportunities
,HierarchyAmountWonOpportunities
,HierarchyNumberSent
,HierarchyExpectedRevenue
,HierarchyBudgetedCost
,HierarchyActualCost
,OwnerId
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,LastViewedDate
,LastReferencedDate
,CampaignMemberRecordTypeId
,SWT_Expected_Leads__c
,SWT_Landing_Page__c
,SWT_Business_Unit__c
,SWT_Partner_Marketing_Campaign__c
,SWT_Status__c
,SWT_Qualification_Team_Name__c
,SWT_Vertical_Industries__c
,SWT_Marketing_Campaign_Owner__c
,SWT_Marketing_Generated__c
,SWT_Program_Name__c
,SWT_City__c
,SWT_Campaign_Country__c
,SWT_Email_Bouncebacks__c
,SWT_Email_Click_Throughs__c
,SWT_Email_Unsubscribers__c
,SWT_Emails_Opened__c
,SWT_Emails_Sent__c
,SWT_Possible_Email_Forwards__c
,SWT_Unique_Email_Visitors__c
,SWT_Call_Center_Calls__c
,SWT_Forms_Submitted__c
,SWT_Print_Mail_Sends__c
,SWT_Surveys_Completed__c
,SWT_Hypersite_Visits__c
,SWT_Online_Referral_Visits__c
,SWT_Campaign_Search_Visits__c
,SWT_Workgroup__c
,SWT_Funding_Account__c
,SWT_Budget_Type__c
,SWT_GTM_Programs__c
,SWT_Plan_vs_Total_Leads_Received__c
,SWT_Sub_Business_Unit__c
,SWT_Total_Closed_Won_Conversion__c
,SWT_Total_Closed_Won_Conversion_value__c
,SWT_Vendor__c
,SWT_New_Business_Opportunity__c
,SWT_Pipeline_Matrix_Sales_Plays__c
,SWT_Campaign_Name_Formula__c
,SWT_Pillar__c
,SWT_Product_Type__c
,SWT_Benefit_Platinum__c
,SWT_Benefit_Gold__c
,SWT_Benefit_Silver__c
,SWT_Benefit__c
,SWT_Discount_Applied__c
,SWT_Tier_Service_Provider_Applicable__c
,SWT_Stackable__c
,SWT_Exclusions__c
,SWT_Quarter__c
,SWT_Product__c
,SWT_Fiscal_Year__c
,SWT_Sourced__c
,SWT_Industry_vertical__c
,Industry_Segment__c
,SWT_Region__c
,SWT_Campaign_Activity_Type__c
,HPSW_Activity__c
,HPSW_Program_Description__c
,HPSW_Campaign_Kit_Link__c
,HPSW_Total_Generated_Pipeline_MGO_MIO__c
,HPSW_Mktg_Actual_Attendance__c
,HPSW_Audience_Target_Size__c
,HPSW_Campaign_with_Education__c
,HPSW_Campaign_with_Professional_Services__c
,HPSW_MDF_Activity_ID__c
,HPSW_Mktg_Expected_Attendance__c
,HPSW_MGO_Planned_Total__c
,HPSW_Outcome_Summary__c
,HPSW_Campaign_Partners__c
,HPSW_Portfolio__c
,HPSW_Target_Audience_Level__c
,HPSW_Sales_Play__c
,HPSW_Target_Account_Type__c
,HPSW_Tweet_Sheet__c
,HPSW_LinkedIn_FB_Post__c
,HPSW_Promo_URL__c
,HPSW_Twitter_Hastag_1__c
,HPSW_Twitter_Hastag_2__c
,HPSW_Twitter_Hastag_3__c
,HPSW_Reg_link__c
,HPSW_MIO_Planned_Total__c
,HPSW_Campaign_Code_Report_Link__c
,HPSW_ADM_Budget__c
,HPSW_ESP_Budget__c
,HPSW_IMG_Budget__c
,HPSW_ITOM_Budget__c
,HPSW_Platform_Budget__c
,HPSW_Total_Budget__c
,HPSW_Aprimo_Activity_Name__c
,HPSW_Bridgeplan_Activity_Name__c
,HPSW_MGO_Planned_ESP__c
,HPSW_MGO_Planned_IMG__c
,HPSW_MGO_Planned_ITOM__c
,HPSW_MGO_Planned_Platform__c
,HPSW_MIO_Planned_ADM__c
,HPSW_MIO_Planned_ESP__c
,HPSW_MIO_Planned_IMG__c
,HPSW_MIO_Planned_ITOM__c
,HPSW_MIO_PLANNED_PLATFORM_C__c
,HPSW_ToGo__c
,HPSW_Total_Expected_Pipeline_MGO_MIO__c
,HPSW_Campaign_State__c
,HPSW_Sales_Rep_Campaign_Participation__c
,HPSW_Sales_Target_Customer_Attendance__c
,HPSW_Sales_Total_Target_Pipeline_Build__c
,HPSW_Campaign_Fiscal_Quarter__c
,HPSW_Campaign_Quarter__c
,SWT_Campaign_Activity_Sub_Type__c
,SWT_Program_Type__c
,SWT_Requires_Claim__c
,SWT_Membership_Specialization_Benefit__c
,SWT_Direct_Indirect_Opportunity__c
,SWT_External_Id__c
,SWT_Aprimo_Id__c
,SWT_Marketing_Business_Unit__c
,SWT_Product_Line__c
,HPSW_Pipeline_Source__c
,SWT_Campaign_External_ID__c
,SWT_Final_Approver__c
,SWT_Lead_Generated_Pipeline__c
,SWT_Marketing_Contributed_Pipeline__c
,SWT_Marketing_Influenced_Pipeline__c
,SWT_URL__c
,HPSW_MGO_Planned_ADM__c
,HPSW_Pillar__c
,SWT_Case_Safe_ID__c
,SWT_Fiscal_Year_Date__c
,Campaign_Owner__c
,SWT_Heirarchy_level__c
,Is_PMX__c
,SWT_Parent_Integrated_Campaign__c
,CFCR_Campaign_Business_Unit_Text__c
,CFCR_Count__c
,FCRM__FCR_Campaign_Sourced_By__c
,FCRM__FCR_QR_s__c
,FCRM__FCR_Qualified_Responses_With_Repeats__c
,SWT_All_Child_Budget__c
,SWT_Campaign_Business_Area__c
,SWT_Campaign_CMT_L1__c
,SWT_Campaign_CMT_L2__c
,Language_Availability__c
,SWT_Sales_Initiative_Type__c
,SWT_Total_Budget__c
,Campaign_CMT_L1__c
,CFCR_Exclude_From_Campaign_Influence__c
,CFCR_FCCRM_Campaign_Threshold__c
,FCRM__FCR_Bypass_Nurture_Timeout__c
,FCRM__FCR_Campaign_Notification_Override__c
,FCRM__FCR_Campaign_Precedence__c
,FCRM__FCR_Cascade_Parent_ID__c
,FCRM__FCR_CascadeParent__c
,FCRM__FCR_ClosedOpRevenueModel1__c
,FCRM__FCR_ClosedOpRevenueModel2__c
,FCRM__FCR_ClosedOpRevenueModel3__c
,FCRM__FCR_Cost_Per_Response__c
,FCRM__FCR_Cost_Per_Response_With_Repeats__c
,FCRM__FCR_LostOpRevenueModel1__c
,FCRM__FCR_LostOpRevenueModel2__c
,FCRM__FCR_LostOpRevenueModel3__c
,FCRM__FCR_Marketing_Region__c
,FCRM__FCR_Net_New_Names__c
,FCRM__FCR_Net_New_Response_Ratio__c
,FCRM__FCR_OpenOpRevenueModel1__c
,FCRM__FCR_OpenOpRevenueModel2__c
,FCRM__FCR_OpenOpRevenueModel3__c
,FCRM__FCR_QR_to_Opportunity_Ratio__c
,FCRM__FCR_Repeat_Campaign_Number__c
,FCRM__FCR_Repeat_Response_Timeout_Segments__c
,FCRM__FCR_Repeat_Responses_Allowed__c
,FCRM__FCR_Responses_to_Won__c
,FCRM__FCR_Sales_Information__c
,FCRM__FCR_Total_Responses_With_Repeats__c
,FCRM__FCR_TotalOpRevenueModel1__c
,FCRM__FCR_TotalOpRevenueModel2__c
,FCRM__FCR_TotalOpRevenueModel3__c
,FCRM__ME_Default_Responded_Member_Status__c
,FCRM__ME_Exclude_From_Reactivation__c
,SWT_Post_Event_New_Promoter_Score__c
,SWT_Pre_Event_Net_Promoter_Score__c
,SWT_INS_DT
)
SELECT DISTINCT 
SF_Campaign_stg_Tmp.Id
,IsDeleted
,Name
,ParentId
,Type
,RecordTypeId
,Status
,StartDate
,EndDate
,CurrencyIsoCode
,ExpectedRevenue
,BudgetedCost
,ActualCost
,ExpectedResponse
,NumberSent
,IsActive
,Description
,NumberOfLeads
,NumberOfConvertedLeads
,NumberOfContacts
,NumberOfResponses
,NumberOfOpportunities
,NumberOfWonOpportunities
,AmountAllOpportunities
,AmountWonOpportunities
,HierarchyNumberOfLeads
,HierarchyNumberOfConvertedLeads
,HierarchyNumberOfContacts
,HierarchyNumberOfResponses
,HierarchyNumberOfOpportunities
,HierarchyNumberOfWonOpportunities
,HierarchyAmountAllOpportunities
,HierarchyAmountWonOpportunities
,HierarchyNumberSent
,HierarchyExpectedRevenue
,HierarchyBudgetedCost
,HierarchyActualCost
,OwnerId
,CreatedDate
,CreatedById
,SF_Campaign_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,LastViewedDate
,LastReferencedDate
,CampaignMemberRecordTypeId
,SWT_Expected_Leads__c
,SWT_Landing_Page__c
,SWT_Business_Unit__c
,SWT_Partner_Marketing_Campaign__c
,SWT_Status__c
,SWT_Qualification_Team_Name__c
,SWT_Vertical_Industries__c
,SWT_Marketing_Campaign_Owner__c
,SWT_Marketing_Generated__c
,SWT_Program_Name__c
,SWT_City__c
,SWT_Campaign_Country__c
,SWT_Email_Bouncebacks__c
,SWT_Email_Click_Throughs__c
,SWT_Email_Unsubscribers__c
,SWT_Emails_Opened__c
,SWT_Emails_Sent__c
,SWT_Possible_Email_Forwards__c
,SWT_Unique_Email_Visitors__c
,SWT_Call_Center_Calls__c
,SWT_Forms_Submitted__c
,SWT_Print_Mail_Sends__c
,SWT_Surveys_Completed__c
,SWT_Hypersite_Visits__c
,SWT_Online_Referral_Visits__c
,SWT_Campaign_Search_Visits__c
,SWT_Workgroup__c
,SWT_Funding_Account__c
,SWT_Budget_Type__c
,SWT_GTM_Programs__c
,SWT_Plan_vs_Total_Leads_Received__c
,SWT_Sub_Business_Unit__c
,SWT_Total_Closed_Won_Conversion__c
,SWT_Total_Closed_Won_Conversion_value__c
,SWT_Vendor__c
,SWT_New_Business_Opportunity__c
,SWT_Pipeline_Matrix_Sales_Plays__c
,SWT_Campaign_Name_Formula__c
,SWT_Pillar__c
,SWT_Product_Type__c
,SWT_Benefit_Platinum__c
,SWT_Benefit_Gold__c
,SWT_Benefit_Silver__c
,SWT_Benefit__c
,SWT_Discount_Applied__c
,SWT_Tier_Service_Provider_Applicable__c
,SWT_Stackable__c
,SWT_Exclusions__c
,SWT_Quarter__c
,SWT_Product__c
,SWT_Fiscal_Year__c
,SWT_Sourced__c
,SWT_Industry_vertical__c
,Industry_Segment__c
,SWT_Region__c
,SWT_Campaign_Activity_Type__c
,HPSW_Activity__c
,HPSW_Program_Description__c
,HPSW_Campaign_Kit_Link__c
,HPSW_Total_Generated_Pipeline_MGO_MIO__c
,HPSW_Mktg_Actual_Attendance__c
,HPSW_Audience_Target_Size__c
,HPSW_Campaign_with_Education__c
,HPSW_Campaign_with_Professional_Services__c
,HPSW_MDF_Activity_ID__c
,HPSW_Mktg_Expected_Attendance__c
,HPSW_MGO_Planned_Total__c
,HPSW_Outcome_Summary__c
,HPSW_Campaign_Partners__c
,HPSW_Portfolio__c
,HPSW_Target_Audience_Level__c
,HPSW_Sales_Play__c
,HPSW_Target_Account_Type__c
,HPSW_Tweet_Sheet__c
,HPSW_LinkedIn_FB_Post__c
,HPSW_Promo_URL__c
,HPSW_Twitter_Hastag_1__c
,HPSW_Twitter_Hastag_2__c
,HPSW_Twitter_Hastag_3__c
,HPSW_Reg_link__c
,HPSW_MIO_Planned_Total__c
,HPSW_Campaign_Code_Report_Link__c
,HPSW_ADM_Budget__c
,HPSW_ESP_Budget__c
,HPSW_IMG_Budget__c
,HPSW_ITOM_Budget__c
,HPSW_Platform_Budget__c
,HPSW_Total_Budget__c
,HPSW_Aprimo_Activity_Name__c
,HPSW_Bridgeplan_Activity_Name__c
,HPSW_MGO_Planned_ESP__c
,HPSW_MGO_Planned_IMG__c
,HPSW_MGO_Planned_ITOM__c
,HPSW_MGO_Planned_Platform__c
,HPSW_MIO_Planned_ADM__c
,HPSW_MIO_Planned_ESP__c
,HPSW_MIO_Planned_IMG__c
,HPSW_MIO_Planned_ITOM__c
,HPSW_MIO_PLANNED_PLATFORM_C__c
,HPSW_ToGo__c
,HPSW_Total_Expected_Pipeline_MGO_MIO__c
,HPSW_Campaign_State__c
,HPSW_Sales_Rep_Campaign_Participation__c
,HPSW_Sales_Target_Customer_Attendance__c
,HPSW_Sales_Total_Target_Pipeline_Build__c
,HPSW_Campaign_Fiscal_Quarter__c
,HPSW_Campaign_Quarter__c
,SWT_Campaign_Activity_Sub_Type__c
,SWT_Program_Type__c
,SWT_Requires_Claim__c
,SWT_Membership_Specialization_Benefit__c
,SWT_Direct_Indirect_Opportunity__c
,SWT_External_Id__c
,SWT_Aprimo_Id__c
,SWT_Marketing_Business_Unit__c
,SWT_Product_Line__c
,HPSW_Pipeline_Source__c
,SWT_Campaign_External_ID__c
,SWT_Final_Approver__c
,SWT_Lead_Generated_Pipeline__c
,SWT_Marketing_Contributed_Pipeline__c
,SWT_Marketing_Influenced_Pipeline__c
,SWT_URL__c
,HPSW_MGO_Planned_ADM__c
,HPSW_Pillar__c
,SWT_Case_Safe_ID__c
,SWT_Fiscal_Year_Date__c
,Campaign_Owner__c
,SWT_Heirarchy_level__c
,Is_PMX__c
,SWT_Parent_Integrated_Campaign__c
,CFCR_Campaign_Business_Unit_Text__c
,CFCR_Count__c
,FCRM__FCR_Campaign_Sourced_By__c
,FCRM__FCR_QR_s__c
,FCRM__FCR_Qualified_Responses_With_Repeats__c
,SWT_All_Child_Budget__c
,SWT_Campaign_Business_Area__c
,SWT_Campaign_CMT_L1__c
,SWT_Campaign_CMT_L2__c
,Language_Availability__c
,SWT_Sales_Initiative_Type__c
,SWT_Total_Budget__c
,Campaign_CMT_L1__c
,CFCR_Exclude_From_Campaign_Influence__c
,CFCR_FCCRM_Campaign_Threshold__c
,FCRM__FCR_Bypass_Nurture_Timeout__c
,FCRM__FCR_Campaign_Notification_Override__c
,FCRM__FCR_Campaign_Precedence__c
,FCRM__FCR_Cascade_Parent_ID__c
,FCRM__FCR_CascadeParent__c
,FCRM__FCR_ClosedOpRevenueModel1__c
,FCRM__FCR_ClosedOpRevenueModel2__c
,FCRM__FCR_ClosedOpRevenueModel3__c
,FCRM__FCR_Cost_Per_Response__c
,FCRM__FCR_Cost_Per_Response_With_Repeats__c
,FCRM__FCR_LostOpRevenueModel1__c
,FCRM__FCR_LostOpRevenueModel2__c
,FCRM__FCR_LostOpRevenueModel3__c
,FCRM__FCR_Marketing_Region__c
,FCRM__FCR_Net_New_Names__c
,FCRM__FCR_Net_New_Response_Ratio__c
,FCRM__FCR_OpenOpRevenueModel1__c
,FCRM__FCR_OpenOpRevenueModel2__c
,FCRM__FCR_OpenOpRevenueModel3__c
,FCRM__FCR_QR_to_Opportunity_Ratio__c
,FCRM__FCR_Repeat_Campaign_Number__c
,FCRM__FCR_Repeat_Response_Timeout_Segments__c
,FCRM__FCR_Repeat_Responses_Allowed__c
,FCRM__FCR_Responses_to_Won__c
,FCRM__FCR_Sales_Information__c
,FCRM__FCR_Total_Responses_With_Repeats__c
,FCRM__FCR_TotalOpRevenueModel1__c
,FCRM__FCR_TotalOpRevenueModel2__c
,FCRM__FCR_TotalOpRevenueModel3__c
,FCRM__ME_Default_Responded_Member_Status__c
,FCRM__ME_Exclude_From_Reactivation__c
,SWT_Post_Event_New_Promoter_Score__c
,SWT_Pre_Event_Net_Promoter_Score__c
,SYSDATE AS SWT_INS_DT
FROM SF_Campaign_stg_Tmp JOIN SF_Campaign_stg_Tmp_Key ON SF_Campaign_stg_Tmp.id= SF_Campaign_stg_Tmp_Key.id AND SF_Campaign_stg_Tmp.LastModifiedDate=SF_Campaign_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 from "swt_rpt_base".SF_Campaign BASE
WHERE SF_Campaign_stg_Tmp.id = BASE.id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_Campaign' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_Campaign' and  COMPLTN_STAT = 'N');


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
select 'SFDC','SF_Campaign',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.SF_Campaign where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


select do_tm_task('mergeout','swt_rpt_stg.SF_Campaign_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_Campaign');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_Campaign');



