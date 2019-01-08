/****
****Script Name	  : AT_SWT_Smart_Discounting__c.sql
****Description   : Incremental data load for AT_SWT_Smart_Discounting__c
****/

/* Setting timing on**/
\timing

--SET SESSION AUTOCOMMIT TO OFF;

\set ON_ERROR_STOP on

CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."AT_SWT_Smart_Discounting__c";

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
select 'APTTUS','AT_SWT_Smart_Discounting__c',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+DIRECT*/ INTO "swt_rpt_stg".AT_SWT_Smart_Discounting__c_Hist select * from "swt_rpt_stg".AT_SWT_Smart_Discounting__c;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.AT_SWT_Smart_Discounting__c where id in (
select id from swt_rpt_stg.AT_SWT_Smart_Discounting__c group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);

delete from swt_rpt_stg.AT_SWT_Smart_Discounting__c where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.AT_SWT_Smart_Discounting__c.id=t2.id and swt_rpt_stg.AT_SWT_Smart_Discounting__c.auto_id<t2.auto_id);

commit;

 CREATE LOCAL TEMP TABLE AT_SWT_Smart_Discounting__c_stg_Tmp ON COMMIT PRESERVE ROWS AS
( 
SELECT DISTINCT * FROM "swt_rpt_stg".AT_SWT_Smart_Discounting__c
) SEGMENTED BY HASH(id,LastModifiedDate) ALL NODES;

TRUNCATE TABLE swt_rpt_stg.AT_SWT_Smart_Discounting__c;

 CREATE LOCAL TEMP TABLE AT_SWT_Smart_Discounting__c_base_Tmp ON COMMIT PRESERVE ROWS AS
( 
SELECT DISTINCT id,LastModifiedDate FROM "swt_rpt_base".AT_SWT_Smart_Discounting__c
) SEGMENTED BY HASH(id,LastModifiedDate) ALL NODES;

  
CREATE LOCAL TEMP TABLE AT_SWT_Smart_Discounting__c_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT id, max(LastModifiedDate) as LastModifiedDate FROM AT_SWT_Smart_Discounting__c_stg_Tmp group by id
) SEGMENTED BY HASH(ID,LastModifiedDate) ALL NODES;


SELECT ANALYZE_STATISTICS('AT_SWT_Smart_Discounting__c_stg_Tmp');
SELECT ANALYZE_STATISTICS('AT_SWT_Smart_Discounting__c_base_Tmp');



