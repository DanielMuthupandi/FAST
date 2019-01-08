/*****
***** Script Name	  : NS_FAM_Depreciation_History.sql
****Description   : Incremental data load for NS_FAM_Depreciation_History
****/

/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_FAM_Depreciation_History";

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
select 'NETSUITE','NS_FAM_Depreciation_History',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';


Commit;
INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_FAM_Depreciation_History_Hist SELECT * from "swt_rpt_stg".NS_FAM_Depreciation_History;

CREATE LOCAL TEMP TABLE duplicates_FAM_Depreciation_History  ON COMMIT PRESERVE ROWS AS 
select max(auto_id) as auto_id,fam_depreciation_history_id from swt_rpt_stg.NS_FAM_Depreciation_History where fam_depreciation_history_id in(
select fam_depreciation_history_id from swt_rpt_stg.NS_FAM_Depreciation_History
group by fam_depreciation_history_id,last_modified_date having count(1)>1)
group by fam_depreciation_history_id;

delete from swt_rpt_stg.NS_FAM_Depreciation_History  where exists(
select 1 from duplicates_FAM_Depreciation_History t2 where swt_rpt_stg.NS_FAM_Depreciation_History.fam_depreciation_history_id=t2.fam_depreciation_history_id and swt_rpt_stg.NS_FAM_Depreciation_History.auto_id<t2.auto_id);

COMMIT;

CREATE LOCAL TEMP TABLE NS_FAM_Depreciation_History_stg_Tmp ON COMMIT PRESERVE ROWS AS
( 
SELECT DISTINCT * FROM swt_rpt_stg.NS_FAM_Depreciation_History)
SEGMENTED BY HASH(fam_depreciation_history_id,last_modified_date) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.NS_FAM_Depreciation_History;

  
CREATE LOCAL TEMP TABLE NS_FAM_Depreciation_History_base_Tmp ON COMMIT PRESERVE ROWS AS
( 
SELECT DISTINCT fam_depreciation_history_id,last_modified_date FROM swt_rpt_base.NS_FAM_Depreciation_History)
SEGMENTED BY HASH(fam_depreciation_history_id,last_modified_date) ALL NODES;


CREATE LOCAL TEMP TABLE NS_FAM_Depreciation_History_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT fam_depreciation_history_id, max(last_modified_date) as last_modified_date FROM NS_FAM_Depreciation_History_stg_Tmp group by fam_depreciation_history_id) 
SEGMENTED BY HASH(fam_depreciation_history_id,last_modified_date) ALL NODES;


 /* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_FAM_Depreciation_History_Hist
(
accounting_book_id
,actual_depreciation_method_id
,alternate_method_id
,alternate__depreciation_id
,asset_id
,asset_type_id
,date_0
,date_created
,depreciation_method_id
,custom_lcci_id
,fam_depreciation_history_extid
,fam_depreciation_history_id
,custom_functional_area_id
,custom_profit_center_id
,is_inactive
,last_modified_date
,net_book_value
,parent_id
,period
,posting_reference_id
,quantity
,schedule
,scheduled_amount
,scheduled_nbv
,subsidiary_id
,summary_record_id
,transaction_amount
,transaction_type_id
,write_in_journal_deprecated
,LD_DT
,SWT_INS_DT
,d_source
,SWT_Ins_Date_Backup
)
 select 
accounting_book_id
,actual_depreciation_method_id
,alternate_method_id
,alternate__depreciation_id
,asset_id
,asset_type_id
,date_0
,date_created
,depreciation_method_id
,custom_lcci_id
,fam_depreciation_history_extid
,fam_depreciation_history_id
,custom_functional_area_id
,custom_profit_center_id
,is_inactive
,last_modified_date
,net_book_value
,parent_id
,period
,posting_reference_id
,quantity
,schedule
,scheduled_amount
,scheduled_nbv
,subsidiary_id
,summary_record_id
,transaction_amount
,transaction_type_id
,write_in_journal_deprecated
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
,SWT_Ins_Date_Backup
FROM "swt_rpt_base".NS_FAM_Depreciation_History WHERE fam_depreciation_history_id in 
(SELECT STG.fam_depreciation_history_id FROM NS_FAM_Depreciation_History_stg_Tmp_Key STG JOIN NS_FAM_Depreciation_History_base_Tmp
ON STG.fam_depreciation_history_id = NS_FAM_Depreciation_History_base_Tmp.fam_depreciation_history_id AND STG.last_modified_date >= NS_FAM_Depreciation_History_base_Tmp.last_modified_date);

 /* Deleting before seven days data from current date in the Historical Table */  

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_FAM_Depreciation_History_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


 /* Incremental VSQL script for loading data from Stage to Base */ 
 

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_FAM_Depreciation_History WHERE fam_depreciation_history_id in
(SELECT STG.fam_depreciation_history_id FROM NS_FAM_Depreciation_History_stg_Tmp_Key STG JOIN NS_FAM_Depreciation_History_base_Tmp
ON STG.fam_depreciation_history_id = NS_FAM_Depreciation_History_base_Tmp.fam_depreciation_history_id AND STG.last_modified_date >= NS_FAM_Depreciation_History_base_Tmp.last_modified_date);
		  
INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_FAM_Depreciation_History
(
accounting_book_id
,actual_depreciation_method_id
,alternate_method_id
,alternate__depreciation_id
,asset_id
,asset_type_id
,date_0
,date_created
,depreciation_method_id
,custom_lcci_id
,fam_depreciation_history_extid
,fam_depreciation_history_id
,custom_functional_area_id
,custom_profit_center_id
,is_inactive
,last_modified_date
,net_book_value
,parent_id
,period
,posting_reference_id
,quantity
,schedule
,scheduled_amount
,scheduled_nbv
,subsidiary_id
,summary_record_id
,transaction_amount
,transaction_type_id
,write_in_journal_deprecated
,SWT_INS_DT	
,SWT_Ins_Date_Backup
)
SELECT DISTINCT
accounting_book_id
,actual_depreciation_method_id
,alternate_method_id
,alternate__depreciation_id
,asset_id
,asset_type_id
,date_0
,date_created
,depreciation_method_id
,custom_lcci_id
,fam_depreciation_history_extid
,NS_FAM_Depreciation_History_stg_Tmp.fam_depreciation_history_id
,custom_functional_area_id
,custom_profit_center_id
,is_inactive
,NS_FAM_Depreciation_History_stg_Tmp.last_modified_date
,net_book_value
,parent_id
,period
,posting_reference_id
,quantity
,schedule
,scheduled_amount
,scheduled_nbv
,subsidiary_id
,summary_record_id
,transaction_amount
,transaction_type_id
,write_in_journal_deprecated
,SYSDATE AS SWT_INS_DT
,sysdate as SWT_Ins_Date_Backup
FROM NS_FAM_Depreciation_History_stg_Tmp JOIN NS_FAM_Depreciation_History_stg_Tmp_Key ON NS_FAM_Depreciation_History_stg_Tmp.fam_depreciation_history_id= NS_FAM_Depreciation_History_stg_Tmp_Key.fam_depreciation_history_id AND NS_FAM_Depreciation_History_stg_Tmp.last_modified_date=NS_FAM_Depreciation_History_stg_Tmp_Key.last_modified_date
	WHERE NOT EXISTS
	(SELECT 1 FROM "swt_rpt_base".NS_FAM_Depreciation_History BASE
		WHERE NS_FAM_Depreciation_History_stg_Tmp.fam_depreciation_history_id = BASE.fam_depreciation_history_id);	

COMMIT;

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
select 'NETSUITE','NS_FAM_Depreciation_History',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_FAM_Depreciation_History where SWT_INS_DT::date = sysdate::date),'Y';


Commit;

/*---------------------------------------------------------------------------*/

CREATE LOCAL TEMP TABLE Start_Time_Tmp_Id ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from swt_rpt_stg.NS_FAM_Depreciation_History_Id;

/* Inserting values into Audit table for ID table */

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
select 'NETSUITE','NS_FAM_Depreciation_History_Id',sysdate::date,sysdate,null,(select count from Start_Time_Tmp_Id) ,null,'N';

Commit;

/* Update is_deleted flag for deletions from Netsuite */

INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_FAM_Depreciation_History_Id
( 
fam_depreciation_history_id,
SWT_INS_DT
)
SELECT
fam_depreciation_history_id,
SYSDATE
FROM swt_rpt_stg.NS_FAM_Depreciation_History_Id;

CREATE LOCAL TEMP TABLE NS_FAM_Depreciation_History_base_deleted ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_base.NS_FAM_Depreciation_History where Is_Deleted <> 'true' and not exists ( select 1 from swt_rpt_stg.NS_FAM_Depreciation_History_ID
where swt_rpt_base.NS_FAM_Depreciation_History.fam_depreciation_history_id = swt_rpt_stg.NS_FAM_Depreciation_History_ID.fam_depreciation_history_id))
SEGMENTED BY HASH(fam_depreciation_history_id) ALL NODES;


DELETE /*+DIRECT*/ FROM swt_rpt_base.NS_FAM_Depreciation_History where Is_Deleted <> 'true' and not exists ( select 1 from swt_rpt_stg.NS_FAM_Depreciation_History_ID
where swt_rpt_base.NS_FAM_Depreciation_History.fam_depreciation_history_id = swt_rpt_stg.NS_FAM_Depreciation_History_ID.fam_depreciation_history_id);

INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_FAM_Depreciation_History_Deleted_Ids
( 
fam_depreciation_history_id,
SWT_INS_DT,
status
)
SELECT
fam_depreciation_history_id,
SYSDATE,
'deleted'
FROM NS_FAM_Depreciation_History_base_deleted;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_FAM_Depreciation_History
(
accounting_book_id
,actual_depreciation_method_id
,alternate_method_id
,alternate__depreciation_id
,asset_id
,asset_type_id
,date_0
,date_created
,depreciation_method_id
,custom_lcci_id
,fam_depreciation_history_extid
,fam_depreciation_history_id
,custom_functional_area_id
,custom_profit_center_id
,is_inactive
,last_modified_date
,net_book_value
,parent_id
,period
,posting_reference_id
,quantity
,schedule
,scheduled_amount
,scheduled_nbv
,subsidiary_id
,summary_record_id
,transaction_amount
,transaction_type_id
,write_in_journal_deprecated
,SWT_INS_DT
,Is_Deleted
,SWT_Ins_Date_Backup
)
select
accounting_book_id
,actual_depreciation_method_id
,alternate_method_id
,alternate__depreciation_id
,asset_id
,asset_type_id
,date_0
,date_created
,depreciation_method_id
,custom_lcci_id
,fam_depreciation_history_extid
,fam_depreciation_history_id
,custom_functional_area_id
,custom_profit_center_id
,is_inactive
,last_modified_date
,net_book_value
,parent_id
,period
,posting_reference_id
,quantity
,schedule
,scheduled_amount
,scheduled_nbv
,subsidiary_id
,summary_record_id
,transaction_amount
,transaction_type_id
,write_in_journal_deprecated
,sysdate as SWT_INS_DT
,'true'
,SWT_INS_DT
FROM NS_FAM_Depreciation_History_base_deleted;

CREATE LOCAL TEMP TABLE NS_FAM_Depreciation_History_base_active ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_base.NS_FAM_Depreciation_History where Is_Deleted = 'true' and exists ( select 1 from swt_rpt_stg.NS_FAM_Depreciation_History_ID
where swt_rpt_base.NS_FAM_Depreciation_History.fam_depreciation_history_id = swt_rpt_stg.NS_FAM_Depreciation_History_ID.fam_depreciation_history_id))
SEGMENTED BY HASH(fam_depreciation_history_id) ALL NODES;


DELETE /*+DIRECT*/ FROM swt_rpt_base.NS_FAM_Depreciation_History where Is_Deleted ='true' and exists ( select 1 from swt_rpt_stg.NS_FAM_Depreciation_History_ID
where swt_rpt_base.NS_FAM_Depreciation_History.fam_depreciation_history_id = swt_rpt_stg.NS_FAM_Depreciation_History_ID.fam_depreciation_history_id);


INSERT /*+DIRECT*/ INTO swt_rpt_base.NS_FAM_Depreciation_History_Deleted_Ids
( 
fam_depreciation_history_id,
SWT_INS_DT,
status
)
SELECT
fam_depreciation_history_id,
SYSDATE,
'activated'
FROM NS_FAM_Depreciation_History_base_active;


INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_FAM_Depreciation_History
(
accounting_book_id
,actual_depreciation_method_id
,alternate_method_id
,alternate__depreciation_id
,asset_id
,asset_type_id
,date_0
,date_created
,depreciation_method_id
,custom_lcci_id
,fam_depreciation_history_extid
,fam_depreciation_history_id
,custom_functional_area_id
,custom_profit_center_id
,is_inactive
,last_modified_date
,net_book_value
,parent_id
,period
,posting_reference_id
,quantity
,schedule
,scheduled_amount
,scheduled_nbv
,subsidiary_id
,summary_record_id
,transaction_amount
,transaction_type_id
,write_in_journal_deprecated
,SWT_INS_DT
,Is_Deleted
,SWT_Ins_Date_Backup
)
select
accounting_book_id
,actual_depreciation_method_id
,alternate_method_id
,alternate__depreciation_id
,asset_id
,asset_type_id
,date_0
,date_created
,depreciation_method_id
,custom_lcci_id
,fam_depreciation_history_extid
,fam_depreciation_history_id
,custom_functional_area_id
,custom_profit_center_id
,is_inactive
,last_modified_date
,net_book_value
,parent_id
,period
,posting_reference_id
,quantity
,schedule
,scheduled_amount
,scheduled_nbv
,subsidiary_id
,summary_record_id
,transaction_amount
,transaction_type_id
,write_in_journal_deprecated
,sysdate as SWT_INS_DT
,'false'
,SWT_INS_DT
FROM NS_FAM_Depreciation_History_base_active;

COMMIT;		
			
/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_FAM_Depreciation_History' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_FAM_Depreciation_History' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_FAM_Depreciation_History_Id',sysdate::date,(select st from Start_Time_Tmp_Id),sysdate,(select count from Start_Time_Tmp_Id) ,(select count(*) from swt_rpt_base.NS_FAM_Depreciation_History where SWT_INS_DT>=(select max(START_DT_TIME) from swt_rpt_stg.FAST_LD_AUDT where TBL_NM='NS_FAM_Depreciation_History_Id') and is_deleted='true'),'Y';

Commit;
    

SELECT DO_TM_TASK('mergeout', 'swt_rpt_base.NS_FAM_Depreciation_History');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.NS_FAM_Depreciation_History_Hist');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_FAM_Depreciation_History');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_FAM_Depreciation_History_deleted_IDS');

TRUNCATE TABLE swt_rpt_stg.NS_FAM_Depreciation_History_Id;
delete /*+DIRECT*/ from "swt_rpt_base"."NS_FAM_Depreciation_History_Id"  where swt_ins_dt::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

commit;




