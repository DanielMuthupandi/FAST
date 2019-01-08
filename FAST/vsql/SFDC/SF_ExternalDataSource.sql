/****
****Script Name   : SF_ExternalDataSource.sql
****Description   : Incremental data load for SF_ExternalDataSource
****/

/*Setting timing on */
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."SF_ExternalDataSource";

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
select 'SFDC','SF_ExternalDataSource',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+Direct*/ INTO swt_rpt_stg.SF_ExternalDataSource_Hist SELECT * from swt_rpt_stg.SF_ExternalDataSource;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_ExternalDataSource where id in (
select id from swt_rpt_stg.SF_ExternalDataSource group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);
delete from swt_rpt_stg.SF_ExternalDataSource where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_ExternalDataSource.id=t2.id and swt_rpt_stg.SF_ExternalDataSource.auto_id<t2.auto_id);

Commit; 

CREATE LOCAL TEMP TABLE SF_ExternalDataSource_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.SF_ExternalDataSource)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.SF_ExternalDataSource;

CREATE LOCAL TEMP TABLE SF_ExternalDataSource_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT ID,LastModifiedDate FROM swt_rpt_base.SF_ExternalDataSource)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_ExternalDataSource_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(LastModifiedDate) as LastModifiedDate FROM SF_ExternalDataSource_stg_Tmp group by id)
SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.SF_ExternalDataSource_Hist
(
Id
,IsDeleted
,DeveloperName
,Language
,MasterLabel
,NamespacePrefix
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,Type
,Endpoint
,Repository
,IsWritable
,PrincipalType
,Protocol
,AuthProviderId
,LargeIconId
,SmallIconId
,CustomConfiguration
,LD_DT
,SWT_INS_DT
,d_source
)
select
Id
,IsDeleted
,DeveloperName
,Language
,MasterLabel
,NamespacePrefix
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,Type
,Endpoint
,Repository
,IsWritable
,PrincipalType
,Protocol
,AuthProviderId
,LargeIconId
,SmallIconId
,CustomConfiguration
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".SF_ExternalDataSource WHERE id in
(SELECT STG.id FROM SF_ExternalDataSource_stg_Tmp_Key STG JOIN SF_ExternalDataSource_base_Tmp
ON STG.id = SF_ExternalDataSource_base_Tmp.id AND STG.LastModifiedDate >= SF_ExternalDataSource_base_Tmp.LastModifiedDate);

/* Deleting before seven days data from current date in the Historical Table */

/*delete /*+DIRECT*/ from "swt_rpt_stg"."SF_ExternalDataSource_HIST"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;*/

/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_ExternalDataSource WHERE id in
(SELECT STG.id FROM SF_ExternalDataSource_stg_Tmp_Key STG JOIN SF_ExternalDataSource_base_Tmp
ON STG.id = SF_ExternalDataSource_base_Tmp.id AND STG.LastModifiedDate >= SF_ExternalDataSource_base_Tmp.LastModifiedDate);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_ExternalDataSource
(
Id
,IsDeleted
,DeveloperName
,Language
,MasterLabel
,NamespacePrefix
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,Type
,Endpoint
,Repository
,IsWritable
,PrincipalType
,Protocol
,AuthProviderId
,LargeIconId
,SmallIconId
,CustomConfiguration
,SWT_INS_DT
)
SELECT DISTINCT 
SF_ExternalDataSource_stg_Tmp.Id
,IsDeleted
,DeveloperName
,Language
,MasterLabel
,NamespacePrefix
,CreatedDate
,CreatedById
,SF_ExternalDataSource_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,Type
,Endpoint
,Repository
,IsWritable
,PrincipalType
,Protocol
,AuthProviderId
,LargeIconId
,SmallIconId
,CustomConfiguration
,SYSDATE AS SWT_INS_DT
FROM SF_ExternalDataSource_stg_Tmp JOIN SF_ExternalDataSource_stg_Tmp_Key ON SF_ExternalDataSource_stg_Tmp.id= SF_ExternalDataSource_stg_Tmp_Key.id AND SF_ExternalDataSource_stg_Tmp.LastModifiedDate=SF_ExternalDataSource_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 from "swt_rpt_base".SF_ExternalDataSource BASE
WHERE SF_ExternalDataSource_stg_Tmp.id = BASE.id);




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
select 'SFDC','SF_ExternalDataSource',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.SF_ExternalDataSource where SWT_INS_DT::date = sysdate::date),'Y';

Commit;
/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_ExternalDataSource' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_ExternalDataSource' and  COMPLTN_STAT = 'N');

commit;
*/

SELECT DROP_PARTITION('swt_rpt_stg.SF_ExternalDataSource_Hist', TIMESTAMPADD(day,-7,getdate())::date);
/*select do_tm_task('mergeout','swt_rpt_stg.SF_ExternalDataSource_Hist');*/
select do_tm_task('mergeout','swt_rpt_base.SF_ExternalDataSource');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_ExternalDataSource');


