/*
****Script Name	  : WD_Employee.sql
****Description   : To find duplicates in WORDAY base table
****/
select 'WD_Employee',count(*)  from 
(
select EXTERNALID,count(*) from swt_rpt_base.WD_Employee
group by EXTERNALID
having count(*)>1
)a;
