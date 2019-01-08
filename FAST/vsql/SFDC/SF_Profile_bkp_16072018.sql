/****
****Script Name   : SF_Profile.sql
****Description   : Incremental data load for SF_Profile
****/

/*Setting timing on */
\timing

/* SET SESSION AUTOCOMMIT TO OFF; */

\set ON_ERROR_STOP on


CREATE LOCAL TEMP TABLE Start_Time_Tmp ON COMMIT PRESERVE ROWS AS select count(*) count, sysdate st from "swt_rpt_stg"."SF_Profile";

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
select 'SFDC','SF_Profile',sysdate::date,sysdate,null,(select count from Start_Time_Tmp) ,null,'N';

Commit;

INSERT /*+Direct*/ INTO swt_rpt_stg.SF_Profile_Hist SELECT * from swt_rpt_stg.SF_Profile;
COMMIT;

CREATE LOCAL TEMP TABLE duplicates_records ON COMMIT PRESERVE ROWS AS (
select id,max(auto_id) as auto_id from swt_rpt_stg.SF_Profile where id in (
select id from swt_rpt_stg.SF_Profile group by id,LASTMODIFIEDDATE having count(1)>1)
group by id);
delete from swt_rpt_stg.SF_Profile where exists(
select 1 from duplicates_records t2 where swt_rpt_stg.SF_Profile.id=t2.id and swt_rpt_stg.SF_Profile.auto_id<t2.auto_id);

Commit; 

CREATE LOCAL TEMP TABLE SF_Profile_stg_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT * FROM swt_rpt_stg.SF_Profile)
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;


TRUNCATE TABLE swt_rpt_stg.SF_Profile;

CREATE LOCAL TEMP TABLE SF_Profile_base_Tmp ON COMMIT PRESERVE ROWS AS
(
SELECT DISTINCT Id,LastModifiedDate FROM swt_rpt_base.SF_Profile)
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;


CREATE LOCAL TEMP TABLE SF_Profile_stg_Tmp_Key ON COMMIT PRESERVE ROWS AS
(
SELECT Id, max(LastModifiedDate) as LastModifiedDate FROM SF_Profile_stg_Tmp group by Id)
SEGMENTED BY HASH(Id,LastModifiedDate) ALL NODES;



/* Inserting Stage table data into Historical Table */

