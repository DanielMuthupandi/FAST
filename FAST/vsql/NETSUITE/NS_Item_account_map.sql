/****
****Script Name	  : NS_Item_account_map.sql
****Description   : Incremental data load for NS_Item_account_map
****/

/* Setting timing on**/
\timing
/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Item_account_map";

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
select 'NETSUITE','NS_Item_account_map',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Item_account_map_Hist SELECT * from "swt_rpt_stg".NS_Item_account_map;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select item_account_map_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Item_account_map where item_account_map_id in (
select item_account_map_id from swt_rpt_stg.NS_Item_account_map group by item_account_map_id,date_last_modified having count(1)>1)
group by item_account_map_id);

delete from swt_rpt_stg.NS_Item_account_map where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Item_account_map.item_account_map_id=t2.item_account_map_id and swt_rpt_stg.NS_Item_account_map.auto_id<t2. auto_id);
COMMIT;

CREATE LOCAL TEMP TABLE NS_Item_account_map_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Item_account_map)
SEGMENTED BY HASH(item_account_map_id,date_last_modified) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.NS_Item_account_map;

CREATE LOCAL TEMP TABLE NS_Item_account_map_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT item_account_map_id,date_last_modified FROM swt_rpt_base.NS_Item_account_map)
SEGMENTED BY HASH(item_account_map_id,date_last_modified) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Item_account_map_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT item_account_map_id, max(date_last_modified) as date_last_modified FROM NS_Item_account_map_stg_Tmp group by item_account_map_id)
SEGMENTED BY HASH(item_account_map_id,date_last_modified) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Item_account_map_Hist
(
accounting_book_id
,class_id
,date_created
,date_effective
,date_end
,date_last_modified
,department_id
,destination_account_id
,form_template_component_id
,form_template_id
,is_class_any
,is_department_any
,is_location_any
,item_account_map_extid
,item_account_map_id
,item_account_type
,location_id
,source_account_id
,subsidiary_id
,LD_DT
,SWT_INS_DT
,d_source
)
select
accounting_book_id
,class_id
,date_created
,date_effective
,date_end
,date_last_modified
,department_id
,destination_account_id
,form_template_component_id
,form_template_id
,is_class_any
,is_department_any
,is_location_any
,item_account_map_extid
,item_account_map_id
,item_account_type
,location_id
,source_account_id
,subsidiary_id
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Item_account_map WHERE item_account_map_id in
(SELECT STG.item_account_map_id FROM NS_Item_account_map_stg_Tmp_Key STG JOIN NS_Item_account_map_base_Tmp
ON STG.item_account_map_id = NS_Item_account_map_base_Tmp.item_account_map_id AND STG.date_last_modified >= NS_Item_account_map_base_Tmp.date_last_modified);




/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Item_account_map_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */


DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Item_account_map WHERE item_account_map_id in
(SELECT STG.item_account_map_id FROM NS_Item_account_map_stg_Tmp_Key STG JOIN NS_Item_account_map_base_Tmp
ON STG.item_account_map_id = NS_Item_account_map_base_Tmp.item_account_map_id AND STG.date_last_modified >= NS_Item_account_map_base_Tmp.date_last_modified);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Item_account_map
(
accounting_book_id
,class_id
,date_created
,date_effective
,date_end
,date_last_modified
,department_id
,destination_account_id
,form_template_component_id
,form_template_id
,is_class_any
,is_department_any
,is_location_any
,item_account_map_extid
,item_account_map_id
,item_account_type
,location_id
,source_account_id
,subsidiary_id
,SWT_INS_DT
)
SELECT DISTINCT
accounting_book_id
,class_id
,date_created
,date_effective
,date_end
,NS_Item_account_map_stg_Tmp.date_last_modified
,department_id
,destination_account_id
,form_template_component_id
,form_template_id
,is_class_any
,is_department_any
,is_location_any
,item_account_map_extid
,NS_Item_account_map_stg_Tmp.item_account_map_id
,item_account_type
,location_id
,source_account_id
,subsidiary_id
,sysdate as SWT_INS_DT
FROM NS_Item_account_map_stg_Tmp JOIN NS_Item_account_map_stg_Tmp_Key ON NS_Item_account_map_stg_Tmp.item_account_map_id= NS_Item_account_map_stg_Tmp_Key.item_account_map_id AND NS_Item_account_map_stg_Tmp.date_last_modified=NS_Item_account_map_stg_Tmp_Key.date_last_modified
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Item_account_map BASE
WHERE NS_Item_account_map_stg_Tmp.item_account_map_id = BASE.item_account_map_id);



/* Deleting partial audit entry */

/*DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Item_account_map' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Item_account_map' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Item_account_map',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Item_account_map where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

SELECT PURGE_TABLE('swt_rpt_base.NS_Item_account_map');
SELECT PURGE_TABLE('swt_rpt_stg.NS_Item_account_map_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Item_account_map');