/* Inserting deleted Stage table data into Historical Table */
INSERT /*+DIRECT*/ INTO "swt_rpt_stg".AT_SWT_Smart_Discounting__c_Hist
(
Id
,OwnerId
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastViewedDate
,LastReferencedDate
,SWT_L2_AMID__c
,SWT_L4_AMID__c
,SWT_Subregion__c
,SWT_Cross_Subregion__c
,SWT_BU__c
,SWT_Product_Line__c
,SWT_Center__c
,SWT_Family__c
,SWT_Type__c
,SWT_DB_Min__c
,SWT_DB_Max__c
,SWT_Disc_Expert__c
,SWT_Disc_Typical__c
,SWT_Disc_Floor__c
,SWT_Rule_Seq_Code__c
,SWT_Country__c
,SWT_Cross_Country__c
,Loyalty_2__c
,SWT_TAM_L2__c
,SWT_Customer_Segment_L2__c
,SWT_Verticle_L2__c
,SWT_Ind_L2__c
,SWT_Loyalty_4__c
,SWT_TAM_L4__c
,SWT_Customer_Segment_L4__c
,SWT_Verticle_L4__c
,SWT_Ind_L4__c
,SWT_L2_AMID_Segment__c
,SWT_L4_AMID_Segment__c
,SWT_CountryCheck__c
,SWT_StdRule_Country_n_Subregion__c
,SWT_L2R1_2_Country_and_Subregion__c
,SWT_L3R1_2_Country_and_Subregion__c
,SWT_Rule_Priority__c
,SWT_Rule_Seq_Digit__c
,SWT_Comments__c
,SWT_L3_Vertical2_and_Industry2__c
,SWT_L3_Vertical4_and_Industry4__c
,SWT_Region__c
,SWT_Default__c
,SWT_Rule_Priority1__c
,SWT_Tier1PartnerAccNum__c
,SWT_Rule_Seq_Digit1__c
,SWT_L2_Partner__c
,SWT_L4_Partner__c
,SWT_Pillar__c
,SWT_L4_AMID_Customer_Segment__c
,SWT_CMT__c
,SWT_L2_AMID_Customer_Segment__c
,SWT_Country_CMT__c
,SWT_Business_Area_Group_L2__c
,SWT_Business_Area_Group_L4__c
,SWT_CMT_1__c
,SWT_CMT_2__c
,SWT_Exclude_Countries__c
,SWT_Mapped_Product_Type__c
,LD_DT
,SWT_INS_DT
,d_source
)
SELECT 
Id
,OwnerId
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastViewedDate
,LastReferencedDate
,SWT_L2_AMID__c
,SWT_L4_AMID__c
,SWT_Subregion__c
,SWT_Cross_Subregion__c
,SWT_BU__c
,SWT_Product_Line__c
,SWT_Center__c
,SWT_Family__c
,SWT_Type__c
,SWT_DB_Min__c
,SWT_DB_Max__c
,SWT_Disc_Expert__c
,SWT_Disc_Typical__c
,SWT_Disc_Floor__c
,SWT_Rule_Seq_Code__c
,SWT_Country__c
,SWT_Cross_Country__c
,Loyalty_2__c
,SWT_TAM_L2__c
,SWT_Customer_Segment_L2__c
,SWT_Verticle_L2__c
,SWT_Ind_L2__c
,SWT_Loyalty_4__c
,SWT_TAM_L4__c
,SWT_Customer_Segment_L4__c
,SWT_Verticle_L4__c
,SWT_Ind_L4__c
,SWT_L2_AMID_Segment__c
,SWT_L4_AMID_Segment__c
,SWT_CountryCheck__c
,SWT_StdRule_Country_n_Subregion__c
,SWT_L2R1_2_Country_and_Subregion__c
,SWT_L3R1_2_Country_and_Subregion__c
,SWT_Rule_Priority__c
,SWT_Rule_Seq_Digit__c
,SWT_Comments__c
,SWT_L3_Vertical2_and_Industry2__c
,SWT_L3_Vertical4_and_Industry4__c
,SWT_Region__c
,SWT_Default__c
,SWT_Rule_Priority1__c
,SWT_Tier1PartnerAccNum__c
,SWT_Rule_Seq_Digit1__c
,SWT_L2_Partner__c
,SWT_L4_Partner__c
,SWT_Pillar__c
,SWT_L4_AMID_Customer_Segment__c
,SWT_CMT__c
,SWT_L2_AMID_Customer_Segment__c
,SWT_Country_CMT__c
,SWT_Business_Area_Group_L2__c
,SWT_Business_Area_Group_L4__c
,SWT_CMT_1__c
,SWT_CMT_2__c
,SWT_Exclude_Countries__c
,SWT_Mapped_Product_Type__c
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".AT_SWT_Smart_Discounting__c WHERE id in
(SELECT STG.id FROM AT_SWT_Smart_Discounting__c_stg_Tmp_Key STG JOIN  AT_SWT_Smart_Discounting__c_base_Tmp ON STG.id = AT_SWT_Smart_Discounting__c_base_Tmp.id 
AND STG.LastModifiedDate >= AT_SWT_Smart_Discounting__c_base_Tmp.LastModifiedDate);

/* Deleting before seven days data from current date in the Historical Table */

/*delete /*+DIRECT*/ from "swt_rpt_stg"."AT_SWT_Smart_Discounting__c_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;*/

/* Incremental VSQL script for loading data from Stage to Base */ 

DELETE /*+DIRECT*/ FROM "swt_rpt_base".AT_SWT_Smart_Discounting__c WHERE id in
(SELECT STG.id FROM AT_SWT_Smart_Discounting__c_stg_Tmp_Key STG JOIN  AT_SWT_Smart_Discounting__c_base_Tmp ON STG.id = AT_SWT_Smart_Discounting__c_base_Tmp.id 
AND STG.LastModifiedDate >= AT_SWT_Smart_Discounting__c_base_Tmp.LastModifiedDate);


