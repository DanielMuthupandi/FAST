/****
****Script Name	  : NS_FAM_Alternate_Depreciation.sql
****Description   : Incremental data load for NS_FAM_Alternate_Depreciation
****/

/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_FAM_Alternate_Depreciation";

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
select 'NETSUITE','NS_FAM_Alternate_Depreciation',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_FAM_Alternate_Depreciation_Hist SELECT * from "swt_rpt_stg".NS_FAM_Alternate_Depreciation;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select fam_alternate_depreciation_id,max(auto_id) as auto_id from swt_rpt_stg.NS_FAM_Alternate_Depreciation where fam_alternate_depreciation_id in (
select fam_alternate_depreciation_id from swt_rpt_stg.NS_FAM_Alternate_Depreciation group by fam_alternate_depreciation_id,last_modified_date having count(1)>1)
group by fam_alternate_depreciation_id);

delete from swt_rpt_stg.NS_FAM_Alternate_Depreciation where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_FAM_Alternate_Depreciation.fam_alternate_depreciation_id=t2.fam_alternate_depreciation_id and swt_rpt_stg.NS_FAM_Alternate_Depreciation.auto_id<t2. auto_id);

COMMIT;

CREATE LOCAL TEMP TABLE NS_FAM_Alternate_Depreciation_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_FAM_Alternate_Depreciation)
SEGMENTED BY HASH(fam_alternate_depreciation_id,last_modified_date) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.NS_FAM_Alternate_Depreciation;

CREATE LOCAL TEMP TABLE NS_FAM_Alternate_Depreciation_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT fam_alternate_depreciation_id,last_modified_date FROM swt_rpt_base.NS_FAM_Alternate_Depreciation)
SEGMENTED BY HASH(fam_alternate_depreciation_id,last_modified_date) ALL NODES;


CREATE LOCAL TEMP TABLE NS_FAM_Alternate_Depreciation_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT fam_alternate_depreciation_id, max(last_modified_date) as last_modified_date FROM NS_FAM_Alternate_Depreciation_stg_Tmp group by fam_alternate_depreciation_id)
SEGMENTED BY HASH(fam_alternate_depreciation_id,last_modified_date) ALL NODES;

/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_FAM_Alternate_Depreciation_Hist
(
accounting_book_id
,allow_override
,alternate_method_id
,annual_method_entry_id
,asset_account_id
,asset_life_al
,asset_status_id
,book_value_nbv
,convention_c_id
,cumulative_depreciation
,currency_id
,current_cost
,date_created
,depreciation_account_id
,depreciation_active_id
,depreciation_charge_account_id
,depreciation_end_date
,depreciation_method_id
,depreciation_period_id
,depreciation_rules_id
,depreciation_start_date
,disposal_cost_account_id
,fam_alternate_depreciation_ext
,fam_alternate_depreciation_id
,financial_year_start_id
,fixed_rate
,forecast_amount_fc_deprecated
,group_depreciation
,group_master
,is_inactive
,last_depreciation_amount_ld
,last_depreciation_date
,last_depreciation_period
,last_modified_date
,original_cost
,parent_asset_id
,parent_id
,period_convention_id
,prior_year_nbv
,residual_value_percentage
,residual_value_rv
,revision_rules_id
,subsidiary_id
,write_down_account_id
,write_off_account_id
,LD_DT
,SWT_INS_DT
,d_source
)
select
accounting_book_id
,allow_override
,alternate_method_id
,annual_method_entry_id
,asset_account_id
,asset_life_al
,asset_status_id
,book_value_nbv
,convention_c_id
,cumulative_depreciation
,currency_id
,current_cost
,date_created
,depreciation_account_id
,depreciation_active_id
,depreciation_charge_account_id
,depreciation_end_date
,depreciation_method_id
,depreciation_period_id
,depreciation_rules_id
,depreciation_start_date
,disposal_cost_account_id
,fam_alternate_depreciation_ext
,fam_alternate_depreciation_id
,financial_year_start_id
,fixed_rate
,forecast_amount_fc_deprecated
,group_depreciation
,group_master
,is_inactive
,last_depreciation_amount_ld
,last_depreciation_date
,last_depreciation_period
,last_modified_date
,original_cost
,parent_asset_id
,parent_id
,period_convention_id
,prior_year_nbv
,residual_value_percentage
,residual_value_rv
,revision_rules_id
,subsidiary_id
,write_down_account_id
,write_off_account_id
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_FAM_Alternate_Depreciation WHERE fam_alternate_depreciation_id in
(SELECT STG.fam_alternate_depreciation_id FROM NS_FAM_Alternate_Depreciation_stg_Tmp_Key STG JOIN NS_FAM_Alternate_Depreciation_base_Tmp
ON STG.fam_alternate_depreciation_id = NS_FAM_Alternate_Depreciation_base_Tmp.fam_alternate_depreciation_id AND STG.last_modified_date >= NS_FAM_Alternate_Depreciation_base_Tmp.last_modified_date);


