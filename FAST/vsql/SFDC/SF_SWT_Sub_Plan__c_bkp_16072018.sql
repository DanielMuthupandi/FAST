/****
****Script Name	  : SF_SWT_Sub_Plan__c.sql
****Description   : Incremental data load for SF_SWT_Sub_Plan__c
****/

/*Setting timing on */
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."SF_SWT_Sub_Plan__c";

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
select 'SFDC','SF_SWT_Sub_Plan__c',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".SF_SWT_Sub_Plan__c_Hist SELECT * from "swt_rpt_stg".SF_SWT_Sub_Plan__c;
COMMIT;


CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_SWT_Sub_Plan__c where id in (
select id from swt_rpt_stg.SF_SWT_Sub_Plan__c group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);
delete from swt_rpt_stg.SF_SWT_Sub_Plan__c where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_SWT_Sub_Plan__c.id=t2.id and swt_rpt_stg.SF_SWT_Sub_Plan__c.auto_id<t2.auto_id);

Commit; 



CREATE LOCAL TEMP TABLE SF_SWT_Sub_Plan__c_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.SF_SWT_Sub_Plan__c)
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.SF_SWT_Sub_Plan__c;

CREATE LOCAL TEMP TABLE SF_SWT_Sub_Plan__c_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,LastModifiedDate FROM swt_rpt_base.SF_SWT_Sub_Plan__c)
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_SWT_Sub_Plan__c_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(LastModifiedDate) as LastModifiedDate FROM SF_SWT_Sub_Plan__c_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;

