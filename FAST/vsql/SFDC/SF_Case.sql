/****
****Script Name   : SF_Case.sql
****Description   : Incremental data load for SF_Case
****/

/*Setting timing on */
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."SF_Case";

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
select 'SFDC','SF_Case',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+Direct*/ INTO swt_rpt_stg.SF_Case_Hist SELECT * from swt_rpt_stg.SF_Case;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_Case where id in (
select id from swt_rpt_stg.SF_Case group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);
delete from swt_rpt_stg.SF_Case where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_Case.id=t2.id and swt_rpt_stg.SF_Case.auto_id<t2.auto_id);

Commit; 

CREATE LOCAL TEMP TABLE SF_Case_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.SF_Case)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.SF_Case;

CREATE LOCAL TEMP TABLE SF_Case_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,LastModifiedDate FROM swt_rpt_base.SF_Case)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_Case_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(LastModifiedDate) as LastModifiedDate FROM SF_Case_stg_Tmp group by id)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.SF_Case_Hist
(
Id
,IsDeleted
,CaseNumber
,ContactId
,AccountId
,EntitlementId
,ParentId
,SuppliedName
,SuppliedEmail
,SuppliedPhone
,SuppliedCompany
,Type
,RecordTypeId
,Reason
,Origin
,Subject
,Priority
,Description
,IsClosed
,ClosedDate
,IsEscalated
,CurrencyIsoCode
,OwnerId
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastViewedDate
,LastReferencedDate
,MilestoneStatus
,SWT_Opportunity_Owner_First_Name__c
,SWT_Application__c
,SWT_OwnerAssignedCase__c
,SWT_Close_Reason__c
,SWT_Opportunity__c
,SWT_User__c
,SWT_Merge_With_Account__c
,SWT_Opportunity_Access__c
,SWT_Due_Date__c
,SWT_Case_Team__c
,SWT_Est_Hours__c
,SWT_Preferred_Engineer__c
,SWT_Est_Start_Date__c
,SWT_Requestor__c
,SWT_User_Role_Type__c
,SWT_Speciality__c
,SWT_Country__c
,SWT_Access_Type__c
,SWT_Record_Type_Name__c
,SWT_Automated_Process_Checked__c
,SWT_Case_Request_Status__c
,SWT_Sales_Ops_Name__c
,SWT_Business_Unit__c
,SWT_Region__c
,SWT_Pillar__c
,SWT_Add_To_Opportunity_Check__c
,SWT_Created_By_User_Email__c
,SWT_On_Behalf_Of__c
,Status
,SWT_Category__c
,SWT_Approved_Bid_Cost__c
,SWT_Presales_WBS_Code__c
,SWT_Primary_WBS_Segment_Code__c
,SWT_Opportunity_Owner__c
,SWT_Opp_Id__c
,SWT_Total_Opp_Value__c
,SWT_Customer_Contact_Name_Email__c
,SWT_Requested_Workshop_Date__c
,SWT_Value_Stream__c
,SWT_Workshop_Category__c
,SWT_Workshop_Name__c
,SWT_Requested_Workshop_Locat_CityState__c
,SWT_Estimated_of_Attendees__c
,SWT_Expected_Workshop_Results_Goals__c
,SWT_Additional_Comments__c
,SWT_Requested_Workshop_Venue__c
,SWT_Related_Opportunity__c
,SWT_CMT_2__c
,SWT_CMT_1__c
,Region_SWT__c
,SWT_Approval_Level__c
,SWT_Client_Principal__c
,SWT_Presales_require_travel_to_Customer__c
,SWT_If_travel_required_City_State__c
,SWT_Customer_SOW_Deadline__c
,SWT_Approved_Bid_Cost_Curr__c
,SWT_Partner_Contact_name__c
,SWT_Partner_Email__c
,SWT_Opportunity_Number__c
,SWT_Contract_Term__c
,SWT_Industry_Code__c
,SWT_Lead_Practice__c
,SWT_Opportunity_Bid_Manager__c
,SWT_Request_Description__c
,SWT_New_Account__c
,SWT_Account_Link__c
,SWT_opportunity_Link__c
,SWT_Partner_Registration__c
,SWT_Terminal_Opportunity__c
,SWT_Termination_Opportunity_Owner__c
,SWT_Opportunity_Owner_Email__c
,ProductId
,ContactPhone
,ContactMobile
,ContactEmail
,ContactFax
,SWT_Account_Name__c
,SWT_Contact_Email__c
,SWT_Contact_Name__c
,SWT_Contact_Phone__c
,SWT_SC_ASSIGNEE_NAME__c
,SWT_SC_CLOSE_TIME__c
,SWT_SC_IMPACT__c
,SWT_SC_INCIDENT_ID__c
,SWT_SC_OPEN_TIME__c
,SWT_SC_OWNER_NAME__c
,SWT_SC_PREFERRED_COMM_METHOD__c
,SWT_SC_PRODUCT_ID__c
,SWT_SC_PRODUCT_NAME__c
,SWT_SC_PRODUCT_VERSION__c
,SWT_SC_PUBLIC_ID__c
,SWT_SC_QCCRs__c
,SWT_SC_QCIMs__c
,SWT_SC_URGENCY__c
,SWT_Unique_Id__c
,SWT_Business_Area__c
,SWT_Product_category__c
,SWT_Account__c
,SWT_Email__c
,SWT_First_Name__c
,SWT_Last_Name__c
,SWT_Phone__c
,SWT_PrimaryState_Province__c
,SWT_Primary_City__c
,SWT_Primary_Country__c
,SWT_Primary_Street__c
,SWT_Primary_Zip__c
,SWT_CreatedfromPartner__c
,SWT_Dart_CASE_externalid__c
,Actual_Implementation_Date__c
,Actual_LOE_Hours__c
,AssetId
,BusinessHoursId
,Current_Behavior__c
,Data_Model_Change_Request_Required__c
,Dependencies__c
,Estimated_LOE_Hours__c
,Expected_Behavior__c
,External_Ticket_Contact_Name_or_Email__c
,External_Ticket_Number__c
,External_Ticket_System__c
,Impacted_Groups__c
,Impacted_Regions__c
,IsClosedOnCreate
,IsStopped
,Justification__c
,Owner_Change_Count__c
,Release_Cycle__c
,Resolution_Summary__c
,Revenue_Impact__c
,Sales_Stage_Upon_Case_Submission__c
,SC_Escalation_Status__c
,SC_Resolution_Code__c
,SFDC_Fields_Involved__c
,SlaExitDate
,SlaStartDate
,SourceId
,StopStartDate
,SWT_ALM_Ticket__c
,SWT_Business_Ops_Contact__c
,SWT_Business_Ops_Function__c
,SWT_Case_Country__c
,SWT_Case_SAID__c
,SWT_Case_Scenario__c
,SWT_Change_Request__c
,SWT_Community_Record_Id__c
,SWT_Country_Formula__c
,SWT_DART_Business_Unit__c
,SWT_Estimated_End_Date__c
,SWT_Opportunity_BidManager__c
,SWT_Order__c
,SWT_Primary_Market_Offering__c
,SWT_Primary_Service_Offering__c
,SWT_Quote_Proposal__c
,SWT_System_Behavior__c
,Target_Implementation_Date__c
,Age__c
,SWT_Parent_Case__c
,SWT_GS_Account__c
,LD_DT
,SWT_INS_DT
,d_source
)
select
Id
,IsDeleted
,CaseNumber
,ContactId
,AccountId
,EntitlementId
,ParentId
,SuppliedName
,SuppliedEmail
,SuppliedPhone
,SuppliedCompany
,Type
,RecordTypeId
,Reason
,Origin
,Subject
,Priority
,Description
,IsClosed
,ClosedDate
,IsEscalated
,CurrencyIsoCode
,OwnerId
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastViewedDate
,LastReferencedDate
,MilestoneStatus
,SWT_Opportunity_Owner_First_Name__c
,SWT_Application__c
,SWT_OwnerAssignedCase__c
,SWT_Close_Reason__c
,SWT_Opportunity__c
,SWT_User__c
,SWT_Merge_With_Account__c
,SWT_Opportunity_Access__c
,SWT_Due_Date__c
,SWT_Case_Team__c
,SWT_Est_Hours__c
,SWT_Preferred_Engineer__c
,SWT_Est_Start_Date__c
,SWT_Requestor__c
,SWT_User_Role_Type__c
,SWT_Speciality__c
,SWT_Country__c
,SWT_Access_Type__c
,SWT_Record_Type_Name__c
,SWT_Automated_Process_Checked__c
,SWT_Case_Request_Status__c
,SWT_Sales_Ops_Name__c
,SWT_Business_Unit__c
,SWT_Region__c
,SWT_Pillar__c
,SWT_Add_To_Opportunity_Check__c
,SWT_Created_By_User_Email__c
,SWT_On_Behalf_Of__c
,Status
,SWT_Category__c
,SWT_Approved_Bid_Cost__c
,SWT_Presales_WBS_Code__c
,SWT_Primary_WBS_Segment_Code__c
,SWT_Opportunity_Owner__c
,SWT_Opp_Id__c
,SWT_Total_Opp_Value__c
,SWT_Customer_Contact_Name_Email__c
,SWT_Requested_Workshop_Date__c
,SWT_Value_Stream__c
,SWT_Workshop_Category__c
,SWT_Workshop_Name__c
,SWT_Requested_Workshop_Locat_CityState__c
,SWT_Estimated_of_Attendees__c
,SWT_Expected_Workshop_Results_Goals__c
,SWT_Additional_Comments__c
,SWT_Requested_Workshop_Venue__c
,SWT_Related_Opportunity__c
,SWT_CMT_2__c
,SWT_CMT_1__c
,Region_SWT__c
,SWT_Approval_Level__c
,SWT_Client_Principal__c
,SWT_Presales_require_travel_to_Customer__c
,SWT_If_travel_required_City_State__c
,SWT_Customer_SOW_Deadline__c
,SWT_Approved_Bid_Cost_Curr__c
,SWT_Partner_Contact_name__c
,SWT_Partner_Email__c
,SWT_Opportunity_Number__c
,SWT_Contract_Term__c
,SWT_Industry_Code__c
,SWT_Lead_Practice__c
,SWT_Opportunity_Bid_Manager__c
,SWT_Request_Description__c
,SWT_New_Account__c
,SWT_Account_Link__c
,SWT_opportunity_Link__c
,SWT_Partner_Registration__c
,SWT_Terminal_Opportunity__c
,SWT_Termination_Opportunity_Owner__c
,SWT_Opportunity_Owner_Email__c
,ProductId
,ContactPhone
,ContactMobile
,ContactEmail
,ContactFax
,SWT_Account_Name__c
,SWT_Contact_Email__c
,SWT_Contact_Name__c
,SWT_Contact_Phone__c
,SWT_SC_ASSIGNEE_NAME__c
,SWT_SC_CLOSE_TIME__c
,SWT_SC_IMPACT__c
,SWT_SC_INCIDENT_ID__c
,SWT_SC_OPEN_TIME__c
,SWT_SC_OWNER_NAME__c
,SWT_SC_PREFERRED_COMM_METHOD__c
,SWT_SC_PRODUCT_ID__c
,SWT_SC_PRODUCT_NAME__c
,SWT_SC_PRODUCT_VERSION__c
,SWT_SC_PUBLIC_ID__c
,SWT_SC_QCCRs__c
,SWT_SC_QCIMs__c
,SWT_SC_URGENCY__c
,SWT_Unique_Id__c
,SWT_Business_Area__c
,SWT_Product_category__c
,SWT_Account__c
,SWT_Email__c
,SWT_First_Name__c
,SWT_Last_Name__c
,SWT_Phone__c
,SWT_PrimaryState_Province__c
,SWT_Primary_City__c
,SWT_Primary_Country__c
,SWT_Primary_Street__c
,SWT_Primary_Zip__c
,SWT_CreatedfromPartner__c
,SWT_Dart_CASE_externalid__c
,Actual_Implementation_Date__c
,Actual_LOE_Hours__c
,AssetId
,BusinessHoursId
,Current_Behavior__c
,Data_Model_Change_Request_Required__c
,Dependencies__c
,Estimated_LOE_Hours__c
,Expected_Behavior__c
,External_Ticket_Contact_Name_or_Email__c
,External_Ticket_Number__c
,External_Ticket_System__c
,Impacted_Groups__c
,Impacted_Regions__c
,IsClosedOnCreate
,IsStopped
,Justification__c
,Owner_Change_Count__c
,Release_Cycle__c
,Resolution_Summary__c
,Revenue_Impact__c
,Sales_Stage_Upon_Case_Submission__c
,SC_Escalation_Status__c
,SC_Resolution_Code__c
,SFDC_Fields_Involved__c
,SlaExitDate
,SlaStartDate
,SourceId
,StopStartDate
,SWT_ALM_Ticket__c
,SWT_Business_Ops_Contact__c
,SWT_Business_Ops_Function__c
,SWT_Case_Country__c
,SWT_Case_SAID__c
,SWT_Case_Scenario__c
,SWT_Change_Request__c
,SWT_Community_Record_Id__c
,SWT_Country_Formula__c
,SWT_DART_Business_Unit__c
,SWT_Estimated_End_Date__c
,SWT_Opportunity_BidManager__c
,SWT_Order__c
,SWT_Primary_Market_Offering__c
,SWT_Primary_Service_Offering__c
,SWT_Quote_Proposal__c
,SWT_System_Behavior__c
,Target_Implementation_Date__c
,Age__c
,SWT_Parent_Case__c
,SWT_GS_Account__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".SF_Case WHERE id in
(SELECT STG.id FROM SF_Case_stg_Tmp_Key STG JOIN SF_Case_base_Tmp
ON STG.id = SF_Case_base_Tmp.id AND STG.LastModifiedDate >= SF_Case_base_Tmp.LastModifiedDate);

