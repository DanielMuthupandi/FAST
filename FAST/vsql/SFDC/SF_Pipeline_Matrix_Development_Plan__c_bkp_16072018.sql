/****
****Script Name   : SF_Pipeline_Matrix_Development_Plan__c.sql
****Description   : Incremental data load for SF_Pipeline_Matrix_Development_Plan__c
****/

/*Setting timing on */
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

--SET SESSION AUTOCOMMIT TO OFF;

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."SF_Pipeline_Matrix_Development_Plan__c";

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
select 'SFDC','SF_Pipeline_Matrix_Development_Plan__c',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+Direct*/ INTO swt_rpt_stg.SF_Pipeline_Matrix_Development_Plan__c_Hist SELECT * from swt_rpt_stg.SF_Pipeline_Matrix_Development_Plan__c;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_Pipeline_Matrix_Development_Plan__c where id in (
select id from swt_rpt_stg.SF_Pipeline_Matrix_Development_Plan__c group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);
delete from swt_rpt_stg.SF_Pipeline_Matrix_Development_Plan__c where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_Pipeline_Matrix_Development_Plan__c.id=t2.id and swt_rpt_stg.SF_Pipeline_Matrix_Development_Plan__c.auto_id<t2.auto_id);

Commit; 


CREATE LOCAL TEMP TABLE SF_Pipeline_Matrix_Development_Plan__c_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.SF_Pipeline_Matrix_Development_Plan__c)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.SF_Pipeline_Matrix_Development_Plan__c;

CREATE LOCAL TEMP TABLE SF_Pipeline_Matrix_Development_Plan__c_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,LastModifiedDate FROM swt_rpt_base.SF_Pipeline_Matrix_Development_Plan__c)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_Pipeline_Matrix_Development_Plan__c_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(LastModifiedDate) as LastModifiedDate FROM SF_Pipeline_Matrix_Development_Plan__c_stg_Tmp group by id)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;

