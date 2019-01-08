\set ON_ERROR_STOP on
\timing
select add_vertica_options('EE', 'ENABLE_JOIN_SPILL');

TRUNCATE TABLE swt_rpt_export.STG_S_Rev_Adj_Links_Split;
TRUNCATE TABLE swt_rpt_export.STG_S_Rev_Adj_Incr_Trns_Id;
Insert /*+direct*/ Into swt_rpt_export.STG_S_Rev_Adj_Links_Split
Select * From swt_rpt_export.STG_S_Rev_Adj_Links_Split_Vw;
Insert /*+direct*/ Into swt_rpt_export.STG_S_Rev_Adj_Incr_Trns_Id
Select * From swt_rpt_export.STG_S_Rev_Adj_Incr_Trns_Id_Vw;

commit;
select clr_vertica_options('EE', 'ENABLE_JOIN_SPILL');
Select Analyze_Histogram('swt_rpt_export.STG_S_Rev_Adj_Links_Split',100);
Select Analyze_Histogram('swt_rpt_export.STG_S_Rev_Adj_Incr_Trns_Id',100);


