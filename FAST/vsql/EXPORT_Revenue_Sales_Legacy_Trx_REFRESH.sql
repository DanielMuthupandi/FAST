\set ON_ERROR_STOP on
\timing
select add_vertica_options('EE', 'ENABLE_JOIN_SPILL');
TRUNCATE TABLE swt_rpt_export.STG_S_Revenue_Legacy_Order_Links_Incremental;

Insert /*+direct*/ Into swt_rpt_export.STG_S_Revenue_Legacy_Order_Links_Incremental
select * from swt_rpt_export.STG_S_Revenue_Legacy_Order_Links_Incremental_Vw;

commit;
select clr_vertica_options('EE', 'ENABLE_JOIN_SPILL');
Select Analyze_Histogram('swt_rpt_export.STG_S_Revenue_Legacy_Order_Links_Incremental',100);


