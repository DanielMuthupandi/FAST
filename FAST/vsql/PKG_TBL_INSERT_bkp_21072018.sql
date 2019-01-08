\set ON_ERROR_STOP on
\timing

select add_vertica_options('EE', 'ENABLE_JOIN_SPILL');
--delete /*+direct*/ from swt_rpt_pkg.Opportunity_Line_Item;
TRUNCATE TABLE swt_rpt_pkg.Opportunity_Line_Item;
Insert /*+direct*/ Into swt_rpt_pkg.Opportunity_Line_Item
Select * From swt_rpt_pkg.Opportunity_Line_Item_Vw;
Insert /*+direct*/ Into swt_rpt_pkg.Opportunity_Line_Item
Select * From swt_rpt_pkg.Opportunity_Line_Item_PS_Vw;

commit;
select clr_vertica_options('EE', 'ENABLE_JOIN_SPILL');
--SELECT DO_TM_TASK('mergeout', 'swt_rpt_pkg.Opportunity_Line_Item');
Select Analyze_Histogram('swt_rpt_pkg.Opportunity_Line_Item',100);

