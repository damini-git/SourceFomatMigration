import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import fetchParentOrgOfRefreshTemplate from '@salesforce/apex/PreRefreshAutomationClass.fetchParentOrgOfRefreshTemplate';
import fetchSourceOrgsForRefresh from '@salesforce/apex/PreRefreshAutomationClass.fetchSourceOrgsForRefresh';
import fetchAllCustomObjects from '@salesforce/apex/PreRefreshAutomationClass.fetchAllCustomObjects';
import fetchFieldsOfObject from '@salesforce/apex/PreRefreshAutomationClass.fetchFieldsOfObject1';
import checkDataRetrievalStatus from '@salesforce/apex/CSVFileReader.checkDataRetrievalStatus';
import checkCustomSettingRetrieveStatus from '@salesforce/apex/PreRefreshAutomationClass.checkCustomSettingRetrieveStatus';
import callRefreshSandboxQueueable from '@salesforce/apex/SandboxRefreshClass.callRefreshSandboxQueueable';
import getSandboxStatus from '@salesforce/apex/SandboxRefreshClass.getSandboxStatus';
import fetchPublicGroupOfSource from '@salesforce/apex/SandboxRefreshClass.fetchPublicGroupOfSource';
import reAuthenticate from '@salesforce/apex/AuthorizationCodeFlowForSRA.auth';

import validatePackage from '@salesforce/apex/SandboxRefreshClass.validatePackage';
import checkValidationStatus from '@salesforce/apex/SandboxRefreshClass.checkValidationStatus';
import getValidationResult from '@salesforce/apex/SandboxRefreshClass.getValidationResult';
import checkDeploymentStatus from '@salesforce/apex/SandboxRefreshClass.checkDeploymentStatus';
import deployPackage from '@salesforce/apex/SandboxRefreshClass.deployPackage';
import getDeployLogRecord from '@salesforce/apex/SandboxRefreshClass.getDeployLogRecord';
import getDeployLogRecordofRefreshTemplate from '@salesforce/apex/SandboxRefreshClass.getDeployLogRecordofRefreshTemplate';
//import fetchMetadataMaskingTemplate from '@salesforce/apex/PostRefreshAutomationClass.fetchMetadataMaskingTemplate';
//import callFindAndReplaceQueueable from '@salesforce/apex/PostRefreshAutomationClass.callFindAndReplaceQueueable';

////Data Restore///
import { CurrentPageReference } from 'lightning/navigation';
import readJSONFromRelatedFiles from '@salesforce/apex/JSONFileReader.readJSONFromRelatedFiles';
//import readCSVFromRelatedFiles from '@salesforce/apex/CSVFileReader.readCSVFromRelatedFiles';
import getScheduleJobCSVData from '@salesforce/apex/CSVFileReader.getScheduleJobCSVData';
import fetchTargetOrgSandbox from '@salesforce/apex/CSVFileReader.fetchTargetOrgSandbox';
import fetchCreatedDate from '@salesforce/apex/CSVFileReader.fetchCreatedDate';
import fetchCustomSettings from '@salesforce/apex/CSVFileReader.fetchCustomSettings';
import saveSelectedCustomSettings from '@salesforce/apex/CustomSettingsRestorationCall.callCustomSettingsBatch';
import executeUserAssignmentsRestoration from '@salesforce/apex/PostRefreshUserRestorationCall.callRestoreBatch';
import executeScheduleJobsRestoration from '@salesforce/apex/PostRefreshAutomationClass.initiateScheduleJobRestoration';
import executeDeleteScheduleJobsRestoration from '@salesforce/apex/PostRefreshAutomationClass.abortScheduledJobsViaExecuteAnonymous';
import getTargetRefreshOrg from '@salesforce/apex/PreRefreshAutomationClass.getTargetRefreshOrg';
import applyDataMasking from '@salesforce/apex/PostRefreshAutomationClass.applyDataMasking';
import getValidationLogRecordofRefreshTemplate from '@salesforce/apex/SandboxRefreshClass.getValidationLogRecordofRefreshTemplate';
import getRefreshLogRecordofRefreshTemplate from '@salesforce/apex/SandboxRefreshClass.getRefreshLogRecordofRefreshTemplate';
import checkForMetadataZipFiles from '@salesforce/apex/SandboxRefreshClass.checkForMetadataZipFiles';
import getValidationLogRecord from '@salesforce/apex/SandboxRefreshClass.getValidationLogRecord';
import getRefreshLogRecord from '@salesforce/apex/SandboxRefreshClass.getRefreshLogRecord';
import getPackageContents from '@salesforce/apex/PackageXMLController.getPackageContents';
import regenerateMetadata from '@salesforce/apex/BackupRegeneration.regenerateMetadata';
import regenerateCustomSettings from '@salesforce/apex/BackupRegeneration.regenerateCustomSettings';
import regenerateScheduledJobs from '@salesforce/apex/BackupRegeneration.regenerateScheduledJobs';
import regenerateUsers from '@salesforce/apex/BackupRegeneration.regenerateUsers';
import { refreshApex } from '@salesforce/apex';
import getMetadataMaskingRules from '@salesforce/apex/MetadataMaskingRulesController.getMetadataMaskingRules';
import callFindAndReplaceQueueable from '@salesforce/apex/PostRefreshAutomationClass.callFindAndReplaceQueueable';
import callSuffixQueueable from '@salesforce/apex/PostRefreshAutomationClass.callSuffixQueueable';
import readCSVFile from '@salesforce/apex/ScriptDataController.readCSVFile';
import callScriptExecution from '@salesforce/apex/ScriptExecutionCall.executeScript';
import getMetadataMaskingLogRecord from '@salesforce/apex/PostRefreshAutomationClass.getMetadataMaskingLogRecord';
import getSearchRulesRecordofRefreshTemplate from '@salesforce/apex/PostRefreshAutomationClass.getSearchRulesRecordofRefreshTemplate';
import getSuffixLogRecord from '@salesforce/apex/PostRefreshAutomationClass.getSuffixLogRecord';
import getSuffixRulesRecordofRefreshTemplate from '@salesforce/apex/PostRefreshAutomationClass.getSuffixRulesRecordofRefreshTemplate';
import getApexScriptLogRecord from '@salesforce/apex/PostRefreshAutomationClass.getApexScriptLogRecord';
import getApexScriptLogRecordofRefreshTemplate from '@salesforce/apex/PostRefreshAutomationClass.getApexScriptLogRecordofRefreshTemplate';
import getDataTransformLogRecord from '@salesforce/apex/SandboxRefreshClass.getDataTransformLogRecord';
import getDataTransformLogRecordofRefreshTemplate from '@salesforce/apex/SandboxRefreshClass.getDataTransformLogRecordofRefreshTemplate';
import getUsersDataRestoreLogRecordofRefreshTemplate from '@salesforce/apex/SandboxRefreshClass.getUsersDataRestoreLogRecordofRefreshTemplate';
import getCustomSettingsDataRestoreLogRecordofRefreshTemplate from '@salesforce/apex/SandboxRefreshClass.getCustomSettingsDataRestoreLogRecordofRefreshTemplate';
import getSourceOrgType from '@salesforce/apex/SandboxRefreshClass.getSourceOrgType';
import getUserTransfLogRecordofRefreshTemplate from '@salesforce/apex/GetAllUsers.getUserTransfLogRecordofRefreshTemplate';
import getMetadataMaskingLogRecordofRefreshTemplate from '@salesforce/apex/PostRefreshAutomationClass.getMetadataMaskingLogRecordofRefreshTemplate';
import getSuffixLogRecordofRefreshTemplate from '@salesforce/apex/PostRefreshAutomationClass.getSuffixLogRecordofRefreshTemplate';

//////End//////
import fetchAllUsers from '@salesforce/apex/GetAllUsers.fetchAllUsers';
import executeData from '@salesforce/apex/GetAllUsers.executeData';
import getAssignedPermissionSets from '@salesforce/apex/PackageXMLController.getAssignedPermissionSets';
import getProfileName from '@salesforce/apex/PackageXMLController.getProfileName';
import uploadSearchRulesCSV from '@salesforce/apex/MetadataMaskingRulesController.uploadSearchRulesCSV';
import uploadSuffixRulesCSV from '@salesforce/apex/MetadataMaskingRulesController.uploadSuffixRulesCSV';

import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

import metaExecuteDisableButton from '@salesforce/apex/SandboxRefreshTemplateClass.metaExecuteDisableButton';
import hasDataInProgressBackupLogs from '@salesforce/apex/SandboxRefreshTemplateClass.hasDataInProgressBackupLogs';
import getLatestLogs from '@salesforce/apex/SandboxRefreshTemplateClass.getLatestLogs';
import getAllDataRestoreStatuses from '@salesforce/apex/SandboxRefreshTemplateClass.getAllDataRestoreStatuses';
import getAllDataRestoreInprogressStatuses from '@salesforce/apex/SandboxRefreshTemplateClass.getAllDataRestoreInprogressStatuses';
import getLatestRefreshLogCreatedDate from '@salesforce/apex/SandboxRefreshTemplateClass.getLatestRefreshLogCreatedDate';
import hasCompletedRefreshLog from '@salesforce/apex/SandboxRefreshTemplateClass.hasCompletedRefreshLog';
import getInProgressTemplateLogs from '@salesforce/apex/SandboxRefreshTemplateClass.getInProgressTemplateLogs';


import { NavigationMixin } from 'lightning/navigation';

const columnsForValidationResultForSucess = [
    { label: 'Component Name', fieldName: 'successCompName', type: 'text', initialWidth: 450 },
    { label: 'Component Type', fieldName: 'successCompType', type: 'text', initialWidth: 450 }
];

const columnsForValidationResultForFailure = [
    { label: 'Component Name', fieldName: 'compName', type: 'text', initialWidth: 150 },
    { label: 'Component Type', fieldName: 'compType', type: 'text', initialWidth: 150 },
    { label: 'Problem', fieldName: 'problem', type: 'text', initialWidth: 150 },
    { label: 'Problem Type', fieldName: 'problemType', type: 'text', initialWidth: 150 },
    //{ label: 'Success', fieldName: 'success', type: 'text', initialWidth: 150 },
    //{ label: 'Warning', fieldName: 'warning', type: 'text', initialWidth: 150 },
    { label: 'Line Number', fieldName: 'lineNumber', type: 'text', initialWidth: 150 },
    { label: 'Column Number', fieldName: 'columnNumber', type: 'text', initialWidth: 150 }
];

const metadataMaskingOptions = [
    { label: 'Metadata Type', fieldName: 'metadataType', type: 'text' },
    { label: 'Masking Type', fieldName: 'maskingType', type: 'text' },
    { label: 'Suffix', fieldName: 'suffixValue', type: 'text' },
    { label: 'Search Key', fieldName: 'searchKey', type: 'text' },
    { label: 'Replace Value', fieldName: 'replaceValue', type: 'text' }
];

const FIELDS = [
    'Refresh_Template__c.Is_User_Data_Selected__c',
    'Refresh_Template__c.Is_Scheduled_Jobs_Selected__c',
    'Refresh_Template__c.Is_Metadata_Selected__c',
    'Refresh_Template__c.Custom_Setting_Names__c'
];

const ORGFIELDS = [
    'Org__c.Last_Refresh__c',
    'Org__c.License_Type__c',
    'Org__c.Access_Token__c',
    'Org__c.Refresh_Token__c',
    'Org__c.Next_Refresh_Available__c'
];


export default class RefreshSandboxNew extends NavigationMixin(LightningElement) {

    @track currentvalue = '1';
    @track showAuthenticateButton = false;
    @track showAuthenticateWarning = false;
    @track showRefreshStatusWarning = false;
    @track showSelectedMaskingFields = false;
    
    get warningMessage() {
        return 'Metadata/Data Retrieval is in progress. The progress will shift to "Sandbox Refresh" stage once the retrieval is done. Please refresh the page to check the status!';
    }

    get warningAuthenticateMessage() {
        return 'Please authenticate the selected Org to continue.';
    }

    get warningRefreshSandboxMessage() {
        return 'A sandbox refresh is currently in progress. Please click the refresh icon to view the latest status.';
    }

    @api recordId;
    @track showDataRetrievalPage = false;
    @track isStatusModalOpen = false;
    @track showWarningMessage = false;
    @track showMainContent = false;
    @track showMetadataRestore = false;
    @track sandboxName = '';
    @track showRefreshPage = false;
    @track isLoading = true;
    @track templateFields = {
        isMetadataSelected: false,
        isUserDataSelected: false,
        isScheduledJobsSelected: false,
        customSettingNames: []
    };
    
    @track showUserTrans = false;
    @track showRefreshPendingMessage = false;
    @track showRefreshIconMessage = false;

    @wire(getInProgressTemplateLogs, { templateId: '$recordId' })
    wiredLogs({ error, data }) {
        console.log('data getInProgressTemplateLogs ='+data);
        
            if (data) {
                this.showWarningMessage = true;
                this.showMainContent = false;
                console.log('this.showWarningMessage  ='+this.showWarningMessage );
            } else {
                console.log('data is not null');
                this.showWarningMessage = false;
                this.showMainContent = true;
            }
            
            if (error){
                console.error('Error fetching logs getInProgressTemplateLogs:', error);
                this.showWarningMessage = false;
                this.showMainContent = true;
            }
        
    }
     
    // Wire service for checking data retrieval status
    @wire(checkDataRetrievalStatus, { templateId: '$recordId' })
    checkStatus(result) {
        this.wiredStatusResult = result;
        const { data, error } = result;

        // Start with loading state
        this.isLoading = true;
        console.log('Wire result received:', result);
        console.log('currentvalue >> ' + this.currentvalue);

        if (data !== undefined) {
            console.log('Data retrieval status:', data);
            console.log('Data received from Apex:', JSON.stringify(data));

            if (data === true) {
                // Check if we've already done a reload
                const hasReloaded = sessionStorage.getItem('hasReloaded');

                if (!hasReloaded) {
                    // Set the flag before reloading
                    sessionStorage.setItem('hasReloaded', 'true');

                    // All files present - show main content
                    console.log('Files check passed, showing main content');
                    this.showDataRetrievalPage = this.currentvalue == 1 || !this.currentvalue ? true : false;
                  //  this.showWarningMessage = false;
                    this.loadRules();
                   // this.showMainContent = true;
                    this.showMetadataMaskingPage = this.currentvalue == 4 ? true : false;
                    this.currentValue = '1';
                    this.stopPolling(); // Stop polling when files are found

                    // Reload the page
                    // window.location.reload();
                    // Refresh the user data wire adapter
                    if (this.wiredUserDataResult) {
                        console.log('Refreshing user data wire adapter');
                        refreshApex(this.wiredUserDataResult);
                    }
                    if (this.wiredMetadataResult) {
                        console.log('Refreshing metadata wire adapter');
                        refreshApex(this.wiredMetadataResult);
                    }
                    if (this.wiredData) {
                        console.log('Sandbox Refresh wire adapter');
                        refreshApex(this.wiredData); 
                    }
                    if (this.wiredDataDeploy) {
                        console.log('Deploy wire adapter');
                        refreshApex(this.wiredDataDeploy); 
                    }
                    if (this.wiredDataValid) {
                        console.log('Validate wire adapter');
                        refreshApex(this.wiredDataValid); 
                    }
                    if (this.wiredUsersLogResult) {
                        console.log('User Data Restore wire adapter');
                        refreshApex(this.wiredUsersLogResult); 
                    }
                    if (this.wiredCustomSettingsLogResult) {
                        console.log('Custom Setting Restore wire adapter');
                        refreshApex(this.wiredCustomSettingsLogResult); 
                    }
                } else {
                    // Just update the UI without reloading
                    this.showDataRetrievalPage = this.currentvalue == 1 || !this.currentvalue ? true : false;
                  //  this.showWarningMessage = false;
                    this.loadRules();
                   // this.showMainContent = true;
                    this.showMetadataMaskingPage = this.currentvalue == 4 ? true : false;
                    this.currentValue = '1';
                    this.stopPolling();
                    // Refresh the user data wire adapter here as well
                    if (this.wiredUserDataResult) {
                        console.log('Refreshing user data wire adapter else');
                        refreshApex(this.wiredUserDataResult);
                    }
                    if (this.wiredMetadataResult) {
                        console.log('Refreshing metadata wire adapter else');
                        refreshApex(this.wiredMetadataResult);
                    }
                    if (this.wiredData) {
                        console.log('Sandbox Refresh wire adapter else');
                        refreshApex(this.wiredData); 
                    }
                    if (this.wiredDataDeploy) {
                        console.log('Deploy wire adapter else');
                        refreshApex(this.wiredDataDeploy); 
                    }
                    if (this.wiredDataValid) {
                        console.log('Validate wire adapter else');
                        refreshApex(this.wiredDataValid); 
                    }
                    if (this.wiredUsersLogResult) {
                        console.log('User Data Restore wire adapter else');
                        refreshApex(this.wiredUsersLogResult); 
                    }
                    if (this.wiredCustomSettingsLogResult) {
                        console.log('Custom Setting Restore wire adapter else');
                        refreshApex(this.wiredCustomSettingsLogResult); 
                    }
                }
            } else {
                // Files missing - show warning and start polling
                console.log('Files check failed, showing warning');
                this.showDataRetrievalPage = this.currentvalue == 1 || !this.currentvalue ? true : false;
             //   this.showWarningMessage = false;
             //   this.showMainContent = true;
                this.showMetadataMaskingPage = this.currentvalue == 4 ? true : false;
                this.currentValue = '1';
                this.startPolling(); // Start polling for files

                // Clear the reload flag if data is false
                sessionStorage.removeItem('hasReloaded');
            }
        } else if (error) {
            // Handle error case
            console.error('Error in data retrieval:', error);
            console.error('Error details:', JSON.stringify(error));
            this.showDataRetrievalPage = this.currentvalue == 1 || !this.currentvalue ? true : false;
           // this.showWarningMessage = false;
         //   this.showMainContent = true;
            this.showMetadataMaskingPage = this.currentvalue == 4 ? true : false;
            this.currentValue = '1';
            this.startPolling(); // Start polling even in error case

            // Clear the reload flag if there's an error
            sessionStorage.removeItem('hasReloaded');
        }

        // End loading state
        this.isLoading = false;
        this.logCurrentState();
    }

    @track showDataRetoreRefresh = false;


    // Polling control methods
    startPolling() {
        // Clear any existing polling interval
        this.stopPolling();

        // Reset poll count
        this.pollCount = 0;

        // Start new polling interval
        this.pollingInterval = setInterval(() => {
            this.pollCount++;
            console.log(`Polling attempt ${this.pollCount} of ${this.MAX_POLL_COUNT}`);

            if (this.pollCount >= this.MAX_POLL_COUNT) {
                console.log('Maximum polling attempts reached');
                this.stopPolling();
                return;
            }

            // Refresh the wire adapter data
            refreshApex(this.wiredStatusResult);
        }, this.POLL_INTERVAL);
    }

    stopPolling() {
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
            this.pollingInterval = undefined;
        }
    }

    logCurrentState() {
        console.log('Current State:', {
            isLoading: this.isLoading,
            currentValue: this.currentValue,
            showDataRetrievalPage: this.showDataRetrievalPage,
            showWarningMessage: this.showWarningMessage,
            showMainContent: this.showMainContent,
            pollCount: this.pollCount
        });
    }

    // Cleanup
    disconnectedCallback() {
        this.stopPolling();
        // Clear the reload flag when component is destroyed
        sessionStorage.removeItem('hasReloaded');
        unsubscribe(this.subscription).then(() => {
            this.subscription = null;
        }).catch((error) => {
            console.error('Error unsubscribing from event:', error);
        });
    }

    pathHandler(event) {
        let targetValue = event.currentTarget.value;
        if (this.showAuthenticateButton ) {    //|| this.refreshStatus !== 'Completed'
            // Allow navigation for Step 1 and Step 2 only if showAuthenticateButton is true
            if (targetValue === '2') {
                console.log(`${targetValue === '1' ? 'Pre-Refresh' : 'Sandbox Refresh'} clicked, authentication is enabled.`);
            } else { 
                // Prevent clicking other steps if authentication is required
                //this.showToast('Warning', 'Authentication is required to proceed. Please authenticate.', 'warning');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Warning',
                        message: 'Authentication is required to proceed. Please authenticate.',
                        variant: 'warning'
                    })
                );
                return;
            }
        }

        // Prevent clicking other steps if the refresh is in progress
        if (this.refreshStatus === 'InProgress' && targetValue !== '2') {
            //this.showToast('Warning', 'Sandbox refresh is in progress', 'warning');
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Warning',
                    message: 'Sandbox refresh is in progress.',
                    variant: 'warning'
                })
            );
            return;
        }
        this.currentvalue = targetValue;
        if (targetValue === '1') {
            this.showDataRetrievalPage = true;
            this.showRefreshPage = false;
            this.showRestorePage = false;
            this.showMetadataMaskingPage = false;
            this.showDataMaskingPage = false;
            this.showMetadataRestore = false;
            this.showUserTrans = false;
        }
        if (targetValue === '2') {
            this.showDataRetrievalPage = false;
            this.showRefreshPage = true;
            this.showRestorePage = false;
            this.showMetadataMaskingPage = false;
            this.showDataMaskingPage = false;
            this.showMetadataRestore = false;
            this.showUserTrans = false;
        }
        if (targetValue === '3') {
            this.showDataRetrievalPage = false;
            this.showRefreshPage = false;
            this.showRestorePage = false;
            this.showMetadataMaskingPage = false;
            this.showDataMaskingPage = false;
            this.showMetadataRestore = true;
            this.showUserTrans = false;
        }
        if (targetValue === '4') {
            this.showDataRetrievalPage = false;
            this.showRefreshPage = false;
            this.showRestorePage = false;
            this.showMetadataMaskingPage = true;
            this.showDataMaskingPage = false;
            this.showMetadataRestore = false;
            this.showUserTrans = false;

            //this.fetchMetadataMaskingTemplate();
        }
        if (targetValue === '5') {
            this.showDataRetrievalPage = false;
            this.showRefreshPage = false;
            this.showRestorePage = true;
            this.showMetadataMaskingPage = false;
            this.showDataMaskingPage = false;
            this.showMetadataRestore = false;
            this.showUserTrans = false;

            //this.fetchAllCustomObjects();
        }
        if (targetValue === '6') {
            this.showDataRetrievalPage = false;
            this.showRefreshPage = false;
            this.showRestorePage = false;
            this.showMetadataMaskingPage = false;
            this.showDataMaskingPage = true;
            this.showMetadataRestore = false;
            this.showUserTrans = false;

        }
        if (targetValue === '7') {
            this.showDataRetrievalPage = false;
            this.showRefreshPage = false;
            this.showRestorePage = false;
            this.showMetadataMaskingPage = false;
            this.showDataMaskingPage = false;
            this.showMetadataRestore = false;
            this.showUserTrans = true;
        }
        this.updateStepClasses(targetValue);
    }



    updateStepClasses(targetValue) {
        // Update the classes based on the selected step
        this.step1Class = targetValue >= '1' ? 'slds-is-complete' : 'slds-is-incomplete';
        this.step2Class = targetValue >= '2' ? 'slds-is-complete' : 'slds-is-incomplete';
        this.step6Class = targetValue <= '6' ? 'slds-is-complete' : 'slds-is-incomplete';
        this.step3Class = targetValue >= '3' ? 'slds-is-complete' : 'slds-is-incomplete';
        this.step4Class = targetValue >= '4' ? 'slds-is-complete' : 'slds-is-incomplete';
        this.step5Class = targetValue === '5' ? 'slds-is-active' : 'slds-is-incomplete';
        this.step7Class = targetValue >= '7' ? 'slds-is-complete' : 'slds-is-incomplete';



        if (targetValue === '1') {
            this.step1Class = 'slds-is-active';
        } else if (targetValue === '2') {
            this.step2Class = 'slds-is-active';
        } else if (targetValue === '6') {
            this.step6Class = 'slds-is-active';
        } else if (targetValue === '3') {
            this.step3Class = 'slds-is-active';
        } else if (targetValue === '4') {
            this.step4Class = 'slds-is-active';
        } else if (targetValue === '5') {
            this.step5Class = 'slds-is-active';
        } else if (targetValue === '7') {
            this.step7Class = 'slds-is-active';
        }
    }


    /****************** PRE REFRESH PAGE CODE BLOCK ******************/
    handleNextToSandboxpage() {
        if (!this.showWarningMessage) {
            this.currentvalue = '2';
            this.showDataRetrievalPage = false;
            this.updateStepClasses(this.currentvalue);
            this.showRefreshPage = true;
            this.recordsPerPage = 5;
            this.metadataPageSize = 5;
            this.updatePagedUsers();
            this.updatePagedUsersPre();
            this.updatePagedCustomSettings();
            this.updatePagedScheduleJobs();
            this.initializePagination();
            this.initializePaginationPre();
            this.initializeCustomSettingsPagination();
            this.updateMetadataDisplay();
        }
    }
    
   /* get isNextDisabled() {
        return this.showWarningMessage || !this.showMainContent;
    }*/

    @track metadataComponents = [];
    @track displayMetadata = [];
    @track originalMetadataComponents = []; // Store original data for reset
    @track error;
    @track searchTermMetadata = '';
    @track isLoading = true;
    @track isExecuting = false;

    // Sorting
    @track sortedBy;
    @track sortDirection = 'asc';

    // Pagination
    @track currentMetadataPage = 1;
    @track metadataPageSize = 5;
    metadataPageSizeOptions = [5, 10, 25, 50, 100];

    columnsMetadata = [
        {
            label: 'Name',
            fieldName: 'name',
            type: 'text',
            sortable: true
        },
        {
            label: 'Type',
            fieldName: 'type',
            type: 'text',
            sortable: true,
        }
    ];

    // Computed properties
    get filteredMetadata() {
        if (!this.searchTermMetadata) {
            return this.metadataComponents;
        }

        const searchLower = this.searchTermMetadata.toLowerCase();
        return this.metadataComponents.filter(item =>
            (item.name && item.name.toLowerCase().includes(searchLower)) ||
            (item.type && item.type.toLowerCase().includes(searchLower))
        );
    }

    get totalMetadataPages() {
        return Math.ceil(this.filteredMetadata.length / this.metadataPageSize);
    }

    get isFirstMetadataPage() {
        return this.currentMetadataPage === 1;
    }

    get isLastMetadataPage() {
        return this.currentMetadataPage === this.totalMetadataPages;
    }

    get totalMetadataRecords() {
        return this.filteredMetadata.length;
    }

    @wire(getPackageContents, { recordId: '$recordId' })
    wiredMetadataContents({ error, data }) {
        this.isLoading = true;

        try {
            if (data) {
                // Add index to each record
                const indexedData = data.map((item, index) => ({
                    ...item,
                    index: index + 1
                }));

                this.metadataComponents = indexedData;
                console.log('this.metadataComponents = ' +this.metadataComponents);
                this.originalMetadataComponents = indexedData;
                this.error = undefined;
                this.updateMetadataDisplay();

                if (indexedData.length > 0) {
                    this.templateFields.isMetadataSelected = true;
                }
            } else if (error) {
                this.error = error;
                this.metadataComponents = [];
                this.originalMetadataComponents = [];
                this.displayMetadata = [];
                console.error('Error loading metadata:', error);
            }
        } finally {
            this.isLoading = false;
        }
    }

    handleSearchMetadata(event) {
        this.searchTermMetadata = event.target.value;
        this.currentMetadataPage = 1;
        this.updateMetadataDisplay();
        this.metadataPageSize = 5;
    }

    handleResetMetadata() {
        this.isExecuting = true;
        try {
            this.searchTermMetadata = '';
            this.currentMetadataPage = 1;
            this.sortedBy = undefined;
            this.sortDirection = 'asc';
            this.metadataComponents = [...this.originalMetadataComponents];
            this.updateMetadataDisplay();
            this.metadataPageSize = 5;
        } finally {
            this.isExecuting = false;
        }
    }

    handleMetadataPageSize(event) {
        this.metadataPageSize = parseInt(event.target.value, 10);
        this.currentMetadataPage = 1;
        this.updateMetadataDisplay();
    }

    handlePrevMetadataPage() {
        if (!this.isFirstMetadataPage) {
            this.currentMetadataPage--;
            this.updateMetadataDisplay();
        }
    }

    handleNextMetadataPage() {
        if (!this.isLastMetadataPage) {
            this.currentMetadataPage++;
            this.updateMetadataDisplay();
        }
    }

    handleMetadataSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortDirection = sortDirection;

        let cloneData = [...this.metadataComponents];

        cloneData.sort((a, b) => {
            let valA = a[sortedBy];
            let valB = b[sortedBy];

            if (typeof valA === 'number') {
                return sortDirection === 'asc' ? valA - valB : valB - valA;
            }

            valA = valA ? valA.toLowerCase() : '';
            valB = valB ? valB.toLowerCase() : '';

            return sortDirection === 'asc' ?
                valA.localeCompare(valB) : valB.localeCompare(valA);
        });

        this.metadataComponents = cloneData;
        this.updateMetadataDisplay();
    }

    updateMetadataDisplay() {
        const filtered = this.filteredMetadata;
        const start = (this.currentMetadataPage - 1) * this.metadataPageSize;
        const end = start + this.metadataPageSize;
        this.displayMetadata = filtered.slice(start, end);
    }


    handleRetrieveMetadata() {
        // Check if metadata is selected
        if (!this.templateFields.isMetadataSelected) {
            this.showToastMessage('Error', 'Metadata retrieval is not enabled for this template.', 'error');
            return;
        }
        // Set loading state
        this.isLoading = true;
        this.isRetrieveMetadataInProgress = true;
        this.showRefreshIconPre = true;

        // Call Apex method
        regenerateMetadata({ refTempId: this.recordId })
            .then(result => {
                // Handle success
                this.showToastMessage('', 'Metadata regeneration initiated. Please wait while files are being generated.', 'success');
                this.metadataExecutionStartTime = new Date().toISOString();
                this.metadataSuccessToastShown = false;
            })
            .catch(error => {
                // Default error message
                let errorMessage = 'An error occurred while retrieving metadata.';

                // Custom error handling based on the error message
                if (error.body && error.body.message.includes('List has no rows for assignment to SObject')) {
                    errorMessage = 'No metadata found for the given reference ID.';
                }

                // Show the error message to the user
                this.showToastMessage('Error', errorMessage, 'error');
            })
            .finally(() => {
                // Reset loading state
                this.isLoading = false;
            });
    }


    @track isModalOpen = false; // To control modal visibility
    @track customSettingsChecked = false;
    @track scheduledJobsChecked = false;
    @track usersChecked = false;
    // Track execution times
    metadataExecutionStartTime = null;
    dataExecutionStartTime = null;

    // Show modal when the button is clicked
    handleRetrieveData() {
        this.metadataSuccessToastShown = false;
        this.dataSuccessToastShown = false;

        if (!this.templateFields) return;

        // Pre-check checkboxes based on template configuration
        this.customSettingsChecked = Boolean(this.templateFields.customSettingNames);
        this.scheduledJobsChecked = this.templateFields.isScheduledJobsSelected;
        this.usersChecked = this.templateFields.isUserDataSelected;

        this.isModalOpen = true;
       
    }

    // Close the modal without doing anything
    closeModalDataretieval() {
        this.isModalOpen = false;
        this.customSettingsChecked = false;
        this.scheduledJobsChecked = false;
        this.usersChecked = false;
    }

    // Handle form submission
  /*  async handleSubmitDataretrieval() {
        try {
            this.metadataSuccessToastShown = false;
            this.dataSuccessToastShown = false;
            this.isLoading = true;
            this.isRetrieveDataInProgress = true;
            this.showRefreshIconPre = true;
            const promises = [];

            // Only add promises for checked items that are configured in the template
            if (this.customSettingsChecked && this.templateFields.customSettingNames) {
                promises.push(regenerateCustomSettings({
                    refTempId: this.recordId,
                    //customSettingNames: this.templateFields.customSettingNames
                }));
            }

            if (this.scheduledJobsChecked && this.templateFields.isScheduledJobsSelected) {
                promises.push(regenerateScheduledJobs({ refTempId: this.recordId }));
            }

            if (this.usersChecked && this.templateFields.isUserDataSelected) {
                console.log('✅ Attempting regenerateUsers...');
              
                promises.push(regenerateUsers({ refTempId: this.recordId }));
            }

            if (promises.length === 0) {
                this.showToastMessage('Warning', 'Please select at least one option to retrieve.', 'warning');
                return;
            }

            console.log('i m user check 2');

            await Promise.all(promises);
            console.log('i m user check 3');
            //this.showToast('Success', 'Data has been successfully retrieved!', 'success');
            this.showToastMessage('', 'Data regeneration initiated. Please wait while files are being generated.', 'success');
            console.log('i m user check 4');
            this.dataExecutionStartTime = new Date().toISOString();
            console.log('i m user check 5');
            this.dataSuccessToastShown = false;
            console.log('i m user check 6');

            this.closeModal();
            console.log('i m user check 7');
            this.isModalOpen = false;
            console.log('i m user check 8');

            // Refresh the data on success
            // You might want to add your refresh logic here

        } catch (error) {
            let errorMessage = 'An error occurred while retrieving data.';

            if (error.body?.message) {
                if (error.body.message.includes('No Custom Settings found')) {
                    errorMessage = 'No custom settings found for retrieval.';
                } else if (error.body.message.includes('No Scheduled Jobs found')) {
                    errorMessage = 'No scheduled jobs found for retrieval.';
                } else if (error.body.message.includes('No Users found')) {
                    errorMessage = 'No users found for retrieval.';
                }
            }

            this.showToastMessage('Error', errorMessage, 'error');
        } finally {
            this.isLoading = false;
            this.closeModal();
            this.isModalOpen = false;
        }
    }*/

        async handleSubmitDataretrieval() {
            try {
                this.metadataSuccessToastShown = false;
                this.dataSuccessToastShown = false;
                this.isLoading = true;
                this.isRetrieveDataInProgress = true;
                this.showRefreshIconPre = true;
        
                const promises = [];
        
                // Wrap each one manually so they are properly awaited and errors are visible
                if (this.customSettingsChecked &&
                    Array.isArray(this.templateFields.customSettingNames) &&
                    this.templateFields.customSettingNames.length > 0) {
                    promises.push(
                        regenerateCustomSettings({ refTempId: this.recordId }).catch(error => {
                            throw new Error('Custom Settings regeneration failed: ' + error.body?.message || error.message);
                        })
                    );
                }
        
                if (this.scheduledJobsChecked && this.templateFields.isScheduledJobsSelected) {
                    promises.push(
                        regenerateScheduledJobs({ refTempId: this.recordId }).catch(error => {
                            throw new Error('Scheduled Jobs regeneration failed: ' + error.body?.message || error.message);
                        })
                    );
                }
        
                if (this.usersChecked && this.templateFields.isUserDataSelected) {
                    console.log('✅ Triggering regenerateUsers...');
                    promises.push(
                        regenerateUsers({ refTempId: this.recordId }).catch(error => {
                            throw new Error('Users regeneration failed: ' + error.body?.message || error.message);
                        })
                    );
                }
        
                if (promises.length === 0) {
                    this.showToastMessage('Warning', 'Please select at least one option to retrieve.', 'warning');
                    return;
                }
        
                console.log('checking user 1');
                 
                await Promise.all(promises);

                console.log('checking user 2');
        
                this.showToastMessage('info', 'Data regeneration initiated. Please wait while files are being generated.', 'info');
                this.dataExecutionStartTime = new Date().toISOString();
                this.dataSuccessToastShown = false;
        
            } catch (error) {
                console.error('❌ handleSubmitDataretrieval failed:', error);
                this.showToastMessage('Error', error.message || 'An error occurred while retrieving data.', 'error');
            } finally {
                this.isLoading = false;
                this.closeModal();
                this.isModalOpen = false;
            }
        }
        

    // Handle checkbox change
    handleCheckboxChange(event) {
        const { name, checked } = event.target;

        switch (name) {
            case 'customSettings':
                this.customSettingsChecked = checked;
                break;
            case 'scheduledJobs':
                this.scheduledJobsChecked = checked;
                break;
            case 'users':
                this.usersChecked = checked;
                break;
        }
    }

    // Polling properties
    @track pollingInterval;
    @track pollCount = 0;
    MAX_POLL_COUNT = 20; // Maximum polling attempts (10 seconds * 20 = 200 seconds)
    POLL_INTERVAL = 10000; // Poll every 10 seconds
    @track wiredStatusResult;
    @track isRetrieveMetadataInProgress = false;
    @track isRetrieveDataInProgress = false;
    @track showRefreshIconPre = false;

    // Get template record fields
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredTemplate({ error, data }) {
        if (data) {
            console.log('checking wire');
            this.templateFields = {
                isUserDataSelected: data.fields.Is_User_Data_Selected__c.value,
                isScheduledJobsSelected: data.fields.Is_Scheduled_Jobs_Selected__c.value,
                isMetadataSelected: data.fields.Is_Metadata_Selected__c.value,
                //customSettingNames: data.fields.Custom_Setting_Names__c.value || ''
                customSettingNames: data.fields.Custom_Setting_Names__c.value 
                                    ? data.fields.Custom_Setting_Names__c.value.split(',').map(s => s.trim()).filter(Boolean) 
                                    : []
       
            };
            this.templateData = data;
            console.log('this.templateData---', this.templateData);
            //this.updateRetrieveDataButton();
        } else if (error) {
            console.error('Error loading template:', error);
        }
    }

    get hasCustomSettings() {
        return Array.isArray(this.templateFields.customSettingNames) && this.templateFields.customSettingNames.length > 0;
    }
    
    
   /* get isRetrieveMetadataDisabled() {
       
        const permissionCheck = !(this.hasAdvancePermissionSet || this.isSystemAdmin);
        
        return permissionCheck || this.showWarningMessage ||
            !this.templateFields.isMetadataSelected ||
            this.isLoading;
    }

    get isRetrieveDataDisabled() {
        
        const permissionCheck = !(this.hasAdvancePermissionSet || this.isSystemAdmin);

        return permissionCheck || this.showWarningMessage ||
            !this.templateFields ||
            !(this.templateFields.isUserDataSelected ||
                this.templateFields.isScheduledJobsSelected ||
                (this.templateFields.customSettingNames && this.templateFields.customSettingNames.length > 0)) ||
            this.isLoading;
    }*/
 
      /*  get isRetrieveMetadataDisabled() {
            const isBasicOnlyUser = this.hasBasicPermissionSet && !this.hasAdvancePermissionSet && !this.isSystemAdmin;
            console.log('execute Disable permission check --', isBasicOnlyUser);
            return isBasicOnlyUser || this.showWarningMessage || this.isRetrieveMetadataInProgress ||
                !this.templateFields.isMetadataSelected || this.isLoading;
        }*/

        get isRetrieveMetadataDisabled() {
            const isBasicOnlyUser = this.hasBasicPermissionSet && !this.hasAdvancePermissionSet && !this.isSystemAdmin;
            console.log('Retrieve Metadata Disable Flags: ', {
                isBasicOnlyUser,
                showWarningMessage: this.showWarningMessage,
                isRetrieveMetadataInProgress: this.isRetrieveMetadataInProgress,
                isMetadataSelected: this.templateFields.isMetadataSelected,
                isLoading: this.isLoading
            });
            return isBasicOnlyUser || this.showWarningMessage || this.isRetrieveMetadataInProgress ||
                   !this.templateFields.isMetadataSelected || this.isLoading;
        }
        
    
      /*  get isRetrieveDataDisabled() {
            const isBasicOnlyUser = this.hasBasicPermissionSet && !this.hasAdvancePermissionSet && !this.isSystemAdmin;
            console.log('execute Disable permission check --', isBasicOnlyUser);
            return isBasicOnlyUser || this.showWarningMessage || this.isRetrieveDataInProgress ||
                !this.templateFields ||
                !(this.templateFields.isUserDataSelected ||
                    this.templateFields.isScheduledJobsSelected ||
                    (this.templateFields.customSettingNames && this.templateFields.customSettingNames.length > 0)) ||
                this.isLoading;
        }*/

        get isRetrieveDataDisabled() {
            const isBasicOnlyUser = this.hasBasicPermissionSet && !this.hasAdvancePermissionSet && !this.isSystemAdmin;
            const showWarning = this.showWarningMessage;
            const inProgress = this.isRetrieveDataInProgress;
            const isLoading = this.isLoading;
            const hasTemplateFields = !!this.templateFields;
        
            let isUserSelected = false;
            let isJobsSelected = false;
            let isCustomSettingsSelected = false;
        
            if (hasTemplateFields) {
                isUserSelected = this.templateFields.isUserDataSelected;
                isJobsSelected = this.templateFields.isScheduledJobsSelected;
                isCustomSettingsSelected = this.templateFields.customSettingNames && this.templateFields.customSettingNames.length > 0;
            }
        
            console.log('Retrieve Data Disable Flags:', {
                isBasicOnlyUser,
                showWarning,
                inProgress,
                hasTemplateFields,
                isUserSelected,
                isJobsSelected,
                isCustomSettingsSelected,
                isLoading
            });
        
            return isBasicOnlyUser || showWarning || inProgress ||
                !hasTemplateFields ||
                !(isUserSelected || isJobsSelected || isCustomSettingsSelected) ||
                isLoading;
        }
        
    
        get isNextDisabled() {
            return this.showWarningMessage || !this.showMainContent || this.isRetrieveMetadataInProgress || this.isRetrieveDataInProgress;
        }
    
        get isEditTemplateDisabled() {
            const isBasicOnlyUser = this.hasBasicPermissionSet && !this.hasAdvancePermissionSet && !this.isSystemAdmin;
            console.log('this.hasCompletedRefreshLog =='+this.hasCompletedRefreshLog);
            return isBasicOnlyUser || this.isRetrieveMetadataInProgress || this.isRetrieveDataInProgress || this.isLoading || this.hasCompletedRefreshLog || this.showWarningMessage;
        }
         
     
           // Updated handleRefreshClick to handle Retrieve Metadata and Data-specific logs accurately
    /*  handleRefreshClickPre() {
               // this.displayToast('Info', 'Checking latest log statuses...', 'info');

                Promise.all([
                    metaExecuteDisableButton({ refreshTemplateId: this.recordId }),
                    hasDataInProgressBackupLogs({ refreshTemplateId: this.recordId }),
                    getLatestLogs({ refreshTemplateId: this.recordId })
                ])
                .then(([metaResult, dataResult, logs]) => {
                    this.isRetrieveMetadataInProgress = metaResult;
                    this.isRetrieveDataInProgress = dataResult;

                    const metadataLog = logs.find(log => log.Log_Type__c === 'Metadata - Backup Regeneration');
                    const dataLogs = logs.filter(log =>
                        log.Log_Type__c === 'Users - Backup Regeneration' ||
                        log.Log_Type__c === 'Scheduled Jobs - Backup Regeneration' ||
                        log.Log_Type__c === 'Custom Settings - Backup Regeneration'
                    );

                    let incompleteLogs = [];

                    // Check metadata log separately
                    if (this.isRetrieveMetadataInProgress && metadataLog) {
                        if (metadataLog.Status__c !== 'Success' && metadataLog.Status__c !== 'Failed') {
                            incompleteLogs.push(`${metadataLog.Log_Type__c}: ${metadataLog.Status__c}`);
                        } else {
                            this.isRetrieveMetadataInProgress = false;
                        }
                    }

                    // Check data logs
                    if (this.isRetrieveDataInProgress && dataLogs.length > 0) {
                        const dataIncomplete = dataLogs.filter(log =>
                            log.Status__c !== 'Success' && log.Status__c !== 'Failed'
                        );

                        if (dataIncomplete.length > 0) {
                            incompleteLogs.push(...dataIncomplete.map(log => `${log.Log_Type__c}: ${log.Status__c}`));
                        } else {
                            this.isRetrieveDataInProgress = false;
                        }
                    }

                    if (incompleteLogs.length > 0) {
                        this.displayToast('Logs In Progress or Pending', `The following logs are still not completed:\n${incompleteLogs.join('\n')}`, 'Info');
                        this.showRefreshIconPre = true;
                    } else {
                        this.displayToast('All Logs Completed', 'All backup logs have been successfully completed.', 'success');
                        this.showRefreshIconPre = false;
                    }
                })
                .catch(error => {
                    console.error('Error checking logs:', error);
                    this.displayToast('Error', 'Failed to check log status.', 'error');
                });
        }*/

     /*   handleRefreshClickPre() {
            //this.displayToast('Info', 'Checking latest log statuses...', 'info');
        
            Promise.all([
                metaExecuteDisableButton({ refreshTemplateId: this.recordId }),
                hasDataInProgressBackupLogs({ refreshTemplateId: this.recordId }),
                getLatestLogs({ refreshTemplateId: this.recordId })
            ])
            .then(([metaResult, dataResult, logs]) => {
                let metadataInProgress = metaResult;
                let dataInProgress = dataResult;
                let incompleteLogs = [];
        
                const sortedLogs = [...(logs || [])].sort((a, b) =>
                    new Date(b.LastModifiedDate) - new Date(a.LastModifiedDate)
                );
        
                // Track latest log by log type
                const latestLogByType = {};
                sortedLogs.forEach(log => {
                    if (!latestLogByType[log.Log_Type__c]) {
                        latestLogByType[log.Log_Type__c] = log;
                    }
                });
        
                // Process metadata log
                const metadataLog = latestLogByType['Metadata - Backup Regeneration'];
                if (metadataLog) {
                    if (metadataLog.Status__c !== 'Success' && metadataLog.Status__c !== 'Failed') {
                        incompleteLogs.push(`${metadataLog.Log_Type__c}: ${metadataLog.Status__c}`);
                        metadataInProgress = true;
                    } else {
                        metadataInProgress = false;
                    }
                }
        
                // Process data logs
                const dataLogTypes = [
                    'Users - Backup Regeneration',
                    'Scheduled Jobs - Backup Regeneration',
                    'Custom Settings - Backup Regeneration'
                ];
                dataInProgress = false;
        
                dataLogTypes.forEach(type => {
                    const log = latestLogByType[type];
                    if (log && log.Status__c !== 'Success' && log.Status__c !== 'Failed') {
                        incompleteLogs.push(`${log.Log_Type__c}: ${log.Status__c}`);
                        dataInProgress = true;
                    }
                });
        
                // Apply UI flags
                this.isRetrieveMetadataInProgress = metadataInProgress;
                this.isRetrieveDataInProgress = dataInProgress;
                this.showRefreshIconPre = metadataInProgress || dataInProgress;
        
                // Toast
                if (incompleteLogs.length > 0) {
                    this.displayToast(
                        'Logs In Progress or Pending',
                        `The following logs are still not completed:\n${incompleteLogs.join('\n')}`,
                        'info'
                    );
                } else {
                    this.displayToast(
                        'All Logs Completed',
                        'All backup logs have been successfully completed.',
                        'success'
                    );
                }
            })
            .catch(error => {
                console.error('Error checking logs:', error);
                this.displayToast('Error', 'Failed to check log status.', 'error');
            });
        }*/
                

        displayToast(title, message, variant) {
            this.dispatchEvent(new ShowToastEvent({
                title,
                message,
                variant
               /* mode: 'sticky'*/
            }));
         }

         @track metadataSuccessToastShown = false;
         @track dataSuccessToastShown = false;
         shownMetadataSuccessLogId = '';
         shownDataSuccessLogIds = new Set();

        handleRefreshClickPre() {
            console.log('Clicked Refresh Icon for Checking Logs...');
        
            Promise.all([
                metaExecuteDisableButton({ refreshTemplateId: this.recordId }),
                hasDataInProgressBackupLogs({ refreshTemplateId: this.recordId }),
                getLatestLogs({ refreshTemplateId: this.recordId })
            ])
            .then(([metaResult, dataResult, logs]) => {
                let metadataInProgress = metaResult;
                let dataInProgress = dataResult;
        
                let metadataLogsPending = [];
                let dataLogsPending = [];
        
                let metadataLogsFailed = [];
                let dataLogsFailed = [];
        
                const sortedLogs = [...(logs || [])].sort((a, b) =>
                    new Date(b.LastModifiedDate) - new Date(a.LastModifiedDate)
                );
        
                const latestLogByType = {};
                sortedLogs.forEach(log => {
                    if (!latestLogByType[log.Log_Type__c]) {
                        latestLogByType[log.Log_Type__c] = log;
                    }
                });
        
                // Metadata Processing
                const metadataLog = latestLogByType['Metadata - Backup Regeneration'];
                if (metadataLog) {
                    const metadataLogTime = new Date(metadataLog.LastModifiedDate);
                    const executionStartTime = this.metadataExecutionStartTime ? new Date(this.metadataExecutionStartTime) : null;
        
                    if (metadataLog.Status__c === 'InProgress') {
                        metadataLogsPending.push(`${metadataLog.Log_Type__c}: ${metadataLog.Status__c}`);
                        metadataInProgress = true;
                    } else if (metadataLog.Status__c === 'Failed') {
                        metadataLogsFailed.push(`${metadataLog.Log_Type__c}: ${metadataLog.Status__c}`);
                        metadataInProgress = false;
                    } else if (metadataLog.Status__c === 'Success' && executionStartTime && metadataLogTime >= executionStartTime) {
                        // ✅ Show metadata success toast only once per refresh
                        if (this.shownMetadataSuccessLogId !== metadataLog.Id) {
                            this.displayToast('Metadata Backup Completed', 'Metadata backup completed successfully.', 'success');
                            this.shownMetadataSuccessLogId = metadataLog.Id; 
                        }
                    }
                }
        
                // Data Processing
                const dataLogTypes = [
                    'Users - Backup Regeneration',
                    'Scheduled Jobs - Backup Regeneration',
                    'Custom Settings - Backup Regeneration'
                ];
                dataInProgress = false;
        
                dataLogTypes.forEach(type => {
                    const log = latestLogByType[type];
                    if (log) {
                        const logTime = new Date(log.LastModifiedDate);
                        const executionStartTime = this.dataExecutionStartTime ? new Date(this.dataExecutionStartTime) : null;
        
                        if (log.Status__c === 'InProgress') {
                            dataLogsPending.push(`${log.Log_Type__c}: ${log.Status__c}`);
                            dataInProgress = true;
                        } else if (log.Status__c === 'Failed') {
                            dataLogsFailed.push(`${log.Log_Type__c}: ${log.Status__c}`);
                            dataInProgress = true;
                        } else if (log.Status__c === 'Success' && executionStartTime && logTime >= executionStartTime) {
                            // ✅ Show individual success per data log but only once
                            if (!this.shownDataSuccessLogIds.has(log.Id)) {
                                this.displayToast(`${type} Backup Completed`, `${type} backup completed successfully.`, 'success');
                                this.shownDataSuccessLogIds.add(log.Id); // memorize
                            }
                        }
                    }
                });
        
                // Apply flags
                this.isRetrieveMetadataInProgress = metadataInProgress;
                this.isRetrieveDataInProgress = dataInProgress;
                this.showRefreshIconPre = metadataInProgress || dataInProgress;
        
                // Pending and Failed Toasts
        
                if (metadataLogsFailed.length > 0) {
                    this.displayToast('Metadata Backup Failed', `Metadata backup failed:\n${metadataLogsFailed.join('\n')}`, 'error');
                } else if (metadataLogsPending.length > 0) {
                    this.displayToast('Metadata Backup In Progress', `Metadata backup still running:\n${metadataLogsPending.join('\n')}`, 'info');
                }
        
                if (dataLogsFailed.length > 0) {
                    this.displayToast('Data Backup Failed', `Data backup failed:\n${dataLogsFailed.join('\n')}`, 'error');
                } else if (dataLogsPending.length > 0) {
                    this.displayToast('Data Backup In Progress', `Data backup still running:\n${dataLogsPending.join('\n')}`, 'info');
                }
        
            })
            .catch(error => {
                console.error('Error checking logs:', error);
                this.displayToast('Error', 'Failed to check log status.', 'error');
            });
        }
        
        
         
        

    clearSearchAndPaginationStates() {
        // Clear all search terms
        this.searchTermMetadata = '';
        this.userSearch = '';
        this.userSearchOnLoad = '';
        this.customSettingsSearch = '';
        this.scheduleJobsSearch = '';
        this.deleteScheduleJobsSearch = '';

        // Reset pagination to page 1 for all tables
        this.currentMetadataPage = 1;
        this.currentPageUsers = 1;
        this.currentPageCustomSettings = 1;
        this.currentPageScheduleJobs = 1;
        this.currentPageDeleteScheduleJobs = 1;

        // Reset any sorting
        this.sortedBy = undefined;
        this.sortDirection = 'asc';

        // Reset page sizes to default (assuming default is the first option in the arrays)
        this.recordsPerPage = this.pageSizeOptions && this.pageSizeOptions.length > 0 ?
            this.pageSizeOptions[0] : 5;

        // Reset filtered data to original data
        if (this.originalUsers && this.originalUsers.length > 0) {
            this.filteredUsers = [...this.originalUsers];
        }

        if (this.originalUsersPre && this.originalUsersPre.length > 0) {
            this.filteredUsersPre = [...this.originalUsersPre];
        }

        if (this.originalCustomSettings && this.originalCustomSettings.length > 0) {
            this.filteredCustomSettings = [...this.originalCustomSettings];
        }

        if (this.originalMetadataComponents && this.originalMetadataComponents.length > 0) {
            this.filteredMetadata = [...this.originalMetadataComponents];
        }

        if (this.scheduleJobs && this.scheduleJobs.length > 0) {
            // For schedule jobs, we need to ensure we're not losing any data
            this.updatePagedScheduleJobs();
        }

        // Update the paged data for all tables
        this.updatePagedUsers();
        this.updatePagedCustomSettings();

        // Now, update the UI elements to reflect these changes
        // This is done in the next event loop to ensure the DOM is updated
        setTimeout(() => {
            // Reset page size dropdown values to default
            const metadataPageSizeSelect = this.template.querySelector('select.slds-select');
            const userPageSizeSelect = this.template.querySelector('#recordsPerPageUsersprerefresh');
            const customSettingsPageSizeSelect = this.template.querySelector('#recordsPerprerefreshPageCustomSettings');
            const scheduleJobsPageSizeSelect = this.template.querySelector('#recordsPerPageScheduleJobsprerefresh');

            if (metadataPageSizeSelect && this.metadataPageSizeOptions && this.metadataPageSizeOptions.length > 0) {
                metadataPageSizeSelect.value = this.metadataPageSizeOptions[0];
            }

            if (userPageSizeSelect && this.pageSizeOptions && this.pageSizeOptions.length > 0) {
                userPageSizeSelect.value = this.pageSizeOptions[0];
            }

            if (customSettingsPageSizeSelect && this.pageSizeOptions && this.pageSizeOptions.length > 0) {
                customSettingsPageSizeSelect.value = this.pageSizeOptions[0];
            }

            if (scheduleJobsPageSizeSelect && this.pageSizeOptions && this.pageSizeOptions.length > 0) {
                scheduleJobsPageSizeSelect.value = this.pageSizeOptions[0];
            }

            // Clear search input fields
            const metadataSearchInput = this.template.querySelector('lightning-input[label="Search Metadata"]');
            const userSearchInput = this.template.querySelector('lightning-input[label="Search Users"]');
            const customSettingsSearchInput = this.template.querySelector('lightning-input[label="Search Custom Settings"]');
            const scheduleJobsSearchInput = this.template.querySelector('lightning-input[label="Search Schedule Jobs"]');

            if (metadataSearchInput) metadataSearchInput.value = '';
            if (userSearchInput) userSearchInput.value = '';
            if (customSettingsSearchInput) customSettingsSearchInput.value = '';
            if (scheduleJobsSearchInput) scheduleJobsSearchInput.value = '';
        }, 0);
    }

    handleEditTemplate(){
        const recordId = this.recordId;

        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Post_Refresh_Automation'
            },
            state: {
                c__recordId: recordId
            }
        });
    }

    /****************** PRE REFRESH PAGE CODE BLOCK ******************/

    /****************** SANDBOX REFRESH PAGE CODE BLOCK ******************/

    @track selectedSourceForRefresh = '';
    @track showRefreshPage = false;
    @track sourceOrgOptionsForRefresh = [];
   // @track parentOrgId;
   

    //@track latestLogId;

    @wire(getValidationLogRecordofRefreshTemplate, { templateId: '$recordId' })
    wiredLogValidate(result) {
        this.wiredDataValid = result; // Store result for manual refresh
        const { error, data } = result;
        if (data) {
            this.latestLogId = data.Id;
            this.validateLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
            this.validatedLogName = data.Name;
            this.lastValidatedDate = data.Last_Validated_Date__c;
            this.lastValidatedStatus = data.Status__c;
            console.log('Validated Log Name: ', this.validatedLogName);
            console.log('Validate Log URL: ', this.validateLogUrl);
            this.error = undefined;

            if (data.Status__c == 'InProgress' || data.Status__c == 'Pending') {
                this.handleRefreshValidationStatus();
            }

        } else if (error) {
            this.error = error; // Handles error
            this.latestLog = undefined;
        }
    }

    @wire(getRefreshLogRecordofRefreshTemplate, { templateId: '$recordId' })
    wiredLogRefresh(result) {
        this.wiredData = result; 
        const { error, data } = result;
        if (data) {
            console.log('refresh data ---', data);
            this.latestLog = data;
            this.refreshLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
            this.refreshedLogName = data.Name;
            this.lastRefreshedDate = data.Last_Refreshed_Date__c || 'N/A';
            this.nextAvailableDate = data.Next_Refresh_Available__c || 'N/A';
            this.refreshStatus = data.Status__c;
            this.lastRefreshedBy = data.Parent_Template__r.Last_Refreshed_By__r?.Name || 'N/A';
            this.lastRunStatus = data.Parent_Template__r.Last_Run_Status__c || 'N/A';

            const licenseType = data.Parent_Template__r?.Parent_Org__r?.License_Type__c?.toLowerCase() || 'unknown';

           /* if (this.refreshStatus === 'Completed') {
                this.showAuthenticateButton = true;
            }*/
            
            console.log('Last Refreshed Date 1: ', this.lastRefreshedDate);
            if (this.lastRefreshedDate !== 'N/A' || this.nextAvailableDate !== 'N/A') {
                this.lastRefreshedDate = this.formatDate(new Date(this.lastRefreshedDate));
                this.nextAvailableDate = this.formatDate(new Date(this.nextAvailableDate));
                console.log('Next Available Date: ', this.nextAvailableDate);
            }
            else {
                console.log('No refreshed record yet for this template.');
                this.lastRefreshedDate = 'N/A';
                this.nextAvailableDate = 'N/A';
            }

            this.error = undefined;

            if (data.Status__c !== 'Completed' && data.Status__c !== 'Forbidden' && data.Status__c !== 'Failed') {
                console.log('this.showRefreshIconMessage before='+this.showRefreshIconMessage);
                this.initializeRefreshIconLogic(); 
                console.log('this.showRefreshIconMessage after ='+this.showRefreshIconMessage);
            }
            
            if (data.Status__c == 'InProgress') {
                this.handleRefreshStatus();
            }

        }else{
            console.log('null refreshStatus'+this.refreshStatus);
            this.refreshStatus = '';
        } 
        if (error) {
            this.error = error; // Handles error
            this.latestLog = undefined;
        }
    }

    @track isValidateButtonDisabled = true;
    @wire(checkForMetadataZipFiles, { templateId: '$recordId' })
    handleRequiredFiles({ error, data }) {
        if (data) {
            console.log('File validation success: ', data);
            this.isValidateButtonDisabled = !data; 
        } else if (error) {
            console.error('Error checking files: ', error);
            this.isValidateButtonDisabled = true; 
        }
    }

    @wire(fetchParentOrgOfRefreshTemplate, { templateId: '$recordId' })
    parentOrgResult({ error, data }) {
        if (data) {
            this.parentOrgId = data;
            console.log('this.parentOrgId --- ' + this.parentOrgId);
            this.fetchAllCustomObjects();
        }
        if (error) {
            console.log('error -- ' + JSON.stringify(error));
        }
    }

    @wire(fetchSourceOrgsForRefresh, { templateId: '$recordId' })
    sourceOrgResult({ error, data }) {
        if (data) {
            console.log('source data --- ' + JSON.stringify(data));
            this.sourceOrgOptionsForRefresh = data.map(item => {
                return { label: item.Name, value: item.Id };
            });
        }
        if (error) {
            console.log('error -- ' + JSON.stringify(error));
        }
    }

    @track disableStartRefresh = false;
    @track lastRefreshDate;
   /* @wire(getRecord, { recordId: '$parentOrgId', fields: ORGFIELDS })
    wiredParentOrgRecord({ error, data }) {
        if (data) {
            console.log('orgData:: ' + JSON.stringify(data));
            
            if (this.refreshStatus === 'Completed') {
                this.showRefreshStatusMessage = false
                if (data.fields.Access_Token__c.value != null && data.fields.Refresh_Token__c.value != null) {
                    this.showAuthenticateButton = false;
                    console.log('in if wiredparentorg');
                }
                else {
                    this.showAuthenticateButton = true;
                    
                    if (this.showAuthenticateButton ) {
                        this.currentvalue = '2'; 
                        this.showDataRetrievalPage = false;
                        this.showRefreshPage = true;
                        this.showAuthenticateMessage = true;
                        this.showRestorePage = false;
                        this.showMetadataMaskingPage = false;
                        this.showDataMaskingPage = false;
                        this.showMetadataRestore = false;
                    } else {
                        this.showDataRetrievalPage = this.currentvalue == 1 || !this.currentvalue ? true : false;
                        this.showWarningMessage = true;
                        this.showMainContent = false;
                        this.showMetadataMaskingPage = this.currentvalue == 4 ? true : false;
                        this.currentValue = '1';
                        this.showAuthenticateMessage = false;
                    }

                }
            }
            else if (this.refreshStatus !== '' && (this.refreshStatus !== 'Completed' || this.refreshStatus !== 'Failed')) {
                this.currentvalue = '2'; 
                this.showDataRetrievalPage = false;
                this.showRefreshPage = true;
                this.showRefreshStatusMessage = true;
                this.showAuthenticateMessage = false; 
                this.showRestorePage = false;
                this.showMetadataMaskingPage = false;
                this.showDataMaskingPage = false;
                this.showMetadataRestore = false;
            }
            
            if (data.fields.Last_Refresh__c.value) {
                const dateParts = data.fields.Last_Refresh__c.value.split('-'); // e.g., ["2025", "03", "12"]
                this.lastRefreshDate = new Date(data.fields.Last_Refresh__c.value);
                console.log('lastRefreshDate. ---', this.lastRefreshDate);
                let licenseType = data.fields.License_Type__c.value.toLowerCase();
                console.log('licenseType >> ' + licenseType);

                if (licenseType === 'developer' || licenseType === 'developer pro') {
                    this.lastRefreshDate.setDate(this.lastRefreshDate.getDate() + 1);
                } else if (licenseType === 'partial copy') {
                    this.lastRefreshDate.setDate(this.lastRefreshDate.getDate() + 5);
                } else if (licenseType === 'full') {
                    this.lastRefreshDate.setDate(this.lastRefreshDate.getDate() + 29);
                }
                // Converting to ISO string here isn't needed unless you're using the value.
                // this.lastRefreshDate.toISOString();
            }
            console.log('nextRefreshDate>> ' + this.lastRefreshDate);
            console.log(new Date() < this.lastRefreshDate);

            this.disableStartRefresh = this.lastRefreshDate && new Date() < this.lastRefreshDate;
        } else if (error) {
            console.error('Error loading template:', error);
        }
    }*/

        @track nextAvailableDateFromOrg;
        @wire(getRecord, { recordId: '$parentOrgId', fields: ORGFIELDS })
        wiredParentOrgRecord({ error, data }) {
            if (data) {
                console.log('orgData:: ' + JSON.stringify(data));

                if (this.wiredData) {
                    console.log('Sandbox Refresh wire adapter in getRecord');
                    refreshApex(this.wiredData); 
                    if (this.refreshStatus === 'Success' || this.refreshStatus === 'Completed' || this.refreshStatus === 'Failed' ||  this.refreshStatus === 'Forbidden') {
                        this.showRefreshIconMessage = false;
                        this.showRefreshPendingMessage = false;
                        console.log('this.showRefreshIconMessage 4 ='+this.showRefreshIconMessage);
                    }
                }
        
                // Always check tokens regardless of refresh status
                const accessToken = data.fields.Access_Token__c.value;
                const refreshToken = data.fields.Refresh_Token__c.value;
                this.nextAvailableDateFromOrg = data.fields.Next_Refresh_Available__c || 'N/A';
                this.nextAvailableDateFromOrg = this.formatDate(new Date(this.nextAvailableDateFromOrg));
        
                const isAuthenticated = accessToken != null && refreshToken != null;
        
                // Set Authenticate Button visibility
                this.showAuthenticateButton = !isAuthenticated;

                if (isAuthenticated) {
                    this.showAuthenticateMessage = false;
                    
                }
        
                // Additional display logic if not authenticated
                if (!isAuthenticated) {
                    this.currentvalue = '2'; 
                    this.showDataRetrievalPage = false;
                    this.showRefreshPage = true;
                    this.showAuthenticateMessage = true;
                    this.showRefreshIconMessage = false;
                    this.showRefreshPendingMessage = false;
                    this.showRestorePage = false;
                    this.showMetadataMaskingPage = false;
                    this.showDataMaskingPage = false;
                    this.showMetadataRestore = false;
                }
        
                // Handle refresh status messages and next refresh logic
                if (this.refreshStatus === 'Success' || this.refreshStatus === 'Completed' || this.refreshStatus === 'Failed' ||  this.refreshStatus === 'Forbidden') {
                    this.showRefreshIconMessage = false;
                    this.showRefreshPendingMessage = false;
                    console.log('this.showRefreshIconMessage 5 ='+this.showRefreshIconMessage);
                } else if (this.refreshStatus !== '' && (this.refreshStatus !== 'Success' && this.refreshStatus !== 'Completed' && this.refreshStatus !== 'Failed' &&  this.refreshStatus !== 'Forbidden')) {
                    this.currentvalue = '2'; 
                    this.showDataRetrievalPage = false;
                    this.showRefreshPage = true;
                   // this.showRefreshIconMessage = true;
                    this.showAuthenticateMessage = false; 
                    this.showRestorePage = false;
                    this.showMetadataMaskingPage = false;
                    this.showDataMaskingPage = false;
                    this.showMetadataRestore = false;

                    if (this.hasFiveMinutesPassed) {
                        this.showRefreshPendingMessage = false;
                        this.showRefreshIconMessage = true;
                        console.log('this.showRefreshIconMessage 7 ='+this.showRefreshIconMessage);
                    } else {
                        this.showRefreshPendingMessage = true;
                        this.showRefreshIconMessage = false;
                        console.log('this.showRefreshIconMessage 6 ='+this.showRefreshIconMessage);
                    }
                }
        
                // Next Refresh Date Logic
                if (data.fields.Last_Refresh__c.value) {
                    this.lastRefreshDate = new Date(data.fields.Last_Refresh__c.value);
                    let licenseType = data.fields.License_Type__c.value.toLowerCase();
        
                    if (licenseType === 'developer' || licenseType === 'developer pro') {
                        this.lastRefreshDate.setDate(this.lastRefreshDate.getDate() + 1);
                    } else if (licenseType === 'partial copy') {
                        this.lastRefreshDate.setDate(this.lastRefreshDate.getDate() + 5);
                    } else if (licenseType === 'full') {
                        this.lastRefreshDate.setDate(this.lastRefreshDate.getDate() + 29);
                    }
                }
        
                this.disableStartRefresh = this.lastRefreshDate && new Date() < this.lastRefreshDate;
        
            } else if (error) {
                console.error('Error loading template:', error);
            }
        }
           

    @track publicGroupOptions = [];
    @track selectedPublicGroup = null;
    @track disablePublicGroup = true;
    @track orgType;
    @track publicGroupMessage = 'Source org is not selected';
    @track hasInProgressMetadataBackupLog = false;

    handleSourceOrgForRefresh(event) {
        console.log('source org --- ' + event.detail.value);
        this.selectedSourceForRefresh = event.detail.value;

        this.selectedPublicGroup = null;

        if (!this.selectedSourceForRefresh) {
            this.disablePublicGroup = true;
            this.publicGroupOptions = []; // Clear dropdown options
            this.publicGroupMessage = 'Source org is not selected'; // Set message
            return;
        }
        this.publicGroupMessage = ''

        getSourceOrgType({ orgId: this.selectedSourceForRefresh })
            .then(result => {
                console.log('Org type: ', result);
                this.orgType = result;
                if (this.orgType === 'Production') {
                    // For Production, force the only option and show public group
                    this.selectedSandboxAccess = 'User Groups (Recommended)';
                    this.isUserGroupSelected = true;
                } else if (this.orgType === 'Sandbox') {
                    // For Sandbox, default to "All Active Users" so the public group remains hidden
                    this.selectedSandboxAccess = 'All Active Users';
                    this.isUserGroupSelected = false;
                }
            })
            .catch(error => {
                console.error('Error fetching org type:', error);
            });

        fetchPublicGroupOfSource({ selectedSourceForRefresh: this.selectedSourceForRefresh })
            .then(result => {
                console.log('result -- ' + JSON.stringify(result));
                this.publicGroupOptions = result.map(item => {
                    return { label: item.Name, value: item.Id };
                });
                this.disablePublicGroup = false;
            })
            .catch(error => {
                this.disablePublicGroup = false;
                console.log('error -- ' + JSON.stringify(error));

            });
    }

    handleSelectPublicGroupForRefresh(event) {
        this.selectedPublicGroup = event.detail.value;
        console.log('selected public group --- ' + this.selectedPublicGroup);
    }

    handleBackFromRefreshPage() {
        //this.showRefreshPage = false;
        //this.isDataPicker = true;
    }

    handleNextFromRefreshPage() {
        this.currentvalue = '3'
        this.updateStepClasses(this.currentvalue);

        this.showMetadataRestore = true;
        this.showRefreshPage = false;
        console.log('this.recordId1 ='+this.recordId);

      /*  metaExecuteDisableButton({ refreshTemplateId: this.recordId })
            .then(result => {
                console.log('this.recordId2 ='+this.recordId);
                this.hasInProgressMetadataBackupLog = result;
                console.log('In this.hasInProgressMetadataBackupLog = '+this.hasInProgressMetadataBackupLog);
            })
            .catch(error => {
                console.error('Error checking Metadata - Backup Regeneration log', error);
                this.hasInProgressMetadataBackupLog = false; // fallback
            });*/
    }

    @track apexClassName = '';
    handleApexClassForRefresh(event) {
        this.apexClassName = event.detail.value;
        console.log('apex class name --- ' + this.apexClassName);
    }

    @wire(getTargetRefreshOrg, { recordId: '$recordId' })
    wiredTargetRefreshOrg({ error, data }) {
        if (data) {
            this.sandboxName = data; // Set sandboxName from the Apex response
        } else if (error) {
            console.error('Error fetching Target Refresh Org:', error);
        }
    }

    handleSandboxNameChange(event) {
        this.sandboxName = event.target.value.replace(/\s+/g, ''); // Remove spaces as user types
        this.validateSandboxName(); // Validate the input
    }

    validateSandboxName() {
        let errorMessage = '';
        const sandboxNamePattern = /^[a-zA-Z0-9]*$/; // Alphanumeric only

        if (!sandboxNamePattern.test(this.sandboxName)) {
            errorMessage = 'Sandbox Name must be alphanumeric and cannot contain special characters or spaces.';
        } else if (this.sandboxName.length > 10) {
            errorMessage = 'Sandbox Name cannot exceed 10 characters.';
        }

        if (errorMessage) {
            this.showError(errorMessage);
            // Reset to a valid portion of the input
            this.sandboxName = this.sandboxName.replace(/[^a-zA-Z0-9]/g, '').substring(0, 10);
        }
    }

    @track description = '';
    handleDescriptionChange(event) {
        this.description = event.target.value;
    }

    @track autoActivate = false;
    handleActoActivateChange(event) {
        this.autoActivate = event.target.checked;
        console.log('this.autoActivate ='+this.autoActivate);
    }

    showError(message) {
        // Show a toast message for validation errors
        const event = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
        });
        this.dispatchEvent(event);
    }

    @track refreshStatus = '';
    @track isStatusButtonDisabled = false;

    /*formatDate(date) {
        const month = String(date.getMonth() + 1).padStart(2, '0'); // Month (1-12)
        const day = String(date.getDate()).padStart(2, '0'); // Day
        const year = date.getFullYear(); // Year
        const hours = String(date.getHours()).padStart(2, '0'); // Hours (0-23)
        const minutes = String(date.getMinutes()).padStart(2, '0'); // Minutes (0-59)

        return `${month}/${day}/${year} ${hours}-${minutes}`;
    }*/

    @track lastRefreshedDate;
    @track nextAvailableDate;
    @track lastRunStatus;
    @track lastRefreshedBy;

    get isRefreshDisabled() {
        // Disable if either validateLogUrl or validatedLogName is empty
        if (!this.validateLogUrl || !this.validatedLogName) {
            return true;
        }

        // Disable if either refreshLogUrl or refreshedLogName is empty
        if (!this.refreshLogUrl || !this.refreshedLogName) {
            return true;
        }

        return false;
    }

    /*fetchLastRefreshedBy() {
        getRefreshLogRecordofRefreshTemplate({ templateId: this.recordId })
            .then((result) => {
                console.log('getRefreshLogRecordofRefreshTemplate result: ', result);
                if (result) {
                    this.refreshLogUrl = `/lightning/r/Logs__c/${result.Id}/view`;
                    this.refreshedLogName = result.Name;
                    this.refreshStatus = result.Status__c;
                    //this.lastRefreshedDate = result.Parent_Template__r.Last_Refreshed_Date__c ? result.Parent_Template__r.Last_Refreshed_Date__c : 'N/A';
                    this.lastRefreshedDate = result.Parent_Template__r.Last_Refreshed_Date__c || 'N/A';
                    //this.lastRunStatus = result.Parent_Template__r.Last_Run_Status__c ? result.Parent_Template__r.Last_Run_Status__c : 'N/A';
                    this.lastRunStatus = result.Parent_Template__r.Last_Run_Status__c || 'N/A';
                    //this.lastRefreshedBy = result.Parent_Template__r.Last_Refreshed_By__r.Name ? result.Parent_Template__r.Last_Refreshed_By__r.Name : 'N/A';
                    this.lastRefreshedBy = result.Parent_Template__r.Last_Refreshed_By__r?.Name || 'N/A';
                    console.log('Last Refreshed Date: ', this.lastRefreshedDate);

                    const licenseType = result.Parent_Template__r.Parent_Org__r.License_Type__c?.toLowerCase();
                    console.log('license type in latest refresh log --- ' + licenseType);

                    if (this.lastRefreshedDate !== 'N/A') {
                        const lastRefreshedDate = new Date(this.lastRefreshedDate);
                        let daysToAdd = 0;

                        if (licenseType === 'developer' || licenseType === 'developer pro') {
                            daysToAdd = 1;
                        } else if (licenseType === 'partial copy') {
                            daysToAdd = 5;
                        } else if (licenseType === 'full') {
                            daysToAdd = 29;
                        } else {
                            this.nextAvailableDate = 'N/A';
                        }

                        if (daysToAdd > 0) {
                            const nextDate = new Date(lastRefreshedDate);
                            //nextDate.setUTCDate(nextDate.getUTCDate() + daysToAdd);
                            nextDate.setDate(nextDate.getDate() + daysToAdd);
                            this.nextAvailableDate = nextDate.toISOString();
                        }

                        this.lastRefreshedDate = this.formatDate(new Date(this.lastRefreshedDate));
                        this.nextAvailableDate = this.formatDate(new Date(this.nextAvailableDate));

                        console.log('Next Available Date: ', this.nextAvailableDate);
                    }
                }
                else {
                    console.log('No refreshed record yet for this template.');
                    this.refreshLogUrl = null;
                    this.refreshedLogName = null;
                }
            })
            .catch((error) => {
                console.error('Error fetching Last Refreshed By:', error);
                this.lastRefreshedDate = 'N/A';
                this.nextAvailableDate = 'N/A';
                this.refreshLogUrl = null;
                this.refreshedLogName = null;
            });
    }*/

    showSpinnerForStartRefresh = false;
    @track refreshLogId;
    @track isModalForAutoActivateSandbox = false;
    @track forceShowRefreshIcon = false;
    @track hasFiveMinutesPassed = false;
    @track refreshLogCreatedDate;
    @track refreshDelayRemaining = null;


   /* handleRefresh() {
        console.log('templateId --- ' + this.recordId);

        if (this.selectedSourceForRefresh == '' || this.selectedSourceForRefresh == null) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select the Source Org first...',
                    variant: 'error'
                })
            );
        }
        else if (this.selectedSandboxAccess === 'User Groups (Recommended)' && !this.selectedPublicGroup ) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select a Public Group...',
                    variant: 'error'
                })
            );
        }
        else if (this.autoActivate == false) {
            this.isModalForAutoActivateSandbox = true;
        }
        else {
            console.log('this.refreshStatus ===', this.refreshStatus);
            console.log('this.lastRunStatus ===', this.lastRunStatus);
            if (this.refreshStatus === 'InProgress') {
                console.log('Sandbox Refresh is already in progress.');
                this.showToastMessage('Warning', 'Sandbox Refresh is already in progress. Please wait.', 'warning');
                return;
            }
            else {
                this.showSpinnerForStartRefresh = true;
                console.log('publicGroupId --- ', this.selectedPublicGroup);
                this.startSandboxRefresh();
            }
        }
    }*/

        initializeRefreshIconLogic() {
            // ✅ Check if refresh is already finished
            if (['Completed', 'Failed', 'Forbidden'].includes(this.refreshStatus)) {
                this.showRefreshPendingMessage = false;
                this.showRefreshIconMessage = false;
                console.log(' Skipping icon logic because refresh already completed or forbidden');
                return;
            }

            console.log('this.showRefreshIconMessage 1 ='+this.showRefreshIconMessage);
        
            getLatestRefreshLogCreatedDate({ templateId: this.recordId })
                .then(createdDateStr => {
                    if (createdDateStr) {
                        const createdDate = new Date(createdDateStr);
                        const now = new Date();
                        const delayMs = 1 * 60 * 1000;
                        const targetTime = createdDate.getTime() + delayMs;
                        const timeRemaining = targetTime - now.getTime();
        
                        this.showRefreshPendingMessage = true;
                        this.showRefreshIconMessage = false;

                        console.log('this.showRefreshIconMessage 2 ='+this.showRefreshIconMessage);
        
                        setTimeout(() => {
                            this.hasFiveMinutesPassed = true;
                            this.showRefreshPendingMessage = false;
                            this.showRefreshIconMessage = true;
                            console.log('⏳ 1-minute passed. Refresh icon now visible.');
                            console.log('this.showRefreshIconMessage 3 ='+this.showRefreshIconMessage);
                        }, Math.max(timeRemaining, 0));
                    } else {
                        console.warn(' No refresh log CreatedDate found.');
                    }

                   
                })
                .catch(error => {
                    console.error('❌ Error fetching refresh log CreatedDate:', error);
                });
        }
        
        
 
        handleRefresh() {
            console.log('templateId --- ' + this.recordId);
        
            if (!this.selectedSourceForRefresh) {
                this.showToastMessage('Error', 'Please select the Source Org first...', 'error');
            } else if (this.selectedSandboxAccess === 'User Groups (Recommended)' && !this.selectedPublicGroup) {
                this.showToastMessage('Error', 'Please select a Public Group...', 'error');
            } else if (!this.autoActivate) {
                this.isModalForAutoActivateSandbox = true;
            } else {
                console.log('this.refreshStatus ===', this.refreshStatus);
        
                if (this.refreshStatus === 'InProgress') {
                    if (!this.hasOneMinutePassed) {
                        this.showRefreshPendingMessage = true;
                        this.showRefreshIconMessage = false;
                    } else {
                        this.showRefreshPendingMessage = false;
                        this.showRefreshIconMessage = true;
                    }
        
                    this.showToastMessage('Warning', 'Sandbox Refresh is already in progress. Please wait.', 'warning');
                    return;
                }
        
                this.showSpinnerForStartRefresh = true;
                this.showRefreshPendingMessage = true;
                this.showRefreshIconMessage = false;
        
                this.showToastMessage('info', 'Sandbox Refresh has been initiated. It may take a few minutes.', 'success');
        
                // 🚀 Trigger actual refresh
                this.startSandboxRefresh();
            }
        }
        
         
        startSandboxRefresh() {
        this.isModalForAutoActivateSandbox = false;
        // Set initial state
        this.hasFiveMinutesPassed = false;
        this.forceShowRefreshIcon = false;
        this.showRefreshPendingMessage = true;
        this.showRefreshIconMessage = false;

        callRefreshSandboxQueueable({
            selectedSourceForRefresh: this.selectedSourceForRefresh, templateId: this.recordId,
            sandboxName: this.sandboxName, description: this.description, autoActivate: this.autoActivate, apexClassName: this.apexClassName, publicGroupId: this.selectedPublicGroup
        })
            .then(result => {
                console.log('result -- ' + JSON.stringify(result));
                this.refreshLogId = result;
                this.refreshStatus = 'In Progress';
                console.log('Calling getRefreshLogRecordRecordDetails with ID: ', this.refreshLogId);
                this.getRefreshLogRecordRecordDetails(this.refreshLogId);
                this.initializeRefreshIconLogic();
            })
            .catch(error => {
                console.log('error -- ' + JSON.stringify(error));
                  this.showToastMessage('Error', 'Failed to initiate sandbox refresh.', 'error');
                  this.showRefreshPendingMessage = false;
            })
            .finally(() => {
                setTimeout(() => {
                    this.showSpinnerForStartRefresh = false;
                    console.log('Spinner turned OFF after 12 seconds');
                }, 15000);
               /* setTimeout(() => {
                    this.forceShowRefreshIcon = true;
                    this.hasFiveMinutesPassed = true;
                    this.showRefreshIconMessage = true;
                    this.showRefreshPendingMessage = false; 
                    console.log('Forced refresh icon displayed after 5 minutes.');
                }, 300000);*/
            });
    }


    get isNavigationDisabledBack() {
        if(this.refreshStatus == '' || this.refreshStatus == 'Completed' || this.refreshStatus == 'Forbidden' || this.refreshStatus == 'Failed') {
            if(this.showAuthenticateButton === true){
            console.log('I am in refreshStatus Completed');
            return true;
            }
            if(this.showAuthenticateButton === false){
                console.log('I am in refreshStatus Completed');
                return false;
           }
        }
        if(this.refreshStatus != '' || this.refreshStatus != 'Completed' ) {
            if(this.showAuthenticateButton === false){
                console.log('I am in refreshStatus Completed');
                return true;
                }
        }
        if(this.showAuthenticateButton === true){
            console.log('I am in Autheniticate Available');
            return true;
        }
        if(this.showAuthenticateButton === false){
            console.log('I am in Autheniticate Not Available');
            return false;
        }
    }

    get isNavigationDisablednext() {
        if(this.refreshStatus == '' || this.refreshStatus == 'Completed' || this.refreshStatus == 'Forbidden' || this.refreshStatus == 'Failed') {
            if(this.showAuthenticateButton === true){
            console.log('I am in refreshStatus Completed');
            return true;
            }
            if(this.showAuthenticateButton === false){
                console.log('I am in refreshStatus Completed');
                return false;
                }
        }
        if(this.refreshStatus != '' || this.refreshStatus != 'Completed' ) {
            if(this.showAuthenticateButton === false){
                console.log('I am in refreshStatus Completed');
                return true;
                }
        }
        if(this.showAuthenticateButton === true){
            console.log('I am in Autheniticate Available');
            return true;
        }
        if(this.showAuthenticateButton === false){
            console.log('I am in Autheniticate Not Available');
            return false;
        }
    }

    handleCancelRefresh() {
        this.isModalForAutoActivateSandbox = false;
    }

    handleProceedForRefresh() {
        this.isModalForAutoActivateSandbox = false;
        this.startSandboxRefresh();
    }

    getRefreshLogRecordRecordDetails(refreshLogId) {
        console.log('Fetching details for Log ID: ', refreshLogId);
        getRefreshLogRecord({ logRecId: refreshLogId })
            .then((result) => {
                console.log('getRefreshLogRecord result: ', result);
                if (result) {

                    this.refreshLogUrl = `/lightning/r/Logs__c/${result.Id}/view`;
                    this.refreshedLogName = result.Name;
                    this.refreshStatus = result.Status__c;
                    console.log('this.refreshedLogName : ', this.refreshedLogName);

                    // ✅ Your permission logic
                    const isBasicOnlyUser = this.hasBasicPermissionSet && !this.hasAdvancePermissionSet && !this.isSystemAdmin;
                    console.log('execute Disable permission check --', isBasicOnlyUser);

                  /*  if (this.refreshStatus === 'Completed') {
                        this.showAuthenticateButton = true;
                        this.showAuthenticateMessage = true;
                        this.showRefreshPendingMessage = false;
                        this.showRefreshIconMessage = false;
                        console.log('this.showRefreshIconMessage 2 ='+this.showRefreshIconMessage);
                    }
                    else {
                      this.showAuthenticateButton = false;
                    }*/

                      if (this.refreshStatus === 'Completed') {
                        if (!isBasicOnlyUser) {
                            this.showAuthenticateButton = true;
                            this.showAuthenticateMessage = true;
                        } else {
                            this.showAuthenticateButton = false;
                            this.showAuthenticateMessage = false;
                        }
                        this.showRefreshPendingMessage = false;
                        this.showRefreshIconMessage = false;
                    } else {
                        this.showAuthenticateButton = false;
                    }

                    // Safely access nested properties
                    this.lastRefreshedDate = result.Last_Refreshed_Date__c || 'N/A';
                    this.lastRunStatus = result.Parent_Template__r.Last_Run_Status__c || 'N/A';
                    this.lastRefreshedBy = result.Parent_Template__r.Last_Refreshed_By__r?.Name || 'N/A';
                    this.nextAvailableDate = result.Next_Refresh_Available__c || 'N/A';
                    console.log('Last Refreshed Date: ', this.lastRefreshedDate);

                    const licenseType = result.Parent_Template__r?.Parent_Org__r?.License_Type__c?.toLowerCase();
                    console.log('License type in latest refresh log --- ' + licenseType);

                    if (this.lastRefreshedDate !== 'N/A') {
                        this.lastRefreshedDate = this.formatDate(new Date(this.lastRefreshedDate));
                        this.nextAvailableDate = this.formatDate(new Date(this.nextAvailableDate));
                        console.log('Next Available Date: ', this.nextAvailableDate);
                    }
                } else {
                    console.log('No refreshed record yet for this template.');
                    //this.refreshLogUrl = null;
                    //this.refreshedLogName = null;
                    this.lastRefreshedDate = 'N/A';
                    this.nextAvailableDate = 'N/A';
                    this.showAuthenticateButton = false;
                }
            })
            .catch((error) => {
                console.error('Error fetching Last Refreshed By:', error);
                this.lastRefreshedDate = 'N/A';
                this.nextAvailableDate = 'N/A';
                this.refreshLogUrl = null;
                this.refreshedLogName = null;
               // this.showAuthenticateButton = false;
            });
    }

    get isSourceOrgDisabled() {    
        return this.lastValidatedStatus === 'InProgress' || this.refreshStatus === 'InProgress';
    }

    get isStartRefreshDisabled() {
        console.log('I m in isStartRefreshDisabled');
    
        const permissionCheck = !(this.hasAdvancePermissionSet || this.isSystemAdmin);
        console.log('permissionCheck:', permissionCheck);
        console.log('lastValidatedStatus:', this.lastValidatedStatus);
        console.log('validateLogName:', this.validateLogName);
        console.log('refreshStatus:', this.refreshStatus);
    
        if (
            permissionCheck ||
            this.lastValidatedStatus === 'InProgress' ||
            this.validateLogName === null ||
            this.refreshStatus === 'InProgress'
        ) {
            console.log('Returning true from primary block');
            return true;
        }
    
        if (this.disableStartRefresh) {
            return true;
        }
       
        if (this.showAuthenticateButton) {
            return true;
        }
    
        const allowedStatuses = [null, '', 'Completed', 'Failed', 'Forbidden'];
        const isAllowedStatus = allowedStatuses.includes(this.refreshStatus);
    
        const isAvailableNow =
            !this.nextAvailableDateFromOrg || this.nextAvailableDateFromOrg === 'N/A' ||
            (() => {
                const currentDate = new Date();
                const nextDate = this.parseCustomDate(this.nextAvailableDateFromOrg);
                currentDate.setHours(0, 0, 0, 0);
                nextDate.setHours(0, 0, 0, 0);
                return currentDate >= nextDate;
            })();
    
        if (isAllowedStatus && isAvailableNow) {
            return false;
        }
    
        console.log('Final decision path - disabled = true');
        return true;
    }

    parseCustomDate(dateString) {
        console.log('dateString>> ' + dateString);
        try {
            let parts = dateString.split(', '); 
            let dateParts = parts[0].split('/'); 
            let timePart = parts[1]; 

            let formattedDateString = `${dateParts[2]}-${dateParts[1]}-${dateParts[0]} ${timePart}`;
            return new Date(formattedDateString);
        } catch (error) {
            console.error('Error parsing nextAvailableDate:', error);
            return new Date(); // Default to current date if error occurs
        }
    }

    get nextRefreshMessage() {
        if (this.lastValidatedStatus === 'InProgress') {
            return 'Validation of Template is In Progress';
        }
        if (this.isStartRefreshDisabled && this.nextAvailableDateFromOrg && this.nextAvailableDateFromOrg !== 'N/A') {
            return `Next refresh is on ${this.nextAvailableDateFromOrg}`;
        }
        if (this.disableStartRefresh === true) {
            return `Sandbox refresh is available on ${this.formatDate(new Date(this.lastRefreshDate))}`;
        }
        return '';
    }

    get isValidateTemplateDisabled() {
        // Permission check: Disable if the user doesn't have required permissions
        const permissionCheck = !(this.hasAdvancePermissionSet || this.isSystemAdmin);

        if (
                permissionCheck ||
                this.lastValidatedStatus === 'InProgress' ||
                this.validateLogName === null ||
                this.refreshStatus === 'InProgress'
            ) {
                return true;
            }
        
            if (this.isValidateButtonDisabled) {
                return true;
            }
           
            if (this.showAuthenticateButton) {
                return true;
            }
        
            const allowedStatuses = [null, '', 'Completed', 'Failed', 'Forbidden'];
            const isAllowedStatus = allowedStatuses.includes(this.refreshStatus);
        
            const isAvailableNow =
                !this.nextAvailableDate || this.nextAvailableDate === 'N/A' ||
                (() => {
                    const currentDate = new Date();
                    const nextDate = this.parseCustomDate(this.nextAvailableDate);
                    currentDate.setHours(0, 0, 0, 0);
                    nextDate.setHours(0, 0, 0, 0);
                    return currentDate >= nextDate;
                })();
        
            if (isAllowedStatus && isAvailableNow) {
                return false;
            }
            
            return true;
    }

    get isValidationInProgress() {
        return this.lastValidatedStatus === 'InProgress' || this.lastValidatedStatus === 'Pending' ; // Show "Refresh Validation Status" button
    }

    // Computed property to check if refresh is in progress
    get isRefreshInProgress() {
        console.log('in RefreshIcon =', this.refreshStatus);
        return this.hasFiveMinutesPassed && (
            this.refreshStatus === 'InProgress' ||
            this.refreshStatus === 'Pending' ||
            this.refreshStatus === 'Activating' ||
            this.refreshStatus === 'Processing' ||
            this.refreshStatus === 'Activation Processing' ||
            this.refreshStatus === 'Activation Confirmed' ||
            this.refreshStatus === 'Pending Activation' ||
            this.refreshStatus === 'Pending Remote Creation' ||
            this.refreshStatus === 'Remote Sandbox Created' ||
            this.refreshStatus === 'Sampling'
        );
    }
    

    get showDefaultRefreshButton() {
        // Condition: No log records exist OR both statuses are not "In Progress"
        const noLogRecords = !this.validateLogUrl && !this.refreshLogUrl; // Check if no log records
        const statusesNotInProgress =
            this.lastValidatedStatus !== 'In Progress' &&
            this.refreshStatus !== 'InProgress'; // Check if neither status is "In Progress"
        return noLogRecords || statusesNotInProgress;
    }

    @track showSpinnerForValidation = false;
    @track showSpinnerForRefresh = false;
    @track isStatusButtonDisabled = false;

    get noLogsInProgress() {
        return !this.isValidationInProgress && !this.isRefreshInProgress;
    }

   /* handleRefreshStatus() {
        console.log('Im in isRefreshInProgress');
        this.isStatusButtonDisabled = true;
        this.showSpinnerForRefresh = true;
        const parts = this.refreshLogUrl.split('/');
        const logRecordId = parts[4];
        console.log('logRecordId: --- ', logRecordId);

        getSandboxStatus({ logRecordId: logRecordId, templateId: this.recordId })
            .then(result => {
                console.log('getSandboxStatus result -- ' + JSON.stringify(result));
                this.refreshStatus = result;
                //this.lastRunStatus = result;

                // Check if result is 'Deleted'
               

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Refresh Status',
                        message: `Sandbox Refresh status is ${this.refreshStatus}`,
                        variant: 'info'
                    })
                );
                if(this.refreshStatus === 'Forbidden' || this.refreshStatus === 'Completed' || this.refreshStatus === 'Failed'){
                    this.showRefreshPendingMessage = false;
                    this.showRefreshIconMessage = false;
                    this.selectedSourceForRefresh = '';
                    this.selectedSourceForRefresh = null;
                    console.log('before this.autoActivate');
                    this.autoActivate = false;
                    console.log('after this.autoActivate');
                }
                if(this.refreshStatus === 'Completed')
                
                return refreshApex(this.wiredData);
            })
            .catch(error => {
                console.log('error -- ' + JSON.stringify(error));
            })
            .finally(() => {
                setTimeout(() => {
                    this.isStatusButtonDisabled = false;
                    this.showSpinnerForRefresh = false;
                }, 2000);
            });
    }*/

            handleRefreshStatus() {
                console.log('Im in isRefreshInProgress');
                this.isStatusButtonDisabled = true;
                this.showSpinnerForRefresh = true;
            
                const parts = this.refreshLogUrl.split('/');
                const logRecordId = parts[4];
                console.log('logRecordId: --- ', logRecordId);
            
                getSandboxStatus({ logRecordId: logRecordId, templateId: this.recordId })
                    .then(result => {
                        console.log('getSandboxStatus result -- ' + JSON.stringify(result));
                        this.refreshStatus = result;
            
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Refresh Status',
                                message: `Sandbox Refresh status is ${this.refreshStatus}`,
                                variant: 'info'
                            })
                        );
            
                        if (['Forbidden', 'Completed', 'Failed'].includes(this.refreshStatus)) {
                            this.showRefreshPendingMessage = false;
                            this.showRefreshIconMessage = false;
                            this.selectedSourceForRefresh = null;
                            this.autoActivate = false;
                        }
            
                        this.showAuthenticateButton = (this.refreshStatus === 'Completed');
                        this.showAuthenticateMessage = this.showAuthenticateButton; 
            
                        return refreshApex(this.wiredData);
                    })
                    .catch(error => {
                        console.log('error -- ' + JSON.stringify(error));
                    })
                    .finally(() => {
                        setTimeout(() => {
                            this.isStatusButtonDisabled = false;
                            this.showSpinnerForRefresh = false;
                        }, 2000);
                    });
            }

    handleBackToPreRefreshPage() {
        this.currentvalue = '1'; // Update the current step to Pre-Refresh
        this.updateStepClasses(this.currentvalue); // Update progress indicator classes

        // Adjust visibility flags
        this.showRefreshPage = false;
        this.showDataRetrievalPage = true;
    }

    @track isValidated = false;
    @track asyncResultId = '';
    @track validateLogUrl;
    @track refreshLogUrl;
    @track validatedLogName;
    @track lastValidatedStatus;
    @track lastValidatedDate;
    @track refreshedLogName;
    @track lastValidatedBy;

    /*getLatestValidationDetails(templateId) {
        getValidationLogRecordofRefreshTemplate({ templateId: templateId })
            .then((data) => {
                console.log('getValidationLogRecordofRefreshTemplate data: ', data);
                if (data) {
                    this.validateLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
                    this.validatedLogName = data.Name;
                    this.lastValidatedStatus = data.Status__c;
                    this.lastValidatedDate = data.Last_Validated_Date__c;
                    this.lastValidatedBy = data.LastModifiedBy.Name;
                }
                else {
                    console.log('there is no validated record yet for this template ---- ');
                    this.validateLogUrl = null;
                    this.validatedLogName = null;
                }
            })
            .catch((error) => {
                console.error('Error fetching logs:', error);
                this.logs = []; // Clear logs on error
                this.validateLogUrl = null;
                this.validatedLogName = null;
            });
    }*/

    getLatestValidationLogRec(logRecId) {

        getValidationLogRecord({ logRecId: logRecId })
            .then((data) => {
                console.log('getValidationLogRecordofRefreshTemplate data: ', data);
                if (data) {
                    this.validateLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
                    this.validatedLogName = data.Name;
                    this.lastValidatedStatus = data.Status__c;
                    this.lastValidatedDate = data.Last_Validated_Date__c;
                    this.lastValidatedBy = data.LastModifiedBy.Name;
                }
                else {
                    console.log('there is no validated record yet for this template ---- ');
                    this.validateLogUrl = null;
                    this.validatedLogName = null;
                }
            })
            .catch((error) => {
                console.error('Error fetching logs:', error);
                this.logs = []; // Clear logs on error
                this.validateLogUrl = null;
                this.validatedLogName = null;
            });

    }

    @track validationStatus = '';
    handleRefreshValidationStatus() {
        console.log('Im in ValidationInProgress');
        this.isStatusButtonDisabled = true;
        this.showSpinnerForValidation = true;
        const parts = this.validateLogUrl.split('/');
        const logRecordId = parts[4];
        console.log('logRecordId: --- ', logRecordId);

        checkValidationStatus({ logRecordId: logRecordId })
            .then((data) => {
                console.log('validation result data: ', data);
                this.validationStatus = data;
                //this.getLatestValidationLogRec(logRecordId);
                this.lastValidatedStatus = data;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Validation Status',
                        message: `Validation status is ${data}`,
                        variant: 'info'
                    })
                );

                if(this.validationStatus == 'Failed' || this.validationStatus == 'Completed' || this.validationStatus == 'Success'){
                    this.selectedSourceForRefresh = '';
                    this.selectedSourceForRefresh = null;
                    console.log('before this.autoActivate'+this.autoActivate);
                    this.autoActivate = false;
                    console.log('after this.autoActivate'+this.autoActivate);
                }
                return refreshApex(this.wiredDataValid);
            })
            .then(() => {
                console.log('Updated validation log');
            })
            .catch((error) => {
                console.error('Error fetching logs:', error);
                this.validationStatus = 'Error loading the status. Please contact System Admin.'
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error loading the status. Please contact System Admin.',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                setTimeout(() => {
                    this.isStatusButtonDisabled = false;
                    this.showSpinnerForValidation = false;
                   
                }, 2000);
            });
    }

    @track logRecordId;
    @track templateId;
    @track showSpinnerForValidationTemplate = false;
    
    handleValidateTemplate() {
        console.log('templateId --- ' + this.recordId);
        this.isValidated = false;
        this.showSpinnerForValidationTemplate = true;
        if (this.selectedSourceForRefresh == '' || this.selectedSourceForRefresh == null) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select the Source Org first...',
                    variant: 'error'
                })
            );
            this.showSpinnerForValidationTemplate = false;
        }
        else {
            if (this.lastValidatedStatus === 'InProgress') {
                console.log('Validation is already in progress.');
                this.showToastMessage('Warning', 'Validation is already in progress. Please wait.', 'warning');
                return;
            }
            else {

                this.showSpinnerForValidationTemplate = true;
                validatePackage({ orgId: this.selectedSourceForRefresh, templateId: this.recordId })
                    .then(result => {
                        console.log('result -- ' + result);
                        //this.asyncResultId = result;
                        //this.handleGetValidationStatus();
                        this.logRecordId = result;
                        this.getLatestValidationLogRec(this.logRecordId); // Update logs after validation
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Info',
                                message: 'Validate Template is started.',
                                variant: 'info',
                            })
                        );
                        this.showSpinnerForValidationTemplate = false;
                    })
                    .catch(error => {
                        console.log('error -- ' + JSON.stringify(error));
                        console.log('error message --- ' + error.body.message);
                        this.showSpinnerForValidationTemplate = false;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: error.body.message,
                                variant: 'error'
                            })
                        );
                        this.showSpinnerForValidationTemplate = false;
                    });
            }
        }
    }

    @track dataOfValidationResultForSuccess;
    @track dataOfValidationResultForFailure;
    @track columnsForValidationResultForSucess = [];
    @track columnsForValidationResultForFailure = [];
    @track isValidationSuccess = false;
    @track isValidationFailure = false;
    @track failureComponentList = [];
    @track successComponentList = [];
    @track showSpinnerForValidation = false;



    handleGetValidationStatus() {
        console.log('templateId --- ' + this.recordId);
        console.log('asyncResultId --- ' + this.asyncResultId);
        getValidationResult({ orgId: this.selectedSourceForRefresh, templateId: this.recordId, asyncResultId: this.asyncResultId })
            .then(result => {
                console.log('result -- ' + JSON.stringify(result));
                this.columnsForValidationResultForSucess = columnsForValidationResultForSucess;
                this.columnsForValidationResultForFailure = columnsForValidationResultForFailure;
                this.dataOfValidationResultForSuccess = [];
                this.dataOfValidationResultForFailure = [];

                console.log('result.allComponentsChecked --- ' + result.allComponentsChecked);
                let allComponentsChecked = result.allComponentsChecked || false;

                if (allComponentsChecked) {
                    this.successComponentList = result.successList || [];
                    this.isValidationSuccess = (result.successList.length > 0) ? true : false;

                    this.failureComponentList = result.failureList || [];
                    this.isValidationFailure = (result.failureList.length > 0) ? true : false;

                    console.log('this.isValidationSuccess --- ' + this.isValidationSuccess + ', this.isValidationFailure --- ' + this.isValidationFailure);


                    this.successComponentList.forEach(objWrap => {
                        this.dataOfValidationResultForSuccess.push({
                            successCompName: String(objWrap['successCompName']),
                            successCompType: String(objWrap['successCompType'])
                        });
                    });

                    this.failureComponentList.forEach(objWrap => {
                        this.dataOfValidationResultForFailure.push({
                            compName: String(objWrap['compName']),
                            compType: String(objWrap['compType']),
                            problem: String(objWrap['problem']),
                            problemType: String(objWrap['problemType']),
                            //success : Boolean(objWrap['success']),
                            //warning : Boolean(objWrap['warning']),
                            lineNumber: String(objWrap['lineNumber']),
                            columnNumber: String(objWrap['columnNumber']),
                        });
                    });


                    console.log('--- validation completed ---');
                    this.isValidated = true;
                    this.showSpinnerForValidation = false;
                }
                else {
                    this.isValidated = false;
                    this.showSpinnerForValidation = true;
                    this.handleGetValidationStatus();
                }

            })
            .catch(error => {
                console.log('error -- ' + JSON.stringify(error));
            });
    }

    @track url;

    handleReAuthenticate() {
        let params = { "orgId": this.parentOrgId, "templateId": this.recordId };
        reAuthenticate(params)
            .then((result) => {
                this.url = result;
                console.log('this.url === ' + this.url);
                window.open(this.url);
            })
            .catch((error) => {
                console.log(error);
            })
    }


    /****************** END OF SANDBOX REFRESH PAGE CODE BLOCK ******************/


    /****************** METADATA RESTORE PAGE CODE BLOCK ******************/

    @track deployLogUrl;
    @track deployLogName;
    @track lastDeploymentStatus;
    @track lastDeploymentDate;
    @track lastDeploymentBy;
    @track deployLogId;
    @track showSpinnerForValidation = false;

    @wire(getDeployLogRecordofRefreshTemplate, { templateId: '$recordId' })
    wiredLogDeploy(result) {
        this.wiredDataDeploy = result; // Store result for manual refresh
        const { error, data } = result;
        if (data) {
            this.deployLogId = data.Id;
            this.deployLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
            this.deployLogName = data.Name;
            this.lastDeploymentDate = data.Last_Deployment_Date__c;
            this.lastDeploymentStatus = data.Status__c;
            console.log('Deployment Log Name: ', this.validatedLogName);
            console.log('Deployment Log URL: ', this.validateLogUrl);

            /*if (data.Status__c == 'InProgress' || data.Status__c == 'Pending') {
                this.handleRefreshDeploymentStatus();
            }*/

            this.error = undefined;
        } else if (error) {
            this.error = error; // Handles error
            this.latestLog = undefined;
            this.computeShowMetaDataRestoreRefresh();
        }
    }

    handleBackFromMetadataRestore() {
        this.currentvalue = '2'
        this.updateStepClasses(this.currentvalue);

        this.showMetadataRestore = false;
        this.showRefreshPage = true;
        this.recordsPerPage = 5;
        this.metadataPageSize = 5;
        this.updatePagedUsers();
        this.updatePagedUsersPre();
        this.updatePagedCustomSettings();
        this.updatePagedScheduleJobs();
        this.initializePagination();
        this.initializePaginationPre();
        this.initializeCustomSettingsPagination();
        this.updateMetadataDisplay();
    }


    handleNextFromMetadataRestore() {
        this.currentvalue = '4'
        this.updateStepClasses(this.currentvalue);

        this.showMetadataRestore = false;
        //this.showRestorePage = true;
        this.showMetadataMaskingPage = true;
        //this.showDataMaskingPage = true;
        this.recordsPerPage = 5;
        this.metadataPageSize = 5;
        this.updatePagedUsers();
        this.updatePagedUsersPre();
        this.updatePagedCustomSettings();
        this.updatePagedScheduleJobs();
        this.initializePagination();
        this.initializePaginationPre();
        this.initializeCustomSettingsPagination();
        this.updateMetadataDisplay();
    }

    @track isExecutingMetadataRestore = false;
    @track deployLogId;

   /* handleExecuteClick() {
        console.log('handleExecuteClick() triggered'); // ✅ Debug log
        if (!this.parentOrgId || !this.recordId) {
            console.log('Missing Org ID or Template ID'); // ✅ Debug log
            this.showToastMessage('Error', 'Org ID or Template ID is missing!', 'error');
            return;
        }

        console.log('Calling deployPackage with:', this.parentOrgId, this.recordId);
        console.log('this.lastDeploymentStatus --- ', this.lastDeploymentStatus);
        if (this.lastDeploymentStatus === 'InProgress') {
            console.log('Deployment is already in progress.');
            this.showToastMessage('Warning', 'Deployment is already in progress. Please wait.', 'warning');
            return;
        }
        else {
            this.isExecutingMetadataRestore = true;
            deployPackage({ orgId: this.parentOrgId, templateId: this.recordId })
                .then((deployLogId) => {
                    console.log('Deployment Log Created with ID:', deployLogId);
                    this.deployLogId = deployLogId;
                    this.getDeployLogRecord(deployLogId);
                    this.showToastMessage('', 'Deployment started successfully!', 'info');
                })
                .catch((error) => {
                    console.error('Error during deployment:', error);
                    this.showToastMessage('Error', 'Failed to start deployment!', 'error');
                })
                .finally(() => {
                    setTimeout(() => {
                        this.isExecutingMetadataRestore = false;
                    }, 2000);

                });
        }
    }*/

       handleExecuteClick() {
            console.log('handleExecuteClick() triggered');
        
            if (!this.parentOrgId || !this.recordId) {
                this.showToastMessage('Error', 'Org ID or Template ID is missing!', 'error');
                return;
            }
        
            if (this.lastDeploymentStatus === 'InProgress') {
                this.showToastMessage('Warning', 'Deployment is already in progress. Please wait.', 'warning');
                return;
            }
        
            this.isExecutingMetadataRestore = true;   
            this.showToastMessage('', 'Deployment initiated successfully!', 'info');
            this.lastDeploymentStatus = 'InProgress'; 
        
            deployPackage({ orgId: this.parentOrgId, templateId: this.recordId })
                .then((deployLogId) => {
                    console.log('Deployment Log Created with ID:', deployLogId);
                    this.deployLogId = deployLogId;
                    this.getDeployLogRecord(deployLogId);
                })
                .catch((error) => {
                    console.error('Error during deployment:', error);
                    this.showToastMessage('Error', 'Failed to start deployment!', 'error');
                    this.lastDeploymentStatus = '';
                })
                .finally(() => {
                    setTimeout(() => {
                        this.isExecutingMetadataRestore = false;  
                    }, 2000);
                });
        }
        
        handleRefreshDeploymentStatus() {
            console.log('Im in ShowRefreshIcon');
            this.showSpinnerForValidation = true;
            
            checkDeploymentStatus({ logRecordId: this.deployLogId })
                .then((data) => {
                    console.log('deployment result data: ', data);
        
                    let title = 'Deployment Status';
                    let message = '';
                    let variant = 'info';
        
                    if (data === 'Succeeded') {
                        this.lastDeploymentStatus = 'Success';
                        message = 'Deployment completed successfully.';
                        variant = 'success';
                    } else if (data === 'Failed') {
                        this.lastDeploymentStatus = 'Failed';
                        message = 'Deployment failed. Please check the log for details.';
                        variant = 'error';
                    } else if (data === 'Pending') {
                        this.lastDeploymentStatus = 'Pending';
                        message = 'Deployment is pending. Please wait and try again shortly.';
                        variant = 'info';
                    } else {
                        this.lastDeploymentStatus = 'InProgress';
                        message = 'Deployment is in progress. Please stay on this page and refresh again later.';
                        variant = 'info';
                    }
        
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: title,
                            message: message,
                            variant: variant,
                        })
                    );
        
                    return refreshApex(this.wiredDataDeploy);
                })
                .then(() => {
                    console.log('Updated deployment log');
                })
                .catch((error) => {
                    console.error('Error fetching logs:', error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Error loading the status. Please contact System Admin.',
                            variant: 'error',
                        })
                    );
                })
                .finally(() => {
                    setTimeout(() => {
                        this.showSpinnerForValidation = false;
                    }, 1000);
                });
        }
        

    get isExecuteButtonDisabledMR() {
        // Permission check: Disable if the user doesn't have required permissions
        const permissionCheck = !(this.hasAdvancePermissionSet || this.isSystemAdmin);

        // Disable the button if any of the following conditions are true:
        return permissionCheck ||
            this.isExecutingMetadataRestore ||
            this.isValidateButtonDisabled ||
            this.lastDeploymentStatus === 'InProgress' ||
            this.lastDeploymentStatus === 'Pending' ||
            this.showAuthenticateButton ||
            this.hasInProgressMetadataBackupLog;
    }

    get showRefreshIcon() {
        return this.lastDeploymentStatus === 'InProgress' || this.lastDeploymentStatus === 'Pending';
    }

    computeShowMetaDataRestoreRefresh() {
        // If either record is InProgress, keep the refresh icon visible
        this.showRefreshIcon = (this.isExecutingMetadataRestore || this.isValidateButtonDisabled || this.lastDeploymentStatus === 'InProgress');
    }

    // Utility function to show toast messages
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }

    getDeployLogRecord(deployLogId) {
        getDeployLogRecord({ logRecId: deployLogId })
            .then((data) => {
                console.log('getDeployLogRecord data: ', data);
                if (data) {
                    this.deployLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
                    this.deployLogName = data.Name;
                    this.lastDeploymentStatus = data.Status__c;
                    this.lastDeploymentDate = data.Last_Deployment_Date__c;
                    this.lastDeploymentBy = data.LastModifiedBy?.Name;
                }
                else {
                    console.log('there is no validated record yet for this template ---- ');
                    this.deployLogUrl = null;
                    this.deployLogName = null;
                }
            })
    }


    /****************** END OF METADATA RESTORE PAGE CODE BLOCK ******************/


    /****************** RESTORE PAGE CODE BLOCK ******************/

    @track selectedSandboxAccess = 'All Active Users'; // Default value
    @track isUserGroupSelected = false;
    @track userGroupInput = '';

    // Radio options for Sandbox Access
    get sandboxAccessOptions() {
        if (this.orgType === 'Production') {
            // For Production, only show "User Groups (Recommended)"
            return [
                { label: 'User Groups (Recommended)', value: 'User Groups (Recommended)' }
            ];
        } else if (this.orgType === 'Sandbox') {
            // For Sandbox, show both options
            return [
                { label: 'All Active Users', value: 'All Active Users' }
                //{ label: 'User Groups (Recommended)', value: 'User Groups (Recommended)' }
            ];
        }
        return [];
    }

    // Handle Sandbox Access radio button change
    handleSandboxAccessChange(event) {
        this.selectedSandboxAccess = event.detail.value;
        this.isUserGroupSelected = this.selectedSandboxAccess === 'User Groups (Recommended)';
    }

    // Handle User Group text input change
    handleUserGroupInputChange(event) {
        this.userGroupInput = event.target.value;
    }

    handleBackFromRestorePage() {
        this.currentvalue = '4'
        this.updateStepClasses(this.currentvalue);

        this.showRestorePage = false;
        this.showMetadataMaskingPage = true;
        this.recordsPerPage = 5;
        this.metadataPageSize = 5;
        this.updatePagedUsers();
        this.updatePagedUsersPre();
        this.updatePagedCustomSettings();
        this.updatePagedScheduleJobs();
        this.initializePagination();
        this.initializePaginationPre();
        this.initializeCustomSettingsPagination();
        this.updateMetadataDisplay();

    }

    handleNextFromRestorePage() {
        this.currentvalue = '6';
        this.showRestorePage = false;
        this.updateStepClasses(this.currentvalue);
        this.showDataMaskingPage = true;
        this.recordsPerPage = 5;
        this.metadataPageSize = 5;
        this.updatePagedUsers();
        this.updatePagedUsersPre();
        this.updatePagedCustomSettings();
        this.updatePagedScheduleJobs();
        this.initializePagination();
        this.initializePaginationPre();
        this.initializeCustomSettingsPagination();
        this.updateMetadataDisplay();
       
    }

    handleRestoreData() {
        console.log('restore data');
    }

    @track userColumns = [
        { label: 'Full Name', fieldName: 'Name', type: 'text', sortable: true },
        { label: 'First Name', fieldName: 'FirstName', type: 'text', sortable: true },
        { label: 'Last Name', fieldName: 'LastName', type: 'text', sortable: true },
        { label: 'Email', fieldName: 'Email', type: 'text', sortable: true },
        { label: 'Username', fieldName: 'Username', type: 'text', sortable: true },
        { label: 'Profile', fieldName: 'ProfileName', type: 'text', sortable: true }
    ];



  /*  @track customSettingsColumns = [
        { label: 'Custom Setting Name', fieldName: 'name', type: 'text', sortable: true }
    ];*/

    @track customSettingsColumns = [
        { label: 'Custom Setting Name', fieldName: 'name', type: 'text', sortable: true },
        { label: 'Record Count', fieldName: 'count', type: 'number', sortable: true, cellAttributes: { alignment: 'left' } }
    ];
    

    @track selectedRecords = [];
    @track filteredCustomSettings = [];
    @track isPermissionSetsAndGroupsChecked = false;
    @track isGroupsChecked = false;
    @track selectedPermissionSetsAndGroups = [];
    @track selectedGroups = [];
    @track selectedUsers = []; 
    @track isExecuting = false; 
    @track totalPagesCustomSettings = 0;
    @track showExecuteModal = false;


    @track filteredUsers = [];
    @track originalUsers = [];
    @track pagedUsers = [];
    @track permissionSets = [];
    @track groups = [];
    @track permissionSetGroups = [];
    @track customSettingsSearch = '';
    @track customSettings = [];
    @track originalCustomSettings = [];
    @track currentPageCustomSettings = 1;
    @track pagedCustomSettings = [];

    @track combinedPermissionData = [];

    @track userSearch = '';
    @track userSearchOnLoad = '';
    @track csvFilename = ''; // To store CSV file name
    @track lastSaveDate = null;
    @track currentPageUsers = 1;
    @track totalPagesUsers = 0;
    @track pageSizeOptions = [5, 10, 25, 50, 100];
    @track recordsPerPage = 5;
    @track selectedCustomSettings = [];
    // Track section inclusion
    @track includeUsersInfo = false;
    @track includeCustomSettings = false;
    @track includeScheduleJobs = false;
    @track includeDeleteScheduleJobs = false;
    @track isExecuting = false;
    @track noRecordsFound = false;
    @track isLoadingUsers = true;
    @track isLoadingCustomSettings = true;
    @track isLoadingScheduleJobs = true;

    @track userDataRestoreLogUrl;
    @track userDataRestoreLogName;
    @track userDataRestoreStatus;
    @track userDataRestoreLogId;
    @track csDataRestoreLogUrl;
    @track csDataRestoreLogName;
    @track csDataRestoreStatus;
    @track csDataRestoreLogId;
    @track executionStarted = false;


    @track originalUsersPre = [];
    @track filteredUsersPre = [];
    @track pagedUsersPre = [];
    @track userSearchOnLoadPre = '';
    @track currentPageUsersPre = 1;
    @track totalPagesUsersPre = 0;
    @track selectedUsersPre = [];
    @track isLoadingUsersPre = true;
    @track sortDirectionPre = 'asc';
    @track sortedByPre;
   
    @wire(readJSONFromRelatedFiles, { recordId: '$recordId' })
    wiredUserData(result) {
        // Store the wire result for refreshing later
        this.wiredUserDataResult = result;

        const { error, data } = result;
        this.isLoadingUsers = true;
        try {
            if (data) {
                console.log('Data fetched from Apex:', JSON.stringify(data));
                this.originalUsers = data.map(item => ({
                    ...item,
                    ProfileName: item.ProfileName ? item.ProfileName : 'N/A'
                }));
                this.filteredUsers = [...this.originalUsers];
                this.initializePagination();
                this.templateFields.isUserDataSelected = this.originalUsers.length > 0;
            } else if (error) {
                console.error('Error loading JSON data:', error);
                this.showToastMessage('Error', 'Error loading JSON data', 'error');
            }
        } finally {
            this.isLoadingUsers = false;
        }
    }

    @wire(readJSONFromRelatedFiles, { recordId: '$recordId' })
    wiredUserDataPre(result) {
        // Store the wire result for refreshing later
        this.wiredUserDataResultPre = result;

        const { error, data } = result;
        this.isLoadingUsersPre = true;
        try {
            if (data) {
                console.log('Data fetched from Apex:', JSON.stringify(data));
                this.originalUsersPre = data.map(item => ({
                    ...item,
                    ProfileName: item.ProfileName ? item.ProfileName : 'N/A'
                }));
                this.filteredUsersPre = [...this.originalUsersPre];
                this.initializePaginationPre();
                this.templateFields.isUserDataSelected = this.originalUsersPre.length > 0;
            } else if (error) {
                console.error('Error loading JSON data:', error);
                this.showToastMessage('Error', 'Error loading JSON data', 'error');
            }
        } finally {
            this.isLoadingUsersPre = false;
        }
    }

    @track showUserDefaultMessage = false;
    @track showDataRestoreSpinner = false;

    @wire(getUsersDataRestoreLogRecordofRefreshTemplate, { templateId: '$recordId' })
    wiredUsersLog(result) {
        this.wiredUsersLogResult = result;
        const { data, error } = result;
        if (data) {
            this.userDataRestoreLogId = data.Id;
            this.userDataRestoreLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
            this.userDataRestoreLogName = data.Name;
            this.userDataRestoreStatus = data.Status__c;
            console.log('users data ---', data);
            
        } else if (error) {
            this.usersError = error;
            this.usersLog = undefined;
        }
        this.showUserDefaultMessage = data == null ? true : false;
        this.computeShowDataRestoreRefresh();
    }

    // Wire method to get the Custom Settings Restoration log record
    @wire(getCustomSettingsDataRestoreLogRecordofRefreshTemplate, { templateId: '$recordId' })
    wiredCustomSettingsLog(result) {
        this.wiredCustomSettingsLogResult = result;
        const { data, error } = result;
        if (data) {
            this.csDataRestoreLogId = data.Id;
            this.csDataRestoreLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
            this.csDataRestoreLogName = data.Name;
            this.csDataRestoreStatus = data.Status__c;
            console.log('cs data ---', data);
           
        } else if (error) {
            this.customSettingsError = error;
            this.customSettingsLog = undefined;
        }
        this.showUserDefaultMessage = data == null ? true : false;
        this.computeShowDataRestoreRefresh();
    }

    userRestoreSuccessToastShown = false;
    userRestoreFailedToastShown = false;
    csRestoreSuccessToastShown = false;
    csRestoreFailedToastShown = false;
    scheduleRestoreSuccessToastShown = false;
    scheduleRestoreFailedToastShown = false;
    deleteScheduleRestoreSuccessToastShown = false;
    deleteScheduleRestoreFailedToastShown = false;

    userRestoreSuccessToastShown = false;
    userRestoreFailedToastShown = false;
    
    csRestoreSuccessToastShown = false;
    csRestoreFailedToastShown = false;
    
    scheduleRestoreSuccessToastShown = false;
    scheduleRestoreFailedToastShown = false;
    
    deleteScheduleRestoreSuccessToastShown = false;
    deleteScheduleRestoreFailedToastShown = false;
    
    handleRefreshDataRestore() {
        console.log('Refreshing statuses...');
        this.showDataRestoreSpinner = true;
    
        getAllDataRestoreStatuses({ templateId: this.recordId })
            .then(statusMap => {
                console.log('Status Map:', statusMap);
               
                this.userDataRestoreStatus = statusMap['User Restoration - Post Refresh'] || null;
                this.csDataRestoreStatus = statusMap['Custom Settings Restoration - Post Refresh'] || null;
               /* this.scheduleJobsRestoreStatus = statusMap['Scheduled Jobs Restoration - Post Refresh'] || null;
                this.deleteScheduleJobsRestoreStatus = statusMap['Delete Scheduled Jobs - Post Refresh'] || null;*/
    
                if (this.userDataRestoreStatus === 'InProgress') {
                    this.wasUserExecutionTriggered = true;
                }

                if (this.csDataRestoreStatus === 'InProgress') {
                    this.wasCSExecutionTriggered = true;
                }

             /*   if (this.scheduleJobsRestoreStatus === 'InProgress') {
                    this.wasScheduleJobExecutionTriggered = true;
                }

                if (this.deleteScheduleJobsRestoreStatus === 'InProgress') {
                    this.wasDeleteScheduleJobExecutionTriggered = true;
                }*/

                this.computeShowDataRestoreRefresh();
    
                this.disableDataRestoreExecution = 
                    this.userDataRestoreStatus === 'InProgress' ||
                    this.csDataRestoreStatus === 'InProgress' ;
    
                // USER RESTORE TOAST
                if(this.wasUserExecutionTriggered){
                    if (this.userDataRestoreStatus === 'InProgress') {
                        this.showToastMessage1('User Restoration', 'User Data Restoration is In Progress.', 'info');
                    } else if (this.userDataRestoreStatus === 'Failed' && !this.userRestoreFailedToastShown) {
                        this.showToastMessage1('User Restoration', 'User Data Restoration Failed.', 'error');
                        this.userRestoreFailedToastShown = true;
                    } else if ((this.userDataRestoreStatus === 'Completed' || this.userDataRestoreStatus === 'Success'  ) && !this.userRestoreSuccessToastShown) {
                        this.showToastMessage1('User Restoration', 'User Data Restoration Completed Successfully.', 'success');
                        this.userRestoreSuccessToastShown = true;
                    }
                }
    
                // CUSTOM SETTINGS TOAST
                if (this.wasCSExecutionTriggered) {
                    if (this.csDataRestoreStatus === 'InProgress') {
                        this.showToastMessage1('Custom Settings Restoration', 'Custom Settings Restoration is In Progress.', 'info');
                    } else if (this.csDataRestoreStatus === 'Failed' && !this.csRestoreFailedToastShown) {
                        this.showToastMessage1('Custom Settings Restoration', 'Custom Settings Restoration Failed.', 'error');
                        this.csRestoreFailedToastShown = true;
                    } else if ((this.csDataRestoreStatus === 'Completed' || this.csDataRestoreStatus === 'Success') && !this.csRestoreSuccessToastShown) {
                        this.showToastMessage1('Custom Settings Restoration', 'Custom Settings Restoration Completed Successfully.', 'success');
                        this.csRestoreSuccessToastShown = true;
                    }
                }
        
                /* SCHEDULED JOBS TOAST
                if (this.wasScheduleJobExecutionTriggered) {
                    if (this.scheduleJobsRestoreStatus === 'InProgress') {
                        this.showToastMessage1('Scheduled Jobs Restoration', 'Scheduled Jobs Restoration is In Progress.', 'info');
                    } else if (this.scheduleJobsRestoreStatus === 'Failed' && !this.sjRestoreFailedToastShown) {
                        this.showToastMessage1('Scheduled Jobs Restoration', 'Scheduled Jobs Restoration Failed.', 'error');
                        this.sjRestoreFailedToastShown = true;
                    } else if (this.scheduleJobsRestoreStatus === 'Success' && !this.sjRestoreSuccessToastShown) {
                        this.showToastMessage1('Scheduled Jobs Restoration', 'Scheduled Jobs Restoration Completed Successfully.', 'success');
                        this.sjRestoreSuccessToastShown = true;
                    }
                }
    
                // DELETE SCHEDULED JOBS TOAST
                if (this.wasDeleteScheduleJobExecutionTriggered) {
                    if (this.deleteScheduleJobsRestoreStatus === 'InProgress') {
                        this.showToastMessage1('Delete Scheduled Jobs', 'Delete Scheduled Jobs Restoration is In Progress.', 'info');
                    } else if (this.deleteScheduleJobsRestoreStatus === 'Failed' && !this.deleteSJRestoreFailedToastShown) {
                        this.showToastMessage1('Delete Scheduled Jobs', 'Delete Scheduled Jobs Restoration Failed.', 'error');
                        this.deleteSJRestoreFailedToastShown = true;
                    } else if (this.deleteScheduleJobsRestoreStatus === 'Success' && !this.deleteSJRestoreSuccessToastShown) {
                        this.showToastMessage1('Delete Scheduled Jobs', 'Delete Scheduled Jobs Restoration Completed Successfully.', 'success');
                        this.deleteSJRestoreSuccessToastShown = true;
                    }
                }*/

    
            /*   if (!this.showDataRetoreRefresh) {
                    this.executionStarted = false;
                }*/
                
            })
            .catch(error => {
                console.error('Error fetching statuses:', error);
                this.showToastMessage1('Error', 'Failed to fetch restore statuses.', 'error');
            })
            .finally(() => {
                this.showDataRestoreSpinner = false;

                // ✅ Only stop execution flag when refresh icon is shown
                if (this.showDataRetoreRefresh) {
                    this.executionStarted = false;
                }
            });
    }
    
    computeShowDataRestoreRefresh() {
        this.showDataRetoreRefresh = (
            this.userDataRestoreStatus === 'InProgress' ||
            this.csDataRestoreStatus === 'InProgress');
        if (this.showDataRetoreRefresh) {
            this.showRefreshIconMessageOnData = false;
        }
    }

    showStatusToast() {
        let inProgressMessages = [];
    
        if (this.userDataRestoreStatus === 'InProgress') {
            inProgressMessages.push('User Restoration - Post Refresh: In Progress');
        }
        if (this.csDataRestoreStatus === 'InProgress') {
            inProgressMessages.push('Custom Settings Restoration - Post Refresh: In Progress');
        }
       
        if (inProgressMessages.length > 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Logs In Progress',
                message: inProgressMessages.join('\n'),
                variant: 'info'
            }));
        } else {
            this.dispatchEvent(new ShowToastEvent({
                title: 'All Logs Completed',
                message: 'All data restore processes are completed successfully.',
                variant: 'success'
            }));
        }
    }
        

     // ✅ Toast Helper
    showToastMessage(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant || 'info'
        }));
    }
    

    extractUniqueItems(data, key, subKey = null) {
        const items = data.flatMap(item =>
            item[key] ?
                (subKey ?
                    item[key].map(i => ({ Name: i[subKey] })) :
                    item[key].map(i => ({ Name: i }))
                ) :
                []
        );
        return [...new Set(items.map(item => item.Name))].map(name => ({ Name: name }));
    }
    // Combine the Permission Set, Group, and Permission Set Group data into a single table
    combinePermissionData() {
        this.combinedPermissionData = [];
        this.selectedPermissionSetsAndGroups = [];
        this.selectedGroups = [];

        // Add Permission Sets to the combined data, filtering out invalid or empty values
        this.permissionSets.forEach(permissionSet => {
            if (permissionSet.Name && permissionSet.Name !== '[object Object]') {
                this.combinedPermissionData.push({
                    name: permissionSet.Name,
                    type: 'Permission Set',
                    selected: false
                });
            }
        });

        // Add Permission Set Groups to the combined data, filtering out invalid or empty values
        this.permissionSetGroups.forEach(psGroup => {
            if (psGroup.Name && psGroup.Name !== '[object Object]') {
                this.combinedPermissionData.push({
                    name: psGroup.Name,
                    type: 'Permission Set Group',
                    selected: false
                });
            }
        });

        // Add Groups to the combined data, filtering out invalid or empty values
        this.groups.forEach(group => {
            if (group.Name && group.Name !== '[object Object]') {
                this.combinedPermissionData.push({
                    name: group.Name,
                    type: 'Group',
                    selected: false
                });
            }
        });
    }

    // Method to handle Permission Sets and Groups checkbox
    handlePermissionSetsAndGroupsCheckbox(event) {
        this.isPermissionSetsAndGroupsChecked = event.target.checked;

        // If checkbox is checked, automatically select all Permission Sets and Permission Set Groups
        if (this.isPermissionSetsAndGroupsChecked) {
            this.selectedPermissionSetsAndGroups = this.combinedPermissionData
                .filter(item => item.type === 'Permission Set' || item.type === 'Permission Set Group')
                .map(item => item.name);

            // Update the selection status in combinedPermissionData
            this.combinedPermissionData.forEach(item => {
                if (item.type === 'Permission Set' || item.type === 'Permission Set Group') {
                    item.selected = true;
                }
            });
        } else {
            // If unchecked, clear selections
            this.selectedPermissionSetsAndGroups = [];

            // Reset selection status in combinedPermissionData
            this.combinedPermissionData.forEach(item => {
                if (item.type === 'Permission Set' || item.type === 'Permission Set Group') {
                    item.selected = false;
                }
            });
        }

        // Log the selected items to console
        console.log('Selected Permission Sets and Groups:', JSON.stringify(this.selectedPermissionSetsAndGroups));
    }

    // Method to handle Groups checkbox
    handleGroupsCheckbox(event) {
        this.isGroupsChecked = event.target.checked;

        // If checkbox is checked, automatically select all Groups
        if (this.isGroupsChecked) {
            this.selectedGroups = this.combinedPermissionData
                .filter(item => item.type === 'Group')
                .map(item => item.name);

            // Update the selection status in combinedPermissionData
            this.combinedPermissionData.forEach(item => {
                if (item.type === 'Group') {
                    item.selected = true;
                }
            });
        } else {
            // If unchecked, clear selections
            this.selectedGroups = [];

            // Reset selection status in combinedPermissionData
            this.combinedPermissionData.forEach(item => {
                if (item.type === 'Group') {
                    item.selected = false;
                }
            });
        }

        // Log the selected groups to console
        console.log('Selected Groups:', JSON.stringify(this.selectedGroups));
    }


    // Method to reset the assignment
    handleResetAssignment() {
        // Reset the checkboxes
        this.isPermissionSetsAndGroupsChecked = false;
        this.isGroupsChecked = false;

        // Clear the saved assignments
        this.savedAssignments = {};

        // Optionally reset the last save date
        this.lastSaveDate = null;
    }

    // Updated execute user assignments restoration
    async executeUserAssignmentsRestoration() {
        console.log('Starting user assignments restoration...');

        // Only proceed if users section is checked
        if (!this.includeUsersInfo) {
            console.log('Users section not checked, skipping user assignments restoration');
            return;
        }

        const params = {
            recordId: this.recordId,
        };

        console.log('User assignments parameters:', params);

        try {
            const result = await executeUserAssignmentsRestoration(params);
            console.log('User assignments restoration completed successfully:', result);
            //this.showToast('Success', 'User assignments restoration completed successfully.', 'success');
        } catch (error) {
            console.error('User assignments restoration error:', error);
            this.showToastMessage('Error', 'Error during user assignments restoration: ' + error.body.message, 'error');
            throw error;
        }
    }

    // Save selected users' assignment
    handleSaveAssignment() {
        if (this.selectedUsers.length === 0) {
            console.log('No users selected for assignment.');
            return;
        }

        // Save the assignment
        this.lastSaveDate = new Date().toLocaleString();
        console.log('Saving assignment for users:', Array.from(this.selectedUsers));  // Convert Proxy to array
        console.log('Last Save Date:', this.lastSaveDate);
    }


    // Initialize pagination based on filtered users
    initializePagination() {
        if (this.filteredUsers.length === 0) {
            // If no data is available, reset paged data
            this.pagedUsers = [];
            this.totalPagesUsers = 0;
        } else {
            this.totalPagesUsers = Math.ceil(this.filteredUsers.length / this.recordsPerPage);
            this.updatePagedUsers();
        }
    }

    initializePaginationPre() {
        if (this.filteredUsersPre.length === 0) {
            // If no data is available, reset paged data
            this.pagedUsersPre = [];
            this.totalPagesUsersPre = 0;
        } else {
            this.totalPagesUsersPre = Math.ceil(this.filteredUsersPre.length / this.recordsPerPage);
            this.updatePagedUsersPre();
        }
    }

    // Update the table's paged data based on current page and records per page
    updatePagedUsers() {
        if (this.filteredUsers.length === 0) {
            // No records to display
            this.pagedUsers = [];
        } else {
            const startIndex = (this.currentPageUsers - 1) * this.recordsPerPage;
            const endIndex = startIndex + this.recordsPerPage;
            this.pagedUsers = this.filteredUsers.slice(startIndex, endIndex);
        }
    }

    updatePagedUsersPre() {
        if (this.filteredUsersPre.length === 0) {
            // No records to display
            this.pagedUsersPre = [];
        } else {
            const startIndex = (this.currentPageUsersPre - 1) * this.recordsPerPage;
            const endIndex = startIndex + this.recordsPerPage;
            this.pagedUsersPre = this.filteredUsersPre.slice(startIndex, endIndex);
        }
    }


    handleTabChange(event) {
        this.activeTab = event.target.value;
    }

    // Handle search input change and filter the users
    handleUserSearchChange(event) {
        this.userSearch = event.target.value;
        console.log('User search changed:', this.userSearch);
        this.filterUsersBySearch(this.userSearch);
    }

    handleUserSearchChangePre(event) {
        this.userSearchPre = event.target.value;
        console.log('User search changed:', this.userSearchPre);
        this.filterUsersBySearchPre(this.userSearchPre);
    }
    

    handleUserSearchChangeOnLoad(event) {
        this.userSearchOnLoad = event.target.value;
        console.log('User search (on load) changed:', this.userSearchOnLoad);
        this.filterUsersBySearch(this.userSearchOnLoad);
    }

    handleUserSearchChangeOnLoadPre(event) {
        this.userSearchOnLoadPre = event.target.value;
        console.log('User search (on load) changed:', this.userSearchOnLoadPre);
        this.filterUsersBySearchPre(this.userSearchOnLoadPre);
    }
    

    filterUsersBySearch(searchTerm) {
        const finalSearchTerm = searchTerm?.toLowerCase() || '';
    
        this.filteredUsers = finalSearchTerm
            ? this.originalUsers.filter(user =>
                Object.values(user).some(value =>
                    String(value).toLowerCase().includes(finalSearchTerm)
                )
            )
            : [...this.originalUsers];
    
        this.currentPageUsers = 1;
       // this.recordsPerPage = 5; // Optional if you always want to reset
        this.initializePagination(); // Your existing pagination logic
    }


    filterUsersBySearchPre(searchTerm) {
        const finalSearchTermPre = searchTerm?.toLowerCase() || '';
    
        this.filteredUsersPre = finalSearchTermPre
            ? this.originalUsersPre.filter(user =>
                Object.values(user).some(value =>
                    String(value).toLowerCase().includes(finalSearchTermPre)
                )
            )
            : [...this.originalUsersPre];
    
        this.currentPageUsersPre = 1;
       // this.recordsPerPage = 5; // Optional if you always want to reset
        this.initializePaginationPre(); // Your existing pagination logic
    }
    
    // Reset search and selections, and show all users
    handleResetUsers() {
        this.userSearch = '';  // Clear the search term
        this.userSearchOnLoad = '';
        this.selectedUsers = []; // Clear selected users
        console.log('Selection reset');
        this.filteredUsers = [...this.originalUsers]; // Reset filtered users to original
        this.currentPageUsers = 1;  // Reset pagination to the first page
        this.initializePagination(); // Re-initialize pagination
        this.lastSaveDate = null;
       // this.recordsPerPage = 5;
    }

    // Reset search and selections, and show all users
    handleResetUsersPre() {
        this.userSearchPre = '';  // Clear the search term
        this.userSearchOnLoadPre = '';
        this.selectedUsersPre = []; // Clear selected users
        console.log('Selection reset');
        this.filteredUsersPre = [...this.originalUsersPre]; // Reset filtered users to original
        this.currentPageUsersPre = 1;  // Reset pagination to the first page
        this.initializePaginationPre(); // Re-initialize pagination
        this.lastSaveDate = null;
      //  this.recordsPerPage = 5;
    }

    handleRecordsPerPage(event) {
        this.recordsPerPage = parseInt(event.target.value, 10);
        this.currentPageUsers = 1;  // Reset to first page when changing records per page
        this.initializePagination(); // Re-initialize pagination
    }
    handlePrevPageUsers() {
        if (this.currentPageUsers > 1) {
            this.currentPageUsers--;
            this.updatePagedUsers();
        }
    }

    handleNextPageUsers() {
        if (this.currentPageUsers < this.totalPagesUsers) {
            this.currentPageUsers++;
            this.updatePagedUsers();
        }
    }

    get isFirstPageUsers() {
        return this.currentPageUsers === 1;
    }

    get isLastPageUsers() {
        return this.currentPageUsers === this.totalPagesUsers;
    }

    // pre

    handleRecordsPerPagePre(event) {
        this.recordsPerPage = parseInt(event.target.value, 10);
        this.currentPageUsersPre = 1;  // Reset to first page when changing records per page
        this.initializePaginationPre(); // Re-initialize pagination
    }
    handlePrevPageUsersPre() {
        if (this.currentPageUsersPre > 1) {
            this.currentPageUsersPre--;
            this.updatePagedUsersPre();
        }
    }

    handleNextPageUsersPre() {
        if (this.currentPageUsersPre < this.totalPagesUsersPre) {
            this.currentPageUsersPre++;
            this.updatePagedUsersPre();
        }
    }

    get isFirstPageUsersPre() {
        return this.currentPageUsersPre === 1;
    }

    get isLastPageUsersPre() {
        return this.currentPageUsersPre === this.totalPagesUsersPre;
    }


    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    @track usersInformation = {
        backupDetails: {
            sandbox: '',
            sandboxId: '',
            userFileDate: '',
            scheduleFileDate: '',
            settingsFileDate: ''
        }
    }
    sandboxUrl = '';

    loadSandboxData() {
        console.log('recordId:', this.recordId);  // Log the current recordId passed to the method

        fetchTargetOrgSandbox({ recordId: this.recordId })
            .then(result => {
                console.log('Apex result:', result);  // Log the result returned from the Apex method
                if (result.length > 0) {
                    const targetOrgId = result[0].Target_Refresh_Org__c; // Get the Target Org ID
                    const targetOrgName = result[0].Name; // Get the Target Org Name (now returned from Apex)
                    console.log('Target Org ID:', targetOrgId);  // Log the Target Org ID
                    console.log('Target Org Name:', targetOrgName);  // Log the Target Org Name (fetched from the Apex result)


                    if (targetOrgId) {
                        // Set the sandboxId and sandbox name for display
                        this.usersInformation.backupDetails.sandboxId = targetOrgId;
                        this.usersInformation.backupDetails.sandbox = targetOrgName; // Display the Org Name

                       
                        // Construct the URL to navigate to the record page using the Id of the target org
                        this.sandboxUrl = `/lightning/r/Org__c/${targetOrgId}/view`;
                        console.log('Constructed sandbox URL:', this.sandboxUrl); // Log the constructed URL for navigation
                    }
                } else {
                    console.log('No records found in the result.');
                }
            })
            .catch(error => {
                console.error('Error:', error.message);  // Log any error encountered during the fetch
            });
    }

    loadCreatedDate() {
        console.log('Loading Created Date for recordId:', this.recordId);
        fetchCreatedDate({ recordId: this.recordId })
            .then(result => {
                if (result) {
                    // Handle users file
                    if (result.users && result.users.length > 0) {
                        const userDate = new Date(result.users[0].lastModifiedDate);
                        this.usersInformation.backupDetails.userFileDate = this.formatDate(userDate);
                    }

                    // Handle schedule file
                    if (result.schedule && result.schedule.length > 0) {
                        const scheduleDate = new Date(result.schedule[0].lastModifiedDate);
                        this.usersInformation.backupDetails.scheduleFileDate = this.formatDate(scheduleDate);
                    }

                    // Handle settings file
                    // Handle settings files (all other CSVs)
                    if (result.settings && result.settings.length > 0) {
                        const mostRecentDate = new Date(Math.max(
                            ...result.settings.map(doc => new Date(doc.lastModifiedDate))
                        ));
                        this.usersInformation.backupDetails.settingsFileDate = this.formatDate(mostRecentDate);
                    }
                }
            })
            .catch(error => {
                console.error('Error fetching documents info:', error);
            });
    }

    formatDate(date) {
        if (!(date instanceof Date) || isNaN(date)) {
            console.error('Invalid date object:', date);
            return '';
        }

        try {
            const day = String(date.getDate()).padStart(2, '0');
            const month = String(date.getMonth() + 1).padStart(2, '0');
            const year = date.getFullYear();
            const hours = date.getHours();
            const minutes = String(date.getMinutes()).padStart(2, '0');
            const ampm = hours >= 12 ? 'PM' : 'AM';
            const formattedHours = hours % 12 || 12;

            return `${day}/${month}/${year}, ${formattedHours}:${minutes} ${ampm}`;
        } catch (error) {
            console.error('Error formatting date:', error);
            return '';
        }
    }


   /* get filteredCustomSettings() {
        const searchTerm = this.customSettingsSearch.toLowerCase();
        return this.customSettings.filter(setting =>
            !searchTerm ||
            setting.name.toLowerCase().includes(searchTerm)  // Only filter by 'name'
        );
    }*/

    // Handle records per page change
    handleRecordsPerPagecustomsettings(event) {
        this.recordsPerPage = parseInt(event.target.value, 10);
        this.currentPageCustomSettings = 1;
        this.initializeCustomSettingsPagination();
    }

    // Search and Filter Methods
    handleCustomSettingsSearchChange(event) {
        this.customSettingsSearch = event.target.value;
        this.filterCustomSettings();
        this.currentPageCustomSettings = 1;
        this.recordsPerPage = 5;

    }
    // Filter custom settings based on search
    filterCustomSettings() {
        const searchTerm = this.customSettingsSearch.toLowerCase().trim();

        if (!searchTerm) {
            this.filteredCustomSettings = [...this.originalCustomSettings];
        } else {
            this.filteredCustomSettings = this.originalCustomSettings.filter(setting =>
                setting.name.toLowerCase().includes(searchTerm)
            );
        }

        this.currentPageCustomSettings = 1;
        this.initializeCustomSettingsPagination();
    }

    // Reset all custom settings
    handleResetCustomSettings() {
        this.customSettingsSearch = '';
        this.selectedCustomSettings = [];
        this.filteredCustomSettings = [...this.originalCustomSettings];
        this.currentPageCustomSettings = 1;
        this.initializeCustomSettingsPagination();
        this.recordsPerPage = 5;

        // Reset selection in the datatable
        const datatable = this.template.querySelector('lightning-datatable');
        if (datatable) {
            datatable.selectedRows = [];
        }
    }
    // Initialize pagination
    initializeCustomSettingsPagination() {
        this.totalPagesCustomSettings = Math.ceil(this.filteredCustomSettings.length / this.recordsPerPage);
        this.updatePagedCustomSettings();
    }
    // Update paged data
    updatePagedCustomSettings() {
        const startIndex = (this.currentPageCustomSettings - 1) * this.recordsPerPage;
        const endIndex = startIndex + this.recordsPerPage;
        this.pagedCustomSettings = this.filteredCustomSettings.slice(startIndex, endIndex);
        console.log('this.pagedCustomSettings updatePagedCustomSettings='+this.pagedCustomSettings)
    }

    calculateTotalPages() {
        return Math.ceil(this.filteredCustomSettings.length / this.recordsPerPage);
    }

    // Update the template to use these attributes
    get selectedCount() {
        return this.selectedCustomSettings ? this.selectedCustomSettings.length : 0;
    }

    get hasSelectedRows() {
        return this.selectedCount > 0;
    }

    handleRowSelectioncustomsettings(event) {
        const selectedRows = event.detail.selectedRows;
        // Convert Proxy to regular array and extract names
        this.selectedCustomSettings = Array.from(selectedRows || []).map(row => row.name);
        console.log('Selected Custom Settings:', JSON.stringify(this.selectedCustomSettings));
    }

    // Updated custom settings restoration
    async executeCustomSettingsRestoration() {
        console.log('Starting custom settings restoration...');

        // Only proceed if custom settings section is checked
        if (!this.includeCustomSettings) {
            console.log('Custom settings section not checked, skipping custom settings restoration');
            return;
        }

        try {
            console.log('Custom settings parameters:', { recordId: this.recordId });
            await saveSelectedCustomSettings({ recordId: this.recordId });
            console.log('Custom settings restoration completed successfully');
            //this.showToast('Success', 'Custom settings restoration completed successfully.', 'success');
        } catch (error) {
            console.error('Custom settings restoration error:', error);
            this.showToastMessage('Error', 'Error during custom settings restoration: ' + error.message, 'error');
            throw error;
        }
    }

    // Getters for template
    get isFirstPageCustomSettings() {
        return this.currentPageCustomSettings === 1;
    }

    get isLastPageCustomSettings() {
        return this.currentPageCustomSettings === this.calculateTotalPages();
    }

    // Navigation methods
    handlePrevPageCustomSettings() {
        if (this.currentPageCustomSettings > 1) {
            this.currentPageCustomSettings--;
            this.updatePagedCustomSettings();
        }
    }

    handleNextPageCustomSettings() {
        if (this.currentPageCustomSettings < this.totalPagesCustomSettings) {
            this.currentPageCustomSettings++;
            this.updatePagedCustomSettings();
        }
    }
 /*   get totalPagesCustomSettings() {
        return this.calculateTotalPages();
    }*/

  /*  get pagedCustomSettings() {
        if (this.filteredCustomSettings.length === 0) {
            return [
                {
                    id: 'no-data',
                    name: 'No custom settings found. Ensure the data is correctly loaded.'
                }
            ];
        } else {
            // Regular pagination logic for available data
            const startIndex = (this.currentPageCustomSettings - 1) * this.recordsPerPage;
            const endIndex = startIndex + this.recordsPerPage;
            return this.filteredCustomSettings.slice(startIndex, endIndex);
        }
    }*/

    @track hasCompletedRefreshLog = false;

    // Manual CSV data loading method
    connectedCallback() {
        //Subscribe to Platform event
        this.subscribeToPlatformEvent();

        setTimeout(() => {
            if (this.recordId) {
                this.loadUsers();
                this.loadCustomSettingsData();
                this.loadSandboxData();
                //this.fetchAllCustomObjects();
                this.loadCreatedDate();
                console.log('UserManagement: connectedCallback');
                console.log('UserManagement: recordId', this.recordId);
                this.setupAlphabetFilter();
                this.checkPermissions();
            }
        }, 100);
        this.loadRules();
        if (!this.hasCheckedCustomSettingsRetrieval && this.recordId) {
            this.hasCheckedCustomSettingsRetrieval = true;
            this.checkCustomSettingRetrieveStatus();
        }
    
        if (this.recordId) {
            this.userRestoreSuccessToastShown = false;
            this.userRestoreFailedToastShown = false;
            this.csRestoreSuccessToastShown = false;
            this.csRestoreFailedToastShown = false;
            this.sjRestoreSuccessToastShown = false;
            this.sjRestoreFailedToastShown = false;
            this.deleteSJRestoreSuccessToastShown = false;
            this.deleteSJRestoreFailedToastShown = false;
            this.dataTransformationSuccessToastShown = false;
            this.dataTransformationFailedToastShown = false;
            this.userTransformationExecutionStartTime = null;

            this.userDeactivationSuccessToastShown = false;
            this.userDeactivationFailedToastShown = false;
            this.userPasswordResetSuccessToastShown = false;
            this.userPasswordResetFailedToastShown = false;
            this.userInvalidRemovalSuccessToastShown = false;
            this.userInvalidRemovalFailedToastShown = false;
            this.userActivationSuccessToastShown = false;
            this.userActivationFailedToastShown = false;
            this.evaluateLogsOnLoad(); 
          /*  if(this.refreshStatus !== 'Forbidden' && this.refreshStatus !== 'Completed' && this.refreshStatus !== 'Failed'){
                console.log('this.showRefreshIconMessage before ='+this.showRefreshIconMessage);
                console.log('this.showRefreshIconMessage before this.refreshStatus='+this.refreshStatus);

                    this.initializeRefreshIconLogic();
                console.log('this.showRefreshIconMessage after ='+this.showRefreshIconMessage);
            }*/
            
            
        }
        this.checkIfRefreshLogCompleted();
        this.getMetadataMaskingLogRecordofRefreshTemplate(this.recordId);
        this.getSuffixLogRecordofRefreshTemplate(this.recordId);
    }

   /* refreshDataRestoreLogWires() {
        if (this.wiredUsersLogResult) {
            refreshApex(this.wiredUsersLogResult);
        }
        if (this.wiredCustomSettingsLogResult) {
            refreshApex(this.wiredCustomSettingsLogResult);
        }
    }

    refreshRefreshLogWire(){
        if (this.wiredData) {
            refreshApex(this.wiredData);
        }
    }*/
    

    checkIfRefreshLogCompleted() {
        hasCompletedRefreshLog({ templateId: this.recordId })
            .then(result => {
                this.hasCompletedRefreshLog = result;
            })
            .catch(error => {
                console.error('Error checking refresh log completion:', error);
            });
    }

    getMetadataMaskingLogRecordofRefreshTemplate(parentTemplate) {
        getMetadataMaskingLogRecordofRefreshTemplate({ templateId: parentTemplate })
            .then(() => {
                console.log('Search and replace fetching latest status executed successfully')
                return refreshApex(this.wiredRecordData);
            })
            .catch(error => console.error('Error calling Apex method:', error));
    }

    getSuffixLogRecordofRefreshTemplate(parentTemplate) {
        getSuffixLogRecordofRefreshTemplate({ templateId: parentTemplate })
            .then(() => {
                console.log('Suffix fetching latest status executed successfully')
                return refreshApex(this.wiredRecordData);
            })
            .catch(error => console.error('Error calling Apex method:', error));
    }

  /*  evaluateLogsOnLoad(parentTemplate) {
        Promise.all([
            metaExecuteDisableButton({ refreshTemplateId: parentTemplate }),
            hasDataInProgressBackupLogs({ refreshTemplateId: parentTemplate }),
            getLatestLogs({ refreshTemplateId: parentTemplate })
        ])
        .then(([metaResult, dataResult, logs]) => {
            this.isRetrieveMetadataInProgress = metaResult;
            this.isRetrieveDataInProgress = dataResult;
    
            const metadataLog = logs.find(log => log.Log_Type__c === 'Metadata - Backup Regeneration');
            const dataLogs = logs.filter(log =>
                log.Log_Type__c === 'Users - Backup Regeneration' ||
                log.Log_Type__c === 'Scheduled Jobs - Backup Regeneration' ||
                log.Log_Type__c === 'Custom Settings - Backup Regeneration'
            );
    
            let incompleteLogs = [];
    
            if (this.isRetrieveMetadataInProgress && metadataLog && metadataLog.Status__c !== 'Success') {
                incompleteLogs.push(`${metadataLog.Log_Type__c}: ${metadataLog.Status__c}`);
            }
    
            if (this.isRetrieveDataInProgress && dataLogs.length > 0) {
                const incomplete = dataLogs.filter(log =>
                    log.Status__c !== 'Success'
                );
                if (incomplete.length > 0) {
                    incompleteLogs.push(...incomplete.map(log => `${log.Log_Type__c}: ${log.Status__c}`));
                }
            }
    
            this.showRefreshIconPre = incompleteLogs.length > 0;
        })
        .catch(error => {
            console.error('Log check on load failed:', error);
        });
    }*/

    evaluateLogsOnLoad() {
        Promise.all([
            metaExecuteDisableButton({ refreshTemplateId: this.recordId }),
            hasDataInProgressBackupLogs({ refreshTemplateId: this.recordId })
        ])
        .then(([metaResult, dataResult]) => {
            this.isRetrieveMetadataInProgress = metaResult;
            this.isRetrieveDataInProgress = dataResult;
    
            this.showRefreshIconPre = this.isRetrieveMetadataInProgress || this.isRetrieveDataInProgress;
        })
        .catch(error => {
            console.error('Error checking logs silently on load:', error);
        });
    }

    subscription = null;
    subscribeToPlatformEvent(event) {
        console.log('in handleVFpageEvent ::');
        const channel = '/event/Send_Data_To_LWC__e'
        var statusCode;
        const messageCallback = (response) => {
            console.log('Received message:', JSON.stringify(response));
            statusCode = response.data.payload.Status_Code__c;
            console.log('statusCode>> ' + statusCode);
            if (statusCode == 200) {
               this.showAuthenticateButton = false;
               this.showAuthenticateMessage = false;
            } else {
                this.showAuthenticateButton = true;
                this.showAuthenticateMessage = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: 'Authentication Failed!',
                        variant: 'error'
                    })
                );
            }
        };

        // Subscribe to the event
        subscribe(channel, -1, messageCallback).then((response) => {
            this.subscription = response;
        }).catch((error) => {
            console.error('Error subscribing to event:', error);
        });
    }

    hasCheckedCustomSettingsRetrieval = false;


    async checkCustomSettingRetrieveStatus() {
        try {
            const result = await checkCustomSettingRetrieveStatus({ refTempId: this.recordId });
            if (result) {
                console.log('custom settings retrieved result --- ');
            }
        } catch (error) {
            console.error('Error retrieving custom settings data :', error.message);
        }
    }

    // New method to load custom settings
  /*  loadCustomSettingsData() {
        this.isLoadingCustomSettings = true;
        fetchCustomSettings({ recordId: this.recordId })
            .then(result => {
                console.log('result loadCustomSettingsData= '+result);

                if (result && result.length > 0) {
                    console.log('checking loadCustomSettingsData');
                    console.log('Fetching Custom settings');

                    //const raw = result || '';
                    const nameArray = result
                        .map(item => {
                            const match = item.trim().match(/^(.+)\((\d+)\)$/);
                            if (match) {
                                return {
                                    name: match[1],
                                    count: parseInt(match[2], 10)
                                };
                            }
                            return null;
                        })
                        .filter(Boolean);

                    console.log('nameArray loadCustomSettingsData=' + JSON.stringify(nameArray));

                    this.processCustomSettingsData(nameArray);
                   // const customSettingNames = result[0].Custom_Setting_Names__c?.split(',') || [];
                  //  this.templateFields.customSettingNames = nameArray;
                } else {
                  //  this.templateFields.customSettingNames = [];
                  console.log('else');
                }
            })
            .catch(error => {
                console.error('Error retrieving custom settings data', error);
                this.showToastMessage('Error', 'Failed to load custom settings data', 'error');
            })
            .finally(() => {
                this.isLoadingCustomSettings = false;
            });
    }*/

            loadCustomSettingsData() {
                this.isLoadingCustomSettings = true;
                fetchCustomSettings({ recordId: this.recordId })
                    .then(result => {
                        console.log('result loadCustomSettingsData = ', result);
            
                        if (result && result.length > 0) {
                            const nameArray = result
                                .map(item => {
                                    const match = item.trim().match(/^(.+?)\s*\((\d+)\)$/);
                                    if (match) {
                                        return {
                                            name: match[1].trim(),
                                            count: parseInt(match[2], 10)
                                        };
                                    }
                                    return {
                                        name: item.trim(),
                                        count: 0
                                    };
                                });
            
                            console.log('Parsed nameArray:', JSON.stringify(nameArray));
                            this.processCustomSettingsData(nameArray);
                            this.templateFields.customSettingNames = nameArray;
                        } else {
                            this.processCustomSettingsData([]);
                            this.templateFields.customSettingNames = [];
                        }
                    })
                    .catch(error => {
                        console.error('Error retrieving custom settings data', error);
                        this.showToastMessage('Error', 'Failed to load custom settings data', 'error');
                    })
                    .finally(() => {
                        this.isLoadingCustomSettings = false;
                    });
            }
            

    /*processCustomSettingsData(customSettingsList) {
        if (customSettingsList && Array.isArray(customSettingsList)) {
            this.originalCustomSettings = customSettingsList.map((setting, index) => {
                const match = setting.trim().match(/^(.+?)\s*\((\d+)\)$/); 
                const name = match ? match[1].trim() : setting;
                const count = match ? parseInt(match[2], 10) : 0;

                return {
                    id: index + 1,
                    name: name,
                    count: count,
                    selected: false
                };
            });

            this.customSettings = [...this.originalCustomSettings];
            console.log('this.customSettings = ', this.customSettings);
            this.filteredCustomSettings = [...this.originalCustomSettings];
            console.log('this.filteredCustomSettings = ', this.filteredCustomSettings);
            this.initializeCustomSettingsPagination();
        } else {
            this.originalCustomSettings = [];
            this.customSettings = [];
            this.filteredCustomSettings = [];
            this.pagedCustomSettings = [];
        }
    }*/


   /* processCustomSettingsData(customSettingsString) {
        if (customSettingsString) {
            const settingsArray = customSettingsString.map(setting => setting.trim());
    
            this.originalCustomSettings = settingsArray.map((setting, index) => {
                const match = setting.match(/^(.+?)\s*\((\d+)\)$/); 
                const name = match ? match[1].trim() : setting;
                const count = match ? parseInt(match[2], 10) : 0;
    
                return {
                    id: index + 1,
                    name: name,
                    count: count,
                    selected: false
                };
            });
    
            this.customSettings = [...this.originalCustomSettings];
            console.log('this.customSettings ='+this.customSettings);
            this.filteredCustomSettings = [...this.originalCustomSettings];
            this.initializeCustomSettingsPagination();
        } else {
            this.originalCustomSettings = [];
            this.customSettings = [];
            this.filteredCustomSettings = [];
            this.pagedCustomSettings = [];
        }
    }*/

        processCustomSettingsData(parsedArray) {
            if (parsedArray && parsedArray.length > 0) {
                this.originalCustomSettings = parsedArray.map((item, index) => ({
                    id: index + 1,
                    name: item.name,
                    count: item.count,
                    selected: false
                }));
        
                this.customSettings = [...this.originalCustomSettings];
                this.filteredCustomSettings = [...this.originalCustomSettings];
                this.initializeCustomSettingsPagination();
            } else {
                this.originalCustomSettings = [];
                this.customSettings = [];
                this.filteredCustomSettings = [];
                this.pagedCustomSettings = [];
            }
        }
        
        


    // Wire method to get current page reference
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.recordId = currentPageReference?.state?.recordId ||
            currentPageReference?.attributes?.recordId;

        if (this.recordId) {
            // this.loadCSVData();

        }
    }

    /////schedule jobs//////
    @track scheduleJobsSearch = '';
    @track deleteScheduleJobsSearch = '';
    @track currentPageScheduleJobs = 1;
    @track currentPageDeleteScheduleJobs = 1;
    @track pagedScheduleJobs = [];
    @track scheduleJobs = [];
    @track deleteScheduleJobs = [];

    // Columns for data tables
    scheduleJobsColumns = [
        { label: 'Job Name', fieldName: 'name', type: 'text', sortable: true },
        { label: 'Job Type', fieldName: 'type', type: 'text', sortable: true },
        { label: 'Apex Class', fieldName: 'class', type: 'text', sortable: true },
        { label: 'Cron Expression', fieldName: 'cron', type: 'text', sortable: true }
    ];

    deleteScheduleJobsColumns = [
        { label: 'Job Name', fieldName: 'name', type: 'text' },
        { label: 'Job Type', fieldName: 'type', type: 'text' },
        { label: 'State', fieldName: 'state', type: 'text' },
        { label: 'Timezone', fieldName: 'timezone', type: 'text' },
        { label: 'CronJobDetailId', fieldName: 'cronjobdetailid', type: 'text' }
    ];

    // Getter for filtered schedule jobs
    get filteredScheduleJobs() {
        const searchTerm = this.scheduleJobsSearch.toLowerCase();
        return this.scheduleJobs.filter(job =>
            !searchTerm ||
            (job.name && job.name.toLowerCase().includes(searchTerm)) ||
            (job.type && job.type.toLowerCase().includes(searchTerm))
        );
    }

    // Getter for filtered delete schedule jobs
    get filteredDeleteScheduleJobs() {
        const searchTerm = this.deleteScheduleJobsSearch.toLowerCase();
        return this.deleteScheduleJobs.filter(job =>
            !searchTerm ||
            (job.name && job.name.toLowerCase().includes(searchTerm)) ||
            (job.type && job.type.toLowerCase().includes(searchTerm))
        );
    }

    // Wire the Apex method to fetch data when recordId changes
    @wire(getScheduleJobCSVData, { recordId: '$recordId' })
    wiredScheduleJobData({ error, data }) {
        this.isLoadingScheduleJobs = true;
        try {
            if (data) {
                this.processScheduleJobData(data);
                 // ✅ SET THE FLAG HERE
                if (data.length > 0) {
                    this.templateFields.isScheduledJobsSelected = true;
                } else {
                    this.templateFields.isScheduledJobsSelected = false;
                }
            } else if (error) {
                console.error('Error fetching schedule job CSV data: ', error);
            }
        } finally {
            this.isLoadingScheduleJobs = false;
        }
    }



    // Process incoming data
    processScheduleJobData(dataSet) {
        if (!dataSet || dataSet.length === 0) {
            this.scheduleJobs = [];
        } else {
            const processedJobs = dataSet.map((item, index) => ({
                id: index + 1,
                name: item.name.replace(/"/g, '').trim(), // Remove all quotes and trim
                type: item.type.replace(/"/g, '').trim(), // Remove all quotes and trim
                class: item.class.replace(/"/g, '').trim(), // Remove all quotes and trim
                cron: item.cron.replace(/"/g, '').trim() // Remove all quotes and trim
            }));

            this.scheduleJobs = processedJobs;  // Assign processed jobs to the scheduleJobs array
            this.updatePagedScheduleJobs();  // Ensure paginated jobs are set after processing data
        }
    }

    handleRecordsPerPageSchedule(event) {
        this.recordsPerPage = parseInt(event.target.value, 10);
        this.currentPageScheduleJobs = 1;
        this.updatePagedScheduleJobs();
    }

    // Search handlers
    handleScheduleJobsSearchChange(event) {
        this.scheduleJobsSearch = event.target.value;
        this.currentPageScheduleJobs = 1;
        this.updatePagedScheduleJobs();
        this.recordsPerPage = 5;
    }

    handleDeleteScheduleJobsSearchChange(event) {
        this.deleteScheduleJobsSearch = event.target.value;
        this.currentPageDeleteScheduleJobs = 1;
    }

    // Reset handlers
    handleResetScheduleJobs() {
        this.scheduleJobsSearch = '';
        this.currentPageScheduleJobs = 1;
        this.updatePagedScheduleJobs();
        this.recordsPerPage = 5;
    }

    handleResetDeleteScheduleJobs() {
        this.deleteScheduleJobsSearch = '';
        this.currentPageDeleteScheduleJobs = 1;
    }
    handlePrevPageScheduleJobs() {
        if (this.currentPageScheduleJobs > 1) {
            this.currentPageScheduleJobs--;
            this.updatePagedScheduleJobs();
        }
    }

    handleNextPageScheduleJobs() {
        if (this.currentPageScheduleJobs < this.totalPagesScheduleJobs) {
            this.currentPageScheduleJobs++;
            this.updatePagedScheduleJobs();
        }
    }
    get totalPagesScheduleJobs() {
        return Math.ceil(this.filteredScheduleJobs.length / this.recordsPerPage);
    }
    get isFirstPageScheduleJobs() {
        return this.currentPageScheduleJobs === 1;
    }
    get isLastPageScheduleJobs() {
        return this.currentPageScheduleJobs === this.totalPagesScheduleJobs;
    }

    updatePagedScheduleJobs() {
        const startIndex = (this.currentPageScheduleJobs - 1) * this.recordsPerPage;
        const endIndex = startIndex + this.recordsPerPage;
        this.pagedScheduleJobs = this.filteredScheduleJobs.slice(startIndex, endIndex);
    }

    // Updated schedule jobs execution
    async executeScheduleJobs() {
        console.log('Starting schedule jobs execution...');
    
        if (!this.includeScheduleJobs) {
            console.log('Schedule jobs section not checked, skipping schedule jobs execution');
            return;
        }
    
        try {
            console.log('Executing schedule jobs with templateId:', this.recordId);
            await executeScheduleJobsRestoration({ templateId: this.recordId });
            this.scheduleJobsRestoreStatus = 'Success';
            console.log('Schedule jobs execution completed successfully');
        } catch (error) {
            console.error('Schedule jobs execution error:', error);
            this.scheduleJobsRestoreStatus = 'Failed';
            this.showToastMessage('Error', 'Error during schedule jobs restoration: ' + error.message, 'error');
            throw error;
        }
    }
    

    async executeDeleteScheduleJobs() {
        console.log('Starting delete schedule jobs execution...');
    
        if (!this.includeDeleteScheduleJobs) {
            console.log('Delete schedule jobs section not checked, skipping execution');
            return;
        }
    
        try {
            console.log('Executing delete schedule jobs for recordId:', this.recordId);
            await executeDeleteScheduleJobsRestoration({ templateId: this.recordId }); 
            this.deleteScheduleJobsRestoreStatus = 'Success'; 
            console.log('Delete schedule jobs execution completed successfully');
        } catch (error) {
            console.error('Delete schedule jobs execution error:', error);
            this.deleteScheduleJobsRestoreStatus = 'Failed';
            this.showToastMessage('Error', 'Error during delete schedule jobs execution: ' + error.body?.message, 'error');
            throw error;
        }
    }
    
    

    // Computed properties for disabling checkboxes
    get isUsersInfoDisabled() {
        return this.pagedUsers.length === 0;
    }

    get isCustomSettingsDisabled() {
        return this.pagedCustomSettings.length === 0;
    }

    get isScheduleJobsDisabled() {
        return this.filteredScheduleJobs.length === 0;
    }

    // Handle checkbox change with logging
    handleSectionCheckboxChange(event) {
        const section = event.target.dataset.id;
        const isChecked = event.target.checked;

        console.log(`Checkbox changed - Section: ${section}, Checked: ${isChecked}`);

        if (section === 'users') {
            this.includeUsersInfo = isChecked;
        } else if (section === 'customSettings') {
            this.includeCustomSettings = isChecked;
        } else if (section === 'scheduleJobs') {
            this.includeScheduleJobs = isChecked;
        } else if (section === 'deleteScheduleJobs') {
            this.includeDeleteScheduleJobs = isChecked;
        }

        console.log('Current checkbox states:', {
            users: this.includeUsersInfo,
            customSettings: this.includeCustomSettings,
            scheduleJobs: this.includeScheduleJobs,
            deleteScheduleJobs: this.includeDeleteScheduleJobs
        });
    }

   get executeDisable() {
        // Permission check: Disable if the user doesn't have required permissions
     //   const permissionCheck = !(this.hasAdvancePermissionSet || this.isSystemAdmin);
        const isBasicOnlyUser = this.hasBasicPermissionSet && !this.hasAdvancePermissionSet && !this.isSystemAdmin;
        console.log('execute Disable permission check --', isBasicOnlyUser);

        // Disable the button if any of the following conditions are true:
        return isBasicOnlyUser ||
            this.executionStarted ||
            this.userDataRestoreStatus === 'InProgress' || 
            this.csDataRestoreStatus === 'InProgress' ||
            this.showAuthenticateButton;
    }    


    @track showRefreshIconMessageOnData = false ;
    @track wasUserExecutionTriggered = false;
    @track wasCSExecutionTriggered = false;
    @track wasScheduleJobExecutionTriggered = false;
    @track wasDeleteScheduleJobExecutionTriggered = false;


   /* async handleExecuteConfirm() {
        console.log('Starting execution process...');
       // this.executionStarted = true;
       // this.showDataRetoreRefresh = false;

        ///this.showToastMessage('Info', 'Execution started. Refresh icon will appear once logs are generated.', 'info');
    
        if (!(this.includeUsersInfo || this.includeCustomSettings || this.includeScheduleJobs || this.includeDeleteScheduleJobs)) {
            this.showToastMessage('Warning', 'Please select at least one section to execute.', 'warning');
            return;
        }
    
        if (this.isExecuting) {
            this.showToastMessage('Warning', 'Execution already in progress.', 'warning');
            return;
        }

        this.wasUserExecutionTriggered = this.includeUsersInfo;
        this.wasCSExecutionTriggered = this.includeCustomSettings;
        this.wasScheduleJobExecutionTriggered = this.includeScheduleJobs;
        this.wasDeleteScheduleJobExecutionTriggered = this.includeDeleteScheduleJobs;

        this.isExecuting = true;
        this.showExecuteModal = false;
        this.showUserDefaultMessage = false;
    
        try {
            // ✅ Immediately show this after clicking Execute (no backend wait)
            this.showToastMessage('Info', 'Execution started. Please wait. Refresh icon will appear after logs are generated.', 'info');  

            // Proceed with your executions
            if (this.includeDeleteScheduleJobs) {
                await this.executeDeleteScheduleJobs();
                this.showDataRetoreRefresh = false;
                if (this.deleteScheduleJobsRestoreStatus === 'Success' || this.deleteScheduleJobsRestoreStatus === 'Completed') {
                    this.showToastMessage1('Delete Scheduled Jobs', 'Delete Scheduled Jobs Restoration Completed Successfully.', 'success');
                } else if (this.deleteScheduleJobsRestoreStatus === 'Failed') {
                    this.showToastMessage1('Delete Scheduled Jobs', 'Delete Scheduled Jobs Restoration Failed.', 'error');
                }
                
            }
    
            if (this.includeScheduleJobs) {
                await this.executeScheduleJobs();
                this.showDataRetoreRefresh = false;
                if (this.scheduleJobsRestoreStatus === 'Success' || this.scheduleJobsRestoreStatus === 'Completed') {
                    this.showToastMessage1('Scheduled Jobs Restoration', 'Scheduled Jobs Restoration Completed Successfully.', 'success');
                } else if (this.scheduleJobsRestoreStatus === 'Failed') {
                    this.showToastMessage1('Scheduled Jobs Restoration', 'Scheduled Jobs Restoration Failed.', 'error');
                }
                
            }
    
            const otherPromises = [];
            if (this.includeUsersInfo || this.includeCustomSettings){
                this.showRefreshIconMessageOnData = true; 
            }
            if (this.includeUsersInfo) {
                otherPromises.push(this.executeUserAssignmentsRestoration());
            }
            if (this.includeCustomSettings) {
                otherPromises.push(this.executeCustomSettingsRestoration());
            }
    
            await Promise.all(otherPromises);
            this.showRefreshIconMessageOnData = false;
            this.showDataRetoreRefresh = true;
            
            if(this.showRefreshIconMessageOnData == true){
                this.showDataRetoreRefresh = false;
            }else{
                this.showDataRetoreRefresh = true;
            }  
        } catch (error) {
            console.error('Execution error:', error);
            this.showToastMessage('Error', 'One or more operations failed.', 'error');
        } finally {
            this.isExecuting = false;
    
            // Reset checkboxes
            this.includeUsersInfo = false;
            this.includeCustomSettings = false;
            this.includeScheduleJobs = false;
            this.includeDeleteScheduleJobs = false;
    
            console.log('Checkbox states reset after execution');
            this.refreshLogDataAndShowRefreshIcon();
           
            }
    }*/

    async handleExecuteConfirm() {
                console.log('Starting execution process...');
              //  this.executionStarted = true;
            
                if (!(this.includeUsersInfo || this.includeCustomSettings || this.includeScheduleJobs || this.includeDeleteScheduleJobs)) {
                    this.showToastMessage('Warning', 'Please select at least one section to execute.', 'warning');
                    return;
                }
            
                if (this.isExecuting) {
                    this.showToastMessage('Warning', 'Execution already in progress.', 'warning');
                    return;
                }
            
                this.wasUserExecutionTriggered = this.includeUsersInfo;
                this.wasCSExecutionTriggered = this.includeCustomSettings;
                this.wasScheduleJobExecutionTriggered = this.includeScheduleJobs;
                this.wasDeleteScheduleJobExecutionTriggered = this.includeDeleteScheduleJobs;
            
               // this.isExecuting = true;
                this.showExecuteModal = false;
                this.showUserDefaultMessage = false;
            
                try {
                    this.showToastMessage('Info', 'Execution started. Please wait. Refresh icon will appear after logs are generated.', 'info');
                   
                    if (this.includeUsersInfo || this.includeCustomSettings) {
                        this.showRefreshIconMessageOnData = true;
                        this.isExecuting = true;
                        this.executionStarted = true;
                        this.showDataRetoreRefresh = false;
                    }
            
                    const promises = [];
                    if (this.includeUsersInfo) {
                        promises.push(this.executeUserAssignmentsRestoration());
                    }
                    if (this.includeCustomSettings) {
                        promises.push(this.executeCustomSettingsRestoration());
                    }
            
                    try {
                        await Promise.all(promises);
                        if (this.includeUsersInfo || this.includeCustomSettings) {
                            this.showDataRetoreRefresh = true;
                            this.showRefreshIconMessageOnData = false;
                        }
                    } catch (error) {
                        console.error('User/CS execution error:', error);
                        this.showToastMessage('Error', 'One or more user/custom setting operations failed.', 'error');
                    }

                    if (this.includeDeleteScheduleJobs) {
                        try {
                            await this.executeDeleteScheduleJobs();
                            this.deleteScheduleJobsRestoreStatus = 'Success';
                            this.showToastMessage1('Delete Scheduled Jobs', 'Delete Scheduled Jobs Restoration Completed Successfully.', 'success');
                        } catch (e) {
                            this.deleteScheduleJobsRestoreStatus = 'Failed';
                            this.showToastMessage1('Delete Scheduled Jobs', 'Delete Scheduled Jobs Restoration Failed.', 'error');
                        }
                    }
            
                    if (this.includeScheduleJobs) {
                        try {
                            await this.executeScheduleJobs();
                            this.scheduleJobsRestoreStatus = 'Success';
                            this.showToastMessage1('Scheduled Jobs Restoration', 'Scheduled Jobs Restoration Completed Successfully.', 'success');
                        } catch (e) {
                            this.scheduleJobsRestoreStatus = 'Failed';
                            this.showToastMessage1('Scheduled Jobs Restoration', 'Scheduled Jobs Restoration Failed.', 'error');
                        }
                    }
            
                } catch (err) {
                    console.error('Unexpected Execution error:', err);
                    this.showToastMessage('Error', 'Unexpected error during execution.', 'error');
                } finally {
                    if (this.wasUserExecutionTriggered || this.wasCSExecutionTriggered) {
                        this.refreshLogDataAndShowRefreshIcon();
                    }
                    this.isExecuting = false;
                    this.includeUsersInfo = false;
                    this.includeCustomSettings = false;
                    this.includeScheduleJobs = false;
                    this.includeDeleteScheduleJobs = false;
                }
    }
            

    toastShownForExecution = false;
    
    async refreshLogDataAndShowRefreshIcon() {
        console.log('🔁 Manually fetching statuses after execution...');
    
        try {
            const statusMap = await getAllDataRestoreInprogressStatuses({ templateId: this.recordId });
    
            console.log('Latest statuses fetched:', statusMap);
    
            if (statusMap !== null && Object.keys(statusMap).length > 0) {
                this.userDataRestoreStatus = statusMap['User Restoration - Post Refresh'] || null;
                this.csDataRestoreStatus = statusMap['Custom Settings Restoration - Post Refresh'] || null;
    
                this.computeShowDataRestoreRefresh();
    
                if (this.showDataRetoreRefresh) {
                    console.log('Logs created. Refresh icon is now visible.');
                } else {
                    console.log('Logs not ready yet. Retrying in 5 seconds...');
                    setTimeout(() => this.refreshLogDataAndShowRefreshIcon(), 5000);
                }
            } else {
                console.log('⏳ Logs not yet created. Showing message only...');
                this.showDataRetoreRefresh = false;
                this.showRefreshIconMessageOnData = true;
    
                setTimeout(() => this.refreshLogDataAndShowRefreshIcon(), 5000);
            }
    
        } catch (error) {
            console.error('Error fetching restore statuses:', error);
        }
    }
    
    /*async refreshLogDataAndShowRefreshIcon() {
        console.log('🔁 Manually fetching statuses after execution...');
    
        try {
            const statusMap = await getAllDataRestoreInprogressStatuses({ templateId: this.recordId });
    
            console.log('Latest statuses fetched:', statusMap);
    
            this.userDataRestoreStatus = statusMap['User Restoration - Post Refresh'] || null;
            this.csDataRestoreStatus = statusMap['Custom Settings Restoration - Post Refresh'] || null;
    
            const userLogCreated = !!this.userDataRestoreStatus;
            const csLogCreated = !!this.csDataRestoreStatus;
    
            const userDone = ['Success', 'Completed', 'Failed'].includes(this.userDataRestoreStatus);
            const csDone = ['Success', 'Completed', 'Failed'].includes(this.csDataRestoreStatus);
    
            // ✅ Message should only disappear once logs are created
            if ((this.wasUserExecutionTriggered && userLogCreated) || (this.wasCSExecutionTriggered && csLogCreated)) {
                this.showRefreshIconMessageOnData = false;
                this.showDataRetoreRefresh = true;
            } else {
                // Retry every 5 seconds if logs not created
                setTimeout(() => this.refreshLogDataAndShowRefreshIcon(), 5000);
            }
        } catch (error) {
            console.error('Error fetching restore statuses:', error);
        }
    }*/
    
    

    // Add a getter for execute button state
    get isExecuteButtonDisabled() {
        return !(this.includeUsersInfo || this.includeCustomSettings || this.includeScheduleJobs || this.includeDeleteScheduleJobs) || this.isExecuting;
    }

    // Modal Methods
    openExecuteModal() {
        this.showExecuteModal = true;
    }

    closeExecuteModal() {
        this.showExecuteModal = false;
        // Reset checkboxes when closing modal
        this.includeUsersInfo = false;
        this.includeCustomSettings = false;
        this.includeScheduleJobs = false;
        this.includeDeleteScheduleJobs = false;
        this.showMetaDataTrans = false;
    }

    @track showMetaDataTrans = false;
    @track metaDataTransCheckboxObj = {};
    @track metaDataExecuteDisabled = true;
    handleMetaDatTransCheckboxChange(event) {
        console.log('In handleMetaDatTransCheckboxChange');
        let label = event.target.dataset.label;
        this.metaDataTransCheckboxObj[label] = event.target.checked;
        this.metaDataExecuteDisabled = false;
    }

    handleMetaDataTransExecute(event) {
        this.showMetaDataTrans = true;
    }



    @track sortDirection = 'asc';
    @track sortedBy;

    // Generic sort function for any data array
    sortData(data, fieldName, sortDirection) {
        const cloneData = [...data];

        cloneData.sort((a, b) => {
            let valueA = a[fieldName] || '';
            let valueB = b[fieldName] || '';

            // Handle string values (case-insensitive)
            if (typeof valueA === 'string') {
                valueA = valueA.toLowerCase();
            }
            if (typeof valueB === 'string') {
                valueB = valueB.toLowerCase();
            }

            // Sort logic
            if (valueA < valueB) {
                return sortDirection === 'asc' ? -1 : 1;
            }
            if (valueA > valueB) {
                return sortDirection === 'asc' ? 1 : -1;
            }
            return 0;
        });

        return cloneData;
    }

    // Handler for user table sorting
    handleUserSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortDirection = sortDirection;

        this.filteredUsers = this.sortData(this.filteredUsers, sortedBy, sortDirection);
        this.currentPageUsers = 1;
        this.updatePagedUsers();
    }

      // Handler for user table sorting
      handleUserSortPre(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortDirection = sortDirection;

        this.filteredUsersPre = this.sortData(this.filteredUsersPre, sortedBy, sortDirection);
        this.currentPageUsersPre = 1;
        this.updatePagedUsersPre();
    }

    // Handler for custom settings table sorting
    handleCustomSettingsSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortDirection = sortDirection;

        this.filteredCustomSettings = this.sortData(this.filteredCustomSettings, sortedBy, sortDirection);
        this.currentPageCustomSettings = 1;
        this.updatePagedCustomSettings();
    }

    // Handler for schedule jobs table sorting
    handleScheduleJobsSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortDirection = sortDirection;

        this.scheduleJobs = this.sortData(this.scheduleJobs, sortedBy, sortDirection);
        this.currentPageScheduleJobs = 1;
        this.updatePagedScheduleJobs();
    }


    /****************** END OF RESTORE PAGE CODE BLOCK ******************/


    /****************** METADATA MASKING PAGE CODE BLOCK ******************/

   
    @track showMetadataMaskingPage = false;
    @track showSpinnerInsideBoxOfMetadataMasking = false;
    @track showMetadataMaskingTable = true;

    @track searchRules = [];
    @track suffixRules = [];
    // Display (paginated) lists.
    @track paginatedSearchRules = [];
    @track paginatedSuffixRules = [];

    // Search filter text.
    @track searchRulesSearchKey = '';
    @track suffixRulesSearchKey = '';

    // Pagination properties for Search & Replace table.
    @track currentPageSearchRules = 1;
    pageSizeSearchRules = 5;
    @track totalPagesSearchRules = 1;

    // Pagination properties for Suffix table.
    @track currentPageSuffixRules = 1;
    pageSizeSuffixRules = 5;
    @track totalPagesSuffixRules = 1;

    // Sorting properties for Search & Replace table.
    @track searchRulesSortedBy;
    @track searchRulesSortedDirection;

    // Sorting properties for Suffix table.
    @track suffixRulesSortedBy;
    @track suffixRulesSortedDirection;

    @track recordsPerPageOptions = [5, 10, 25, 50];
    @track selectedSearchRecordsPerPage = '5';
    @track selectedSuffixRecordsPerPage = '5';

    @track totalSearchRecords = 0;
    @track totalSuffixRecords = 0;

    @track showSpinnerInsideBoxOfMetadataMasking = false;
    @track showSearchFieldsWhenNoData = false;
    @track showSuffixSearchFields = false;
    @track metadataMaskingLogRecord;
    @track suffixLogRecord;
    @track metadataMaskingLogName;
    @track metadataMaskingLogUrl;
    @track lastmetadataMaskingStatus;
    @track lastmetadataMaskingDate;
    @track metadataMaskingId;
    @track apexScriptLogRecord;
    @track apexScriptLogName;
    @track apexScriptLogUrl;
    @track apexScriptStatus;
    @track apexScriptId;
    @track apexScriptDate;
    @track apexScriptExecution = true;
    @track showMetadataTransformationeSpinner = false;
    @track showMetadataTransformationRefresh;
    @track suffixStatus;
    @track suffixLogUrl;
    @track suffixLogName;
    @track suffixLogId;
    @track suffixDate;
    @track isShowExecutionOrderModal = false;

    @track firstOrder = ''; // default value for Step 1
    @track secondOrder = '';       // default value for Step 2
    @track orderOptions = [
        { label: 'Search & Replace', value: 'SearchReplace' },
        { label: 'Suffix', value: 'Suffix' }
    ];
    @track orderError = '';


    get hasSearchReplace() {
        return this.searchRules && this.searchRules.length > 0;
    }
    get hasSuffix() {
        return this.suffixRules && this.suffixRules.length > 0;
    }

    @track metadataMaskingResult;

    
    @wire(getSearchRulesRecordofRefreshTemplate, { templateId: '$recordId' })
    wiredMetadatamaskingLog(result) {
        this.metadataMaskingResult = result;  // Save the entire wire result
        console.log('wiredMetadatamaskingLog --', result);
        const { error, data } = result;
        if (data) {
            this.metadataMaskingId = data.Id;
            this.metadataMaskingLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
            this.metadataMaskingLogName = data.Name;
            this.lastmetadataMaskingStatus = data.Status__c;
            //this.lastmetadataMaskingDate = data.Last_Search_And_Replace_Date__c;
            this.lastmetadataMaskingDate = this.formatDate(new Date(data.Last_Search_And_Replace_Date__c));
            this.error = undefined;
            console.log('this.lastmetadataMaskingStatus ---', this.lastmetadataMaskingStatus);
        } else if (error) {
            this.error = error;
        }
        this.computeShowMetadataTransformationRefresh();
    }

    @track suufixLogResult;
    @wire(getSuffixRulesRecordofRefreshTemplate, { templateId: '$recordId' })
    wiredSuffixLog(result) {
        this.suufixLogResult = result;  // Save the entire wire result
        const { error, data } = result;
        if (data) {
            this.suffixLogId = data.Id;
            this.suffixLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
            this.suffixLogName = data.Name;
            this.suffixStatus = data.Status__c;
            //this.suffixDate = data.Last_Suffix_Date__c;
            this.suffixDate = this.formatDate(new Date(data.Last_Suffix_Date__c));
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
        this.computeShowMetadataTransformationRefresh();
    }

    @track apexScriptLogResult;

    @wire(getApexScriptLogRecordofRefreshTemplate, { templateId: '$recordId' })
    wiredApexScriptLog(result) {
        this.apexScriptLogResult = result;  // Save the entire wire result
        const { error, data } = result;
        if (data) {
            console.log('Apex data ---', data);
            this.apexScriptId = data.Id;
            this.apexScriptLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
            this.apexScriptLogName = data.Name;
            this.apexScriptStatus = data.Status__c;
            //this.apexScriptDate = data.Last_ApexScript_Date__c;
            this.apexScriptDate = this.formatDate(new Date(data.Last_ApexScript_Date__c));
            this.apexScriptExecution = false;
            this.apexScriptJustExecuted = false;
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
        this.computeShowMetadataTransformationRefresh();
    }

    srSuccessToastShown = false;
    suffixSuccessToastShown = false;
    apexSuccessToastShown = false;

    srFailedToastShown = false;
    suffixFailedToastShown = false;
    apexFailedToastShown = false;

    @track hasJustExecutedApex = false;
    @track hasJustExecutedSuffix = false;
    @track hasJustExecutedMetadataMasking = false;


        handleRefreshMetadataTransformation(event) {
            console.log('I am in handleRefreshMetadataTransformation');
            this.showMetadataTransformationeSpinner = true;
        
            Promise.all([
                refreshApex(this.metadataMaskingResult),
                refreshApex(this.apexScriptLogResult),
                refreshApex(this.suufixLogResult)
            ])
            .then(() => {
                console.log('Wire refresh completed');
        
                
        
                // 🧼 Normalize statuses (in case they're undefined/null or have casing issues)
                const srStatus = this.lastmetadataMaskingStatus || '';
                const suffixStatus = this.suffixStatus || '';
                const apexStatus = this.apexScriptStatus || '';

                this.computeShowMetadataTransformationRefresh();
                this.disableExecuteMetadataTransformationButton = false;
        
                // ✅ Toast flags if not initialized
                if (this.srSuccessToastShown == null) this.srSuccessToastShown = false;
                if (this.suffixSuccessToastShown == null) this.suffixSuccessToastShown = false;
                if (this.apexSuccessToastShown == null) this.apexSuccessToastShown = false;
        
                if (this.srFailedToastShown == null) this.srFailedToastShown = false;
                if (this.suffixFailedToastShown == null) this.suffixFailedToastShown = false;
                if (this.apexFailedToastShown == null) this.apexFailedToastShown = false;
        
                // 🔄 Search & Replace
                if (srStatus === 'InProgress') {
                    this.showToastMessage1('Search & Replace', 'Search & Replace Transformation is In Progress.', 'info');
                    this.disableExecuteMetadataTransformationButton = true;
                } else if (srStatus === 'Failed' && !this.srFailedToastShown && this.hasJustExecutedMetadataMasking) {
                    this.showToastMessage1('Search & Replace', 'Search & Replace Transformation Failed!', 'error');
                    this.srFailedToastShown = true;
                } else if (srStatus === 'Success' && !this.srSuccessToastShown && this.hasJustExecutedMetadataMasking) {
                    this.showToastMessage1('Search & Replace', 'Search & Replace Transformation Completed Successfully!', 'success');
                    this.srSuccessToastShown = true;
                }
        
                // 🔄 Suffix
                if (suffixStatus === 'InProgress') {
                    this.showToastMessage1('Suffix', 'Suffix Transformation is In Progress.', 'info');
                    this.disableExecuteMetadataTransformationButton = true;
                } else if (suffixStatus === 'Failed' && !this.suffixFailedToastShown && this.hasJustExecutedSuffix) {
                    this.showToastMessage1('Suffix', 'Suffix Transformation Failed!', 'error');
                    this.suffixFailedToastShown = true;
                } else if (suffixStatus === 'Success' && !this.suffixSuccessToastShown && this.hasJustExecutedSuffix) {
                    this.showToastMessage1('Suffix', 'Suffix Transformation Completed Successfully!', 'success');
                    this.suffixSuccessToastShown = true;
                }
        
                // 🔄 Apex Script
                if (apexStatus === 'InProgress') {
                    this.showToastMessage1('Apex Script', 'Apex Script Transformation is In Progress.', 'info');
                    this.disableExecuteMetadataTransformationButton = true;
                } else if (apexStatus === 'Failed' && !this.apexFailedToastShown && this.hasJustExecutedApex) {
                    this.showToastMessage1('Apex Script', 'Apex Script Transformation Failed!', 'error');
                    this.apexFailedToastShown = true;
                } else if (apexStatus === 'Completed' && !this.apexSuccessToastShown && this.hasJustExecutedApex) {
                    this.showToastMessage1('Apex Script', 'Apex Script Transformation Completed Successfully!', 'success');
                    this.apexSuccessToastShown = true;
                }
        
            })
            .catch((error) => {
                console.error('Error during refresh:', error);
                this.showToastMessage1('Error', 'Error refreshing Metadata Transformation status.', 'error');
                this.disableExecuteMetadataTransformationButton = true;
            })
            .finally(() => {
                this.showMetadataTransformationeSpinner = false;
            });
        }


        showToastMessage1(title, message, variant) {
            this.dispatchEvent(new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            }));
        }
        

    computeShowMetadataTransformationRefresh() {
        console.log('computeShowMetadataTransformationRefresh called');
        console.log('lastmetadataMaskingStatus =', this.lastmetadataMaskingStatus);
        console.log('apexScriptStatus =', this.apexScriptStatus);
        console.log('suffixStatus =', this.suffixStatus);
        console.log('apexScriptJustExecuted =', this.apexScriptJustExecuted);
    
        this.showMetadataTransformationRefresh = (
            this.lastmetadataMaskingStatus === 'InProgress' ||
            this.apexScriptStatus === 'InProgress' ||
            this.suffixStatus === 'InProgress' ||
            this.apexScriptJustExecuted === true 
        );
    }
    


    searchColumns = [
        { label: 'Metadata Types', fieldName: 'metadataType', type: 'text', sortable: true },
        { label: 'Masking Type', fieldName: 'maskingType', type: 'text', sortable: true },
        { label: 'Search Key', fieldName: 'searchKey', type: 'text', sortable: true },
        { label: 'Replace Value', fieldName: 'replaceValue', type: 'text', sortable: true }
    ];

    suffixColumns = [
        { label: 'Metadata Types', fieldName: 'metadataType', type: 'text', sortable: true },
        { label: 'Masking Type', fieldName: 'maskingType', type: 'text', sortable: true },
        { label: 'Suffix', fieldName: 'suffixValue', type: 'text', sortable: true }
    ];

    get metadataTypeOptions() {
        return [
            { label: 'Apex Triggers', value: 'ApexTriggers' },
            { label: 'Approval Process', value: 'ApprovalProcess' },
            { label: 'Duplicate Rules', value: 'Duplicate Rules' },
            { label: 'Flows', value: 'Flows' },
            { label: 'Process Builders', value: 'ProcessBuilders' },
            { label: 'Validation Rules', value: 'ValidationRules' },
            { label: 'Workflow Rules', value: 'WorkflowRules' }
        ];
    }

    get enableDisableOptions() {
        return [
            { label: 'Enable', value: 'Enable' },
            { label: 'Disable', value: 'Disable' }
        ];
    }

    metadatafieldsColumns = [
        { label: 'Label', fieldName: 'label', type: 'text', sortable: true },
        { label: 'API Name', fieldName: 'apiName', type: 'text', sortable: true },
        { label: 'Object', fieldName: 'object', type: 'text', sortable: true },
        { label: 'Last Modified By', fieldName: 'lastModifyBy', type: 'text', sortable: true },
        { label: 'Last Modified Date', fieldName: 'lastModifyDate', type: 'text', sortable: true }
    ];

    selectedMetadataColumns = [
        { label: 'Label', fieldName: 'label', type: 'text', sortable: true },
        { label: 'API Name', fieldName: 'apiName', type: 'text', sortable: true },
        { label: 'Object', fieldName: 'object', type: 'text', sortable: true },
        { label: 'Type', fieldName: 'metadataTyp', type: 'text', sortable: true },
        { label: 'Action', fieldName: 'action', type: 'text', sortable: true }
    ];

    @track searchAndsuffixRecords = [];
    loadRules() {
        getMetadataMaskingRules({ refreshTemplateId: this.recordId })
            .then(result => {
                if (result) {
                    // For Search Rules
                    if (result.searchRules && result.searchRules.length > 0) {
                        this.showSearchFieldsWhenNoData = true;
                        this.searchRules = result.searchRules.map((item, index) => {
                            return { ...item, id: 's-' + index };
                        });
                    } else {
                        this.showSearchFieldsWhenNoData = false;
                    }

                    // For Suffix Rules
                    if (result.suffixRules && result.suffixRules.length > 0) {
                        this.showSuffixSearchFields = true;
                        this.suffixRules = result.suffixRules.map((item, index) => {
                            return { ...item, id: 'x-' + index };
                        });
                    } else {
                        this.showSuffixSearchFields = false;
                    }

                    this.refreshSearchRulesTable();
                    this.refreshSuffixRulesTable();
                }
                else {
                    this.showSearchFieldsWhenNoData = false;
                    this.showSuffixSearchFields = false;
                }
            })
            .catch(error => {
                showSearchFieldsWhenNoData = false;
                console.error('Error fetching metadata masking rules:', error);
            });
    }

    // Filter (Search)
    filterSearchRules() {
        if (!this.searchRulesSearchKey) {
            return [...this.searchRules];
        }
        const searchKeyLower = this.searchRulesSearchKey.toLowerCase();
        return this.searchRules.filter(rule => {
            return Object.values(rule).some(val =>
                String(val).toLowerCase().includes(searchKeyLower)
            );
        });
    }

    // Sort
    sortSearchRules(rulesList) {
        if (!this.searchRulesSortedBy) {
            return rulesList;
        }
        return rulesList.sort((a, b) => {
            let aField = a[this.searchRulesSortedBy] ? a[this.searchRulesSortedBy].toLowerCase() : '';
            let bField = b[this.searchRulesSortedBy] ? b[this.searchRulesSortedBy].toLowerCase() : '';
            if (aField === bField) {
                return 0;
            }
            return aField > bField
                ? (this.searchRulesSortedDirection === 'asc' ? 1 : -1)
                : (this.searchRulesSortedDirection === 'asc' ? -1 : 1);
        });
    }
    //Records per page
    handleSearchRecordsPerPageChange(event) {
        this.selectedSearchRecordsPerPage = event.target.value;
        this.pageSizeSearchRules = parseInt(event.target.value, 10);
        this.currentPageSearchRules = 1;
        this.refreshSearchRulesTable();
    }



    // Paginate
    paginateSearchRules(rulesList) {
        this.totalPagesSearchRules = Math.ceil(rulesList.length / this.pageSizeSearchRules) || 1;
        if (this.currentPageSearchRules > this.totalPagesSearchRules) {
            this.currentPageSearchRules = this.totalPagesSearchRules;
        }
        const startIdx = (this.currentPageSearchRules - 1) * this.pageSizeSearchRules;
        return rulesList.slice(startIdx, startIdx + this.pageSizeSearchRules);
    }

    // Refresh the Search & Replace table by applying filter, sort, then pagination.
    refreshSearchRulesTable() {
        const filtered = this.filterSearchRules();
        this.totalSearchRecords = filtered.length;
        const sorted = this.sortSearchRules(filtered);
        this.paginatedSearchRules = this.paginateSearchRules(sorted);
    }

    // Event handler for search input (Search & Replace table).
    handleSearchRulesSearch(event) {
        this.searchRulesSearchKey = event.target.value;
        this.currentPageSearchRules = 1; // Reset to first page.
        this.refreshSearchRulesTable();
    }

    // Event handler for sorting (Search & Replace table).
    handleSearchRulesSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.searchRulesSortedBy = fieldName;
        this.searchRulesSortedDirection = sortDirection;
        this.refreshSearchRulesTable();
    }

    // Pagination event handlers for Search & Replace table.
    handleSearchRulesNext() {
        if (this.currentPageSearchRules < this.totalPagesSearchRules) {
            this.currentPageSearchRules++;
            this.refreshSearchRulesTable();
        }
    }

    handleSearchRulesPrev() {
        if (this.currentPageSearchRules > 1) {
            this.currentPageSearchRules--;
            this.refreshSearchRulesTable();
        }
    }

    handleSearchRulesFirst() {
        this.currentPageSearchRules = 1;
        this.refreshSearchRulesTable();
    }

    handleSearchRulesLast() {
        this.currentPageSearchRules = this.totalPagesSearchRules;
        this.refreshSearchRulesTable();
    }

    get isSearchRulesPrevDisabled() {
        return this.currentPageSearchRules === 1;
    }

    get isSearchRulesNextDisabled() {
        return this.currentPageSearchRules === this.totalPagesSearchRules;
    }

    // --- SUFFIX TABLE FUNCTIONS ---

    // Filter (Search)
    filterSuffixRules() {
        if (!this.suffixRulesSearchKey) {
            return [...this.suffixRules];
        }
        const searchKeyLower = this.suffixRulesSearchKey.toLowerCase();
        return this.suffixRules.filter(rule => {
            return Object.values(rule).some(val =>
                String(val).toLowerCase().includes(searchKeyLower)
            );
        });
    }

    // Sort
    sortSuffixRules(rulesList) {
        if (!this.suffixRulesSortedBy) {
            return rulesList;
        }
        return rulesList.sort((a, b) => {
            let aField = a[this.suffixRulesSortedBy] ? a[this.suffixRulesSortedBy].toLowerCase() : '';
            let bField = b[this.suffixRulesSortedBy] ? b[this.suffixRulesSortedBy].toLowerCase() : '';
            if (aField === bField) {
                return 0;
            }
            return aField > bField
                ? (this.suffixRulesSortedDirection === 'asc' ? 1 : -1)
                : (this.suffixRulesSortedDirection === 'asc' ? -1 : 1);
        });
    }

    //Records per page
    handleSuffixRecordsPerPageChange(event) {
        this.selectedSuffixRecordsPerPage = event.target.value;
        this.pageSizeSuffixRules = parseInt(event.target.value, 10);
        this.currentPageSuffixRules = 1;
        this.refreshSuffixRulesTable();
    }

    // Paginate
    paginateSuffixRules(rulesList) {
        this.totalPagesSuffixRules = Math.ceil(rulesList.length / this.pageSizeSuffixRules) || 1;
        if (this.currentPageSuffixRules > this.totalPagesSuffixRules) {
            this.currentPageSuffixRules = this.totalPagesSuffixRules;
        }
        const startIdx = (this.currentPageSuffixRules - 1) * this.pageSizeSuffixRules;
        return rulesList.slice(startIdx, startIdx + this.pageSizeSuffixRules);
    }

    // Refresh the Suffix table by applying filter, sort, then pagination.
    refreshSuffixRulesTable() {
        const filtered = this.filterSuffixRules();
        this.totalSuffixRecords = filtered.length;
        const sorted = this.sortSuffixRules(filtered);
        this.paginatedSuffixRules = this.paginateSuffixRules(sorted);
    }

    // Event handler for search input (Suffix table).
    handleSuffixRulesSearch(event) {
        this.suffixRulesSearchKey = event.target.value;
        this.currentPageSuffixRules = 1;
        this.refreshSuffixRulesTable();
    }

    // Event handler for sorting (Suffix table).
    handleSuffixRulesSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.suffixRulesSortedBy = fieldName;
        this.suffixRulesSortedDirection = sortDirection;
        this.refreshSuffixRulesTable();
    }

    // Pagination event handlers for Suffix table.
    handleSuffixRulesNext() {
        if (this.currentPageSuffixRules < this.totalPagesSuffixRules) {
            this.currentPageSuffixRules++;
            this.refreshSuffixRulesTable();
        }
    }

    handleSuffixRulesPrev() {
        if (this.currentPageSuffixRules > 1) {
            this.currentPageSuffixRules--;
            this.refreshSuffixRulesTable();
        }
    }

    handleSuffixRulesFirst() {
        this.currentPageSuffixRules = 1;
        this.refreshSuffixRulesTable();
    }

    handleSuffixRulesLast() {
        this.currentPageSuffixRules = this.totalPagesSuffixRules;
        this.refreshSuffixRulesTable();
    }

    get isSuffixRulesPrevDisabled() {
        return this.currentPageSuffixRules === 1;
    }

    get isSuffixRulesNextDisabled() {
        return this.currentPageSuffixRules === this.totalPagesSuffixRules;
    }



    handleBackFromMetadataMaskingPage() {
        this.currentvalue = '3'
        this.updateStepClasses(this.currentvalue);

        this.showMetadataRestore = true;
        this.showMetadataMaskingPage = false;

        metaExecuteDisableButton({ refreshTemplateId: this.recordId })
            .then(result => {
                this.hasInProgressMetadataBackupLog = result;
            })
            .catch(error => {
                console.error('Error checking metadata backup log:', error);
                this.hasInProgressMetadataBackupLog = false;
            });
    }

    @track hasInProgressGeneralBackupLog = false

    handleNextFromMetadataMaskingPage() {
        this.currentvalue = '5'
        this.updateStepClasses(this.currentvalue);

        this.showMetadataMaskingPage = false;
        //this.showDataMaskingPage = true;
        this.showRestorePage = true;

        /* hasDataInProgressBackupLogs({ refreshTemplateId: this.recordId })
         .then(result => {
             this.hasInProgressGeneralBackupLog = result;
         })
         .catch(error => {
             console.error('Error checking general backup logs:', error);
             this.hasInProgressGeneralBackupLog = false;
         });*/
    }



    get isExecuteFindButtonDisabled() {
        
        if (this.isExecuteFindAndReplaceDisabled) {
            return true;
        }
        const permissionCheck = !(this.hasAdvancePermissionSet || this.isSystemAdmin);
    
        if (this.showAuthenticateButton) {
            console.log('isExecuteFindButtonDisabled: Disabled due to authentication being true');
            return true;
        }
    
        const isDataEmpty = !this.paginatedSearchRules.length &&
            !this.paginatedSuffixRules.length &&
            !this.hasapexScript;
    
        return permissionCheck ||
            this.lastmetadataMaskingStatus === 'InProgress' ||
            this.apexScriptStatus === 'InProgress' ||
            this.suffixStatus === 'InProgress' ||
            isDataEmpty;
    }
    

    handleExecuteFindAndReplace() {
        console.log('handleExecuteFindAndReplace started');
        try {
            this.showSpinnerInsideBoxOfMetadataMasking = true;
            this.isExecuteFindAndReplaceDisabled = true;
            this.showMetadataTransformationRefresh = false;

            const filteredSearchRules = this.filterSearchRules();
            const filteredSuffixRules = this.filterSuffixRules();

            let searchRulesArray = [];
            let suffixRulesArray = [];
            if (filteredSearchRules.length > 0) {
                filteredSearchRules.forEach(rule => {
                    searchRulesArray.push({
                        metadataType: rule.metadataType,
                        maskingType: rule.maskingType,
                        searchKey: rule.searchKey,
                        replaceValue: rule.replaceValue
                    });
                });
            }
            if (filteredSuffixRules.length > 0) {
                filteredSuffixRules.forEach(rule => {
                    suffixRulesArray.push({
                        metadataType: rule.metadataType,
                        maskingType: rule.maskingType,
                        suffixValue: rule.suffixValue
                    });
                });
            }
            const searchRulesJSON = JSON.stringify(searchRulesArray);
            const suffixRulesJSON = JSON.stringify(suffixRulesArray);
            console.log('searchRulesJSON:', searchRulesJSON);
            console.log('suffixRulesJSON:', suffixRulesJSON);

            const hasSearchRules = filteredSearchRules.length > 0;
            const hasSuffixRules =  filteredSuffixRules.length > 0;
            const hasApexScript = this.hasapexScript;

            console.log('hasSearchRules:', hasSearchRules);
            console.log('hasSuffixRules:', hasSuffixRules);
            console.log('hasApexScript:', hasApexScript);

           /* if (hasSearchRules || hasSuffixRules || hasApexScript) {
                this.isShowExecutionOrderModal = true;
                this.executeOperationsInOrder(searchRulesJSON, suffixRulesJSON);
                this.computeShowMetadataTransformationRefresh();
            }

            // If all three are available, show the combobox modal (Scenario 1)
            if (hasSearchRules && hasSuffixRules && !hasApexScript) {
                this.isShowExecutionOrderModal = true;
                console.log('Showing execution order modal');
                this.executeOperationsInOrder(searchRulesJSON, suffixRulesJSON);
            } */

                const openModal = (
                    (hasSearchRules && hasSuffixRules && hasApexScript) ||
                    (hasSearchRules && hasSuffixRules)
                );
        
                if (openModal) {
                    this.isShowExecutionOrderModal = true;
                } else if (hasSearchRules || hasSuffixRules || hasApexScript) {
                    // Execute directly without showing modal
                    this.executeOperationsInOrder(searchRulesJSON, suffixRulesJSON);
                    this.computeShowMetadataTransformationRefresh();
                } else {
                    // Nothing to execute
                    this.showToastMessage('Info', 'No transformation rules found to execute', 'info');
                    this.showSpinnerInsideBoxOfMetadataMasking = false;
                    this.isExecuteFindAndReplaceDisabled = false;
                }
                //this.computeShowMetadataTransformationRefresh();
            
            

            // Create an array of promises to track all API calls
            /*const promises = [];

            // Call callFindAndReplaceQueueable ONLY if there are search rules
            if (hasSearchRules) {
                console.log('Executing search rules transformation');
                operations.push('search rules');
                const searchPromise = callFindAndReplaceQueueable({
                    templateId: this.recordId,
                    findAndReplaceTemp: findAndReplaceTemp
                })
                    .then(result => {
                        console.log('Metadata masking result---', result);
                        this.metadataMaskingLogRecord = result;
                        this.getMetadataMaskingLogRecord(this.metadataMaskingLogRecord);
                        return result;
                    })
                    .catch(error => {
                        console.error('Error in search rules execution: ', error);
                        throw error;
                    });

                promises.push(searchPromise);
            } else {
                console.log('No search rules to execute, skipping callFindAndReplaceQueueable');
            }

            // Call callSuffixQueueable ONLY if there are suffix rules
            if (hasSuffixRules) {
                console.log('Executing suffix rules transformation');
                console.log('filteredSuffixRules --', filteredSuffixRules);
                operations.push('suffix rules');
                const suffixPromise = callSuffixQueueable({
                    templateId: this.recordId,
                    suffixTemp: findAndReplaceTemp
                })
                    .then(result => {
                        console.log('Suffix transformation result---', result);
                        return result;
                    })
                    .catch(error => {
                        console.error('Error in suffix transformation: ', error);
                        throw error;
                    });

                promises.push(suffixPromise);
            } else {
                console.log('No suffix rules to execute, skipping callSuffixQueueable');
            }

            // Call apex script execution ONLY if the hasapexScript flag is true
            if (hasApexScript) {
                console.log('Executing apex script transformation');
                operations.push('apex script');
                const scriptPromise = callScriptExecution({
                    refTempId: this.recordId
                })
                    .then(scriptResult => {
                        console.log('Apex Script Metadata Transformation result---', scriptResult);
                        this.apexScriptExecution = true;
                        return scriptResult;
                    })
                    .catch(error => {
                        console.error('Error in apex script execution: ', error);
                        throw error;
                    });

                promises.push(scriptPromise);
            } else {
                console.log('No apex script to execute, skipping callScriptExecution');
            }

            // Handle the case when no operations are performed
            if (promises.length === 0) {
                console.log('No operations to perform');
                this.showSpinnerInsideBoxOfMetadataMasking = false;
                this.isExecuteFindAndReplaceDisabled = false;
                this.showToast('Info', 'No transformation rules found to execute', 'info');
                return;
            }

            // Wait for all promises to resolve and show a unified success message
            Promise.all(promises)
                .then(() => {
                    const operationsText = operations.join(', ');
                    this.showToast('Success', `Transformation for ${operationsText} started successfully!`, 'success');
                })
                .catch(error => {
                    console.error('Error in one or more transformations: ', error);
                    this.showToast('Error', 'An error occurred during transformation. Please check the logs.', 'error');
                })
                .finally(() => {
                    this.showSpinnerInsideBoxOfMetadataMasking = false;
                    this.isExecuteFindAndReplaceDisabled = false;
                });*/



        } catch (error) {
            console.error('Error in handleExecuteFindAndReplace:', error);
            this.showSpinnerInsideBoxOfMetadataMasking = false;
            this.isExecuteFindAndReplaceDisabled = false;
            this.showToastMessage('Error', 'An unexpected error occurred', 'error');
        }
    }

    handleFirstOrderChange(event) {
        this.firstOrder = event.detail.value;
        // Automatically set Step 2 to the complementary value
        if (this.firstOrder === 'SearchReplace') {
            this.secondOrder = 'Suffix';
        } else if (this.firstOrder === 'Suffix') {
            this.secondOrder = 'SearchReplace';
        }
        // Clear any error
        this.orderError = '';
    }

    // Handler for Step 2 change (if you want to support change on step 2 as well):
    handleSecondOrderChange(event) {
        this.secondOrder = event.detail.value;
        if (this.secondOrder === 'SearchReplace') {
            this.firstOrder = 'Suffix';
        } else if (this.secondOrder === 'Suffix') {
            this.firstOrder = 'SearchReplace';
        }
        this.orderError = '';
    }

    // Optionally, if you want to validate (though our automatic assignment should prevent duplicates):
    validateOrder() {
        if (this.firstOrder === this.secondOrder) {
            this.orderError = 'Step 1 and Step 2 cannot be the same.';
        } else {
            this.orderError = '';
        }
    }

    // The rest of your modal confirm/cancel handlers remain unchanged:
    handleExecutionOrderConfirm() {
        if (this.orderError) {
            return;
        }
        this.isShowExecutionOrderModal = false;
        // Rebuild JSON strings in case rules have changed and call sequential execution.
        const filteredSearchRules = this.filterSearchRules();
        const filteredSuffixRules = this.filterSuffixRules();
        let searchRulesArray = [];
        let suffixRulesArray = [];
        if (filteredSearchRules.length > 0) {
            filteredSearchRules.forEach(rule => {
                searchRulesArray.push({
                    metadataType: rule.metadataType,
                    maskingType: rule.maskingType,
                    searchKey: rule.searchKey,
                    replaceValue: rule.replaceValue
                });
            });
        }
        if (filteredSuffixRules.length > 0) {
            filteredSuffixRules.forEach(rule => {
                suffixRulesArray.push({
                    metadataType: rule.metadataType,
                    maskingType: rule.maskingType,
                    suffixValue: rule.suffixValue
                });
            });
        }
        const searchRulesJSON = JSON.stringify(searchRulesArray);
        const suffixRulesJSON = JSON.stringify(suffixRulesArray);
        this.executeOperationsInOrder(searchRulesJSON, suffixRulesJSON);
    }

    handleExecutionOrderCancel() {
        this.isShowExecutionOrderModal = false;
        this.isExecuteFindAndReplaceDisabled = false;
        this.showSpinnerInsideBoxOfMetadataMasking = false;
    }

    // -------------------------------------------------------------------
    // Wrap your API calls in helper methods:
    async callSearchReplaceOperation(searchRulesJSON) {
        this.hasJustExecutedMetadataMasking = true;
        return callFindAndReplaceQueueable({
            templateId: this.recordId,
            findAndReplaceTemp: searchRulesJSON
        })
            .then(result => {
                console.log('Metadata masking result---', result);
                this.metadataMaskingLogRecord = result;
                this.getMetadataMaskingLogRecord(this.metadataMaskingLogRecord);
                return result;
            })
            .catch(error => {
                console.error('Error in search rules execution: ', error);
                throw error;
            });
    }

    async callSuffixOperation(suffixRulesJSON) {
        this.hasJustExecutedSuffix = true;
        return callSuffixQueueable({
            templateId: this.recordId,
            suffixTemp: suffixRulesJSON
        })
            .then(result => {
                console.log('Suffix transformation result---', result);
                this.suffixLogRecord = result;
                this.fetchSuffixLogRecord(this.suffixLogRecord);
                return result;
            })
            .catch(error => {
                console.error('Error in suffix transformation: ', error);
                throw error;
            });
    }

    @track  apexScriptJustExecuted = false;


    async callApexScriptOperation() {
        this.hasJustExecutedApex = true;
        return callScriptExecution({
            refTempId: this.recordId
        })
            .then(scriptResult => {
                console.log('Apex Script Metadata Transformation result---', scriptResult);
                this.apexScriptExecution = true;
                this.apexScriptJustExecuted = true;
                this.computeShowMetadataTransformationRefresh();
                return scriptResult;
            })
            .catch(error => {
                console.error('Error in apex script execution: ', error);
                throw error;
            });
    }

    // -------------------------------------------------------------------
    // Execute operations sequentially based on the combobox selections.
    async executeOperationsInOrder(searchRulesJSON, suffixRulesJSON) {
        try {
            // Scenario 1: Both search and suffix exist (and apex) 
            this.isExecuteFindAndReplaceDisabled = true;
            
            if (this.hasSearchReplace && this.hasSuffix && this.hasapexScript) {
                this.computeShowMetadataTransformationRefresh();
                if (this.firstOrder === 'SearchReplace' && this.secondOrder === 'Suffix') {
                    await this.callSearchReplaceOperation(searchRulesJSON);
                    await this.callSuffixOperation(suffixRulesJSON);
                } else if (this.firstOrder === 'Suffix' && this.secondOrder === 'SearchReplace') {
                    await this.callSuffixOperation(suffixRulesJSON);
                    await this.callSearchReplaceOperation(searchRulesJSON);
                }
                await this.callApexScriptOperation();
            }
            // Scenario 2: Only one of Search or Suffix exists (with apex)
            else if ((this.hasSearchReplace || this.hasSuffix) && this.hasapexScript) {
                this.computeShowMetadataTransformationRefresh();
                if (this.hasSearchReplace) {
                    await this.callSearchReplaceOperation(searchRulesJSON);
                } else if (this.hasSuffix) {
                    await this.callSuffixOperation(suffixRulesJSON);
                }
                await this.callApexScriptOperation();
            }
            else if ((this.hasSearchReplace && this.hasSuffix)) {
                this.computeShowMetadataTransformationRefresh();
                if (this.firstOrder === 'SearchReplace' && this.secondOrder === 'Suffix') {
                    await this.callSearchReplaceOperation(searchRulesJSON);
                    await this.callSuffixOperation(suffixRulesJSON);
                } else if (this.firstOrder === 'Suffix' && this.secondOrder === 'SearchReplace') {
                    await this.callSuffixOperation(suffixRulesJSON);
                    await this.callSearchReplaceOperation(searchRulesJSON);
                }
            }
            else if (this.hasSearchReplace || this.hasSuffix || this.hasapexScript) {
                this.computeShowMetadataTransformationRefresh();
                if (this.hasSearchReplace) {
                    await this.callSearchReplaceOperation(searchRulesJSON);
                } else if (this.hasSuffix) {
                    await this.callSuffixOperation(suffixRulesJSON);
                } else {
                    await this.callApexScriptOperation();
                }

            }

            // Scenario 3: Only Apex exists.
            else if (this.hasapexScript) {
                this.computeShowMetadataTransformationRefresh();
                await this.callApexScriptOperation();
            }
            this.showToastMessage('', 'Metadata Transformation initiated successfully!', 'info');
        } catch (error) {
            console.error('Error executing operations in order: ', error);
            this.showToastMessage('Error', 'An error occurred during transformation', 'error');
        } finally {
            this.showSpinnerInsideBoxOfMetadataMasking = false;
            this.isExecuteFindAndReplaceDisabled = false;
        }
    }

    getMetadataMaskingLogRecord(metadataMaskingLogRecord) {
        getMetadataMaskingLogRecord({ logRecId: metadataMaskingLogRecord })
            .then((data) => {
                console.log('getMetadataMaskingLogRecord data: ', data);
                if (data) {
                    this.metadataMaskingLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
                    this.metadataMaskingLogName = data.Name;
                    this.lastmetadataMaskingStatus = data.Status__c;
                    //this.lastmetadataMaskingDate = data.Last_Search_And_Replace_Date__c;
                    this.lastmetadataMaskingDate = this.formatDate(new Date(data.Last_Search_And_Replace_Date__c));
                    if (this.lastmetadataMaskingStatus === 'InProgress') {
                        this.showMetadataTransformationRefresh = true;
                    }
                    //this.lastmetadataMaskingDate = data.Last_Deployment_Date__c;
                }
                else {
                    console.log('there is no validated record yet for this template ---- ');
                    this.metadataMaskingLogUrl = null;
                    this.metadataMaskingLogName = null;
                }
            })
    }

    fetchSuffixLogRecord(suffixLogRecordId) {
        console.log('Invoking fetchSuffixLogRecord with logRecId:', suffixLogRecordId);
        getSuffixLogRecord({ logRecId: suffixLogRecordId })
            .then((data) => {
                console.log('getSuffixLogRecord data: ', data);
                if (data) {
                    this.suffixLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
                    this.suffixLogName = data.Name;
                    this.suffixStatus = data.Status__c;
                    //this.suffixDate = data.Last_Suffix_Date__c;
                    this.suffixDate = this.formatDate(new Date(data.Last_Suffix_Date__c));
                    if (this.suffixStatus === 'InProgress') {
                        this.showMetadataTransformationRefresh = true;
                    }
                    //this.lastmetadataMaskingDate = data.Last_Deployment_Date__c;
                }
                else {
                    console.log('there is no validated record yet for this template ---- ');
                    this.suffixLogUrl = null;
                    this.suffixLogName = null;
                }
            })
    }

    /*getApexScriptLogRecord(apexScriptLogRecord) {
        getApexScriptLogRecord({ logRecId: apexScriptLogRecord })
            .then((data) => {
                console.log('getApexScriptLogRecord data: ', data);
                if (data) {
                    this.apexScriptLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
                    this.apexScriptLogName = data.Name;
                    this.apexScriptStatus = data.Status__c;
                    //this.lastmetadataMaskingDate = data.Last_Deployment_Date__c;
                }
                else {
                    console.log('there is no validated record yet for this template ---- ');
                    this.apexScriptLogUrl = null;
                    this.apexScriptLogName = null;
                }
            })
    }*/

    /* Csv file upload add on code*/


    handleSearchRulesDownloadTemplate() {
        // Create CSV content
        let csvContent = "data:text/csv;charset=utf-8,";
        csvContent += "Metadata Type,Search Key,Replace Value\n";

        // Create and trigger download
        this.downloadCsvFile(csvContent, "Search_Rules_Template.csv");
    }

    // Simple method to download a template CSV for Suffix Rules
    handleSuffixRulesDownloadTemplate() {
        // Create CSV content
        let csvContent = "data:text/csv;charset=utf-8,";
        csvContent += "Metadata Type,Suffix Value\n";

        // Create and trigger download
        this.downloadCsvFile(csvContent, "Suffix_Rules_Template.csv");
    }



    handleSearchRulesFileUpload(event) {
        const file = event.target.files[0];
        console.log('File selected:', file ? file.name : 'No file selected');

        if (!file) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No file selected',
                    variant: 'error'
                })
            );
            return;
        }

        // Check if file is CSV
        console.log('File type:', file.type);
        if (file.type !== 'text/csv' && !file.name.endsWith('.csv')) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please upload a CSV file',
                    variant: 'error'
                })
            );
            return;
        }

        this.isLoadingRules = true;
        const reader = new FileReader();

        reader.onload = () => {
            try {
                const csvContent = reader.result;
                console.log('CSV content length:', csvContent.length);

                // First, let's check if headers match our expected format
                const lines = csvContent.split('\n');
                console.log('Number of lines:', lines.length);

                if (lines.length > 0) {
                    const headerLine = lines[0].trim();
                    console.log('Header line:', headerLine);

                    // Check if headerLine is empty
                    if (!headerLine) {
                        this.isLoadingRules = false;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'CSV header line is empty',
                                variant: 'error'
                            })
                        );
                        return;
                    }

                    try {
                        const headers = this.parseCSVLine(headerLine);
                        console.log('Parsed headers:', headers);

                        const normalizedHeaders = headers.map(header => header.trim().toLowerCase());
                        console.log('Normalized headers:', normalizedHeaders);

                        // Check if this CSV has the required headers for Search Rules (without Masking Type)
                        const hasRequiredHeaders =
                            normalizedHeaders.includes('metadata type') &&
                            normalizedHeaders.includes('search key') &&
                            normalizedHeaders.includes('replace value');

                        console.log('Has required headers:', hasRequiredHeaders);

                        if (hasRequiredHeaders) {
                            const modifiedContent = this.addMaskingTypeToSearchRulesCSV(csvContent);
    
                            const modifiedLines = modifiedContent.split('\n');
                            const dataLines = modifiedLines.slice(1); // skip header
                            const headers = this.parseCSVLine(modifiedLines[0]);
    
                            let hasEmptyValue = false;
                            let lineNumber = null;
                            let missingColumn = null;
    
                            for (let i = 0; i < dataLines.length; i++) {
                                const line = dataLines[i].trim();
                                if (!line) continue;
    
                                const values = this.parseCSVLine(line);
    
                                for (let j = 0; j < headers.length; j++) {
                                    // Accept spaces as valid input, only fail if value is actually null/undefined
                                    if (values[j] === undefined || values[j] === null || values[j] === '') {
                                        hasEmptyValue = true;
                                        lineNumber = i + 2;
                                        missingColumn = headers[j];
                                        console.error(`Missing value at row ${lineNumber}, column ${missingColumn}`);
                                        break;
                                    }
                                }
    
                                if (hasEmptyValue) break;
                            }
                            
                            if (hasEmptyValue) {
                                this.isLoadingRules = false;
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: `CSV contains empty values. Please fill "${missingColumn}" at row ${lineNumber}.`,
                                        variant: 'error'
                                    })
                                );
                                event.target.value = '';
                                return;
                            }

                            // Process the modified CSV to check for duplicates before uploading
                            this.processSearchRulesCSV(modifiedContent, event);
                        } else {
                            this.isLoadingRules = false;
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'The CSV file does not have the required headers for Search Rules (Metadata Type, Search Key, Replace Value)',
                                    variant: 'error'
                                })
                            );
                            // Clear the file input to allow trying again
                            event.target.value = '';
                        }
                    } catch (parseError) {
                        console.error('Error parsing CSV header:', parseError);
                        this.isLoadingRules = false;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'Error parsing CSV header: ' + parseError.message,
                                variant: 'error'
                            })
                        );
                        event.target.value = '';
                    }
                } else {
                    this.isLoadingRules = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'The uploaded file is empty',
                            variant: 'error'
                        })
                    );
                    event.target.value = '';
                }
            } catch (e) {
                console.error('General error in file processing:', e);
                this.isLoadingRules = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error processing file: ' + e.message,
                        variant: 'error'
                    })
                );
                event.target.value = '';
            }
        };

        reader.onerror = (event) => {
            console.error('FileReader error:', event);
            this.isLoadingRules = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error reading the file',
                    variant: 'error'
                })
            );
            event.target.value = '';
        };

        try {
            reader.readAsText(file);
        } catch (e) {
            console.error('Error starting file read:', e);
            this.isLoadingRules = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error reading file: ' + e.message,
                    variant: 'error'
                })
            );
            event.target.value = '';
        }
    }

    // New method to add Masking Type to Search Rules CSV
    addMaskingTypeToSearchRulesCSV(csvContent) {
        try {
            const lines = csvContent.split('\n');
            const headerLine = lines[0].trim();
            const headers = this.parseCSVLine(headerLine);

            // Find if "Masking Type" already exists in the headers
            const maskingTypeIndex = headers.findIndex(header =>
                header.trim().toLowerCase() === 'masking type');

            // If "Masking Type" is not in the headers, add it
            if (maskingTypeIndex === -1) {
                // Add "Masking Type" after "Metadata Type"
                const metadataTypeIndex = headers.findIndex(header =>
                    header.trim().toLowerCase() === 'metadata type');

                // Add "Masking Type" header
                const newHeaders = [...headers];
                newHeaders.splice(metadataTypeIndex + 1, 0, 'Masking Type');

                // Create new CSV content with added "Masking Type" column
                let newLines = [newHeaders.join(',')];

                // Process each data row and add "Search & Replace" value
                for (let i = 1; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (!line) continue; // Skip empty lines

                    try {
                        const values = this.parseCSVLine(line);
                        // Add "Search & Replace" after Metadata Type value
                        const newValues = [...values];
                        newValues.splice(metadataTypeIndex + 1, 0, 'Search & Replace');
                        newLines.push(newValues.join(','));
                    } catch (lineError) {
                        console.warn('Error processing line:', line, lineError);
                        // Keep original line if error
                        newLines.push(line);
                    }
                }

                return newLines.join('\n');
            }

            // If "Masking Type" already exists, return original content
            return csvContent;
        } catch (error) {
            console.error('Error adding Masking Type to Search Rules CSV:', error);
            // Return original content if there's an error
            return csvContent;
        }
    }

    // New method to process search rules CSV and check for duplicates
    processSearchRulesCSV(csvContent, event) {
        try {
            const lines = csvContent.split('\n');
            const headerLine = lines[0].trim();
            const headers = this.parseCSVLine(headerLine);

            // Find index positions of important columns
            const metadataTypeIndex = headers.findIndex(header =>
                header.trim().toLowerCase() === 'metadata type');
            const searchKeyIndex = headers.findIndex(header =>
                header.trim().toLowerCase() === 'search key');

            // Check if we have existing rules to compare against
            if (this.searchRules && this.searchRules.length > 0) {
                console.log('Checking for duplicate search keys in existing rules');

                // Create a map of existing metadata types and search keys
                const existingSearchKeys = new Map();
                this.searchRules.forEach(rule => {
                    const key = `${rule.metadataType.toLowerCase()}_${rule.searchKey.toLowerCase()}`;
                    existingSearchKeys.set(key, true);
                });

                // Process data rows and filter out duplicates
                let filteredLines = [headerLine];
                let duplicateCount = 0;

                for (let i = 1; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (!line) continue; // Skip empty lines

                    try {
                        const values = this.parseCSVLine(line);
                        if (values.length < Math.max(metadataTypeIndex, searchKeyIndex) + 1) {
                            console.warn('Skipping invalid line:', line);
                            continue;
                        }

                        const metadataType = values[metadataTypeIndex].trim().toLowerCase();
                        const searchKey = values[searchKeyIndex].trim().toLowerCase();
                        const key = `${metadataType}_${searchKey}`;

                        // Check if this is a duplicate
                        if (existingSearchKeys.has(key)) {
                            duplicateCount++;
                            console.log(`Duplicate found: ${metadataType} - ${searchKey}`);
                        } else {
                            // Not a duplicate, add to our filtered lines
                            filteredLines.push(line);
                            // Also add to our map to catch duplicates within the uploaded file
                            existingSearchKeys.set(key, true);
                        }
                    } catch (lineError) {
                        console.warn('Error processing line:', line, lineError);
                    }
                }

                // If we found and removed duplicates, show a toast message
                if (duplicateCount > 0) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Duplicate Detection',
                            message: `Removed ${duplicateCount} duplicate search rules that already exist in the system`,
                            variant: 'info'
                        })
                    );
                }

                // If we have any non-duplicate lines, proceed with upload
                if (filteredLines.length > 1) {
                    const filteredContent = filteredLines.join('\n');
                    this.uploadSearchRulesContent(filteredContent, event);
                } else {
                    this.isLoadingRules = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Warning',
                            message: 'All rules in the CSV file are duplicates of existing rules. No changes made.',
                            variant: 'warning'
                        })
                    );
                    event.target.value = '';
                }
            } else {
                // No existing rules to check against, upload the file as is
                this.uploadSearchRulesContent(csvContent, event);
            }
        } catch (error) {
            console.error('Error in processing search rules CSV:', error);
            this.isLoadingRules = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error processing CSV: ' + error.message,
                    variant: 'error'
                })
            );
            event.target.value = '';
        }
    }

    // Method to upload the filtered search rules content
    uploadSearchRulesContent(csvContent, event) {
        console.log('Calling Apex uploadSearchRulesCSV method');
        uploadSearchRulesCSV({
            refreshTemplateId: this.recordId,
            csvContent: csvContent
        })
            .then(result => {
                console.log('Upload result:', result);
                // Check if the result contains a success message
                if (result && result.toLowerCase().includes('successfully')) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: result,
                            variant: 'success'
                        })
                    );
                    // Refresh the data
                    this.loadRules();
                } else {
                    // Result doesn't indicate success
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Warning',
                            message: result || 'Upload did not complete successfully',
                            variant: 'warning'
                        })
                    );
                }
            })
            .catch(error => {
                console.error('Upload error:', error);
                let errorMessage = 'Error uploading file';
                if (error.body && error.body.message) {
                    errorMessage += ': ' + error.body.message;
                } else if (error.message) {
                    errorMessage += ': ' + error.message;
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: errorMessage,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoadingRules = false;
                // Clear the file input to allow uploading the same file again
                event.target.value = '';
            });
    }

    // Enhanced file upload handler for Suffix Rules
    handleSuffixRulesFileUpload(event) {
        const file = event.target.files[0];
        console.log('Suffix File selected:', file ? file.name : 'No file selected');

        if (!file) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No file selected',
                    variant: 'error'
                })
            );
            return;
        }

        // Check if file is CSV
        console.log('Suffix File type:', file.type);
        if (file.type !== 'text/csv' && !file.name.endsWith('.csv')) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please upload a CSV file',
                    variant: 'error'
                })
            );
            return;
        }

        this.isLoadingsufix = true;
        const reader = new FileReader();

        reader.onload = () => {
            try {
                const csvContent = reader.result;
                console.log('Suffix CSV content length:', csvContent.length);

                // First, let's check if headers match our expected format
                const lines = csvContent.split('\n');
                console.log('Suffix Number of lines:', lines.length);

                if (lines.length > 0) {
                    const headerLine = lines[0].trim();
                    console.log('Suffix Header line:', headerLine);

                    // Check if headerLine is empty
                    if (!headerLine) {
                        this.isLoadingsufix = false;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'CSV header line is empty',
                                variant: 'error'
                            })
                        );
                        return;
                    }

                    try {
                        const headers = this.parseCSVLine(headerLine);
                        console.log('Suffix Parsed headers:', headers);

                        const normalizedHeaders = headers.map(header => header.trim().toLowerCase());
                        console.log('Suffix Normalized headers:', normalizedHeaders);
                        
                        const hasRequiredHeaders =
                            normalizedHeaders.includes('metadata type') &&
                            normalizedHeaders.includes('suffix value');

                        console.log('Suffix Has required headers:', hasRequiredHeaders);

                        if (hasRequiredHeaders) {
                            const modifiedContent = this.addMaskingTypeToSuffixRulesCSV(csvContent);
                        
                            const modifiedLines = modifiedContent.split('\n');
                            const dataLines = modifiedLines.slice(1); // Skip header
                            const suffixHeaders = this.parseCSVLine(modifiedLines[0]);
                        
                            let hasEmptyValue = false;
                            let lineNumber = null;
                            let missingColumn = null;
                        
                            for (let i = 0; i < dataLines.length; i++) {
                                const line = dataLines[i].trim();
                                if (!line) continue;
                        
                                const values = this.parseCSVLine(line);
                        
                                for (let j = 0; j < suffixHeaders.length; j++) {
                                    // Accept space-only values: only throw error if null/undefined
                                    if (values[j] === undefined || values[j] === null || values[j] === '') {
                                        hasEmptyValue = true;
                                        lineNumber = i + 2; // +1 for header row, +1 for index base
                                        missingColumn = suffixHeaders[j];
                                        console.error(`Missing value at row ${lineNumber}, column ${missingColumn}`);
                                        break;
                                    }
                                }
                        
                                if (hasEmptyValue) break;
                            }
                        
                            if (hasEmptyValue) {
                                this.isLoadingsufix = false;
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: `CSV contains empty values. Please fill "${missingColumn}" at row ${lineNumber}.`,
                                        variant: 'error'
                                    })
                                );
                                event.target.value = '';
                                return;
                            }
                            
                            this.processSuffixRulesCSV(modifiedContent, event);
                        }
                         else {
                            this.isLoadingsufix = false;
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'The CSV file does not have the required headers for Suffix Rules (Metadata Type, Suffix Value)',
                                    variant: 'error'
                                })
                            );
                            // Clear the file input to allow trying again
                            event.target.value = '';
                        }
                    } catch (parseError) {
                        console.error('Error parsing Suffix CSV header:', parseError);
                        this.isLoadingsufix = false;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'Error parsing CSV header: ' + parseError.message,
                                variant: 'error'
                            })
                        );
                        event.target.value = '';
                    }
                } else {
                    this.isLoadingsufix = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'The uploaded file is empty',
                            variant: 'error'
                        })
                    );
                    event.target.value = '';
                }
            } catch (e) {
                console.error('General error in suffix file processing:', e);
                this.isLoadingsufix = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error processing file: ' + e.message,
                        variant: 'error'
                    })
                );
                event.target.value = '';
            }
        };

        reader.onerror = (event) => {
            console.error('Suffix FileReader error:', event);
            this.isLoadingsufix = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error reading the file',
                    variant: 'error'
                })
            );
            event.target.value = '';
        };

        try {
            reader.readAsText(file);
        } catch (e) {
            console.error('Error starting suffix file read:', e);
            this.isLoadingsufix = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error reading file: ' + e.message,
                    variant: 'error'
                })
            );
            event.target.value = '';
        }
    }

    addMaskingTypeToSuffixRulesCSV(csvContent) {
        try {
            const lines = csvContent.split('\n');
            const headerLine = lines[0].trim();
            const headers = this.parseCSVLine(headerLine);

            // Find if "Masking Type" already exists in the headers
            const maskingTypeIndex = headers.findIndex(header =>
                header.trim().toLowerCase() === 'masking type');

            // If "Masking Type" is not in the headers, add it
            if (maskingTypeIndex === -1) {
                // Add "Masking Type" after "Metadata Type"
                const metadataTypeIndex = headers.findIndex(header =>
                    header.trim().toLowerCase() === 'metadata type');

                // Add "Masking Type" header
                const newHeaders = [...headers];
                newHeaders.splice(metadataTypeIndex + 1, 0, 'Masking Type');

                // Create new CSV content with added "Masking Type" column
                let newLines = [newHeaders.join(',')];

                // Process each data row and add "Suffix" value
                for (let i = 1; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (!line) continue; // Skip empty lines

                    try {
                        const values = this.parseCSVLine(line);
                        // Add "Suffix" after Metadata Type value
                        const newValues = [...values];
                        newValues.splice(metadataTypeIndex + 1, 0, 'Suffix');
                        newLines.push(newValues.join(','));
                    } catch (lineError) {
                        console.warn('Error processing line:', line, lineError);
                        // Keep original line if error
                        newLines.push(line);
                    }
                }

                return newLines.join('\n');
            }

            // If "Masking Type" already exists, return original content
            return csvContent;
        } catch (error) {
            console.error('Error adding Masking Type to Suffix Rules CSV:', error);
            // Return original content if there's an error
            return csvContent;
        }
    }


    // New method to process suffix rules CSV and check for duplicates
    processSuffixRulesCSV(csvContent, event) {
        try {
            const lines = csvContent.split('\n');
            const headerLine = lines[0].trim();
            const headers = this.parseCSVLine(headerLine);

            // Find index position of metadata type column
            const metadataTypeIndex = headers.findIndex(header =>
                header.trim().toLowerCase() === 'metadata type');
            const maskingTypeIndex = headers.findIndex(header =>
                header.trim().toLowerCase() === 'masking type');

            // Check if we have existing suffix rules to compare against
            if (this.suffixRules && this.suffixRules.length > 0) {
                console.log('Checking for duplicate metadata types in existing suffix rules');

                // Create a map of existing metadata types
                const existingMetadataTypes = new Map();
                this.suffixRules.forEach(rule => {
                    const key = `${rule.metadataType.toLowerCase()}_${rule.maskingType.toLowerCase()}`;
                    existingMetadataTypes.set(key, true);
                });

                // Process data rows and filter out duplicates
                let filteredLines = [headerLine];
                let duplicateCount = 0;

                for (let i = 1; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (!line) continue; // Skip empty lines

                    try {
                        const values = this.parseCSVLine(line);
                        if (values.length < Math.max(metadataTypeIndex, maskingTypeIndex) + 1) {
                            console.warn('Skipping invalid line:', line);
                            continue;
                        }

                        const metadataType = values[metadataTypeIndex].trim().toLowerCase();
                        const maskingType = values[maskingTypeIndex].trim().toLowerCase();
                        const key = `${metadataType}_${maskingType}`;

                        // Check if this metadata type already exists
                        if (existingMetadataTypes.has(key)) {
                            duplicateCount++;
                            console.log(`Duplicate metadata type found: ${metadataType} with masking type: ${maskingType}`);
                        } else {
                            // Not a duplicate, add to our filtered lines
                            filteredLines.push(line);
                            // Also add to our map to catch duplicates within the uploaded file
                            existingMetadataTypes.set(key, true);
                        }
                    } catch (lineError) {
                        console.warn('Error processing line:', line, lineError);
                    }
                }

                // If we found and removed duplicates, show a toast message
                if (duplicateCount > 0) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Duplicate Detection',
                            message: `Removed ${duplicateCount} duplicate metadata types that already exist in the system`,
                            variant: 'info'
                        })
                    );
                }

                // If we have any non-duplicate lines, proceed with upload
                if (filteredLines.length > 1) {
                    const filteredContent = filteredLines.join('\n');
                    this.uploadSuffixRulesContent(filteredContent, event);
                } else {
                    this.isLoadingsufix = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Warning',
                            message: 'All metadata types in the CSV file already exist. No changes made.',
                            variant: 'warning'
                        })
                    );
                    event.target.value = '';
                }
            } else {
                // No existing rules to check against, upload the file as is
                this.uploadSuffixRulesContent(csvContent, event);
            }
        } catch (error) {
            console.error('Error in processing suffix rules CSV:', error);
            this.isLoadingsufix = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error processing CSV: ' + error.message,
                    variant: 'error'
                })
            );
            event.target.value = '';
        }
    }

    // Method to upload the filtered suffix rules content
    uploadSuffixRulesContent(csvContent, event) {
        console.log('Calling Apex uploadSuffixRulesCSV method');
        uploadSuffixRulesCSV({
            refreshTemplateId: this.recordId,
            csvContent: csvContent
        })
            .then(result => {
                console.log('Suffix Upload result:', result);
                // Check if the result contains a success message
                if (result && result.toLowerCase().includes('successfully')) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: result,
                            variant: 'success'
                        })
                    );
                    // Refresh the data
                    this.loadRules();
                } else {
                    // Result doesn't indicate success
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Warning',
                            message: result || 'Upload did not complete successfully',
                            variant: 'warning'
                        })
                    );
                }
            })
            .catch(error => {
                console.error('Suffix Upload error:', error);
                let errorMessage = 'Error uploading file';
                if (error.body && error.body.message) {
                    errorMessage += ': ' + error.body.message;
                } else if (error.message) {
                    errorMessage += ': ' + error.message;
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: errorMessage,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoadingsufix = false;
                // Clear the file input to allow uploading the same file again
                event.target.value = '';
            });
    }

    // Helper method to download CSV file (unchanged)
    downloadCsvFile(csvContent, fileName) {
        try {
            const encodedUri = encodeURI(csvContent);
            const link = document.createElement("a");
            link.setAttribute("href", encodedUri);
            link.setAttribute("download", fileName);
            document.body.appendChild(link);
            link.click();

            // Small delay before removing the element
            setTimeout(() => {
                document.body.removeChild(link);
            }, 100);

            // Show success message using dispatchEvent directly for reliability
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `${fileName} downloaded successfully`,
                    variant: 'success'
                })
            );
        } catch (error) {
            console.error('Error downloading file:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to download file: ' + error.message,
                    variant: 'error'
                })
            );
        }
    }

    // Improved CSV line parser with better error handling (unchanged)
    parseCSVLine(line) {
        try {
            const result = [];
            let inQuotes = false;
            let value = '';

            for (let i = 0; i < line.length; i++) {
                const c = line.charAt(i);
                if (c === '"') {
                    inQuotes = !inQuotes;
                } else if (c === ',' && !inQuotes) {
                    result.push(value.trim());
                    value = '';
                } else {
                    value += c;
                }
            }
            result.push(value.trim());
            return result;
        } catch (e) {
            console.error('Error in parseCSVLine:', e, 'for line:', line);
            throw new Error('Failed to parse CSV line: ' + e.message);
        }
    }


    /*CSv file upload end*/


    /*Apex script code start*/

    @track scripts = [];
    @track originalScripts = [];
    @track newScriptOrder = '';
    @track newScriptName = '';
    @track newScriptDetails = '';
    @track searchTermapexScript = '';
    @track isLoading = false;

    // Pagination variables
    @track pageSizeApex = 5;
    @track currentPageApex = 1;
    @track sortedByapex = 'order';
    @track sortDirectionapex = 'asc';
    @track selectedCurrentPageApexscript = 1;
    @track totalSelectedPagesApexscript = 1;
    @track totalRecordsApexscript = 0;
    wiredScriptResult;

    pageSizeOptionsApex = [
        { label: '5', value: 5 },
        { label: '10', value: 10 },
        { label: '25', value: 25 },
        { label: '50', value: 50 }
    ];

    apexScriptcolumns = [
        {
            label: 'Order',
            fieldName: 'order',
            type: 'number',
            sortable: true,
            initialWidth: 100,
            cellAttributes: {
                alignment: 'center'
            }
        },
        {
            label: 'Script Name',
            fieldName: 'scriptName',
            type: 'text',
            sortable: true
        },
        {
            label: 'Script Details',
            fieldName: 'scriptData',
            type: 'text',
            sortable: true
        }
    ];


    // Wire the apex method
    @wire(readCSVFile, { recordId: '$recordId' })
    wiredScripts(result) {
        this.isLoading = true;
        const { data, error } = result;

        if (data) {
            console.log('CSV Data:', data);
            this.originalScripts = data;
            this.scripts = [...this.originalScripts];
            this.updatePaginationDetails();
            this.isLoading = false;
        } else if (error) {
            this.handleError(error);
            this.isLoading = false;
        }
    }



    // Error handling
    handleError(error) {
        console.error('Error:', error);
        this.showToastMessage('Error', error.body?.message || 'An error occurred while processing your request', 'error');
    }

    // Toast message
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    // Getters for pagination and display
    get hasapexScript() {
        return this.originalScripts && this.originalScripts.length > 0;
    }

    get totalPagesApex() {
        return Math.ceil(this.scripts.length / this.pageSizeApex);
    }

    get isFirstPageapex() {
        return this.currentPageApex === 1;
    }

    get isLastPageapex() {
        return this.currentPageApex === this.totalPagesApex;
    }

    get paginatedScripts() {
        const start = (this.currentPageApex - 1) * this.pageSizeApex;
        const end = start + this.pageSizeApex;
        return this.scripts.slice(start, end);
    }

    // Pagination methods
    handlePageSizeChangeApex(event) {
        this.pageSizeApex = parseInt(event.target.value, 10);
        this.currentPageApex = 1;
        this.updatePaginationDetails();
    }

    handleFirstapex() {
        this.currentPageApex = 1;
        this.updatePaginationDetails();
    }

    handlePreviousapex() {
        if (this.currentPageApex > 1) {
            this.currentPageApex--;
            this.updatePaginationDetails();
        }
    }

    handleNextapex() {
        if (this.currentPageApex < this.totalPagesApex) {
            this.currentPageApex++;
            this.updatePaginationDetails();
        }
    }

    handleLastapex() {
        this.currentPageApex = this.totalPagesApex;
        this.updatePaginationDetails();
    }

    // Search functionality
    handleSearchApexScripts(event) {
        this.searchTermapexScript = event.target.value;
        this.currentPageApex = 1;

        if (!this.searchTermapexScript) {
            this.scripts = [...this.originalScripts];
        } else {
            const searchTerm = this.searchTermapexScript.toLowerCase();
            this.scripts = this.originalScripts.filter(script =>
                script.scriptName.toLowerCase().includes(searchTerm) ||
                script.scriptData.toLowerCase().includes(searchTerm) ||
                script.order.toString().includes(searchTerm)
            );
        }
        this.updatePaginationDetails();
    }

    // Sorting functionality
    handleSortapex(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortedByapex = fieldName;
        this.sortDirectionapex = sortDirection;

        const clonedData = [...this.scripts];
        clonedData.sort((a, b) => {
            let valueA = a[fieldName] || '';
            let valueB = b[fieldName] || '';

            if (typeof valueA === 'string') {
                valueA = valueA.toLowerCase();
                valueB = valueB.toLowerCase();
            }

            return sortDirection === 'asc'
                ? valueA < valueB ? -1 : valueA > valueB ? 1 : 0
                : valueA > valueB ? -1 : valueA < valueB ? 1 : 0;
        });

        this.scripts = clonedData;
        this.updatePaginationDetails();
    }

    // Update pagination details
    updatePaginationDetails() {
        this.totalSelectedPagesApexscript = this.totalPagesApex;
        this.selectedCurrentPageApexscript = this.currentPageApex;
        this.totalRecordsApexscript = this.scripts.length;
    }


    /*Apex script code end*/







    /****************** END OF METADATA MASKING PAGE CODE BLOCK ******************/


    /****************** DATA MASKING PAGE CODE BLOCK ******************/
    @track showDataMaskingPage = false;
    @track objectOptions = [];
    @api parentOrgId;
    @track showDataMaskingPage = false;
    @track objectOptions = [];
    @track selectedObject = '';
    @track showFieldsList = false;
    @track fieldsToDiplayInMasking = [];
    @track searchTerm = '';
    @track fieldscurrentPage = 1;
    @track sortedByFields;
    @track sortedDirectionFields = 'asc';
    @track selectedRows = [];
    @track selectedFieldsMap = new Map();
    @track selectedFieldsToDisplay = [];
    @track selectedFieldscurrentPage = 1;
    @track selectedSortedByFields;
    @track selectedSortedDirectionFields = 'asc';
    @track fieldspageSize = 5;  // Initial page size for available fields
    @track selectedFieldspageSize = 5;  // Initial page size for selected fields
    @track searchTermAvailableFields = '';  // Search term for available fields
    @track searchTermSelectedFields = '';   // Search term for selected fields
    @track showUnsupportedError = false;
    @track errorTimeout;
    @track isLoadingFields = false;
    @track allSelectedRows = new Set();
    @track selectedFieldsSelectedRows = [];
    @track dataTransformationLogRecord;
    @track dataTransformationLogName;
    @track dataTransformationLogUrl;
    @track dataTransformationStatus;
    @track dataTransformationId;
    @track isLoadingCust = false;
    @track showDataTransformationSpinner = false;
    @track showDataTransformationRefresh;
    @track dataTransformationLogResult;
    
    @wire(getDataTransformLogRecordofRefreshTemplate, { templateId: '$recordId' })
    wiredDataTransformationLog(result) {
        this.wiredDataTrans = result; // Store result for manual refresh
        this.dataTransformationLogResult = result;
        const { error, data } = result;
        if (data) {
            this.dataTransformationId = data.Id;
            this.dataTransformationLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
            this.dataTransformationLogName = data.Name;
            this.dataTransformationStatus = data.Status__c;
            this.showDataTransformationRefresh = data.Status__c == 'InProgress' ? true : false;
            this.error = undefined;
        } else if (error) {
            this.error = error; // Handles error

        }
    }

    dataTransformationSuccessToastShown = false;
    dataTransformationFailedToastShown = false;

    handleRefreshDataTransformation() {
        console.log('I am in handleRefreshDataTransformation');
        this.showDataTransformationSpinner = true;
        console.log('IN handleRefreshDataTransformation');
    
        refreshApex(this.dataTransformationLogResult)
            .then(() => {
                // After wire refresh, extract status again
                const status = this.dataTransformationStatus;
    
                if (status === 'InProgress') {
                    this.showToastMessage1('Info', 'Data Transformation is in progress.', 'info');
                } else if (status === 'Completed') {
                    if (!this.dataTransformationSuccessToastShown) {
                        this.showToastMessage1('Success', 'Data Transformation completed successfully.', 'success');
                        this.dataTransformationSuccessToastShown = true;
                    }
                } else if (status === 'Failed') {
                    if (!this.dataTransformationFailedToastShown) {
                        this.showToastMessage1('Error', 'Data Transformation failed. Please check the log.', 'error');
                        this.dataTransformationFailedToastShown = true;
                    }
                }
            })
            .catch(error => {
                console.error('Refresh error:', error);
                this.showToastMessage1('Error', 'Failed to refresh Data Transformation log.', 'error');
            })
            .finally(() => {
                this.showDataTransformationSpinner = false;
            });
    }

    handleBackFromDataMaskingPage() {
        this.currentvalue = '5'
        this.updateStepClasses(this.currentvalue);

        //this.showRestorePage = true;
        this.showRestorePage = true;
        this.showDataMaskingPage = false;

       /* hasDataInProgressBackupLogs({ refreshTemplateId: this.recordId })
            .then(result => {
                this.hasInProgressGeneralBackupLog = result;
            })
            .catch(error => {
                console.error('Error checking general backup logs:', error);
                this.hasInProgressGeneralBackupLog = false;
            });*/
    }

    handleNextFromDataMaskingPage() {
        this.currentvalue = '7'
        this.updateStepClasses(this.currentvalue);

        //this.showRestorePage = true;
        this.showUserTrans = true;
        this.showDataMaskingPage = false;
    }
    fieldsColumns = [
        {
            label: 'Field Label',
            fieldName: 'label',
            sortable: true,
            type: 'text',
            cellAttributes: {
                class: { fieldName: 'cellClass' }
            }
        },
        {
            label: 'API Name',
            fieldName: 'apiName',
            sortable: true,
            type: 'text',
            cellAttributes: {
                class: { fieldName: 'cellClass' }
            }
        },
        {
            label: 'Data Type',
            fieldName: 'dataType',
            sortable: true,
            type: 'text',
            cellAttributes: {
                class: { fieldName: 'cellClass' }
            }
        },
    ];


    selectedFieldsColumns = [
        {
            label: 'Object Name',
            fieldName: 'objectName',
            sortable: true,
            type: 'text'
        },
        {
            label: 'Field Label',
            fieldName: 'label',
            sortable: true,
            type: 'text'
        },
        {
            label: 'API Name',
            fieldName: 'apiName',
            sortable: true,
            type: 'text'
        },
        {
            label: 'Data Type',
            fieldName: 'dataType',
            sortable: true,
            type: 'text'
        },
    ];


    // Method to fetch custom objects based on parentOrgId
    async fetchAllCustomObjects() {
        if (!this.parentOrgId) {
            return;  // If parentOrgId is not available yet, don't fetch custom objects
        }

        try {
            console.log('I am in fetchAllCustomObjects');
            this.isLoadingCust = true;
            // Call the Apex method to fetch custom objects
            const result = await fetchAllCustomObjects({ sandboxId: this.parentOrgId });
            // Map the result into the options array for the combobox
            this.objectOptions = result.map(option => ({
                label: option,
                value: option
            }));
           
        } catch (error) {
            console.error('Error fetching custom objects:', error);
            this.isLoadingCust = false;
        } finally {
            // Set loading state to false after fetching (whether successful or not)
            this.isLoadingCust = false;
        }
    }

    @track pageSizeOptions = [5, 10, 25, 50, 100];

    handleObjectForMasking(event) {
        try {
            const selectedValue = event.target.value;

            // Reset states
            this.showFieldsList = false;
            this.filteredData = [];
            this.fieldsToDiplayInMasking = [];
            this.fieldspageSize = 5;
            this.fieldscurrentPage = 1;
            this.selectedFieldscurrentPage = 1;

            // Important: Don't clear the selectedRows here
            // this.selectedRows = [];

            if (selectedValue) {
                this.selectedObject = selectedValue;
                // Fetch fields will update filteredData through filterAndSortData
                this.fetchFieldsOfObject(this.selectedObject);
            } else {
                this.selectedObject = '';
            }

            // Since fetchFieldsOfObject is async, we need to update the filtered data 
            // and selection state here as well to ensure immediate UI response
            this.filterAndSortData();
            this.updateSelectionState();

        } catch (error) {
            console.error('Error in handleObjectForMasking:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error occurred while selecting object',
                    variant: 'error'
                })
            );
        }
    }

    // Fetch fields of the selected object
    async fetchFieldsOfObject(selectedObject) {
        console.log('i am in fetchFieldsOfObject');
        this.isLoadingFields = true;
        this.showFieldsList = false;
        try {
            const result = await fetchFieldsOfObject({
                sandboxId: this.parentOrgId,
                objectName: selectedObject
            });

            // Process fields to add selectable and styling properties
           this.fieldsToDiplayInMasking = result.map((field, index) => {
            const normalizedDataType = field.dataType === 'string' ? 'text' : field.dataType;
                const isSupported = this.isDataTypeSupported(normalizedDataType);
                const fieldId = `${field.apiName}-${index}`;

                // Check if this field is already selected for this object
                let isSelected = false;
                if (this.selectedFieldsMap.has(selectedObject)) {
                    const objectFields = this.selectedFieldsMap.get(selectedObject);
                    isSelected = Array.from(objectFields).some(fieldString => {
                        const selectedField = JSON.parse(fieldString);
                        return selectedField.apiName === field.apiName;
                    });
                }

                // If the field is selected, make sure it's in the allSelectedRows Set
                if (isSelected) {
                    this.allSelectedRows.add(fieldId);
                }

                return {
                    ...field,
                    dataType: normalizedDataType,
                    Id: fieldId,
                    selectable: isSupported,
                    isSelected: isSelected, // Add isSelected property based on selectedFieldsMap
                    checkboxDisabled: !isSupported, // Disable checkbox for unsupported fields
                    isSelectable: true, // Required for checkbox type column
                    cellClass: isSupported ? '' : 'slds-cell-edit slds-is-disabled',
                    rowClass: isSupported ? '' : 'unsupported-row',
                    checkboxClass: isSupported ? '' : 'unsupported-checkbox'
                };
            });

            this.filterAndSortData();
            this.updateSelectionState(); // Update selection state after loading fields
            this.showFieldsList = true;
        } catch (error) {
            console.error('Error fetching fields:', error);
        } finally {
            this.isLoadingFields = false;
        }
    }


    handleFieldsDatatableRowSelection(event) {
        console.log('Available Fields Selection Event:', event.detail);
        const selectedRows = event.detail.selectedRows;
        const currentPageRows = this.paginatedData;

        // Track which rows are being selected/deselected
        const newlySelected = [];
        const newlyDeselected = [];

        // Find newly deselected rows
        currentPageRows.forEach(row => {
            const wasSelected = this.allSelectedRows.has(row.Id);
            const isSelected = selectedRows.some(selected => selected.Id === row.Id);

            if (wasSelected && !isSelected) {
                newlyDeselected.push(row);
            } else if (!wasSelected && isSelected) {
                newlySelected.push(row);
            }
        });
        console.log('Newly deselected rows:', newlyDeselected);
        console.log('Newly selected rows:', newlySelected);

        // Handle deselections
        newlyDeselected.forEach(row => {
            this.allSelectedRows.delete(row.Id);

            // Remove from selectedFieldsMap
            if (this.selectedFieldsMap.has(this.selectedObject)) {
                const objectFields = this.selectedFieldsMap.get(this.selectedObject);
                objectFields.forEach(fieldString => {
                    const field = JSON.parse(fieldString);
                    if (field.Id === row.Id) {
                        objectFields.delete(fieldString);
                    }
                });
            }
        });

        // Handle new selections
        newlySelected.forEach(row => {
            if (!row.selectable) {
                console.log('Attempted to select unsupported field:', row);
                this.showUnsupportedError = true;
                if (this.errorTimeout) {
                    clearTimeout(this.errorTimeout);
                }
                this.errorTimeout = setTimeout(() => {
                    this.showUnsupportedError = false;
                }, 3000);
                return;
            }

            this.allSelectedRows.add(row.Id);

            // Add to selectedFieldsMap
            if (!this.selectedFieldsMap.has(this.selectedObject)) {
                this.selectedFieldsMap.set(this.selectedObject, new Set());
            }

            const fieldData = {
                objectName: this.selectedObject,
                label: row.label,
                apiName: row.apiName,
                dataType: row.dataType,
                Id: row.Id
            };
            this.selectedFieldsMap.get(this.selectedObject).add(JSON.stringify(fieldData));
        });

        if(this.allSelectedRows.size > 0  ){
            this.showSelectedMaskingFields = true
        }else{
            this.showSelectedMaskingFields = false
        }
        // Update both tables
        this.updateSelectionState();
    }



    closeErrorToast() {
        this.showUnsupportedError = false;
        if (this.errorTimeout) {
            clearTimeout(this.errorTimeout);
        }
    }



    updateSelectedFieldsDisplay() {
        const allSelectedFields = [];

        this.selectedFieldsMap.forEach((fields, objectName) => {
            fields.forEach(fieldString => {
                const field = JSON.parse(fieldString);
                // Only include fields that are in the selectedFieldsMap
                allSelectedFields.push({
                    ...field,
                    isSelected: this.allSelectedRows.has(field.Id)
                });
            });
        });

        // Apply search filter if exists
        if (this.searchTermSelectedFields) {
            const searchLower = this.searchTermSelectedFields.toLowerCase();
            this.selectedFieldsToDisplay = allSelectedFields.filter(field =>
                field.apiName.toLowerCase().includes(searchLower) ||
                field.label.toLowerCase().includes(searchLower) ||
                field.dataType.toLowerCase().includes(searchLower)
            );
        } else {
            this.selectedFieldsToDisplay = allSelectedFields;
        }

        // Update selected rows for the selected fields table
        this.selectedFieldsSelectedRows = this.selectedFieldsToDisplay
            .filter(row => this.allSelectedRows.has(row.Id))
            .map(row => row.Id);
    }

    // Get paginated data and mark selected fields in Available Fields
    get paginatedData() {
        const start = (this.fieldscurrentPage - 1) * this.fieldspageSize;
        const end = this.fieldscurrentPage * this.fieldspageSize;
        const paginatedData = this.filteredData.slice(start, end);

        return paginatedData.map(item => ({
            ...item,
            // Add a CSS class to style unselectable rows differently
            cellAttributes: {
                class: item.selectable ? '' : 'slds-cell-edit slds-is-disabled'
            }
        }));
    }


    get paginatedSelectedData() {
        if (!this.selectedFieldsToDisplay.length) {
            return [];
        }
        const start = (this.selectedFieldscurrentPage - 1) * this.selectedFieldspageSize;
        const end = this.selectedFieldscurrentPage * this.selectedFieldspageSize;
        return this.selectedFieldsToDisplay.slice(start, end);
    }
    get totalPages() {
        return Math.ceil((this.filteredData?.length || 0) / this.fieldspageSize);
    }

    get isFirstPage() {
        return this.fieldscurrentPage === 1;
    }

    get isLastPage() {
        const nextPageStart = this.fieldscurrentPage * this.fieldspageSize;
        return nextPageStart >= this.filteredData.length;
    }
    

    get totalSelectedPages() {
        return Math.ceil(this.selectedFieldsToDisplay.length / this.selectedFieldspageSize) || 1;
    }

    get isSelectedFirstPage() {
        return this.selectedFieldscurrentPage === 1;
    }

    get isSelectedLastPage() {
        return this.selectedFieldscurrentPage === this.totalSelectedPages;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.fieldscurrentPage = 1;
        this.filterAndSortData();
    }

    handleSortFields(event) {
        this.sortedByFields = event.detail.fieldName;
        this.sortedDirectionFields = event.detail.sortDirection;
        this.filterAndSortData();
        this.fieldscurrentPage = 1;
        this.updateSelectionState();
    }

    handleSelectedSort(event) {
        this.selectedSortedByFields = event.detail.fieldName;
        this.selectedSortedDirectionFields = event.detail.sortDirection;

        this.selectedFieldsToDisplay = [...this.selectedFieldsToDisplay].sort((a, b) => {
            let valueA = a[this.selectedSortedByFields] || '';
            let valueB = b[this.selectedSortedByFields] || '';

            if (typeof valueA === 'string') valueA = valueA.toLowerCase();
            if (typeof valueB === 'string') valueB = valueB.toLowerCase();

            return this.selectedSortedDirectionFields === 'asc' ?
                valueA.localeCompare(valueB) : valueB.localeCompare(valueA);
        });
    }

    handleNextData() {
        if (this.fieldscurrentPage < this.totalPages) {
            this.fieldscurrentPage++;
            // Update selectedRows for the new page
            this.selectedRows = Array.from(this.allSelectedRows)
                .filter(id => this.paginatedData.some(row => row.Id === id));
        }
    }

    handlePreviousData() {
        if (this.fieldscurrentPage > 1) {
            this.fieldscurrentPage--;
            // Update selectedRows for the new page
            this.selectedRows = Array.from(this.allSelectedRows)
                .filter(id => this.paginatedData.some(row => row.Id === id));
        }
    }

    handleFirstData() {
        this.fieldscurrentPage = 1;
        // Update selectedRows for the new page
        this.selectedRows = Array.from(this.allSelectedRows)
            .filter(id => this.paginatedData.some(row => row.Id === id));
    }

    handleLastData() {
        this.fieldscurrentPage = this.totalPages;
        // Update selectedRows for the new page
        this.selectedRows = Array.from(this.allSelectedRows)
            .filter(id => this.paginatedData.some(row => row.Id === id));
    }

    handleSelectedFirstData() {
        this.selectedFieldscurrentPage = 1;
        this.updateSelectedFieldsDisplay();
    }

    handleSelectedPreviousData() {
        if (this.selectedFieldscurrentPage > 1) {
            this.selectedFieldscurrentPage--;
            this.updateSelectedFieldsDisplay();
        }
    }

    handleSelectedNextData() {
        if (this.selectedFieldscurrentPage < this.totalSelectedPages) {
            this.selectedFieldscurrentPage++;
            this.updateSelectedFieldsDisplay();
        }
    }

    handleSelectedLastData() {
        this.selectedFieldscurrentPage = this.totalSelectedPages;
        this.updateSelectedFieldsDisplay();
    }

    filterAndSortData() {
        let filteredData = [...this.fieldsToDiplayInMasking];

        // Apply support status filter
        /*if (this.selectedSupportFilter !== 'all') {
            filteredData = filteredData.filter(record => {
                const isSupported = this.isDataTypeSupported(record.dataType);
                return this.selectedSupportFilter === 'supported' ? isSupported : !isSupported;
            });
        }*/

            if (this.selectedSupportFilter !== 'all') {
                filteredData = filteredData.filter(record => {
                    const normalizedType = record.dataType?.toLowerCase();
                    const filterValue = this.selectedSupportFilter.toLowerCase();
                    const isSupported = this.isDataTypeSupported(record.dataType);
        
                    if (filterValue === 'supported') {
                        return isSupported;
                    } else if (filterValue === 'unsupported') {
                        return !isSupported;
                    } else if (filterValue === 'text') {
                        return normalizedType === 'text' || normalizedType === 'string';
                    } else {
                        return normalizedType === filterValue;
                    }
                });
            }
            

        // Apply search filter
        if (this.searchTermAvailableFields) {
            const searchLower = this.searchTermAvailableFields.toLowerCase();
            filteredData = filteredData.filter(record =>
                (record.apiName && record.apiName.toLowerCase().includes(searchLower)) ||
                (record.label && record.label.toLowerCase().includes(searchLower)) ||
                (record.dataType && record.dataType.toLowerCase().includes(searchLower))
            );
        }
        

        // Apply sorting
        if (this.sortedByFields) {
            filteredData.sort((a, b) => {
                let valueA = a[this.sortedByFields] || '';
                let valueB = b[this.sortedByFields] || '';

                valueA = valueA.toLowerCase();
                valueB = valueB.toLowerCase();

                if (valueA < valueB) {
                    return this.sortedDirectionFields === 'asc' ? -1 : 1;
                }
                if (valueA > valueB) {
                    return this.sortedDirectionFields === 'asc' ? 1 : -1;
                }
                return 0;
            });
        }
        // Preserve the selection state for filtered data
        filteredData.forEach(field => {
            field.isSelected = this.allSelectedRows.has(field.Id);
        });


        this.filteredData = filteredData;
    }


    // Handler for available fields page size change
    handleavailablefieldsPerPage(event) {
        const selectedPageSize = event.target.value;
        this.fieldspageSize = parseInt(selectedPageSize, 10);  // Update page size
        this.fieldscurrentPage = 1;  // Reset to first page
        this.filterAndSortData();    // Re-apply the filtering and sorting
        this.updateSelectionState();
    }

    // Handler for selected fields page size change
    handleselectedfieldsPerPage(event) {
        const selectedPageSize = event.target.value;
        this.selectedFieldspageSize = parseInt(selectedPageSize, 10);  // Update page size
        this.selectedFieldscurrentPage = 1;  // Reset to first page
        this.updateSelectedFieldsDisplay(); // Update the selected fields display
    }

    // Handle search for Available Fields
    handleSearchAvailableFields(event) {
        this.searchTermAvailableFields = event.target.value;
        this.fieldscurrentPage = 1;
        this.filterAndSortData();
        this.updateSelectionState();
    }

    // Handle search for Selected Fields
    handleSearchSelectedFields(event) {
        this.searchTermSelectedFields = event.target.value;
        this.selectedFieldscurrentPage = 1;
        this.updateSelectedFieldsDisplay();
    }


    handleSelectedFieldsSelection(event) {
        const selectedRows = event.detail.selectedRows;
        const currentSelectedPageRows = this.paginatedSelectedData;

        // Track which rows are being deselected
        currentSelectedPageRows.forEach(row => {
            const isSelected = selectedRows.some(selected => selected.Id === row.Id);

            if (!isSelected) {
                // Remove from allSelectedRows
                this.allSelectedRows.delete(row.Id);

                // Remove from selectedFieldsMap
                if (this.selectedFieldsMap.has(row.objectName)) {
                    const objectFields = this.selectedFieldsMap.get(row.objectName);
                    const fieldToRemove = Array.from(objectFields)
                        .find(fieldString => {
                            const field = JSON.parse(fieldString);
                            return field.Id === row.Id;
                        });
                    if (fieldToRemove) {
                        objectFields.delete(fieldToRemove);
                    }
                }
            }
        });

        // Handle newly selected rows
        selectedRows.forEach(row => {
            this.allSelectedRows.add(row.Id);
        });

        // Update both tables
        this.updateSelectionState();
    }


    updateSelectionState() {
        // Update available fields selection state
        this.fieldsToDiplayInMasking.forEach(field => {
            field.isSelected = this.allSelectedRows.has(field.Id);
        });

        // Update the filteredData as well since that's what powers the table
        if (this.filteredData) {
            this.filteredData.forEach(field => {
                field.isSelected = this.allSelectedRows.has(field.Id);
            });
        }

        // Update current page selections for available fields table
        const currentAvailablePageIds = this.paginatedData.map(row => row.Id);
        this.selectedRows = Array.from(this.allSelectedRows)
            .filter(id => currentAvailablePageIds.includes(id));

        // Update selected fields table
        this.updateSelectedFieldsDisplay();
    }
    
    shouldDisplayField(field) {
        // Check if the field exists in selectedFieldsMap
        if (this.selectedFieldsMap.has(field.objectName)) {
            const objectFields = this.selectedFieldsMap.get(field.objectName);
            return Array.from(objectFields).some(fieldString => {
                const parsedField = JSON.parse(fieldString);
                return parsedField.Id === field.Id;
            });
        }
        return false;
    }


    @track selectedSupportFilter = 'all';
    supportedDataTypes = [
        'Text',
        'Currency',
        'Date',
        'DateTime',
        'URL',
        'Email',
        'Phone',
        'TextArea'
    ];
    get supportFilterOptions() {
        return [
            { label: 'All Data Types', value: 'all' },
            { label: 'Supported Data Types', value: 'supported' },
            { label: 'Unsupported Data Types', value: 'unsupported' },
            { label: 'Text', value: 'text' },
            { label: 'Phone', value: 'phone' },
            { label: 'Currency', value: 'currency' },
            { label: 'Date', value: 'cate' },
            { label: 'DateTime', value: 'cateTime' },
            { label: 'URL', value: 'url' },
            { label: 'Email', value: 'email' },
            { label: 'Text Area', value: 'textarea' }
        ];
    }

    isDataTypeSupported(dataType) {
        return this.supportedDataTypes.some(type =>
            dataType.toLowerCase().includes(type.toLowerCase())
        );
    }

    handleSupportFilterChange(event) {
        this.selectedSupportFilter = event.target.value;
        //this.selectedRows = []; // Clear selections when changing filter
        this.filterAndSortData();
        this.updateSelectionState();
    }

    handleClearAll() {
        // Clear selections
        this.allSelectedRows.clear();
        this.selectedRows = [];
        this.selectedFieldsMap.clear();

        // Clear search terms
        this.searchTermAvailableFields = '';
        this.searchTermSelectedFields = '';

        // Reset filters and sorting
        this.selectedSupportFilter = 'all';
        this.sortedByFields = undefined;
        this.sortedDirectionFields = 'asc';
        this.selectedSortedByFields = undefined;
        this.selectedSortedDirection = 'asc';

        // Reset pagination
        this.fieldscurrentPage = 1;
        this.selectedFieldscurrentPage = 1;
        this.filteredData = [];
        this.showFieldsList = false;
        this.fieldsToDiplayInMasking = [];

        // Update displays
        this.filterAndSortData();
        this.updateSelectedFieldsDisplay();
        this.selectedObject = '';
        this.fieldspageSize = 5;
        this.selectedFieldspageSize = 5;
    }

    // Getter for total available fields
    get totalAvailableFields() {
        return this.filteredData?.length || 0;
    }

    // Getter for total selected fields
    get totalSelectedFields() {
        return this.selectedFieldsToDisplay?.length || 0;
    }
    get sandboxUrl() {
        return `/${this.usersInformation.backupDetails.sandboxId}`;
    }

    // Function to open the modal when 'Execute' button is clicked
    handleExecuteDataMasking() {
        this.isModalOpenfordata = true;
    }

    // Close the modal (Cancel button or Close button)
    closeModal() {
        if (!this.isProcessing) {
            this.isModalOpenfordata = false;
        }
    }

    // Function to confirm and apply data masking
    confirmDataMasking() {
        this.isModalOpenfordata = false;
        this.isProcessing = true;
        console.log('Preparing data for masking...');

        // Create array to hold formatted data
        const formattedData = [];

        // Loop through selected fields and prepare the data
        this.selectedFieldsMap.forEach((fields, objectName) => {
            console.log(`Processing object: ${objectName}`);

            // Convert Set of stringified fields to array of field names
            const members = Array.from(fields).map(fieldString => {
                try {
                    const field = JSON.parse(fieldString);
                    console.log(`Parsed field: ${field.apiName}`);
                    return field.apiName;
                } catch (err) {
                    console.error(`Error parsing field: ${fieldString}`, err);
                    return null;
                }
            }).filter(field => field !== null);

            // Only add objects that have selected fields
            if (members.length > 0) {
                formattedData.push({
                    type: objectName,
                    members: members
                });
            }
        });

        console.log('Formatted data:', formattedData);

        // Convert to JSON string for Apex
        const mapJson = JSON.stringify(formattedData);
        console.log('JSON string for Apex:', mapJson);

        // Call Apex method
        try {
            console.log('Calling Apex method applyDataMasking...');
            applyDataMasking({
                sandboxId: this.parentOrgId,
                refTempId: this.recordId,
                mapJson: mapJson
            })
                .then(result => {
                    console.log('Data masking applied successfully:', result);
                    this.dataTransformationLogRecord = result;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Info',
                            message: 'Data Transformation initiated successfully.',
                            variant: 'info'
                        })
                    );

                    this.getDataTransformLogRecord(this.dataTransformationLogRecord);
                  /*  this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Data masking configuration saved successfully',
                            variant: 'success'
                        })
                    );*/
                    this.handleClearAll();
                })
                .catch(error => {
                    console.error('Error applying data masking:', error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Failed to save data masking configuration: ' + error.body.message,
                            variant: 'error'
                        })
                    );
                })
                .finally(() => {
                    this.isProcessing = false; // Reset processing state
                });
        } catch (error) {
            console.error('Error in handleApplyDataMasking:', error);
            this.isProcessing = false;
        }
    }

    getDataTransformLogRecord(dataTransformationLogRecord) {
        getDataTransformLogRecord({ logRecId: dataTransformationLogRecord })
            .then((data) => {
                console.log('getDeployLogRecord data: ', data);
                if (data) {
                    this.dataTransformationLogUrl = `/lightning/r/Logs__c/${data.Id}/view`;
                    this.dataTransformationLogName = data.Name;
                    this.dataTransformationStatus = data.Status__c;
                    //this.lastDeploymentDate = data.Last_Deployment_Date__c;
                    if (this.dataTransformationStatus === 'InProgress') {
                        this.showDataTransformationRefresh = true;
                    }
                }
                else {
                    console.log('there is no validated record yet for this template ---- ');
                    this.dataTransformationLogUrl = null;
                    this.dataTransformationLogName = null;
                }
            })
    }

    isModalOpenfordata = false;

    get isExecuteDataMaskingButtonDisabled() {
        // Check the permission condition (user doesn't have required permissions)
        //const permissionCheck = !(this.hasAdvancePermissionSet || this.isSystemAdmin);
        const isBasicOnlyUser = this.hasBasicPermissionSet && !this.hasAdvancePermissionSet && !this.isSystemAdmin;
        console.log('Data masking - execute Disable permission check --', isBasicOnlyUser);

        // Combine with existing condition for user activity status
        return isBasicOnlyUser || this.allSelectedRows.size === 0 || this.isProcessing || this.dataTransformationStatus === 'InProgress' || this.showAuthenticateButton;
    }

    get hasSelectedRows() {
        return this.allSelectedRows.size > 0; // Returns true if there are selected rows
    }

    @track isProcessing = false;


    /****************** END OF DATA MASKING PAGE CODE BLOCK ******************/


    /****************** START OF USER TRANSFORMATION PAGE CODE BLOCK ******************/
    // User data and filtering
    @track allUsers = [];
    @track filteredUsersTrans = [];
    @track selectedUsers = [];
    @track displayedUsers = [];
    @track showResetPasswordsModal = false;
    @track showRemoveInvalidModal = false;
    @track showActivateModal = false;
    @track showDeactivateModal = false;
    @track selectedRowsTrans = [];


    // View options
    @track currentView = 'All Users'; // Default to All Users
    @track viewOptions = [
        { label: 'All Users', value: 'All Users' },
        { label: 'Active Users', value: 'Active Users' },
        { label: 'Inactive Users', value: 'Inactive Users' },
        { label: 'Admin Users', value: 'Admin Users' }
    ];

    // Tracking selected rows by ID for consistency
    @track selectedUserIds = new Set();

    // Sorting
    @track sortedByTrans;
    @track sortDirectionTrans = 'asc';

    // Pagination
    @track pageSizeTrans = 10;
    @track currentPageTrans = 1;

    // Alphabet filter
    @track alphabetList = [];
    @track currentLetter = 'All';

    // Loading state
    @track isLoadingTrans = false;

    // Pagination data
    @track nextRecordsUrl = '';
    @track oldNextRecordsUrl = '';

    // Status fields
    @track passwordResetLog;
    @track passwordResetLogUrl;
    @track passwordResetStatus;
    @track activationLog;
    @track activationStatus;
    @track activationLogUrl;
    @track invalidRemovalLog;
    @track invalidRemovalLogUrl;
    @track invalidRemovalStatus;
    @track deactivationLog = '';
    @track deactivationStatus = '';
    @track deactivationId;
    @track deactivationLogUrl;


    // Toast
    @track showToast = false;
    @track toastMessage = '';
    @track toastType = '';
    @track toastClass = '';
    @track toastIcon = '';
    @track showUserTransformRefreshIcon = false;

    // Define the columns for the lightning-datatable component
    @track columns = [
        { label: 'Name', fieldName: 'name', type: 'text', sortable: true },
        { label: 'Email', fieldName: 'email', type: 'text', sortable: true },
        { label: 'Username', fieldName: 'username', type: 'text', sortable: true },
        { label: 'Profile', fieldName: 'profile', type: 'text', sortable: true },
        { label: 'Active', fieldName: 'isActive', type: 'text', sortable: true }
    ];

    // Selected Users tracking variables
    @track filteredSelectedUsers = [];
    @track displayedSelectedUsers = [];

    // Selected Users pagination
    @track selectedPageSizeTrans = 10;
    @track selectedCurrentPage = 1;
    @track selectedPageSizeOptionstrans = [10, 25, 50, 100];
    @track selectedSearchTerm = '';

    // Selected Users sorting
    @track selectedSortedByTrans;
    @track selectedSortDirectionTrans = 'asc';

    @track wiredUserTransformResult;
    //Wire to get the log records for Template ID.
    @wire(getUserTransfLogRecordofRefreshTemplate, { templateId: '$recordId' })
    wiredUserTransform(result) {
        this.wiredUserTransformResult = result;
        const { error, data } = result;
        if (data) {
            console.log('LogData:: ' + JSON.stringify(data));
            // Iterate through each log record in the returned list
            data.forEach(log => {
                if (log.Log_Type__c === 'User Deactivation - Post Refresh' && !this.deactivationId) {
                    this.deactivationStatus = log.Status__c;
                    this.deactivationLog = log.Name;
                    this.deactivationId = log.Id;
                    this.deactivationLogUrl = `/lightning/r/Logs__c/${log.Id}/view`;
                }
                else if (log.Log_Type__c === 'Reset User Password - Post Refresh' && !this.passwordResetLogUrl) {
                    this.passwordResetStatus = log.Status__c;
                    this.passwordResetLog = log.Name;
                    this.passwordResetLogUrl = `/lightning/r/Logs__c/${log.Id}/view`;
                }
                else if (log.Log_Type__c === 'User Email Validation - Post Refresh' && !this.invalidRemovalLogUrl) {
                    this.invalidRemovalStatus = log.Status__c;
                    this.invalidRemovalLog = log.Name;
                    this.invalidRemovalLogUrl = `/lightning/r/Logs__c/${log.Id}/view`;
                }
                else if (log.Log_Type__c === 'User Activation - Post Refresh' && !this.activationLogUrl) {
                    this.activationStatus = log.Status__c;
                    this.activationLog = log.Name;
                    this.activationLogUrl = `/lightning/r/Logs__c/${log.Id}/view`;
                }
            });

        }
        else if (error) {
            console.error('Error loading template:', error);
        }
        this.computeShowUserTransformRefresh();
    }

    computeShowUserTransformRefresh() {
        // If either record is InProgress, keep the refresh icon visible
        this.showUserTransformRefreshIcon = (this.deactivationStatus === 'InProgress' || this.passwordResetStatus === 'InProgress' || this.invalidRemovalStatus === 'InProgress' || this.activationStatus === 'InProgress');
    }

    @track showSpinnerForUserTransform = false;
    @track showUserTransformRefreshIcon = false;

    
            // Toast flags
            userDeactivationSuccessToastShown = false;
            userDeactivationFailedToastShown = false;
            
            userPasswordResetSuccessToastShown = false;
            userPasswordResetFailedToastShown = false;
            
            userInvalidRemovalSuccessToastShown = false;
            userInvalidRemovalFailedToastShown = false;
            
            userActivationSuccessToastShown = false;
            userActivationFailedToastShown = false;
            
            // Execution start time
            userTransformationExecutionStartTime = null;
    


            handleRefreshUserTransformation() {
                console.log('Checking user transformation log statuses...');
                this.showSpinnerForUserTransform = true;
            
                refreshApex(this.wiredUserTransformResult)
                    .then(() => {
                        const startTime = this.userTransformationExecutionStartTime
                            ? new Date(this.userTransformationExecutionStartTime)
                            : null;
            
                        const logList = this.wiredUserTransformResult.data || [];
            
                        logList.forEach(log => {
                            const status = log.Status__c;
                            const logTime = new Date(log.LastModifiedDate);
                            const isNewLog = startTime && logTime >= startTime;
            
                            if (log.Log_Type__c === 'User Deactivation - Post Refresh') {
                                if (status === 'InProgress') {
                                    this.showToastMessage('User Deactivation', 'User Deactivation is in progress.', 'info');
                                    this.showUserTransformRefreshIcon = true;
                                } else if (status === 'Failed' && isNewLog && !this.userDeactivationFailedToastShown) {
                                    this.showToastMessage('User Deactivation', 'User Deactivation failed.', 'error');
                                    this.userDeactivationFailedToastShown = true;
                                } else if (status === 'Completed' && isNewLog && !this.userDeactivationSuccessToastShown) {
                                    this.showToastMessage('User Deactivation', 'User Deactivation completed.', 'success');
                                    this.userDeactivationSuccessToastShown = true;
                                }
                            }
            
                            if (log.Log_Type__c === 'Reset User Password - Post Refresh') {
                                if (status === 'InProgress') {
                                    this.showToastMessage('Reset Password', 'Reset Password is in progress.', 'info');
                                    this.showUserTransformRefreshIcon = true;
                                } else if (status === 'Failed' && isNewLog && !this.userPasswordResetFailedToastShown) {
                                    this.showToastMessage('Reset Password', 'Reset Password failed.', 'error');
                                    this.userPasswordResetFailedToastShown = true;
                                } else if (status === 'Completed' && isNewLog && !this.userPasswordResetSuccessToastShown) {
                                    this.showToastMessage('Reset Password', 'Reset Password completed.', 'success');
                                    this.userPasswordResetSuccessToastShown = true;
                                }
                            }
            
                            if (log.Log_Type__c === 'User Email Validation - Post Refresh') {
                                if (status === 'InProgress') {
                                    this.showToastMessage('Remove Invalid Emails', 'Removal of invalid emails is in progress.', 'info');
                                    this.showUserTransformRefreshIcon = true;
                                } else if (status === 'Failed' && isNewLog && !this.userInvalidRemovalFailedToastShown) {
                                    this.showToastMessage('Remove Invalid Emails', 'Removal of invalid emails failed.', 'error');
                                    this.userInvalidRemovalFailedToastShown = true;
                                } else if (status === 'Completed' && isNewLog && !this.userInvalidRemovalSuccessToastShown) {
                                    this.showToastMessage('Remove Invalid Emails', 'Invalid emails removed successfully.', 'success');
                                    this.userInvalidRemovalSuccessToastShown = true;
                                }
                            }
            
                            if (log.Log_Type__c === 'User Activation - Post Refresh') {
                                if (status === 'InProgress') {
                                    this.showToastMessage('User Activation', 'User Activation is in progress.', 'info');
                                    this.showUserTransformRefreshIcon = true;
                                } else if (status === 'Failed' && isNewLog && !this.userActivationFailedToastShown) {
                                    this.showToastMessage('User Activation', 'User Activation failed.', 'error');
                                    this.userActivationFailedToastShown = true;
                                } else if (status === 'Completed' && isNewLog && !this.userActivationSuccessToastShown) {
                                    this.showToastMessage('User Activation', 'User Activation completed successfully.', 'success');
                                    this.userActivationSuccessToastShown = true;
                                }
                            }
                        });
            
                        // Hide icon if all logs are completed
                        const stillInProgress = logList.some(log => log.Status__c === 'InProgress');
                        this.showUserTransformRefreshIcon = stillInProgress;
                    })
                    .catch(error => {
                        console.error('Refresh Error:', error);
                        this.showToastMessage('Error', 'Error checking log statuses.', 'error');
                    })
                    .finally(() => {
                        this.showSpinnerForUserTransform = false;
                    });
            }
            
            

    // Initialize alphabet filter
    setupAlphabetFilter() {
        console.log('UserManagement: setupAlphabetFilter');
        const letters = [];
        letters.push({
            label: 'All',
            value: 'All',
            className: this.currentLetter === 'All' ? 'slds-button slds-button_brand' : 'slds-button slds-button_neutral'
        });

        for (let i = 65; i <= 90; i++) {
            const letter = String.fromCharCode(i);
            letters.push({
                label: letter,
                value: letter,
                className: this.currentLetter === letter ? 'slds-button slds-button_brand' : 'slds-button slds-button_neutral'
            });
        }

        this.alphabetList = letters;
        console.log('UserManagement: alphabetList created with', this.alphabetList.length, 'letters');
    }

    // Load users based on current filters
    loadUsers() {
        this.isLoadingTrans = true;

        // Get search and filter parameters
        const searchInput = this.template.querySelector('input[data-id="searchInput"]');
        const searchString = searchInput ? searchInput.value : '';
        const sortBy = this.currentLetter !== 'All' ? this.currentLetter : '';

        let isActive = 'All Users';
        if (this.currentView === 'Active Users') {
            isActive = 'Active Users';
        } else if (this.currentView === 'Inactive Users') {
            isActive = 'InActive Users';
        }

        // Only pass queryEndpoint if it has an actual value
        const queryEndpoint = this.nextRecordsUrl ? this.nextRecordsUrl : null;

        fetchAllUsers({
            refTempId: this.recordId,
            queryEndpoint: queryEndpoint,
            searchString: searchString,
            sortBy: sortBy,
            isActive: isActive
        })
            .then(result => {
                if (result && result.users && result.users.length > 0) {
                  
                    let transformedUsers = result.users.map(user => {
                        // Determine active status
                        let isActiveVal = user.isActive;
                        let activeVal = false;

                        if (typeof isActiveVal === 'boolean') {
                            activeVal = isActiveVal;
                        } else if (typeof isActiveVal === 'string') {
                            activeVal = isActiveVal === 'Yes' || isActiveVal.toLowerCase() === 'true';
                        }

                        return {
                            id: user.id || '',
                            name: user.name || '',
                            username: user.username || '',
                            email: user.email || '',
                            profile: user.profile || '',
                            isActive: isActiveVal,
                            // Make sure each user reflects its selection state
                            selected: this.selectedUserIds.has(user.username),
                            isAdmin: user.profile && user.profile.toLowerCase().includes('admin'),
                            active: activeVal
                        };
                    });

                    // Update pagination URL
                    if (this.nextRecordsUrl !== result.nextRecordsUrl) {
                        this.oldNextRecordsUrl = this.nextRecordsUrl;
                    }
                    this.nextRecordsUrl = result.nextRecordsUrl;

                    // First load or filter change
                    if (!this.oldNextRecordsUrl || this.allUsers.length === 0) {
                        this.allUsers = transformedUsers;
                    } else {
                        this.allUsers = [...this.allUsers, ...transformedUsers];
                    }
                    console.log('this.allUsers= '+this.allUsers);

                    this.filterUsersTrans();
                    this.updateSelectedUsersFromAllUsers();

                    if(this.filteredUsersTrans.length == 0 ){
                        this.totalRecordsUsers = 0 ;
                    }else{
                        this.totalRecordsUsers = this.filteredUsersTrans.length;
                    }

                    console.log('this.allUsers= '+this.allUsers);
                    console.log('this.filteredUsersTrans = '+this.filteredUsersTrans);

                    // Important: Set the selected rows after the datatable has fully rendered
                    setTimeout(() => {
                        this.selectRowsBasedOnIds();
                    }, 100);
                } else {
                    // Empty result
                    this.allUsers = [];
                    this.filteredUsersTrans = [];
                    this.displayedUsers = [];
                    this.totalRecordsUsers = 0;
                }
            })
            .catch(error => {
                this.totalRecordsUsers = 0;
                console.error('Error fetching users:', error);
            })
            .finally(() => {
                this.isLoadingTrans = false;
            });
    }

    renderedCallback() {
        // Get references to both datatables
        const availableDatatable = this.template.querySelector('lightning-datatable[key-field="username"][data-id="availableUsersTable"]');
        const selectedDatatable = this.template.querySelector('lightning-datatable[key-field="username"][data-id="selectedUsersTable"]');

        // Only run this once the datatables are available
        if (availableDatatable && this.displayedUsers.length > 0) {
            // Find usernames of users that should be selected on the current page
            const usernamesToSelect = this.displayedUsers
                .filter(user => this.selectedUserIds.has(user.username))
                .map(user => user.username);

            // Update available users table
            if (usernamesToSelect.length > 0 || availableDatatable.selectedRows.length > 0) {
                console.log('Setting available users selected rows to:', usernamesToSelect);
                availableDatatable.selectedRows = usernamesToSelect;
            }
        }

        // Update selected users table
        if (selectedDatatable && this.displayedSelectedUsers.length > 0) {
            // All rows in the selected users table should be selected
            const selectedUsernames = this.displayedSelectedUsers.map(user => user.username);
            console.log('Setting selected users rows to:', selectedUsernames);
            selectedDatatable.selectedRows = selectedUsernames;
        }
    }


    updateSelectedUsersFromAllUsers() {
        this.selectedUsers = this.allUsers
            .filter(user => this.selectedUserIds.has(user.username))
            .map(user => ({ ...user, selected: true }));

        // Update the selected users table
        this.filterSelectedUsers();
    }

    // Load more users for pagination
    loadMoreUsers() {
        console.log('UserManagement: loadMoreUsers');
        console.log('UserManagement: nextRecordsUrl exists?'+this.nextRecordsUrl);

        if (this.nextRecordsUrl) {
            this.loadUsers();
        }
    }

    // Filter users based on current view and search criteria
    filterUsersTrans() {
        console.log('UserManagement: filterUsersTrans');
        console.log('UserManagement: currentView', this.currentView);
        console.log('UserManagement: currentLetter', this.currentLetter);

        let filtered = [...this.allUsers];
        console.log('UserManagement: starting with', filtered.length, 'users');

        // Filter by view
        if (this.currentView === 'Admin Users') {
            filtered = filtered.filter(user => user.isAdmin);
            console.log('UserManagement: filtered to admin users', filtered.length);
        }

        // Filter by alphabet
        if (this.currentLetter !== 'All') {
            filtered = filtered.filter(user =>
                (user.name && user.name.startsWith(this.currentLetter))
            );
            console.log('UserManagement: filtered by letter', this.currentLetter, 'to', filtered.length, 'users');
        }

        // Search filter (if any)
        const searchInput = this.template.querySelector('input[data-id="searchInput"]');
        if (searchInput && searchInput.value) {
            const searchKey = searchInput.value.toLowerCase();
            console.log('UserManagement: filtering by search key', searchKey);

            filtered = filtered.filter(user => {
                const name = (user.name || '').toLowerCase();
                const email = (user.email || '').toLowerCase();
                const username = (user.username || '').toLowerCase();
                const profile = (user.profile || '').toLowerCase();
        
                return (
                    name.includes(searchKey) ||
                    email.includes(searchKey) ||
                    username.includes(searchKey) ||
                    profile.includes(searchKey)
                );
            });
            console.log('UserManagement: filtered by search to', filtered.length, 'users');
            console.log('Sample user:', this.allUsers[0]);

        }

        // Ensure each user's selection status is correctly set
        filtered = filtered.map(user => ({
            ...user,
            selected: this.selectedUserIds.has(user.username)
        }));

        this.filteredUsersTrans = filtered;
        console.log('UserManagement: final filteredUsersTrans count', this.filteredUsersTrans.length);

        // Reset to first page when filters change
        this.currentPageTrans = 1;

        this.updateDisplayedUsers();

        // If we have no results, check if more data is available to load from server
        if (this.filteredUsersTrans.length === 0 && this.nextRecordsUrl) {
            console.log('UserManagement: No users found in current data, attempting to load more');
            this.loadMoreUsers();
        }

        // Make sure to set the selected rows after filtering
        setTimeout(() => {
            this.selectRowsBasedOnIds();
        }, 100);
    }

    updateDisplayedUsers() {
        if (this.filteredUsersTrans.length === 0) {
            this.displayedUsers = [];
            return;
        }

        const start = (this.currentPageTrans - 1) * this.pageSizeTrans;
        const end = this.currentPageTrans * this.pageSizeTrans;

        // Get users for current page and mark them as selected if they are in selectedUserIds
        this.displayedUsers = this.filteredUsersTrans.slice(start, end).map(user => ({
            ...user,
            selected: this.selectedUserIds.has(user.username)
        }));
    }

    // Handle view change (All Users, Active Users, Inactive Users, Admin Users)
    handleViewChange(event) {
        const newView = event.target.value;
        this.showSelectedUserTable = false

        this.currentView = newView;
        this.currentPageTrans = 1;
        this.nextRecordsUrl = '';
        this.allUsers = [];

        // Clear all selections
        this.selectedUserIds = new Set();
        this.selectedUsers = [];
        this.filteredSelectedUsers = [];
        this.displayedSelectedUsers = [];

        // Reset filters
        this.currentLetter = 'All';
        this.setupAlphabetFilter();

        // Clear search
        const searchInput = this.template.querySelector('input[data-id="searchInput"]');
        if (searchInput) {
            searchInput.value = '';
        }

        // Load new data
        this.loadUsers();
    }

    // Handle alphabet filter
    handleAlphabetFilter(event) {
        const letter = event.currentTarget.dataset.letter;
        console.log('UserManagement: handleAlphabetFilter from', this.currentLetter, 'to', letter);

        this.currentLetter = letter;
        this.setupAlphabetFilter();
        this.currentPageTrans = 1;

        // Reset data and reload with new filter
        this.nextRecordsUrl = '';
        this.allUsers = [];
        this.loadUsers();
    }

    // Handle search key press
    handleSearchKey(event) {
        console.log('UserManagement: handleSearchKey', event.key);
        console.log('UserManagement: search value', event.target.value);

        // If Enter key is pressed or this is not a key event (e.g., button click)
        if (!event.key || event.key === 'Enter' || event.target.value === '') {
            console.log('UserManagement: search triggered');
            this.nextRecordsUrl = '';
            this.allUsers = [];
            this.loadUsers();
        }
    }



    // Handle previous page navigation
    handlePreviousTrans() {
        if (this.currentPageTrans > 1) {
            this.currentPageTrans--;
            this.updateDisplayedUsers();

            // Add a slight delay to ensure the datatable has fully rendered
            setTimeout(() => {
                this.selectRowsBasedOnIds();
            }, 100);
        }
    }

    handleNextTrans() {
        const totalPages = Math.ceil(this.filteredUsersTrans.length / this.pageSizeTrans);

        if (this.currentPageTrans < totalPages) {
            this.currentPageTrans++;
            this.updateDisplayedUsers();

            // Add a slight delay to ensure the datatable has fully rendered
            setTimeout(() => {
                this.selectRowsBasedOnIds();
            }, 100);
        } else if (this.nextRecordsUrl) {
            // Load more data, then ensure selected rows are restored after data loads
            this.loadMoreUsers();

            // The loadMoreUsers method needs to call selectRowsBasedOnIds after completion
        }
    }

    selectRowsBasedOnIds() {
        const datatable = this.template.querySelector('lightning-datatable[key-field="username"][data-id="availableUsersTable"]');
        if (datatable) {
            // Find the usernames that should be selected on the current page
            const usernamesToSelect = this.displayedUsers
                .filter(user => this.selectedUserIds.has(user.username))
                .map(user => user.username);

            // Only update if there's a change needed
            if (usernamesToSelect.length > 0 || datatable.selectedRows.length > 0) {
                console.log('Setting selected rows to:', usernamesToSelect);
                datatable.selectedRows = usernamesToSelect;
            }
        }
    }

    get pageNumberUsers() {
        return this.currentPageTrans;
    }

    get totalPagesAvailable() {
        const totalPages = Math.ceil(this.filteredUsersTrans.length / this.pageSizeTrans);
        // If there's a nextRecordsUrl, there are more pages beyond what we can calculate
        return this.nextRecordsUrl ? totalPages + '+' : totalPages;
    }

    @track showSelectedUserTable = false

    handleRowSelectionTrans(event) {
        const selectedRows = event.detail.selectedRows;
        console.log('UserManagement: handleRowSelection with', selectedRows.length, 'rows');

        // Get usernames of all rows displayed on current page
        const currentPageUsernames = this.displayedUsers.map(user => user.username);

        // For each username on the current page, update its selection state
        currentPageUsernames.forEach(username => {
            const isSelected = selectedRows.some(row => row.username === username);
            if (isSelected) {
                this.selectedUserIds.add(username);
            } else {
                this.selectedUserIds.delete(username);
            }
        });

        if(this.selectedUserIds.size >= 1){
           this.showSelectedUserTable = true
        } else{
            this.showSelectedUserTable = false
        }

        // Update selection state in all collections
        this.updateSelectionStateTrans();

        // Update selected users list and refresh both tables
        this.updateSelectedUsersList();
        this.updateDisplayedSelectedUsers();
    }


    updateSelectionStateTrans() {
        // Update allUsers
        this.allUsers = this.allUsers.map(user => ({
            ...user,
            selected: this.selectedUserIds.has(user.username)
        }));

        // Update filteredUsersTrans
        this.filteredUsersTrans = this.filteredUsersTrans.map(user => ({
            ...user,
            selected: this.selectedUserIds.has(user.username)
        }));

        // Update displayedUsers
        this.displayedUsers = this.displayedUsers.map(user => ({
            ...user,
            selected: this.selectedUserIds.has(user.username)
        }));
    }

    updateSelectedUsersList() {
        // Create a new selectedUsers array with users whose usernames are in selectedUserIds
        this.selectedUsers = this.allUsers
            .filter(user => this.selectedUserIds.has(user.username))
            .map(user => ({ ...user, selected: true }));

        // Update the selected users table
        this.filterSelectedUsers();
        this.updateDisplayedSelectedUsers();

        // Ensure both tables are updated
        this.selectRowsBasedOnIds();
    }

    handleSelectedRowSelection(event) {
        const selectedRowsInTable = event.detail.selectedRows;

        // Get all usernames currently displayed in the selected table
        const displayedSelectedUsernames = this.displayedSelectedUsers.map(user => user.username);

        // Update selection state based on what's selected in the table
        displayedSelectedUsernames.forEach(username => {
            const isSelected = selectedRowsInTable.some(row => row.username === username);
            if (!isSelected) {
                // If deselected in the selected users table, remove from the main selection set
                this.selectedUserIds.delete(username);
            }
        });

        // Update selection state across all collections
        this.updateSelectionStateTrans();
        this.updateSelectedUsersList();
        this.updateDisplayedUsers();

        // Update main datatable
        this.selectRowsBasedOnIds();
    }
    // Update the selected users table
    updateSelectedUsersTable() {
        // Filter selected users based on search term
        this.filterSelectedUsers();

        // Reset to first page when the selection changes significantly
        this.selectedCurrentPage = 1;

        // Update the displayed selected users
        this.updateDisplayedSelectedUsers();
    }

    handleSortTrans(event) {
        const fieldName = event.detail.fieldName;
        const direction = event.detail.sortDirection; // ✅ Corrected key
        console.log('UserManagement: handleSort by', fieldName, 'in', direction, 'direction');
    
        this.sortedByTrans = fieldName;
        this.sortDirectionTrans = direction;
        this.sortDataTrans(this.sortedByTrans, this.sortDirectionTrans);
    }
    

    // Sort method for selected users table
    handleSortSelectedTrans(event) {
        const fieldName = event.detail.fieldName;
        const direction = event.detail.sortDirection;
        console.log('UserManagement: handleSortSelected by', fieldName, 'in', direction, 'direction');

        this.selectedSortedByTrans = fieldName;
        this.selectedSortDirectionTrans = direction;

        this.sortSelectedUsers(fieldName, direction);
        this.updateDisplayedSelectedUsers();
    }

    // Sort method for main users table
    sortDataTrans(fieldName, direction) {
        console.log('UserManagement: sortData by', fieldName, 'in', direction, 'direction');

        // Return the field value or empty string if field is undefined
        const parseField = (obj, field) => obj[field] ?
            (typeof obj[field] === 'string' ? obj[field].toLowerCase() : obj[field]) : '';

        // Sort the data
        let sortedData = [...this.filteredUsersTrans];

        sortedData.sort((a, b) => {
            let valueA = parseField(a, fieldName);
            let valueB = parseField(b, fieldName);

            return direction === 'asc' ?
                (valueA > valueB ? 1 : -1) :
                (valueA < valueB ? 1 : -1);
        });

        this.filteredUsersTrans = sortedData;
        console.log('UserManagement: filteredUsersTrans sorted');
        this.updateDisplayedUsers();
    }

    // Filter selected users based on search
    filterSelectedUsers() {
        console.log('UserManagement: filterSelectedUsers');

        if (!this.selectedUsers || this.selectedUsers.length === 0) {
            this.filteredSelectedUsers = [];
            this.displayedSelectedUsers = [];
            return;
        }

        // Apply search filter if search term exists
        if (this.selectedSearchTerm) {
            const searchTerm = this.selectedSearchTerm.toLowerCase();
            this.filteredSelectedUsers = this.selectedUsers.filter(user =>
                (user.name && user.name.toLowerCase().includes(searchTerm)) ||
                (user.email && user.email.toLowerCase().includes(searchTerm)) ||
                (user.username && user.username.toLowerCase().includes(searchTerm)) ||
                (user.profile && user.profile.toLowerCase().includes(searchTerm)) ||
                (user.isActive && user.isActive.toLowerCase().includes(searchTerm))
            );
        } else {
            this.filteredSelectedUsers = [...this.selectedUsers];
        }

        // Apply sort if needed
        this.sortSelectedUsers(this.selectedSortedByTrans, this.selectedSortDirectionTrans);

        // Update displayed users based on pagination
        this.updateDisplayedSelectedUsers();
    }

    // Sort selected users
    sortSelectedUsers(fieldName, direction) {
        // Copy the array to avoid modifying the original
        let sortedData = [...this.filteredSelectedUsers];

        // Parse field function to get value or empty string
        const parseField = (obj, field) => obj[field] ?
            (typeof obj[field] === 'string' ? obj[field].toLowerCase() : obj[field]) : '';

        // Sort the data
        sortedData.sort((a, b) => {
            let valueA = parseField(a, fieldName);
            let valueB = parseField(b, fieldName);

            return direction === 'asc' ?
                (valueA > valueB ? 1 : -1) :
                (valueA < valueB ? 1 : -1);
        });

        this.filteredSelectedUsers = sortedData;
    }

    // Update displayed selected users based on pagination
    updateDisplayedSelectedUsers() {
        console.log('UserManagement: updateDisplayedSelectedUsers');

        const startIndex = (this.selectedCurrentPage - 1) * this.selectedPageSizeTrans;
        const endIndex = Math.min(startIndex + this.selectedPageSizeTrans, this.filteredSelectedUsers.length);

        this.displayedSelectedUsers = this.filteredSelectedUsers.slice(startIndex, endIndex);
        console.log('UserManagement: displayedSelectedUsers count', this.displayedSelectedUsers.length);
    }

    // Handle search input for selected users
    handleSelectedSearch(event) {
        console.log('UserManagement: handleSelectedSearch', event.target.value);

        // Update search term
        this.selectedSearchTerm = event.target.value;

        // Reset to first page on search change
        this.selectedCurrentPage = 1;

        // Apply filtering and update display
        this.filterSelectedUsers();

        // Log to verify search is working
        console.log('UserManagement: selectedSearchTerm updated to', this.selectedSearchTerm);
        console.log('UserManagement: filteredSelectedUsers count after search', this.filteredSelectedUsers.length);
    }

    // Handle page size change for selected users
    handleSelectedPageSizeChange(event) {
        this.selectedPageSizeTrans = parseInt(event.target.value, 10);
        this.selectedCurrentPage = 1; // Reset to first page on page size change
        this.updateDisplayedSelectedUsers();
    }

    // Handle previous page navigation for selected users
    handleSelectedPreviousTrans() {
        if (this.selectedCurrentPage > 1) {
            this.selectedCurrentPage--;
            this.updateDisplayedSelectedUsers();
        }
    }

    // Handle next page navigation for selected users
    handleSelectedNextTrans() {
        if (this.selectedCurrentPage < this.totalSelectedPagesTrans) {
            this.selectedCurrentPage++;
            this.updateDisplayedSelectedUsers();
        }
    }

    // Add this helper method somewhere in your class
    isUserActive(user) {
        if (typeof user.isActive === 'boolean') {
            return user.isActive === true;
        } else if (typeof user.isActive === 'string') {
            return user.isActive === 'Yes' || user.isActive.toLowerCase() === 'true';
        }
        return false;
    }

    // You can also add this companion method for inactive checks
    isUserInactive(user) {
        if (typeof user.isActive === 'boolean') {
            return user.isActive === false;
        } else if (typeof user.isActive === 'string') {
            return user.isActive === 'No' || user.isActive.toLowerCase() === 'false';
        }
        return false;
    }

    handleResetPasswords() {
        console.log('UserManagement: handleResetPasswords');

        const selectedActiveUsers = this.selectedUsers.filter(user => this.isUserActive(user));
        console.log('UserManagement: selectedActiveUsers count', selectedActiveUsers.length);

        if (selectedActiveUsers.length === 0) {
            this.showToastMessage('No active users selected', 'error');
            return;
        }
        this.showResetPasswordsModal = true;


    }

    confirmResetPasswords() {
        // Close the modal
        this.closeResetPasswordsModal();

        this.userTransformationExecutionStartTime = new Date().toISOString();
        this.userPasswordResetSuccessToastShown = false;
        this.userPasswordResetFailedToastShown = false;
        this.showUserTransformRefreshIcon = true;

        // Extract selected active users
        const selectedActiveUsers = this.selectedUsers.filter(user => this.isUserActive(user));
        const userIds = selectedActiveUsers.map(user => user.id);

        // Show loading spinner
        this.isLoadingTrans = true;

        // Call the Apex method to execute batch job
        executeData({
            refTempId: this.recordId,
            userIds: userIds,
            emailList: null,
            logType: 'Reset User Password - Post Refresh'
        })
            .then(result => {
                this.showUserTransformRefreshIcon = true;
                this.showToastMessage('Password reset initiated for ' + selectedActiveUsers.length + ' users', 'success');
                console.log('UserManagement: passwordResetLog updated to', this.passwordResetLog);
                console.log('UserManagement: passwordResetStatus updated to', this.passwordResetStatus);

                // Clear selections after action completes
                this.clearSelections();
                this.reloadUsers('All Users');
                this.showSelectedUserTable = false;
            })
            .catch(error => {
                console.error('UserManagement: Error executing password reset:', error);
                this.passwordResetStatus = 'Failed';
                this.showToastMessage('Error resetting passwords: ' + (error.body ? error.body.message : error.message), 'error');
            })
            .finally(() => {
                this.isLoadingTrans = false;
            });
    }

    handleRemoveInvalid() {
        console.log('UserManagement: handleRemoveInvalid');

        const selectedUsers = this.selectedUsers;
        console.log('UserManagement: selectedUsers count', selectedUsers.length);

        if (selectedUsers.length === 0) {
            this.showToastMessage('No users selected', 'error');
            return;
        }
        this.showRemoveInvalidModal = true;


    }

    confirmRemoveInvalid() {
        // Close the modal
        this.closeRemoveInvalidModal();
        this.userTransformationExecutionStartTime = new Date().toISOString();
        this.userInvalidRemovalSuccessToastShown = false;
        this.userInvalidRemovalFailedToastShown = false;
        this.showUserTransformRefreshIcon = true;

        const selectedUsers = this.selectedUsers;

        // Extract email information
        const emailList = selectedUsers.map(user => {
            return {
                'userId': user.id,
                'email': user.email
            };
        });

        // Show loading spinner
        this.isLoadingTrans = true;

        // Call the Apex method to execute batch job
        executeData({
            refTempId: this.recordId,
            userIds: null, // Not needed for email validation
            emailList: emailList,
            logType: 'User Email Validation - Post Refresh'
        })
            .then(result => {
                this.showUserTransformRefreshIcon = true;
                this.showToastMessage('Invalid characters removal initiated for ' + selectedUsers.length + ' users', 'success');
                console.log('UserManagement: invalidRemovalLog updated to', this.invalidRemovalLog);
                console.log('UserManagement: invalidRemovalStatus updated to', this.invalidRemovalStatus);

                // Clear selections after action completes
                this.clearSelections();
                this.reloadUsers('All Users');
                this.showSelectedUserTable = false
            })
            .catch(error => {
                console.error('UserManagement: Error executing invalid removal:', error);
                this.invalidRemovalStatus = 'Failed';
                this.showToastMessage('Error removing invalid characters: ' + (error.body ? error.body.message : error.message), 'error');
            })
            .finally(() => {
                this.isLoadingTrans = false;
            });
    }


    handleActivate() {
        console.log('UserManagement: handleActivate');

        const selectedInactiveUsers = this.selectedUsers.filter(user => this.isUserInactive(user));
        console.log('UserManagement: selectedInactiveUsers count', selectedInactiveUsers.length);

        if (selectedInactiveUsers.length === 0) {
            this.showToastMessage('No inactive users selected', 'error');
            return;
        }
        this.showActivateModal = true;


    }

    confirmActivate() {
        // Close the modal
        this.closeActivateModal();

        this.userTransformationExecutionStartTime = new Date().toISOString();
        this.userActivationSuccessToastShown = false;
        this.userActivationFailedToastShown = false;
        this.showUserTransformRefreshIcon = true;

        const selectedInactiveUsers = this.selectedUsers.filter(user => this.isUserInactive(user));
        const userIds = selectedInactiveUsers.map(user => user.id);

        // Show loading spinner
        this.isLoadingTrans = true;

        // Call the Apex method to execute batch job
        executeData({
            refTempId: this.recordId,
            userIds: userIds,
            emailList: null, // Not needed for activation
            logType: 'User Activation - Post Refresh'
        })
            .then(result => {
                this.showUserTransformRefreshIcon = true;
                // Update logs
                this.showToastMessage('Activation initiated for ' + selectedInactiveUsers.length + ' users', 'success');

                console.log('UserManagement: activationLog updated to', this.activationLog);
                console.log('UserManagement: activationStatus updated to', this.activationStatus);

                // Update the user status in our local data
                this.updateUserStatus(selectedInactiveUsers, true);

                // Clear selections after action completes
                this.clearSelections();

                // Switch view to Active Users
                this.reloadUsers('All Users');
                this.showSelectedUserTable = false
            })
            .catch(error => {
                console.error('UserManagement: Error executing user activation:', error);
                this.activationStatus = 'Failed';
                this.showToastMessage('Error activating users: ' + (error.body ? error.body.message : error.message), 'error');
            })
            .finally(() => {
                this.isLoadingTrans = false;
            });
    }


    handleDeactivate() {
        console.log('UserManagement: handleDeactivate');

        const selectedActiveUsers = this.selectedUsers.filter(user => this.isUserActive(user));
        console.log('UserManagement: selectedActiveUsers count', selectedActiveUsers.length);

        if (selectedActiveUsers.length === 0) {
            this.showToastMessage('No active users selected', 'error');
            return;
        }

        this.showDeactivateModal = true;
    }

    confirmDeactivate() {
        // Close the modal
        this.closeDeactivateModal();

        this.userTransformationExecutionStartTime = new Date().toISOString();
        this.userDeactivationSuccessToastShown = false;
        this.userDeactivationFailedToastShown = false;
        this.showUserTransformRefreshIcon = true;


        const selectedActiveUsers = this.selectedUsers.filter(user => this.isUserActive(user));
        const userIds = selectedActiveUsers.map(user => user.id);

        // Show loading spinner
        this.isLoadingTrans = true;

        // Call the Apex method to execute batch job
        executeData({
            refTempId: this.recordId,
            userIds: userIds,
            emailList: null, // Not needed for deactivation
            logType: 'User Deactivation - Post Refresh'
        })
            .then(result => {
                this.showUserTransformRefreshIcon = true;
                // Update logs
                console.log('result of user trans --', result);
                this.showToastMessage('Deactivation initiated for ' + selectedActiveUsers.length + ' users', 'success');

                console.log('UserManagement: deactivationLog updated to', this.deactivationLog);
                console.log('UserManagement: deactivationStatus updated to', this.deactivationStatus);

                // Update the user status in our local data
                this.updateUserStatus(selectedActiveUsers, false);

                // Clear selections after action completes
                this.clearSelections();
               
                this.reloadUsers('All Users');
                this.showSelectedUserTable = false
            })
            .catch(error => {
                console.error('UserManagement: Error executing user deactivation:', error);
                this.deactivationStatus = 'Failed';
                this.showToastMessage('Error deactivating users: ' + (error.body ? error.body.message : error.message), 'error');
            })
            .finally(() => {
                this.isLoadingTrans = false;
            });
    }

    // Modal close handlers
    closeResetPasswordsModal() {
        this.showResetPasswordsModal = false;
    }

    closeRemoveInvalidModal() {
        this.showRemoveInvalidModal = false;
    }

    closeActivateModal() {
        this.showActivateModal = false;
    }

    closeDeactivateModal() {
        this.showDeactivateModal = false;
    }

    // Helper method to update user status
    updateUserStatus(usersToUpdate, newActiveStatus) {
        // Create a Set of usernames for quick lookup
        const usernamesToUpdate = new Set(usersToUpdate.map(user => user.username));

        // Boolean value for new status
        const isActive = Boolean(newActiveStatus);
        // String representation (for backwards compatibility)
        const statusString = isActive ? 'Yes' : 'No';

        // Update status in all user collections
        this.allUsers = this.allUsers.map(user => {
            if (usernamesToUpdate.has(user.username)) {
                return {
                    ...user,
                    isActive: isActive, // Store as boolean
                    active: isActive
                };
            }
            return user;
        });

        this.selectedUsers = this.selectedUsers.map(user => {
            if (usernamesToUpdate.has(user.username)) {
                return {
                    ...user,
                    isActive: isActive, // Store as boolean
                    active: isActive
                };
            }
            return user;
        });
    }

    clearSelections() {
        // Clear selected IDs
        this.selectedUserIds = new Set();

        // Clear selected users array
        this.selectedUsers = [];
        this.filteredSelectedUsers = [];
        this.displayedSelectedUsers = [];

        // Update selection state across all collections
        this.updateSelectionStateTrans();

        // Reset the selected users table
        this.selectedCurrentPage = 1;
        this.updateSelectedUsersTable();

        // Update displayed users to reflect selection changes
        this.updateDisplayedUsers();

        // Ensure the datatables reflect these changes
        setTimeout(() => {
            const mainDatatable = this.template.querySelector('lightning-datatable[key-field="username"][data-id="availableUsersTable"]');
            if (mainDatatable) {
                mainDatatable.selectedRows = [];
            }

            const selectedDatatable = this.template.querySelector('lightning-datatable[key-field="username"][data-id="selectedUsersTable"]');
            if (selectedDatatable) {
                selectedDatatable.selectedRows = [];
            }
        }, 10);

        // Clear selected search term
        this.selectedSearchTerm = '';
        const selectedSearchInput = this.template.querySelector('input[placeholder="Search Selected Users"]');
        if (selectedSearchInput) {
            selectedSearchInput.value = '';
        }
    }

    // Helper method to reload users with a specific view
    reloadUsers(newView) {
        this.currentView = newView;
        this.nextRecordsUrl = '';
        this.allUsers = [];
        this.loadUsers();
    }

    handleBackFromTrans() {
        this.currentvalue = '6';
        this.updateStepClasses(this.currentvalue);
        this.showUserTrans = false;
        this.showDataMaskingPage = true;
    }

    // Show toast message
  /*  showToastMessage(message, type) {
        console.log('UserManagement: showToastMessage', message, type);

        // For Lightning toast notification
        const event = new ShowToastEvent({
            title: type.charAt(0).toUpperCase() + type.slice(1),
            message: message,
            variant: type,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
        console.log('UserManagement: dispatched ShowToastEvent');

        // For in-component toast
        this.toastMessage = message;
        this.toastType = type;

        if (type === 'success') {
            this.toastClass = 'slds-notify slds-notify_toast slds-theme_success';
            this.toastIcon = 'utility:success';
        } else if (type === 'error') {
            this.toastClass = 'slds-notify slds-notify_toast slds-theme_error';
            this.toastIcon = 'utility:error';
        } else if (type === 'warning') {
            this.toastClass = 'slds-notify slds-notify_toast slds-theme_warning';
            this.toastIcon = 'utility:warning';
        } else {
            this.toastClass = 'slds-notify slds-notify_toast slds-theme_info';
            this.toastIcon = 'utility:info';
        }

        this.showToast = true;
        console.log('UserManagement: in-component toast displayed');

        // Auto-hide toast after 5 seconds
        setTimeout(() => {
            this.closeToast();
        }, 5000);
    }*/

    closeToast() {
        console.log('UserManagement: closeToast');
        this.showToast = false;
    }

    // Computed properties
    get hasUsers() {
        return this.displayedUsers && this.displayedUsers.length > 0;
    }

    get startRecord() {
        return this.filteredUsersTrans.length === 0 ? 0 : (this.currentPageTrans - 1) * this.pageSizeTrans + 1;
    }

    get endRecord() {
        return Math.min(this.currentPageTrans * this.pageSizeTrans, this.filteredUsersTrans.length);
    }

    get totalRecords() {
        return this.filteredUsersTrans.length;
    }

    get isPreviousDisabled() {
        return this.currentPageTrans <= 1;
    }

    get isNextUsersDisabled() {
        // Check if we're at the last page AND there's no nextRecordsUrl
        const totalPages = Math.ceil(this.filteredUsersTrans.length / this.pageSizeTrans);
        return this.currentPageTrans >= totalPages && !this.nextRecordsUrl;

    }

    // Replace your existing getter methods with these
    get isActivateDisabled() {
        // Check the permission condition (user doesn't have required permissions)
        const permissionCheck = !(this.hasAdvancePermissionSet || this.isSystemAdmin);

        // Combine with existing condition for user activity status
        return permissionCheck || !this.selectedUsers.some(user => this.isUserInactive(user));
    }

    get isDeactivateDisabled() {
        // Check the permission condition (user doesn't have required permissions)
        const permissionCheck = !(this.hasAdvancePermissionSet || this.isSystemAdmin);

        // Combine with existing condition for user activity status
        return permissionCheck || !this.selectedUsers.some(user => this.isUserActive(user));
    }

    get isNoActiveUserSelected() {
        // Check the permission condition (user doesn't have required permissions)
        const permissionCheck = !(this.hasAdvancePermissionSet || this.isSystemAdmin);

        // Combine with existing condition for user activity status
        return permissionCheck || !this.selectedUsers.some(user => this.isUserActive(user));
    }

    get isRemoveInvalidDisabled() {
        // Check the permission condition (user doesn't have required permissions)
        const permissionCheck = !(this.hasAdvancePermissionSet || this.isSystemAdmin);

        // Combine with existing condition for user activity status
        return permissionCheck || this.selectedUsers.length === 0;
    }
    // Selected Users tracking variables
    @track selectedUsers = [];
    @track filteredSelectedUsers = [];
    @track displayedSelectedUsers = [];

    // Selected Users pagination
    @track selectedPageSizeTrans = 10;
    @track selectedCurrentPage = 1;
    @track selectedPageSizeOptions = [5, 10, 25, 50, 100];
    @track selectedSearchTerm = '';


    /**
     * Filters and updates the displayed selected users based on search term
     */
    filterSelectedUsers() {
        console.log('UserManagement: filterSelectedUsers');

        if (!this.selectedUsers || this.selectedUsers.length === 0) {
            this.filteredSelectedUsers = [];
            this.displayedSelectedUsers = [];
            return;
        }

        // Apply search filter if search term exists
        if (this.selectedSearchTerm && this.selectedSearchTerm.trim() !== '') {
            const searchTerm = this.selectedSearchTerm.toLowerCase();
            console.log('UserManagement: filtering selected users with search term:', searchTerm);

            this.filteredSelectedUsers = this.selectedUsers.filter(user => {
                const nameMatch = user.name && user.name.toLowerCase().includes(searchTerm);
                const emailMatch = user.email && user.email.toLowerCase().includes(searchTerm);
                const usernameMatch = user.username && user.username.toLowerCase().includes(searchTerm);
                const profileMatch = user.profile && user.profile.toLowerCase().includes(searchTerm);
                const isActiveMatch = user.isActive && String(user.isActive).toLowerCase().includes(searchTerm);

                return nameMatch || emailMatch || usernameMatch || profileMatch || isActiveMatch;
            });

            console.log('UserManagement: found', this.filteredSelectedUsers.length, 'matching users');
        } else {
            console.log('UserManagement: no search term, showing all selected users');
            this.filteredSelectedUsers = [...this.selectedUsers];
        }

        // Apply sort if needed
        this.sortSelectedUsers(this.selectedSortedByTrans, this.selectedSortDirectionTrans);

        // Update displayed users based on pagination
        this.updateDisplayedSelectedUsers();
    }

    /**
     * Updates displayed selected users based on pagination
     */
    updateDisplayedSelectedUsers() {
        console.log('UserManagement: updateDisplayedSelectedUsers');

        const startIndex = (this.selectedCurrentPage - 1) * this.selectedPageSizeTrans;
        const endIndex = Math.min(startIndex + this.selectedPageSizeTrans, this.filteredSelectedUsers.length);

        this.displayedSelectedUsers = this.filteredSelectedUsers.slice(startIndex, endIndex);
        console.log('UserManagement: displayedSelectedUsers count', this.displayedSelectedUsers.length);
    }

    /**
     * Sorts the filtered selected users
     */
    sortSelectedUsers(fieldName, direction) {
        // Copy the array to avoid modifying the original
        let sortedData = [...this.filteredSelectedUsers];

        // Parse field function to get value or empty string
        const parseField = (obj, field) => obj[field] ?
            (typeof obj[field] === 'string' ? obj[field].toLowerCase() : obj[field]) : '';

        // Sort the data
        sortedData.sort((a, b) => {
            let valueA = parseField(a, fieldName);
            let valueB = parseField(b, fieldName);

            return direction === 'asc' ?
                (valueA > valueB ? 1 : -1) :
                (valueA < valueB ? 1 : -1);
        });

        this.filteredSelectedUsers = sortedData;
    }

    // Computed properties for pagination
    get totalSelectedRecords() {
        return this.filteredSelectedUsers ? this.filteredSelectedUsers.length : 0;
    }

    get totalSelectedPagesTrans() {
        return Math.ceil(this.totalSelectedRecords / this.selectedPageSizeTrans);
    }

    get selectedPaginationText() {
        return `Showing ${this.selectedCurrentPage} of ${this.totalSelectedPagesTrans} Page(s)`;
    }

    get isSelectedPreviousDisabled() {
        return this.selectedCurrentPage <= 1;
    }

    get isSelectedNextDisabled() {
        return this.selectedCurrentPage >= this.totalSelectedPagesTrans;
    }

    handlePageSizeChangeTrans(event) {
        const newSize = parseInt(event.target.value, 10);
        console.log('UserManagement: handlePageSizeChange from', this.pageSizeTrans, 'to', newSize);

        this.pageSizeTrans = newSize;
        this.currentPageTrans = 1;
        this.updateDisplayedUsers();
    }
    

    @track pageSizeOptionsTrans = [10, 25, 50, 100];

    get selectedUsernames() {
        return Array.from(this.selectedUserIds);
    }

    /*User end*/


    // Define permission flags
    hasAdvancePermissionSet = false;
    hasBasicPermissionSet = false; 
    isSystemAdmin = false;


    // Permissions check logic
    checkPermissions() {
        getAssignedPermissionSets()
            .then(result => {
                console.log('Permission sets fetched:', result); // Log the permission sets received

                if (result && result.length > 0) {
                    console.log('Permission sets fetched:', result);
                    // Check if 'Sandbox_Refresh_Admin' is present in the fetched permission sets
                    this.hasAdvancePermissionSet = result.some(permissionSet => permissionSet.Name === 'Sandbox_Refresh_Admin');
                    this.hasBasicPermissionSet = result.some(ps => ps.Name === 'Sandbox_Refresh_Basic');

                    console.log('Has Sandbox_Refresh_Admin permission set:', this.hasAdvancePermissionSet);

                    // Fetch the profile name
                    getProfileName()
                        .then(profileName => {
                            this.isSystemAdmin = profileName === 'System Administrator';
                            console.log('Profile name:', profileName); // Log the profile name
                            console.log('Is user a System Administrator?', this.isSystemAdmin); // Log the system admin status
                            //this.updateRetrieveDataButton();
                        })
                        .catch(error => {
                            console.error('Error fetching profile name', error);
                            //this.updateRetrieveDataButton();
                        });
                } else {
                    this.hasAdvancePermissionSet = false;
                    this.hasBasicPermissionSet = false;
                    this.isSystemAdmin = false;

                    console.log('No permission sets found for the user.');
                    //this.updateRetrieveDataButton();
                }
            })
            .catch(error => {
                console.error('Error fetching permission sets', error);
            });
    }

    closeAuthenticateWarning(){
        this.showAuthenticateWarning = false
    }

    closeRefreshStatusWarning(){
         this.showRefreshStatusWarning = false
    }
}