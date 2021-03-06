/****
****Script Name	  : NS_Finance_Owner_ID.sql
****Description   : Incremental data load for NS_Finance_Owner_ID
****/

/* Setting timing on**/
\timing

/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."NS_Finance_Owner_ID";

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
select 'NETSUITE','NS_Finance_Owner_ID',now()::date,now(),null,(select count from Start_Time_Tmp) ,null,'N';

Commit;


INSERT /*+DIRECT*/ INTO "swt_rpt_stg".NS_Finance_Owner_ID_Hist SELECT * from "swt_rpt_stg".NS_Finance_Owner_ID;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select finance_owner_id_id,max(auto_id) as auto_id from swt_rpt_stg.NS_Finance_Owner_ID where finance_owner_id_id in (
select finance_owner_id_id from swt_rpt_stg.NS_Finance_Owner_ID group by finance_owner_id_id,last_modified_date having count(1)>1)
group by finance_owner_id_id);


delete from swt_rpt_stg.NS_Finance_Owner_ID where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.NS_Finance_Owner_ID.finance_owner_id_id=t2.finance_owner_id_id and swt_rpt_stg.NS_Finance_Owner_ID.auto_id<t2.auto_id);

commit;


CREATE LOCAL TEMP TABLE NS_Finance_Owner_ID_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NS_Finance_Owner_ID)
SEGMENTED BY HASH(finance_owner_id_id,last_modified_date) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.NS_Finance_Owner_ID;

CREATE LOCAL TEMP TABLE NS_Finance_Owner_ID_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT finance_owner_id_id,last_modified_date FROM swt_rpt_base.NS_Finance_Owner_ID)
SEGMENTED BY HASH(finance_owner_id_id,last_modified_date) ALL NODES;


CREATE LOCAL TEMP TABLE NS_Finance_Owner_ID_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT finance_owner_id_id, max(last_modified_date) as last_modified_date FROM NS_Finance_Owner_ID_stg_Tmp group by finance_owner_id_id)
SEGMENTED BY HASH(finance_owner_id_id,last_modified_date) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NS_Finance_Owner_ID_Hist
(
date_created
,finance_owner_description
,finance_owner_id_extid
,finance_owner_id_id
,finance_owner_id_name
,hierarchy_level
,is_inactive
,last_modified_date
,parent_id
,LD_DT
,SWT_INS_DT
,d_source
)
select
date_created
,finance_owner_description
,finance_owner_id_extid
,finance_owner_id_id
,finance_owner_id_name
,hierarchy_level
,is_inactive
,last_modified_date
,parent_id
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NS_Finance_Owner_ID WHERE finance_owner_id_id in
(SELECT STG.finance_owner_id_id FROM NS_Finance_Owner_ID_stg_Tmp_Key STG JOIN NS_Finance_Owner_ID_base_Tmp
ON STG.finance_owner_id_id = NS_Finance_Owner_ID_base_Tmp.finance_owner_id_id AND STG.last_modified_date >= NS_Finance_Owner_ID_base_Tmp.last_modified_date);




/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Finance_Owner_ID_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,now())::date;



/* Incremental VSQL script for loading data from Stage to Base */


DELETE /*+DIRECT*/ FROM "swt_rpt_base".NS_Finance_Owner_ID WHERE finance_owner_id_id in
(SELECT STG.finance_owner_id_id FROM NS_Finance_Owner_ID_stg_Tmp_Key STG JOIN NS_Finance_Owner_ID_base_Tmp
ON STG.finance_owner_id_id = NS_Finance_Owner_ID_base_Tmp.finance_owner_id_id AND STG.last_modified_date >= NS_Finance_Owner_ID_base_Tmp.last_modified_date);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Finance_Owner_ID
(
date_created
,finance_owner_description
,finance_owner_id_extid
,finance_owner_id_id
,finance_owner_id_name
,hierarchy_level
,is_inactive
,last_modified_date
,parent_id
,SWT_INS_DT
)
SELECT DISTINCT
date_created
,finance_owner_description
,finance_owner_id_extid
,NS_Finance_Owner_ID_stg_Tmp.finance_owner_id_id
,finance_owner_id_name
,hierarchy_level
,is_inactive
,NS_Finance_Owner_ID_stg_Tmp.last_modified_date
,parent_id
,SYSDATE AS SWT_INS_DT
FROM NS_Finance_Owner_ID_stg_Tmp JOIN NS_Finance_Owner_ID_stg_Tmp_Key ON NS_Finance_Owner_ID_stg_Tmp.finance_owner_id_id= NS_Finance_Owner_ID_stg_Tmp_Key.finance_owner_id_id AND NS_Finance_Owner_ID_stg_Tmp.last_modified_date=NS_Finance_Owner_ID_stg_Tmp_Key.last_modified_date
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NS_Finance_Owner_ID BASE
WHERE NS_Finance_Owner_ID_stg_Tmp.finance_owner_id_id = BASE.finance_owner_id_id);


/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Finance_Owner_ID' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Finance_Owner_ID' and  COMPLTN_STAT = 'N');

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
select 'NETSUITE','NS_Finance_Owner_ID',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.NS_Finance_Owner_ID where SWT_INS_DT::date = sysdate::date),'Y';

Commit;


SELECT PURGE_TABLE('swt_rpt_base.NS_Finance_Owner_ID');
SELECT PURGE_TABLE('swt_rpt_stg.NS_Finance_Owner_ID_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Finance_Owner_ID');


