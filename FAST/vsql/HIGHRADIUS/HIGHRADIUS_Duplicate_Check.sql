select 'HR_Collections', count(*) from (select account_customer_number,Count(*) from swt_rpt_base.HR_Collections group by account_customer_number Having Count(*)>1)A;
select 'HR_Credit_information', count(*) from (select account_customer_number,Count(*) from swt_rpt_base.HR_Credit_information group by account_customer_number Having Count(*)>1)A;
select 'HR_Deductions', count(*) from (select pk_deduction_id,count(*) from swt_rpt_base.HR_Deductions group by pk_deduction_id having count(*)>1)A;
