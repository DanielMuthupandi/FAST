/****
****Script Name	  : NS_Payment_terms.sql
****Description   : Incremental data load for NS_Payment_terms
****/

/* Setting timing on**/
\timing
/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Payment_terms";

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
select 'NETSUITE','NS_Payment_terms',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Payment_terms_Hist SELECT * from "swt_rpt_stg".NS_Payment_terms;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select payment_terms_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Payment_terms where payment_terms_id in (
select payment_terms_id from swt_rpt_stg.NS_Payment_terms group by payment_terms_id,date_last_modified having count(1)>1)
group by payment_terms_id);


delete from swt_rpt_stg.NS_Payment_terms where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Payment_terms.payment_terms_id=t2.payment_terms_id and swt_rpt_stg.NS_Payment_terms.auto_id<t2.auto_id);

commit;


CREATE LOCAL TEMP TABLE NS_Payment_terms_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Payment_terms)
SEGMENTED BY HASH(payment_terms_id,date_last_modified) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.NS_Payment_terms;

CREATE LOCAL TEMP TABLE NS_Payment_terms_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT payment_terms_id,date_last_modified FROM swt_rpt_base.NS_Payment_terms)
SEGMENTED BY HASH(payment_terms_id,date_last_modified) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Payment_terms_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT payment_terms_id, max(date_last_modified) as date_last_modified FROM NS_Payment_terms_stg_Tmp group by payment_terms_id)
SEGMENTED BY HASH(payment_terms_id,date_last_modified) ALL NODES;



/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Payment_terms_Hist
(
percentage_discount
,date_driven
,date_last_modified
,days_until_due
,discount_days
,isinactive
,is_preferred
,minimum_days
,name
,payment_terms_extid
,payment_terms_id
,LD_DT
,SWT_INS_DT
,d_source
)
select
percentage_discount
,date_driven
,date_last_modified
,days_until_due
,discount_days
,isinactive
,is_preferred
,minimum_days
,name
,payment_terms_extid
,payment_terms_id
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Payment_terms WHERE payment_terms_id in
(SELECT STG.payment_terms_id FROM NS_Payment_terms_stg_Tmp_Key STG JOIN NS_Payment_terms_base_Tmp
ON STG.payment_terms_id = NS_Payment_terms_base_Tmp.payment_terms_id AND STG.date_last_modified >= NS_Payment_terms_base_Tmp.date_last_modified);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Payment_terms_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Payment_terms WHERE payment_terms_id in
(SELECT STG.payment_terms_id FROM NS_Payment_terms_stg_Tmp_Key STG JOIN NS_Payment_terms_base_Tmp
ON STG.payment_terms_id = NS_Payment_terms_base_Tmp.payment_terms_id AND STG.date_last_modified >= NS_Payment_terms_base_Tmp.date_last_modified);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Payment_terms
(
percentage_discount
,date_driven
,date_last_modified
,days_until_due
,discount_days
,isinactive
,is_preferred
,minimum_days
,name
,payment_terms_extid
,payment_terms_id
,SWT_INS_DT
)
SELECT DISTINCT 
percentage_discount
,date_driven
,NS_Payment_terms_stg_Tmp.date_last_modified
,days_until_due
,discount_days
,isinactive
,is_preferred
,minimum_days
,name
,payment_terms_extid
,NS_Payment_terms_stg_Tmp.payment_terms_id
,SYSDATE AS SWT_INS_DT
FROM NS_Payment_terms_stg_Tmp JOIN NS_Payment_terms_stg_Tmp_Key ON NS_Payment_terms_stg_Tmp.payment_terms_id= NS_Payment_terms_stg_Tmp_Key.payment_terms_id AND NS_Payment_terms_stg_Tmp.date_last_modified=NS_Payment_terms_stg_Tmp_Key.date_last_modified
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Payment_terms BASE
WHERE NS_Payment_terms_stg_Tmp.payment_terms_id = BASE.payment_terms_id);




/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Payment_terms' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Payment_terms' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Payment_terms',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Payment_terms where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

SELECT PURGE_TABLE('swt_rpt_base.NS_Payment_terms');
SELECT PURGE_TABLE('swt_rpt_stg.NS_Payment_terms_Hist');
select ANALYZE_STATISTICS('swt_rpt_base.NS_Payment_terms');


