/****
****Script Name	  : NS_Locations.sql
****Description   : Incremental data load for NS_Locations
****/
/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Locations";

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
select 'NETSUITE','NS_Locations',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Locations_Hist SELECT * from "swt_rpt_stg".NS_Locations;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select location_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Locations where location_id in (
select location_id from swt_rpt_stg.NS_Locations group by location_id,date_last_modified having count(1)>1)
group by location_id);

delete from swt_rpt_stg.NS_Locations where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Locations.location_id=t2.location_id and swt_rpt_stg.NS_Locations.auto_id<t2. auto_id);

COMMIT;

CREATE LOCAL TEMP TABLE NS_Locations_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Locations)
SEGMENTED BY HASH(location_id,date_last_modified) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.NS_Locations;

CREATE LOCAL TEMP TABLE NS_Locations_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT location_id,date_last_modified FROM swt_rpt_base.NS_Locations)
SEGMENTED BY HASH(location_id,date_last_modified) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Locations_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT location_id, max(date_last_modified) as date_last_modified FROM NS_Locations_stg_Tmp group by location_id)
SEGMENTED BY HASH(location_id,date_last_modified) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Locations_Hist
(
address
,address_one
,address_three
,address_two
,addressee
,attention
,city
,country
,date_last_modified
,full_name
,inventory_available
,inventory_available_web_store
,is_include_in_supply_planning
,isinactive
,location_extid
,location_id
,name
,parent_id
,phone
,return_address_one
,return_address_two
,return_city
,return_country
,return_state
,return_zipcode
,returnaddress
,state
,tran_num_prefix
,use_bins
,zipcode
,branch_id
,business_area_id
,cost_center_id
,LD_DT
,SWT_INS_DT
,d_source
)
select
address
,address_one
,address_three
,address_two
,addressee
,attention
,city
,country
,date_last_modified
,full_name
,inventory_available
,inventory_available_web_store
,is_include_in_supply_planning
,isinactive
,location_extid
,location_id
,name
,parent_id
,phone
,return_address_one
,return_address_two
,return_city
,return_country
,return_state
,return_zipcode
,returnaddress
,state
,tran_num_prefix
,use_bins
,zipcode
,branch_id
,business_area_id
,cost_center_id
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Locations WHERE location_id in
(SELECT STG.location_id FROM NS_Locations_stg_Tmp_Key STG JOIN NS_Locations_base_Tmp
ON STG.location_id = NS_Locations_base_Tmp.location_id AND STG.date_last_modified >= NS_Locations_base_Tmp.date_last_modified);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Locations_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Locations WHERE location_id in
(SELECT STG.location_id FROM NS_Locations_stg_Tmp_Key STG JOIN NS_Locations_base_Tmp
ON STG.location_id = NS_Locations_base_Tmp.location_id AND STG.date_last_modified >= NS_Locations_base_Tmp.date_last_modified);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Locations
(
address
,address_one
,address_three
,address_two
,addressee
,attention
,city
,country
,date_last_modified
,full_name
,inventory_available
,inventory_available_web_store
,is_include_in_supply_planning
,isinactive
,location_extid
,location_id
,name
,parent_id
,phone
,return_address_one
,return_address_two
,return_city
,return_country
,return_state
,return_zipcode
,returnaddress
,state
,tran_num_prefix
,use_bins
,zipcode
,branch_id
,business_area_id
,cost_center_id
,SWT_INS_DT
)
SELECT DISTINCT
address
,address_one
,address_three
,address_two
,addressee
,attention
,city
,country
,NS_Locations_stg_Tmp.date_last_modified
,full_name
,inventory_available
,inventory_available_web_store
,is_include_in_supply_planning
,isinactive
,location_extid
,NS_Locations_stg_Tmp.location_id
,name
,parent_id
,phone
,return_address_one
,return_address_two
,return_city
,return_country
,return_state
,return_zipcode
,returnaddress
,state
,tran_num_prefix
,use_bins
,zipcode
,branch_id
,business_area_id
,cost_center_id
,SYSDATE AS SWT_INS_DT
FROM NS_Locations_stg_Tmp JOIN NS_Locations_stg_Tmp_Key ON NS_Locations_stg_Tmp.location_id= NS_Locations_stg_Tmp_Key.location_id AND NS_Locations_stg_Tmp.date_last_modified=NS_Locations_stg_Tmp_Key.date_last_modified
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Locations BASE
WHERE NS_Locations_stg_Tmp.location_id = BASE.location_id);



/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Locations' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Locations' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Locations',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Locations where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


SELECT PURGE_TABLE('swt_rpt_base.NS_Locations');
SELECT PURGE_TABLE('swt_rpt_stg.NS_Locations_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Locations');


