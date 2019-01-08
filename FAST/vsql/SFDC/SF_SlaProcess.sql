/****
****Script Name	  : SF_SlaProcess.sql
****Description   : Incremental data load for SF_SlaProcess
****/

/*Setting timing on */
\timing

/* SET SESSION AUTOCOMMIT TO OFF; */

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
select 'SFDC','SF_SlaProcess',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."SF_SlaProcess") ,null,'N';

Commit;


CREATE LOCAL TEMP TABLE SF_SlaProcess_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.SF_SlaProcess)
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_SlaProcess_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,LastModifiedDate FROM swt_rpt_base.SF_SlaProcess)
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_SlaProcess_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(LastModifiedDate) as LastModifiedDate FROM SF_SlaProcess_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.SF_SlaProcess_Hist
(
Id
,Name
,NameNorm
,Description
,IsActive
,VersionNumber
,IsVersionDefault
,VersionNotes
,VersionMaster
,StartDateField
,SobjectType
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,IsDeleted
,BusinessHoursId
,LastViewedDate
,LD_DT
,SWT_INS_DT
,d_source
)
select
Id
,Name
,NameNorm
,Description
,IsActive
,VersionNumber
,IsVersionDefault
,VersionNotes
,VersionMaster
,StartDateField
,SobjectType
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,IsDeleted
,BusinessHoursId
,LastViewedDate
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".SF_SlaProcess WHERE id in
(SELECT STG.id FROM SF_SlaProcess_stg_Tmp_Key STG JOIN SF_SlaProcess_base_Tmp
ON STG.id = SF_SlaProcess_base_Tmp.id AND STG.LastModifiedDate >= SF_SlaProcess_base_Tmp.LastModifiedDate);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."SF_SlaProcess_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_SlaProcess WHERE id in
(SELECT STG.id FROM SF_SlaProcess_stg_Tmp_Key STG JOIN SF_SlaProcess_base_Tmp
ON STG.id = SF_SlaProcess_base_Tmp.id AND STG.LastModifiedDate >= SF_SlaProcess_base_Tmp.LastModifiedDate);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_SlaProcess
(
Id
,Name
,NameNorm
,Description
,IsActive
,VersionNumber
,IsVersionDefault
,VersionNotes
,VersionMaster
,StartDateField
,SobjectType
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,IsDeleted
,BusinessHoursId
,LastViewedDate
,SWT_INS_DT
)
SELECT DISTINCT
SF_SlaProcess_stg_Tmp.Id
,Name
,NameNorm
,Description
,IsActive
,VersionNumber
,IsVersionDefault
,VersionNotes
,VersionMaster
,StartDateField
,SobjectType
,CreatedDate
,CreatedById
,SF_SlaProcess_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,IsDeleted
,BusinessHoursId
,LastViewedDate
,SYSDATE
FROM SF_SlaProcess_stg_Tmp JOIN SF_SlaProcess_stg_Tmp_Key ON SF_SlaProcess_stg_Tmp.Id= SF_SlaProcess_stg_Tmp_Key.Id AND SF_SlaProcess_stg_Tmp.LastModifiedDate=SF_SlaProcess_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".SF_SlaProcess BASE
WHERE SF_SlaProcess_stg_Tmp.Id = BASE.Id);


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_SlaProcess' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_SlaProcess' and  COMPLTN_STAT = 'N');
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
select 'SFDC','SF_SlaProcess',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."SF_SlaProcess") ,(select count(*) from swt_rpt_base.SF_SlaProcess where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


SELECT PURGE_TABLE('swt_rpt_base.SF_SlaProcess');
SELECT PURGE_TABLE('swt_rpt_stg.SF_SlaProcess_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.SF_SlaProcess');
INSERT /*+Direct*/ INTO swt_rpt_stg.SF_SlaProcess_Hist SELECT * from swt_rpt_stg.SF_SlaProcess;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.SF_SlaProcess;
