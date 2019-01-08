/*Script Name	  : NS_Transaction_links.sql
****Description   : Incremental data load for NS_Transaction_links
****/

/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from swt_rpt_stg.NS_Transaction_links;

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
select 'NETSUITE','NS_Transaction_links',SYSDATE::date,SYSDATE,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Transaction_links_Hist SELECT * from "swt_rpt_stg".NS_Transaction_links;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select original_transaction_id ,applied_transaction_id ,applied_transaction_line_id ,original_transaction_line_id,inventory_number,link_type,max(auto_id) as auto_id from swt_rpt_stg.NS_Transaction_links where (original_transaction_id ,applied_transaction_id ,applied_transaction_line_id ,original_transaction_line_id ,inventory_number,link_type) in (
select original_transaction_id ,applied_transaction_id ,applied_transaction_line_id ,original_transaction_line_id ,inventory_number,link_type from swt_rpt_stg.NS_Transaction_links group by original_transaction_id ,applied_transaction_id ,applied_transaction_line_id ,original_transaction_line_id ,date_last_modified,inventory_number,link_type having count(1)>1)
group by original_transaction_id ,applied_transaction_id ,applied_transaction_line_id ,original_transaction_line_id,inventory_number,link_type);


delete from swt_rpt_stg.NS_Transaction_links  where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Transaction_links.original_transaction_id=t2.original_transaction_id and  swt_rpt_stg.NS_Transaction_links.applied_transaction_id=t2.applied_transaction_id and swt_rpt_stg.NS_Transaction_links.applied_transaction_line_id=t2.applied_transaction_line_id and swt_rpt_stg.NS_Transaction_links.original_transaction_line_id=t2.original_transaction_line_id and swt_rpt_stg.NS_Transaction_links.inventory_number=t2.inventory_number and swt_rpt_stg.NS_Transaction_links.link_type=t2.link_type and swt_rpt_stg.NS_Transaction_links.auto_id<t2.auto_id);

commit;


CREATE LOCAL TEMP TABLE NS_Transaction_links_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Transaction_links)
SEGMENTED BY HASH(original_transaction_id ,applied_transaction_id ,applied_transaction_line_id ,original_transaction_line_id ,date_last_modified,inventory_number,link_type) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.NS_Transaction_links;


CREATE LOCAL TEMP TABLE NS_Transaction_links_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT original_transaction_id ,applied_transaction_id ,applied_transaction_line_id ,original_transaction_line_id,max(date_last_modified) as date_last_modified ,inventory_number,link_type FROM NS_Transaction_links_stg_Tmp group by original_transaction_id ,applied_transaction_id ,applied_transaction_line_id ,original_transaction_line_id,inventory_number,link_type)
SEGMENTED BY HASH(original_transaction_id ,applied_transaction_id ,applied_transaction_line_iD ,original_transaction_line_id ,date_last_modified,inventory_number,link_type) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Transaction_links_Hist
(
amount_foreign_linked
,amount_linked
,applied_date_posted
,applied_transaction_id
,applied_transaction_line_id
,date_last_modified
,discount
,inventory_number
,link_type
,original_date_posted
,original_transaction_id
,original_transaction_line_id
,quantity_linked
,LD_DT
,SWT_INS_DT
,d_source
,SWT_Ins_Date_Backup
)
select
amount_foreign_linked
,amount_linked
,applied_date_posted
,applied_transaction_id
,applied_transaction_line_id
,date_last_modified
,discount
,inventory_number
,link_type
,original_date_posted
,original_transaction_id
,original_transaction_line_id
,quantity_linked
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
,SWT_Ins_Date_Backup
FROM "swt_rpt_base".NS_Transaction_links WHERE EXISTS
(SELECT 1 FROM NS_Transaction_links_stg_Tmp_Key STG 
WHERE STG.original_transaction_id = NS_Transaction_links.original_transaction_id AND STG.applied_transaction_id = NS_Transaction_links.applied_transaction_id AND STG.applied_transaction_line_id = NS_Transaction_links.applied_transaction_line_id AND STG.original_transaction_line_id = NS_Transaction_links.original_transaction_line_id AND STG.date_last_modified >= NS_Transaction_links.date_last_modified AND isnull(STG.inventory_number,'')=isnull(NS_Transaction_links.inventory_number,'') AND isnull(STG.link_type,'')=isnull(NS_Transaction_links.link_type,''));



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Transaction_links_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,SYSDATE)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Transaction_links WHERE EXISTS
(SELECT 1 FROM NS_Transaction_links_stg_Tmp_Key STG 
WHERE STG.original_transaction_id = NS_Transaction_links.original_transaction_id AND STG.applied_transaction_id = NS_Transaction_links.applied_transaction_id AND STG.applied_transaction_line_id = NS_Transaction_links.applied_transaction_line_id AND STG.original_transaction_line_id = NS_Transaction_links.original_transaction_line_id AND STG.date_last_modified >= NS_Transaction_links.date_last_modified AND isnull(STG.inventory_number,'')=isnull(NS_Transaction_links.inventory_number,'') AND isnull(STG.link_type,'')=isnull(NS_Transaction_links.link_type,''));

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Transaction_links
(
amount_foreign_linked
,amount_linked
,applied_date_posted
,applied_transaction_id
,applied_transaction_line_id
,date_last_modified
,discount
,inventory_number
,link_type
,original_date_posted
,original_transaction_id
,original_transaction_line_id
,quantity_linked
,SWT_INS_DT
,SWT_Ins_Date_Backup
)

