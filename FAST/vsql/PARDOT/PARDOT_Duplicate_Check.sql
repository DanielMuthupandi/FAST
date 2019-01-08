select 'PD_Prospect', count(*) from (select Prospect_Id,Count(*) from swt_rpt_base.PD_Prospect group by Prospect_Id Having Count(*)>1)A;
