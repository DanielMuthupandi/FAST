\set ON_ERROR_STOP on
\timing

select add_vertica_options('EE', 'ENABLE_JOIN_SPILL');

-- Populate Opportunity Line Item

TRUNCATE TABLE swt_rpt_pkg.Opportunity_Line_Item;

Insert /*+direct*/ Into swt_rpt_pkg.Opportunity_Line_Item
Select * From swt_rpt_pkg.Opportunity_Line_Item_Vw;
Insert /*+direct*/ Into swt_rpt_pkg.Opportunity_Line_Item
Select * From swt_rpt_pkg.Opportunity_Line_Item_PS_Vw;
Insert Into swt_rpt_pkg.Opportunity_Line_Item
Select * From swt_rpt_pkg.Opportunity_Line_Item_Trilead_Vw;
commit;

--SELECT DO_TM_TASK('mergeout', 'swt_rpt_pkg.Opportunity_Line_Item');
Select Analyze_Histogram('swt_rpt_pkg.Opportunity_Line_Item',100);
---------------------------------------------------------
-- Populate Opportunity Dimension

TRUNCATE TABLE swt_rpt_pkg.Opportunity_Dmsn;

Insert Into swt_rpt_pkg.Opportunity_Dmsn
Select * From swt_rpt_pkg.Opportunity_Dmsn_Vw;
Insert Into swt_rpt_pkg.Opportunity_Dmsn
Select * From swt_rpt_pkg.Opportunity_Dmsn_Trilead_Vw;
commit;

--SELECT DO_TM_TASK('mergeout', 'swt_rpt_pkg.Opportunity_Dmsn');
Select Analyze_Histogram('swt_rpt_pkg.Opportunity_Dmsn',100);

select clr_vertica_options('EE', 'ENABLE_JOIN_SPILL');