/* Deleting before seven days data from current date in the Historical Table */

/*delete /*+DIRECT*/ from "swt_rpt_stg"."SF_Case_HIST"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date; */


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_Case WHERE id in
(SELECT STG.id FROM SF_Case_stg_Tmp_Key STG JOIN SF_Case_base_Tmp
ON STG.id = SF_Case_base_Tmp.id AND STG.LastModifiedDate >= SF_Case_base_Tmp.LastModifiedDate);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_Case
(
Id
,IsDeleted
,CaseNumber
,ContactId
,AccountId
,EntitlementId
,ParentId
,SuppliedName
,SuppliedEmail
,SuppliedPhone
,SuppliedCompany
,Type
,RecordTypeId
,Reason
,Origin
,Subject
,Priority
,Description
,IsClosed
,ClosedDate
,IsEscalated
,CurrencyIsoCode
,OwnerId
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastViewedDate
,LastReferencedDate
,MilestoneStatus
,SWT_Opportunity_Owner_First_Name__c
,SWT_Application__c
,SWT_OwnerAssignedCase__c
,SWT_Close_Reason__c
,SWT_Opportunity__c
,SWT_User__c
,SWT_Merge_With_Account__c
,SWT_Opportunity_Access__c
,SWT_Due_Date__c
,SWT_Case_Team__c
,SWT_Est_Hours__c
,SWT_Preferred_Engineer__c
,SWT_Est_Start_Date__c
,SWT_Requestor__c
,SWT_User_Role_Type__c
,SWT_Speciality__c
,SWT_Country__c
,SWT_Access_Type__c
,SWT_Record_Type_Name__c
,SWT_Automated_Process_Checked__c
,SWT_Case_Request_Status__c
,SWT_Sales_Ops_Name__c
,SWT_Business_Unit__c
,SWT_Region__c
,SWT_Pillar__c
,SWT_Add_To_Opportunity_Check__c
,SWT_Created_By_User_Email__c
,SWT_On_Behalf_Of__c
,Status
,SWT_Category__c
,SWT_Approved_Bid_Cost__c
,SWT_Presales_WBS_Code__c
,SWT_Primary_WBS_Segment_Code__c
,SWT_Opportunity_Owner__c
,SWT_Opp_Id__c
,SWT_Total_Opp_Value__c
,SWT_Customer_Contact_Name_Email__c
,SWT_Requested_Workshop_Date__c
,SWT_Value_Stream__c
,SWT_Workshop_Category__c
,SWT_Workshop_Name__c
,SWT_Requested_Workshop_Locat_CityState__c
,SWT_Estimated_of_Attendees__c
,SWT_Expected_Workshop_Results_Goals__c
,SWT_Additional_Comments__c
,SWT_Requested_Workshop_Venue__c
,SWT_Related_Opportunity__c
,SWT_CMT_2__c
,SWT_CMT_1__c
,Region_SWT__c
,SWT_Approval_Level__c
,SWT_Client_Principal__c
,SWT_Presales_require_travel_to_Customer__c
,SWT_If_travel_required_City_State__c
,SWT_Customer_SOW_Deadline__c
,SWT_Approved_Bid_Cost_Curr__c
,SWT_Partner_Contact_name__c
,SWT_Partner_Email__c
,SWT_Opportunity_Number__c
,SWT_Contract_Term__c
,SWT_Industry_Code__c
,SWT_Lead_Practice__c
,SWT_Opportunity_Bid_Manager__c
,SWT_Request_Description__c
,SWT_New_Account__c
,SWT_Account_Link__c
,SWT_opportunity_Link__c
,SWT_Partner_Registration__c
,SWT_Terminal_Opportunity__c
,SWT_Termination_Opportunity_Owner__c
,SWT_Opportunity_Owner_Email__c
,ProductId
,ContactPhone
,ContactMobile
,ContactEmail
,ContactFax
,SWT_Account_Name__c
,SWT_Contact_Email__c
,SWT_Contact_Name__c
,SWT_Contact_Phone__c
,SWT_SC_ASSIGNEE_NAME__c
,SWT_SC_CLOSE_TIME__c
,SWT_SC_IMPACT__c
,SWT_SC_INCIDENT_ID__c
,SWT_SC_OPEN_TIME__c
,SWT_SC_OWNER_NAME__c
,SWT_SC_PREFERRED_COMM_METHOD__c
,SWT_SC_PRODUCT_ID__c
,SWT_SC_PRODUCT_NAME__c
,SWT_SC_PRODUCT_VERSION__c
,SWT_SC_PUBLIC_ID__c
,SWT_SC_QCCRs__c
,SWT_SC_QCIMs__c
,SWT_SC_URGENCY__c
,SWT_Unique_Id__c
,SWT_Business_Area__c
,SWT_Product_category__c
,SWT_Account__c
,SWT_Email__c
,SWT_First_Name__c
,SWT_Last_Name__c
,SWT_Phone__c
,SWT_PrimaryState_Province__c
,SWT_Primary_City__c
,SWT_Primary_Country__c
,SWT_Primary_Street__c
,SWT_Primary_Zip__c
,SWT_CreatedfromPartner__c
,SWT_Dart_CASE_externalid__c
,Actual_Implementation_Date__c
,Actual_LOE_Hours__c
,AssetId
,BusinessHoursId
,Current_Behavior__c
,Data_Model_Change_Request_Required__c
,Dependencies__c
,Estimated_LOE_Hours__c
,Expected_Behavior__c
,External_Ticket_Contact_Name_or_Email__c
,External_Ticket_Number__c
,External_Ticket_System__c
,Impacted_Groups__c
,Impacted_Regions__c
,IsClosedOnCreate
,IsStopped
,Justification__c
,Owner_Change_Count__c
,Release_Cycle__c
,Resolution_Summary__c
,Revenue_Impact__c
,Sales_Stage_Upon_Case_Submission__c
,SC_Escalation_Status__c
,SC_Resolution_Code__c
,SFDC_Fields_Involved__c
,SlaExitDate
,SlaStartDate
,SourceId
,StopStartDate
,SWT_ALM_Ticket__c
,SWT_Business_Ops_Contact__c
,SWT_Business_Ops_Function__c
,SWT_Case_Country__c
,SWT_Case_SAID__c
,SWT_Case_Scenario__c
,SWT_Change_Request__c
,SWT_Community_Record_Id__c
,SWT_Country_Formula__c
,SWT_DART_Business_Unit__c
,SWT_Estimated_End_Date__c
,SWT_Opportunity_BidManager__c
,SWT_Order__c
,SWT_Primary_Market_Offering__c
,SWT_Primary_Service_Offering__c
,SWT_Quote_Proposal__c
,SWT_System_Behavior__c
,Target_Implementation_Date__c
,Age__c
,SWT_Parent_Case__c
,SWT_GS_Account__c
,SWT_INS_DT
)
SELECT DISTINCT
SF_Case_stg_Tmp.Id
,IsDeleted
,CaseNumber
,ContactId
,AccountId
,EntitlementId
,ParentId
,SuppliedName
,SuppliedEmail
,SuppliedPhone
,SuppliedCompany
,Type
,RecordTypeId
,Reason
,Origin
,Subject
,Priority
,Description
,IsClosed
,ClosedDate
,IsEscalated
,CurrencyIsoCode
,OwnerId
,CreatedDate
,CreatedById
,SF_Case_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastViewedDate
,LastReferencedDate
,MilestoneStatus
,SWT_Opportunity_Owner_First_Name__c
,SWT_Application__c
,SWT_OwnerAssignedCase__c
,SWT_Close_Reason__c
,SWT_Opportunity__c
,SWT_User__c
,SWT_Merge_With_Account__c
,SWT_Opportunity_Access__c
,SWT_Due_Date__c
,SWT_Case_Team__c
,SWT_Est_Hours__c
,SWT_Preferred_Engineer__c
,SWT_Est_Start_Date__c
,SWT_Requestor__c
,SWT_User_Role_Type__c
,SWT_Speciality__c
,SWT_Country__c
,SWT_Access_Type__c
,SWT_Record_Type_Name__c
,SWT_Automated_Process_Checked__c
,SWT_Case_Request_Status__c
,SWT_Sales_Ops_Name__c
,SWT_Business_Unit__c
,SWT_Region__c
,SWT_Pillar__c
,SWT_Add_To_Opportunity_Check__c
,SWT_Created_By_User_Email__c
,SWT_On_Behalf_Of__c
,Status
,SWT_Category__c
,SWT_Approved_Bid_Cost__c
,SWT_Presales_WBS_Code__c
,SWT_Primary_WBS_Segment_Code__c
,SWT_Opportunity_Owner__c
,SWT_Opp_Id__c
,SWT_Total_Opp_Value__c
,SWT_Customer_Contact_Name_Email__c
,SWT_Requested_Workshop_Date__c
,SWT_Value_Stream__c
,SWT_Workshop_Category__c
,SWT_Workshop_Name__c
,SWT_Requested_Workshop_Locat_CityState__c
,SWT_Estimated_of_Attendees__c
,SWT_Expected_Workshop_Results_Goals__c
,SWT_Additional_Comments__c
,SWT_Requested_Workshop_Venue__c
,SWT_Related_Opportunity__c
,SWT_CMT_2__c
,SWT_CMT_1__c
,Region_SWT__c
,SWT_Approval_Level__c
,SWT_Client_Principal__c
,SWT_Presales_require_travel_to_Customer__c
,SWT_If_travel_required_City_State__c
,SWT_Customer_SOW_Deadline__c
,SWT_Approved_Bid_Cost_Curr__c
,SWT_Partner_Contact_name__c
,SWT_Partner_Email__c
,SWT_Opportunity_Number__c
,SWT_Contract_Term__c
,SWT_Industry_Code__c
,SWT_Lead_Practice__c
,SWT_Opportunity_Bid_Manager__c
,SWT_Request_Description__c
,SWT_New_Account__c
,SWT_Account_Link__c
,SWT_opportunity_Link__c
,SWT_Partner_Registration__c
,SWT_Terminal_Opportunity__c
,SWT_Termination_Opportunity_Owner__c
,SWT_Opportunity_Owner_Email__c
,ProductId
,ContactPhone
,ContactMobile
,ContactEmail
,ContactFax
,SWT_Account_Name__c
,SWT_Contact_Email__c
,SWT_Contact_Name__c
,SWT_Contact_Phone__c
,SWT_SC_ASSIGNEE_NAME__c
,SWT_SC_CLOSE_TIME__c
,SWT_SC_IMPACT__c
,SWT_SC_INCIDENT_ID__c
,SWT_SC_OPEN_TIME__c
,SWT_SC_OWNER_NAME__c
,SWT_SC_PREFERRED_COMM_METHOD__c
,SWT_SC_PRODUCT_ID__c
,SWT_SC_PRODUCT_NAME__c
,SWT_SC_PRODUCT_VERSION__c
,SWT_SC_PUBLIC_ID__c
,SWT_SC_QCCRs__c
,SWT_SC_QCIMs__c
,SWT_SC_URGENCY__c
,SWT_Unique_Id__c
,SWT_Business_Area__c
,SWT_Product_category__c
,SWT_Account__c
,SWT_Email__c
,SWT_First_Name__c
,SWT_Last_Name__c
,SWT_Phone__c
,SWT_PrimaryState_Province__c
,SWT_Primary_City__c
,SWT_Primary_Country__c
,SWT_Primary_Street__c
,SWT_Primary_Zip__c
,SWT_CreatedfromPartner__c
,SWT_Dart_CASE_externalid__c
,Actual_Implementation_Date__c
,Actual_LOE_Hours__c
,AssetId
,BusinessHoursId
,Current_Behavior__c
,Data_Model_Change_Request_Required__c
,Dependencies__c
,Estimated_LOE_Hours__c
,Expected_Behavior__c
,External_Ticket_Contact_Name_or_Email__c
,External_Ticket_Number__c
,External_Ticket_System__c
,Impacted_Groups__c
,Impacted_Regions__c
,IsClosedOnCreate
,IsStopped
,Justification__c
,Owner_Change_Count__c
,Release_Cycle__c
,Resolution_Summary__c
,Revenue_Impact__c
,Sales_Stage_Upon_Case_Submission__c
,SC_Escalation_Status__c
,SC_Resolution_Code__c
,SFDC_Fields_Involved__c
,SlaExitDate
,SlaStartDate
,SourceId
,StopStartDate
,SWT_ALM_Ticket__c
,SWT_Business_Ops_Contact__c
,SWT_Business_Ops_Function__c
,SWT_Case_Country__c
,SWT_Case_SAID__c
,SWT_Case_Scenario__c
,SWT_Change_Request__c
,SWT_Community_Record_Id__c
,SWT_Country_Formula__c
,SWT_DART_Business_Unit__c
,SWT_Estimated_End_Date__c
,SWT_Opportunity_BidManager__c
,SWT_Order__c
,SWT_Primary_Market_Offering__c
,SWT_Primary_Service_Offering__c
,SWT_Quote_Proposal__c
,SWT_System_Behavior__c
,Target_Implementation_Date__c
,Age__c
,SWT_Parent_Case__c
,SWT_GS_Account__c
,SYSDATE AS SWT_INS_DT
FROM SF_Case_stg_Tmp JOIN SF_Case_stg_Tmp_Key ON SF_Case_stg_Tmp.id= SF_Case_stg_Tmp_Key.id AND SF_Case_stg_Tmp.LastModifiedDate=SF_Case_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 from "swt_rpt_base".SF_Case BASE
WHERE SF_Case_stg_Tmp.id = BASE.id);




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
select 'SFDC','SF_Case',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.SF_Case where SWT_INS_DT::date = sysdate::date),'Y';

Commit;
/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_Case' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_Case' and  COMPLTN_STAT = 'N');

commit;
*/

SELECT DROP_PARTITION('swt_rpt_stg.SF_Case_Hist', TIMESTAMPADD(day,-7,getdate())::date);
/*select do_tm_task('mergeout','swt_rpt_stg.SF_Case_Hist');*/
select do_tm_task('mergeout','swt_rpt_base.SF_Case');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.SF_Case');