insert /*+DIRECT*/ into swt_rpt_stg.SF_Profile_Hist
(
Id
,Name
,PermissionsEmailSingle
,PermissionsEmailMass
,PermissionsEditTask
,PermissionsEditEvent
,PermissionsExportReport
,PermissionsImportPersonal
,PermissionsDataExport
,PermissionsManageUsers
,PermissionsEditPublicTemplates
,PermissionsModifyAllData
,PermissionsManageCases
,PermissionsMassInlineEdit
,PermissionsEditKnowledge
,PermissionsManageKnowledge
,PermissionsManageSolutions
,PermissionsCustomizeApplication
,PermissionsEditReadonlyFields
,PermissionsRunReports
,PermissionsViewSetup
,PermissionsTransferAnyEntity
,PermissionsNewReportBuilder
,PermissionsActivateContract
,PermissionsActivateOrder
,PermissionsImportLeads
,PermissionsManageLeads
,PermissionsTransferAnyLead
,PermissionsViewAllData
,PermissionsEditPublicDocuments
,PermissionsViewEncryptedData
,PermissionsEditBrandTemplates
,PermissionsEditHtmlTemplates
,PermissionsChatterInternalUser
,PermissionsManageTranslation
,PermissionsDeleteActivatedContract
,PermissionsChatterInviteExternalUsers
,PermissionsSendSitRequests
,PermissionsOverrideForecasts
,PermissionsViewAllForecasts
,PermissionsApiUserOnly
,PermissionsManageRemoteAccess
,PermissionsCanUseNewDashboardBuilder
,PermissionsManageCategories
,PermissionsConvertLeads
,PermissionsPasswordNeverExpires
,PermissionsUseTeamReassignWizards
,PermissionsEditActivatedOrders
,PermissionsInstallMultiforce
,PermissionsPublishMultiforce
,PermissionsManagePartners
,PermissionsChatterOwnGroups
,PermissionsEditOppLineItemUnitPrice
,PermissionsCreateMultiforce
,PermissionsBulkApiHardDelete
,PermissionsInboundMigrationToolsUser
,PermissionsSolutionImport
,PermissionsManageCallCenters
,PermissionsManageSynonyms
,PermissionsOutboundMigrationToolsUser
,PermissionsDelegatedPortalUserAdmin
,PermissionsViewContent
,PermissionsManageEmailClientConfig
,PermissionsEnableNotifications
,PermissionsManageDataIntegrations
,PermissionsDistributeFromPersWksp
,PermissionsViewDataCategories
,PermissionsManageDataCategories
,PermissionsAuthorApex
,PermissionsManageMobile
,PermissionsApiEnabled
,PermissionsManageCustomReportTypes
,PermissionsEditCaseComments
,PermissionsTransferAnyCase
,PermissionsContentAdministrator
,PermissionsCreateWorkspaces
,PermissionsManageContentPermissions
,PermissionsManageContentProperties
,PermissionsManageContentTypes
,PermissionsScheduleJob
,PermissionsManageExchangeConfig
,PermissionsManageAnalyticSnapshots
,PermissionsScheduleReports
,PermissionsManageBusinessHourHolidays
,PermissionsManageEntitlements
,PermissionsManageDynamicDashboards
,PermissionsManageInteraction
,PermissionsViewMyTeamsDashboards
,PermissionsModerateChatter
,PermissionsResetPasswords
,PermissionsFlowUFLRequired
,PermissionsCanInsertFeedSystemFields
,PermissionsManageKnowledgeImportExport
,PermissionsDeferSharingCalculations
,PermissionsEmailTemplateManagement
,PermissionsEmailAdministration
,PermissionsManageChatterMessages
,PermissionsAllowEmailIC
,PermissionsChatterFileLink
,PermissionsForceTwoFactor
,PermissionsViewEventLogFiles
,PermissionsManageNetworks
,PermissionsViewCaseInteraction
,PermissionsManageAuthProviders
,PermissionsRunFlow
,PermissionsViewGlobalHeader
,PermissionsManageQuotas
,PermissionsCreateCustomizeDashboards
,PermissionsCreateDashboardFolders
,PermissionsViewPublicDashboards
,PermissionsManageDashbdsInPubFolders
,PermissionsCreateCustomizeReports
,PermissionsCreateReportFolders
,PermissionsViewPublicReports
,PermissionsManageReportsInPubFolders
,PermissionsEditMyDashboards
,PermissionsEditMyReports
,PermissionsViewAllUsers
,PermissionsAllowUniversalSearch
,PermissionsConnectOrgToEnvironmentHub
,PermissionsCreateCustomizeFilters
,PermissionsModerateNetworkFeeds
,PermissionsModerateNetworkFiles
,PermissionsGovernNetworks
,PermissionsSalesConsole
,PermissionsTwoFactorApi
,PermissionsDeleteTopics
,PermissionsEditTopics
,PermissionsCreateTopics
,PermissionsAssignTopics
,PermissionsIdentityEnabled
,PermissionsIdentityConnect
,PermissionsAllowViewKnowledge
,PermissionsCreateWorkBadgeDefinition
,PermissionsManageSearchPromotionRules
,PermissionsCustomMobileAppsAccess
,PermissionsViewHelpLink
,PermissionsManageProfilesPermissionsets
,PermissionsAssignPermissionSets
,PermissionsManageRoles
,PermissionsManageIpAddresses
,PermissionsManageSharing
,PermissionsManageInternalUsers
,PermissionsManagePasswordPolicies
,PermissionsManageLoginAccessPolicies
,PermissionsManageCustomPermissions
,PermissionsManageUnlistedGroups
,PermissionsManageTwoFactor
,PermissionsLightningExperienceUser
,PermissionsConfigCustomRecs
,PermissionsSubmitMacrosAllowed
,PermissionsBulkMacrosAllowed
,PermissionsShareInternalArticles
,PermissionsModerateNetworkMessages
,PermissionsSendAnnouncementEmails
,PermissionsChatterEditOwnPost
,PermissionsChatterEditOwnRecordPost
,PermissionsWaveTrendReports
,PermissionsWaveTabularDownload
,PermissionsManageSandboxes
,PermissionsAutomaticActivityCapture
,PermissionsImportCustomObjects
,PermissionsSalesforceIQInbox
,PermissionsDelegatedTwoFactor
,PermissionsChatterComposeUiCodesnippet
,PermissionsSelectFilesFromSalesforce
,PermissionsModerateNetworkUsers
,PermissionsMergeTopics
,PermissionsSubscribeToLightningReports
,PermissionsManagePvtRptsAndDashbds
,PermissionsCampaignInfluence2
,PermissionsViewDataAssessment
,PermissionsCanApproveFeedPost
,PermissionsAllowViewEditConvertedLeads
,PermissionsSocialInsightsLogoAdmin
,PermissionsShowCompanyNameAsUserBadge
,PermissionsAccessCMC
,PermissionsViewHealthCheck
,PermissionsManageHealthCheck
,PermissionsViewAllActivities
,UserLicenseId
,UserType
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,Description
,LastViewedDate
,LastReferencedDate
,PermissionsContentWorkspaces
,PermissionsInsightsAppDashboardEditor
,PermissionsInsightsAppUser
,PermissionsInsightsAppAdmin
,PermissionsInsightsAppEltEditor
,PermissionsInsightsAppUploadUser
,PermissionsInsightsCreateApplication
,PermissionsManageSessionPermissionSets
,PermissionsManageTemplatedApp
,PermissionsUseTemplatedApp
,PermissionsSalesAnalyticsUser
,PermissionsServiceAnalyticsUser
,PermissionsCreateAuditFields
,PermissionsUpdateWithInactiveOwner
,PermissionsRemoveDirectMessageMembers
,PermissionsAddDirectMessageMembers
,PermissionsManageCertificates
,PermissionsPreventClassicExperience
,PermissionsHideReadByList
,PermissionsSubscribeReportToOtherUsers
,PermissionsLightningConsoleAllowedForUser
,PermissionsSubscribeReportsRunAsUser
,PermissionsEnableCommunityAppLauncher
,LD_DT
,SWT_INS_DT
,d_source
)
select
Id
,Name
,PermissionsEmailSingle
,PermissionsEmailMass
,PermissionsEditTask
,PermissionsEditEvent
,PermissionsExportReport
,PermissionsImportPersonal
,PermissionsDataExport
,PermissionsManageUsers
,PermissionsEditPublicTemplates
,PermissionsModifyAllData
,PermissionsManageCases
,PermissionsMassInlineEdit
,PermissionsEditKnowledge
,PermissionsManageKnowledge
,PermissionsManageSolutions
,PermissionsCustomizeApplication
,PermissionsEditReadonlyFields
,PermissionsRunReports
,PermissionsViewSetup
,PermissionsTransferAnyEntity
,PermissionsNewReportBuilder
,PermissionsActivateContract
,PermissionsActivateOrder
,PermissionsImportLeads
,PermissionsManageLeads
,PermissionsTransferAnyLead
,PermissionsViewAllData
,PermissionsEditPublicDocuments
,PermissionsViewEncryptedData
,PermissionsEditBrandTemplates
,PermissionsEditHtmlTemplates
,PermissionsChatterInternalUser
,PermissionsManageTranslation
,PermissionsDeleteActivatedContract
,PermissionsChatterInviteExternalUsers
,PermissionsSendSitRequests
,PermissionsOverrideForecasts
,PermissionsViewAllForecasts
,PermissionsApiUserOnly
,PermissionsManageRemoteAccess
,PermissionsCanUseNewDashboardBuilder
,PermissionsManageCategories
,PermissionsConvertLeads
,PermissionsPasswordNeverExpires
,PermissionsUseTeamReassignWizards
,PermissionsEditActivatedOrders
,PermissionsInstallMultiforce
,PermissionsPublishMultiforce
,PermissionsManagePartners
,PermissionsChatterOwnGroups
,PermissionsEditOppLineItemUnitPrice
,PermissionsCreateMultiforce
,PermissionsBulkApiHardDelete
,PermissionsInboundMigrationToolsUser
,PermissionsSolutionImport
,PermissionsManageCallCenters
,PermissionsManageSynonyms
,PermissionsOutboundMigrationToolsUser
,PermissionsDelegatedPortalUserAdmin
,PermissionsViewContent
,PermissionsManageEmailClientConfig
,PermissionsEnableNotifications
,PermissionsManageDataIntegrations
,PermissionsDistributeFromPersWksp
,PermissionsViewDataCategories
,PermissionsManageDataCategories
,PermissionsAuthorApex
,PermissionsManageMobile
,PermissionsApiEnabled
,PermissionsManageCustomReportTypes
,PermissionsEditCaseComments
,PermissionsTransferAnyCase
,PermissionsContentAdministrator
,PermissionsCreateWorkspaces
,PermissionsManageContentPermissions
,PermissionsManageContentProperties
,PermissionsManageContentTypes
,PermissionsScheduleJob
,PermissionsManageExchangeConfig
,PermissionsManageAnalyticSnapshots
,PermissionsScheduleReports
,PermissionsManageBusinessHourHolidays
,PermissionsManageEntitlements
,PermissionsManageDynamicDashboards
,PermissionsManageInteraction
,PermissionsViewMyTeamsDashboards
,PermissionsModerateChatter
,PermissionsResetPasswords
,PermissionsFlowUFLRequired
,PermissionsCanInsertFeedSystemFields
,PermissionsManageKnowledgeImportExport
,PermissionsDeferSharingCalculations
,PermissionsEmailTemplateManagement
,PermissionsEmailAdministration
,PermissionsManageChatterMessages
,PermissionsAllowEmailIC
,PermissionsChatterFileLink
,PermissionsForceTwoFactor
,PermissionsViewEventLogFiles
,PermissionsManageNetworks
,PermissionsViewCaseInteraction
,PermissionsManageAuthProviders
,PermissionsRunFlow
,PermissionsViewGlobalHeader
,PermissionsManageQuotas
,PermissionsCreateCustomizeDashboards
,PermissionsCreateDashboardFolders
,PermissionsViewPublicDashboards
,PermissionsManageDashbdsInPubFolders
,PermissionsCreateCustomizeReports
,PermissionsCreateReportFolders
,PermissionsViewPublicReports
,PermissionsManageReportsInPubFolders
,PermissionsEditMyDashboards
,PermissionsEditMyReports
,PermissionsViewAllUsers
,PermissionsAllowUniversalSearch
,PermissionsConnectOrgToEnvironmentHub
,PermissionsCreateCustomizeFilters
,PermissionsModerateNetworkFeeds
,PermissionsModerateNetworkFiles
,PermissionsGovernNetworks
,PermissionsSalesConsole
,PermissionsTwoFactorApi
,PermissionsDeleteTopics
,PermissionsEditTopics
,PermissionsCreateTopics
,PermissionsAssignTopics
,PermissionsIdentityEnabled
,PermissionsIdentityConnect
,PermissionsAllowViewKnowledge
,PermissionsCreateWorkBadgeDefinition
,PermissionsManageSearchPromotionRules
,PermissionsCustomMobileAppsAccess
,PermissionsViewHelpLink
,PermissionsManageProfilesPermissionsets
,PermissionsAssignPermissionSets
,PermissionsManageRoles
,PermissionsManageIpAddresses
,PermissionsManageSharing
,PermissionsManageInternalUsers
,PermissionsManagePasswordPolicies
,PermissionsManageLoginAccessPolicies
,PermissionsManageCustomPermissions
,PermissionsManageUnlistedGroups
,PermissionsManageTwoFactor
,PermissionsLightningExperienceUser
,PermissionsConfigCustomRecs
,PermissionsSubmitMacrosAllowed
,PermissionsBulkMacrosAllowed
,PermissionsShareInternalArticles
,PermissionsModerateNetworkMessages
,PermissionsSendAnnouncementEmails
,PermissionsChatterEditOwnPost
,PermissionsChatterEditOwnRecordPost
,PermissionsWaveTrendReports
,PermissionsWaveTabularDownload
,PermissionsManageSandboxes
,PermissionsAutomaticActivityCapture
,PermissionsImportCustomObjects
,PermissionsSalesforceIQInbox
,PermissionsDelegatedTwoFactor
,PermissionsChatterComposeUiCodesnippet
,PermissionsSelectFilesFromSalesforce
,PermissionsModerateNetworkUsers
,PermissionsMergeTopics
,PermissionsSubscribeToLightningReports
,PermissionsManagePvtRptsAndDashbds
,PermissionsCampaignInfluence2
,PermissionsViewDataAssessment
,PermissionsCanApproveFeedPost
,PermissionsAllowViewEditConvertedLeads
,PermissionsSocialInsightsLogoAdmin
,PermissionsShowCompanyNameAsUserBadge
,PermissionsAccessCMC
,PermissionsViewHealthCheck
,PermissionsManageHealthCheck
,PermissionsViewAllActivities
,UserLicenseId
,UserType
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,Description
,LastViewedDate
,LastReferencedDate
,PermissionsContentWorkspaces
,PermissionsInsightsAppDashboardEditor
,PermissionsInsightsAppUser
,PermissionsInsightsAppAdmin
,PermissionsInsightsAppEltEditor
,PermissionsInsightsAppUploadUser
,PermissionsInsightsCreateApplication
,PermissionsManageSessionPermissionSets
,PermissionsManageTemplatedApp
,PermissionsUseTemplatedApp
,PermissionsSalesAnalyticsUser
,PermissionsServiceAnalyticsUser
,PermissionsCreateAuditFields
,PermissionsUpdateWithInactiveOwner
,PermissionsRemoveDirectMessageMembers
,PermissionsAddDirectMessageMembers
,PermissionsManageCertificates
,PermissionsPreventClassicExperience
,PermissionsHideReadByList
,PermissionsSubscribeReportToOtherUsers
,PermissionsLightningConsoleAllowedForUser
,PermissionsSubscribeReportsRunAsUser
,PermissionsEnableCommunityAppLauncher
,SYSDATE AS LD_DT
,SWT_INS_DT
,'base'
FROM "swt_rpt_base".SF_Profile WHERE id in
(SELECT STG.id FROM SF_Profile_stg_Tmp_Key STG JOIN SF_Profile_base_Tmp
ON STG.id = SF_Profile_base_Tmp.id AND STG.LastModifiedDate >= SF_Profile_base_Tmp.LastModifiedDate);



