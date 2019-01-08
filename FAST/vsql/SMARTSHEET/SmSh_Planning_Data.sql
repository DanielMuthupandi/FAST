/****
Scription   : Truncate and data load for SmSh_Planning_Data
****/

/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select sysdate st from dual;

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
select 'SMARTSHEET','SmSh_Planning_Data',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."SmSh_Planning_Data") ,null,'N';

Commit;


 
 /* Full load VSQL script for loading data from Stage to Base */ 
 
TRUNCATE TABLE "swt_rpt_base".SmSh_Planning_Data;
 
 /* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."SmSh_Planning_Data_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SmSh_Planning_Data
(
Created_By
,Created_On
,External_ID_SFDC
,Aprimo_ID__Pivotal_ID
,PMx_Activity_Name__Project_Name
,Campaign_Owner
,Campaign_Business_Unit
,Campaign_Name
,Status
,Description
,Campaign_Activity_Type
,Campaign_Activity_Sub_Type
,Quarter
,Fiscal_Year
,Integrated_Campaign
,Campaign_Summary
,PMx_Activity_Level
,Target_Audience_Level
,Region
,Campaign_Country
,Campaign_City
,Campaign_State
,Ventor
,FY18_Campaign_CMT_L1
,FY18_Campaign_CMT_L2
,Start_Date
,End_Date
,Expected_Leads
,Budgeted_Cost_in_Campaign
,Actual_Costs_in_Campaign
,Budget_Type
,Funding_Account
,Expected_Revenue_in_Campaign
,Estimated_Marketing_Influenced_Pipeline
,Estimated_Lead_Generated_Pipeline
,Landing_Page
,URL
,Campaign_Partners
,MDF_Activity_ID
,Estimated_Marketing_Contributed
,Active
,SubBusiness_Unit
,Is_PMX
,GTM_Programs
,Marketing_Campaign_Owner
,Campaign_Record_Type
,Parent_Campaign
,Leads_in_Campaign
,System
,FY17_Campaign_CMT_L1
,FY17_Campaign_CMT_L2
,Hierarchy_Level
,SFDC_Refresh_Date
,"Primary"
,SWT_INS_DT
)
SELECT DISTINCT
Created_By
,Created_On
,External_ID_SFDC
,Aprimo_ID__Pivotal_ID
,PMx_Activity_Name__Project_Name
,Campaign_Owner
,Campaign_Business_Unit
,Campaign_Name
,Status
,Description
,Campaign_Activity_Type
,Campaign_Activity_Sub_Type
,Quarter
,Fiscal_Year
,Integrated_Campaign
,Campaign_Summary
,PMx_Activity_Level
,Target_Audience_Level
,Region
,Campaign_Country
,Campaign_City
,Campaign_State
,Ventor
,FY18_Campaign_CMT_L1
,FY18_Campaign_CMT_L2
,Start_Date
,End_Date
,Expected_Leads
,Budgeted_Cost_in_Campaign
,Actual_Costs_in_Campaign
,Budget_Type
,Funding_Account
,Expected_Revenue_in_Campaign
,Estimated_Marketing_Influenced_Pipeline
,Estimated_Lead_Generated_Pipeline
,Landing_Page
,URL
,Campaign_Partners
,MDF_Activity_ID
,Estimated_Marketing_Contributed
,Active
,SubBusiness_Unit
,Is_PMX
,GTM_Programs
,Marketing_Campaign_Owner
,Campaign_Record_Type
,Parent_Campaign
,Leads_in_Campaign
,System
,FY17_Campaign_CMT_L1
,FY17_Campaign_CMT_L2
,Hierarchy_Level
,SFDC_Refresh_Date
,"Primary"
,SYSDATE AS SWT_INS_DT
 FROM "swt_rpt_stg"."SmSh_Planning_Data";

/* Deleting partial audit entry */

/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SMARTSHEET' and
TBL_NM = 'SmSh_Planning_Data' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SMARTSHEET' and  TBL_NM = 'SmSh_Planning_Data' and  COMPLTN_STAT = 'N');
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
select 'SMARTSHEET','SmSh_Planning_Data',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."SmSh_Planning_Data") ,(select count(*) from swt_rpt_base.SmSh_Planning_Data where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

INSERT /*+DIRECT*/ INTO swt_rpt_stg.SmSh_Planning_Data_Hist SELECT * FROM swt_rpt_stg.SmSh_Planning_Data;

COMMIT;

TRUNCATE TABLE swt_rpt_stg.SmSh_Planning_Data;

SELECT PURGE_TABLE('swt_rpt_base.SmSh_Planning_Data');
SELECT PURGE_TABLE('swt_rpt_stg.SmSh_Planning_Data_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.SmSh_Planning_Data');




