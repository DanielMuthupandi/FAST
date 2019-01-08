/****
****Script Name   : NS_Subsidiary_location_map.sql
****Description   : Truncate and data load for NS_Subsidiary_location_map
****/

/* Setting timing on**/
\timing
/**SET SESSION AUTOCOMMIT TO OFF;**/

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select sysdate st from dual;

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
  select 'NETSUITE','NS_Subsidiary_location_map',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NS_Subsidiary_location_map") ,null,'N';

  Commit;  




 /* Full load VSQL script for loading data from Stage to Base */  


TRUNCATE TABLE "swt_rpt_base".NS_Subsidiary_location_map;

/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NS_Subsidiary_location_map_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NS_Subsidiary_location_map
( 
location_id
,subsidiary_id
,SWT_INS_DT
)
SELECT
DISTINCT
location_id
,subsidiary_id
,SYSDATE AS SWT_INS_DT
FROM "swt_rpt_stg"."NS_Subsidiary_location_map";

/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITE' and
TBL_NM = 'NS_Subsidiary_location_map' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITE' and  TBL_NM = 'NS_Subsidiary_location_map' and  COMPLTN_STAT = 'N');
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
select 'NETSUITE','NS_Subsidiary_location_map',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NS_Subsidiary_location_map") ,(select count(*) from swt_rpt_base.NS_Subsidiary_location_map where SWT_INS_DT::date = sysdate::date),'Y';

   Commit;
   
INSERT /*+DIRECT*/ INTO swt_rpt_stg.NS_Subsidiary_Location_Map_Hist SELECT * FROM swt_rpt_stg.NS_Subsidiary_Location_Map;

COMMIT;

SELECT PURGE_TABLE('swt_rpt_stg.NS_Subsidiary_location_map_Hist');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NS_Subsidiary_location_map');

TRUNCATE TABLE swt_rpt_stg.NS_Subsidiary_Location_Map;
 
