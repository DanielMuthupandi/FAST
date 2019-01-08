/***
**** Script Name	  : NS_Custom_Subsidiary_Codes.sql
****Description   : Incremental data load for NS_Custom_Subsidiary_Codes
****/
/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Custom_Subsidiary_Codes";

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
select 'NETSUITE','NS_Custom_Subsidiary_Codes',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Custom_Subsidiary_Codes_Hist SELECT * from "swt_rpt_stg".NS_Custom_Subsidiary_Codes;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select custom_subsidiary_codes_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Custom_Subsidiary_Codes where custom_subsidiary_codes_id in (
select custom_subsidiary_codes_id from swt_rpt_stg.NS_Custom_Subsidiary_Codes group by custom_subsidiary_codes_id,last_modified_date having count(1)>1)
group by custom_subsidiary_codes_id);

delete from swt_rpt_stg.NS_Custom_Subsidiary_Codes where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Custom_Subsidiary_Codes.custom_subsidiary_codes_id=t2.custom_subsidiary_codes_id and swt_rpt_stg.NS_Custom_Subsidiary_Codes.auto_id<t2. auto_id);

COMMIT;

CREATE LOCAL TEMP TABLE NS_Custom_Subsidiary_Codes_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Custom_Subsidiary_Codes)
SEGMENTED BY HASH(custom_subsidiary_codes_id,last_modified_date) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.NS_Custom_Subsidiary_Codes;

CREATE LOCAL TEMP TABLE NS_Custom_Subsidiary_Codes_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT custom_subsidiary_codes_id,last_modified_date FROM swt_rpt_base.NS_Custom_Subsidiary_Codes)
SEGMENTED BY HASH(custom_subsidiary_codes_id,last_modified_date) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Custom_Subsidiary_Codes_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT custom_subsidiary_codes_id, max(last_modified_date) as last_modified_date FROM NS_Custom_Subsidiary_Codes_stg_Tmp group by custom_subsidiary_codes_id)
SEGMENTED BY HASH(custom_subsidiary_codes_id,last_modified_date) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Custom_Subsidiary_Codes_Hist
(
company_code
,date_created
,custom_subsidiary_codes_extid
,custom_subsidiary_codes_id
,is_inactive
,last_modified_date
,parent_id
,region_name_id
,LD_DT
,SWT_INS_DT
,d_source
)
select
company_code
,date_created
,custom_subsidiary_codes_extid
,custom_subsidiary_codes_id
,is_inactive
,last_modified_date
,parent_id
,region_name_id
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Custom_Subsidiary_Codes WHERE custom_subsidiary_codes_id in
(SELECT STG.custom_subsidiary_codes_id FROM NS_Custom_Subsidiary_Codes_stg_Tmp_Key STG JOIN NS_Custom_Subsidiary_Codes_base_Tmp
ON STG.custom_subsidiary_codes_id = NS_Custom_Subsidiary_Codes_base_Tmp.custom_subsidiary_codes_id AND STG.last_modified_date >= NS_Custom_Subsidiary_Codes_base_Tmp.last_modified_date);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Custom_Subsidiary_Codes_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */


DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Custom_Subsidiary_Codes WHERE custom_subsidiary_codes_id in
(SELECT STG.custom_subsidiary_codes_id FROM NS_Custom_Subsidiary_Codes_stg_Tmp_Key STG JOIN NS_Custom_Subsidiary_Codes_base_Tmp
ON STG.custom_subsidiary_codes_id = NS_Custom_Subsidiary_Codes_base_Tmp.custom_subsidiary_codes_id AND STG.last_modified_date >= NS_Custom_Subsidiary_Codes_base_Tmp.last_modified_date);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Custom_Subsidiary_Codes
(
company_code
,date_created
,custom_subsidiary_codes_extid
,custom_subsidiary_codes_id
,is_inactive
,last_modified_date
,parent_id
,region_name_id
,SWT_INS_DT
)
SELECT DISTINCT
company_code
,date_created
,custom_subsidiary_codes_extid
,NS_Custom_Subsidiary_Codes_stg_Tmp.custom_subsidiary_codes_id
,is_inactive
,NS_Custom_Subsidiary_Codes_stg_Tmp.last_modified_date
,parent_id
,region_name_id
,sysdate as SWT_INS_DT
FROM NS_Custom_Subsidiary_Codes_stg_Tmp JOIN NS_Custom_Subsidiary_Codes_stg_Tmp_Key ON NS_Custom_Subsidiary_Codes_stg_Tmp.custom_subsidiary_codes_id= NS_Custom_Subsidiary_Codes_stg_Tmp_Key.custom_subsidiary_codes_id AND NS_Custom_Subsidiary_Codes_stg_Tmp.last_modified_date=NS_Custom_Subsidiary_Codes_stg_Tmp_Key.last_modified_date
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Custom_Subsidiary_Codes BASE
WHERE NS_Custom_Subsidiary_Codes_stg_Tmp.custom_subsidiary_codes_id = BASE.custom_subsidiary_codes_id);



/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Custom_Subsidiary_Codes' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Custom_Subsidiary_Codes' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Custom_Subsidiary_Codes',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Custom_Subsidiary_Codes where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


SELECT PURGE_TABLE('swt_rpt_base.NS_Custom_Subsidiary_Codes');
SELECT PURGE_TABLE('swt_rpt_stg.NS_Custom_Subsidiary_Codes_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Custom_Subsidiary_Codes');