SELECT DISTINCT
amount_foreign_linked
,amount_linked
,applied_date_posted
,NS_Transaction_links_stg_Tmp.applied_transaction_id
,NS_Transaction_links_stg_Tmp.applied_transaction_line_id
,NS_Transaction_links_stg_Tmp.date_last_modified
,discount
,NS_Transaction_links_stg_Tmp.inventory_number
,NS_Transaction_links_stg_Tmp.link_type
,original_date_posted
,NS_Transaction_links_stg_Tmp.original_transaction_id
,NS_Transaction_links_stg_Tmp.original_transaction_line_id
,quantity_linked
,SYSDATE AS SWT_INS_DT
,sysdate as SWT_Ins_Date_Backup
FROM NS_Transaction_links_stg_Tmp JOIN NS_Transaction_links_stg_Tmp_Key ON NS_Transaction_links_stg_Tmp.original_transaction_id = NS_Transaction_links_stg_Tmp_Key.original_transaction_id AND NS_Transaction_links_stg_Tmp.applied_transaction_id = NS_Transaction_links_stg_Tmp_Key.applied_transaction_id AND NS_Transaction_links_stg_Tmp.applied_transaction_line_iD = NS_Transaction_links_stg_Tmp_Key.applied_transaction_line_iD AND NS_Transaction_links_stg_Tmp.original_transaction_line_id = NS_Transaction_links_stg_Tmp_Key.original_transaction_line_id AND NS_Transaction_links_stg_Tmp.date_last_modified = NS_Transaction_links_stg_Tmp_Key.date_last_modified AND isnull(NS_Transaction_links_stg_Tmp.inventory_number,'')=isnull(NS_Transaction_links_stg_Tmp_Key.inventory_number,'') AND isnull(NS_Transaction_links_stg_Tmp.link_type,'')=isnull(NS_Transaction_links_stg_Tmp_Key.link_type,'') 
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Transaction_links BASE
WHERE NS_Transaction_links_stg_Tmp.original_transaction_id = BASE.original_transaction_id
AND NS_Transaction_links_stg_Tmp.applied_transaction_id=BASE.applied_transaction_id
AND NS_Transaction_links_stg_Tmp.applied_transaction_line_id=BASE.applied_transaction_line_id
AND NS_Transaction_links_stg_Tmp.original_transaction_line_id=BASE.original_transaction_line_id 
AND isnull(NS_Transaction_links_stg_Tmp.inventory_number,'')=isnull(BASE.inventory_number,'')
AND isnull(NS_Transaction_links_stg_Tmp.link_type,'')=isnull(BASE.link_type,''));

COMMIT;


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Transaction_links' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Transaction_links' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Transaction_links',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Transaction_links where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

SELECT DO_TM_TASK('mergeout', 'swt_rpt_base.NS_Transaction_links');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.NS_Transaction_links_Hist');
SELECT DO_TM_TASK('mergeout', 'swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Transaction_links');


