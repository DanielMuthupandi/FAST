/****
****Script Name	  : SF_UserRole.sql
****Description   : Incremental data load for SF_UserRole
****/

/*Setting timing on */
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."SF_UserRole";

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
select 'SFDC','SF_UserRole',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit; 

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".SF_UserRole_Hist SELECT * from "swt_rpt_stg".SF_UserRole;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_UserRole where id in (
select id from swt_rpt_stg.SF_UserRole group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);


delete from swt_rpt_stg.SF_UserRole where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_UserRole.id=t2.id and swt_rpt_stg.SF_UserRole.auto_id<t2.auto_id);

commit;

CREATE LOCAL TEMP TABLE SF_UserRole_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.SF_UserRole)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.SF_UserRole;

CREATE LOCAL TEMP TABLE SF_UserRole_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,LastModifiedDate FROM swt_rpt_base.SF_UserRole)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_UserRole_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(LastModifiedDate) as LastModifiedDate FROM SF_UserRole_stg_Tmp group by id)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;




/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.SF_UserRole_Hist
(
Id
,Name
,ParentRoleId
,RollupDescription
,OpportunityAccessForAccountOwner
,CaseAccessForAccountOwner
,ContactAccessForAccountOwner
,ForecastUserId
,MayForecastManagerShare
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,DeveloperName
,PortalAccountId
,PortalType
,PortalRole
,PortalAccountOwnerId
,LD_DT
,SWT_INS_DT
,d_source
)
 select 
Id
,Name
,ParentRoleId
,RollupDescription
,OpportunityAccessForAccountOwner
,CaseAccessForAccountOwner
,ContactAccessForAccountOwner
,ForecastUserId
,MayForecastManagerShare
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,DeveloperName
,PortalAccountId
,PortalType
,PortalRole
,PortalAccountOwnerId
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".SF_UserRole WHERE id in
(SELECT STG.id FROM SF_UserRole_stg_Tmp_Key STG JOIN SF_UserRole_base_Tmp
ON STG.id = SF_UserRole_base_Tmp.id AND STG.LastModifiedDate >= SF_UserRole_base_Tmp.LastModifiedDate);

/* Deleting before seven days data from current date in the Historical Table */  

delete /*+DIRECT*/ from "swt_rpt_stg"."SF_UserRole_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


 /* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_UserRole WHERE id in
(SELECT STG.id FROM SF_UserRole_stg_Tmp_Key STG JOIN SF_UserRole_base_Tmp
ON STG.id = SF_UserRole_base_Tmp.id AND STG.LastModifiedDate >= SF_UserRole_base_Tmp.LastModifiedDate);


INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_UserRole
(
Id
,Name
,ParentRoleId
,RollupDescription
,OpportunityAccessForAccountOwner
,CaseAccessForAccountOwner
,ContactAccessForAccountOwner
,ForecastUserId
,MayForecastManagerShare
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,DeveloperName
,PortalAccountId
,PortalType
,PortalRole
,PortalAccountOwnerId
,SWT_INS_DT
)
SELECT DISTINCT 
SF_UserRole_stg_Tmp.Id
,Name
,ParentRoleId
,RollupDescription
,OpportunityAccessForAccountOwner
,CaseAccessForAccountOwner
,ContactAccessForAccountOwner
,ForecastUserId
,MayForecastManagerShare
,SF_UserRole_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,DeveloperName
,PortalAccountId
,PortalType
,PortalRole
,PortalAccountOwnerId
,SYSDATE
FROM SF_UserRole_stg_Tmp JOIN SF_UserRole_stg_Tmp_Key ON SF_UserRole_stg_Tmp.id= SF_UserRole_stg_Tmp_Key.id AND SF_UserRole_stg_Tmp.LastModifiedDate=SF_UserRole_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 from "swt_rpt_base".SF_UserRole BASE
WHERE SF_UserRole_stg_Tmp.id = BASE.id);

/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_UserRole' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_UserRole' and  COMPLTN_STAT = 'N');


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
select 'SFDC','SF_UserRole',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.SF_UserRole where SWT_INS_DT::date = sysdate::date),'Y';

Commit;
    
select do_tm_task('mergeout','swt_rpt_stg.SF_UserRole_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_UserRole');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_UserRole');