/* Deleting before seven days data from current date in the Historical Table */

delete /*+DIRECT*/ from "swt_rpt_stg"."SF_Profile_Hist"  where LD_DT::date <= TIMESTAMPADD(DAY,-7,sysdate)::date;



/* Incremental VSQL script for loading data from Stage to Base */


DELETE /*+DIRECT*/ FROM "swt_rpt_base".SF_Profile WHERE id in
(SELECT STG.id FROM SF_Profile_stg_Tmp_Key STG JOIN SF_Profile_base_Tmp
ON STG.id = SF_Profile_base_Tmp.id AND STG.LastModifiedDate >= SF_Profile_base_Tmp.LastModifiedDate);

INSERT /*+DIRECT*/ INTO "swt_rpt_base".SF_Profile
(
Id
,Name
,PermissionsEmailSingle
,PermissionsEmailMass
,PermissionsEditTask
,PermissionsEditEvent
,PermissionsExportReport
,PermissionsImportPersonal
,PermissionsDataExport
,PermissionsManageUsers
,PermissionsEditPublicTemplates
,PermissionsModifyAllData
,PermissionsManageCases
,PermissionsMassInlineEdit
,PermissionsEditKnowledge
,PermissionsManageKnowledge
,PermissionsManageSolutions
,PermissionsCustomizeApplication
,PermissionsEditReadonlyFields
,PermissionsRunReports
,PermissionsViewSetup
,PermissionsTransferAnyEntity
,PermissionsNewReportBuilder
,PermissionsActivateContract
,PermissionsActivateOrder
,PermissionsImportLeads
,PermissionsManageLeads
,PermissionsTransferAnyLead
,PermissionsViewAllData
,PermissionsEditPublicDocuments
,PermissionsViewEncryptedData
,PermissionsEditBrandTemplates
,PermissionsEditHtmlTemplates
,PermissionsChatterInternalUser
,PermissionsManageTranslation
,PermissionsDeleteActivatedContract
,PermissionsChatterInviteExternalUsers
,PermissionsSendSitRequests
,PermissionsOverrideForecasts
,PermissionsViewAllForecasts
,PermissionsApiUserOnly
,PermissionsManageRemoteAccess
,PermissionsCanUseNewDashboardBuilder
,PermissionsManageCategories
,PermissionsConvertLeads
,PermissionsPasswordNeverExpires
,PermissionsUseTeamReassignWizards
,PermissionsEditActivatedOrders
,PermissionsInstallMultiforce
,PermissionsPublishMultiforce
,PermissionsManagePartners
,PermissionsChatterOwnGroups
,PermissionsEditOppLineItemUnitPrice
,PermissionsCreateMultiforce
,PermissionsBulkApiHardDelete
,PermissionsInboundMigrationToolsUser
,PermissionsSolutionImport
,PermissionsManageCallCenters
,PermissionsManageSynonyms
,PermissionsOutboundMigrationToolsUser
,PermissionsDelegatedPortalUserAdmin
,PermissionsViewContent
,PermissionsManageEmailClientConfig
,PermissionsEnableNotifications
,PermissionsManageDataIntegrations
,PermissionsDistributeFromPersWksp
,PermissionsViewDataCategories
,PermissionsManageDataCategories
,PermissionsAuthorApex
,PermissionsManageMobile
,PermissionsApiEnabled
,PermissionsManageCustomReportTypes
,PermissionsEditCaseComments
,PermissionsTransferAnyCase
,PermissionsContentAdministrator
,PermissionsCreateWorkspaces
,PermissionsManageContentPermissions
,PermissionsManageContentProperties
,PermissionsManageContentTypes
,PermissionsScheduleJob
,PermissionsManageExchangeConfig
,PermissionsManageAnalyticSnapshots
,PermissionsScheduleReports
,PermissionsManageBusinessHourHolidays
,PermissionsManageEntitlements
,PermissionsManageDynamicDashboards
,PermissionsManageInteraction
,PermissionsViewMyTeamsDashboards
,PermissionsModerateChatter
,PermissionsResetPasswords
,PermissionsFlowUFLRequired
,PermissionsCanInsertFeedSystemFields
,PermissionsManageKnowledgeImportExport
,PermissionsDeferSharingCalculations
,PermissionsEmailTemplateManagement
,PermissionsEmailAdministration
,PermissionsManageChatterMessages
,PermissionsAllowEmailIC
,PermissionsChatterFileLink
,PermissionsForceTwoFactor
,PermissionsViewEventLogFiles
,PermissionsManageNetworks
,PermissionsViewCaseInteraction
,PermissionsManageAuthProviders
,PermissionsRunFlow
,PermissionsViewGlobalHeader
,PermissionsManageQuotas
,PermissionsCreateCustomizeDashboards
,PermissionsCreateDashboardFolders
,PermissionsViewPublicDashboards
,PermissionsManageDashbdsInPubFolders
,PermissionsCreateCustomizeReports
,PermissionsCreateReportFolders
,PermissionsViewPublicReports
,PermissionsManageReportsInPubFolders
,PermissionsEditMyDashboards
,PermissionsEditMyReports
,PermissionsViewAllUsers
,PermissionsAllowUniversalSearch
,PermissionsConnectOrgToEnvironmentHub
,PermissionsCreateCustomizeFilters
,PermissionsModerateNetworkFeeds
,PermissionsModerateNetworkFiles
,PermissionsGovernNetworks
,PermissionsSalesConsole
,PermissionsTwoFactorApi
,PermissionsDeleteTopics
,PermissionsEditTopics
,PermissionsCreateTopics
,PermissionsAssignTopics
,PermissionsIdentityEnabled
,PermissionsIdentityConnect
,PermissionsAllowViewKnowledge
,PermissionsCreateWorkBadgeDefinition
,PermissionsManageSearchPromotionRules
,PermissionsCustomMobileAppsAccess
,PermissionsViewHelpLink
,PermissionsManageProfilesPermissionsets
,PermissionsAssignPermissionSets
,PermissionsManageRoles
,PermissionsManageIpAddresses
,PermissionsManageSharing
,PermissionsManageInternalUsers
,PermissionsManagePasswordPolicies
,PermissionsManageLoginAccessPolicies
,PermissionsManageCustomPermissions
,PermissionsManageUnlistedGroups
,PermissionsManageTwoFactor
,PermissionsLightningExperienceUser
,PermissionsConfigCustomRecs
,PermissionsSubmitMacrosAllowed
,PermissionsBulkMacrosAllowed
,PermissionsShareInternalArticles
,PermissionsModerateNetworkMessages
,PermissionsSendAnnouncementEmails
,PermissionsChatterEditOwnPost
,PermissionsChatterEditOwnRecordPost
,PermissionsWaveTrendReports
,PermissionsWaveTabularDownload
,PermissionsManageSandboxes
,PermissionsAutomaticActivityCapture
,PermissionsImportCustomObjects
,PermissionsSalesforceIQInbox
,PermissionsDelegatedTwoFactor
,PermissionsChatterComposeUiCodesnippet
,PermissionsSelectFilesFromSalesforce
,PermissionsModerateNetworkUsers
,PermissionsMergeTopics
,PermissionsSubscribeToLightningReports
,PermissionsManagePvtRptsAndDashbds
,PermissionsCampaignInfluence2
,PermissionsViewDataAssessment
,PermissionsCanApproveFeedPost
,PermissionsAllowViewEditConvertedLeads
,PermissionsSocialInsightsLogoAdmin
,PermissionsShowCompanyNameAsUserBadge
,PermissionsAccessCMC
,PermissionsViewHealthCheck
,PermissionsManageHealthCheck
,PermissionsViewAllActivities
,UserLicenseId
,UserType
,CreatedDate
,CreatedById
,LastModifiedDate
,LastModifiedById
,SystemModstamp
,Description
,LastViewedDate
,LastReferencedDate
,PermissionsContentWorkspaces
,PermissionsInsightsAppDashboardEditor
,PermissionsInsightsAppUser
,PermissionsInsightsAppAdmin
,PermissionsInsightsAppEltEditor
,PermissionsInsightsAppUploadUser
,PermissionsInsightsCreateApplication
,PermissionsManageSessionPermissionSets
,PermissionsManageTemplatedApp
,PermissionsUseTemplatedApp
,PermissionsSalesAnalyticsUser
,PermissionsServiceAnalyticsUser
,PermissionsCreateAuditFields
,PermissionsUpdateWithInactiveOwner
,PermissionsRemoveDirectMessageMembers
,PermissionsAddDirectMessageMembers
,PermissionsManageCertificates
,PermissionsPreventClassicExperience
,PermissionsHideReadByList
,PermissionsSubscribeReportToOtherUsers
,PermissionsLightningConsoleAllowedForUser
,PermissionsSubscribeReportsRunAsUser
,PermissionsEnableCommunityAppLauncher
,SWT_INS_DT
)
SELECT DISTINCT
SF_Profile_stg_Tmp.Id
,Name
,PermissionsEmailSingle
,PermissionsEmailMass
,PermissionsEditTask
,PermissionsEditEvent
,PermissionsExportReport
,PermissionsImportPersonal
,PermissionsDataExport
,PermissionsManageUsers
,PermissionsEditPublicTemplates
,PermissionsModifyAllData
,PermissionsManageCases
,PermissionsMassInlineEdit
,PermissionsEditKnowledge
,PermissionsManageKnowledge
,PermissionsManageSolutions
,PermissionsCustomizeApplication
,PermissionsEditReadonlyFields
,PermissionsRunReports
,PermissionsViewSetup
,PermissionsTransferAnyEntity
,PermissionsNewReportBuilder
,PermissionsActivateContract
,PermissionsActivateOrder
,PermissionsImportLeads
,PermissionsManageLeads
,PermissionsTransferAnyLead
,PermissionsViewAllData
,PermissionsEditPublicDocuments
,PermissionsViewEncryptedData
,PermissionsEditBrandTemplates
,PermissionsEditHtmlTemplates
,PermissionsChatterInternalUser
,PermissionsManageTranslation
,PermissionsDeleteActivatedContract
,PermissionsChatterInviteExternalUsers
,PermissionsSendSitRequests
,PermissionsOverrideForecasts
,PermissionsViewAllForecasts
,PermissionsApiUserOnly
,PermissionsManageRemoteAccess
,PermissionsCanUseNewDashboardBuilder
,PermissionsManageCategories
,PermissionsConvertLeads
,PermissionsPasswordNeverExpires
,PermissionsUseTeamReassignWizards
,PermissionsEditActivatedOrders
,PermissionsInstallMultiforce
,PermissionsPublishMultiforce
,PermissionsManagePartners
,PermissionsChatterOwnGroups
,PermissionsEditOppLineItemUnitPrice
,PermissionsCreateMultiforce
,PermissionsBulkApiHardDelete
,PermissionsInboundMigrationToolsUser
,PermissionsSolutionImport
,PermissionsManageCallCenters
,PermissionsManageSynonyms
,PermissionsOutboundMigrationToolsUser
,PermissionsDelegatedPortalUserAdmin
,PermissionsViewContent
,PermissionsManageEmailClientConfig
,PermissionsEnableNotifications
,PermissionsManageDataIntegrations
,PermissionsDistributeFromPersWksp
,PermissionsViewDataCategories
,PermissionsManageDataCategories
,PermissionsAuthorApex
,PermissionsManageMobile
,PermissionsApiEnabled
,PermissionsManageCustomReportTypes
,PermissionsEditCaseComments
,PermissionsTransferAnyCase
,PermissionsContentAdministrator
,PermissionsCreateWorkspaces
,PermissionsManageContentPermissions
,PermissionsManageContentProperties
,PermissionsManageContentTypes
,PermissionsScheduleJob
,PermissionsManageExchangeConfig
,PermissionsManageAnalyticSnapshots
,PermissionsScheduleReports
,PermissionsManageBusinessHourHolidays
,PermissionsManageEntitlements
,PermissionsManageDynamicDashboards
,PermissionsManageInteraction
,PermissionsViewMyTeamsDashboards
,PermissionsModerateChatter
,PermissionsResetPasswords
,PermissionsFlowUFLRequired
,PermissionsCanInsertFeedSystemFields
,PermissionsManageKnowledgeImportExport
,PermissionsDeferSharingCalculations
,PermissionsEmailTemplateManagement
,PermissionsEmailAdministration
,PermissionsManageChatterMessages
,PermissionsAllowEmailIC
,PermissionsChatterFileLink
,PermissionsForceTwoFactor
,PermissionsViewEventLogFiles
,PermissionsManageNetworks
,PermissionsViewCaseInteraction
,PermissionsManageAuthProviders
,PermissionsRunFlow
,PermissionsViewGlobalHeader
,PermissionsManageQuotas
,PermissionsCreateCustomizeDashboards
,PermissionsCreateDashboardFolders
,PermissionsViewPublicDashboards
,PermissionsManageDashbdsInPubFolders
,PermissionsCreateCustomizeReports
,PermissionsCreateReportFolders
,PermissionsViewPublicReports
,PermissionsManageReportsInPubFolders
,PermissionsEditMyDashboards
,PermissionsEditMyReports
,PermissionsViewAllUsers
,PermissionsAllowUniversalSearch
,PermissionsConnectOrgToEnvironmentHub
,PermissionsCreateCustomizeFilters
,PermissionsModerateNetworkFeeds
,PermissionsModerateNetworkFiles
,PermissionsGovernNetworks
,PermissionsSalesConsole
,PermissionsTwoFactorApi
,PermissionsDeleteTopics
,PermissionsEditTopics
,PermissionsCreateTopics
,PermissionsAssignTopics
,PermissionsIdentityEnabled
,PermissionsIdentityConnect
,PermissionsAllowViewKnowledge
,PermissionsCreateWorkBadgeDefinition
,PermissionsManageSearchPromotionRules
,PermissionsCustomMobileAppsAccess
,PermissionsViewHelpLink
,PermissionsManageProfilesPermissionsets
,PermissionsAssignPermissionSets
,PermissionsManageRoles
,PermissionsManageIpAddresses
,PermissionsManageSharing
,PermissionsManageInternalUsers
,PermissionsManagePasswordPolicies
,PermissionsManageLoginAccessPolicies
,PermissionsManageCustomPermissions
,PermissionsManageUnlistedGroups
,PermissionsManageTwoFactor
,PermissionsLightningExperienceUser
,PermissionsConfigCustomRecs
,PermissionsSubmitMacrosAllowed
,PermissionsBulkMacrosAllowed
,PermissionsShareInternalArticles
,PermissionsModerateNetworkMessages
,PermissionsSendAnnouncementEmails
,PermissionsChatterEditOwnPost
,PermissionsChatterEditOwnRecordPost
,PermissionsWaveTrendReports
,PermissionsWaveTabularDownload
,PermissionsManageSandboxes
,PermissionsAutomaticActivityCapture
,PermissionsImportCustomObjects
,PermissionsSalesforceIQInbox
,PermissionsDelegatedTwoFactor
,PermissionsChatterComposeUiCodesnippet
,PermissionsSelectFilesFromSalesforce
,PermissionsModerateNetworkUsers
,PermissionsMergeTopics
,PermissionsSubscribeToLightningReports
,PermissionsManagePvtRptsAndDashbds
,PermissionsCampaignInfluence2
,PermissionsViewDataAssessment
,PermissionsCanApproveFeedPost
,PermissionsAllowViewEditConvertedLeads
,PermissionsSocialInsightsLogoAdmin
,PermissionsShowCompanyNameAsUserBadge
,PermissionsAccessCMC
,PermissionsViewHealthCheck
,PermissionsManageHealthCheck
,PermissionsViewAllActivities
,UserLicenseId
,UserType
,CreatedDate
,CreatedById
,SF_Profile_stg_Tmp.LastModifiedDate
,LastModifiedById
,SystemModstamp
,Description
,LastViewedDate
,LastReferencedDate
,PermissionsContentWorkspaces
,PermissionsInsightsAppDashboardEditor
,PermissionsInsightsAppUser
,PermissionsInsightsAppAdmin
,PermissionsInsightsAppEltEditor
,PermissionsInsightsAppUploadUser
,PermissionsInsightsCreateApplication
,PermissionsManageSessionPermissionSets
,PermissionsManageTemplatedApp
,PermissionsUseTemplatedApp
,PermissionsSalesAnalyticsUser
,PermissionsServiceAnalyticsUser
,PermissionsCreateAuditFields
,PermissionsUpdateWithInactiveOwner
,PermissionsRemoveDirectMessageMembers
,PermissionsAddDirectMessageMembers
,PermissionsManageCertificates
,PermissionsPreventClassicExperience
,PermissionsHideReadByList
,PermissionsSubscribeReportToOtherUsers
,PermissionsLightningConsoleAllowedForUser
,PermissionsSubscribeReportsRunAsUser
,PermissionsEnableCommunityAppLauncher
,SYSDATE
FROM SF_Profile_stg_Tmp JOIN SF_Profile_stg_Tmp_Key ON SF_Profile_stg_Tmp.Id= SF_Profile_stg_Tmp_Key.Id AND SF_Profile_stg_Tmp.LastModifiedDate=SF_Profile_stg_Tmp_Key.LastModifiedDate
WHERE NOT EXISTS
(SELECT 1 FROM "swt_rpt_base".SF_Profile BASE
WHERE SF_Profile_stg_Tmp.Id = BASE.Id);


/* Deleting partial audit entry */

DELETE FROM swt_rpt_stg.FAST_LD_AUDT where SUBJECT_AREA = 'SFDC' and
TBL_NM = 'SF_Profile' and
COMPLTN_STAT = 'N' and
LD_DT=sysdate::date and 
SEQ_ID = (select max(SEQ_ID) from swt_rpt_stg.FAST_LD_AUDT where  SUBJECT_AREA = 'SFDC' and  TBL_NM = 'SF_Profile' and  COMPLTN_STAT = 'N');


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
select 'SFDC','SF_Profile',sysdate::date,(select st from Start_Time_Tmp),sysdate,(select count from Start_Time_Tmp) ,(select count(*) from swt_rpt_base.SF_Profile where SWT_INS_DT::date = sysdate::date),'Y';

Commit;

select do_tm_task('mergeout','swt_rpt_stg.SF_Profile_Hist');
select do_tm_task('mergeout','swt_rpt_base.SF_Profile');
select do_tm_task('mergeout','swt_rpt_stg.FAST_LD_AUDT');
select ANALYZE_STATISTICS('swt_rpt_base.SF_Profile');