/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_FAM_Alternate_Depreciation_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

/* Incremental VSQL script for loading data from Stage to Base */


DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_FAM_Alternate_Depreciation WHERE fam_alternate_depreciation_id in
(SELECT STG.fam_alternate_depreciation_id FROM NS_FAM_Alternate_Depreciation_stg_Tmp_Key STG JOIN NS_FAM_Alternate_Depreciation_base_Tmp
ON STG.fam_alternate_depreciation_id = NS_FAM_Alternate_Depreciation_base_Tmp.fam_alternate_depreciation_id AND STG.last_modified_date >= NS_FAM_Alternate_Depreciation_base_Tmp.last_modified_date);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_FAM_Alternate_Depreciation
(
accounting_book_id
,allow_override
,alternate_method_id
,annual_method_entry_id
,asset_account_id
,asset_life_al
,asset_status_id
,book_value_nbv
,convention_c_id
,cumulative_depreciation
,currency_id
,current_cost
,date_created
,depreciation_account_id
,depreciation_active_id
,depreciation_charge_account_id
,depreciation_end_date
,depreciation_method_id
,depreciation_period_id
,depreciation_rules_id
,depreciation_start_date
,disposal_cost_account_id
,fam_alternate_depreciation_ext
,fam_alternate_depreciation_id
,financial_year_start_id
,fixed_rate
,forecast_amount_fc_deprecated
,group_depreciation
,group_master
,is_inactive
,last_depreciation_amount_ld
,last_depreciation_date
,last_depreciation_period
,last_modified_date
,original_cost
,parent_asset_id
,parent_id
,period_convention_id
,prior_year_nbv
,residual_value_percentage
,residual_value_rv
,revision_rules_id
,subsidiary_id
,write_down_account_id
,write_off_account_id
,SWT_INS_DT
)
SELECT DISTINCT
accounting_book_id
,allow_override
,alternate_method_id
,annual_method_entry_id
,asset_account_id
,asset_life_al
,asset_status_id
,book_value_nbv
,convention_c_id
,cumulative_depreciation
,currency_id
,current_cost
,date_created
,depreciation_account_id
,depreciation_active_id
,depreciation_charge_account_id
,depreciation_end_date
,depreciation_method_id
,depreciation_period_id
,depreciation_rules_id
,depreciation_start_date
,disposal_cost_account_id
,fam_alternate_depreciation_ext
,NS_FAM_Alternate_Depreciation_stg_Tmp.fam_alternate_depreciation_id
,financial_year_start_id
,fixed_rate
,forecast_amount_fc_deprecated
,group_depreciation
,group_master
,is_inactive
,last_depreciation_amount_ld
,last_depreciation_date
,last_depreciation_period
,NS_FAM_Alternate_Depreciation_stg_Tmp.last_modified_date
,original_cost
,parent_asset_id
,parent_id
,period_convention_id
,prior_year_nbv
,residual_value_percentage
,residual_value_rv
,revision_rules_id
,subsidiary_id
,write_down_account_id
,write_off_account_id
,SYSDATE AS SWT_INS_DT
FROM NS_FAM_Alternate_Depreciation_stg_Tmp JOIN NS_FAM_Alternate_Depreciation_stg_Tmp_Key ON NS_FAM_Alternate_Depreciation_stg_Tmp.fam_alternate_depreciation_id= NS_FAM_Alternate_Depreciation_stg_Tmp_Key.fam_alternate_depreciation_id AND NS_FAM_Alternate_Depreciation_stg_Tmp.last_modified_date=NS_FAM_Alternate_Depreciation_stg_Tmp_Key.last_modified_date
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_FAM_Alternate_Depreciation BASE
WHERE NS_FAM_Alternate_Depreciation_stg_Tmp.fam_alternate_depreciation_id = BASE.fam_alternate_depreciation_id);


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_FAM_Alternate_Depreciation' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_FAM_Alternate_Depreciation' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_FAM_Alternate_Depreciation',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_FAM_Alternate_Depreciation where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


SELECT DO_TM_TASK('mergeout', 'swt_rpt_base.NS_FAM_Alternate_Depreciation');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.NS_FAM_Alternate_Depreciation_Hist');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_FAM_Alternate_Depreciation');