INSERT /*+DIRECT*/ INTO "swt_rpt_base".AT_SWT_Smart_Discounting__c
(
Id
,OwnerId
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastViewedDate
,LastReferencedDate
,SWT_L2_AMID__c
,SWT_L4_AMID__c
,SWT_Subregion__c
,SWT_Cross_Subregion__c
,SWT_BU__c
,SWT_Product_Line__c
,SWT_Center__c
,SWT_Family__c
,SWT_Type__c
,SWT_DB_Min__c
,SWT_DB_Max__c
,SWT_Disc_Expert__c
,SWT_Disc_Typical__c
,SWT_Disc_Floor__c
,SWT_Rule_Seq_Code__c
,SWT_Country__c
,SWT_Cross_Country__c
,Loyalty_2__c
,SWT_TAM_L2__c
,SWT_Customer_Segment_L2__c
,SWT_Verticle_L2__c
,SWT_Ind_L2__c
,SWT_Loyalty_4__c
,SWT_TAM_L4__c
,SWT_Customer_Segment_L4__c
,SWT_Verticle_L4__c
,SWT_Ind_L4__c
,SWT_L2_AMID_Segment__c
,SWT_L4_AMID_Segment__c
,SWT_CountryCheck__c
,SWT_StdRule_Country_n_Subregion__c
,SWT_L2R1_2_Country_and_Subregion__c
,SWT_L3R1_2_Country_and_Subregion__c
,SWT_Rule_Priority__c
,SWT_Rule_Seq_Digit__c
,SWT_Comments__c
,SWT_L3_Vertical2_and_Industry2__c
,SWT_L3_Vertical4_and_Industry4__c
,SWT_Region__c
,SWT_Default__c
,SWT_Rule_Priority1__c
,SWT_Tier1PartnerAccNum__c
,SWT_Rule_Seq_Digit1__c
,SWT_L2_Partner__c
,SWT_L4_Partner__c
,SWT_Pillar__c
,SWT_L4_AMID_Customer_Segment__c
,SWT_CMT__c
,SWT_L2_AMID_Customer_Segment__c
,SWT_Country_CMT__c
,SWT_Business_Area_Group_L2__c
,SWT_Business_Area_Group_L4__c
,SWT_CMT_1__c
,SWT_CMT_2__c
,SWT_Exclude_Countries__c
,SWT_Mapped_Product_Type__c
,SWT_INS_DT
)
SELECT DISTINCT 
stg_Tmp.Id
,OwnerId
,IsDeleted
,Name
,CurrencyIsoCode
,CreatedDate
,CreatedById
,stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,LastViewedDate
,LastReferencedDate
,SWT_L2_AMID__c
,SWT_L4_AMID__c
,SWT_Subregion__c
,SWT_Cross_Subregion__c
,SWT_BU__c
,SWT_Product_Line__c
,SWT_Center__c
,SWT_Family__c
,SWT_Type__c
,SWT_DB_Min__c
,SWT_DB_Max__c
,SWT_Disc_Expert__c
,SWT_Disc_Typical__c
,SWT_Disc_Floor__c
,SWT_Rule_Seq_Code__c
,SWT_Country__c
,SWT_Cross_Country__c
,Loyalty_2__c
,SWT_TAM_L2__c
,SWT_Customer_Segment_L2__c
,SWT_Verticle_L2__c
,SWT_Ind_L2__c
,SWT_Loyalty_4__c
,SWT_TAM_L4__c
,SWT_Customer_Segment_L4__c
,SWT_Verticle_L4__c
,SWT_Ind_L4__c
,SWT_L2_AMID_Segment__c
,SWT_L4_AMID_Segment__c
,SWT_CountryCheck__c
,SWT_StdRule_Country_n_Subregion__c
,SWT_L2R1_2_Country_and_Subregion__c
,SWT_L3R1_2_Country_and_Subregion__c
,SWT_Rule_Priority__c
,SWT_Rule_Seq_Digit__c
,SWT_Comments__c
,SWT_L3_Vertical2_and_Industry2__c
,SWT_L3_Vertical4_and_Industry4__c
,SWT_Region__c
,SWT_Default__c
,SWT_Rule_Priority1__c
,SWT_Tier1PartnerAccNum__c
,SWT_Rule_Seq_Digit1__c
,SWT_L2_Partner__c
,SWT_L4_Partner__c
,SWT_Pillar__c
,SWT_L4_AMID_Customer_Segment__c
,SWT_CMT__c
,SWT_L2_AMID_Customer_Segment__c
,SWT_Country_CMT__c
,SWT_Business_Area_Group_L2__c
,SWT_Business_Area_Group_L4__c
,SWT_CMT_1__c
,SWT_CMT_2__c
,SWT_Exclude_Countries__c
,SWT_Mapped_Product_Type__c
,SYSDATE as SWT_INS_DT
FROM AT_SWT_Smart_Discounting__c_stg_Tmp stg_Tmp JOIN AT_SWT_Smart_Discounting__c_stg_Tmp_Key stg_Tmp_Key ON stg_Tmp.id = stg_Tmp_Key.id AND stg_Tmp.LastModifiedDate = stg_Tmp_Key.LastModifiedDate
	WHERE NOT EXISTS
	(SELECT 1 FROM "swt_rpt_base".AT_SWT_Smart_Discounting__c BASE
		WHERE stg_Tmp.id = BASE.id);

commit;	

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
select 'APTTUS','AT_SWT_Smart_Discounting__c',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.AT_SWT_Smart_Discounting__c where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

/* Deleting partial audit entry */
/*
DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'APTTUS' and
TBL_NM = 'AT_SWT_Smart_Discounting__c' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'APTTUS' and  TBL_NM = 'AT_SWT_Smart_Discounting__c' and  COMPLTN_STAT = 'N');
Commit;*/

SELECT DROP_PARTITIONS('swt_rpt_stg.AT_SWT_Smart_Discounting__c_Hist', TIMESTAMPADD(day,-7,getdate())::date);
/*select do_tm_task('mergeout','swt_rpt_stg.AT_SWT_Smart_Discounting__c_Hist');*/
select do_tm_task('mergeout','swt_rpt_base.AT_SWT_Smart_Discounting__c');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
SELECT ANALYZE_STATISTICS('swt_rpt_base.AT_SWT_Smart_Discounting__c');






