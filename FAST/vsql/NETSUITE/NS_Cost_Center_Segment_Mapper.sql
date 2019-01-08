/*******
*****Script Name	  : NS_Cost_Center_Segment_Mapper.sql
****Description   : Incremental data load for NS_Cost_Center_Segment_Mapper
****/
/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Cost_Center_Segment_Mapper";

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
select 'NETSUITE','NS_Cost_Center_Segment_Mapper',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;


INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Cost_Center_Segment_Mapper_Hist SELECT * from "swt_rpt_stg".NS_Cost_Center_Segment_Mapper;
Commit;


CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select cost_center_segment_mapper_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Cost_Center_Segment_Mapper where cost_center_segment_mapper_id in (
select cost_center_segment_mapper_id from swt_rpt_stg.NS_Cost_Center_Segment_Mapper group by cost_center_segment_mapper_id,last_modified_date having count(1)>1)
group by cost_center_segment_mapper_id);


delete from swt_rpt_stg.NS_Cost_Center_Segment_Mapper  where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Cost_Center_Segment_Mapper.cost_center_segment_mapper_id=t2.cost_center_segment_mapper_id and swt_rpt_stg.NS_Cost_Center_Segment_Mapper.auto_id<t2.auto_id);

commit;

CREATE LOCAL TEMP TABLE NS_Cost_Center_Segment_Mapper_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Cost_Center_Segment_Mapper)
SEGMENTED BY HASH(cost_center_segment_mapper_id,last_modified_date) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.NS_Cost_Center_Segment_Mapper;

CREATE LOCAL TEMP TABLE NS_Cost_Center_Segment_Mapper_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT cost_center_segment_mapper_id,last_modified_date FROM swt_rpt_base.NS_Cost_Center_Segment_Mapper)
SEGMENTED BY HASH(cost_center_segment_mapper_id,last_modified_date) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Cost_Center_Segment_Mapper_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT cost_center_segment_mapper_id, max(last_modified_date) as last_modified_date FROM NS_Cost_Center_Segment_Mapper_stg_Tmp group by cost_center_segment_mapper_id)
SEGMENTED BY HASH(cost_center_segment_mapper_id,last_modified_date) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Cost_Center_Segment_Mapper_Hist
(
business_area_id
,cost_center_segment_mapper_ext
,cost_center_segment_mapper_id
,date_created
,custom_functional_area_id
,custom_profit_center_id
,is_inactive
,last_modified_date
,lcci_id
,legacy_cost_center
,mru_id
,parent_id
,subsidiary_id
,LD_DT
,SWT_INS_DT
,d_source
)
select
business_area_id
,cost_center_segment_mapper_ext
,cost_center_segment_mapper_id
,date_created
,custom_functional_area_id
,custom_profit_center_id
,is_inactive
,last_modified_date
,lcci_id
,legacy_cost_center
,mru_id
,parent_id
,subsidiary_id
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Cost_Center_Segment_Mapper WHERE cost_center_segment_mapper_id in
(SELECT STG.cost_center_segment_mapper_id FROM NS_Cost_Center_Segment_Mapper_stg_Tmp_Key STG JOIN NS_Cost_Center_Segment_Mapper_base_Tmp
ON STG.cost_center_segment_mapper_id = NS_Cost_Center_Segment_Mapper_base_Tmp.cost_center_segment_mapper_id AND STG.last_modified_date >= NS_Cost_Center_Segment_Mapper_base_Tmp.last_modified_date);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Cost_Center_Segment_Mapper_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Cost_Center_Segment_Mapper WHERE cost_center_segment_mapper_id in
(SELECT STG.cost_center_segment_mapper_id FROM NS_Cost_Center_Segment_Mapper_stg_Tmp_Key STG JOIN NS_Cost_Center_Segment_Mapper_base_Tmp
ON STG.cost_center_segment_mapper_id = NS_Cost_Center_Segment_Mapper_base_Tmp.cost_center_segment_mapper_id AND STG.last_modified_date >= NS_Cost_Center_Segment_Mapper_base_Tmp.last_modified_date);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Cost_Center_Segment_Mapper
(
business_area_id
,cost_center_segment_mapper_ext
,cost_center_segment_mapper_id
,date_created
,custom_functional_area_id
,custom_profit_center_id
,is_inactive
,last_modified_date
,lcci_id
,legacy_cost_center
,mru_id
,parent_id
,subsidiary_id
,SWT_INS_DT
)
SELECT DISTINCT 
business_area_id
,cost_center_segment_mapper_ext
,NS_Cost_Center_Segment_Mapper_stg_Tmp.cost_center_segment_mapper_id
,date_created
,custom_functional_area_id
,custom_profit_center_id
,is_inactive
,NS_Cost_Center_Segment_Mapper_stg_Tmp.last_modified_date
,lcci_id
,legacy_cost_center
,mru_id
,parent_id
,subsidiary_id
,SYSDATE AS SWT_INS_DT
FROM NS_Cost_Center_Segment_Mapper_stg_Tmp JOIN NS_Cost_Center_Segment_Mapper_stg_Tmp_Key ON NS_Cost_Center_Segment_Mapper_stg_Tmp.cost_center_segment_mapper_id= NS_Cost_Center_Segment_Mapper_stg_Tmp_Key.cost_center_segment_mapper_id AND NS_Cost_Center_Segment_Mapper_stg_Tmp.last_modified_date=NS_Cost_Center_Segment_Mapper_stg_Tmp_Key.last_modified_date
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Cost_Center_Segment_Mapper BASE
WHERE NS_Cost_Center_Segment_Mapper_stg_Tmp.cost_center_segment_mapper_id = BASE.cost_center_segment_mapper_id);


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Cost_Center_Segment_Mapper' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Cost_Center_Segment_Mapper' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Cost_Center_Segment_Mapper',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Cost_Center_Segment_Mapper where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


SELECT DO_TM_TASK('mergeout',  'swt_rpt_base.NS_Cost_Center_Segment_Mapper');
SELECT DO_TM_TASK('mergeout',  'swt_rpt_stg.NS_Cost_Center_Segment_Mapper_Hist');

select ANALYZE_STATISTICS('swt_rpt_base.NS_Cost_Center_Segment_Mapper');




