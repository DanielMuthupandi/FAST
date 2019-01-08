/****
****Script Name	  : SF_SWT_Sales_Territory__c.sql
****Description   : Incremental data load for SF_SWT_Sales_Territory__c
****/

/*Setting timing on */
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."SF_SWT_Sales_Territory__c";

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
select 'SFDC','SF_SWT_Sales_Territory__c',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".SF_SWT_Sales_Territory__c_Hist SELECT * from "swt_rpt_stg".SF_SWT_Sales_Territory__c;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_SWT_Sales_Territory__c where id in (
select id from swt_rpt_stg.SF_SWT_Sales_Territory__c group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);


delete from swt_rpt_stg.SF_SWT_Sales_Territory__c where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_SWT_Sales_Territory__c.id=t2.id and swt_rpt_stg.SF_SWT_Sales_Territory__c.auto_id<t2.auto_id);

commit;

CREATE LOCAL TEMP TABLE SF_SWT_Sales_Territory__c_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.SF_SWT_Sales_Territory__c)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.SF_SWT_Sales_Territory__c;

CREATE LOCAL TEMP TABLE SF_SWT_Sales_Territory__c_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,LastModifiedDate FROM swt_rpt_base.SF_SWT_Sales_Territory__c)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_SWT_Sales_Territory__c_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(LastModifiedDate) as LastModifiedDate FROM SF_SWT_Sales_Territory__c_stg_Tmp group by id)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.SF_SWT_Sales_Territory__c_Hist
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
,LastViewedDate
,LastReferencedDate
,SWT_Account_Access__c
,SWT_Active__c
,SWT_Case_Access__c
,SWT_Confidential__c
,SWT_Notes__c
,SWT_Opportunity_Access__c
,SWT_Parent_Sales_Territory__c
,SWT_Parent__c
,SWT_Partner__c
,SWT_Sales_Territory_Name__c
,SWT_Sales_Territory_Short_Name__c
,SWT_Start_Date__c
,SWT_Territory_Country__c
,SWT_Territory_Region__c
,SWT_Territory_ID__c
,SWT_Sales_Territory_Type__c
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
,LastViewedDate
,LastReferencedDate
,SWT_Account_Access__c
,SWT_Active__c
,SWT_Case_Access__c
,SWT_Confidential__c
,SWT_Notes__c
,SWT_Opportunity_Access__c
,SWT_Parent_Sales_Territory__c
,SWT_Parent__c
,SWT_Partner__c
,SWT_Sales_Territory_Name__c
,SWT_Sales_Territory_Short_Name__c
,SWT_Start_Date__c
,SWT_Territory_Country__c
,SWT_Territory_Region__c
,SWT_Territory_ID__c
,SWT_Sales_Territory_Type__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".SF_SWT_Sales_Territory__c WHERE id in
(SELECT STG.id FROM SF_SWT_Sales_Territory__c_stg_Tmp_Key STG JOIN SF_SWT_Sales_Territory__c_base_Tmp
ON STG.id = SF_SWT_Sales_Territory__c_base_Tmp.id AND STG.LastModifiedDate >= SF_SWT_Sales_Territory__c_base_Tmp.LastModifiedDate);

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."SF_SWT_Sales_Territory__c_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_SWT_Sales_Territory__c WHERE id in
(SELECT STG.id FROM SF_SWT_Sales_Territory__c_stg_Tmp_Key STG JOIN SF_SWT_Sales_Territory__c_base_Tmp
ON STG.id = SF_SWT_Sales_Territory__c_base_Tmp.id AND STG.LastModifiedDate >= SF_SWT_Sales_Territory__c_base_Tmp.LastModifiedDate);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_SWT_Sales_Territory__c
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
,LastViewedDate
,LastReferencedDate
,SWT_Account_Access__c
,SWT_Active__c
,SWT_Case_Access__c
,SWT_Confidential__c
,SWT_Notes__c
,SWT_Opportunity_Access__c
,SWT_Parent_Sales_Territory__c
,SWT_Parent__c
,SWT_Partner__c
,SWT_Sales_Territory_Name__c
,SWT_Sales_Territory_Short_Name__c
,SWT_Start_Date__c
,SWT_Territory_Country__c
,SWT_Territory_Region__c
,SWT_Territory_ID__c
,SWT_Sales_Territory_Type__c
,SWT_INS_DT
)
SELECT DISTINCT 
SF_SWT_Sales_Territory__c_stg_Tmp.Id
,OwnerId
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,SF_SWT_Sales_Territory__c_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastViewedDate
,LastReferencedDate
,SWT_Account_Access__c
,SWT_Active__c
,SWT_Case_Access__c
,SWT_Confidential__c
,SWT_Notes__c
,SWT_Opportunity_Access__c
,SWT_Parent_Sales_Territory__c
,SWT_Parent__c
,SWT_Partner__c
,SWT_Sales_Territory_Name__c
,SWT_Sales_Territory_Short_Name__c
,SWT_Start_Date__c
,SWT_Territory_Country__c
,SWT_Territory_Region__c
,SWT_Territory_ID__c
,SWT_Sales_Territory_Type__c
,SYSDATE
FROM SF_SWT_Sales_Territory__c_stg_Tmp JOIN SF_SWT_Sales_Territory__c_stg_Tmp_Key ON SF_SWT_Sales_Territory__c_stg_Tmp.id= SF_SWT_Sales_Territory__c_stg_Tmp_Key.id AND SF_SWT_Sales_Territory__c_stg_Tmp.LastModifiedDate=SF_SWT_Sales_Territory__c_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".SF_SWT_Sales_Territory__c BASE
WHERE SF_SWT_Sales_Territory__c_stg_Tmp.id = BASE.id);

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
select 'SFDC','SF_SWT_Sales_Territory__c',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.SF_SWT_Sales_Territory__c where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

/* Deleting partial audit entry */

/*DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_SWT_Sales_Territory__c' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_SWT_Sales_Territory__c' and  COMPLTN_STAT = 'N');
commit;
*/

select do_tm_task('mergeout','swt_rpt_stg.SF_SWT_Sales_Territory__c_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_SWT_Sales_Territory__c');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_SWT_Sales_Territory__c');



