/****
****Script Name   : NO_Projectbillingrule.sql
****Description   : Incremental data load for NO_Projectbillingrule
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
select 'NETSUITEOPENAIR','NO_Projectbillingrule',sysdate::date,sysdate,null,(select count(*) from "swt_rpt_stg"."NO_Projectbillingrule") ,null,'N';

Commit;



CREATE LOCAL TEMP TABLE NO_Projectbillingrule_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.NO_Projectbillingrule)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Projectbillingrule_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,Updated FROM swt_rpt_base.NO_Projectbillingrule)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


CREATE LOCAL TEMP TABLE NO_Projectbillingrule_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(Updated) as Updated FROM NO_Projectbillingrule_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,Updated) ALL NODES;


/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.NO_Projectbillingrule_Hist
(
id
,created
,updated
,name
,user_filter
,cap_hours
,backout_gst
,markup_type
,percent
,end_milestone
,daily_roll_to_next
,category_filter
,exclude_non_reimbursable
,percent_how
,adjust_if_capped
,slip_stageid
,markup_category
,timetype_filter
,cap
,daily_cap_period
,active
,description
,categoryid
,start_milestone
,end_date
,rate_from
,type
,agreementid
,customerpoid
,item_filter
,position
,rate_multiplier
,project_task_filter
,rate_cardid
,product_filter
,currency
,repeatid
,exclude_archived_ts
,exclude_non_billable
,markup
,start_date
,category_when
,projectid
,stop_if_capped
,amount
,daily_cap_is_per_user
,acct_date
,acct_date_how
,accounting_period_id
,daily_cap_hours
,cost_center_id
,customerid
,daily_rate_multiplier
,job_code_filter
,category_1id
,category_2id
,category_3id
,category_4id
,category_5id
,exclude_non_billable_task
,assigned_user
,ticket_maximums
,round_rules
,LD_DT
,SWT_INS_DT
,d_source
)
select
id
,created
,updated
,name
,user_filter
,cap_hours
,backout_gst
,markup_type
,percent
,end_milestone
,daily_roll_to_next
,category_filter
,exclude_non_reimbursable
,percent_how
,adjust_if_capped
,slip_stageid
,markup_category
,timetype_filter
,cap
,daily_cap_period
,active
,description
,categoryid
,start_milestone
,end_date
,rate_from
,type
,agreementid
,customerpoid
,item_filter
,position
,rate_multiplier
,project_task_filter
,rate_cardid
,product_filter
,currency
,repeatid
,exclude_archived_ts
,exclude_non_billable
,markup
,start_date
,category_when
,projectid
,stop_if_capped
,amount
,daily_cap_is_per_user
,acct_date
,acct_date_how
,accounting_period_id
,daily_cap_hours
,cost_center_id
,customerid
,daily_rate_multiplier
,job_code_filter
,category_1id
,category_2id
,category_3id
,category_4id
,category_5id
,exclude_non_billable_task
,assigned_user
,ticket_maximums
,round_rules
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".NO_Projectbillingrule WHERE id in
(SELECT STG.id FROM NO_Projectbillingrule_stg_Tmp_Key STG JOIN NO_Projectbillingrule_base_Tmp
ON STG.id = NO_Projectbillingrule_base_Tmp.id AND STG.updated >= NO_Projectbillingrule_base_Tmp.updated);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."NO_Projectbillingrule_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;


/* Incremental VSQL script for loading data from Stage to Base */

DELETE /*+DIRECT*/ FROM "swt_rpt_base".NO_Projectbillingrule WHERE id in
(SELECT STG.id FROM NO_Projectbillingrule_stg_Tmp_Key STG JOIN NO_Projectbillingrule_base_Tmp
ON STG.id = NO_Projectbillingrule_base_Tmp.id AND STG.updated >= NO_Projectbillingrule_base_Tmp.updated);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".NO_Projectbillingrule
(
id
,created
,updated
,name
,user_filter
,cap_hours
,backout_gst
,markup_type
,percent
,end_milestone
,daily_roll_to_next
,category_filter
,exclude_non_reimbursable
,percent_how
,adjust_if_capped
,slip_stageid
,markup_category
,timetype_filter
,cap
,daily_cap_period
,active
,description
,categoryid
,start_milestone
,end_date
,rate_from
,type
,agreementid
,customerpoid
,item_filter
,position
,rate_multiplier
,project_task_filter
,rate_cardid
,product_filter
,currency
,repeatid
,exclude_archived_ts
,exclude_non_billable
,markup
,start_date
,category_when
,projectid
,stop_if_capped
,amount
,daily_cap_is_per_user
,acct_date
,acct_date_how
,accounting_period_id
,daily_cap_hours
,cost_center_id
,customerid
,daily_rate_multiplier
,job_code_filter
,category_1id
,category_2id
,category_3id
,category_4id
,category_5id
,exclude_non_billable_task
,assigned_user
,ticket_maximums
,round_rules
,SWT_INS_DT
)
SELECT DISTINCT
NO_Projectbillingrule_stg_Tmp.id
,created
,NO_Projectbillingrule_stg_Tmp.updated
,name
,user_filter
,cap_hours
,backout_gst
,markup_type
,percent
,end_milestone
,daily_roll_to_next
,category_filter
,exclude_non_reimbursable
,percent_how
,adjust_if_capped
,slip_stageid
,markup_category
,timetype_filter
,cap
,daily_cap_period
,active
,description
,categoryid
,start_milestone
,end_date
,rate_from
,type
,agreementid
,customerpoid
,item_filter
,position
,rate_multiplier
,project_task_filter
,rate_cardid
,product_filter
,currency
,repeatid
,exclude_archived_ts
,exclude_non_billable
,markup
,start_date
,category_when
,projectid
,stop_if_capped
,amount
,daily_cap_is_per_user
,acct_date
,acct_date_how
,accounting_period_id
,daily_cap_hours
,cost_center_id
,customerid
,daily_rate_multiplier
,job_code_filter
,category_1id
,category_2id
,category_3id
,category_4id
,category_5id
,exclude_non_billable_task
,assigned_user
,ticket_maximums
,round_rules
,SYSDATE AS SWT_INS_DT
FROM NO_Projectbillingrule_stg_Tmp JOIN NO_Projectbillingrule_stg_Tmp_Key ON NO_Projectbillingrule_stg_Tmp.Id= NO_Projectbillingrule_stg_Tmp_Key.Id AND NO_Projectbillingrule_stg_Tmp.Updated=NO_Projectbillingrule_stg_Tmp_Key.Updated
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".NO_Projectbillingrule BASE
WHERE NO_Projectbillingrule_stg_Tmp.Id = BASE.Id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'NETSUITEOPENAIR' and
TBL_NM = 'NO_Projectbillingrule' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'NETSUITEOPENAIR' and  TBL_NM = 'NO_Projectbillingrule' and  COMPLTN_STAT = 'N');


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
select 'NETSUITEOPENAIR','NO_Projectbillingrule',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count(*) from "swt_rpt_stg"."NO_Projectbillingrule") ,(select count(*) from swt_rpt_base.NO_Projectbillingrule where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

select do_tm_task('mergeout','swt_rpt_stg.NO_Projectbillingrule_Hist');
select do_tm_task('mergeout','swt_rpt_base.NO_Projectbillingrule');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.NO_Projectbillingrule');
INSERT /*+Direct*/ INTO swt_rpt_stg.NO_Projectbillingrule_Hist SELECT * from swt_rpt_stg.NO_Projectbillingrule;
COMMIT;
TRUNCATE TABLE swt_rpt_stg.NO_Projectbillingrule;
