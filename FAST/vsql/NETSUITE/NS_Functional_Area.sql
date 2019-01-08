/****
****Script Name	  : NS_Functional_Area.sql
****Description   : Incremental data load for NS_Functional_Area
****/

/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO ON;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Functional_Area";

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
select 'NETSUITE','NS_Functional_Area',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Functional_Area_Hist SELECT * from "swt_rpt_stg".NS_Functional_Area;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select functional_area_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Functional_Area where functional_area_id in (
select functional_area_id from swt_rpt_stg.NS_Functional_Area group by functional_area_id,last_modified_date having count(1)>1)
group by functional_area_id);


delete from swt_rpt_stg.NS_Functional_Area where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Functional_Area.functional_area_id=t2.functional_area_id and swt_rpt_stg.NS_Functional_Area.auto_id<t2.auto_id);

commit;

CREATE LOCAL TEMP TABLE NS_Functional_Area_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Functional_Area)
SEGMENTED BY HASH(functional_area_id,last_modified_date) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.NS_Functional_Area;

CREATE LOCAL TEMP TABLE NS_Functional_Area_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT functional_area_id,last_modified_date FROM swt_rpt_base.NS_Functional_Area)
SEGMENTED BY HASH(functional_area_id,last_modified_date) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Functional_Area_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT functional_area_id, max(last_modified_date) as last_modified_date FROM NS_Functional_Area_stg_Tmp group by functional_area_id)
SEGMENTED BY HASH(functional_area_id,last_modified_date) ALL NODES;

/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Functional_Area_Hist
(
date_created
,fa_description
,functional_area_extid
,functional_area_id
,functional_area_name
,is_inactive
,last_modified_date
,fa_hierarchy_level
,parent_id
,LD_DT
,SWT_INS_DT
,d_source
)
select
date_created
,fa_description
,functional_area_extid
,functional_area_id
,functional_area_name
,is_inactive
,last_modified_date
,fa_hierarchy_level
,parent_id
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Functional_Area WHERE functional_area_id in
(SELECT STG.functional_area_id FROM NS_Functional_Area_stg_Tmp_Key STG JOIN NS_Functional_Area_base_Tmp
ON STG.functional_area_id = NS_Functional_Area_base_Tmp.functional_area_id AND STG.last_modified_date >= NS_Functional_Area_base_Tmp.last_modified_date);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Functional_Area_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */


DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Functional_Area WHERE functional_area_id in
(SELECT STG.functional_area_id FROM NS_Functional_Area_stg_Tmp_Key STG JOIN NS_Functional_Area_base_Tmp
ON STG.functional_area_id = NS_Functional_Area_base_Tmp.functional_area_id AND STG.last_modified_date >= NS_Functional_Area_base_Tmp.last_modified_date);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Functional_Area
(
date_created
,fa_description
,functional_area_extid
,functional_area_id
,functional_area_name
,is_inactive
,last_modified_date
,fa_hierarchy_level
,parent_id
,SWT_INS_DT
)
SELECT DISTINCT 
date_created
,fa_description
,functional_area_extid
,NS_Functional_Area_stg_Tmp.functional_area_id
,functional_area_name
,is_inactive
,NS_Functional_Area_stg_Tmp.last_modified_date
,fa_hierarchy_level
,parent_id
,SYSDATE AS SWT_INS_DT
FROM NS_Functional_Area_stg_Tmp JOIN NS_Functional_Area_stg_Tmp_Key ON NS_Functional_Area_stg_Tmp.functional_area_id= NS_Functional_Area_stg_Tmp_Key.functional_area_id AND NS_Functional_Area_stg_Tmp.last_modified_date=NS_Functional_Area_stg_Tmp_Key.last_modified_date
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Functional_Area BASE
WHERE NS_Functional_Area_stg_Tmp.functional_area_id = BASE.functional_area_id);



/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Functional_Area' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Functional_Area' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Functional_Area',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Functional_Area where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


SELECT PURGE_TABLE('swt_rpt_base.NS_Functional_Area');
SELECT PURGE_TABLE('swt_rpt_stg.NS_Functional_Area_Hist');
select ANALYZE_STATISTICS('swt_rpt_base.NS_Functional_Area');


