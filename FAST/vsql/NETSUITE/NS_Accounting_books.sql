/****
****Script Name	  : NS_Accounting_books.sql
****Description   : Incremental data load for NS_Accounting_books
****/
/* Setting timing on**/
\timing
/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Accounting_books";

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
select 'NETSUITE','NS_Accounting_books',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Accounting_books_Hist SELECT * from "swt_rpt_stg".NS_Accounting_books;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select accounting_book_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Accounting_books where accounting_book_id in (
select accounting_book_id from swt_rpt_stg.NS_Accounting_books group by accounting_book_id,date_last_modified having count(1)>1)
group by accounting_book_id);


delete from swt_rpt_stg.NS_Accounting_books where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Accounting_books.accounting_book_id=t2.accounting_book_id and swt_rpt_stg.NS_Accounting_books.auto_id<t2.auto_id);

commit;

CREATE LOCAL TEMP TABLE NS_Accounting_books_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Accounting_books)
SEGMENTED BY HASH(accounting_book_id,date_last_modified) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.NS_Accounting_books;

CREATE LOCAL TEMP TABLE NS_Accounting_books_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT accounting_book_id,date_last_modified FROM swt_rpt_base.NS_Accounting_books)
SEGMENTED BY HASH(accounting_book_id,date_last_modified) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Accounting_books_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT accounting_book_id, max(date_last_modified) as date_last_modified FROM NS_Accounting_books_stg_Tmp group by accounting_book_id)
SEGMENTED BY HASH(accounting_book_id,date_last_modified) ALL NODES;

/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Accounting_books_Hist
(
accounting_book_extid
,accounting_book_id
,accounting_book_name
,date_created
,date_last_modified
,effective_period_id
,form_template_component_id
,form_template_id
,is_arrangement_level_reclass
,is_consolidated
,is_contingent_revenue_handling
,is_include_child_subsidiaries
,is_primary
,is_two_step_revenue_allocation
,status
,unbilled_receivable_grouping
,LD_DT
,SWT_INS_DT
,d_source
)
select
accounting_book_extid
,accounting_book_id
,accounting_book_name
,date_created
,date_last_modified
,effective_period_id
,form_template_component_id
,form_template_id
,is_arrangement_level_reclass
,is_consolidated
,is_contingent_revenue_handling
,is_include_child_subsidiaries
,is_primary
,is_two_step_revenue_allocation
,status
,unbilled_receivable_grouping
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Accounting_books WHERE accounting_book_id in
(SELECT STG.accounting_book_id FROM NS_Accounting_books_stg_Tmp_Key STG JOIN NS_Accounting_books_base_Tmp
ON STG.accounting_book_id = NS_Accounting_books_base_Tmp.accounting_book_id AND STG.date_last_modified >= NS_Accounting_books_base_Tmp.date_last_modified);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Accounting_books_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Accounting_books WHERE accounting_book_id in
(SELECT STG.accounting_book_id FROM NS_Accounting_books_stg_Tmp_Key STG JOIN NS_Accounting_books_base_Tmp
ON STG.accounting_book_id = NS_Accounting_books_base_Tmp.accounting_book_id AND STG.date_last_modified >= NS_Accounting_books_base_Tmp.date_last_modified);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Accounting_books
(
accounting_book_extid
,accounting_book_id
,accounting_book_name
,date_created
,date_last_modified
,effective_period_id
,form_template_component_id
,form_template_id
,is_arrangement_level_reclass
,is_consolidated
,is_contingent_revenue_handling
,is_include_child_subsidiaries
,is_primary
,is_two_step_revenue_allocation
,status
,unbilled_receivable_grouping
,SWT_INS_DT
)
SELECT DISTINCT 
accounting_book_extid
,NS_Accounting_books_stg_Tmp.accounting_book_id
,accounting_book_name
,date_created
,NS_Accounting_books_stg_Tmp.date_last_modified
,effective_period_id
,form_template_component_id
,form_template_id
,is_arrangement_level_reclass
,is_consolidated
,is_contingent_revenue_handling
,is_include_child_subsidiaries
,is_primary
,is_two_step_revenue_allocation
,status
,unbilled_receivable_grouping
,sysdate as SWT_INS_DT
FROM NS_Accounting_books_stg_Tmp JOIN NS_Accounting_books_stg_Tmp_Key ON NS_Accounting_books_stg_Tmp.accounting_book_id= NS_Accounting_books_stg_Tmp_Key.accounting_book_id AND NS_Accounting_books_stg_Tmp.date_last_modified=NS_Accounting_books_stg_Tmp_Key.date_last_modified
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Accounting_books BASE
WHERE NS_Accounting_books_stg_Tmp.accounting_book_id = BASE.accounting_book_id);



/* Deleting partial audit entry 
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Accounting_books' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Accounting_books' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Accounting_books',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Accounting_books where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


SELECT DO_TM_TASK('mergeout',  'swt_rpt_base.NS_Accounting_Books');
SELECT DO_TM_TASK('mergeout',  'swt_rpt_stg.NS_Accounting_Books_Hist');
select ANALYZE_STATISTICS('swt_rpt_base.NS_Accounting_books');