/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.SF_SWT_Sub_Plan__c_Hist
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
,SWT_Business_Unit__c
,SWT_Previous_FY_Actual_FYQ1__c
,SWT_Previous_FY_Actual_FYQ2__c
,SWT_Previous_FY_Actual_FYQ3__c
,SWT_Previous_FY_Actual_FYQ4__c
,SWT_Previous_FY_Actual_FY_Total__c
,SWT_Current_FY_Planned_FYQ1__c
,SWT_Current_FY_Planned_FYQ2__c
,SWT_Current_FY_Planned_FYQ3__c
,SWT_Current_FY_Planned_FYQ4__c
,SWT_Current_FY_Planned_FY_Total__c
,SWT_Current_FY_Actual_FY_Q1__c
,SWT_Current_FY_Actual_FY_Q2__c
,SWT_Current_FY_Actual_FY_Q3__c
,SWT_Current_FY_Actual_FY_Q4__c
,SWT_Current_FY_Actual_FY_Total__c
,SWT_Previous_Year_Claimed_FY_H1__c
,SWT_Previous_Year_Claimed_FY_H2__c
,SWT_Previous_Year_Claimed_FY_Total__c
,SWT_Projected_FY_H1__c
,SWT_Projected_FY_H2__c
,SWT_Projected_FY_Total__c
,SWT_Allocated_FY_H1__c
,SWT_Allocated_FY_H2__c
,SWT_Allocated_FY_Total__c
,SWT_Committed_to_Activities_FY_H1__c
,SWT_Committed_to_Activities_FY_H2__c
,SWT_Committed_to_Activities_FY_Total__c
,SWT_Claimed_FY_H1__c
,SWT_Claimed_FY_H2__c
,SWT_Claimed_FY_Total__c
,SWT_Joint_Business_Plan__c
,SWT_Utilization_Rate_FY_Total__c
,SWT_Utilization_Rate_FY_H2__c
,SWT_Utilization_Rate_FY_H1__c
,SWT_YoY_MDF_Actual_Growth_FY_Total__c
,SWT_YoY_MDF_Actual_Growth_FY_H2__c
,SWT_YoY_MDF_Actual_Growth_FY_H1__c
,SWT_YoY_Projected_Growth_FY_Total__c
,YoY_Projected_Growth_FY_H2__c
,SWT_YoY_Projected_Growth_FY_H1__c
,SWT_Achievement_FY_Total__c
,SWT_Achievement_FY_Q4__c
,SWT_Achievement_FY_Q3__c
,SWT_Achievement_FY_Q2__c
,SWT_Achievement_FY_Q1__c
,SWT_Duplicate_Business_Unit__c
,SWT_Previous_FY_Planned_FYQ1__c
,Previous_FY_Planned_FYQ2__c
,SWT_Previous_FY_Planned_FYQ3__c
,SWT_Previous_FY_Planned_FYQ4__c
,SWT_Previous_FY_Planned_FY_Total__c
,SWT_YoY_Planned_Growth_FYQ1__c
,SWT_YoY_Planned_Growth_FY_Q2__c
,SWT_YoY_Planned_Growth_FY_Q3__c
,SWT_YoY_Planned_Growth_FYQ4__c
,SWT_YoY_Planned_Growth_FY_Total__c
,SWT_YoY_Actual_Growth_FY_Q1__c
,SWT_YoY_Actual_Growth_FY_Q2__c
,SWT_YoY_Actual_Growth_FY_Q3__c
,SWT_YoY_Actual_Growth_FY_Q4__c
,SWT_YoY_Actual_Growth_FY_Total__c
,SWT_ExternalId__c
,SWT_sum_of_Previous_FY_Planned__c
,SWT_sum_of_Previous_FY_Actual__c
,SWT_sum_of_Current_FY_Planned__c
,SWT_sum_of_the_Current_FY_Actual__c
,SWT_Allocated_FY_Total_H1_H2__c
,SWT_Projected_FY_Total_H1_H2__c
,SWT_Committed_to_Activities_FY_Total_For__c
,SWT_Claimed_FY_Total_Formula__c
,SWT_Previous_Year_Claimed_FY_Total_Form__c
,SWT_Partner_Account_Number__c
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
,SWT_Business_Unit__c
,SWT_Previous_FY_Actual_FYQ1__c
,SWT_Previous_FY_Actual_FYQ2__c
,SWT_Previous_FY_Actual_FYQ3__c
,SWT_Previous_FY_Actual_FYQ4__c
,SWT_Previous_FY_Actual_FY_Total__c
,SWT_Current_FY_Planned_FYQ1__c
,SWT_Current_FY_Planned_FYQ2__c
,SWT_Current_FY_Planned_FYQ3__c
,SWT_Current_FY_Planned_FYQ4__c
,SWT_Current_FY_Planned_FY_Total__c
,SWT_Current_FY_Actual_FY_Q1__c
,SWT_Current_FY_Actual_FY_Q2__c
,SWT_Current_FY_Actual_FY_Q3__c
,SWT_Current_FY_Actual_FY_Q4__c
,SWT_Current_FY_Actual_FY_Total__c
,SWT_Previous_Year_Claimed_FY_H1__c
,SWT_Previous_Year_Claimed_FY_H2__c
,SWT_Previous_Year_Claimed_FY_Total__c
,SWT_Projected_FY_H1__c
,SWT_Projected_FY_H2__c
,SWT_Projected_FY_Total__c
,SWT_Allocated_FY_H1__c
,SWT_Allocated_FY_H2__c
,SWT_Allocated_FY_Total__c
,SWT_Committed_to_Activities_FY_H1__c
,SWT_Committed_to_Activities_FY_H2__c
,SWT_Committed_to_Activities_FY_Total__c
,SWT_Claimed_FY_H1__c
,SWT_Claimed_FY_H2__c
,SWT_Claimed_FY_Total__c
,SWT_Joint_Business_Plan__c
,SWT_Utilization_Rate_FY_Total__c
,SWT_Utilization_Rate_FY_H2__c
,SWT_Utilization_Rate_FY_H1__c
,SWT_YoY_MDF_Actual_Growth_FY_Total__c
,SWT_YoY_MDF_Actual_Growth_FY_H2__c
,SWT_YoY_MDF_Actual_Growth_FY_H1__c
,SWT_YoY_Projected_Growth_FY_Total__c
,YoY_Projected_Growth_FY_H2__c
,SWT_YoY_Projected_Growth_FY_H1__c
,SWT_Achievement_FY_Total__c
,SWT_Achievement_FY_Q4__c
,SWT_Achievement_FY_Q3__c
,SWT_Achievement_FY_Q2__c
,SWT_Achievement_FY_Q1__c
,SWT_Duplicate_Business_Unit__c
,SWT_Previous_FY_Planned_FYQ1__c
,Previous_FY_Planned_FYQ2__c
,SWT_Previous_FY_Planned_FYQ3__c
,SWT_Previous_FY_Planned_FYQ4__c
,SWT_Previous_FY_Planned_FY_Total__c
,SWT_YoY_Planned_Growth_FYQ1__c
,SWT_YoY_Planned_Growth_FY_Q2__c
,SWT_YoY_Planned_Growth_FY_Q3__c
,SWT_YoY_Planned_Growth_FYQ4__c
,SWT_YoY_Planned_Growth_FY_Total__c
,SWT_YoY_Actual_Growth_FY_Q1__c
,SWT_YoY_Actual_Growth_FY_Q2__c
,SWT_YoY_Actual_Growth_FY_Q3__c
,SWT_YoY_Actual_Growth_FY_Q4__c
,SWT_YoY_Actual_Growth_FY_Total__c
,SWT_ExternalId__c
,SWT_sum_of_Previous_FY_Planned__c
,SWT_sum_of_Previous_FY_Actual__c
,SWT_sum_of_Current_FY_Planned__c
,SWT_sum_of_the_Current_FY_Actual__c
,SWT_Allocated_FY_Total_H1_H2__c
,SWT_Projected_FY_Total_H1_H2__c
,SWT_Committed_to_Activities_FY_Total_For__c
,SWT_Claimed_FY_Total_Formula__c
,SWT_Previous_Year_Claimed_FY_Total_Form__c
,SWT_Partner_Account_Number__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".SF_SWT_Sub_Plan__c WHERE id in
(SELECT STG.id FROM SF_SWT_Sub_Plan__c_stg_Tmp_Key STG JOIN SF_SWT_Sub_Plan__c_base_Tmp
ON STG.id = SF_SWT_Sub_Plan__c_base_Tmp.id AND STG.LastModifiedDate >= SF_SWT_Sub_Plan__c_base_Tmp.LastModifiedDate);

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."SF_SWT_Sub_Plan__c_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_SWT_Sub_Plan__c WHERE id in
(SELECT STG.id FROM SF_SWT_Sub_Plan__c_stg_Tmp_Key STG JOIN SF_SWT_Sub_Plan__c_base_Tmp
ON STG.id = SF_SWT_Sub_Plan__c_base_Tmp.id AND STG.LastModifiedDate >= SF_SWT_Sub_Plan__c_base_Tmp.LastModifiedDate);


INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_SWT_Sub_Plan__c
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
,SWT_Business_Unit__c
,SWT_Previous_FY_Actual_FYQ1__c
,SWT_Previous_FY_Actual_FYQ2__c
,SWT_Previous_FY_Actual_FYQ3__c
,SWT_Previous_FY_Actual_FYQ4__c
,SWT_Previous_FY_Actual_FY_Total__c
,SWT_Current_FY_Planned_FYQ1__c
,SWT_Current_FY_Planned_FYQ2__c
,SWT_Current_FY_Planned_FYQ3__c
,SWT_Current_FY_Planned_FYQ4__c
,SWT_Current_FY_Planned_FY_Total__c
,SWT_Current_FY_Actual_FY_Q1__c
,SWT_Current_FY_Actual_FY_Q2__c
,SWT_Current_FY_Actual_FY_Q3__c
,SWT_Current_FY_Actual_FY_Q4__c
,SWT_Current_FY_Actual_FY_Total__c
,SWT_Previous_Year_Claimed_FY_H1__c
,SWT_Previous_Year_Claimed_FY_H2__c
,SWT_Previous_Year_Claimed_FY_Total__c
,SWT_Projected_FY_H1__c
,SWT_Projected_FY_H2__c
,SWT_Projected_FY_Total__c
,SWT_Allocated_FY_H1__c
,SWT_Allocated_FY_H2__c
,SWT_Allocated_FY_Total__c
,SWT_Committed_to_Activities_FY_H1__c
,SWT_Committed_to_Activities_FY_H2__c
,SWT_Committed_to_Activities_FY_Total__c
,SWT_Claimed_FY_H1__c
,SWT_Claimed_FY_H2__c
,SWT_Claimed_FY_Total__c
,SWT_Joint_Business_Plan__c
,SWT_Utilization_Rate_FY_Total__c
,SWT_Utilization_Rate_FY_H2__c
,SWT_Utilization_Rate_FY_H1__c
,SWT_YoY_MDF_Actual_Growth_FY_Total__c
,SWT_YoY_MDF_Actual_Growth_FY_H2__c
,SWT_YoY_MDF_Actual_Growth_FY_H1__c
,SWT_YoY_Projected_Growth_FY_Total__c
,YoY_Projected_Growth_FY_H2__c
,SWT_YoY_Projected_Growth_FY_H1__c
,SWT_Achievement_FY_Total__c
,SWT_Achievement_FY_Q4__c
,SWT_Achievement_FY_Q3__c
,SWT_Achievement_FY_Q2__c
,SWT_Achievement_FY_Q1__c
,SWT_Duplicate_Business_Unit__c
,SWT_Previous_FY_Planned_FYQ1__c
,Previous_FY_Planned_FYQ2__c
,SWT_Previous_FY_Planned_FYQ3__c
,SWT_Previous_FY_Planned_FYQ4__c
,SWT_Previous_FY_Planned_FY_Total__c
,SWT_YoY_Planned_Growth_FYQ1__c
,SWT_YoY_Planned_Growth_FY_Q2__c
,SWT_YoY_Planned_Growth_FY_Q3__c
,SWT_YoY_Planned_Growth_FYQ4__c
,SWT_YoY_Planned_Growth_FY_Total__c
,SWT_YoY_Actual_Growth_FY_Q1__c
,SWT_YoY_Actual_Growth_FY_Q2__c
,SWT_YoY_Actual_Growth_FY_Q3__c
,SWT_YoY_Actual_Growth_FY_Q4__c
,SWT_YoY_Actual_Growth_FY_Total__c
,SWT_ExternalId__c
,SWT_sum_of_Previous_FY_Planned__c
,SWT_sum_of_Previous_FY_Actual__c
,SWT_sum_of_Current_FY_Planned__c
,SWT_sum_of_the_Current_FY_Actual__c
,SWT_Allocated_FY_Total_H1_H2__c
,SWT_Projected_FY_Total_H1_H2__c
,SWT_Committed_to_Activities_FY_Total_For__c
,SWT_Claimed_FY_Total_Formula__c
,SWT_Previous_Year_Claimed_FY_Total_Form__c
,SWT_Partner_Account_Number__c
,SWT_INS_DT
)
SELECT DISTINCT
SF_SWT_Sub_Plan__c_stg_Tmp.Id
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,SF_SWT_Sub_Plan__c_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastActivityDate
,SWT_Business_Unit__c
,SWT_Previous_FY_Actual_FYQ1__c
,SWT_Previous_FY_Actual_FYQ2__c
,SWT_Previous_FY_Actual_FYQ3__c
,SWT_Previous_FY_Actual_FYQ4__c
,SWT_Previous_FY_Actual_FY_Total__c
,SWT_Current_FY_Planned_FYQ1__c
,SWT_Current_FY_Planned_FYQ2__c
,SWT_Current_FY_Planned_FYQ3__c
,SWT_Current_FY_Planned_FYQ4__c
,SWT_Current_FY_Planned_FY_Total__c
,SWT_Current_FY_Actual_FY_Q1__c
,SWT_Current_FY_Actual_FY_Q2__c
,SWT_Current_FY_Actual_FY_Q3__c
,SWT_Current_FY_Actual_FY_Q4__c
,SWT_Current_FY_Actual_FY_Total__c
,SWT_Previous_Year_Claimed_FY_H1__c
,SWT_Previous_Year_Claimed_FY_H2__c
,SWT_Previous_Year_Claimed_FY_Total__c
,SWT_Projected_FY_H1__c
,SWT_Projected_FY_H2__c
,SWT_Projected_FY_Total__c
,SWT_Allocated_FY_H1__c
,SWT_Allocated_FY_H2__c
,SWT_Allocated_FY_Total__c
,SWT_Committed_to_Activities_FY_H1__c
,SWT_Committed_to_Activities_FY_H2__c
,SWT_Committed_to_Activities_FY_Total__c
,SWT_Claimed_FY_H1__c
,SWT_Claimed_FY_H2__c
,SWT_Claimed_FY_Total__c
,SWT_Joint_Business_Plan__c
,SWT_Utilization_Rate_FY_Total__c
,SWT_Utilization_Rate_FY_H2__c
,SWT_Utilization_Rate_FY_H1__c
,SWT_YoY_MDF_Actual_Growth_FY_Total__c
,SWT_YoY_MDF_Actual_Growth_FY_H2__c
,SWT_YoY_MDF_Actual_Growth_FY_H1__c
,SWT_YoY_Projected_Growth_FY_Total__c
,YoY_Projected_Growth_FY_H2__c
,SWT_YoY_Projected_Growth_FY_H1__c
,SWT_Achievement_FY_Total__c
,SWT_Achievement_FY_Q4__c
,SWT_Achievement_FY_Q3__c
,SWT_Achievement_FY_Q2__c
,SWT_Achievement_FY_Q1__c
,SWT_Duplicate_Business_Unit__c
,SWT_Previous_FY_Planned_FYQ1__c
,Previous_FY_Planned_FYQ2__c
,SWT_Previous_FY_Planned_FYQ3__c
,SWT_Previous_FY_Planned_FYQ4__c
,SWT_Previous_FY_Planned_FY_Total__c
,SWT_YoY_Planned_Growth_FYQ1__c
,SWT_YoY_Planned_Growth_FY_Q2__c
,SWT_YoY_Planned_Growth_FY_Q3__c
,SWT_YoY_Planned_Growth_FYQ4__c
,SWT_YoY_Planned_Growth_FY_Total__c
,SWT_YoY_Actual_Growth_FY_Q1__c
,SWT_YoY_Actual_Growth_FY_Q2__c
,SWT_YoY_Actual_Growth_FY_Q3__c
,SWT_YoY_Actual_Growth_FY_Q4__c
,SWT_YoY_Actual_Growth_FY_Total__c
,SWT_ExternalId__c
,SWT_sum_of_Previous_FY_Planned__c
,SWT_sum_of_Previous_FY_Actual__c
,SWT_sum_of_Current_FY_Planned__c
,SWT_sum_of_the_Current_FY_Actual__c
,SWT_Allocated_FY_Total_H1_H2__c
,SWT_Projected_FY_Total_H1_H2__c
,SWT_Committed_to_Activities_FY_Total_For__c
,SWT_Claimed_FY_Total_Formula__c
,SWT_Previous_Year_Claimed_FY_Total_Form__c
,SWT_Partner_Account_Number__c
,SYSDATE
FROM SF_SWT_Sub_Plan__c_stg_Tmp JOIN SF_SWT_Sub_Plan__c_stg_Tmp_Key ON SF_SWT_Sub_Plan__c_stg_Tmp.Id= SF_SWT_Sub_Plan__c_stg_Tmp_Key.Id AND SF_SWT_Sub_Plan__c_stg_Tmp.LastModifiedDate=SF_SWT_Sub_Plan__c_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".SF_SWT_Sub_Plan__c BASE
WHERE SF_SWT_Sub_Plan__c_stg_Tmp.Id = BASE.Id);

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_SWT_Sub_Plan__c' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_SWT_Sub_Plan__c' and  COMPLTN_STAT = 'N');


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
select 'SFDC','SF_SWT_Sub_Plan__c',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.SF_SWT_Sub_Plan__c where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


select do_tm_task('mergeout','swt_rpt_stg.SF_SWT_Sub_Plan__c_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_SWT_Sub_Plan__c');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_SWT_Sub_Plan__c');