/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.SF_Pipeline_Matrix_Development_Plan__c_Hist
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
,HPSW_Annual_Closed_against_Quota__c
,HPSW_Annual_Qualified_Goal__c
,HPSW_Annual_Sales_Quota__c
,HPSW_Fiscal_Year_Qualified_Total__c
,HPSW_Left_to_go__c
,HPSW_Pipeline_Growth_Factor__c
,HPSW_Q1_Actual_Closed_stage_6__c
,HPSW_Q1_Closed_against_Quota__c
,HPSW_Q1_Gap_to_Qualified_Goal__c
,HPSW_Q1_Linearity__c
,HPSW_Q1_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q1_Qualified_Coverage__c
,HPSW_Q1_Qualified_Goal__c
,HPSW_Q1_Qualified_Stage_3_5__c
,HPSW_Q1_Quota__c
,HPSW_Q2_Actual_Closed_stage_6__c
,HPSW_Q2_Closed_against_Quota__c
,HPSW_Q2_Gap_to_Qualified_Goal__c
,HPSW_Q2_Linearity__c
,HPSW_Q2_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q2_Qualified_Coverage__c
,HPSW_Q2_Qualified_Goal__c
,HPSW_Q2_Qualified_Stage_3_5__c
,HPSW_Q2_Quota__c
,HPSW_Q3_Actual_Closed_stage_6__c
,HPSW_Q3_Closed_against_Quota__c
,HPSW_Q3_Gap_to_Qualified_Goal__c
,HPSW_Q3_Linearity__c
,HPSW_Q3_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q3_Qualified_Coverage__c
,HPSW_Q3_Qualified_Goal__c
,HPSW_Q3_Qualified_Stage_3_5__c
,HPSW_Q3_Quota__c
,HPSW_Q4_Actual_Closed_stage_6__c
,HPSW_Q4_Closed_against_Quota__c
,HPSW_Q4_Gap_to_Qualified_Goal__c
,HPSW_Q4_Linearity__c
,HPSW_Q4_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q4_Qualified_Coverage__c
,HPSW_Q4_Qualified_Goal__c
,HPSW_Q4_Qualified_Stage_3_5__c
,HPSW_Q4_Quota__c
,HPSW_Rep_CMT_L1__c
,HPSW_Rep_CMT_L2__c
,HPSW_Rep_Plan_Fiscal_Year__c
,HPSW_Rep_Region__c
,HPSW_Rep_Role__c
,HPSW_Total_Qualified_Coverage_Ratio__c
,HPSW_of_Plan_to_Goal__c
,HP_Gap_to_Annual_Qualified_Pipeline_Goal__c
,HPSW_Plan_Total_Expected_Pipeline_Build__c
,HPSW_Q1_Campaigns_Target_Pipeline_Build__c
,HPSW_Q2_Campaigns_Target_Pipeline_Build__c
,HPSW_Q3_Campaigns_Target_Pipeline_Build__c
,HPSW_Q4_Campaigns_Target_Pipeline_Build__c
,HPSW_Current_Quarter_Commit__c
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
,HPSW_Annual_Closed_against_Quota__c
,HPSW_Annual_Qualified_Goal__c
,HPSW_Annual_Sales_Quota__c
,HPSW_Fiscal_Year_Qualified_Total__c
,HPSW_Left_to_go__c
,HPSW_Pipeline_Growth_Factor__c
,HPSW_Q1_Actual_Closed_stage_6__c
,HPSW_Q1_Closed_against_Quota__c
,HPSW_Q1_Gap_to_Qualified_Goal__c
,HPSW_Q1_Linearity__c
,HPSW_Q1_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q1_Qualified_Coverage__c
,HPSW_Q1_Qualified_Goal__c
,HPSW_Q1_Qualified_Stage_3_5__c
,HPSW_Q1_Quota__c
,HPSW_Q2_Actual_Closed_stage_6__c
,HPSW_Q2_Closed_against_Quota__c
,HPSW_Q2_Gap_to_Qualified_Goal__c
,HPSW_Q2_Linearity__c
,HPSW_Q2_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q2_Qualified_Coverage__c
,HPSW_Q2_Qualified_Goal__c
,HPSW_Q2_Qualified_Stage_3_5__c
,HPSW_Q2_Quota__c
,HPSW_Q3_Actual_Closed_stage_6__c
,HPSW_Q3_Closed_against_Quota__c
,HPSW_Q3_Gap_to_Qualified_Goal__c
,HPSW_Q3_Linearity__c
,HPSW_Q3_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q3_Qualified_Coverage__c
,HPSW_Q3_Qualified_Goal__c
,HPSW_Q3_Qualified_Stage_3_5__c
,HPSW_Q3_Quota__c
,HPSW_Q4_Actual_Closed_stage_6__c
,HPSW_Q4_Closed_against_Quota__c
,HPSW_Q4_Gap_to_Qualified_Goal__c
,HPSW_Q4_Linearity__c
,HPSW_Q4_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q4_Qualified_Coverage__c
,HPSW_Q4_Qualified_Goal__c
,HPSW_Q4_Qualified_Stage_3_5__c
,HPSW_Q4_Quota__c
,HPSW_Rep_CMT_L1__c
,HPSW_Rep_CMT_L2__c
,HPSW_Rep_Plan_Fiscal_Year__c
,HPSW_Rep_Region__c
,HPSW_Rep_Role__c
,HPSW_Total_Qualified_Coverage_Ratio__c
,HPSW_of_Plan_to_Goal__c
,HP_Gap_to_Annual_Qualified_Pipeline_Goal__c
,HPSW_Plan_Total_Expected_Pipeline_Build__c
,HPSW_Q1_Campaigns_Target_Pipeline_Build__c
,HPSW_Q2_Campaigns_Target_Pipeline_Build__c
,HPSW_Q3_Campaigns_Target_Pipeline_Build__c
,HPSW_Q4_Campaigns_Target_Pipeline_Build__c
,HPSW_Current_Quarter_Commit__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".SF_Pipeline_Matrix_Development_Plan__c WHERE id in
(SELECT STG.id FROM SF_Pipeline_Matrix_Development_Plan__c_stg_Tmp_Key STG JOIN SF_Pipeline_Matrix_Development_Plan__c_base_Tmp
ON STG.id = SF_Pipeline_Matrix_Development_Plan__c_base_Tmp.id AND STG.LastModifiedDate >= SF_Pipeline_Matrix_Development_Plan__c_base_Tmp.LastModifiedDate);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."SF_Pipeline_Matrix_Development_Plan__c_HIST"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_Pipeline_Matrix_Development_Plan__c WHERE id in
(SELECT STG.id FROM SF_Pipeline_Matrix_Development_Plan__c_stg_Tmp_Key STG JOIN SF_Pipeline_Matrix_Development_Plan__c_base_Tmp
ON STG.id = SF_Pipeline_Matrix_Development_Plan__c_base_Tmp.id AND STG.LastModifiedDate >= SF_Pipeline_Matrix_Development_Plan__c_base_Tmp.LastModifiedDate);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_Pipeline_Matrix_Development_Plan__c
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
,HPSW_Annual_Closed_against_Quota__c
,HPSW_Annual_Qualified_Goal__c
,HPSW_Annual_Sales_Quota__c
,HPSW_Fiscal_Year_Qualified_Total__c
,HPSW_Left_to_go__c
,HPSW_Pipeline_Growth_Factor__c
,HPSW_Q1_Actual_Closed_stage_6__c
,HPSW_Q1_Closed_against_Quota__c
,HPSW_Q1_Gap_to_Qualified_Goal__c
,HPSW_Q1_Linearity__c
,HPSW_Q1_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q1_Qualified_Coverage__c
,HPSW_Q1_Qualified_Goal__c
,HPSW_Q1_Qualified_Stage_3_5__c
,HPSW_Q1_Quota__c
,HPSW_Q2_Actual_Closed_stage_6__c
,HPSW_Q2_Closed_against_Quota__c
,HPSW_Q2_Gap_to_Qualified_Goal__c
,HPSW_Q2_Linearity__c
,HPSW_Q2_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q2_Qualified_Coverage__c
,HPSW_Q2_Qualified_Goal__c
,HPSW_Q2_Qualified_Stage_3_5__c
,HPSW_Q2_Quota__c
,HPSW_Q3_Actual_Closed_stage_6__c
,HPSW_Q3_Closed_against_Quota__c
,HPSW_Q3_Gap_to_Qualified_Goal__c
,HPSW_Q3_Linearity__c
,HPSW_Q3_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q3_Qualified_Coverage__c
,HPSW_Q3_Qualified_Goal__c
,HPSW_Q3_Qualified_Stage_3_5__c
,HPSW_Q3_Quota__c
,HPSW_Q4_Actual_Closed_stage_6__c
,HPSW_Q4_Closed_against_Quota__c
,HPSW_Q4_Gap_to_Qualified_Goal__c
,HPSW_Q4_Linearity__c
,HPSW_Q4_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q4_Qualified_Coverage__c
,HPSW_Q4_Qualified_Goal__c
,HPSW_Q4_Qualified_Stage_3_5__c
,HPSW_Q4_Quota__c
,HPSW_Rep_CMT_L1__c
,HPSW_Rep_CMT_L2__c
,HPSW_Rep_Plan_Fiscal_Year__c
,HPSW_Rep_Region__c
,HPSW_Rep_Role__c
,HPSW_Total_Qualified_Coverage_Ratio__c
,HPSW_of_Plan_to_Goal__c
,HP_Gap_to_Annual_Qualified_Pipeline_Goal__c
,HPSW_Plan_Total_Expected_Pipeline_Build__c
,HPSW_Q1_Campaigns_Target_Pipeline_Build__c
,HPSW_Q2_Campaigns_Target_Pipeline_Build__c
,HPSW_Q3_Campaigns_Target_Pipeline_Build__c
,HPSW_Q4_Campaigns_Target_Pipeline_Build__c
,HPSW_Current_Quarter_Commit__c
,SWT_INS_DT
)
SELECT DISTINCT
SF_Pipeline_Matrix_Development_Plan__c_stg_Tmp.Id
,OwnerId
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,SF_Pipeline_Matrix_Development_Plan__c_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,LastViewedDate
,LastReferencedDate
,HPSW_Annual_Closed_against_Quota__c
,HPSW_Annual_Qualified_Goal__c
,HPSW_Annual_Sales_Quota__c
,HPSW_Fiscal_Year_Qualified_Total__c
,HPSW_Left_to_go__c
,HPSW_Pipeline_Growth_Factor__c
,HPSW_Q1_Actual_Closed_stage_6__c
,HPSW_Q1_Closed_against_Quota__c
,HPSW_Q1_Gap_to_Qualified_Goal__c
,HPSW_Q1_Linearity__c
,HPSW_Q1_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q1_Qualified_Coverage__c
,HPSW_Q1_Qualified_Goal__c
,HPSW_Q1_Qualified_Stage_3_5__c
,HPSW_Q1_Quota__c
,HPSW_Q2_Actual_Closed_stage_6__c
,HPSW_Q2_Closed_against_Quota__c
,HPSW_Q2_Gap_to_Qualified_Goal__c
,HPSW_Q2_Linearity__c
,HPSW_Q2_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q2_Qualified_Coverage__c
,HPSW_Q2_Qualified_Goal__c
,HPSW_Q2_Qualified_Stage_3_5__c
,HPSW_Q2_Quota__c
,HPSW_Q3_Actual_Closed_stage_6__c
,HPSW_Q3_Closed_against_Quota__c
,HPSW_Q3_Gap_to_Qualified_Goal__c
,HPSW_Q3_Linearity__c
,HPSW_Q3_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q3_Qualified_Coverage__c
,HPSW_Q3_Qualified_Goal__c
,HPSW_Q3_Qualified_Stage_3_5__c
,HPSW_Q3_Quota__c
,HPSW_Q4_Actual_Closed_stage_6__c
,HPSW_Q4_Closed_against_Quota__c
,HPSW_Q4_Gap_to_Qualified_Goal__c
,HPSW_Q4_Linearity__c
,HPSW_Q4_Open_Early_Pipeline_Stage_1_2__c
,HPSW_Q4_Qualified_Coverage__c
,HPSW_Q4_Qualified_Goal__c
,HPSW_Q4_Qualified_Stage_3_5__c
,HPSW_Q4_Quota__c
,HPSW_Rep_CMT_L1__c
,HPSW_Rep_CMT_L2__c
,HPSW_Rep_Plan_Fiscal_Year__c
,HPSW_Rep_Region__c
,HPSW_Rep_Role__c
,HPSW_Total_Qualified_Coverage_Ratio__c
,HPSW_of_Plan_to_Goal__c
,HP_Gap_to_Annual_Qualified_Pipeline_Goal__c
,HPSW_Plan_Total_Expected_Pipeline_Build__c
,HPSW_Q1_Campaigns_Target_Pipeline_Build__c
,HPSW_Q2_Campaigns_Target_Pipeline_Build__c
,HPSW_Q3_Campaigns_Target_Pipeline_Build__c
,HPSW_Q4_Campaigns_Target_Pipeline_Build__c
,HPSW_Current_Quarter_Commit__c
,SYSDATE AS SWT_INS_DT
FROM SF_Pipeline_Matrix_Development_Plan__c_stg_Tmp JOIN SF_Pipeline_Matrix_Development_Plan__c_stg_Tmp_Key ON SF_Pipeline_Matrix_Development_Plan__c_stg_Tmp.id= SF_Pipeline_Matrix_Development_Plan__c_stg_Tmp_Key.id AND SF_Pipeline_Matrix_Development_Plan__c_stg_Tmp.LastModifiedDate=SF_Pipeline_Matrix_Development_Plan__c_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 from "swt_rpt_base".SF_Pipeline_Matrix_Development_Plan__c BASE
WHERE SF_Pipeline_Matrix_Development_Plan__c_stg_Tmp.id = BASE.id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_Pipeline_Matrix_Development_Plan__c' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_Pipeline_Matrix_Development_Plan__c' and  COMPLTN_STAT = 'N');


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
select 'SFDC','SF_Pipeline_Matrix_Development_Plan__c',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.SF_Pipeline_Matrix_Development_Plan__c where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


select do_tm_task('mergeout','swt_rpt_stg.SF_Pipeline_Matrix_Development_Plan__c_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_Pipeline_Matrix_Development_Plan__c');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_Pipeline_Matrix_Development_Plan__c');

