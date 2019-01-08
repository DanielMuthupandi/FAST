
/****
****Script Name   : SF_DatedConversionRate.sql
****Description   : Incremental data load for SF_DatedConversionRate
****/

/*Setting timing on */
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."SF_DatedConversionRate";

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
select 'SFDC','SF_DatedConversionRate',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+Direct*/ INTO swt_rpt_stg.SF_DatedConversionRate_Hist SELECT * from swt_rpt_stg.SF_DatedConversionRate;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_DatedConversionRate where id in (
select id from swt_rpt_stg.SF_DatedConversionRate group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);

delete from swt_rpt_stg.SF_DatedConversionRate where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_DatedConversionRate.id=t2.id and swt_rpt_stg.SF_DatedConversionRate.auto_id<t2.auto_id);

commit;

CREATE LOCAL TEMP TABLE SF_DatedConversionRate_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.SF_DatedConversionRate)
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.SF_DatedConversionRate;

CREATE LOCAL TEMP TABLE SF_DatedConversionRate_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,LastModifiedDate FROM swt_rpt_base.SF_DatedConversionRate)
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_DatedConversionRate_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(LastModifiedDate) as LastModifiedDate FROM SF_DatedConversionRate_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.SF_DatedConversionRate_Hist
(
ConversionRate
,CreatedById
,CreatedDate
,Id
,IsoCode
,LastModifiedById
,LastModifiedDate
,NextStartDate
,StartDate
,SystemModstamp
,LD_DT
,SWT_INS_DT
,d_source
)
select
ConversionRate
,CreatedById
,CreatedDate
,Id
,IsoCode
,LastModifiedById
,LastModifiedDate
,NextStartDate
,StartDate
,SystemModstamp
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".SF_DatedConversionRate WHERE id in
(SELECT STG.id FROM SF_DatedConversionRate_stg_Tmp_Key STG JOIN SF_DatedConversionRate_base_Tmp
ON STG.id = SF_DatedConversionRate_base_Tmp.id AND STG.LastModifiedDate >= SF_DatedConversionRate_base_Tmp.LastModifiedDate);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."SF_DatedConversionRate_HIST"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;





/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_DatedConversionRate WHERE id in
(SELECT STG.id FROM SF_DatedConversionRate_stg_Tmp_Key STG JOIN SF_DatedConversionRate_base_Tmp
ON STG.id = SF_DatedConversionRate_base_Tmp.id AND STG.LastModifiedDate >= SF_DatedConversionRate_base_Tmp.LastModifiedDate);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_DatedConversionRate
(
ConversionRate
,CreatedById
,CreatedDate
,Id
,IsoCode
,LastModifiedById
,LastModifiedDate
,NextStartDate
,StartDate
,SystemModstamp
,SWT_INS_DT
)
SELECT DISTINCT 
ConversionRate
,CreatedById
,CreatedDate
,SF_DatedConversionRate_stg_Tmp.Id
,IsoCode
,LastModifiedById
,SF_DatedConversionRate_stg_Tmp.LastModifiedDate
,NextStartDate
,StartDate
,SystemModstamp
,SYSDATE AS SWT_INS_DT
FROM SF_DatedConversionRate_stg_Tmp JOIN SF_DatedConversionRate_stg_Tmp_Key ON SF_DatedConversionRate_stg_Tmp.Id= SF_DatedConversionRate_stg_Tmp_Key.Id AND SF_DatedConversionRate_stg_Tmp.LastModifiedDate=SF_DatedConversionRate_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".SF_DatedConversionRate BASE
WHERE SF_DatedConversionRate_stg_Tmp.Id = BASE.Id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_DatedConversionRate' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_DatedConversionRate' and  COMPLTN_STAT = 'N');


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
select 'SFDC','SF_DatedConversionRate',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.SF_DatedConversionRate where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

select do_tm_task('mergeout','swt_rpt_stg.SF_DatedConversionRate_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_DatedConversionRate');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_DatedConversionRate');


