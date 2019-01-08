\set ON_ERROR_STOP on
\timing

select add_vertica_options('EE', 'ENABLE_JOIN_SPILL');
TRUNCATE TABLE swt_rpt_pkg.STG_ATF_Sls_Ord_Mapping;
TRUNCATE TABLE swt_rpt_pkg.STG_ATF_Revenue_Links_Split;

Insert /*+direct*/ Into swt_rpt_pkg.STG_ATF_Sls_Ord_Mapping
Select * From swt_rpt_pkg.STG_ATF_Sls_Ord_Mapping_Vw;
Insert /*+direct*/ Into swt_rpt_pkg.STG_ATF_Revenue_Links_Split
Select * From swt_rpt_pkg.STG_ATF_Revenue_Links_Split_Vw;

commit;
select clr_vertica_options('EE', 'ENABLE_JOIN_SPILL');
Select Analyze_Histogram('swt_rpt_pkg.STG_ATF_Sls_Ord_Mapping',100);
Select Analyze_Histogram('swt_rpt_pkg.STG_ATF_Revenue_Links_Split',100);
