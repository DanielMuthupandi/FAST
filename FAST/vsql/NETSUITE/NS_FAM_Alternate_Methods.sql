/****
****Script Name	  : NS_FAM_Alternate_Methods.sql
****Description   : Incremental data load for NS_FAM_Alternate_Methods
****/


/* Setting timing on**/
\timing
/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_FAM_Alternate_Methods";

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
select 'NETSUITE','NS_FAM_Alternate_Methods',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_FAM_Alternate_Methods_Hist SELECT * from "swt_rpt_stg".NS_FAM_Alternate_Methods;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select fam_alternate_methods_id,max(auto_id) as auto_id from swt_rpt_stg.NS_FAM_Alternate_Methods where fam_alternate_methods_id in (
select fam_alternate_methods_id from swt_rpt_stg.NS_FAM_Alternate_Methods group by fam_alternate_methods_id,last_modified_date having count(1)>1)
group by fam_alternate_methods_id);

delete from swt_rpt_stg.NS_FAM_Alternate_Methods where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_FAM_Alternate_Methods.fam_alternate_methods_id=t2.fam_alternate_methods_id and swt_rpt_stg.NS_FAM_Alternate_Methods.auto_id<t2. auto_id);

COMMIT; 

CREATE LOCAL TEMP TABLE NS_FAM_Alternate_Methods_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_FAM_Alternate_Methods)
SEGMENTED BY HASH(fam_alternate_methods_id ,last_modified_date) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.NS_FAM_Alternate_Methods;

CREATE LOCAL TEMP TABLE NS_FAM_Alternate_Methods_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT fam_alternate_methods_id ,last_modified_date FROM swt_rpt_base.NS_FAM_Alternate_Methods)
SEGMENTED BY HASH(fam_alternate_methods_id ,last_modified_date) ALL NODES;


CREATE LOCAL TEMP TABLE NS_FAM_Alternate_Methods_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT fam_alternate_methods_id , max(last_modified_date) as last_modified_date FROM NS_FAM_Alternate_Methods_stg_Tmp group by fam_alternate_methods_id )
SEGMENTED BY HASH(fam_alternate_methods_id ,last_modified_date) ALL NODES;

/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_FAM_Alternate_Methods_Hist
(
asset_life
,convention_id
,date_created
,depreciation_method_id
,description
,fam_alternate_methods_extid
,fam_alternate_methods_id 
,fam_alternate_methods_name
,financial_year_start_id
,is_inactive
,last_modified_date
,override_flag
,parent_id
,period_convention_id
,pool_flag
,LD_DT
,SWT_INS_DT
,d_source
)
select
asset_life
,convention_id
,date_created
,depreciation_method_id
,description
,fam_alternate_methods_extid
,fam_alternate_methods_id 
,fam_alternate_methods_name
,financial_year_start_id
,is_inactive
,last_modified_date
,override_flag
,parent_id
,period_convention_id
,pool_flag
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_FAM_Alternate_Methods WHERE fam_alternate_methods_id in
(SELECT STG.fam_alternate_methods_id FROM NS_FAM_Alternate_Methods_stg_Tmp_Key STG JOIN NS_FAM_Alternate_Methods_base_Tmp
ON STG.fam_alternate_methods_id = NS_FAM_Alternate_Methods_base_Tmp.fam_alternate_methods_id AND STG.last_modified_date >= NS_FAM_Alternate_Methods_base_Tmp.last_modified_date);




/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_FAM_Alternate_Methods_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */


DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_FAM_Alternate_Methods WHERE fam_alternate_methods_id in
(SELECT STG.fam_alternate_methods_id FROM NS_FAM_Alternate_Methods_stg_Tmp_Key STG JOIN NS_FAM_Alternate_Methods_base_Tmp
ON STG.fam_alternate_methods_id = NS_FAM_Alternate_Methods_base_Tmp.fam_alternate_methods_id AND STG.last_modified_date >= NS_FAM_Alternate_Methods_base_Tmp.last_modified_date);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_FAM_Alternate_Methods
(
asset_life
,convention_id
,date_created
,depreciation_method_id
,description
,fam_alternate_methods_extid
,fam_alternate_methods_id 
,fam_alternate_methods_name
,financial_year_start_id
,is_inactive
,last_modified_date
,override_flag
,parent_id
,period_convention_id
,pool_flag
,SWT_INS_DT
)
SELECT DISTINCT
asset_life
,convention_id
,date_created
,depreciation_method_id
,description
,fam_alternate_methods_extid
,NS_FAM_Alternate_Methods_stg_Tmp.fam_alternate_methods_id 
,fam_alternate_methods_name
,financial_year_start_id
,is_inactive
,NS_FAM_Alternate_Methods_stg_Tmp.last_modified_date
,override_flag
,parent_id
,period_convention_id
,pool_flag
,SYSDATE AS SWT_INS_DT
FROM NS_FAM_Alternate_Methods_stg_Tmp JOIN NS_FAM_Alternate_Methods_stg_Tmp_Key ON NS_FAM_Alternate_Methods_stg_Tmp.fam_alternate_methods_id = NS_FAM_Alternate_Methods_stg_Tmp_Key.fam_alternate_methods_id AND NS_FAM_Alternate_Methods_stg_Tmp.last_modified_date=NS_FAM_Alternate_Methods_stg_Tmp_Key.last_modified_date
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_FAM_Alternate_Methods BASE
WHERE NS_FAM_Alternate_Methods_stg_Tmp.fam_alternate_methods_id = BASE.fam_alternate_methods_id );


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_FAM_Alternate_Methods' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_FAM_Alternate_Methods' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_FAM_Alternate_Methods',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_FAM_Alternate_Methods where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

SELECT DO_TM_TASK('mergeout', 'swt_rpt_base.NS_FAM_Alternate_Methods');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.NS_FAM_Alternate_Methods_Hist');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_FAM_Alternate_Methods');


