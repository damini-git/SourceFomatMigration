import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import fetchAllRefreshTemplates from '@salesforce/apex/PreRefreshAutomationClass.fetchAllRefreshTemplates';
import fetchAllOrgs from '@salesforce/apex/PreRefreshAutomationClass.fetchAllOrgs';
import fetchAllMetadataTypes from '@salesforce/apex/PreRefreshAutomationClass.fetchAllMetadataTypes';
import fetchAllMetadataComponents from '@salesforce/apex/PreRefreshAutomationClass.fetchAllMetadataComponents';
import deleteRecord from '@salesforce/apex/PreRefreshAutomationClass.deleteRecord';

import fetchAllUsers from '@salesforce/apex/DataPickerClass.fetchAllUsers';
import fetchCustomSettings from '@salesforce/apex/DataPickerClass.fetchCustomSettings';
import fetchScheduledJobs from '@salesforce/apex/DataPickerClass.fetchScheduledJobs1';

import getTemplateOrgName from '@salesforce/apex/PreRefreshAutomationClass.getTemplateOrgName';
import createNewTemplate from '@salesforce/apex/PreRefreshAutomationClass.createNewTemplate';
import checkOrgAuthenticated from '@salesforce/apex/PreRefreshAutomationClass.checkOrgAuthenticated';

import fetchRefreshTemplate from '@salesforce/apex/EditRefreshTemplateClass.fetchRefreshTemplate';
import getPackageContents from '@salesforce/apex/PackageXMLController.getPackageContents';
import fetchAllMetadataComponentsForEdit from '@salesforce/apex/EditRefreshTemplateClass.fetchAllMetadataComponentsForEdit';
import getMetadataMaskingRules from '@salesforce/apex/MetadataMaskingRulesController.getMetadataMaskingRules';
import readCSVFile from '@salesforce/apex/ScriptDataController.readCSVFile';
import readJSONFromRelatedFiles from '@salesforce/apex/JSONFileReader.readJSONFromRelatedFiles';
import fetchExistingCustomSettings from '@salesforce/apex/CSVFileReader.fetchCustomSettings';
import getScheduleJobCSVData from '@salesforce/apex/CSVFileReader.getScheduleJobCSVData';

import updateTemplate from '@salesforce/apex/EditRefreshTemplateClass.updateTemplate';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';


/*** refTempColumn is to display the Refresh Templates in the datatable on page load ***/
const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];

const refTempColumn = [
    {
        label: 'Template Name', fieldName: 'TemplateName',
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_self'
        }
    },
    { label: 'Source Org', fieldName: 'SourceOrg', sortable: true, },
    { label: 'Target Org', fieldName: 'TargetOrg', sortable: true, },
    { label: 'Status', fieldName: 'LastRunStatus', sortable: true, },
    { label: 'Last Refreshed Date', fieldName: 'LastRefreshedDate', sortable: true, },
    { label: 'Last Refreshed By', fieldName: 'LastRefreshedBy', sortable: true, },
    { label: 'Created Date', fieldName: 'CreatedDate', sortable: true, },
    { label: 'Modified Date', fieldName: 'ModifiedDate', sortable: true, },
    { type: 'action',
        typeAttributes: {
            rowActions: { fieldName: 'rowActions' }
        }
    }
];

/***  columnsForUserData is used to display the columns for the User Datatable in Data Picker ***/
const columnsForUserData = [
    // { label: 'S.No', fieldName: 'serialNumber', type: 'text', initialWidth: 80 },
    { label: 'Name', fieldName: 'Name', type: 'text', sortable: true },
    { label: 'Email', fieldName: 'Email', type: 'text', sortable: true },
    { label: 'Username', fieldName: 'Username', type: 'text', sortable: true },
    { label: 'Profile', fieldName: 'Profile', type: 'text', sortable: true }
];

/***  columnsForCustomSettings is used to display the columns for the Custom Settings Datatable in Data Picker ***/
const columnsForCustomSettings = [
    { label: 'Custom Settings', fieldName: 'customSettingName', type: 'text', sortable: true }
];

/***  columnsForScheduledJobs is used to display the columns for the Scheduled Jobs Datatable in Data Picker ***/
const columnsForScheduledJobs = [
    //{ label: 'CronJobDetailId', fieldName: 'cronJobDetailId', type: 'text', initialWidth: 100 },
    { label: 'Job Name', fieldName: 'jobName', type: 'text', sortable: true },
    { label: 'Job Type', fieldName: 'jobType', type: 'text', sortable: true },
    { label: 'Apex Class', fieldName: 'apexClassName', type: 'text', sortable: true },
    //{ label: 'State', fieldName: 'state', type: 'text', initialWidth: 100 },
    //{ label: 'Next Fire Time', fieldName: 'nextFireTime', type: 'text', initialWidth: 300 },
    //{ label: 'Start Time', fieldName: 'startTime', type: 'text', initialWidth: 250 },
    //{ label: 'End Time', fieldName: 'endTime', type: 'text', initialWidth: 400 },
    //{ label: 'Time Zone', fieldName: 'timeZoneSidKey', type: 'text', initialWidth: 200 },
    { label: 'Cron Expression', fieldName: 'cronExpression', type: 'text', sortable: true },
    //{ label: 'Times Triggered', fieldName: 'timesTriggered', type: 'number', initialWidth: 300 },
    //{ label: 'Previous Fire Time', fieldName: 'previousFireTime', type: 'text', initialWidth: 300 },
];


const metadataDatatableColumn = [
    { label: 'Metadata', fieldName: 'value', sortable: true, initialWidth: 200 },
    { label: 'Last Modified By', fieldName: 'lastModifiedBy', sortable: true },
    { label: 'Last Modified Date', fieldName: 'lastModifiedDate', sortable: true, type: 'date' },
    { label: 'Created By', fieldName: 'createdBy', sortable: true },
    { label: 'Created Date', fieldName: 'createdDate', sortable: true, type: 'date' },
];

const metadataDatatableColumnForEdit = [
    { label: 'Metadata', fieldName: 'value', sortable: true },
    { label: 'Type', fieldName: 'type', sortable: true },
];


const findAndReplaceColumns = [
    { label: 'Metadata Types', fieldName: 'metadataTypesForFindAndReplace', type: 'text', sortable: true },
    { label: 'Masking Type', fieldName: 'maskingType', type: 'text', sortable: true },
    { label: 'Search Key', fieldName: 'searchKey', type: 'text', sortable: true },
    { label: 'Replace Value', fieldName: 'replaceValue', type: 'text', sortable: true },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Delete', name: 'delete' }
            ]
        }
    }
];

const suffixColumns = [
    { label: 'Metadata Types', fieldName: 'metadataTypesForFindAndReplace', type: 'text', sortable: true },
    { label: 'Masking Type', fieldName: 'maskingType', type: 'text', sortable: true },
    { label: 'Suffix', fieldName: 'suffixValue', type: 'text', sortable: true },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Delete', name: 'delete' }
            ]
        }
    }
];


const selectedMetadataColumns = [
    { label: 'Name', fieldName: 'name', sortable: true },
    { label: 'Type', fieldName: 'type', sortable: true },
    { label: 'Last Modified By', fieldName: 'lastModifiedBy', sortable: true },
    { label: 'Last Modified Date', fieldName: 'lastModifiedDate', type: 'date', sortable: true },
    { label: 'Created By', fieldName: 'createdBy', sortable: true },
    { label: 'Created Date', fieldName: 'createdDate', type: 'date', sortable: true }
];

const searchColumnsForEdit = [
    { label: 'Metadata Type', fieldName: 'metadataType', type: 'text', sortable: true },
    { label: 'Masking Type', fieldName: 'maskingType', type: 'text', sortable: true },
    { label: 'Search Key', fieldName: 'searchKey', type: 'text', sortable: true },
    { label: 'Replace Value', fieldName: 'replaceValue', type: 'text', sortable: true },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Delete', name: 'deleteSearchRule' }
            ]
        }
    }
];


const suffixColumnsForEdit = [
    { label: 'Metadata Type', fieldName: 'metadataType', sortable: true },
    { label: 'Masking Type', fieldName: 'maskingType', sortable: true },
    { label: 'Suffix Value', fieldName: 'suffixValue', sortable: true },
    {
        type: 'action',
        typeAttributes: { rowActions: [ { label: 'Delete', name: 'delete_suffix' } ]}
    }
];

const columnsForUserDataForEdit = [
    // { label: 'S.No', fieldName: 'serialNumber', type: 'text', initialWidth: 80 },
    { label: 'Name', fieldName: 'Name', type: 'text', sortable: true },
    { label: 'Email', fieldName: 'Email', type: 'text', sortable: true },
    { label: 'Username', fieldName: 'Username', type: 'text', sortable: true },
    { label: 'Profile', fieldName: 'Profile', type: 'text', sortable: true }
];

const columnsForCustomSettingsForEdit = [
    { label: 'Custom Settings', fieldName: 'customSettingName', type: 'text', sortable: true }
];

const columnsForScheduledJobsForEdit = [
    { label: 'Job Name', fieldName: 'jobName', type: 'text', sortable: true },
    { label: 'Job Type', fieldName: 'jobType', type: 'text', sortable: true },
    { label: 'Apex Class', fieldName: 'apexClassName', type: 'text', sortable: true },
    { label: 'Cron Expression', fieldName: 'cronExpression', type: 'text', sortable: true }
];

const selectedMetadataColumnsForEdit = [
    { label: 'Name', fieldName: 'name', sortable: true },
    { label: 'Type', fieldName: 'type', sortable: true }
];

const findAndReplaceColumnsForEdit = [
    { label: 'Metadata Types', fieldName: 'metadataType', type: 'text', sortable: true },
    { label: 'Masking Type', fieldName: 'maskingType', type: 'text', sortable: true },
    { label: 'Search Key', fieldName: 'searchKey', type: 'text', sortable: true },
    { label: 'Replace Value', fieldName: 'replaceValue', type: 'text', sortable: true },
    
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Delete', name: 'delete' }
            ]
        }
    }
];

export default class PostRefreshAutomationNew extends NavigationMixin(LightningElement) {

    /****************** ON LOAD PAGE CODE BLOCK ******************/
    @track showOnPageLoad = true;
    @track pageSizeOptions = [10, 25, 50, 75, 100];
    @track pageSizeRef = 10;
    @track totalPagesRef = 1; //Total no.of pages
    @track pageNumberRef = 1; //Page number
    @track totalRecordsReF = 0;
    @track showSpinnerNavigation = false;

    @track totalRefTempRecords = [];

    @track selectedRows = [];
    @track selectedListView = 'All';
    @track listViewOptions = [
        { label: 'All', value: 'All' }
    ];

    @track searchTemplate = '';
    @track refTempplatesToDisplay = [];
    @track wiredTemplateResult;
    @track sortedByTemplate = '';
    @track sortDirectionTemplate = 'asc';
    @track selectedMetadataListToDisplay = [];
    @track selectedMetadataColumns = [];


    fieldLabels = {
        TemplateName: 'Template Name',
        SourceOrg: 'Source Org',
        TargetOrg: 'Target Org',
        LastRunStatus: 'Status',
        LastRefreshedDate: 'Last Refreshed Date',
        LastRefreshedBy: 'Last Refreshed By',
        CreatedDate: 'Created Date',
        ModifiedDate: 'Modified Date'
    };

    handleSortTemplates(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortedBy = fieldName;
        this.sortDirectionTemplate = sortDirection;

        // Always sort the filtered data
        let dataToSort = [...this.totalRefTempRecords];

        // Apply search filter first if there's a search term
        if (this.searchTerm) {
            const searchValue = this.searchTerm.toLowerCase().trim();
            dataToSort = dataToSort.filter(record => {
                const nameMatch = (record.Name || '').toLowerCase().includes(searchValue);
                const sourceMatch = (record.SourceOrg || '').toLowerCase().includes(searchValue);
                const targetMatch = (record.TargetOrg || '').toLowerCase().includes(searchValue);
                const statusMatch = (record.LastRunStatus || '').toLowerCase().includes(searchValue);
                return nameMatch || sourceMatch || targetMatch || statusMatch;
            });
        }

        // Sort the filtered data
        dataToSort.sort((a, b) => {
            let valueA, valueB;

            // Handle date fields
            const dateFields = ['LastRefreshedDate', 'CreatedDate', 'ModifiedDate'];
            if (dateFields.includes(fieldName)) {
                // Map field names to their corresponding data properties
                const fieldMapping = {
                    'LastRefreshedDate': 'Last_Refreshed_Date__c',
                    'CreatedDate': 'CreatedDate',
                    'ModifiedDate': 'LastModifiedDate'
                };

                const dataField = fieldMapping[fieldName];

                // Helper function to parse date string
                const parseDate = (dateStr) => {
                    if (!dateStr) return -Infinity;

                    try {
                        // Check if it's ISO format (contains 'T' and 'Z')
                        if (dateStr.includes('T') && dateStr.includes('Z')) {
                            const timestamp = new Date(dateStr).getTime();
                            return isNaN(timestamp) ? -Infinity : timestamp;
                        }

                        // Handle localized format (DD/MM/YYYY, HH:MM AM/PM)
                        const [datePart, timePart] = dateStr.split(', ');
                        if (!datePart || !timePart) return -Infinity;

                        const [day, month, year] = datePart.split('/');
                        const [time, period] = timePart.split(' ');
                        let [hours, minutes] = time.split(':');

                        // Convert to 24-hour format
                        hours = parseInt(hours);
                        if (period === 'PM' && hours !== 12) hours += 12;
                        if (period === 'AM' && hours === 12) hours = 0;

                        const timestamp = new Date(year, month - 1, day, hours, parseInt(minutes)).getTime();
                        return isNaN(timestamp) ? -Infinity : timestamp;
                    } catch (error) {
                        console.log('Error parsing date:', dateStr, error);
                        return -Infinity;
                    }
                };

                // Convert to timestamps for comparison
                valueA = parseDate(a[dataField]);
                valueB = parseDate(b[dataField]);

                // Handle sorting direction
                return sortDirection === 'asc' ? valueA - valueB : valueB - valueA;
            }

            // Handle template name field
            if (fieldName === 'TemplateName') {
                valueA = a.Name || '';
                valueB = b.Name || '';
            } else {
                // Handle all other fields
                valueA = a[fieldName] || '';
                valueB = b[fieldName] || '';
            }

            // Convert to lowercase for case-insensitive comparison
            valueA = valueA.toString().toLowerCase();
            valueB = valueB.toString().toLowerCase();

            return sortDirection === 'asc'
                ? valueA.localeCompare(valueB)
                : valueB.localeCompare(valueA);
        });

        // Update total records count without resetting page number
        this.totalRecordsReF = dataToSort.length;
        this.totalPagesRef = Math.ceil(this.totalRecordsReF / this.pageSizeRef) || 1;

        // Check if current page is now invalid after sorting
        if (this.pageNumberRef > this.totalPagesRef) {
            this.pageNumberRef = this.totalPagesRef;
        }

        // Calculate start and end indices based on current page
        const startIndex = (this.pageNumberRef - 1) * this.pageSizeRef;
        const endIndex = Math.min(startIndex + this.pageSizeRef, dataToSort.length);

        // Update the display with sorted and paginated data
        this.refTempplatesToDisplay = dataToSort.slice(startIndex, endIndex);
    }

    // Updated getter to show sort direction
    get sortedByColumnText() {
        if (!this.sortedBy) return '';
        const fieldLabel = this.fieldLabels[this.sortedBy] || this.sortedBy;
        const direction = this.sortDirectionTemplate === 'asc' ? '▲' : '▼';
        return `Sorted by ${fieldLabel} ${direction}`;
    }


    @track sortedByMetadata; // Current field to sort by
    @track sortDirectionMetada = 'asc'; // Current sort direction

    handleListViewChange(event) {
        this.selectedListView = event.detail.value;
        console.log('Selected List View:', this.selectedListView);
    }

    @track refTempColumn = [];
    @wire(fetchAllRefreshTemplates)
    wiredTemplates(result) {
        this.wiredTemplateResult = result;
        const { error, data } = result;

        if (data) {
            this.totalRefTempRecords = data.map((record) => {
                const LastRunStatus = record.Last_Run_Status__c;

                return {
                    ...record,
                    TemplateName: '/' + record.Id,
                    Name: record.Name,
                    SourceOrg: record.Source_Refresh_Org__c,
                    TargetOrg: record.Target_Refresh_Org__c,
                    LastRunStatus: LastRunStatus,
                    LastRefreshedDate: this.formatDate(record.Last_Refreshed_Date__c),
                    LastRefreshedBy: record.Last_Refreshed_By__r?.Name,
                    CreatedDate: this.formatDate(record.CreatedDate),
                    ModifiedDate: this.formatDate(record.LastModifiedDate),
                    rowActions: [
                        {
                            label: 'Edit',
                            name: 'edit',
                            disabled: LastRunStatus != null
                        },
                        {
                            label: 'Delete',
                            name: 'delete',
                            disabled: LastRunStatus != null
                        }
                    ]
                };
            });

            this.refTempplatesToDisplay = [...this.totalRefTempRecords];
            this.totalRecordsReF = data.length;
            this.pageSizeRef = this.pageSizeOptions[0];
            this.paginationHelper();
        }
        if (error) {
            console.error('Error fetching templates:', error);
            this.showToastMessage('Error', 'Failed to fetch templates', 'error');
        }
    }

    handleSearchTemplates(event) {
        this.searchTerm = event.target.value;

        // Only reset to first page when a new search term is entered
        // (Not when sorting with an existing search term)
        if (this.searchTerm && !this.previousSearchTerm) {
            this.pageNumberRef = 1;
        }
        this.previousSearchTerm = this.searchTerm;

        // If we have a current sort, reapply it with the search
        if (this.sortedBy) {
            this.handleSortTemplates({
                detail: {
                    fieldName: this.sortedBy,
                    sortDirection: this.sortDirectionTemplate
                }
            });
        } else {
            // If no sort is applied, just filter and paginate
            this.filterAndPaginate();
        }
    }

    filterAndPaginate() {
        let recordsToUse = [...this.totalRefTempRecords];

        // Apply search filter if there's a search term
        if (this.searchTerm) {
            const searchValue = this.searchTerm.toLowerCase().trim();
            recordsToUse = recordsToUse.filter(record => {
                const nameMatch = (record.Name || '').toLowerCase().includes(searchValue);
                const sourceMatch = (record.SourceOrg || '').toLowerCase().includes(searchValue);
                const targetMatch = (record.TargetOrg || '').toLowerCase().includes(searchValue);
                const statusMatch = (record.LastRunStatus || '').toLowerCase().includes(searchValue);
                return nameMatch || sourceMatch || targetMatch || statusMatch;
            });
        }

        // If there's an active sort, apply it
        if (this.sortedBy) {
            recordsToUse.sort((a, b) => {
                let valueA, valueB;

                // Handle date fields
                const dateFields = ['LastRefreshedDate', 'CreatedDate', 'ModifiedDate'];
                if (dateFields.includes(this.sortedBy)) {
                    // Map field names to their corresponding data properties
                    const fieldMapping = {
                        'LastRefreshedDate': 'Last_Refreshed_Date__c',
                        'CreatedDate': 'CreatedDate',
                        'ModifiedDate': 'LastModifiedDate'
                    };

                    const fieldName = fieldMapping[this.sortedBy];

                    // Helper function to parse date string
                    const parseDate = (dateStr) => {
                        if (!dateStr) return -Infinity;

                        try {
                            // Check if it's ISO format (contains 'T' and 'Z')
                            if (dateStr.includes('T') && dateStr.includes('Z')) {
                                const timestamp = new Date(dateStr).getTime();
                                return isNaN(timestamp) ? -Infinity : timestamp;
                            }

                            // Handle localized format (DD/MM/YYYY, HH:MM AM/PM)
                            const [datePart, timePart] = dateStr.split(', ');
                            if (!datePart || !timePart) return -Infinity;

                            const [day, month, year] = datePart.split('/');
                            const [time, period] = timePart.split(' ');
                            let [hours, minutes] = time.split(':');

                            // Convert to 24-hour format
                            hours = parseInt(hours);
                            if (period === 'PM' && hours !== 12) hours += 12;
                            if (period === 'AM' && hours === 12) hours = 0;

                            const timestamp = new Date(year, month - 1, day, hours, parseInt(minutes)).getTime();
                            return isNaN(timestamp) ? -Infinity : timestamp;
                        } catch (error) {
                            return -Infinity;
                        }
                    };

                    // Convert to timestamps for comparison
                    valueA = parseDate(a[fieldName]);
                    valueB = parseDate(b[fieldName]);

                    // Handle sorting direction
                    return this.sortDirectionTemplate === 'asc' ? valueA - valueB : valueB - valueA;
                }

                // Handle template name and other fields
                valueA = this.sortedBy === 'TemplateName' ? (a.Name || '') : (a[this.sortedBy] || '');
                valueB = this.sortedBy === 'TemplateName' ? (b.Name || '') : (b[this.sortedBy] || '');

                valueA = valueA.toString().toLowerCase();
                valueB = valueB.toString().toLowerCase();

                return this.sortDirectionTemplate === 'asc'
                    ? valueA.localeCompare(valueB)
                    : valueB.localeCompare(valueA);
            });
        }

        // Update total records and calculate pages
        this.totalRecordsReF = recordsToUse.length;
        this.totalPagesRef = Math.ceil(this.totalRecordsReF / this.pageSizeRef) || 1;

        // Ensure current page is valid
        if (this.pageNumberRef > this.totalPagesRef) {
            this.pageNumberRef = this.totalPagesRef;
        }

        // Calculate start and end indices for current page
        const startIndex = (this.pageNumberRef - 1) * this.pageSizeRef;
        const endIndex = Math.min(startIndex + this.pageSizeRef, recordsToUse.length);

        // Update displayed records
        this.refTempplatesToDisplay = recordsToUse.slice(startIndex, endIndex);
    }

    @track showSpinner = false;
    async handleRefreshTable() {
        this.showSpinner = true;

        try {
            await refreshApex(this.wiredTemplateResult);
            //window.location.reload();
            this.showToastMessage('Success', 'Table refreshed successfully', 'success');
        } catch (error) {
            console.error('Error refreshing table:', error);
            this.showToastMessage('Error', 'Failed to refresh the table', 'error');
        } finally {
            this.showSpinner = false;
        }
    }

    showToastMessage(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
     }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        /*return date.toLocaleString('en-US', {
            year: 'numeric',
            month: 'numeric',
            day: 'numeric',
            hour: 'numeric',
            minute: 'numeric',
            hour12: true
        });*/
        // Extract date components in dd/mm/yyyy format
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0'); // Month is 0-based, so add 1
        const year = date.getFullYear();

        // Extract time components
        const hours = date.getHours() % 12 || 12; // Convert 24-hour time to 12-hour format
        const minutes = String(date.getMinutes()).padStart(2, '0');
        const amPm = date.getHours() >= 12 ? 'PM' : 'AM';

        return `${day}/${month}/${year}, ${hours}:${minutes} ${amPm}`;
    }

    @track currentPageReference;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        this.currentPageReference = currentPageReference;
        console.log('currentPageReference --- ', currentPageReference);
        console.log('currentPageReference record id from refreshSandboxNew --- ', currentPageReference?.state?.c__recordId);
        if (currentPageReference?.state?.c__recordId != undefined) {
            this.templateRecordId = currentPageReference.state.c__recordId;
            console.log('recordId:', this.templateRecordId);
            this.showMetadataRetrievePageForEditTemplate = true;
            this.showOnPageLoad = false;
            this.isDataPickerForEdit = false;
            this.showFindAndReplacePageForEdit = false;
            this.showCreateTemplatePageForEdit = false;
            this.fetchRecordDetails(this.templateRecordId);
        }
        else{
            currentPageReference = null;
            this.templateRecordId = '';
            this.showMetadataRetrievePageForEditTemplate = false;
            this.showOnPageLoad = true;
            this.isMetadataPicker = false;
            this.isNewPage = false;

        }
    }

    @track templateRecordId;
    handleRefTempRow(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        this.templateRecordId = row.Id; // Assuming each record has an 'Id' field
        console.log('this.templateRecordId --- ' + this.templateRecordId)
        switch (actionName) {
            case 'edit':
              //  this.isNextButtonDisabledForEdit = true;
                this.fetchRecordDetails(this.templateRecordId);
                this.showMetadataRetrievePageForEditTemplate = true;
                this.showOnPageLoad = false;
                break;
            case 'delete':
                this.deleteRecord();
                break;
            default:
                break;
        }
    }

    deleteRecord() {
        // Display a confirmation dialog
        if (confirm('Are you sure you want to delete this record?')) {
            console.log('Delete confirmed');
            deleteRecord({ templateId: this.templateRecordId })
                .then(() => {
                    window.location.reload();
                })
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Record has been deleted',
                            variant: 'success'
                        })
                    );
                })
                .catch(error => {
                    this.error = error;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error deleting record',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
        } else {
            console.log('Delete cancelled');
            // Optionally handle the cancellation
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Cancelled',
                    message: 'Record deletion cancelled',
                    variant: 'info'
                })
            );
        }
    }

    @track isNewPage = false;
    handleNew() {
        this.showOnPageLoad = false;
        this.isNewPage = true;
    }

    handleRecordsPerPage(event) {
        this.pageSizeRef = parseInt(event.target.value, 10);
        this.pageNumberRef = 1;
        // Update total records based on whether we have a search or not
        this.totalRecordsReF = this.searchTerm ? this.refTempplatesToDisplay.length : this.totalRefTempRecords.length;
        this.filterAndPaginate();
    }

    previousPage() {
        if (this.pageNumberRef > 1) {
            this.pageNumberRef = this.pageNumberRef - 1;
            this.filterAndPaginate();
        }
    }

    nextPage() {
        if (this.pageNumberRef < this.totalPagesRef) {
            this.pageNumberRef = this.pageNumberRef + 1;
            this.filterAndPaginate();
        }
    }

    firstPage() {
        this.pageNumberRef = 1;
        this.filterAndPaginate();
    }

    lastPage() {
        this.pageNumberRef = this.totalPagesRef;
        this.filterAndPaginate();
    }

    // Update the disable getters to work with filtered results
    get bDisableFirst() {
        return this.pageNumberRef <= 1;
    }

    get bDisablePrevious() {
        return this.pageNumberRef <= 1;
    }

    get bDisableNext() {
        return this.pageNumberRef >= this.totalPagesRef;
    }

    get bDisableLast() {
        return this.pageNumberRef >= this.totalPagesRef;
    }

    paginationHelper() {
        // Store the current filtered records
        const currentRecords = [...this.refTempplatesToDisplay];

        // Reset the display array
        this.refTempplatesToDisplay = [];

        // Calculate total pages
        this.totalPagesRef = Math.ceil(this.totalRecordsReF / this.pageSizeRef);
        if (this.totalRecordsReF === 0) {
            this.totalPagesRef = 1;
        }

        // Adjust page number if needed
        if (this.pageNumberRef <= 1) {
            this.pageNumberRef = 1;
        } else if (this.pageNumberRef >= this.totalPagesRef) {
            this.pageNumberRef = this.totalPagesRef;
        }

        // Calculate start and end indices
        const startIndex = (this.pageNumberRef - 1) * this.pageSizeRef;
        const endIndex = Math.min(startIndex + this.pageSizeRef, this.totalRecordsReF);

        // Get records for current page
        for (let i = startIndex; i < endIndex; i++) {
            if (currentRecords[i]) {
                this.refTempplatesToDisplay.push(currentRecords[i]);
            }
        }

        this.refTempColumn = refTempColumn;
    }
    /****************** END OF ON LOAD PAGE CODE BLOCK ******************/


    /****************** NEW PAGE CODE BLOCK ******************/

    options = [
        { label: 'Create/Clone a Sandbox', value: 'existing' },
        { label: 'Refresh a Sandbox', value: 'create' }
    ];

    @track selectedOption;
    @track isExistingTemplate = false;

    handleOptionChange(event) {
        this.selectedOption = event.detail.value;
        if (this.selectedOption == 'existing') {
            this.isExistingTemplate = true;
        }
        else {
            this.isExistingTemplate = false;
        }
    }

    @track selectedTemplate;
    @track templateOrgName;
    @track templateOrgId;
    handleTemplates(event) {
        this.selectedTemplate = event.target.value;
        console.log('selectedTemplate --- ' + this.selectedTemplate);
        getTemplateOrgName({ selectedTemplate: this.selectedTemplate })
            .then(result => {
                this.templateOrgName = result.Name;
                this.templateOrgId = result.Id;
                console.log('templateOrgId --- ' + this.templateOrgId + ' --- templateOrgName --- ' + this.templateOrgName);
            }).catch(error => {
                console.log('error --- ' + JSON.stringify(error));
            });
    }

    @track showBackConfirmationModal = false;
    handleBackFromNewPage() {
        // Check if any data is selected that needs confirmation
        const hasSelectedData = this.checkForSelectedData();

        // Reset any lingering spinner states
        this.showSpinnerNavigation = false;
        this.showSpinner = false;

        if (hasSelectedData) {
            // Show confirmation modal if data is selected
            this.showBackConfirmationModal = true;
        } else {
            // If no data is selected, simply go back without showing modal
            this.handleDirectBack();
        }
    }

    clearApexScriptData() {
        this.newScriptOrder = '';
        this.newScriptName = '';
        this.newScriptDetails = '';
        this.originalScripts = [];
        this.scripts = [];
        this.searchTermapexScript = '';
        this.showapexScript = false;
        this.currentPageApex = 1;
        this.validationWarnings = [];
        this.showValidationWarnings = false;

        // Reset pagination for Apex scripts
        this.pageSizeApex = 5;
        this.selectedCurrentPageApexscript = 1;
        this.totalSelectedPagesApexscript = 1;
        this.totalRecordsApexscript = 0;

        console.log('Apex Script data cleared');
    }

    checkForSelectedData() {
        // Check metadata selections
        const hasMetadataSelections = Object.keys(this.selectedMetadataMap || {}).length > 0;

        // Check Users data - using selectedUserMap which contains actual selections
        const hasUsersData = Object.keys(this.selectedUserMap || {}).length > 0;

        // Check Custom Settings - using customSettingsSelectedRows Set
        const hasCustomSettings = this.customSettingsSelectedRows?.size > 0;

        // Check Scheduled Jobs - using selectedRows Set
        const hasScheduledJobs = this.selectedRows?.size > 0;

        // Check for active values in Search & Replace form
        const hasActiveSearchAndReplace =
            (this.selectedMaskingType === 'Search & Replace' &&
                (this.selectedMetadataTypesForSearch?.length > 0 ||
                    this.searchKey ||
                    this.replaceValue));

        // Check for active values in Suffix form
        const hasActiveSuffix =
            (this.selectedMaskingType === 'Suffix' &&
                (this.selectedMetadataTypesForSuffix?.length > 0 ||
                    this.suffixValue));

        // Check for active values in Apex Script form
        const hasActiveApexScript =
            (this.selectedMaskingType === 'Apex Script' &&
                (this.newScriptOrder ||
                    this.newScriptName ||
                    this.newScriptDetails));
        // Check for saved scripts
        const hasScripts = this.originalScripts?.length > 0;

        // Check for saved Find and Replace rules
        const hasFindReplaceRules = this.findAndReplaceRulesForBackend?.some(rule =>
            rule.maskingType === 'Search & Replace');

        // Check for saved Suffix rules
        const hasSuffixRules = this.findAndReplaceRulesForBackend?.some(rule =>
            rule.maskingType === 'Suffix');

        // Log selections for debugging
        console.log('Selection Status:', {
            metadata: hasMetadataSelections,
            users: hasUsersData,
            customSettings: hasCustomSettings,
            scheduledJobs: hasScheduledJobs,
            activeSearchAndReplace: hasActiveSearchAndReplace,
            activeSuffix: hasActiveSuffix,
            activeApexScript: hasActiveApexScript,
            savedFindReplace: hasFindReplaceRules,
            savedSuffix: hasSuffixRules,
            savedScripts: hasScripts
        });

        // Return true if any of the conditions are met
        return (
            hasMetadataSelections ||
            hasUsersData ||
            hasCustomSettings ||
            hasScheduledJobs ||
            hasActiveSearchAndReplace ||
            hasActiveSuffix ||
            hasActiveApexScript ||
            hasFindReplaceRules ||
            hasSuffixRules ||
            hasScripts
        );
    }


    handleDirectBack() {
        // Navigate back without clearing data
        this.isNewPage = false;
        this.showOnPageLoad = true;
        this.templateName = '';
        this.selectedOrg = '';
        this.selectedOrgName = '';
        this.selectedMaskingType = '';
        this.findAndReplaceRules = [];
        this.selectedOption = '';
        this.selectedMetadata = '';
        this.metadataToDisplayInDatatable = [];
        this.selectedMetadataListToDisplay = [];
        this.metadataOptions = [];

        // Clear Users data
        this.selectedUsers = [];
        this.userDataforDatatable = [];
        this.selectedUserMap = {};
        this.selectedUsernames = [];

        // Clear Custom Settings
        this.selectedCustomSettings = [];
        this.customSettingsDataforDatatable = [];
        this.customSettingsSelectedRows = new Set();

        // Clear Scheduled Jobs
        this.selectedScheduledJobs = [];
        this.scheduledJobsDataforDatatable = [];
        this.selectedRows = new Set();

        // Clear Find and Replace rules
        this.findAndReplaceRules = [];
        this.findAndReplaceRulesForBackend = [];
        this.selectedMaskingType = '';
        this.previousSelectedMaskingType = '';
        this.selectedMetadataTypesForSearch = [];
        this.selectedMetadataTypesForSuffix = [];
        this.searchKey = '';
        this.replaceValue = '';
        this.suffixValue = '';
        this.newScriptOrder = '';
        this.newScriptName = '';
        this.newScriptDetails = '';
        this.hasSelectedMetadataTypesSearch = false;
        this.hasSelectedMetadataTypesSuffix = false;
        this.showSearchAndReplace = false;
        this.showSuffix = false;
        this.showapexScript = false;

        // Clear other related properties
        this.selectedOption = '';
        this.selectedTemplate = '';
        this.templateName = '';
        this.selectedOrg = '';
        this.selectedOrgName = '';
        this.showMetadataDatatable = false;
        this.showUsersDatatable = false;
        this.showCustomSettingsDatatable = false;
        this.showScheduledJobsDatatable = false;
        this.showPackageXml = false;
        this.resetPaginationAndSearch();
        this.clearAllData();
        this.isNewPage = false;
        this.showOnPageLoad = true;
        this.selectedMaskingType = '';
        this.previousSelectedMaskingType = '';
        this.findAndReplaceRules = [];
        this.findAndReplaceRulesForBackend = [];
        this.showSearchAndReplace = false;
        this.showFindAndReplacePage = false;
        this.showSuffix = false;
        this.resetPaginationAndSearch();
        this.clearApexScriptData();
    }

    handleBackConfirmation(event) {
        if (event.detail) {
            // Clear all data and go back
            this.clearAllData();
            this.isNewPage = false;
            this.showOnPageLoad = true;
        }
        this.showBackConfirmationModal = false;
    }

    clearAllData() {
        // Clear metadata selections
        this.selectedMetadata = '';
        this.metadataToDisplayInDatatable = [];
        this.selectedMetadataListToDisplay = [];
        this.metadataOptions = [];

        // Clear Users data
        this.selectedUsers = [];
        this.userDataforDatatable = [];
        this.selectedUserMap = {};
        this.selectedUsernames = [];

        // Clear Custom Settings
        this.selectedCustomSettings = [];
        this.customSettingsDataforDatatable = [];
        this.customSettingsSelectedRows = new Set();

        // Clear Scheduled Jobs
        this.selectedScheduledJobs = [];
        this.scheduledJobsDataforDatatable = [];
        this.selectedRows = new Set();

        // Clear Find and Replace rules
        this.findAndReplaceRules = [];
        this.findAndReplaceRulesForBackend = [];

        // Clear other related properties
        this.selectedOption = '';
        this.selectedTemplate = '';
        this.templateName = '';
        this.selectedOrg = '';
        this.selectedOrgName = '';
        this.showMetadataDatatable = false;
        this.showUsersDatatable = false;
        this.showCustomSettingsDatatable = false;
        this.showScheduledJobsDatatable = false;
        this.showPackageXml = false;
        this.selectedMaskingType = '';
        this.previousSelectedMaskingType = '';
        this.findAndReplaceRules = [];
        this.findAndReplaceRulesForBackend = [];
        this.showSearchAndReplace = false;
        this.showSuffix = false;

        // Reset pagination and search states
        this.resetPaginationAndSearch();
        this.clearApexScriptData();

        this.selectedMaskingType = '';
        this.previousSelectedMaskingType = '';
        this.selectedMetadataTypesForSearch = [];
        this.selectedMetadataTypesForSuffix = [];
        this.hasSelectedMetadataTypesSearch = false;
        this.hasSelectedMetadataTypesSuffix = false;
        this.searchKey = '';
        this.replaceValue = '';
        this.suffixValue = '';
        this.newScriptOrder = '';
        this.newScriptName = '';
        this.newScriptDetails = '';
        this.showSearchAndReplace = false;
        this.showSuffix = false;
        this.showapexScript = false;

        // Clear Find and Replace rules
        this.findAndReplaceRules = [];
        this.findAndReplaceRulesForBackend = [];
        this.paginatedSearchAndReplaceData = [];
        this.paginatedSuffixData = [];
    }

    resetPaginationAndSearch() {
        // Reset pagination for all datatables
        this.selectedCurrentPage = 1;
        this.selectedTotalPages = 1;
        this.pageNumberUsers = 1;
        this.currentPageAvailCS = 1;
        this.currentPageSJ = 1;
        this.pageNumberRef = 1;
        this.pageSizeRef = this.pageSizeOptions[0]; // Reset to default (usually 10)

        // Recalculate pagination with new page size
        if (this.totalRefTempRecords) {
            this.totalPagesRef = Math.ceil(this.totalRecordsReF / this.pageSizeRef) || 1;
            this.filterAndPaginate(); // This will apply the new page size
        }

        // Reset search terms
        this.searchTerm = '';
        this.selectedTableSearchTermUSER = '';
        this.searchTermavailCus = '';
        this.searchTermSJ = '';
        this.searchTermRules = '';
        this.searchTermSuffix = '';

        // Reset other navigation states
        this.activeSectionsData = [];
        this.showSpinnerInsideAccordionsData = false;
    }

    /*  handleBackFromNewPage() {
          this.showBackConfirmationModal = true;
      }*/

    handleBackCancellation() {
        this.showBackConfirmationModal = false;
    }

    @track isMetadataPicker = false;
    @track isMetadataPickerForExisting = false;

    handleNextFromNewPage() {
        this.showOnPageLoad = false;
        this.isNewPage = false;

        if (this.isExistingTemplate) {
            const dispEvent = new ShowToastEvent({
                title: '',
                message: 'Work is still in progress for this option, please wait for the next release...',
                variant: 'error'
            });
            this.dispatchEvent(dispEvent);
            this.isNewPage = true;
            /*if (this.selectedTemplate != null) {
                this.isMetadataPickerForExisting = true;
                this.parseXmlOfSelectedTemplate(this.selectedTemplate);
            }
            else {
                const dispEvent = new ShowToastEvent({
                    title: '',
                    message: 'Please select a template',
                    variant: 'error'
                });
                this.dispatchEvent(dispEvent);
                this.isNewPage = true;
            }*/
        }
        else if (this.selectedOption == 'create') {
            this.isMetadataPicker = true;
        }
        else {
            const dispEvent = new ShowToastEvent({
                title: '',
                message: 'Please select an option',
                variant: 'error'
            });
            this.dispatchEvent(dispEvent);
            this.isNewPage = true;
        }

    }
    /****************** END OF NEW PAGE CODE BLOCK ******************/


    /****************** METADATA PICKER CODE BLOCK FOR CREATE NEW TEMPLATE ******************/

    @track packageXml;
    @track showPackageXml = false;
    @track allSelectedMetadataRows = new Set();
    @track selectedMetadataMap = new Map();

    @track showSpinnerInsideAccordions = false;
    @track showSpinnerInsideAccordionsData = false;

    handleBack() {
        this.showOnPageLoad = false;
        this.isNewPage = true;
        this.isMetadataPicker = false;
        this.isDataPicker = false;

        this.packageXml = '';
        this.showPackageXml = false;
        this.isPackageGenerated = true;
    }

    @track isDataPicker = false;
    async handleNextFromMetadataPicker() {
        this.searchTerm = '';
        this.selectedTableSearchTermUSER = '';
        //this.filterLetter = '';
        //this.activeLetter = '';

        // Custom Settings section
        this.searchTermavailCus = '';
        this.searchTermselCus = '';

        // Scheduled Jobs section
        this.searchTermSJ = '';
        this.searchTermSelectedSJ = '';

        // Reset page sizes to default for all sections
        // Users section
        this.selectedTablePageSize = 10;

        // Custom Settings section
        this.pageSizeCS = 5;
        this.selectedPageSizeCS = 5;

        // Scheduled Jobs section
        this.pageSizeSJ = 5;
        this.selectedPageSizeSJ = 5;

        // Reset table data to reflect cleared search terms
        if (this.selectedData === 'Users') {
            this.filteredData = [...this.userDataforDatatable];
            this.refreshSelectedTableData();
        } else if (this.selectedData === 'Custom Settings') {
            this.updateSelectedCustomSettingsData();
            this.updatePreselectedRowsForCS();
        } else if (this.selectedData === 'Scheduled Jobs') {
            this.updateSelectedJobsData();
            this.updatePreselectedRows();
        }
        // this.showFindAndReplacePage = true;
        //this.isDataPicker = false;
        //this.isMetadataPicker = false;
        console.log('handleNextFromDataPicker -> 1 - this.findAndReplaceRulesForBackend:', JSON.stringify(this.findAndReplaceRulesForBackend));
        console.log('Navigating to Find and Replace -> Backend Rules:', JSON.stringify(this.findAndReplaceRulesForBackend));
        if (this.findAndReplaceRulesForBackend.length > 0) {
            this.findAndReplaceRules = this.findAndReplaceRulesForBackend.filter(
                rule => rule.maskingType === this.selectedMaskingType
            );
            console.log('Loaded Rules for Current Masking Type:', JSON.stringify(this.findAndReplaceRules));
        }

        if (this.selectedOrg == null || this.selectedOrg == '') {
            this.dispatchEvent(new ShowToastEvent({
                title: '',
                message: 'Please select org',
                variant: 'error'
            }));
            return;
        }

        const hasPreselectedData = (
            (this.selectedData === 'Users' && this.userDataforDatatable.length > 0) ||
            (this.selectedData === 'Custom Settings' && this.customSettingsDataforDatatable.length > 0) ||
            (this.selectedData === 'Scheduled Jobs' && this.scheduledJobsDataforDatatable.length > 0)
        );

        if (hasPreselectedData) {
            console.log('Preselected data found. Showing spinner...');
            this.showSpinnerNavigation = true;
            await Promise.resolve(); // Force UI update
        }

        setTimeout(async () => {
            this.showOnPageLoad = false;
            this.isMetadataPicker = false;
            this.showFindAndReplacePage = true;

            if (this.selectedData === 'Users' && this.userDataforDatatable.length > 0) {
                this.showUsersDatatable = true;
            } else if (this.selectedData === 'Custom Settings' && this.customSettingsDataforDatatable.length > 0) {
                this.showCustomSettingsDatatable = true;
            } else if (this.selectedData === 'Scheduled Jobs' && this.scheduledJobsDataforDatatable.length > 0) {
                this.showScheduledJobsDatatable = true;
            }

            if (this.selectedMetadataListToDisplay.length !== 0) {
                console.log('--- go to generate package xml ---');
                this.generatePackageXml();
            }


            this.showSpinnerNavigation = false;
            console.log('Spinner disabled after transition.');
            // Keep spinner for longer to ensure visibility
        }, 100);
    }

    @track selectedOrg = '';
    @track selectedOrgName = '';
    @track orgOptions = [];
    @track domainUrl; // To store the Domain_URL__c field value
    @track errorMessage;

    // Fetch the Domain_URL__c value whenever the selectedOrg changes
    @wire(fetchAllOrgs)
    orgResult({ error, data }) {
        if (data) {
            console.log('data --- ' + JSON.stringify(data));
            this.orgOptions = data.map(item => {
                return { label: item.Name, value: item.Id };
            });
        }
        if (error) {
            console.log('error -- ' + JSON.stringify(error));
        }
    }

    @track recordUrl;
    @track showSpinnerForLoadingMetadataType = false;
    @track isNextButtonDisabled = false;
    handleOrgSelection(event) {
        // Basic org selection
        this.selectedOrg = event.detail.value;
        const selectedOption = this.orgOptions.find(option => option.value === this.selectedOrg);
        this.selectedOrgName = selectedOption ? selectedOption.label : '';
        this.updateRecordUrl();

        // Reset metadata-related properties
        this.metadataOptions = [];
        this.metadataToDisplayInDatatable = [];
        this.selectedMetadata = '';
        this.showMetadataDatatable = false;
        this.selectedMetadataListToDisplay = [];
        this.filteredMetadata = [];
        this.paginatedMetadata = [];
        this.currentPage = 1;
        this.totalPages = 1;
        this.selectedMetadataRows = {};
        this.selectedMetadataMap = new Map();
        this.preselectedRows = [];
        this.allSelectedMetadataRows = new Set();
        this.selectedCurrentPage = 1;
        this.selectedTotalPages = 1;
        this.paginatedSelectedMetadata = [];

        // Reset Users-related properties
        this.selectedUserMap = {};
        this.selectedUsers = [];
        this.selectedUsernames = [];
        this.preselectedUsernames = [];
        this.filteredData = [];
        this.userDataforDatatable = [];
        this.pageNumberUsers = 1;
        this.searchTerm = '';
        this.selectedTablePage = 1;
        this.selectedTablePageSize = 10;
        this.selectedTableSearchTermUSER = '';
        this.totalSelectedRecords = 0;
        this.nextRecordsUrl = '';
        this.oldNextRecordsUrl = '';
        this.selectedTableRows = [];
        this.activeLetter = '';
        this.filterLetter = '';
        this.showUsersDatatable = false;
        this.isUsersSelected = false;
        this.isSelectedUserEmpty = true;

        // Reset Custom Settings-related properties
        this.customSettingsDataforDatatable = [];
        this.currentPageAvailCS = 1;
        this.pageSizeCS = 5;
        this.searchTermavailCus = '';
        this.sortedByAvCS = 'customSettingName';
        this.sortedDirectionAvCS = 'asc';
        this.customSettingsSelectedRows = new Set();
        this.selectedCustomSettings = [];
        this.preselectedCS = [];
        this.selectedcustomSelectedRows = [];
        this.isSelectedCustomSettingsEmpty = true;
        this.showCustomSettingsDatatable = false;
        this.isCustomSettingsSelected = false;

        // Reset Scheduled Jobs-related properties
        this.scheduledJobsDataforDatatable = [];
        this.currentPageSJ = 1;
        this.pageSizeSJ = 5;
        this.searchTermSJ = '';
        this.sortBySJ = undefined;
        this.sortDirectionSJ = 'asc';
        this.selectedCurrentPageSJ = 1;
        this.selectedPageSizeSJ = 5;
        this.searchTermSelectedSJ = '';
        this.selectedScheduledJobs = [];
        this.preselectedSJ = [];
        this.selectedRows = new Set();
        this.scheduleSelectedRows = new Set();
        this.selectedJobsTableData = [];
        this.selectedTablePreselectedRows = [];
        this.showScheduledJobsDatatable = false;
        this.isScheduledJobsSelected = false;
        this.isSelectedScheduledJobsEmpty = true;

        // Reset common properties
        this.selectedData = '';
        this.showSpinnerInsideAccordionsData = false;
        this.activeSectionsData = [];

        //Reset template name
        this.templateName = '';

        // Reset package XML related data
        this.packageXml = '';
        this.showPackageXml = false;
        this.metadataPackageXmlContent = '';

        // Check org authentication and fetch metadata
        if (this.selectedOrg) {
            checkOrgAuthenticated({ orgId: this.selectedOrg })
                .then((isAuthenticated) => {
                    if (!isAuthenticated) {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Authentication Required',
                            message: 'The org selected is not authenticated. Please authenticate it.',
                            variant: 'error'
                        }));
                        this.isOrgNotSelectedYet = true;
                        this.isNextButtonDisabled = true;
                        this.showSpinnerForLoadingMetadataType = false;
                    } else {
                        console.log('If Authenticate ='+this.isOrgNotSelectedYet);
                        this.isOrgNotSelectedYet = false;
                        this.isNextButtonDisabled = false;
                        this.fetchAllMetadataTypes(this.selectedOrg);
                        this.showSpinnerForLoadingMetadataType = true;
                    }
                })
                .catch(error => {
                    console.error('Error checking authentication:', error);
                    this.isOrgNotSelectedYet = true;
                    this.isNextButtonDisabled = true;
                });
        }

        
        this.selectedMaskingType = '';
        this.findAndReplaceRules = [];
        this.findAndReplaceRulesForBackend = [];
        this.previousSelectedMaskingType = '';
        this.selectedMetadataTypesForSearch = [];
        this.selectedMetadataTypesForSuffix = [];
        this.searchKey = '';
        this.replaceValue = '';
        this.suffixValue = '';
        this.newScriptOrder = '';
        this.newScriptName = '';
        this.newScriptDetails = '';
        this.hasSelectedMetadataTypesSearch = false;
        this.hasSelectedMetadataTypesSuffix = false;
        this.showSearchAndReplace = false;
        this.showSuffix = false;
        this.showapexScript = false;
        this.clearApexScriptData();
    }

    // Generate the record detail URL
    updateRecordUrl() {
        if (this.selectedOrg) {
            this.recordUrl = `/lightning/r/Org__c/${this.selectedOrg}/view`;
        } else {
            this.recordUrl = null; // Handle null case if necessary
        }
    }

    @track metadataOptions = [];
    fetchAllMetadataTypes(selectedOrg) {
        this.showSpinnerForLoadingMetadataType = true;
        console.log('selectedOrg --- ' + selectedOrg);
        fetchAllMetadataTypes({ sandboxId: selectedOrg })
            .then(result => {
                //console.log('result --- ' + result);
                this.showSpinnerForLoadingMetadataType = false;
                this.isOrgNotSelectedYet = false;
                this.metadataOptions = result.map(option => {
                    return { label: option, value: option };
                });
                this.isNextButtonDisabledForEdit = false;
            })
            .catch(error => {
                console.log('error -- ' + JSON.stringify(error));
            });
    }

    @track selectedMetadata = '';
    @track isOrgNotSelectedYet = true;
    @track showMetadataDatatable = false;
    @track metadataDatatableColumn = [];


    @track filteredMetadata = [];
    handleMetadataSelection(event) {
        this.selectedMetadata = event.target.value;
        console.log('Selected Metadata --- ', this.selectedMetadata);

        // Reset state
        this.showSpinnerInsideMetadataBox = true;
        this.showMetadataDatatable = false;
        this.metadata = [];
        this.metadataToDisplayInDatatable = [];
        this.filteredMetadata = [];

        // Fetch metadata components
        this.fetchAllMetadataComponents(this.selectedMetadata);

        // Set the showSelectedMD to true if there are already selected metadata items
        this.updatePaginatedSelectedMetadata();

        // Wait for the DOM to update and then open the accordion section
        setTimeout(() => {
            const accordion = this.template.querySelector('lightning-accordion');
            if (accordion) {
                accordion.activeSectionName = ['Metadata']; // Use array for multiple sections
                console.log('Setting active section to: Metadata');
            } else {
                console.log('Accordion element not found');
            }
        }, 100); // Increased timeout to ensure DOM is updated
    }

    @track searchKeySMD = '';
    @track showSpinnerInsideMetadataBox = false;
    @track preselectedRows = [];
    @track metadata = [];
    fetchAllMetadataComponents(selectedMetadata) {
        this.showSpinnerInsideMetadataBox = true;
        this.showMetadataDatatable = false;
        fetchAllMetadataComponents({ sandboxId: this.selectedOrg, selectedMetadataType: selectedMetadata })
            .then(result => {
                console.log('result -- ' + JSON.stringify(result));
                this.showSpinnerInsideMetadataBox = false;

                if (result && result.length > 0) {

                    this.showMetadataDatatable = true;
                    this.metadata = result;
                    this.metadataToDisplayInDatatable = result.map(item => ({
                        value: item.value,
                        type: item.type,
                        lastModifiedBy: item.lastModifiedBy,
                        lastModifiedDate: item.lastModifiedDate,
                        createdBy: item.createdBy,
                        createdDate: item.createdDate
                    }));

                    this.metadataToDisplayInDatatable.sort((a, b) => {
                        const aValue = (a.value || '').toLowerCase();
                        const bValue = (b.value || '').toLowerCase();
                        return aValue.localeCompare(bValue);
                    });

                    this.sortedByMetadata = '';
                    this.sortDirectionMetada = 'asc';
                    this.metadataDatatableColumn = metadataDatatableColumn;

                    this.filteredMetadata = [...this.metadataToDisplayInDatatable];
                    this.totalPages = Math.ceil(this.filteredMetadata.length / this.pageSizeMetadata);
                    this.currentPage = 1;
                    this.updatePaginatedMetadata();
                    this.updatePaginatedSelectedMetadata();
                } else {
                    // No data returned, so hide the datatable.
                    this.showMetadataDatatable = false;
                    this.metadata = [];
                    this.metadataToDisplayInDatatable = [];
                    this.filteredMetadata = [];
                }
            })
            .catch(error => {
                this.showSpinnerInsideMetadataBox = false;
                console.log('error -- ' + JSON.stringify(error));
            });
    }

    @track pageSizeOptionsMetadata = [5, 10, 20, 50];
    handleMetadataPerPage(event) {
        const pageSizeMD = parseInt(event.target.value, 10);
        this.pageSizeMetadata = pageSizeMD;
        this.currentPage = 1;
        this.updatePaginatedMetadata();

    }

    @track metadataSearchKey = ''

    handleSearchMetadata(event) {
        const searchKey = event.target.value.toLowerCase();
        this.metadataSearchKey = searchKey;

        if (searchKey) {
            this.filteredMetadata = this.metadataToDisplayInDatatable.filter(metadata =>
                metadata.value.toLowerCase().includes(searchKey)
            );
        } else {
            this.filteredMetadata = [...this.metadataToDisplayInDatatable];
        }
        this.currentPage = 1;
        this.totalPages = Math.ceil(this.filteredMetadata.length / this.pageSizeMetadata);
        this.updatePaginatedMetadata();
        this.updatePaginatedSelectedMetadata();
    }

    @track currentPage = 1; // Current page number
    @track totalPages = 1; // Total number of pages
    @track pageSizeMetadata = 5; // Records per page
    @track paginatedMetadata = []; // Metadata for the current page
    @track selectedRows = []; // Tracks selected rows across pages

    updatePaginatedMetadata() {
        this.totalPages = Math.ceil(this.filteredMetadata.length / this.pageSizeMetadata);
        const start = (this.currentPage - 1) * this.pageSizeMetadata;
        const end = start + this.pageSizeMetadata;
        console.log('Start ::' + start, ' end:: ' + end);

        this.paginatedMetadata = this.filteredMetadata.slice(start, end);
        this.preselectedRows = this.metadataToDisplayInDatatable
            .map(row => row.value)
            .filter(value => Object.keys(this.selectedMetadataMap).includes(value));
    }

    handlePageChange() {
        this.updatePaginatedMetadata();
        this.updatePaginatedSelectedMetadata();
    }

    handleFirstPage() {
        this.currentPage = 1;
        this.handlePageChange();
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            this.handlePageChange();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
            this.handlePageChange();
        }
    }

    handleLastPage() {
        this.currentPage = this.totalPages;
        this.handlePageChange();
    }

    get isFirstPageDisabled() {
        return this.currentPage === 1;
    }

    get isLastPageDisabled() {
        return this.currentPage === this.totalPages;
    }

    handleSelectedPageChange() {
        this.updatePaginatedSelectedMetadata();
    }

    updatePreselectedRows(metadataType) {
        // Reset preselectedRows
        this.preselectedRows = [];

        // Find if there are any existing selections under the current metadata type
        const selectedMetadataForType = this.selectedMetadataListToDisplay.find(metadata => metadata.type === metadataType);

        if (selectedMetadataForType && selectedMetadataForType.members) {
            const membersToSelect = selectedMetadataForType.members;

            // Preselect rows by matching the 'value' field in the datatable rows
            this.preselectedRows = this.paginatedMetadata
                .filter(row => membersToSelect.includes(row.value))
                .map(row => row.value); // Ensure the values match the datatable row values
        }
        console.log('preselectedRows --- ' + this.preselectedRows);
    }

    @track selectedMetadataRows = {};
    @track selectedMetadataMap = {};
    handleMetadataDatatableRowAction(event) {
        let selectedRows = event.detail.selectedRows || [];
        const selectedValues = selectedRows.map(row => row.value);
        console.log('selected value --- ' + selectedValues);

        selectedRows.forEach(row => {
            this.selectedMetadataMap[row.value] = {
                formattedString: `Name: ${row.value}, Type: ${row.type}, Last Modified By: ${row.lastModifiedBy} , Last Modified Date: ${row.lastModifiedDate}, Created By: ${row.createdBy} , Created Date: ${row.createdDate}`,
                lastModifiedBy: row.lastModifiedBy,
                lastModifiedDate: row.lastModifiedDate,
                createdBy: row.createdBy,
                createdDate: row.createdDate,
                name: row.value,
                type: row.type

            };
        });

        // Remove deselected rows from `selectedMetadataMap`
        Object.keys(this.selectedMetadataMap).forEach(metadata => {
            if (
                !selectedValues.includes(metadata) &&
                this.paginatedMetadata.some(data => data.value === metadata)
            ) {
                delete this.selectedMetadataMap[metadata];
            }
        });

        console.log('selectedMetadataMap: ' + Object.keys(this.selectedMetadataMap));
        this.transformMapToArray();

        this.updateSelectedMetadataList();
        this.updatePaginatedMetadata();
        this.updatePaginatedSelectedMetadata();
    }

    transformMapToArray() {
        this.selectedMetadataListToDisplay = Object.entries(this.selectedMetadataMap).map(([name, metadata]) => {
            return {
                name, // Metadata name
                type: metadata.formattedString.split(',')[1].split(':')[1].trim(), // Extract 'Type' from formattedString
                lastModifiedBy: metadata.lastModifiedBy, // Add lastModifiedBy
                lastModifiedDate: metadata.lastModifiedDate, // Add lastModifiedDate
                createdBy: metadata.createdBy, // Add createdBy
                createdDate: metadata.createdDate // Add createdDate
            };
        });
        this.selectedMetadataColumns = selectedMetadataColumns;
        this.selectedMetadataListToDisplay = [...this.selectedMetadataListToDisplay];
        this.selectedTotalPages = Math.ceil(this.selectedMetadataListToDisplay.length / this.selectedPageSize);
        this.selectedCurrentPage = Math.min(this.selectedCurrentPage, this.selectedTotalPages || 1); // Prevent invalid page number
        this.updatePaginatedSelectedMetadata();

        this.isSelectedMetadata = Object.keys(this.selectedMetadataListToDisplay).length < 0 ? true : false;
        console.log('isSelectedMetadata: ' + this.isSelectedMetadata);

        console.log('selectedMetadataListToDisplay --- ' + JSON.stringify(this.selectedMetadataListToDisplay)); // To verify the result
    }

    get formattedMetadataList() {
        //return this.convertMetadataListToJson();
        if (!this.selectedMetadata) {
            console.warn('Skipping Metadata JSON conversion: No metadata type selected');
            return [];
        }
        return this.convertMetadataListToJson();
    }

    convertMetadataListToJson() {

        const groupedMetadata = {};

        // Iterate over selectedMetadataListToDisplay and group by 'type'
        this.selectedMetadataListToDisplay.forEach(item => {
            if (!groupedMetadata[item.type]) {
                groupedMetadata[item.type] = {
                    type: item.type,
                    members: []
                };
            }
            groupedMetadata[item.type].members.push(item.name);
        });

        // Convert grouped object into an array
        const formattedMetadataArray = Object.values(groupedMetadata);

        console.log('Formatted Metadata JSON:', JSON.stringify(formattedMetadataArray, null, 2));

        return formattedMetadataArray;
    }

    @track pageSizeOptionsSelectedMetadata = [5, 10, 20, 50];
    handleSelectedMetadataPerPage(event) {
        const pageSizeSMD = parseInt(event.target.value, 10);
        this.selectedPageSize = pageSizeSMD;
        this.selectedCurrentPage = 1;
        this.updatePaginatedSelectedMetadata();

    }

    updateSelectedMetadataList() {
        this.selectedMetadataListToDisplay = Object.values(this.selectedMetadataMap);
        console.log('sordDirection>> ' + this.sortDirectionSelectedMetada, '  sortby>> ' + this.sortedBySelectedMetadata);
        let sortData = [];
        if (this.sortDirectionSelectedMetada && this.sortedBySelectedMetadata) {
            console.log('in if>>>');
            sortData = this.selectedMetadataListToDisplay;
            sortData.sort((a, b) => {
                let valueA = a[this.sortedBySelectedMetadata] ? a[this.sortedBySelectedMetadata].toString().toLowerCase() : '';
                let valueB = b[this.sortedBySelectedMetadata] ? b[this.sortedBySelectedMetadata].toString().toLowerCase() : '';

                return this.sortDirection === 'asc' ? valueA.localeCompare(valueB) : valueB.localeCompare(valueA);
            });
            console.log('Sort Data>> ' + JSON.stringify(sortData));

            this.selectedMetadataListToDisplay = sortData;
            //this.sortSelectedMetadataTable = true;
        }
        this.selectedTotalPages = Math.ceil(this.selectedMetadataListToDisplay.length / this.selectedPageSize);
        this.selectedCurrentPage = Math.min(this.selectedCurrentPage, this.selectedTotalPages || 1);
        this.updatePaginatedSelectedMetadata();
    }

    updatePaginatedSelectedMetadata() {
        this.selectedCurrentPage = this.paginatedSelectedMetadata.length == 0 && this.selectedCurrentPage > 1 ? this.selectedCurrentPage - 1 : this.selectedCurrentPage;
        this.selectedTotalPages = Math.ceil(this.selectedMetadataListToDisplay.length / this.selectedPageSize);
        const start = (this.selectedCurrentPage - 1) * this.selectedPageSize;
        const end = start + this.selectedPageSize;
        console.log('Start:: ' + start, '  end:: ' + end);

        this.paginatedSelectedMetadata = this.selectedMetadataListToDisplay.slice(start, end);
        console.log('paginatedSelectedMetadata:: ' + JSON.stringify(this.paginatedSelectedMetadata));
        // this.preselectedRows = this.selectedMetadataListToDisplay
        //     .map(row => row.name)
        //     .filter(name => this.selectedMetadataMap[name]);
        this.preselectedRows = Object.keys(this.selectedMetadataMap);
    }


    @track selectedCurrentPage = 1; // Current page number for selected metadata
    @track selectedTotalPages = 1; // Total number of pages for selected metadata
    @track selectedPageSize = 5; // Records per page for selected metadata
    @track paginatedSelectedMetadata = []; // Selected metadata for the current page

    handleSelectedFirstPage() {
        this.selectedCurrentPage = 1;
        this.sortSelectedMetadataTable = true;
        this.updatePaginatedSelectedMetadata();
    }

    handleSelectedNextPage() {
        if (this.selectedCurrentPage < this.selectedTotalPages) {
            this.selectedCurrentPage++;
            this.sortSelectedMetadataTable = true;
            this.updatePaginatedSelectedMetadata();
        }
    }

    handleSelectedPreviousPage() {
        if (this.selectedCurrentPage > 1) {
            this.selectedCurrentPage--;
            this.sortSelectedMetadataTable = true;
            this.updatePaginatedSelectedMetadata();
        }
    }

    handleSelectedLastPage() {
        this.selectedCurrentPage = this.selectedTotalPages;
        this.sortSelectedMetadataTable = true;
        this.updatePaginatedSelectedMetadata();
    }

    // Navigation button disabled states
    get isSelectedFirstPageDisabled() {
        return this.selectedCurrentPage === 1;
    }

    get isSelectedLastPageDisabled() {
        return this.selectedCurrentPage === this.selectedTotalPages;
    }

    get showSelectedMD() {
        console.log('in showSelectedMD' + Object.values(this.selectedMetadataMap).length);
        console.log('in showSelectedMD' + Object.values(this.selectedMetadataMap).length > 0);
        return Object.values(this.selectedMetadataMap).length > 0;
    }

    handleSelectedMetadataRowAction(event) {
        console.log('in handleSelectedMetadataRowAction');

        let selectedRows = event.detail.selectedRows || [];
        console.log('selectedRows :: ' + JSON.stringify(selectedRows));

        // Get currently displayed rows to handle deselections properly
        const currentPageValues = this.paginatedSelectedMetadata.map(row => row.name);

        // Handle selections
        selectedRows.forEach(row => {
            if (!this.selectedMetadataMap[row.name]) {
                this.selectedMetadataMap[row.name] = row;
            }
        });

        //let deletedRecCount = 0
        // Handle deselections - only for current page items
        currentPageValues.forEach(name => {
            if (!selectedRows.find(row => row.name === name)) {
                delete this.selectedMetadataMap[name];
               // deletedRecCount++;
            }
        });

        // Update the list display
        this.selectedMetadataListToDisplay = Object.values(this.selectedMetadataMap);

        if (this.searchKeySMD) {
            this.selectedMetadataListToDisplay = this.selectedMetadataListToDisplay.filter(metadata =>
                metadata.name && metadata.name.toLowerCase().includes(this.searchKeySMD)
            );
        }

        this.paginatedSelectedMetadata = selectedRows.length<1 ? [] : this.paginatedSelectedMetadata;

        // Update preselected rows for current page
        // this.preselectedRows = this.paginatedSelectedMetadata
        //     .map(row => row.name)
        //     .filter(name => this.selectedMetadataMap[name]);

        // Refresh pagination
        this.updatePaginatedSelectedMetadata();
        if (this.sortSelectedMetadataTable && this.sortedSelectedMdData.length > 0) {
            this.selectedMetadataListToDisplay = this.sortedSelectedMdData;
            this.sortSelectedMetadataTable = false;
            this.updatePaginatedSelectedMetadata();
        }
    }


    handleSearchSelectedMetadata(event) {
        this.searchKeySMD = event.target.value.toLowerCase();
        console.log('searchKeySMD>> ' + this.searchKeySMD);
        console.log('selectedMetadataMap :: ' + JSON.stringify(this.selectedMetadataMap));

        if (this.searchKeySMD) {
            this.selectedMetadataListToDisplay = Object.values(this.selectedMetadataMap).filter(metadata =>
                metadata.name.toLowerCase().includes(this.searchKeySMD)
            );
            console.log('selectedMetadataListToDisplay>> ' + JSON.stringify(this.selectedMetadataListToDisplay));
        } else {
            this.selectedMetadataListToDisplay = Object.values(this.selectedMetadataMap);
        }
        console.log('selectedMetadataListToDisplay>> ' + JSON.stringify(this.selectedMetadataListToDisplay));
        this.selectedCurrentPage = 1;
        this.selectedTotalPages = Math.ceil(this.selectedMetadataListToDisplay.length / this.selectedPageSize) || 1;
        this.updatePaginatedSelectedMetadata();
        //this.preselectedRows = Object.keys(this.selectedMetadataMap); 


    }

    @track metadataToDisplayInDatatable = [];
    handleSortMetadata(event) {
        try {
            const { fieldName: sortedBy, sortDirection } = event.detail;
            // Sort only the records displayed on the current page
            const currentPageData = [...this.filteredMetadata];

            currentPageData.sort((a, b) => {
                let valueA = a[sortedBy] ? a[sortedBy].toLowerCase() : '';
                let valueB = b[sortedBy] ? b[sortedBy].toLowerCase() : '';
                return sortDirection === 'asc'
                    ? valueA.localeCompare(valueB)
                    : valueB.localeCompare(valueA);
            });

            this.filteredMetadata = [...currentPageData];
            //this.paginatedMetadata = [...currentPageData];
            this.sortDirectionMetada = sortDirection;
            this.sortedByMetadata = sortedBy;
            this.updatePaginatedMetadata();
            this.updatePaginatedSelectedMetadata();
            // No need to reset pagination since sort is local to current page
            console.log('Sorting applied to current page only');
        } catch (error) {
            console.error('Error in handleSortMetadata:', error);
        }
    }

    @track sortedBySelectedMetadata;
    @track sortDirectionSelectedMetada = 'asc';

    @track sortedSelectedMdData = [];
    @track sortSelectedMetadataTable = false;
    handleSortSelectedMetadata(event) {
        console.log('In handleSortSelectedMetadata ::');
        this.sortedSelectedMdData = [];
        this.sortSelectedMetadataTable = true;
        const { fieldName: sortedBy, sortDirection } = event.detail;
        let sortedData = [...this.selectedMetadataListToDisplay];
        sortedData.sort((a, b) => {
            let valueA = a[sortedBy] ? a[sortedBy].toString().toLowerCase() : '';
            let valueB = b[sortedBy] ? b[sortedBy].toString().toLowerCase() : '';

            return sortDirection === 'asc' ? valueA.localeCompare(valueB) : valueB.localeCompare(valueA);
        });
        console.log('after sort :: ' + JSON.stringify(sortedData));
        this.selectedMetadataListToDisplay = [...sortedData];
        this.sortedSelectedMdData = [...sortedData];
        this.sortedBySelectedMetadata = sortedBy;
        this.sortDirectionSelectedMetada = sortDirection;
        //this.selectedCurrentPage = 1;
        this.updatePaginatedSelectedMetadata();
        //this.selectedTotalPages = Math.ceil(this.selectedMetadataListToDisplay.length / this.selectedPageSize);
    }


    @track metadataPackageXmlContent = '';
    generatePackageXml() {
        console.log('this.formattedMetadataList --- ' + JSON.stringify(this.formattedMetadataList));

        if (Object.keys(this.formattedMetadataList).length > 0) {
            this.showSpinner = true;
            let packageXmlContent = `<?xml version="1.0" encoding="UTF-8"?>
            <Package xmlns="http://soap.sforce.com/2006/04/metadata">`;

            this.formattedMetadataList.forEach(metadata => {
                let metadataType = metadata.type === 'CustomLabels' ? 'CustomLabel' : metadata.type;
                console.log('type --- ' + metadataType);

                let members = metadata.members.length ? metadata.members : ['*'];
                console.log('members --- ' + members);

                packageXmlContent += `
                <types>${members.map(member => `<members>${member}</members>`).join('')}
                <name>${metadataType}</name>
                </types>`;

                if (metadataType === 'CustomMetadata') {
                    const uniqueMembers = [...new Set(members.map(member => member.split('.')[0]))];

                    packageXmlContent += `
                    <types>${uniqueMembers.map(member => `<members>${member}__mdt</members>`).join('')}
                    <name>CustomObject</name>
                    </types>`;
                }
            });

            packageXmlContent += `<version>59.0</version>
            </Package>`;

            this.metadataPackageXmlContent = packageXmlContent;
            console.log('metadataPackageXmlContent --- ' + this.metadataPackageXmlContent);
        }
    }

    /****************** END OF METADATA PICKER CODE BLOCK FOR CREATE NEW TEMPLATE ******************/


    /****************** DATA PICKER CODE BLOCK FOR CREATE NEW TEMPLATE ******************/
    // Common Properties
    @api selectedOrg;
    @track selectedData = '';
    @track showSpinnerInsideAccordionsData = false;
    @track selectedAccordionSection = '';

    // Data Selection Properties
    @track isSelectedUserEmpty = true;
    @track isSelectedCustomSettingsEmpty = true;
    @track isSelectedScheduledJobsEmpty = true;
    @track isSelectedMetadata = false;
    @track showUsersDatatable = false;
    @track showCustomSettingsDatatable = false;
    @track showScheduledJobsDatatable = false;
    @track isUsersSelected = false;
    @track isCustomSettingsSelected = false;
    @track isScheduledJobsSelected = false;


    // Common Methods
    get dataOptions() {
        return [
            { label: 'Users', value: 'Users' },
            { label: 'Custom Settings', value: 'Custom Settings' },
            { label: 'Scheduled Jobs', value: 'Scheduled Jobs' },
        ];
    }

    handleDataSelection(event) {
        console.log('i am in handleDataSelection');
        const newSelectedData = event.target.value;

        // Reset all section flags and datatables
        this.isUsersSelected = false;
        this.isCustomSettingsSelected = false;
        this.isScheduledJobsSelected = false;
        this.showUsersDatatable = false;
        this.showCustomSettingsDatatable = false;
        this.showScheduledJobsDatatable = false;
        this.nextRecordsUrl = '';
        this.oldNextRecordsUrl = '';
        this.pageNumberUsers = 1;

        // Set only the selected section flag
        switch (newSelectedData) {
            case 'Users':
                this.isUsersSelected = true;
                this.showUsersDatatable = true;
                break;
            case 'Custom Settings':
                this.isCustomSettingsSelected = true;
                this.showCustomSettingsDatatable = true;
                break;
            case 'Scheduled Jobs':
                this.isScheduledJobsSelected = true;
                this.showScheduledJobsDatatable = true;
                break;
        }

        this.selectedData = newSelectedData;

        if (newSelectedData) {
            console.log('i am in newSelectedData');
            this.fetchAllDataComponents(newSelectedData);
            // Wait for the DOM to update before opening the accordion
            setTimeout(() => {
                const accordion = this.template.querySelector('lightning-accordion');
                if (accordion) {
                    switch (newSelectedData) {
                        case 'Users':
                            accordion.activeSectionName = 'Users';
                            break;
                        case 'Custom Settings':
                            accordion.activeSectionName = 'CustomSettings';
                            break;
                        case 'Scheduled Jobs':
                            accordion.activeSectionName = 'ScheduledJobs';
                            break;
                    }
                }
            }, 0);
        }
    }

    handleBackFromDataPicker() {
        this.searchTermRules = '';
        this.searchTermSuffix = '';
        this.searchTerm = '';
        this.selectedTableSearchTermUSER = '';
        //this.filterLetter = '';
        //this.activeLetter = '';

        // Custom Settings section
        this.searchTermavailCus = '';
        this.searchTermselCus = '';

        // Scheduled Jobs section
        this.searchTermSJ = '';
        this.searchTermSelectedSJ = '';


        // Reset page sizes to default for all sections
        // Users section
        this.selectedTablePageSize = 10;
        this.pageSizeRules = 5;
        this.pageSizeSuffix = 5;

        // Custom Settings section
        this.pageSizeCS = 5;
        this.selectedPageSizeCS = 5;

        // Scheduled Jobs section
        this.pageSizeSJ = 5;
        this.selectedPageSizeSJ = 5;
        this.currentPageRules = 1;
        this.currentPageSuffix = 1;
        this.currentPageAvailCS = 1;
        this.selectedCurrentPageCS = 1;
        this.currentPageSJ = 1;
        this.selectedCurrentPageSJ = 1;
        this.selectedTablePage = 1;
        this.searchTermapexScript = '';
        //this.pageSizeApex = 5;


        // Reset table data to reflect cleared search terms
        if (this.selectedData === 'Users') {
            this.filteredData = [...this.userDataforDatatable];
            this.refreshSelectedTableData();
        } else if (this.selectedData === 'Custom Settings') {
            this.updateSelectedCustomSettingsData();
            this.updatePreselectedRowsForCS();
        } else if (this.selectedData === 'Scheduled Jobs') {
            this.updateSelectedJobsData();
            this.updatePreselectedRows();
        }
        this.isDataPicker = false;
        this.showFindAndReplacePage = true;

        console.log("Before filtering: ", JSON.stringify(this.findAndReplaceRulesForBackend));

        // Initially hide both sections
        this.showSearchAndReplace = false;
        this.showSuffix = false;

        // Only show appropriate section if we have a previous masking type
        if (this.previousSelectedMaskingType) {
            this.selectedMaskingType = this.previousSelectedMaskingType;

            if (this.selectedMaskingType === 'Search & Replace') {
                this.showSearchAndReplace = true;
                this.showSuffix = false;
                this.showapexScript = false;
            } else if (this.selectedMaskingType === 'Suffix') {
                this.showSearchAndReplace = false;
                this.showSuffix = true;
                this.showapexScript = false;
            } else if (this.selectedMaskingType === 'Apex Script') {
                this.showapexScript = true;
                this.showSearchAndReplace = false;
                this.showSuffix = false;
            }

            // Reload rules for the selected masking type
            this.findAndReplaceRules = this.findAndReplaceRulesForBackend.filter(
                rule => rule.maskingType === this.selectedMaskingType
            );
        } else {
            // If no previous masking type, clear the selection and hide both sections
            this.selectedMaskingType = '';
            this.findAndReplaceRules = [];
        }

        console.log("Selected Masking Type:", this.selectedMaskingType);
        console.log("Filtered Rules:", JSON.stringify(this.findAndReplaceRules));
    }

    handleNextFromDataPicker() {
        this.searchTermRules = '';
        this.searchTermSuffix = '';
        this.searchTerm = '';
        this.selectedTableSearchTermUSER = '';
        //this.filterLetter = '';
        //this.activeLetter = '';

        // Custom Settings section
        this.searchTermavailCus = '';
        this.searchTermselCus = '';

        // Scheduled Jobs section
        this.searchTermSJ = '';
        this.searchTermSelectedSJ = '';


        // Reset page sizes to default for all sections
        // Users section
        this.selectedTablePageSize = 10;
        this.pageSizeRules = 5;
        this.pageSizeSuffix = 5;

        // Custom Settings section
        this.pageSizeCS = 5;
        this.selectedPageSizeCS = 5;

        // Scheduled Jobs section
        this.pageSizeSJ = 5;
        this.selectedPageSizeSJ = 5;
        this.currentPageRules = 1;
        this.currentPageSuffix = 1;
        this.currentPageAvailCS = 1;
        this.selectedCurrentPageCS = 1;
        this.currentPageSJ = 1;
        this.selectedCurrentPageSJ = 1;
        this.selectedTablePage = 1;
        this.searchTermapexScript = '';
        //this.pageSizeApex = 5;


        // Reset table data to reflect cleared search terms
        if (this.selectedData === 'Users') {
            this.filteredData = [...this.userDataforDatatable];
            this.refreshSelectedTableData();
        } else if (this.selectedData === 'Custom Settings') {
            this.updateSelectedCustomSettingsData();
            this.updatePreselectedRowsForCS();
        } else if (this.selectedData === 'Scheduled Jobs') {
            this.updateSelectedJobsData();
            this.updatePreselectedRows();
        }

        // Reset search terms
        this.searchTermRules = '';
        this.searchTermSuffix = '';
        // this.searchTermapexScript = '';
        //pageSizeApex = 5;

        // Reset page sizes to default
        this.pageSizeRules = 5;
        this.pageSizeSuffix = 5;

        // Reset current pages to first page
        this.currentPageRules = 1;
        this.currentPageSuffix = 1;
        this.previousSelectedMaskingType = this.selectedMaskingType;
        this.updateSearchAndReplaceTable();
        this.updateSuffixTable();
        this.showSearchAndReplace = true;
        this.showSuffix = true;
        this.showapexScript = true;

        // Check specifically for search key without replace value
        if (this.selectedMaskingType === 'Search & Replace') {
            if (this.searchKey && !this.replaceValue) {
                // Show popup if replace value is missing
                this.isShowModalForFindAndReplaceValidation = true;
                this.showSuffix = false;
                return;
            } else if (this.searchKey && this.replaceValue) {
                // Clear form if both values are present
                this.resetForm();
            }
        }

        // Handle Suffix validation
        if (this.selectedMaskingType === 'Suffix' && this.suffixValue) {
            this.resetForm();
        }
        // Handle Apex Script validation
        if (this.selectedMaskingType === 'Apex Script' &&
            this.newScriptOrder &&
            this.newScriptName &&
            this.newScriptDetails) {
            this.resetForm();
        }

        // Navigate to next page
        this.isDataPicker = false;
        this.showCreateTemplatePage = true;
    }

    fetchAllDataComponents(type) {
        console.log('I m in fetchAllDataComponents');
        console.log('fetchAllDataComponents called with type:', type);
        this.showSpinnerInsideAccordionsData = true;
        this.showUsersDatatable = false;
        this.showCustomSettingsDatatable = false;
        this.showScheduledJobsDatatable = false;

        if (type.includes('Users')) {
            const previousNextRecordsUrl = this.nextRecordsUrl; // Save the current nextRecordsUrl
            console.log('previousNextRecordsUrl ---', this.previousNextRecordsUrl);
            console.log('Fetching users for org:', this.selectedOrg);
            console.log('nextRecordsUrl --- ' + this.nextRecordsUrl);

            const queryEndpoint = this.nextRecordsUrl || ''; // Use an empty string for the first page

            fetchAllUsers({ sandboxId: this.selectedOrg, queryEndpoint, SearchString: '', sortBy: '' })
                //fetchAllUsers({ sandboxId: this.selectedOrg, queryEndpoint : this.nextRecordsUrl })
                .then(result => {

                    console.log('result --- ', JSON.stringify(result));
                    this.showSpinnerInsideAccordionsData = false;
                    this.showUsersDatatable = true;
                    this.showCustomSettingsDatatable = false;
                    this.showScheduledJobsDatatable = false;

                    this.userDataforDatatable = [];
                    this.columnsForUserData = columnsForUserData;

                    // Populate the datatable data and calculate serial numbers
                    result.users.forEach((user, index) => {
                        this.userDataforDatatable.push({
                            Name: user.name,
                            Email: user.email,
                            Username: user.username,
                            Profile: user.profile,
                        });
                    });

                    this.preselectedUsernames = Object.keys(this.selectedUserMap).filter(username =>
                        this.userDataforDatatable.some(user => user.Username === username)
                    );
                    this.filteredData = [...this.userDataforDatatable];
                    this.nextRecordsUrl = result.nextRecordsUrl || null;
                    console.log('nextRecordsUrl after response --- ', this.nextRecordsUrl);
                    // Save oldNextRecordsUrl for Previous button if nextRecordsUrl becomes null
                    if (this.nextRecordsUrl != previousNextRecordsUrl) {
                        console.log('Setting oldNextRecordsUrl for previous navigation:', previousNextRecordsUrl);
                        this.oldNextRecordsUrl = previousNextRecordsUrl;
                    }
                    this.updatePaginationControls();
                    this.totalRecordsUSER = result.totalRecords || 0;
                    console.log('Total Records Count:', this.totalRecordsUSER);


                    this.showPagination = true;
                    this.updatePreselectedRowsForUsers();

                })
                .catch(error => {
                    console.error('Error queuing job:', error);
                    this.showSpinnerInsideAccordionsData = false;
                });
        }


        if (type.includes('Custom Settings')) {
            console.log('i am in custom setting');
            fetchCustomSettings({ sandboxId: this.selectedOrg })
                .then(result => {
                    console.log('result --- ' + JSON.stringify(result));
                    this.showSpinnerInsideAccordionsData = false;
                    this.showUsersDatatable = false;
                    this.showCustomSettingsDatatable = true;
                    this.showScheduledJobsDatatable = false;

                    this.customSettingsDataforDatatable = [];
                    this.columnsForCustomSettings = columnsForCustomSettings;
                    result.forEach(objWrap => {
                        this.customSettingsDataforDatatable.push({
                            customSettingName: String(objWrap['name'])
                        });
                    });

                    this.updatePreselectedRowsForCS();
                })
                .catch(error => {
                    this.showSpinnerInsideAccordionsData = false;
                    console.log('error -- ' + JSON.stringify(error));
                });
        }

        if (type.includes('Scheduled Jobs')) {
            fetchScheduledJobs({ sandboxId: this.selectedOrg })
                .then(result => {
                    console.log('result --- ' + JSON.stringify(result));
                    this.showSpinnerInsideAccordionsData = false;
                    this.showUsersDatatable = false;
                    this.showCustomSettingsDatatable = false;
                    this.showScheduledJobsDatatable = true;

                    this.scheduledJobsDataforDatatable = [];
                    this.columnsForScheduledJobs = columnsForScheduledJobs;
                    result.forEach(objWrap => {
                        this.scheduledJobsDataforDatatable.push({
                            //cronJobDetailId : String(objWrap['cronJobDetailId']),
                            jobName: String(objWrap['jobName']),
                            jobType: String(objWrap['jobType']),
                            apexClassName: String(objWrap['apexClassName']),
                            //state : String(objWrap['state']),
                            //NextFireTime : String(objWrap['nextFireTime']),
                            //StartTime : String(objWrap['startTime']),
                            //EndTime : String(objWrap['endTime']),
                            //timeZoneSidKey : String(objWrap['timeZoneSidKey']),
                            cronExpression: String(objWrap['cronExpression']),
                            //timesTriggered : Integer(objWrap['timesTriggered']),
                            //PreviousFireTime : String(objWrap['previousFireTime']),
                        });
                    });

                    this.updatePreselectedRowsForSJ();
                })
                .catch(error => {
                    this.showSpinnerInsideAccordionsData = false;
                    console.log('error -- ' + JSON.stringify(error));
                });
        }
    }

    updatePreselectedRowsForMetadata() {
        this.preselectedRows = Object.keys(this.selectedMetadataMap).filter(metadata =>
            this.selectedMetadataListToDisplay.some(row => row.name === metadata)
        );
        console.log('Preselected Metadata Rows:', this.preselectedRows);
    }


    /*User section*/
    // API Properties
    @api isUsersSelected = false;

    // Track variables for user data
    @track selectedUsers = [];
    @track selectedUsernames = [];
    @track selectedUserMap = {};
    @track preselectedUsernames = [];
    @track filteredData = [];
    @track userDataforDatatable = [];

    // Track variables for pagination and search
    @track pageNumberUsers = 1;
    @track searchTerm = '';
    @track selectedTablePage = 1;
    @track selectedTablePageSize = 10;
    @track selectedTableSearchTermUSER = '';
    @track pageSizeOptionsselectedUser = [10, 25, 50, 100];
    @track totalSelectedRecords = 0;

    // Track variables for filtering
    @track alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
    @track filterLetter = '';
    @track activeLetter = '';
    @track allData = [];

    // Track variables for UI state
    @track showSpinnerForFilter = false;
    @track showSpinnerForSelection = false;
    @track selectedTableRows = [];
    @track nextRecordsUrl = '';
    @track oldNextRecordsUrl = '';
    @track selectedTableSelectedRows = [];
    @track totalPagesUser = 0;
    @track currentPageUser = 1;
    @track sortedBy = '';
    @track sortDirection = 'asc';
    @track selectedTableSortedBy = '';
    @track selectedTableSortDirection = 'asc';
    pageSizeOptionsAvailUser = [2000];

    handleAvailTablePageSizeChange(event) {
        const selectedPageSize = event.target.value;
        console.log('Selected Page Size:', selectedPageSize);
        // Perform any logic needed when the page size changes, like pagination
    }

    get letterButtons() {
        return this.alphabet.map(letter => ({
            letter,
            className: `alphabet-button ${this.activeLetter === letter ? 'active' : ''}`
        }));
    }
    get allButtonClass() {
        return `alphabet-button ${!this.activeLetter ? 'active' : ''}`;
    }


    // Getters for computed properties
    get hasSelectedUsers() {
        return this.selectedUsers && this.selectedUsers.length > 0;
    }
    get isSelectedUserEmpty() {
        return Object.keys(this.selectedUserMap).length === 0
    }
    get paginationText() {
        return `Showing ${this.pageNumberUsers} of ${this.totalPagesAvailable} Page(s)`;
    }
    get totalPagesAvailable() {
        return Math.ceil(this.totalRecordsUSER / 2000);
    }

    get paginatedSelectedDataUser() {
        console.log('==== PAGINATED SELECTED DATA USER START ====');
        console.log('Selected user map size:', Object.keys(this.selectedUserMap).length);
        console.log('Current search term:', this.selectedTableSearchTermUSER);

        // Memoize the conversion of selectedUserMap to array
        if (!this._cachedSelectedData || this._lastMapUpdate !== JSON.stringify(this.selectedUserMap)) {
            console.log('Rebuilding cached selected data');
            this._cachedSelectedData = Object.values(this.selectedUserMap).map(user => ({
                Name: user.name,
                Email: user.email,
                Username: user.Username || user.id,
                Profile: user.profile
            }));
            this._lastMapUpdate = JSON.stringify(this.selectedUserMap);
        }

        let allSelectedData = this._cachedSelectedData;
        console.log('Initial data count:', allSelectedData.length);

        // Apply search filter if there's a search term
        if (this.selectedTableSearchTermUSER) {
            const searchTerm = this.selectedTableSearchTermUSER.toLowerCase();
            allSelectedData = allSelectedData.filter(user =>
            (user.Name?.toLowerCase().includes(searchTerm) ||
                user.Email?.toLowerCase().includes(searchTerm) ||
                user.Username?.toLowerCase().includes(searchTerm) ||
                user.Profile?.toLowerCase().includes(searchTerm))
            );
            console.log('Filtered data count after search:', allSelectedData.length);
        }

        // Apply sorting if needed
        if (this.selectedTableSortedBy) {
            console.log('Sorting by:', this.selectedTableSortedBy, 'direction:', this.selectedTableSortDirection);
            allSelectedData = [...allSelectedData].sort((a, b) => {
                let valueA = a[this.selectedTableSortedBy] || '';
                let valueB = b[this.selectedTableSortedBy] || '';

                valueA = typeof valueA === 'string' ? valueA.toLowerCase() : valueA;
                valueB = typeof valueB === 'string' ? valueB.toLowerCase() : valueB;

                const sortResult = valueA > valueB ? 1 : -1;
                return this.selectedTableSortDirection === 'desc' ? -sortResult : sortResult;
            });
        }

        // Update total records count
        this.totalSelectedRecords = allSelectedData.length;
        console.log('Total selected records:', this.totalSelectedRecords);

        // Calculate pagination
        const startIndex = (this.selectedTablePage - 1) * this.selectedTablePageSize;
        const endIndex = Math.min(startIndex + this.selectedTablePageSize, allSelectedData.length);
        console.log('Pagination start:', startIndex, 'end:', endIndex);

        const paginatedData = allSelectedData.slice(startIndex, endIndex);
        console.log('Returning paginated data count:', paginatedData.length);
        console.log('==== PAGINATED SELECTED DATA USER END ====');

        return paginatedData;
    }

    get totalPagesselUSR() {
        return Math.ceil(this.totalSelectedRecords / this.selectedTablePageSize);
    }

    get currentPagesselUSR() {
        return Math.min(this.selectedTablePage, this.totalPagesselUSR);
    }

    get isSelectedPreviousDisabled() {
        return this.selectedTablePage <= 1;
    }

    get isSelectedNextDisabled() {
        return this.selectedTablePage >= this.totalPagesselUSR;
    }

    get getLetterButtonClass() {
        return (letter) => `slds-button ${this.activeLetter === letter ? 'slds-button_brand' : 'slds-button_neutral'}`;
    }

    // Event Handlers for main table
    handleInputChange(event) {
        this.searchTerm = event.target.value.toLowerCase();
        if (!this.searchTerm) {
            this.resetFilter();
        }
    }

    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.handleSearchClick();
        }
    }

    handleSearchClick() {
        this.allData = [];
        this.showSpinnerForFilter = true;
        this.nextRecordsUrl = '';
        this.getFilteredData(this.searchTerm, '')
            .then(() => {
                if (this.activeLetter) {
                    this.filteredData = this.filteredData.filter(user =>
                        user.Name.startsWith(this.activeLetter)
                    );
                }
                this.updatePreselectedRowsForUsers();
            });
    }

    // Event Handlers for selected table
    handleSelectedTableSearchUSER(event) {
        const searchTerm = event.target.value.toLowerCase();

        // Preserve full selection state
        const currentSelections = { ...this.selectedUserMap };

        this.selectedTableSearchTermUSER = searchTerm;
        this.selectedTablePage = 1;

        // After search, restore all previous selections
        this.selectedUserMap = currentSelections;
        this.selectedUsers = Object.values(currentSelections);
        this.selectedUsernames = Object.keys(currentSelections);

        // Update selected rows based on current page and existing selections
        this.selectedTableRows = this.paginatedSelectedDataUser
            .filter(row => this.selectedUserMap[row.Username])
            .map(row => row.Username);

        this.refreshSelectedTableData();
    }

    handleSelectedTablePageSizeChange(event) {
        const newPageSize = parseInt(event.target.value, 10);
        this.selectedTablePageSize = newPageSize;

        // Retain all current selections
        const currentSelections = { ...this.selectedUserMap };

        // Reset page to 1 but keep all selections intact
        this.selectedTablePage = 1;

        // Update selections without losing existing data
        this.selectedUserMap = currentSelections;
        this.selectedUsers = Object.values(currentSelections);
        this.selectedUsernames = Object.keys(currentSelections);

        // Ensure selected rows reflect current selections
        this.selectedTableRows = this.paginatedSelectedDataUser
            .filter(row => this.selectedUserMap[row.Username])
            .map(row => row.Username);

        this.refreshSelectedTableData();
    }

    // Pagination handlers
    handleSelectedTablePrevious() {
        if (this.selectedTablePage > 1) {
            // Store current selections before page change
            const currentSelections = this.paginatedSelectedDataUser.map(row => row.Username);

            // Move to previous page
            this.selectedTablePage--;

            // After page change, mark all rows as selected
            this.selectedTableRows = this.paginatedSelectedDataUser.map(row => row.Username);
        }
    }

    handleSelectedTableNext() {
        if (this.selectedTablePage < this.totalPagesselUSR) {
            // Store current selections before page change
            const currentSelections = this.paginatedSelectedDataUser.map(row => row.Username);

            // Move to next page
            this.selectedTablePage++;

            // After page change, mark all rows as selected
            this.selectedTableRows = this.paginatedSelectedDataUser.map(row => row.Username);
        }
    }

    // Filter handlers
    filterByLetter(event) {
        this.allData = [];
        this.showSpinnerForFilter = true;
        const letter = event.target.dataset.letter;
        this.filterLetter = letter;
        this.activeLetter = letter;

        if (this.filterLetter === 'All') {
            this.resetFilter();
            return;
        }

        this.nextRecordsUrl = '';
        this.getFilteredData('', this.filterLetter)
            .then(() => {
                // Only update preselected rows if we have actual data
                if (!this.isPlaceholderData) {
                    this.updatePreselectedRowsForUsers();
                }
            });

        if (this.pageNumberUsers <= 1) {
            this.pageNumberUsers = 1;
        }
    }

    resetFilter() {
        this.searchTerm = '';
        this.filterLetter = '';
        this.allData = [];
        this.pageNumberUsers = 1;
        this.nextRecordsUrl = '';
        this.oldNextRecordsUrl = '';
        this.activeLetter = '';
        this.fetchAllDataComponents('Users');
        this.updatePaginationControls();
    }

    handleRowSelectionForUserData(event) {
        try {
            if (this.isPlaceholderData) {
                return;
            }
            this.showSpinnerForSelection = true;
            const selectedRows = event.detail.selectedRows || [];

            // Create a new map for better performance
            const newSelectedUserMap = new Map();

            // First, preserve existing selections that aren't in current view
            const visibleUsernames = new Set(this.filteredData.map(user => user.Username));
            Object.entries(this.selectedUserMap).forEach(([username, userData]) => {
                if (!visibleUsernames.has(username)) {
                    newSelectedUserMap.set(username, userData);
                }
            });

            // Process new selections
            selectedRows.forEach(user => {
                newSelectedUserMap.set(user.Username, {
                    id: user.Username,
                    type: 'Users',
                    name: user.Name,
                    email: user.Email,
                    profile: user.Profile,
                    Username: user.Username
                });
            });

            // Update the component properties
            this.selectedUserMap = Object.fromEntries(newSelectedUserMap);
            this.selectedUsers = Object.values(this.selectedUserMap);
            this.selectedUsernames = Object.keys(this.selectedUserMap);
            this.preselectedUsernames = [...this.selectedUsernames];
            this.selectedTableRows = [...this.selectedUsernames];

            this.refreshSelectedTableData();
            this.totalSelectedRecords = this.selectedUsers.length;

        } catch (error) {
            console.error('Error in row selection:', error);
        } finally {
            this.showSpinnerForSelection = false;
        }
    }

    handleDeselectUsers(event) {
        try {
            console.log('==== DESELECT USERS START ====');
            // Debounce to prevent multiple rapid deselections
            if (this._deselectionInProgress) {
                console.log('Deselection already in progress, skipping');
                return;
            }

            this._deselectionInProgress = true;
            this.showSpinnerForSelection = true;

            // Get the current selected rows from the event
            const currentSelectedRows = event.detail.selectedRows || [];
            const allCurrentPageRecords = this.paginatedSelectedDataUser || [];

            // Create sets for easier comparison
            const currentSelectedUsernames = new Set(currentSelectedRows.map(row => row.Username));
            console.log('Selected map before deselection:', Object.keys(this.selectedUserMap).length);
            console.log('Current page records:', allCurrentPageRecords.length);
            console.log('Current selections on page:', currentSelectedRows.length);

            // CASE 1: Header checkbox was unchecked to deselect all rows
            if (currentSelectedRows.length === 0 && allCurrentPageRecords.length > 0) {
                console.log('Deselect all operation');

                const newSelectedUserMap = { ...this.selectedUserMap };
                console.log('Selected map size before removing:', Object.keys(newSelectedUserMap).length);

                // Remove all records from the current page
                allCurrentPageRecords.forEach(row => {
                    console.log('Removing user:', row.Username);
                    delete newSelectedUserMap[row.Username];
                });

                console.log('Selected map size after removing:', Object.keys(newSelectedUserMap).length);

                // Update all the tracking variables
                this.selectedUserMap = newSelectedUserMap;
                this.selectedUsers = Object.values(this.selectedUserMap);
                this.selectedUsernames = Object.keys(this.selectedUserMap);
                this.preselectedUsernames = this.selectedUsernames;
                this.selectedTableRows = []; // Clear selected rows for this page

                console.log('Final selection counts:');
                console.log('  Selected map:', Object.keys(this.selectedUserMap).length);
                console.log('  Selected users:', this.selectedUsers.length);
                console.log('  Selected usernames:', this.selectedUsernames.length);
            }
            // CASE 2: Individual row deselection
            else {
                console.log('Individual deselection');

                // Get current known state before the event
                const previousSelectedUsernamesSet = new Set(Object.keys(this.selectedUserMap));
                const previousSelectedCount = previousSelectedUsernamesSet.size;
                console.log('Previous selected count:', previousSelectedCount);

                // Update selection state directly based on the event
                // This guarantees we match exactly what the UI shows
                const newSelectedUserMap = {};

                // First, preserve all selections not on current page
                Object.entries(this.selectedUserMap).forEach(([username, userData]) => {
                    // If username is not on current page, preserve it
                    if (!allCurrentPageRecords.some(record => record.Username === username)) {
                        newSelectedUserMap[username] = userData;
                    }
                });

                console.log('Selections not on current page:', Object.keys(newSelectedUserMap).length);

                // Then add all current selections
                currentSelectedRows.forEach(row => {
                    if (this.selectedUserMap[row.Username]) {
                        newSelectedUserMap[row.Username] = this.selectedUserMap[row.Username];
                    }
                });

                console.log('Total selections after adding current page selections:', Object.keys(newSelectedUserMap).length);

                // Update all the tracking variables
                this.selectedUserMap = newSelectedUserMap;
                this.selectedUsers = Object.values(this.selectedUserMap);
                this.selectedUsernames = Object.keys(this.selectedUserMap);
                this.preselectedUsernames = this.selectedUsernames;

                // Update selected rows to match the current selection
                this.selectedTableRows = Array.from(currentSelectedUsernames);
                console.log('Updated selectedTableRows length:', this.selectedTableRows.length);

                // Log the difference for debugging
                console.log('Records before:', previousSelectedCount);
                console.log('Records after:', Object.keys(newSelectedUserMap).length);
                console.log('Difference:', previousSelectedCount - Object.keys(newSelectedUserMap).length);
            }

            // Check if current page is now invalid after deselection
            const totalPagesselUSR = Math.ceil(this.selectedUsernames.length / this.selectedTablePageSize);
            console.log('Total pages after update:', totalPagesselUSR);

            if (this.selectedTablePage > totalPagesselUSR && totalPagesselUSR > 0) {
                // If current page is now invalid, move to the last valid page
                console.log('Page adjustment needed, moving from', this.selectedTablePage, 'to', totalPagesselUSR);
                this.selectedTablePage = totalPagesselUSR;
            }

            // Refresh the data
            console.log('Refreshing selected table data');
            this.refreshSelectedTableData();

        } catch (error) {
            console.error('Error in deselection:', error);
        } finally {
            this.showSpinnerForSelection = false;
            console.log('==== DESELECT USERS END ====');

            // Reset the debounce flag after a short delay
            setTimeout(() => {
                this._deselectionInProgress = false;
            }, 300);
        }
    }

    // Helper methods
    refreshSelectedTableData() {
        console.log('==== REFRESH TABLE DATA START ====');
        console.log('Current selectedUserMap size:', Object.keys(this.selectedUserMap).length);
        console.log('Current page:', this.selectedTablePage);
        console.log('Current page size:', this.selectedTablePageSize);

        // Debounce the refresh to prevent multiple rapid updates
        if (this._refreshTimeout) {
            clearTimeout(this._refreshTimeout);
            console.log('Cleared previous refresh timeout');
        }

        this._refreshTimeout = setTimeout(() => {
            console.log('Executing refresh inside timeout');
            // Ensure current page is valid
            const maxPages = this.totalPagesselUSR;
            console.log('Max pages:', maxPages);

            if (this.selectedTablePage > maxPages) {
                console.log('Page adjustment needed, setting to:', Math.max(1, maxPages));
                this.selectedTablePage = Math.max(1, maxPages);
            }

            // Use requestAnimationFrame for smooth UI updates
            requestAnimationFrame(() => {
                console.log('Inside requestAnimationFrame');
                // Get the current data that should be visible on this page
                const currentPageData = this.paginatedSelectedDataUser;
                console.log('Current page data count:', currentPageData.length);

                // Before setting selectedTableRows
                console.log('Selected table rows before update:', [...this.selectedTableRows]);

                // Update the selected rows to match what's visible on this page
                // All rows in the selected table should be "selected" since they're part of the selection
                this.selectedTableRows = currentPageData.map(row => row.Username);

                console.log('Selected table rows after update:', [...this.selectedTableRows]);
                console.log('Selected user map count after update:', Object.keys(this.selectedUserMap).length);

                this.totalSelectedRecords = this.selectedUsers.length;
                console.log('Total selected records:', this.totalSelectedRecords);
            });
        }, 100);

        console.log('==== REFRESH TABLE DATA END (timeout set) ====');
    }

    updatePaginationControls() {
        this.isNextDisabledAvailUSER = !this.nextRecordsUrl;
        this.isPreviousDisabledAvailUSER = this.pageNumberUsers <= 1;
        this.totalPagesUser = this.totalPagesAvailable;
    }

    updatePreselectedRowsForUsers() {
        this.preselectedUsernames = Object.keys(this.selectedUserMap).filter(username =>
            this.userDataforDatatable.some(user => user.Username === username)
        );
    }

    async getFilteredData(searchValue, sortValue) {
        this.filteredData = [];
        this.userDataforDatatable = [];
        this.showSpinnerForFilter = true;
        const previousNextRecordsUrl = this.nextRecordsUrl;

        try {
            const result = await fetchAllUsers({
                sandboxId: this.selectedOrg,
                queryEndpoint: this.nextRecordsUrl,
                searchString: searchValue,
                sortBy: sortValue
            });

            if (result?.users?.length > 0) {
                result.users.forEach(user => {
                    this.userDataforDatatable.push({
                        Name: user.name,
                        Email: user.email,
                        Username: user.username,
                        Profile: user.profile,
                        _isPlaceholder: false
                    });
                });
            } else {
                console.warn('⚡ No users found matching search.');
                this.filteredData = [];
            }

            if (this.nextRecordsUrl !== previousNextRecordsUrl) {
                this.oldNextRecordsUrl = previousNextRecordsUrl;
            }

            this.nextRecordsUrl = result.nextRecordsUrl || '';
            this.filteredData = [...this.userDataforDatatable];
            this.updatePaginationControls();
            this.totalRecordsUSER = result.totalRecords || 0;
            this.updatePreselectedRowsForUsers();
        } catch (error) {
            console.error('Error in getFilteredData:', error);
            throw error;
        } finally {
            this.showSpinnerForFilter = false;
        }
    }

    get isPlaceholderData() {
        return this.userDataforDatatable.length === 1 && this.userDataforDatatable[0]._isPlaceholder;
    }

    // Main table pagination handlers
    handlePreviousAvailUSR() {
        if (this.pageNumberUsers > 1) {
            this.pageNumberUsers--;
            if (this.pageNumberUsers === 1) {
                if (this.filterLetter || this.searchTerm) {
                    this.pageNumberUsers = 1;
                    this.allData = [];
                    this.oldNextRecordsUrl = null;
                    this.nextRecordsUrl = '';
                    this.getFilteredData(this.searchTerm, this.filterLetter)
                        .then(() => {
                            this.updatePreselectedRowsForUsers();
                        });
                    return;
                } else {
                    this.nextRecordsUrl = null;
                }
            } else {
                const currentUrl = this.oldNextRecordsUrl;
                if (currentUrl) {
                    const baseUrl = currentUrl.substring(0, currentUrl.lastIndexOf('-') + 1);
                    const currentOffset = parseInt(currentUrl.split('-').pop(), 10);
                    const newOffset = currentOffset - 2000;
                    this.nextRecordsUrl = newOffset > 0 ? `${baseUrl}${newOffset}` : null;
                }
            }

            this.oldNextRecordsUrl = this.nextRecordsUrl;
            this.fetchAllDataComponents('Users');
            this.updatePaginationControls();
        }
    }

    handleNextAvailUSR() {
        if (this.nextRecordsUrl) {
            this.allData.push({
                nextRecordsUrl: this.nextRecordsUrl,
                currentPageData: [...this.filteredData]
            });
            this.pageNo++;
            this.oldNextRecordsUrl = this.nextRecordsUrl;
            this.pageNumberUsers++;
            this.fetchAllDataComponents('Users');
            this.updatePaginationControls();
        }
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortDirection = sortDirection;

        // Clone the data for sorting
        let clonedData = [...this.filteredData];

        // Sort the data
        clonedData.sort((a, b) => {
            let valueA = a[sortedBy] || '';
            let valueB = b[sortedBy] || '';

            valueA = typeof valueA === 'string' ? valueA.toLowerCase() : valueA;
            valueB = typeof valueB === 'string' ? valueB.toLowerCase() : valueB;

            let sortResult = valueA > valueB ? 1 : -1;

            return sortDirection === 'desc' ? -sortResult : sortResult;
        });

        this.filteredData = clonedData;
    }

    handleSelectedTableSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.selectedTableSortedBy = sortedBy;
        this.selectedTableSortDirection = sortDirection;

        // Store current selections
        const currentSelections = new Set(this.selectedTableRows);

        // Update sort parameters without modifying the data structure
        this.refreshSelectedTableData();

        // After refresh, restore selections
        this.selectedTableRows = [...currentSelections];

        // Ensure all rows on the current page are marked as selected
        const currentPageUsernames = this.paginatedSelectedDataUser.map(row => row.Username);
        this.selectedTableRows = currentPageUsernames.filter(username =>
            this.selectedUserMap[username] !== undefined
        );
    }

    // Add these handlers for Selected Users table
    handleSelectedTableFirst() {
        if (!this.isSelectedFirstDisabled) {
            // Store current selections
            const currentSelections = this.paginatedSelectedDataUser.map(row => row.Username);

            // Move to first page
            this.selectedTablePage = 1;

            // After page change, mark all rows as selected
            this.selectedTableRows = this.paginatedSelectedDataUser.map(row => row.Username);
        }
    }

    handleSelectedTableLast() {
        if (!this.isSelectedLastDisabled) {
            // Store current selections
            const currentSelections = this.paginatedSelectedDataUser.map(row => row.Username);

            // Move to last page
            this.selectedTablePage = this.totalPagesselUSR;

            // After page change, mark all rows as selected
            this.selectedTableRows = this.paginatedSelectedDataUser.map(row => row.Username);
        }
    }

    // Add these getters for button disable conditions
    get isSelectedFirstDisabled() {
        return this.selectedTablePage <= 1;
    }

    get isSelectedLastDisabled() {
        return this.selectedTablePage >= this.totalPagesselUSR;
    }

    /*User end*/


    /*Custom settings */
    // Track variables for available custom settings table
    @track customSettingsDataforDatatable = [];
    @track currentPageAvailCS = 1;
    @track pageSizeCS = 5;
    @track searchTermavailCus = '';
    @track sortedByAvCS = 'customSettingName';
    @track sortedDirectionAvCS = 'asc';
    @track customSettingsSelectedRows = new Set();
    @track selectedCustomSettings = [];
    @track preselectedCS = [];
    @track selectedcustomSelectedRows = [];
    @track isSelectedCustomSettingsEmpty = true;
    @track showSpinnerInsideAccordionsData = false;
    @track showCustomSettingsDatatable = false;

    // Properties for selected custom settings table
    @track selectedCurrentPageCS = 1;
    @track selectedPageSizeCS = 5;
    @track searchTermselCus = '';
    @track selectedSortedBy = 'customSettingName';
    @track selectedSortedDirectionCS = 'asc';

    // Page size options for both tables
    pageSizeOptionsavailCs = [5, 10, 25, 50];
    pageSizeOptionsselCs = [5, 10, 25, 50];

    // Filter methods for both tables
    filterAvailableData() {
        let filteredData = [...this.customSettingsDataforDatatable];

        // Apply search filter
        if (this.searchTermavailCus) {
            const searchTerm = this.searchTermavailCus.toLowerCase();
            filteredData = filteredData.filter(setting =>
                setting.customSettingName.toLowerCase().includes(searchTerm)
            );
        }

        // Apply sorting
        if (this.sortedByAvCS) {
            filteredData.sort((a, b) => {
                let val1 = a[this.sortedByAvCS] || '';
                let val2 = b[this.sortedByAvCS] || '';

                val1 = typeof val1 === 'string' ? val1.toLowerCase() : val1;
                val2 = typeof val2 === 'string' ? val2.toLowerCase() : val2;

                const sortMultiplier = this.sortedDirectionAvCS === 'asc' ? 1 : -1;
                return val1 > val2 ? sortMultiplier : -sortMultiplier;
            });
        }

        return filteredData;
    }

    filterSelectedData() {
        let filteredData = [...this.selectedCustomSettings];

        if (this.searchTermselCus) {
            const searchTerm = this.searchTermselCus.toLowerCase();
            filteredData = filteredData.filter(setting =>
                setting.customSettingName.toLowerCase().includes(searchTerm)
            );
        }

        if (this.selectedSortedBy) {
            filteredData = [...filteredData].sort((a, b) => {
                let val1 = a[this.selectedSortedBy] || '';
                let val2 = b[this.selectedSortedBy] || '';

                val1 = typeof val1 === 'string' ? val1.toLowerCase() : val1;
                val2 = typeof val2 === 'string' ? val2.toLowerCase() : val2;

                if (val1 < val2) return this.selectedSortedDirectionCS === 'asc' ? -1 : 1;
                if (val1 > val2) return this.selectedSortedDirectionCS === 'asc' ? 1 : -1;
                return 0;
            });
        }

        return filteredData;
    }

    // Getters for paginated data
    get paginatedAvailableData() {
        const filteredData = this.filterAvailableData();
        const startIndex = (this.currentPageAvailCS - 1) * this.pageSizeCS;
        const endIndex = Math.min(startIndex + this.pageSizeCS, filteredData.length);
        return filteredData.slice(startIndex, endIndex);
    }

    get paginatedSelectedDataCs() {
        const filteredData = this.filterSelectedData();
        const startIndex = (this.selectedCurrentPageCS - 1) * this.selectedPageSizeCS;
        const endIndex = startIndex + this.selectedPageSizeCS;
        return filteredData.slice(startIndex, endIndex);
    }
    get isSelectedCustomSettingsEmpty() {
        return !this.selectedCustomSettings || this.selectedCustomSettings.length === 0;
    }

    handleRowSelectionForCustomSettings(event) {
        try {
            const selectedRows = event.detail.selectedRows;
            const currentPageRows = this.paginatedAvailableData;

            // Update selections based on current page
            currentPageRows.forEach(row => {
                const isSelected = selectedRows.some(
                    selected => selected.customSettingName === row.customSettingName
                );
                if (isSelected) {
                    this.customSettingsSelectedRows.add(row.customSettingName);
                } else {
                    this.customSettingsSelectedRows.delete(row.customSettingName);
                }
            });

            // Transform for template format
            this.selectedCustomSettings = Array.from(this.customSettingsSelectedRows).map(name => ({
                id: name,
                type: 'Custom Settings',
                formattedString: name
            }));

            // Update selected data and UI
            this.updateSelectedCustomSettingsData();
            this.updatePreselectedRowsForCS();

            // Update list for backend
            this.customSettingNamesList = Array.from(this.customSettingsSelectedRows);

        } catch (error) {
            console.error('Error in custom settings selection:', error);
        }
    }

    handleDeselectionselCus(event) {
        const selectedRows = event.detail.selectedRows;
        const currentSelectedPageRows = this.paginatedSelectedDataCs;

        currentSelectedPageRows.forEach(row => {
            const isStillSelected = selectedRows.some(
                selected => selected.customSettingName === row.customSettingName
            );
            if (!isStillSelected) {
                this.customSettingsSelectedRows.delete(row.customSettingName);
            }
        });

        this.updateSelectedCustomSettingsData();
        // Check if current page is now invalid after deselection
        const totalSelectedPagesCS = Math.ceil(this.selectedCustomSettings.length / this.selectedPageSizeCS);
        if (this.selectedCurrentPageCS > totalSelectedPagesCS && totalSelectedPagesCS > 0) {
            // If current page is now invalid, move to the last valid page
            this.selectedCurrentPageCS = totalSelectedPagesCS;
        }
        this.updatePreselectedRowsForCS();
        // Update list for backend
        this.customSettingNamesList = Array.from(this.customSettingsSelectedRows);
    }

    // Update methods for selections
    updateSelectedCustomSettingsData() {
        this.selectedCustomSettings = this.customSettingsDataforDatatable
            .filter(setting => this.customSettingsSelectedRows.has(setting.customSettingName));
        this.isSelectedCustomSettingsEmpty = this.customSettingsSelectedRows.size === 0;
    }

    updatePreselectedRowsForCS() {
        this.preselectedCS = this.paginatedAvailableData
            .filter(row => this.customSettingsSelectedRows.has(row.customSettingName))
            .map(row => row.customSettingName);

        this.selectedcustomSelectedRows = this.paginatedSelectedDataCs
            .map(row => row.customSettingName);
    }

    // Pagination getters
    get totalPagesAvailCS() {
        const totalRecords = this.filterAvailableData().length;
        return Math.ceil(totalRecords / this.pageSizeCS);
    }

    get totalSelectedPagesCS() {
        const filteredData = this.filterSelectedData();
        return Math.ceil(filteredData.length / this.selectedPageSizeCS) || 1;
    }

    get isPreviousDisabledavilCS() {
        return this.currentPageAvailCS <= 1;
    }

    get isNextDisabledavilCS() {
        return this.currentPageAvailCS >= this.totalPagesAvailCS;
    }

    get isSelectedPreviousDisabledCS() {
        return this.selectedCurrentPageCS <= 1;
    }

    get isSelectedNextDisabledCS() {
        return this.selectedCurrentPageCS >= this.totalSelectedPagesCS;
    }

    get totalRecordscustom() {
        return this.customSettingsDataforDatatable?.length || 0;
    }

    // Event handlers for pagination
    handlePageSizeChangeAvlCus(event) {
        const newPageSize = parseInt(event.target.value, 10);
        // Store current selections
        const currentSelections = new Set(this.customSettingsSelectedRows);

        // Update page size and reset to first page
        this.pageSizeCS = newPageSize;
        this.currentPageAvailCS = 1;

        // Restore selections
        this.customSettingsSelectedRows = currentSelections;

        // Update tables
        this.updateSelectedCustomSettingsData();
        this.updatePreselectedRowsForCS();
    }

    handleSelectedPageSizeChangeSelCS(event) {
        const newPageSize = parseInt(event.target.value, 10);
        this.selectedPageSizeCS = newPageSize;
        this.selectedCurrentPageCS = 1;
        this.updatePreselectedRowsForCS();
    }

    handlePreviousavailCS() {
        if (this.currentPageAvailCS > 1) {
            this.currentPageAvailCS--;
            this.updatePreselectedRowsForCS();
        }
    }

    handleNextavailCS() {
        if (this.currentPageAvailCS < this.totalPagesAvailCS) {
            this.currentPageAvailCS++;
            this.updatePreselectedRowsForCS();
        }
    }
    handleSelectedPreviousCS() {
        if (!this.isSelectedPreviousDisabledCS) {
            this.selectedCurrentPageCS -= 1;
            this.updatePreselectedRowsForCS();
        }
    }

    handleSelectedNextCS() {
        if (!this.isSelectedNextDisabledCS) {
            this.selectedCurrentPageCS += 1;
            this.updatePreselectedRowsForCS();
        }
    }

    // Search handlers
    handleSearchavailCus(event) {
        this.searchTermavailCus = event.target.value;
        // Reset to first page when searching
        this.currentPageAvailCS = 1;
        this.updatePreselectedRowsForCS();
    }

    handleSearchselCus(event) {
        this.searchTermselCus = event.target.value;
        this.selectedCurrentPageCS = 1;
        this.updatePreselectedRowsForCS();
    }

    // Sort handlers
    // Sort handlers for available custom settings table
    handleSortavailCus(event) {
        // Store current selections before sorting
        const currentSelections = new Set(this.customSettingsSelectedRows);

        this.sortedByAvCS = event.detail.fieldName;
        this.sortedDirectionAvCS = event.detail.sortDirection;

        // After sorting, ensure preselected rows are updated
        this.customSettingsSelectedRows = currentSelections;
        this.updatePreselectedRowsForCS();
    }

    // Sort handler for selected custom settings table
    handleSelectedSortCS(event) {
        // Store current page selections
        const currentPageSelections = new Set(this.selectedcustomSelectedRows);

        this.selectedSortedBy = event.detail.fieldName;
        this.selectedSortedDirectionCS = event.detail.sortDirection;

        // After sorting, restore selections for current page
        this.selectedcustomSelectedRows = Array.from(currentPageSelections);
        this.updatePreselectedRowsForCS();
    }

    handleFirstsavailCS() {
        if (!this.isFirstDisabledavilCS) {
            this.currentPageAvailCS = 1;
            this.updatePreselectedRowsForCS();
        }
    }

    handleLastavailCS() {
        if (!this.isLasrDisabledavilCS) {
            this.currentPageAvailCS = this.totalPagesAvailCS;
            this.updatePreselectedRowsForCS();
        }
    }

    handleSelectedFirstCS() {
        if (!this.isSelectedFirstDisabledCS) {
            this.selectedCurrentPageCS = 1;
            this.updatePreselectedRowsForCS();
        }
    }

    handleSelectedLastCS() {
        if (!this.isSelectedLastDisabledCS) {
            this.selectedCurrentPageCS = this.totalSelectedPagesCS;
            this.updatePreselectedRowsForCS();
        }
    }

    // Add these getters for button disable conditions
    get isFirstDisabledavilCS() {
        return this.currentPageAvailCS <= 1;
    }

    get isLasrDisabledavilCS() {
        return this.currentPageAvailCS >= this.totalPagesAvailCS;
    }

    get isSelectedFirstDisabledCS() {
        return this.selectedCurrentPageCS <= 1;
    }

    get isSelectedLastDisabledCS() {
        return this.selectedCurrentPageCS >= this.totalSelectedPagesCS;
    }

    /*end custom settings*/

    /** schedulejobs*/
    @track currentPageSJ = 1;
    @track pageSizeSJ = 5;
    @track searchTermSJ = '';
    @track sortBySJ;
    @track sortDirectionSJ = 'asc';
    @track selectedCurrentPageSJ = 1;
    @track selectedPageSizeSJ = 5;
    @track searchTermSelectedSJ = '';
    @track selectedScheduledJobs = [];
    @track preselectedSJ = [];
    @track selectedRows = new Set(); // To maintain all selected rows across pages
    @track scheduleSelectedRows = new Set(); // For selected table selections
    @track selectedJobsTableData = [];
    @track selectedTablePreselectedRows = [];
    @track showSpinnerInsideAccordionsData = false;

    // Page size options
    pageSizeOptionsASJ = [5, 10, 25, 50];
    pageSizeOptionsSSJ = [5, 10, 25, 50];
    @track selectedSortedBy;
    @track selectedSortedDirection = 'asc';

    get paginatedScheduledJobsData() {
        let filteredData = this.scheduledJobsDataforDatatable;

        if (this.searchTermSJ) {
            const searchTerm = this.searchTermSJ.toLowerCase();
            filteredData = filteredData.filter(job =>
                job.jobName?.toLowerCase().includes(searchTerm) ||
                job.jobType?.toLowerCase().includes(searchTerm) ||
                job.apexClassName?.toLowerCase().includes(searchTerm) ||
                job.cronExpression?.toLowerCase().includes(searchTerm)
            );
        }

        if (this.sortBySJ) {
            filteredData = [...filteredData].sort((a, b) => {
                let val1 = a[this.sortBySJ] || '';
                let val2 = b[this.sortBySJ] || '';

                val1 = typeof val1 === 'string' ? val1.toLowerCase() : val1;
                val2 = typeof val2 === 'string' ? val2.toLowerCase() : val2;

                if (val1 < val2) return this.sortDirectionSJ === 'asc' ? -1 : 1;
                if (val1 > val2) return this.sortDirectionSJ === 'asc' ? 1 : -1;
                return 0;
            });
        }

        const startIndex = (this.currentPageSJ - 1) * this.pageSizeSJ;
        const endIndex = startIndex + this.pageSizeSJ;

        return filteredData.slice(startIndex, endIndex);
    }

    handleRowSelectionForScheduledJobs(event) {
        try {
            const selectedRows = event.detail.selectedRows;
            const currentPageRows = this.paginatedScheduledJobsData;

            // Track which rows were selected/deselected on current page
            currentPageRows.forEach(row => {
                const isSelected = selectedRows.some(selected => selected.jobName === row.jobName);
                if (isSelected) {
                    this.selectedRows.add(row.jobName);
                } else {
                    this.selectedRows.delete(row.jobName);
                }
            });

            // Transform for template format
            // Transform selected rows directly for template format
            this.selectedScheduledJobs = selectedRows.map(job => ({
                id: job.jobName,
                type: 'Scheduled Jobs',
                formattedString: `Job Name: ${job.jobName}, Job Type: ${job.jobType}, Apex Class: ${job.apexClassName}, Cron Expression: ${job.cronExpression}`
            }));



            // Update both tables
            this.updateSelectedJobsData();
            this.updatePreselectedRows();

        } catch (error) {
            console.error('Error in scheduled jobs selection:', error);
        }
    }

    // Helper method to get selected rows for current page
    getSelectedRowsForPage(data) {
        return data
            .filter(row => this.selectedRows.has(row.jobName))
            .map(row => row.jobName);
    }

    handleDeselection(event) {
        const selectedRowsFromDeselectionTable = event.detail.selectedRows;
        const currentSelectedPageRows = this.paginatedSelectedJobsData;

        // Update selectedRows Set based on deselections
        currentSelectedPageRows.forEach(row => {
            const isStillSelected = selectedRowsFromDeselectionTable.some(
                selected => selected.jobName === row.jobName
            );
            if (!isStillSelected) {
                this.selectedRows.delete(row.jobName);
            }
        });

        // Update both tables
        this.updateSelectedJobsData();
        // Check if current page is now invalid after deselection
        const totalSelectedPagesSJ = Math.ceil(this.selectedJobsTableData.length / this.selectedPageSizeSJ);
        if (this.selectedCurrentPageSJ > totalSelectedPagesSJ && totalSelectedPagesSJ > 0) {
            // If current page is now invalid, move to the last valid page
            this.selectedCurrentPageSJ = totalSelectedPagesSJ;
        }

        this.updatePreselectedRows();
    }

    updatePreselectedRows() {
        // Update main table preselected rows
        this.preselectedSJ = this.getSelectedRowsForPage(this.paginatedScheduledJobsData);

        // Update selected table preselected rows
        const selectedPageData = this.paginatedSelectedJobsData;
        this.selectedTablePreselectedRows = selectedPageData.map(row => row.jobName);
    }

    updateSelectedJobsData() {
        // Get full data for selected jobs
        const allSelectedJobs = this.scheduledJobsDataforDatatable
            .filter(job => this.selectedRows.has(job.jobName))
            .map(job => ({
                ...job,  // Preserve all original properties
                type: 'Scheduled Jobs',
                selected: true
            }));

        this.selectedJobsTableData = allSelectedJobs;
        this.isSelectedScheduledJobsEmpty = this.selectedRows.size === 0;
    }

    get paginatedSelectedJobsData() {
        let filteredData = this.selectedJobsTableData;

        if (this.searchTermSelectedSJ) {
            const searchTerm = this.searchTermSelectedSJ.toLowerCase();
            filteredData = filteredData.filter(job =>
                job.jobName?.toLowerCase().includes(searchTerm) ||
                job.jobType?.toLowerCase().includes(searchTerm) ||
                job.apexClassName?.toLowerCase().includes(searchTerm) ||
                job.cronExpression?.toLowerCase().includes(searchTerm)
            );
        }

        // Apply sorting to selected table
        if (this.selectedSortedBy) {
            filteredData = [...filteredData].sort((a, b) => {
                let val1 = a[this.selectedSortedBy] || '';
                let val2 = b[this.selectedSortedBy] || '';

                val1 = typeof val1 === 'string' ? val1.toLowerCase() : val1;
                val2 = typeof val2 === 'string' ? val2.toLowerCase() : val2;

                if (val1 < val2) return this.selectedSortedDirection === 'asc' ? -1 : 1;
                if (val1 > val2) return this.selectedSortedDirection === 'asc' ? 1 : -1;
                return 0;
            });
        }

        const startIndex = (this.selectedCurrentPageSJ - 1) * this.selectedPageSizeSJ;
        const endIndex = startIndex + this.selectedPageSizeSJ;

        return filteredData.slice(startIndex, endIndex);
    }

    // Computed properties for pagination controls
    get totalPagesSJ() {
        const filteredData = this.scheduledJobsDataforDatatable.filter(job => {
            if (!this.searchTermSJ) return true;
            const searchTerm = this.searchTermSJ.toLowerCase();
            return job.jobName?.toLowerCase().includes(searchTerm) ||
                job.jobType?.toLowerCase().includes(searchTerm) ||
                job.apexClassName?.toLowerCase().includes(searchTerm) ||
                job.cronExpression?.toLowerCase().includes(searchTerm);
        });
        return Math.ceil(filteredData.length / this.pageSizeSJ);
    }

    updatePreselectedRowsForSJ() {
        this.preselectedSJ = this.selectedScheduledJobs.map(job => job.jobName);
        console.log('Preselected Scheduled Jobs:', JSON.stringify(this.preselectedSJ));
    }

    get totalSelectedPagesSJ() {
        const filteredData = this.selectedJobsTableData.filter(job => {
            if (!this.searchTermSelectedSJ) return true;
            const searchTerm = this.searchTermSelectedSJ.toLowerCase();
            return job.jobName?.toLowerCase().includes(searchTerm) ||
                job.jobType?.toLowerCase().includes(searchTerm) ||
                job.apexClassName?.toLowerCase().includes(searchTerm) ||
                job.cronExpression?.toLowerCase().includes(searchTerm);
        });
        return Math.ceil(filteredData.length / this.selectedPageSizeSJ);
    }

    get isPreviousDisabledSJ() {
        return this.currentPageSJ <= 1;
    }

    get isNextDisabledSJ() {
        return this.currentPageSJ >= this.totalPagesSJ;
    }

    get isSelectedPreviousDisabledSJ() {
        return this.selectedCurrentPageSJ <= 1;
    }

    get isSelectedNextDisabledSJ() {
        return this.selectedCurrentPageSJ >= this.totalSelectedPagesSJ;
    }
    get isSelectedScheduledJobsEmpty() {
        return !this.selectedScheduledJobs || this.selectedScheduledJobs.length === 0;
    }

    // Event handlers
    handleSearchSJ(event) {
        // Store current selections before searching
        const currentSelections = new Set(this.selectedRows);

        // Update search term and reset to first page
        this.searchTermSJ = event.target.value;
        this.currentPageSJ = 1;

        // Restore selections
        this.selectedRows = currentSelections;

        // Update preselected rows for the current page
        this.updatePreselectedRows();
    }

    handleSearchSelectedSJ(event) {
        this.searchTermSelectedSJ = event.target.value;
        this.selectedCurrentPageSJ = 1;
        this.updateSelectedJobsData();
        this.updatePreselectedRows();
    }

    handleSortSJ(event) {
        // Store current selections before sorting
        const currentSelections = new Set(this.selectedRows);

        // Update sort parameters
        this.sortBySJ = event.detail.fieldName;
        this.sortDirectionSJ = event.detail.sortDirection;

        // Restore selections
        this.selectedRows = currentSelections;

        // Update preselected rows for the current page
        this.updatePreselectedRows();
    }

    handleSelectedSort(event) {
        this.selectedSortedBy = event.detail.fieldName;
        this.selectedSortedDirection = event.detail.sortDirection;
        this.updateSelectedJobsData();
        this.updatePreselectedRows();
    }

    handlePageSizeSJ(event) {
        const newPageSize = parseInt(event.target.value, 10);

        // Store current selections before changing page size
        const currentSelections = new Set(this.selectedRows);

        // Update page size and reset to first page
        this.pageSizeSJ = newPageSize;
        this.currentPageSJ = 1;

        // Restore selections
        this.selectedRows = currentSelections;

        // Update both tables
        this.updateSelectedJobsData();
        this.updatePreselectedRows();

        // Force checkbox refresh for current page
        this.preselectedSJ = this.getSelectedRowsForPage(this.paginatedScheduledJobsData);
    }

    handleSelectedPageSizeSJ(event) {
        const newPageSize = parseInt(event.target.value, 10);

        // Store current selections before changing page size
        const currentSelections = new Set(this.selectedRows);

        // Update page size and reset to first page
        this.selectedPageSizeSJ = newPageSize;
        this.selectedCurrentPageSJ = 1;

        // Restore selections
        this.selectedRows = currentSelections;

        // Update both tables
        this.updateSelectedJobsData();
        this.updatePreselectedRows();

        // Force checkbox refresh for selected table
        this.selectedTablePreselectedRows = this.paginatedSelectedJobsData.map(row => row.jobName);
    }

    handlePreviousSJ() {
        if (!this.isPreviousDisabledSJ) {
            this.currentPageSJ -= 1;
            this.updatePreselectedRows();
        }
    }

    handleNextSJ() {
        if (!this.isNextDisabledSJ) {
            this.currentPageSJ += 1;
            this.updatePreselectedRows();
        }
    }

    handleSelectedPreviousSJ() {
        if (!this.isSelectedPreviousDisabledSJ) {
            this.selectedCurrentPageSJ -= 1;
            this.updatePreselectedRows();
        }
    }

    handleSelectedNextSJ() {
        if (!this.isSelectedNextDisabledSJ) {
            this.selectedCurrentPageSJ += 1;
            this.updatePreselectedRows();
        }
    }

    handleFirstSJ() {
        if (!this.isFirstDisabledSJ) {
            this.currentPageSJ = 1;
            this.updatePreselectedRows();
        }
    }

    handleLastSJ() {
        if (!this.isLastDisabledSJ) {
            this.currentPageSJ = this.totalPagesSJ;
            this.updatePreselectedRows();
        }
    }

    // Add these handlers for Selected Scheduled Jobs
    handleSelectedFirstSJ() {
        if (!this.isSelectedFirstDisabledSJ) {
            this.selectedCurrentPageSJ = 1;
            this.updatePreselectedRows();
        }
    }

    handleSelectedLastSJ() {
        if (!this.isSelectedLastDisabledSJ) {
            this.selectedCurrentPageSJ = this.totalSelectedPagesSJ;
            this.updatePreselectedRows();
        }
    }

    // Add these getters for button disable conditions
    get isFirstDisabledSJ() {
        return this.currentPageSJ <= 1;
    }

    get isLastDisabledSJ() {
        return this.currentPageSJ >= this.totalPagesSJ;
    }

    get isSelectedFirstDisabledSJ() {
        return this.selectedCurrentPageSJ <= 1;
    }

    get isSelectedLastDisabledSJ() {
        return this.selectedCurrentPageSJ >= this.totalSelectedPagesSJ;
    }
    /*end**/


    get isFilteredDataEmpty() {
        // Check if the original data is empty (no users from the org)
        return (!this.userDataforDatatable || this.userDataforDatatable.length === 0) &&
            (!this.searchTerm && !this.filterLetter);
    }

    get isAvailableCustomSettingsEmpty() {
        return !this.customSettingsDataforDatatable || this.customSettingsDataforDatatable.length === 0;
    }

    get isAvailableScheduledJobsEmpty() {
        return !this.scheduledJobsDataforDatatable || this.scheduledJobsDataforDatatable.length === 0;
    }

    /****************** END OF DATA PICKER CODE BLOCK FOR CREATE NEW TEMPLATE ******************/


    /****************** FIND AND REPLACE PAGE CODE BLOCK ******************/

    @track showFindAndReplacePage = false;
    @track isDataPicker = false;
    @track showCreateTemplatePage = false;
    @track showSpinnerNavigation = false;
    @track isShowModalForFindAndReplaceValidation = false;
    @track selectedData = '';
    @track previousSelectedMaskingType = '';

    // Form fields
    @track selectedMaskingType = '';
    @track showSearchAndReplace = false;
    @track showSuffix = false;
    @track selectedMetadataTypesForFindAndReplace = [];
    @track searchKey = '';
    @track replaceValue = '';
    @track suffixValue = '';

    // Data tables and rules
    @track findAndReplaceRules = [];
    @track findAndReplaceRulesForBackend = [];
    @track findAndReplaceColumns = findAndReplaceColumns;
    @track suffixColumns = suffixColumns;

    // Pagination properties
    @track pageSize = 5;
    @track pageSizeRules = 5;
    @track pageSizeSuffix = 5;
    @track currentPage = 1;
    @track currentPageRules = 1;
    @track currentPageSuffix = 1;
    @track totalPages = 0;
    @track totalPagesRules = 0;
    @track totalPagesSuffix = 0;
    @track searchTermRules = '';
    @track searchTermSuffix = '';
    @track sortedBySearch = '';
    @track sortDirectionSearch = 'asc';
    @track sortedBySuffix = '';
    @track sortDirectionSuffix = 'asc';
    @track paginatedData = [];
    @track hasSearchAndReplaceRules = false;
    @track hasSuffixRules = false;
    @track paginatedSearchAndReplaceData = [];
    @track paginatedSuffixData = [];
    @track isViewingFinalScreen = false;
    @track hasSelectedMetadataTypes = false;
    @track selectedMetadataTypesForSearch = [];
    @track selectedMetadataTypesForSuffix = [];
    @track hasSelectedMetadataTypesSearch = false;
    @track hasSelectedMetadataTypesSuffix = false;
    @track isShowModalForApexscriptValidation = false;
    @track isShowModalForSuffixValidation = false;
    @track isShowModalForFindAndReplaceValidationfortheallselection = false;

    // Component options getters
    get pageSizeOptionsrules() {
        return [5, 10, 25, 50];
    }

    get pageSizeOptionssuffix() {
        return [5, 10, 25, 50];
    }

    get metadataOptionsForFindAndReplace() {
        return [
            { label: 'Auth. Providers', value: 'AuthProvider' },
            { label: 'Custom Labels', value: 'CustomLabel' },
            { label: 'Custom Metadata', value: 'CustomMetadata' },
            { label: 'Named Credentials', value: 'NamedCredential' },
            { label: 'Remote Site Settings', value: 'RemoteSiteSetting' },
            { label: 'Workflow Alerts', value: 'WorkflowAlert' }
        ];
    }

    get metadataOptionsForSuffix() {
        return [
            { label: 'Custom Labels', value: 'CustomLabel' },
            { label: 'Connected App', value: 'ConnectedApp' },
            { label: 'Custom Metadata', value: 'CustomMetadata' },
            { label: 'Email Service', value: 'EmailServicesFunction' },
            { label: 'Workflow Alerts', value: 'WorkflowAlert' }
        ];
    }

    get maskingTypeOptions() {
        return [
            { label: 'Search & Replace', value: 'Search & Replace' },
            { label: 'Suffix', value: 'Suffix' },
            { label: 'Apex Script', value: 'Apex Script' },
        ];
    }

    getSelectedMetadataTypes() {
        return this.selectedMaskingType === 'Search & Replace'
            ? this.selectedMetadataTypesForSearch
            : this.selectedMetadataTypesForSuffix;
    }

    // Pagination computed properties
    get isFirstPagerules() {
        return this.currentPageRules === 1;
    }

    get isLastPagerules() {
        return this.currentPageRules === this.totalPagesRules;
    }

    get isFirstPagesuffix() {
        return this.currentPageSuffix === 1;
    }

    get isLastPagesuffix() {
        return this.currentPageSuffix === this.totalPagesSuffix;
    }

    get selectedCurrentPagerules() {
        return this.currentPageRules;
    }

    get totalSelectedPagesrules() {
        return this.totalPagesRules;
    }

    get selectedCurrentPagesuffix() {
        return this.currentPageSuffix;
    }

    get totalSelectedPagessuffix() {
        return this.totalPagesSuffix;
    }

    get totalRecordsrules() {
        if (this.showCreateTemplatePage) {
            // If we're on the final screen, always count Search & Replace rules
            return this.findAndReplaceRulesForBackend.filter(
                rule => rule.maskingType === 'Search & Replace'
            ).length;
        }
        // During creation, show filtered view
        return this.findAndReplaceRules.filter(
            rule => rule.maskingType === 'Search & Replace'
        ).length;
    }

    get totalRecordssuffix() {
        if (this.showCreateTemplatePage) {
            // If we're on the final screen, always count Suffix rules
            return this.findAndReplaceRulesForBackend.filter(
                rule => rule.maskingType === 'Suffix'
            ).length;
        }
        // During creation, show filtered view
        return this.findAndReplaceRules.filter(
            rule => rule.maskingType === 'Suffix'
        ).length;
    }

    handleBackFromFindAndReplacePage() {
        this.showOnPageLoad = false;
        this.isMetadataPicker = true;
        this.showFindAndReplacePage = false;
        this.isDataPicker = false;
        this.showUsersDatatable = false;
        this.showCustomSettingsDatatable = false;
        this.showScheduledJobsDatatable = false;
        this.showSpinnerNavigation = false;
        console.log('Filters reset on Back button click.');
    }

    handleNextFromFindAndReplacePage() {
        // Reset search terms
        this.searchTermRules = '';
        this.searchTermSuffix = '';
        this.searchTermapexScript = '';

        // Reset page sizes to default
        this.pageSizeRules = 5;
        this.pageSizeSuffix = 5;
        this.pageSizeApex = 5;

        // Reset current pages to first page
        this.currentPageRules = 1;
        this.currentPageSuffix = 1;
        this.currentPageApex = 1;

        this.previousSelectedMaskingType = this.selectedMaskingType;
        this.updateSearchAndReplaceTable();
        this.updateSuffixTable();

        if (this.selectedMaskingType === 'Search & Replace') {
            if (this.searchKey && !this.replaceValue) {
                // Show popup if replace value is missing
                this.isShowModalForFindAndReplaceValidation = true;
                this.showSuffix = false;
                return;
            } else if (this.searchKey && this.replaceValue) {
                // Clear form if both values are present
                this.isShowModalForFindAndReplaceValidationfortheallselection = true;
                this.showSuffix = false;
                return;
                //this.resetForm();
            }
        }

        // Check for unsaved changes in Suffix
        if (this.selectedMaskingType === 'Suffix') {
            // Check if user selected metadata types and entered suffix value but didn't create a rule
            if (this.hasSelectedMetadataTypesSuffix && this.suffixValue) {
                this.isShowModalForSuffixValidation = true;
                return;
            }
        }

        // Check for unsaved changes in Apex Script
        if (this.selectedMaskingType === 'Apex Script') {
            // Check if user entered any script details but didn't add the script
            if (this.newScriptOrder || this.newScriptName || this.newScriptDetails) {
                this.isShowModalForApexscriptValidation = true;
                return;
            }
        }

        // If no unsaved changes, proceed to the next page
        this.showFindAndReplacePage = false;
        this.isDataPicker = true;
    }


    // Handlers for Apex Script modal
    handleYesInApexScriptModal() {
        console.log('m handleYesInApexScriptModal');
        this.isShowModalForApexscriptValidation = false;
        this.showFindAndReplacePage = false;
        this.isDataPicker = true;
        this.showMetadataRetrievePageForEditTemplate = false;
        this.resetForm();
    }

    handleNoInApexScriptModal() {
        console.log('m handleNoInApexScriptModal');
        this.isShowModalForApexscriptValidation = false;
        this.showFindAndReplacePage = true;
        this.isDataPicker = false;
        this.showMetadataRetrievePageForEditTemplate = false;
        // Stay on the current page
    }

    // Handlers for Suffix modal
    handleYesInSuffixModal() {
        this.isShowModalForSuffixValidation = false;
        this.showFindAndReplacePage = false;
        this.isDataPicker = true;
        this.showMetadataRetrievePageForEditTemplate = false;
        this.resetForm(); // Clear form fields
    }

    handleNoInSuffixModal() {
        this.isShowModalForSuffixValidation = false;
        this.showFindAndReplacePage = true;
        this.isDataPicker = false;
        this.showMetadataRetrievePageForEditTemplate = false;
        // Stay on the current page
    }

    handleYesInFindAndReplaceModal() {
        this.isShowModalForFindAndReplaceValidation = false;
        this.isShowModalForFindAndReplaceValidationfortheallselection = false;
        this.showFindAndReplacePage = false;
        this.isDataPicker = true;
        this.showMetadataRetrievePageForEditTemplate = false;
        this.resetForm();
    }

    handleNoInFindAndReplaceModal() {
        this.isShowModalForFindAndReplaceValidation = false;
        this.isShowModalForFindAndReplaceValidationfortheallselection = false;
        this.showFindAndReplacePage = true;
        this.isDataPicker = false;
        this.showMetadataRetrievePageForEditTemplate = false;
    }

    // Form Event Handlers
    handleMaskingType(event) {
        const selectedValue = event.target.value;
        this.selectedMaskingType = selectedValue;

        // Only update visibility during rule creation
        if (!this.showCreateTemplatePage) {
            if (this.selectedMaskingType === 'Search & Replace') {
                this.showSearchAndReplace = true;
                this.showSuffix = false;
                this.showapexScript = false;
                this.selectedMetadataTypesForSuffix = [];
                this.hasSelectedMetadataTypesSuffix = false;
            } else if (this.selectedMaskingType === 'Suffix') {
                this.showSearchAndReplace = false;
                this.showSuffix = true;
                this.showapexScript = false;
                this.selectedMetadataTypesForSearch = [];
                this.hasSelectedMetadataTypesSearch = false;
            } else if (this.selectedMaskingType === 'Apex Script') {
                this.showapexScript = true;
                this.showSearchAndReplace = false;
                this.showSuffix = false;
                this.selectedMetadataTypesForSearch = [];
                this.selectedMetadataTypesForSuffix = [];
                this.hasSelectedMetadataTypesSearch = false;
                this.hasSelectedMetadataTypesSuffix = false;
            }
        }

        // Update current view with rules matching selected type
        this.findAndReplaceRules = this.findAndReplaceRulesForBackend.filter(
            rule => rule.maskingType === this.selectedMaskingType
        );
        this.updatePagination();
    }

    handleMetadataTypeForFindAndReplace(event) {
        if (this.selectedMaskingType === 'Search & Replace') {
            this.selectedMetadataTypesForSearch = event.target.value;
            this.hasSelectedMetadataTypesSearch = this.selectedMetadataTypesForSearch.length > 0;
        } else if (this.selectedMaskingType === 'Suffix') {
            this.selectedMetadataTypesForSuffix = event.target.value;
            this.hasSelectedMetadataTypesSuffix = this.selectedMetadataTypesForSuffix.length > 0;
        }
    }

    handleSearch(event) {
        this.searchKey = event.target.value;
    }

    handleReplace(event) {
        this.replaceValue = event.target.value;
    }

    handleSuffixValue(event) {
        this.suffixValue = event.target.value;
    }

    handleSearchRules(event) {
        this.searchTermRules = event.target.value;
        // Reset to first page when search term changes
        this.currentPageRules = 1;

        // If search term is cleared, show all rules
        if (!this.searchTermRules) {
            this.findAndReplaceRules = this.findAndReplaceRulesForBackend.filter(
                rule => rule.maskingType === 'Search & Replace'
            );
        } else {
            // Filter based on search term
            const lcSearchTerm = this.searchTermRules.toLowerCase();
            this.findAndReplaceRules = this.findAndReplaceRulesForBackend
                .filter(rule => rule.maskingType === 'Search & Replace')
                .filter(record =>
                    Object.values(record).some(value =>
                        String(value).toLowerCase().includes(lcSearchTerm)
                    )
                );
        }
        this.updatePagination();
    }

    handleSearchsuffix(event) {
        this.searchTermSuffix = event.target.value;
        // Reset to first page when search term changes
        this.currentPageSuffix = 1;

        // If search term is cleared, show all rules
        if (!this.searchTermSuffix) {
            this.findAndReplaceRules = this.findAndReplaceRulesForBackend.filter(
                rule => rule.maskingType === 'Suffix'
            );
        } else {
            // Filter based on search term
            const lcSearchTerm = this.searchTermSuffix.toLowerCase();
            this.findAndReplaceRules = this.findAndReplaceRulesForBackend
                .filter(rule => rule.maskingType === 'Suffix')
                .filter(record =>
                    Object.values(record).some(value =>
                        String(value).toLowerCase().includes(lcSearchTerm)
                    )
                );
        }
        this.updatePagination();
    }

    // Pagination Handlers
    handlePageSizeChangeRules(event) {
        this.pageSizeRules = parseInt(event.target.value, 10);
        this.currentPageRules = 1;
        this.updatePagination();
    }

    handlePageSizeChangesuffix(event) {
        this.pageSizeSuffix = parseInt(event.target.value, 10);
        this.currentPageSuffix = 1;
        this.updatePagination();
    }

    handleFirstPagerules() {
        this.currentPageRules = 1;
        this.updatePagination();
    }

    handlePreviousPagerules() {
        if (this.currentPageRules > 1) {
            this.currentPageRules--;
            this.updatePagination();
        }
    }

    handleNextPagerules() {
        if (this.currentPageRules < this.totalPagesRules) {
            this.currentPageRules++;
            this.updatePagination();
        }
    }

    handleLastPagerules() {
        this.currentPageRules = this.totalPagesRules;
        this.updatePagination();
    }

    handleFirstPagesuffix() {
        this.currentPageSuffix = 1;
        this.updatePagination();
    }

    handlePreviousPagesuffix() {
        if (this.currentPageSuffix > 1) {
            this.currentPageSuffix--;
            this.updatePagination();
        }
    }

    handleNextPagesuffix() {
        if (this.currentPageSuffix < this.totalPagesSuffix) {
            this.currentPageSuffix++;
            this.updatePagination();
        }
    }

    handleLastPagesuffix() {
        this.currentPageSuffix = this.totalPagesSuffix;
        this.updatePagination();
    }

    // Sorting Handlers
    handleSortSearch(event) {
        this.sortedBySearch = event.detail.fieldName;
        this.sortDirectionSearch = event.detail.sortDirection;
        this.sortData('search');
    }

    handleSortSuffix(event) {
        this.sortedBySuffix = event.detail.fieldName;
        this.sortDirectionSuffix = event.detail.sortDirection;
        this.sortData('suffix');
    }

    // Rule Management
    handleCreateRule() {
        if (!this.validateRule()) {
            return;
        }

        const newRules = [];
        const nextId = this.findAndReplaceRulesForBackend.length;
        const selectedMetadataTypes = this.getSelectedMetadataTypes();

        // Create a separate rule for each selected metadata type
        selectedMetadataTypes.forEach((metadataType, index) => {
            const baseRule = {
                id: nextId + index + 1,
                metadataTypesForFindAndReplace: metadataType,
                maskingType: this.selectedMaskingType
            };

            if (this.selectedMaskingType === 'Search & Replace') {
                // Check if a rule with same metadata type and search key already exists
                const duplicateRule = this.findAndReplaceRulesForBackend.find(
                    rule => rule.metadataTypesForFindAndReplace === metadataType &&
                        rule.maskingType === 'Search & Replace' &&
                        rule.searchKey.trim() === this.searchKey.trim()
                );

                if (duplicateRule) {
                    this.showToast(
                        'Error',
                        `A Search & Replace rule for metadata type "${metadataType}" with search key "${this.searchKey}" already exists!`,
                        'error'
                    );
                    return;
                }

                newRules.push({
                    ...baseRule,
                    searchKey: this.searchKey.trim(),
                    replaceValue: this.replaceValue.trim()
                });
            } else if (this.selectedMaskingType === 'Suffix') {
                // For Suffix, keep existing validation - only one rule per metadata type
                const existingRule = this.findAndReplaceRulesForBackend.find(
                    rule => rule.metadataTypesForFindAndReplace === metadataType &&
                        rule.maskingType === 'Suffix'
                );

                if (existingRule) {
                    this.showToast(
                        'Error',
                        `A Suffix rule for metadata type "${metadataType}" already exists!`,
                        'error'
                    );
                    return;
                }

                newRules.push({
                    ...baseRule,
                    suffixValue: this.suffixValue.trim()
                });
            }
        });

        // Only proceed if we have valid rules to add
        if (newRules.length > 0) {
            // Add all new rules
            this.findAndReplaceRulesForBackend = [...this.findAndReplaceRulesForBackend, ...newRules];
            this.findAndReplaceRules = this.findAndReplaceRulesForBackend.filter(
                rule => rule.maskingType === this.selectedMaskingType
            );

            this.resetForm();
            this.updatePagination();

            // Show success toast
            const ruleCount = newRules.length;
            this.showToast(
                'Success',
                `${ruleCount} rule${ruleCount > 1 ? 's' : ''} created successfully`,
                'success'
            );
        }
    }

    // Update the resetForm method to handle both types
    resetForm() {
        if (this.selectedMaskingType === 'Search & Replace') {
            this.selectedMetadataTypesForSearch = [];
            this.hasSelectedMetadataTypesSearch = false;
            this.searchKey = '';
            this.replaceValue = '';
        } else if (this.selectedMaskingType === 'Suffix') {
            this.selectedMetadataTypesForSuffix = [];
            this.hasSelectedMetadataTypesSuffix = false;
            this.suffixValue = '';
        } else if (this.selectedMaskingType === 'Apex Script') {
            this.newScriptOrder = '';
            this.newScriptName = '';
            this.newScriptDetails = '';
            // Also clear any validation warnings
            this.showValidationWarnings = false;
            this.validationWarnings = [];
        }
    }
    handleFindAndReplaceRowSelection(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName.startsWith('delete')) {
            this.deleteRule(row);
        }
    }

    validateRule() {
        const selectedTypes = this.selectedMaskingType === 'Search & Replace'
            ? this.selectedMetadataTypesForSearch
            : this.selectedMetadataTypesForSuffix;

        if (!selectedTypes.length) {
            this.showToast('Error', 'No Metadata Types selected for Metadata Masking...', 'error');
            return false;
        }

        if (this.selectedMaskingType === 'Search & Replace') {
            if (!this.searchKey) {
                this.showToast('Error', 'Search Key cannot be empty...', 'error');
                return false;
            }
            if (!this.replaceValue) {
                this.showToast('Error', 'Replace Value cannot be empty...', 'error');
                return false;
            }
            if (this.searchKey === this.replaceValue) {
                this.showToast('Error', 'Search Key and Replace Value cannot be same...', 'error');
                return false;
            }
        } else if (this.selectedMaskingType === 'Suffix' && !this.suffixValue) {
            this.showToast('Error', 'Suffix Value cannot be empty...', 'error');
            return false;
        }

        return true;
    }

    createNewRule() {
        const nextId = this.findAndReplaceRulesForBackend.length;
        const newRules = [];

        // Create a separate rule for each selected metadata type
        this.selectedMetadataTypesForFindAndReplace.forEach((metadataType, index) => {
            const baseRule = {
                id: nextId + index + 1,
                metadataTypesForFindAndReplace: metadataType, // Single metadata type per rule
                maskingType: this.selectedMaskingType
            };

            if (this.selectedMaskingType === 'Search & Replace') {
                newRules.push({
                    ...baseRule,
                    searchKey: this.searchKey,
                    replaceValue: this.replaceValue
                });
            } else {
                newRules.push({
                    ...baseRule,
                    suffixValue: this.suffixValue
                });
            }
        });

        return newRules;
    }

    deleteRule(row) {
        try {
            this.findAndReplaceRulesForBackend = this.findAndReplaceRulesForBackend
                .filter(rule => rule.id !== row.id);

            this.findAndReplaceRulesForBackend = this.findAndReplaceRulesForBackend
                .map((record, index) => ({
                    ...record,
                    id: index + 1
                }));

            const isSearchRule = row.maskingType === 'Search & Replace';
            const filteredRules = this.findAndReplaceRulesForBackend.filter(
                rule => rule.maskingType === row.maskingType
            );

            if (isSearchRule) {
                const totalPages = Math.ceil(filteredRules.length / this.pageSizeRules);
                if (this.currentPageRules > totalPages) {
                    this.currentPageRules = Math.max(1, totalPages);
                }
            } else {
                const totalPages = Math.ceil(filteredRules.length / this.pageSizeSuffix);
                if (this.currentPageSuffix > totalPages) {
                    this.currentPageSuffix = Math.max(1, totalPages);
                }
            }

            this.findAndReplaceRules = filteredRules;
            this.updatePagination();

            this.showToast(
                'Success',
                'Rule deleted successfully',
                'success'
            );
        } catch (error) {
            this.showToast(
                'Error',
                'Error deleting rule: ' + error.message,
                'error'
            );
            console.error('Error in deleteRule:', error);
        }
    }

    updatePagination() {
        if (this.showCreateTemplatePage) {
            // On final screen, update both tables
            this.updateSearchAndReplaceTable();
            this.updateSuffixTable();
        } else {
            // During rule creation, update based on selected type
            if (this.selectedMaskingType === 'Search & Replace') {
                this.updateSearchAndReplaceTable();
            } else if (this.selectedMaskingType === 'Suffix') {
                this.updateSuffixTable();
            }
        }
    }

    updateSearchAndReplaceTable() {
        const searchRules = this.findAndReplaceRulesForBackend.filter(
            rule => rule.maskingType === 'Search & Replace'
        );

        let filteredData = [...searchRules];

        // Apply search term filtering
        if (this.searchTermRules) {
            const lcSearchTerm = this.searchTermRules.toLowerCase();
            filteredData = filteredData.filter(record =>
                Object.values(record).some(value =>
                    String(value).toLowerCase().includes(lcSearchTerm)
                )
            );
        }

        // Apply sorting before pagination
        if (this.sortedBySearch) {
            filteredData.sort((a, b) => {
                let valueA = a[this.sortedBySearch];
                let valueB = b[this.sortedBySearch];

                // Handle null/undefined values
                valueA = valueA === null || valueA === undefined ? '' : valueA;
                valueB = valueB === null || valueB === undefined ? '' : valueB;

                // Convert to lowercase if strings
                if (typeof valueA === 'string') {
                    valueA = valueA.toLowerCase();
                }
                if (typeof valueB === 'string') {
                    valueB = valueB.toLowerCase();
                }

                // Perform the comparison
                if (valueA < valueB) {
                    return this.sortDirectionSearch === 'asc' ? -1 : 1;
                }
                if (valueA > valueB) {
                    return this.sortDirectionSearch === 'asc' ? 1 : -1;
                }
                return 0;
            });
        }

        this.hasSearchAndReplaceRules = searchRules.length > 0;
        this.totalPagesRules = Math.ceil(filteredData.length / this.pageSizeRules);

        if (this.currentPageRules > this.totalPagesRules) {
            this.currentPageRules = Math.max(1, this.totalPagesRules);
        }

        const startIndex = (this.currentPageRules - 1) * this.pageSizeRules;
        const endIndex = startIndex + this.pageSizeRules;

        this.paginatedSearchAndReplaceData = filteredData.slice(startIndex, endIndex);
    }

    updateSuffixTable() {
        const suffixRules = this.findAndReplaceRulesForBackend.filter(
            rule => rule.maskingType === 'Suffix'
        );

        let filteredData = [...suffixRules];

        // Apply search term filtering
        if (this.searchTermSuffix) {
            const lcSearchTerm = this.searchTermSuffix.toLowerCase();
            filteredData = filteredData.filter(record =>
                Object.values(record).some(value =>
                    String(value).toLowerCase().includes(lcSearchTerm)
                )
            );
        }

        // Apply sorting before pagination
        if (this.sortedBySuffix) {
            filteredData.sort((a, b) => {
                let valueA = a[this.sortedBySuffix];
                let valueB = b[this.sortedBySuffix];

                // Handle null/undefined values
                valueA = valueA === null || valueA === undefined ? '' : valueA;
                valueB = valueB === null || valueB === undefined ? '' : valueB;

                // Convert to lowercase if strings
                if (typeof valueA === 'string') {
                    valueA = valueA.toLowerCase();
                }
                if (typeof valueB === 'string') {
                    valueB = valueB.toLowerCase();
                }

                // Perform the comparison
                if (valueA < valueB) {
                    return this.sortDirectionSuffix === 'asc' ? -1 : 1;
                }
                if (valueA > valueB) {
                    return this.sortDirectionSuffix === 'asc' ? 1 : -1;
                }
                return 0;
            });
        }

        this.hasSuffixRules = suffixRules.length > 0;
        this.totalPagesSuffix = Math.ceil(filteredData.length / this.pageSizeSuffix);

        if (this.currentPageSuffix > this.totalPagesSuffix) {
            this.currentPageSuffix = Math.max(1, this.totalPagesSuffix);
        }

        const startIndex = (this.currentPageSuffix - 1) * this.pageSizeSuffix;
        const endIndex = startIndex + this.pageSizeSuffix;

        this.paginatedSuffixData = filteredData.slice(startIndex, endIndex);
    }


    sortData(type) {
        let sortBy, sortDirection;
        if (type === 'search') {
            sortBy = this.sortedBySearch;
            sortDirection = this.sortDirectionSearch;
        } else {
            sortBy = this.sortedBySuffix;
            sortDirection = this.sortDirectionSuffix;
        }

        // Get the data for the correct type
        const dataToSort = type === 'search'
            ? this.findAndReplaceRulesForBackend.filter(rule => rule.maskingType === 'Search & Replace')
            : this.findAndReplaceRulesForBackend.filter(rule => rule.maskingType === 'Suffix');

        // Create a copy for sorting
        const sortedData = [...dataToSort];

        // Perform the sort
        sortedData.sort((a, b) => {
            let valueA = a[sortBy];
            let valueB = b[sortBy];

            // Handle null/undefined values
            valueA = valueA === null || valueA === undefined ? '' : valueA;
            valueB = valueB === null || valueB === undefined ? '' : valueB;

            // Convert to lowercase if strings
            if (typeof valueA === 'string') {
                valueA = valueA.toLowerCase();
            }
            if (typeof valueB === 'string') {
                valueB = valueB.toLowerCase();
            }

            // Perform the comparison
            if (valueA < valueB) {
                return sortDirection === 'asc' ? -1 : 1;
            }
            if (valueA > valueB) {
                return sortDirection === 'asc' ? 1 : -1;
            }
            return 0;
        });

        // Update the appropriate data array
        if (type === 'search') {
            this.findAndReplaceRules = sortedData;
            const startIndex = (this.currentPageRules - 1) * this.pageSizeRules;
            const endIndex = startIndex + this.pageSizeRules;
            this.paginatedSearchAndReplaceData = sortedData.slice(startIndex, endIndex);
        } else {
            this.findAndReplaceRules = sortedData;
            const startIndex = (this.currentPageSuffix - 1) * this.pageSizeSuffix;
            const endIndex = startIndex + this.pageSizeSuffix;
            this.paginatedSuffixData = sortedData.slice(startIndex, endIndex);
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    /****************** START OF APEX SCRIPT PAGE CODE BLOCK ******************/
    @track scripts = [];
    @track originalScripts = [];
    @track newScriptOrder = '';
    @track newScriptName = '';
    @track newScriptDetails = '';
    @track searchTermapexScript = '';

    // Pagination variables
    @track pageSizeApex = 5;
    @track currentPageApex = 1;
    @track sortedByapex = 'order';
    @track sortDirectionapex = 'asc';
    @track selectedCurrentPageApexscript = 1;
    @track totalSelectedPagesApexscript = 1;
    @track totalRecordsApexscript = 0;
    @track showapexScript = false;
    @track selectedMaskingType = '';
    @track validationWarnings = [];
    @track showValidationWarnings = false;
    validateDebounceTimeout;

    columns = [
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
            fieldName: 'ScriptName',
            type: 'text',
            sortable: true
        },
        {
            label: 'Script Details',
            fieldName: 'ScriptData',
            type: 'text',
            sortable: true
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Delete', name: 'delete' }
                ]
            }
        }
    ];

    pageSizeOptionsApex = [
        { label: '5', value: 5 },
        { label: '10', value: 10 },
        { label: '25', value: 25 },
        { label: '50', value: 50 }
    ];

    get hasapexScript() {
        return this.originalScripts && this.originalScripts.length > 0;
    }

    get hasValidationIssues() {
        return this.validationWarnings && this.validationWarnings.length > 0;
    }

    get hasValidationErrors() {
        return this.validationWarnings && this.validationWarnings.length > 0;
    }
    get scriptDetailsContainerClass() {
        let baseClass = 'slds-textarea_container';

        if (this.hasValidationIssues) {
            const hasErrors = this.validationWarnings.some(warning =>
                warning.includes('bracket') ||
                warning.includes('Error during validation'));

            if (hasErrors) {
                return `${baseClass} has-error`;
            } else {
                return `${baseClass} has-warning`;
            }
        }

        return baseClass;
    }

    get validationSummary() {
        if (!this.hasValidationIssues) return '';

        const errorCount = this.validationWarnings.filter(warning =>
            warning.includes('bracket') ||
            warning.includes('Error during validation')).length;

        const warningCount = this.validationWarnings.filter(warning =>
            warning.startsWith('Warning:')).length;

        const suggestionCount = this.validationWarnings.filter(warning =>
            warning.startsWith('Suggestion:')).length;

        if (errorCount > 0) {
            return `${errorCount} syntax ${errorCount === 1 ? 'error' : 'errors'} found - Add button is disabled`;
        } else if (warningCount > 0) {
            return `${warningCount} ${warningCount === 1 ? 'warning' : 'warnings'} found`;
        } else if (suggestionCount > 0) {
            return `${suggestionCount} ${suggestionCount === 1 ? 'suggestion' : 'suggestions'} available`;
        }

        return 'Validation issues found';
    }

    get validationIconName() {
        if (!this.hasValidationIssues) return '';

        const hasErrors = this.validationWarnings.some(warning =>
            warning.includes('bracket') ||
            warning.includes('Error during validation'));

        if (hasErrors) {
            return 'utility:error';
        }

        const hasWarnings = this.validationWarnings.some(warning =>
            warning.startsWith('Warning:'));

        if (hasWarnings) {
            return 'utility:warning';
        }

        return 'utility:info';
    }

    get validationIconVariant() {
        if (!this.hasValidationIssues) return '';

        const hasErrors = this.validationWarnings.some(warning =>
            warning.includes('bracket') ||
            warning.includes('Error during validation'));

        if (hasErrors) {
            return 'error';
        }

        return 'warning';
    }

    get validationMessagesByType() {
        if (!this.validationWarnings || this.validationWarnings.length === 0) {
            return [];
        }

        // Group messages by type
        const errors = [];
        const warnings = [];
        const suggestions = [];

        this.validationWarnings.forEach((message, index) => {
            const messageObj = {
                id: `message-${index}`,
                text: message.replace(/^(Suggestion:|Warning:)\s+/, ''),
                style: ''
            };

            if (message.startsWith('Suggestion:')) {
                messageObj.style = 'color: #0070d2';
                suggestions.push(messageObj);
            } else if (message.startsWith('Warning:')) {
                messageObj.style = 'color: #706e6b';
                warnings.push(messageObj);
            } else if (message.includes('bracket') || message.includes('Error during validation')) {
                messageObj.style = 'color: #c23934';
                errors.push(messageObj);
            } else {
                messageObj.style = 'color: #706e6b';
                warnings.push(messageObj);
            }
        });

        const groups = [];

        if (errors.length > 0) {
            groups.push({
                type: 'errors',
                heading: 'Syntax Errors',
                icon: 'utility:error',
                variant: 'error',
                messages: errors
            });
        }

        if (warnings.length > 0) {
            groups.push({
                type: 'warnings',
                heading: 'Warnings',
                icon: 'utility:warning',
                variant: 'warning',
                messages: warnings
            });
        }

        if (suggestions.length > 0) {
            groups.push({
                type: 'suggestions',
                heading: 'Suggestions',
                icon: 'utility:info',
                variant: 'info',
                messages: suggestions
            });
        }

        return groups;
    }

    toggleValidationPanel() {
        this.showValidationWarnings = !this.showValidationWarnings;
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

    get showApexScriptContent() {
        return this.showapexScript && this.selectedMaskingType === 'Apex Script';
    }

    handleSearchApexScripts(event) {
        this.searchTermapexScript = event.target.value;
        this.currentPageApex = 1;

        if (!this.searchTermapexScript) {
            this.scripts = [...this.originalScripts];
        } else {
            const searchTerm = this.searchTermapexScript.toLowerCase();
            this.scripts = this.originalScripts.filter(script =>
                script.ScriptName.toLowerCase().includes(searchTerm) ||
                script.ScriptData.toLowerCase().includes(searchTerm) ||
                script.order.toString().includes(searchTerm)
            );
        }
        this.updatePaginationDetails();
    }

    updatePaginationDetails() {
        this.totalSelectedPagesApexscript = this.totalPagesApex;
        this.selectedCurrentPageApexscript = this.currentPageApex;
        this.totalRecordsApexscript = this.scripts.length;
    }

    handleOrderChange(event) {
        this.newScriptOrder = event.target.value;
    }

    handleNameChange(event) {
        this.newScriptName = event.target.value;
    }

    handleDetailsChange(event) {
        this.newScriptDetails = event.target.value;
        // Validate with debounce for better performance
        if (this.validateDebounceTimeout) {
            clearTimeout(this.validateDebounceTimeout);
        }

        this.validateDebounceTimeout = setTimeout(() => {
            this.validateCurrentScript(true); // true = show warnings only, not errors
        }, 500); // Validate after 0.5 seconds of inactivity
    }

    validateScriptSyntax(scriptCode) {
        //if (!scriptCode) return { isValid: false, errors: ['Script details cannot be empty'] };

        try {
            const errors = [];

            // Check for balanced brackets/parentheses/braces
            const openBrackets = [];
            const bracketPairs = {
                '(': ')',
                '{': '}',
                '[': ']'
            };

            // Track if we're inside a string or comment to ignore brackets there
            let inSingleQuoteString = false;
            let inDoubleQuoteString = false;
            let inLineComment = false;
            let inBlockComment = false;

            for (let i = 0; i < scriptCode.length; i++) {
                const char = scriptCode[i];
                const nextChar = scriptCode[i + 1] || '';

                // Handle string and comment tracking
                if (char === '/' && nextChar === '/' && !inSingleQuoteString && !inDoubleQuoteString && !inBlockComment) {
                    inLineComment = true;
                } else if (char === '/' && nextChar === '*' && !inSingleQuoteString && !inDoubleQuoteString && !inLineComment) {
                    inBlockComment = true;
                } else if (char === '*' && nextChar === '/' && inBlockComment) {
                    inBlockComment = false;
                    i++; // Skip the next character
                } else if (char === '\n' && inLineComment) {
                    inLineComment = false;
                } else if (char === "'" && !inDoubleQuoteString && !inLineComment && !inBlockComment) {
                    // Toggle single quote string if not escaped
                    if (i > 0 && scriptCode[i - 1] !== '\\') {
                        inSingleQuoteString = !inSingleQuoteString;
                    }
                } else if (char === '"' && !inSingleQuoteString && !inLineComment && !inBlockComment) {
                    // Toggle double quote string if not escaped
                    if (i > 0 && scriptCode[i - 1] !== '\\') {
                        inDoubleQuoteString = !inDoubleQuoteString;
                    }
                }

                // Check for brackets only when not in a string or comment
                if (!inSingleQuoteString && !inDoubleQuoteString && !inLineComment && !inBlockComment) {
                    if (char === '(' || char === '{' || char === '[') {
                        openBrackets.push({ char, position: i });
                    } else if (char === ')' || char === '}' || char === ']') {
                        const lastOpen = openBrackets.pop();

                        if (!lastOpen) {
                            errors.push(`Extra closing bracket '${char}' at position ${i + 1}`);
                        } else if (bracketPairs[lastOpen.char] !== char) {
                            errors.push(`Mismatched bracket at position ${i + 1}: expected '${bracketPairs[lastOpen.char]}', found '${char}'`);
                        }
                    }
                }
            }

            if (openBrackets.length > 0) {
                openBrackets.forEach(bracket => {
                    errors.push(`Unclosed '${bracket.char}' at position ${bracket.position + 1}`);
                });
            }

            // Check for semicolons at end of statements
            const lines = scriptCode.split('\n');
            for (let i = 0; i < lines.length; i++) {
                let line = lines[i].trim();

                // Skip empty lines and comments
                if (!line || line.startsWith('//') || line.startsWith('/*') || line.endsWith('*/')) {
                    continue;
                }

                // Skip lines that end with opening or closing braces
                if (line.endsWith('{') || line.endsWith('}')) {
                    continue;
                }

                // Skip if/for/while statements without a body (just a condition)
                if (/^\s*(if|else if|for|while|else)\s*\(.*\)\s*$/i.test(line)) {
                    continue;
                }

                // Skip annotations - lines that start with @
                if (line.trim().startsWith('@')) {
                    continue;
                }

                // Check if line needs a semicolon - only suggest it rather than treating it as an error
                if (!line.endsWith(';')) {
                    errors.push(`Suggestion: Line ${i + 1} may need a semicolon: "${line}"`);
                }
            }

            // Check for Apex specific patterns - but be case-insensitive
            if (/\bclass\b/i.test(scriptCode) && !/(public|private|global)\s+class/i.test(scriptCode)) {
                errors.push('Suggestion: Class definition should include an access modifier (public, private, or global)');
            }

            // Check for common errors in conditions
            const ifConditions = scriptCode.match(/if\s*\((.*?)\)/g) || [];
            for (const condition of ifConditions) {
                const innerCondition = condition.match(/if\s*\((.*?)\)/)[1];

                // Check for assignment in condition (= instead of ==)
                if (/ = /.test(innerCondition) && !/ == /.test(innerCondition) && !/ != /.test(innerCondition) && !/ >= /.test(innerCondition) && !/ <= /.test(innerCondition)) {
                    errors.push(`Warning: Possible assignment in condition: "${condition}". Did you mean to use == instead of =?`);
                }
            }

            // Check for SOQL-specific issues
            const soqlPatterns = [
                { regex: /select\s+.*\s+from\s+/i, keywords: ['select', 'from'] },
                { regex: /\bwhere\b/i, keywords: ['where'] },
                { regex: /\border\s+by\b/i, keywords: ['order by'] },
                { regex: /\bgroup\s+by\b/i, keywords: ['group by'] },
                { regex: /\bhaving\b/i, keywords: ['having'] },
                { regex: /\blimit\b/i, keywords: ['limit'] }
            ];

            // Check for SOQL queries without LIMIT clause
            if (/select\s+.*\s+from\s+/i.test(scriptCode) && !/\blimit\b/i.test(scriptCode)) {
                errors.push('Warning: SOQL query is missing LIMIT clause, which can lead to governor limit issues');
            }

            return {
                isValid: errors.length === 0,
                errors: errors
            };
        } catch (error) {
            return {
                isValid: false,
                errors: ['Error during validation: ' + error.message]
            };
        }
    }

    // Add this method to dismiss validation warnings
    dismissValidationWarnings() {
        // We don't want to hide the validation warnings if there are errors
        // Only allow dismissing if there are only suggestions
        const hasErrors = this.validationWarnings.some(warning =>
            warning.includes('bracket') ||
            warning.includes('Error during validation') ||
            warning.startsWith('Warning:'));

        if (!hasErrors) {
            this.validationWarnings = [];
        } else {
            // Show a toast message explaining why it can't be dismissed
            this.showToast('Info', 'Please fix validation issues before dismissing this panel.', 'info');
        }
    }

    // Add this method to validate on blur
    validateOnBlur() {
        this.validateCurrentScript(true);
    }

    validateCurrentScript(warningsOnly = false) {
        const result = this.validateScriptSyntax(this.newScriptDetails);

        // Filter warnings vs. errors
        const criticalErrors = result.errors.filter(err =>
            !err.startsWith('Suggestion:') &&
            !err.startsWith('Warning:') &&
            (err.includes('bracket') || err.includes('Error during validation'))
        );

        const warnings = result.errors.filter(err =>
            err.startsWith('Warning:') ||
            (!err.includes('bracket') && !err.includes('Error during validation') && !err.startsWith('Suggestion:'))
        );

        const suggestions = result.errors.filter(err =>
            err.startsWith('Suggestion:')
        );

        // Store all issues in the warnings array
        this.validationWarnings = [...criticalErrors, ...warnings, ...suggestions];

        // Only show critical errors as toast messages that block submission
        if (!warningsOnly && criticalErrors.length > 0) {
            this.showToast('Syntax Errors', `Please correct syntax errors before continuing.`, 'error');
            return false;
        }

        // Return true if there are no critical errors
        return criticalErrors.length === 0;
    }

    // Added this getter to replace the direct function call
    get formattedWarnings() {
        return this.validationWarnings.map((warning, index) => {
            let cssClass = 'warning-text';

            if (warning.startsWith('Suggestion:')) {
                cssClass = 'suggestion-text';
            } else if (warning.startsWith('Warning:')) {
                cssClass = 'warning-text';
            } else if (warning.includes('bracket') || warning.includes('Error during validation')) {
                cssClass = 'error-text';
            }

            return {
                id: index.toString(), // Unique key for the template iteration
                message: warning,
                class: cssClass
            };
        });
    }

    handleAddScript() {
        if (!this.newScriptOrder || !this.newScriptName || !this.newScriptDetails) {
            let missingFields = [];

            if (!this.newScriptOrder) missingFields.push('Order');
            if (!this.newScriptName) missingFields.push('Script Name');
            if (!this.newScriptDetails) missingFields.push('Script Details');

            const message = `${missingFields.join(', ')} are required`;
            this.showToast('Error', message, 'error');
            return;
        }

        // Validate script syntax before adding
        if (!this.validateCurrentScript()) {
            return;
        }

        const orderNum = parseInt(this.newScriptOrder, 10);
        // Check if the order is less than or equal to 0
        if (orderNum <= 0) {
            this.showToast('Error', 'Order must start from 1. Please enter a valid positive order number.', 'error');
            return;
        }
        console.log('Before adding - originalScripts:', [...this.originalScripts]);

        // Check if a script with the same name already exists
        if (this.originalScripts.some(script => script.ScriptName === this.newScriptName)) {
            this.showToast('Error', `Script with name "${this.newScriptName}" already exists!`, 'error');
            return;
        }

        // Check if script with this order already exists
        if (this.originalScripts.some(script => script.order === orderNum)) {
            this.showToast('Error', `Script with order ${orderNum} already exists!`, 'error');
            return;
        }

        // Check for sequential order
        // Check for sequential order
        if (orderNum > 1) {
            // Find the highest existing order
            const existingOrders = this.originalScripts.map(script => script.order);
            const highestOrder = existingOrders.length > 0 ? Math.max(...existingOrders) : 0;

            // New order should be exactly one more than the highest existing order
            if (orderNum !== highestOrder + 1) {
                this.showToast('Error', `Please add script with order ${highestOrder + 1} next!`, 'error');
                return;
            }
        }

        const script = {
            id: Date.now().toString(),
            order: orderNum,
            ScriptName: this.newScriptName,
            ScriptData: this.newScriptDetails || ''
        };
        // Reset validation warnings after successful addition
        this.showValidationWarnings = false;
        this.validationWarnings = [];
        console.log('New script to be added:', script);

        this.originalScripts = [...this.originalScripts, script].sort((a, b) => a.order - b.order);
        console.log('After adding - originalScripts:', [...this.originalScripts]);

        if (this.searchTermapexScript) {
            const searchTerm = this.searchTermapexScript.toLowerCase();
            this.scripts = this.originalScripts.filter(script =>
                script.ScriptName.toLowerCase().includes(searchTerm) ||
                script.ScriptData.toLowerCase().includes(searchTerm) ||
                script.order.toString().includes(searchTerm)
            );
        } else {
            this.scripts = [...this.originalScripts];
        }

        this.clearApexScriptForm();
        this.updatePaginationDetails();
        this.showToast('Success', 'Script added successfully', 'success');
    }

    clearApexScriptForm() {
        this.newScriptOrder = '';
        this.newScriptName = '';
        this.newScriptDetails = '';
    }

    handleRowActionApexScript(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'delete') {
            this.deleteScript(row.id);
        }
    }

    deleteScript(scriptId) {
        this.originalScripts = this.originalScripts.filter(script => script.id !== scriptId);

        if (this.searchTermapexScript) {
            const searchTerm = this.searchTermapexScript.toLowerCase();
            this.scripts = this.originalScripts.filter(script =>
                script.ScriptName.toLowerCase().includes(searchTerm) ||
                script.ScriptData.toLowerCase().includes(searchTerm) ||
                script.order.toString().includes(searchTerm)
            );
        } else {
            this.scripts = [...this.originalScripts];
        }

        this.updatePaginationDetails();
        this.showToast('Success', 'Script deleted successfully', 'success');
    }

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

    /****************** END OF APEX SCRIPT CODE BLOCK ******************/

    ///progress barr///

    // Getters for step classes
    // Getters for step classes
    get getStepClass1() {
        if (this.isMetadataPicker) {
            return 'progress-step active';
        }
        return `progress-step ${this.isDataPicker || this.showFindAndReplacePage || this.showCreateTemplatePage ? 'completed' : ''}`;
    }

    get getStepClass2() {
        if (this.showFindAndReplacePage) {
            return 'progress-step active';
        }
        return `progress-step ${this.isDataPicker || this.showCreateTemplatePage ? 'completed' : ''}`;
    }

    get getStepClass3() {
        if (this.isDataPicker) {
            return 'progress-step active';
        }
        return `progress-step ${this.showCreateTemplatePage ? 'completed' : ''}`;
    }

    get getStepClass4() {
        if (this.showCreateTemplatePage) {
            return 'progress-step active';
        }
        return 'progress-step';
    }

    // Getters for line classes
    get getLine1Class() {
        return `progress-line ${this.isDataPicker || this.showFindAndReplacePage || this.showCreateTemplatePage ? 'completed' : this.isMetadataPicker ? 'active' : ''}`;
    }

    get getLine2Class() {
        return `progress-line ${this.isDataPicker || this.showCreateTemplatePage ? 'completed' : this.showFindAndReplacePage ? 'active' : ''}`;
    }

    get getLine3Class() {
        return `progress-line ${this.showCreateTemplatePage ? 'completed' : this.isDataPicker ? 'active' : ''}`;
    }

    // Getters for step completion status
    get isStep1Complete() {
        return this.isDataPicker || this.showFindAndReplacePage || this.showCreateTemplatePage;
    }

    get isStep2Complete() {
        return this.isDataPicker || this.showCreateTemplatePage;
    }

    get isStep3Complete() {
        return this.showCreateTemplatePage;
    }

    get isStep4Complete() {
        return false;
    }
    ///end////

    /****************** END OF FIND AND REPLACE PAGE CODE BLOCK ******************/


    /****************** CREATE TEMPLATE CODE BLOCK FOR CREATE NEW TEMPLATE ******************/

    @track showCreateTemplatePage = false;

    @track templateName = '';
    handleTemplateName(event) {
        this.templateName = event.target.value;
        console.log('this.templateName --- ' + this.templateName);
    }

    handleBackFromTemplateCreationPage() {
        this.searchTermRules = '';
        this.searchTermSuffix = '';
        this.searchTerm = '';
        this.selectedTableSearchTermUSER = '';
        //this.filterLetter = '';
        //this.activeLetter = '';

        // Custom Settings section
        this.searchTermavailCus = '';
        this.searchTermselCus = '';

        // Scheduled Jobs section
        this.searchTermSJ = '';
        this.searchTermSelectedSJ = '';


        // Reset page sizes to default for all sections
        // Users section
        this.selectedTablePageSize = 10;
        this.pageSizeRules = 5;
        this.pageSizeSuffix = 5;

        // Custom Settings section
        this.pageSizeCS = 5;
        this.selectedPageSizeCS = 5;

        // Scheduled Jobs section
        this.pageSizeSJ = 5;
        this.selectedPageSizeSJ = 5;
        this.currentPageRules = 1;
        this.currentPageSuffix = 1;
        this.currentPageAvailCS = 1;
        this.selectedCurrentPageCS = 1;
        this.currentPageSJ = 1;
        this.selectedCurrentPageSJ = 1;
        this.selectedTablePage = 1;
        this.searchTermapexScript = '';
        //this.pageSizeApex = 5;


        // Reset table data to reflect cleared search terms
        if (this.selectedData === 'Users') {
            this.filteredData = [...this.userDataforDatatable];
            this.refreshSelectedTableData();
        } else if (this.selectedData === 'Custom Settings') {
            this.updateSelectedCustomSettingsData();
            this.updatePreselectedRowsForCS();
        } else if (this.selectedData === 'Scheduled Jobs') {
            this.updateSelectedJobsData();
            this.updatePreselectedRows();
        }
        this.showCreateTemplatePage = false;
        this.isDataPicker = true;

        console.log("Before filtering: ", JSON.stringify(this.findAndReplaceRulesForBackend));

        // Initially hide both sections
        this.showSearchAndReplace = false;
        this.showSuffix = false;

        // Only show appropriate section if we have a previous masking type
        if (this.previousSelectedMaskingType) {
            this.selectedMaskingType = this.previousSelectedMaskingType;

            if (this.selectedMaskingType === 'Search & Replace') {
                this.showSearchAndReplace = true;
                this.showSuffix = false;
                this.showapexScript = false;
            } else if (this.selectedMaskingType === 'Suffix') {
                this.showSearchAndReplace = false;
                this.showSuffix = true;
                this.showapexScript = false;
            } else if (this.selectedMaskingType === 'Apex Script') {
                this.showapexScript = true;
                this.showSearchAndReplace = false;
                this.showSuffix = false;
            }

            this.findAndReplaceRules = this.findAndReplaceRulesForBackend.filter(
                rule => rule.maskingType === this.selectedMaskingType
            );
        } else {
            this.selectedMaskingType = '';
            this.findAndReplaceRules = [];
        }

        console.log("Selected Masking Type:", this.selectedMaskingType);
        console.log("Filtered Rules:", JSON.stringify(this.findAndReplaceRules));
    }


    /*** show modal  ***/
    @track isShowModal = false;

    showModalBox() {
        this.isShowModal = true;
    }

    hideModalBox() {
        this.isShowModal = false;
    }
    /*** end of show modal ***/

    /*** progress bar ***/

    progress = 0;
    isProgressing = false;

    get computedLabel() {
        return this.isProgressing ? 'Stop' : 'Start';
    }

    toggleProgress() {
        console.log('this.isProgressing --- ' + this.isProgressing);

        if (this.isProgressing) {
            // stop
            this.isProgressing = false;
            clearInterval(this._interval);
        } else {
            // start
            this.isProgressing = true;
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            /*this._interval = setInterval(() => {
                this.progress = this.progress === 100 ? 0 : this.progress + 1;
            }, 100);*/

            this._interval = setInterval(() => {
                this.progress = this.progress === 100 ? window.location.reload() : this.progress + 1;
            }, 100);
        }
    }

    disconnectedCallback() {
        clearInterval(this._interval);
    }
    // Add to your existing properties
    @track selectedAccordionSection = '';

    // Add this lifecycle hook
    connectedCallback() {
    }
    /*** end of progress bar ***/

    handleCreateTemplate() {
        console.log('this.templateName -=='+this.templateName);
        if (this.templateName != '') {
            console.log('selected user length = ' + Object.keys(this.selectedUsers).length);
            console.log('selected custom settings length = ' + Object.keys(this.selectedCustomSettings).length);
            console.log('selected scheduled jobs length = ' + Object.keys(this.selectedScheduledJobs).length);
            console.log('selected metadata length = ' + Object.keys(this.selectedMetadataListToDisplay).length);
            console.log('template for find and replace = ' + JSON.stringify(this.findAndReplaceRulesForBackend));
            console.log('apex scripts = ' + JSON.stringify(this.originalScripts));

            console.log('this.selectedOrg --- ' + this.selectedOrg); 
            console.log('this.templateName --- ' + this.templateName);
            console.log('this.metadataPackageXmlContent --- ' + this.metadataPackageXmlContent);
            console.log('this.selectedUsernames --- ' + this.selectedUsernames);
            console.log('this.customSettingNamesList --- ' + this.customSettingNamesList);
            console.log('this.selectedScheduledJobs --- ' + JSON.stringify(this.selectedScheduledJobs));
            console.log('this.findAndReplaceRulesForBackend --- ' + JSON.stringify(this.findAndReplaceRulesForBackend));
            console.log('jsonData --- ' + JSON.stringify(this.originalScripts));
            console.log('csvString --- ' + this.convertApexScriptsToCSV(this.originalScripts));


            let isTempNull = (Object.keys(this.selectedUsers).length === 0 && Object.keys(this.selectedCustomSettings).length === 0 && Object.keys(this.selectedScheduledJobs).length == 0 && Object.keys(this.selectedMetadataListToDisplay).length === 0 && this.originalScripts.length === 0) ? true : false;
            console.log('is everything empty --- ' + isTempNull);

            if (isTempNull) {
                const dispEvent = new ShowToastEvent({
                    title: 'Error',
                    message: 'There is no metadata/data to create a template...',
                    variant: 'error'
                });
                this.dispatchEvent(dispEvent);
                this.showCreateTemplatePage = true;
            }
            else {
                console.log('template creation successfull');
                this.isShowModal = true;
                this.toggleProgress();
                const jsonData = JSON.stringify(this.originalScripts);
                //const csvString = this.convertApexScriptsToCSV(this.originalScripts);
                let csvString = '';
                if (this.originalScripts && this.originalScripts.length > 0) {
                    csvString = this.convertApexScriptsToCSV(this.originalScripts);
                }

                createNewTemplate({
                    parentOrgId: this.selectedOrg, templateName: this.templateName,
                    metadataPackageXmlContent: this.metadataPackageXmlContent, selectedUsernames: this.selectedUsernames,
                    customSettingNames: this.customSettingNamesList, sJobs: JSON.stringify(this.selectedScheduledJobs),
                    findAndReplaceTemplate: JSON.stringify(this.findAndReplaceRulesForBackend), jsonData: jsonData,
                    csvString: csvString
                })
                    .then(result => {
                        console.log('result --- ' + JSON.stringify(result));
                    })
                    .catch(error => {
                        console.log('error --- ' + JSON.stringify(error));
                    })
            }

        }
        else {
            const dispEvent = new ShowToastEvent({
                title: 'Error',
                message: 'Please provide a template name...',
                variant: 'error'
            });
            this.dispatchEvent(dispEvent);
            this.showCreateTemplatePage = true;
        }

    }

    convertApexScriptsToCSV(scripts) {
        if (!scripts || scripts.length === 0) return 'order,scriptname,ScriptData\n';

        const header = 'order,scriptname,ScriptData\n';
        const rows = scripts.map(script => {
            // Escape any commas in the script data
            const sanitizedScriptData = script.ScriptData.replace(/,/g, '\\,');
            const sanitizedScriptName = script.ScriptName.replace(/,/g, '\\,');
            return `${script.order},${sanitizedScriptName},${sanitizedScriptData}`;
        }).join('\n');

        return header + rows;
    }

    /****************** END OF CREATE TEMPLATE CODE BLOCK FOR CREATE NEW TEMPLATE ******************/


    /****************** EDIT METADATA RETRIEVAL PAGE CODE BLOCK ******************/

    @track showBackConfirmationModalForEdit = false

    handleBackCancellationForEdit(){
        this.showBackConfirmationModalForEdit = false
    }

    handleBackConfirmationForEdit(){
        console.log('this.currentPageReference recordId ---- ' + this.currentPageReference?.state?.c__recordId);
        if(this.currentPageReference?.state?.c__recordId != undefined || this.currentPageReference?.state?.c__recordId != null){
            /*this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.currentPageReference?.state?.c__recordId,
                    objectApiName: 'Refresh_Template__c',
                    actionName: 'view'
                }
            });
            window.location.reload();*/
            const templateRecordId = this.currentPageReference?.state?.c__recordId;
            const url = `/lightning/r/Refresh_Template__c/${templateRecordId}/view?reloadRecord=true`;
            window.location.href = url;
        }
        else{
            /*this.showSpinner = false;
            this.showOnPageLoad = true
            this.showMetadataRetrievePageForEditTemplate = false;
            this.showFindAndReplacePageForEdit = false;
            this.isDataPickerForEdit = false;
            this.showCreateTemplatePageForEdit = false;*/
            window.location.reload();
        }
    }

   
    @track showMetadataRetrievePageForEditTemplate = false;
    @track parentOrg;
    @track parentOrgName = '';
    //@track showSpinnerForLoadingMetadataType = true;
    @track activeAccordionSectionEdit = 'Metadata';

    fetchRecordDetails(tempId) {
        fetchRefreshTemplate({ refTempId: tempId })
        .then(result => {
            console.log('result --- ' + JSON.stringify(result));
            this.parentOrg = result.Parent_Org__c;
            this.parentOrgName = result.Parent_Org__r.Name;
            this.templateNameForEdit = result.Name; 

            this.recordUrl = `/lightning/r/Org__c/${this.parentOrg}/view`;
            this.activeAccordionSectionEdit = 'Metadata';

            this.fetchAllMetadataTypes(this.parentOrg);
            this.fetchExistingMetadataOfTemplate(tempId);
        }).catch(error => {
            console.log('Error fetching record details: ' + error);
        });
    }

    @track existingMetadataComponents = [];
    @track existingMetadataComponentsColumns = [
        { label: 'Name', fieldName: 'name', type: 'text', sortable: true },
        { label: 'Type', fieldName: 'type', type: 'text', sortable: true },
    ];

    @track preselectedRowsForEdit = [];
    @track selectedMetadataListToDisplayForEdit = [];

    @track isNextButtonDisabledForEdit = true;
    fetchExistingMetadataOfTemplate(tempId) {
        getPackageContents({ recordId: tempId })
            .then(data => {
                const indexedData = data.map((item, index) => ({
                    ...item,
                    index: item.name
                }));
    
                this.existingMetadataComponents = indexedData;
                this.preselectedRowsForEdit = indexedData.map(item => item.name);
        
                indexedData.forEach(item => {
                    this.selectedMetadataMapForEdit[item.name] = item;
                });
                
                this.selectedMetadataListToDisplayForEdit = Object.values(this.selectedMetadataMapForEdit);

                // ✅ Force pagination to start from page 1
                this.selectedCurrentPageForEdit = 1;
                this.selectedTotalPagesForEdit = Math.ceil(this.selectedMetadataListToDisplayForEdit.length / this.selectedPageSizeForEdit) || 1;

                this.updatePaginatedSelectedMetadataForEdit();
                
                this.isNextButtonDisabledForEdit = false;
                
            })
            .catch(error => {
                console.log('Error fetching record details: ' + error);
            });
    }

    @track metadataDatatableColumnForEdit = [];
    @track showMetadataDatatableForEdit = false;
    @track metadataToDisplayInDatatableForEdit = [];

    handleMetadataSelectionForEdit(event) {
        this.selectedMetadata = event.target.value;
        console.log('selectedMetadata --- ' + this.selectedMetadata);
    
        this.showMetadataDatatableForEdit = false;
        this.showSpinnerInsideMetadataBoxForEdit = true;
    
        fetchAllMetadataComponentsForEdit({
            sandboxId: this.parentOrg,
            selectedMetadataType: this.selectedMetadata
        })
        .then(result => {
            console.log('result -- ' + JSON.stringify(result));
            if (result && result.length > 0) {
                this.showMetadataDatatableForEdit = true;
                this.metadataForEdit = result;
    
                // 🟢 Enrich result with name and selection state
                this.metadataToDisplayInDatatableForEdit = result.map(item => {
                    const value = item.value;
                    return {
                        ...item,
                        name: value,
                        isSelected: this.selectedMetadataMapForEdit.hasOwnProperty(value)
                    };
                });
    
                // Merge existing selected metadata with full list
                this.mergeSelectedMetadataWithFullList(this.metadataToDisplayInDatatableForEdit);
    
                // Sort and setup pagination
                this.metadataToDisplayInDatatableForEdit.sort((a, b) =>
                    (a.value || '').toLowerCase().localeCompare((b.value || '').toLowerCase())
                );
    
                this.sortedByMetadataForEdit = '';
                this.sortDirectionMetadaForEdit = 'asc';
                this.metadataDatatableColumnForEdit = metadataDatatableColumnForEdit;
    
                this.filteredMetadataForEdit = [...this.metadataToDisplayInDatatableForEdit];
                this.totalPagesForEdit = Math.ceil(this.filteredMetadataForEdit.length / this.pageSizeMetadataForEdit) || 1;
                this.currentPageForEdit = 1;
    
                // ✅ Set preselected rows based on current metadata
                this.preselectedRowsForEdit = this.filteredMetadataForEdit
                    .map(row => row.value)
                    .filter(value => this.selectedMetadataMapForEdit.hasOwnProperty(value));
    
                this.updatePaginatedMetadataForEdit();
                this.updatePaginatedSelectedMetadataForEdit();
            } else {
                // No data for selected metadata type
                this.showMetadataDatatableForEdit = false;
                this.metadataForEdit = [];
                this.metadataToDisplayInDatatableForEdit = [];
                this.filteredMetadataForEdit = [];
            }
        })
        .catch(error => {
            console.log('error -- ' + JSON.stringify(error));
        })
        .finally(() => {
            this.showSpinnerInsideMetadataBoxForEdit = false;
        });
    }

  /*  handleSelectedMetadataRowAction(event) {
        const selectedRowKeys = event.detail.selectedRows.map(row => row.name);
    
        // Remove unselected
        for (const key in this.selectedMetadataMapForEdit) {
            if (!selectedRowKeys.includes(key)) {
                delete this.selectedMetadataMapForEdit[key];
            }
        }
    
        this.selectedMetadataListToDisplayForEdit = Object.values(this.selectedMetadataMapForEdit);
        this.updatePaginatedSelectedMetadataForEdit();
    }*/
    
    @track _selectedMetadataMapForEdit = {};

    get selectedMetadataMapForEdit() {
        return this._selectedMetadataMapForEdit;
    }
    set selectedMetadataMapForEdit(value) {
        this._selectedMetadataMapForEdit = { ...value };
    }
    
    handleMetadataDatatableRowActionForEdit(event) {
        const selectedRows = event.detail.selectedRows || [];
        const selectedRowIds = selectedRows.map(row => row.value);
    
        // Merge selections
        selectedRows.forEach(row => {
            this.selectedMetadataMapForEdit[row.value] = row;
        });
    
        // Handle deselection on current page
        this.paginatedMetadataForEdit.forEach(row => {
            if (!selectedRowIds.includes(row.value)) {
                delete this.selectedMetadataMapForEdit[row.value];
            }
        });
    
        this.selectedMetadataListToDisplayForEdit = Object.values(this.selectedMetadataMapForEdit);
        this.updatePaginatedSelectedMetadataForEdit();
    }

    // Damini's Changes Start 
    handleBackEdit(){
        this.showBackConfirmationModalForEdit = true;
    }

    @track pageSizeOptionsMetadataForEdit = [5, 10, 20, 50];
    @track searchKeySMDForEdit = '';
    @track searchKeySMDForEdits = '';
    @track showSpinnerInsideMetadataBoxForEdit = false;
    @track preselectedRowsForEdit = [];
    @track metadataForEdit = [];
    @track selectedMetadataForEdit = '';
    @track isOrgNotSelectedYetForEdit = true;
    @track showMetadataDatatableForEdit = false;
    @track filteredMetadataForEdit = [];

    get isMetadataListEmpty() {
        return !(this.metadataToDisplayInDatatableForEdit && this.metadataToDisplayInDatatableForEdit.length > 0);
    }

    get hasExistingMetadataComponents() {
        return Array.isArray(this.existingMetadataComponents) && this.existingMetadataComponents.length > 0;
    }

    get hasPaginatedMetadataForEdit() {
        return Array.isArray(this.paginatedMetadataForEdit) && this.paginatedMetadataForEdit.length > 0;
    }
    
    get hasPaginatedSelectedMetadataForEdit() {
        return Array.isArray(this.paginatedSelectedMetadataForEdit) && this.paginatedSelectedMetadataForEdit.length > 0;
    }

    get filteredMetadataCountForEdit() {
        return Array.isArray(this.filteredMetadataForEdit) ? this.filteredMetadataForEdit.length : 0;
    }
    

    handleSearchMetadataForEdit(event) {
        this.searchKeySMDForEdits = event.target.value.toLowerCase();
    
        if (this.searchKeySMDForEdits) {
            this.filteredMetadataForEdit = this.metadataToDisplayInDatatableForEdit.filter(metadata =>
                metadata.value.toLowerCase().includes(this.searchKeySMDForEdits)
            );
        } else {
            this.filteredMetadataForEdit = [...this.metadataToDisplayInDatatableForEdit];
        }
    
        this.currentPageForEdit = 1;
        this.totalPagesForEdit = Math.ceil(this.filteredMetadataForEdit.length / this.pageSizeMetadataForEdit);
        this.updatePaginatedMetadataForEdit();
    }

    @track currentPageForEdit = 1; // Current page number
    @track totalPagesForEdit = 1; // Total number of pages
    @track pageSizeMetadataForEdit = 5; // Records per page
    @track paginatedMetadataForEdit = []; // Metadata for the current page
    @track selectedRowsForEdit = []; // Tracks selected rows across pages
    @track selectedMetadataRowsForEdit = {};
    @track selectedMetadataListToDisplayForEdit = [];
    @track selectedMetadataMapForEdit = {}; // ✅ add this if missing
    @track paginatedSelectedMetadataForEdit = [];
    @track selectedMetadataListToDisplayForEdit = [];
    @track selectedCurrentPageForEdit = 1; // Current page number for selected metadata
    @track selectedTotalPagesForEdit = 1; // Total number of pages for selected metadata
    @track selectedPageSizeForEdit = 5; // Records per page for selected metadata
    @track paginatedSelectedMetadataForEdit = []; // Selected metadata for the current page
    @track sortedByMetadataForEdit; // Current field to sort by
    @track sortDirectionMetadaForEdit = 'asc'; // Current sort direction

    updatePaginatedMetadataForEdit() {
        const start = (this.currentPageForEdit - 1) * this.pageSizeMetadataForEdit;
        const end = start + this.pageSizeMetadataForEdit;
    
        this.paginatedMetadataForEdit = this.filteredMetadataForEdit.slice(start, end);
    
        // 🟢 Correctly preselect checkboxes based on selected metadata map
        this.preselectedRowsForEdit = this.paginatedMetadataForEdit
            .map(row => row.value)
            .filter(value => this.selectedMetadataMapForEdit.hasOwnProperty(value));
    }
    
    handlePageChangeForEdit() {
        this.updatePaginatedMetadataForEdit();
        this.updatePaginatedSelectedMetadataForEdit();
    }

    handleFirstPageForEdit() {
        this.currentPageForEdit = 1;
        this.handlePageChangeForEdit();
    }

    handlePreviousPageForEdit() {
        if (this.currentPageForEdit > 1) {
            this.currentPageForEdit -= 1;
            this.handlePageChangeForEdit();
        }
    }

    handleNextPageForEdit() {
        if (this.currentPageForEdit < this.totalPagesForEdit) {
            this.currentPageForEdit += 1;
            this.handlePageChangeForEdit();
        }
    }

    handleLastPageForEdit() {
        this.currentPageForEdit = this.totalPagesForEdit;
        this.handlePageChangeForEdit();
    }

    get isFirstPageDisabledForEdit() {
        return this.currentPageForEdit === 1;
    }

    get isLastPageDisabledForEdit() {
        return this.currentPageForEdit === this.totalPagesForEdit;
    }

    @track preselectedRowsForSelectedTableEdit = [];
    
    updatePaginatedSelectedMetadataForEdit() {
        this.selectedCurrentPageForEdit = this.paginatedSelectedMetadataForEdit.length == 0 && this.selectedCurrentPageForEdit > 1 ? this.selectedCurrentPageForEdit - 1 : this.selectedCurrentPageForEdit;
        this.selectedTotalPagesForEdit = Math.ceil(this.selectedMetadataListToDisplayForEdit.length / this.selectedPageSizeForEdit);
        const start = (this.selectedCurrentPageForEdit - 1) * this.selectedPageSizeForEdit;
        const end = start + this.selectedPageSizeForEdit;
        console.log('Start:: ' + start, '  end:: ' + end);

        this.paginatedSelectedMetadataForEdit = this.selectedMetadataListToDisplayForEdit.slice(start, end);
        console.log('paginatedSelectedMetadata ForEdit:: ' + JSON.stringify(this.paginatedSelectedMetadataForEdit));
        // this.preselectedRows = this.selectedMetadataListToDisplay
        //     .map(row => row.name)
        //     .filter(name => this.selectedMetadataMap[name]);

       // this.preselectedRowsForEdit = Object.keys(this.selectedMetadataMapForEdit);

       // ✅ Use this for selected table's checkbox state
        this.preselectedRowsForSelectedTableEdit = this.paginatedSelectedMetadataForEdit.map(row => row.name);

        // 🔒 Keep this unchanged for Available table
        this.preselectedRowsForEdit = this.paginatedMetadataForEdit
            .map(row => row.value)
            .filter(value => this.selectedMetadataMapForEdit.hasOwnProperty(value));
    }

    get showSelectedMDForEdit() {
        return Object.keys(this.selectedMetadataMapForEdit).length > 0;
    }


    handleSearchSelectedMetadataForEdit(event) {
        this.searchKeySMDForEdit = event.target.value.toLowerCase();
        console.log('searchKeySMD ForEdit>> ' + this.searchKeySMDForEdit);
        console.log('selectedMetadataMap ForEdit :: ' + JSON.stringify(this.selectedMetadataMapForEdit));

        if (this.searchKeySMDForEdit) {
            this.selectedMetadataListToDisplayForEdit = Object.values(this.selectedMetadataMapForEdit).filter(metadata =>
                metadata.name.toLowerCase().includes(this.searchKeySMDForEdit)
            );
            console.log('selectedMetadataListToDisplay ForEdit>> ' + JSON.stringify(this.selectedMetadataListToDisplayForEdit));
        } else {
            this.selectedMetadataListToDisplayForEdit = Object.values(this.selectedMetadataMapForEdit);
        }
        console.log('selectedMetadataListToDisplayForEdit>> ' + JSON.stringify(this.selectedMetadataListToDisplayForEdit));
        this.selectedCurrentPageForEdit = 1;
        this.selectedTotalPagesForEdit = Math.ceil(this.selectedMetadataListToDisplayForEdit.length / this.selectedPageSizeForEdit) || 1;
        this.updatePaginatedSelectedMetadataForEdit();
        //this.preselectedRows = Object.keys(this.selectedMetadataMap); 
    }

    handleSelectedFirstPageForEdit() {
        this.selectedCurrentPageForEdit = 1;
        this.sortSelectedMetadataTableForEdit = true;
        this.updatePaginatedSelectedMetadataForEdit();
    }

    handleSelectedNextPageForEdit() {
        if (this.selectedCurrentPageForEdit < this.selectedTotalPagesForEdit) {
            this.selectedCurrentPageForEdit++;
            this.sortSelectedMetadataTableForEdit = true;
            this.updatePaginatedSelectedMetadataForEdit();
        }
    }

    handleSelectedPreviousPageForEdit() {
        if (this.selectedCurrentPageForEdit > 1) {
            this.selectedCurrentPageForEdit--;
            this.sortSelectedMetadataTableForEdit = true;
            this.updatePaginatedSelectedMetadataForEdit();
        }
    }

    handleSelectedLastPageForEdit() {
        this.selectedCurrentPageForEdit = this.selectedTotalPagesForEdit;
        this.sortSelectedMetadataTableForEdit = true;
        this.updatePaginatedSelectedMetadataForEdit();
    }

    // Navigation button disabled states
    get isSelectedFirstPageDisabledForEdit() {
        return this.selectedCurrentPageForEdit === 1;
    }

    get isSelectedLastPageDisabledForEdit() {
        return this.selectedCurrentPageForEdit === this.selectedTotalPagesForEdit;
    }

    get showSelectedMDForEdit() {
        return Object.keys(this.selectedMetadataMapForEdit).length > 0;
    }

    handleSelectedMetadataRowActionForEdit(event) {
        console.log('in handleSelectedMetadataRowAction');

        let selectedRows = event.detail.selectedRows || [];
        console.log('selectedRows :: ' + JSON.stringify(selectedRows));

        // Get currently displayed rows to handle deselections properly
        const currentPageValues = this.paginatedSelectedMetadataForEdit.map(row => row.name);

        // Handle selections
        selectedRows.forEach(row => {
            if (!this.selectedMetadataMapForEdit[row.name]) {
                this.selectedMetadataMapForEdit[row.name] = row;
            }
        });

        // Handle deselections - only for current page items
        currentPageValues.forEach(name => {
            if (!selectedRows.find(row => row.name === name)) {
                delete this.selectedMetadataMapForEdit[name];
                // deletedRecCount++;
            }
        });

        // Update the list display
        this.selectedMetadataListToDisplayForEdit = Object.values(this.selectedMetadataMapForEdit);

        if (this.searchKeySMDForEdit) {
            this.selectedMetadataListToDisplayForEdit = this.selectedMetadataListToDisplayForEdit.filter(metadata =>
                metadata.name && metadata.name.toLowerCase().includes(this.searchKeySMDForEdit)
            );
        }

        this.paginatedSelectedMetadataForEdit = selectedRows.length<1 ? [] : this.paginatedSelectedMetadataForEdit;

        // Refresh pagination
        this.updatePaginatedSelectedMetadataForEdit();
        if (this.sortSelectedMetadataTableForEdit && this.sortedSelectedMdDataForEdit.length > 0) {
            this.selectedMetadataListToDisplayForEdit = this.sortedSelectedMdDataForEdit;
            this.sortSelectedMetadataTableForEdit = false;
            this.updatePaginatedSelectedMetadataForEdit();
        }
    }

    handleSortMetadataForEdit(event) {
        try {
            const { fieldName: sortedBy, sortDirection } = event.detail;
            // Sort only the records displayed on the current page
            const currentPageData = [...this.filteredMetadataForEdit];

            currentPageData.sort((a, b) => {
                let valueA = a[sortedBy] ? a[sortedBy].toLowerCase() : '';
                let valueB = b[sortedBy] ? b[sortedBy].toLowerCase() : '';
                return sortDirection === 'asc'
                    ? valueA.localeCompare(valueB)
                    : valueB.localeCompare(valueA);
            });

            this.filteredMetadataForEdit = [...currentPageData];
            //this.paginatedMetadata = [...currentPageData];
            this.sortDirectionMetadaForEdit = sortDirection;
            this.sortedByMetadataForEdit = sortedBy;
            this.updatePaginatedMetadataForEdit();
            this.updatePaginatedSelectedMetadataForEdit();
            // No need to reset pagination since sort is local to current page
            console.log('Sorting applied to current page only');
        } catch (error) {
            console.error('Error in handleSortMetadata:', error);
        }
    }

    @track sortedBySelectedMetadataForEdit;
    @track sortDirectionSelectedMetadaForEdit = 'asc';

    @track sortedSelectedMdDataForEdit = [];
    @track sortSelectedMetadataTableForEdit = false;

    handleSortSelectedMetadataForEdit(event) {
        console.log('In handleSortSelectedMetadata ::');
        this.sortedSelectedMdDataForEdit = [];
        this.sortSelectedMetadataTableForEdit = true;
        const { fieldName: sortedBy, sortDirection } = event.detail;
        let sortedData = [...this.selectedMetadataListToDisplayForEdit];
        sortedData.sort((a, b) => {
            let valueA = a[sortedBy] ? a[sortedBy].toString().toLowerCase() : '';
            let valueB = b[sortedBy] ? b[sortedBy].toString().toLowerCase() : '';

            return sortDirection === 'asc' ? valueA.localeCompare(valueB) : valueB.localeCompare(valueA);
        });
        console.log('after sort :: ' + JSON.stringify(sortedData));
        this.selectedMetadataListToDisplayForEdit = [...sortedData];
        this.sortedSelectedMdDataForEdit = [...sortedData];
        this.sortedBySelectedMetadataForEdit = sortedBy;
        this.sortDirectionSelectedMetadaForEdit = sortDirection;
        //this.selectedCurrentPage = 1;
        this.updatePaginatedSelectedMetadataForEdit();
        //this.selectedTotalPages = Math.ceil(this.selectedMetadataListToDisplay.length / this.selectedPageSize);
    }

    get showSelectedMDForEdit() {
        const count = Object.values(this.selectedMetadataMapForEdit).length;
        console.log('🔎 selectedMetadataMapForEdit count:', count);
        return count > 0;
    }
    
    mergeSelectedMetadataWithFullList(fullList) {
        const fullMap = {};
        fullList.forEach(item => {
            fullMap[item.value] = { ...item };
        });
    
        for (const key in this.selectedMetadataMapForEdit) {
            if (fullMap[key]) {
                this.selectedMetadataMapForEdit[key] = { ...fullMap[key] };
            }
        }
    
        this.selectedMetadataListToDisplayForEdit = Object.values(this.selectedMetadataMapForEdit);
        this.updatePaginatedSelectedMetadataForEdit(); // optional safety
    }

    @track disabledNextFromFindAndReplacePageForEdit = false;

    async handleNextFromMetadataPickerForEdit() {
        this.disabledNextFromFindAndReplacePageForEdit = true;
        
        this.searchTermForEdit = '';
        this.selectedTableSearchTermUSERForEdit = '';
        this.searchTermavailCusForEdit = '';
        this.searchTermselCusForEdit = '';
        this.searchTermSJForEdit = '';
        this.searchTermSelectedSJForEdit = '';
    
        this.selectedTablePageSizeForEdit = 10;
        this.pageSizeCSForEdit = 5;
        this.selectedPageSizeCSForEdit = 5;
        this.pageSizeSJForEdit = 5;
        this.selectedPageSizeSJForEdit = 5;
    
        // Data picker logic
        if (this.selectedDataForEdit === 'Users') {
            this.filteredDataForEdit = [...this.userDataforDatatableForEdit];
            this.refreshSelectedTableDataForEdit();
        } else if (this.selectedDataForEdit === 'Custom Settings') {
            this.updateSelectedCustomSettingsDataForEdit();
            this.updatePreselectedRowsForCSForEdit();
        } else if (this.selectedDataForEdit === 'Scheduled Jobs') {
            this.updateSelectedJobsDataForEdit();
            this.updatePreselectedRowsForEdit();
        }
    
        if (!this.parentOrg) {
            this.dispatchEvent(new ShowToastEvent({
                title: '',
                message: 'Please select org',
                variant: 'error'
            }));
            return;
        }
    
        this.showSpinnerNavigation = true;
    
        try {
            
            await Promise.all([
                this.fetchSearchAndReplaceRulesForEdit(),  
                this.fetchApexScriptsForEdit()             
            ]);
    
            // 👉 Set current visible list to ALL rules (initial state)
            this.findAndReplaceRulesForEdit = this.findAndReplaceRulesForBackendForEdit;

            console.log( 'this.findAndReplaceRulesForEdit = '+this.findAndReplaceRulesForEdit);
    
            this.updateSearchAndReplaceTableForEdit();
            this.updateSuffixTableForEdit();
            this.updatePaginationDetailsForEdit();
    
            // Show next screen
            this.showOnPageLoad = false;
            this.isMetadataPickerForEdit = false;
            this.showMetadataRetrievePageForEditTemplate = false;
            this.showFindAndReplacePageForEdit = true;
    
            // Set datatable flags
            this.showUsersDatatableForEdit = this.selectedDataForEdit === 'Users';
            this.showCustomSettingsDatatableForEdit = this.selectedDataForEdit === 'Custom Settings';
            this.showScheduledJobsDatatableForEdit = this.selectedDataForEdit === 'Scheduled Jobs';
    
            console.log('this.selectedMetadataListToDisplayForEdit --- ' + JSON.stringify(this.selectedMetadataListToDisplayForEdit));
            if (this.selectedMetadataListToDisplayForEdit.length !== 0) {
                this.formatMetadataForPackageXmlEdit();  
                this.generatePackageXmlForEdit();        
            }
            
    
        } catch (error) {
            console.error('Error while loading rules/scripts:', error);
            this.showToast('Error', 'Failed to load existing transformation rules or scripts.', 'error');
            this.disabledNextFromFindAndReplacePageForEdit = false;
        } finally {
            this.showSpinnerNavigation = false;
            this.disabledNextFromFindAndReplacePageForEdit = false;
        }
    }

    @track metadataPackageXmlContentForEdit = '';
    @track formattedMetadataListForEdit = [];

    formatMetadataForPackageXmlEdit() {
        const metadataMap = new Map();
    
        this.selectedMetadataListToDisplayForEdit.forEach(item => {
            const metadataType = item.metadataType || item.type;
            const metadataName = item.name;

            if (!metadataMap.has(metadataType)) {
                metadataMap.set(metadataType, []);
            }
            metadataMap.get(metadataType).push(metadataName);
        });
    
        this.formattedMetadataListForEdit = Array.from(metadataMap.entries()).map(([type, members]) => ({
            type,
            members
        }));
    
        console.log('formattedMetadataListForEdit --- ' + JSON.stringify(this.formattedMetadataListForEdit));
    }

    generatePackageXmlForEdit() {
        console.log('this.formattedMetadataListForEdit --- ' + JSON.stringify(this.formattedMetadataListForEdit));
    
        if (this.formattedMetadataListForEdit && this.formattedMetadataListForEdit.length > 0) {
            this.showSpinner = true;
    
            let packageXmlContent = `<?xml version="1.0" encoding="UTF-8"?>
            <Package xmlns="http://soap.sforce.com/2006/04/metadata">`;
    
            this.formattedMetadataListForEdit.forEach(metadata => {
                let metadataType = metadata.type === 'CustomLabels' ? 'CustomLabel' : metadata.type;
                console.log('type --- ' + metadataType);
    
                let members = metadata.members.length ? metadata.members : ['*'];
                console.log('members --- ' + members);
    
                packageXmlContent += `
                <types>${members.map(member => `<members>${member}</members>`).join('')}
                <name>${metadataType}</name>
                </types>`;
    
                if (metadataType === 'CustomMetadata') {
                    const uniqueMembers = [...new Set(members.map(member => member.split('.')[0]))];
    
                    packageXmlContent += `
                    <types>${uniqueMembers.map(member => `<members>${member}__mdt</members>`).join('')}
                    <name>CustomObject</name>
                    </types>`;
                }
            });
    
            packageXmlContent += `<version>59.0</version>
            </Package>`;
    
            this.metadataPackageXmlContentForEdit = packageXmlContent;
            console.log('metadataPackageXmlContent --- ' + this.metadataPackageXmlContentForEdit);
        }
    }
    
    // ****************** END OF EDIT METADATA RETRIEVAL PAGE CODE BLOCK ****************** //



    // ************** START OF METADATA TRANSFORMATION PAGE CODE BLOCK  ************************* //

    get getStepClass1ForEdit() {
        if (this.isMetadataPickerForEdit) {
            return 'progress-step active';
        }
        return `progress-step ${this.isDataPickerForEdit || this.showFindAndReplacePageForEdit || this.showCreateTemplatePageForEdit ? 'completed' : ''}`;
    }

    get getStepClass2ForEdit() {
        if (this.showFindAndReplacePageForEdit) {
            return 'progress-step active';
        }
        return `progress-step ${this.isDataPickerForEdit || this.showCreateTemplatePageForEdit ? 'completed' : ''}`;
    }

    get getStepClass3ForEdit() {
        if (this.isDataPickerForEdit) {
            return 'progress-step active';
        }
        return `progress-step ${this.showCreateTemplatePageForEdit ? 'completed' : ''}`;
    }

    get getStepClass4ForEdit() {
        if (this.showCreateTemplatePageForEdit) {
            return 'progress-step active';
        }
        return 'progress-step';
    }

    // Getters for line classes
    get getLine1ClassForEdit() {
        return `progress-line ${this.isDataPickerForEdit || this.showFindAndReplacePageForEdit || this.showCreateTemplatePageForEdit ? 'completed' : this.isMetadataPickerForEdit ? 'active' : ''}`;
    }

    get getLine2ClassForEdit() {
        return `progress-line ${this.isDataPickerForEdit || this.showCreateTemplatePageForEdit ? 'completed' : this.showFindAndReplacePageForEdit ? 'active' : ''}`;
    }

    get getLine3ClassForEdit() {
        return `progress-line ${this.showCreateTemplatePageForEdit ? 'completed' : this.isDataPickerForEdit ? 'active' : ''}`;
    }

    // Getters for step completion status
    get isStep1CompleteForEdit() {
        return this.isDataPickerForEdit || this.showFindAndReplacePageForEdit || this.showCreateTemplatePageForEdit;
    }

    get isStep2CompleteForEdit() {
        return this.isDataPickerForEdit || this.showCreateTemplatePageForEdit;
    }

    get isStep3CompleteForEdit() {
        return this.showCreateTemplatePageForEdit;
    }

    get isStep4CompleteForEdit() {
        return false;
    }

    @track showFindAndReplacePageForEdit = false;
    
    @track showCreateTemplatePageForEdit = false;
    @track showSpinnerNavigationForEdit = false;
    @track isShowModalForFindAndReplaceValidationForEdit = false;
    @track selectedDataForEdit = '';
    @track previousSelectedMaskingTypeForEdit = '';

    // Form fields
    @track selectedMaskingTypeForEdit = '';
    @track showSearchAndReplaceForEdit = false;
    @track showSuffixForEdit = false;
    @track selectedMetadataTypesForFindAndReplaceForEdit = [];
    @track searchKeyForEdit = '';
    @track replaceValueForEdit = '';
    @track suffixValueForEdit = '';

    // Data tables and rules
    @track findAndReplaceRulesForEdit = [];
    @track findAndReplaceRulesForBackendForEdit = [];
    @track findAndReplaceColumnsForEdit = findAndReplaceColumnsForEdit;
    @track suffixColumnsForEdit = suffixColumnsForEdit;
    @track searchColumnsForEdit = searchColumnsForEdit;

    // Pagination properties
    @track pageSizeForEdit = 5;
    @track pageSizeRulesForEdit = 5;
    @track pageSizeSuffixForEdit = 5;
    @track currentPageForEdit = 1;
    @track currentPageRulesForEdit = 1;
    @track currentPageSuffixForEdit = 1;
    @track totalPagesForEdit = 0;
    @track totalPagesRulesForEdit = 0;
    @track totalPagesSuffixForEdit = 0;
    @track searchTermRulesForEdit = '';
    @track searchTermSuffixForEdit = '';
    @track sortedBySearchForEdit = '';
    @track sortDirectionSearchForEdit = 'asc';
    @track sortedBySuffixForEdit = '';
    @track sortDirectionSuffixForEdit = 'asc';
    @track paginatedDataForEdit = [];
    @track hasSearchAndReplaceRulesForEdit = false;
    @track hasSuffixRulesForEdit = false;
    @track paginatedSearchAndReplaceDataForEdit = [];
    @track paginatedSuffixDataForEdit = [];
    @track isViewingFinalScreenForEdit = false;
    @track hasSelectedMetadataTypesForEdit = false;
    @track selectedMetadataTypesForSearchForEdit = [];
    @track selectedMetadataTypesForSuffixForEdit = [];
    @track hasSelectedMetadataTypesSearchForEdit = false;
    @track hasSelectedMetadataTypesSuffixForEdit = false;
    @track isShowModalForApexscriptValidationForEdit = false;
    @track isShowModalForSuffixValidationForEdit = false;
    @track isShowModalForFindAndReplaceValidationfortheallselectionForEdit = false;

    // Component options getters
    get pageSizeOptionsrulesForEdit() {
        return [5, 10, 25, 50];
    }

    get pageSizeOptionssuffixForEdit() {
        return [5, 10, 25, 50];
    }
    
    handleBackFromFindAndReplacePageForEdit() {
        this.showFindAndReplacePageForEdit = false;
        this.showMetadataRetrievePageForEditTemplate = true;
    }

    @track disableNextFromDataPickerForEdit = false;
        
    handleNextFromFindAndReplacePageForEdit() {
        console.log('🔁 handleNextFromFindAndReplacePageForEdit');
        this.disableNextFromDataPickerForEdit = true;
        console.log('this.disableNextFromDataPickerForEdit handleNextFromFindAndReplacePageForEdit ='+this.disableNextFromDataPickerForEdit);
    

        if (this.selectedMaskingTypeForEdit === 'Search & Replace') {
            console.log('this.selectedMaskingTypeForEdit=='+this.selectedMaskingTypeForEdit);

            if (this.searchKeyForEdit && !this.replaceValueForEdit) {
                console.log('this.searchKeyForEdit ='+this.searchKeyForEdit);
                this.isShowModalForFindAndReplaceValidationForEdit = true;
                this.showSuffixForEdit = false;
                return;
            } else if (this.searchKeyForEdit && this.replaceValueForEdit) {
                console.log('this.searchKeyForEdit else ='+this.searchKeyForEdit);
                console.log('this.replaceValueForEdit else='+this.replaceValueForEdit);
                // Clear form if both values are present
                this.isShowModalForFindAndReplaceValidationfortheallselectionForEdit = true;
                this.showSuffixForEdit = false;
                return;
            }
        }

        // Check for unsaved changes in Suffix
        if (this.selectedMaskingTypeForEdit === 'Suffix') {
            // Check if user selected metadata types and entered suffix value but didn't create a rule
            if (this.hasSelectedMetadataTypesSuffixForEdit && this.suffixValueForEdit) {
                this.isShowModalForSuffixValidationForEdit = true;
                return;
            }
        }

        // Check for unsaved changes in Apex Script
        if (this.selectedMaskingTypeForEdit === 'Apex Script') {
            // Check if user entered any script details but didn't add the script
            if (this.newScriptOrderForEdit || this.newScriptNameForEdit || this.newScriptDetailsForEdit) {
                this.isShowModalForApexscriptValidationForEdit = true;
                return;
            }
        }

      //  this.continueToDataPickerForEdit();

        this.isDataPickerForEdit = true;
        this.showFindAndReplacePageForEdit = false;
        this.showSpinnerInsideAccordionsDataForEdit = true;
    
        this.searchTermRulesForEdit = '';
        this.searchTermSuffixForEdit = '';
        this.searchTermapexScriptForEdit = '';
        this.pageSizeRulesForEdit = 5;
        this.pageSizeSuffixForEdit = 5;
        this.pageSizeApexForEdit = 5;
        this.currentPageRulesForEdit = 1;
        this.currentPageSuffixForEdit = 1;
        this.currentPageApexForEdit = 1;
    
        this.previousSelectedMaskingTypeForEdit = this.selectedMaskingTypeForEdit;
        this.updateSearchAndReplaceTableForEdit();
        this.updateSuffixTableForEdit();

       
    
        // Start chaining
        Promise.resolve()
    
            // ✅ USERS
            .then(() => {
                if (!this.hasFetchedUsersOnce) {
                    this.hasFetchedUsersOnce = true;
                    return this.fetchExistingSelectedUsersForEdit();
                }
                return Promise.resolve();
            })
    
            // ✅ CUSTOM SETTINGS
            .then(() => {
                if (!this.hasFetchedCustomSettingsOnce) {
                    this.hasFetchedCustomSettingsOnce = true;
                    return this.fetchSelectedCustomSettingsForEdit();
                    /*return fetchCustomSettings({ sandboxId: this.parentOrg }).then((result) => {
                        this.customSettingsDataforDatatableForEdit = result.map(objWrap => ({
                            customSettingName: String(objWrap.name)
                        }));
                        this.columnsForCustomSettingsForEdit = columnsForCustomSettingsForEdit;
                        return this.fetchSelectedCustomSettingsForEdit();
                    });*/
                }
                return Promise.resolve();
            })
    
            // ✅ SCHEDULED JOBS
            .then(() => {
                
                   return fetchScheduledJobs({ sandboxId: this.parentOrg }).then((result) => {
                    console.log('✅ Scheduled Jobs from Apex:', JSON.stringify(result));

                    this.scheduledJobsDataforDatatableForEdit = result.map(job => ({
                        jobName: String(job.jobName).trim(),
                        jobType: String(job.jobType).trim(),
                        apexClassName: String(job.apexClassName).trim(),
                        cronExpression: String(job.cronExpression).trim()
                    }));

                    this.columnsForScheduledJobsForEdit = columnsForScheduledJobsForEdit;
                    this.hasFetchedScheduledJobsOnce = true;

                    // ✅ If we already have user-modified data in the map, rehydrate instead of fetching again
                    if (this.selectedJobsMapForEdit && this.selectedJobsMapForEdit.size > 0) {
                        console.log('im going to rehydrateScheduledJobsSelectionForEdit');
                        this.rehydrateScheduledJobsSelectionForEdit();
                    } else {
                        console.log('im going to fetchSelectedScheduledJobsForEdit');
                        return this.fetchSelectedScheduledJobsForEdit();
                    }
                });

                
                  //  return this.fetchSelectedScheduledJobsForEdit(); // Only fetch if it's never hydrated
                    /*return fetchScheduledJobs({ sandboxId: this.parentOrg }).then((result) => {
                        console.log('✅ Scheduled Jobs from Apex:', JSON.stringify(result));
    
                        this.scheduledJobsDataforDatatableForEdit = result.map(job => ({
                            jobName: String(job.jobName).trim(),
                            jobType: String(job.jobType).trim(),
                            apexClassName: String(job.apexClassName).trim(),
                            cronExpression: String(job.cronExpression).trim()
                        }));
    
                        this.columnsForScheduledJobsForEdit = columnsForScheduledJobsForEdit;
                        this.hasFetchedScheduledJobsOnce = true;
    
                        // ✅ If we already have user-modified data in the map, rehydrate instead of fetching again
                        if (this.selectedJobsMapForEdit && this.selectedJobsMapForEdit.size > 0) {
                            this.rehydrateScheduledJobsSelectionForEdit();
                        } else {
                            return this.fetchSelectedScheduledJobsForEdit(); // Only fetch if it's never hydrated
                        }
                    });*/
                
              //  return Promise.resolve();
            })

    
            // ✅ Rehydrate based on current selection
            .then(() => {
                if (this.selectedDataForEdit === 'Users') {
                    this.filteredDataForEdit = [...this.userDataforDatatableForEdit];
                    this.updatePreselectedRowsForUsersForEdit();
                    this.refreshSelectedTableDataForEdit();
                } else if (this.selectedDataForEdit === 'Custom Settings') {
                    this.updateSelectedCustomSettingsDataForEdit();
                    this.updatePreselectedRowsForCSForEdit();
                } else if (this.selectedDataForEdit === 'Scheduled Jobs') {
                    this.updateSelectedJobsDataForEdit();
                    this.updatePreselectedRowsForEdit();
                 //   this.isSelectedScheduledJobsEmptyForEdit = this.selectedJobsTableDataForEdit.length === 0;
                }
            })
    
            // ✅ Finalize
            .finally(() => {
                this.selectedDataForEdit = ''; 
                this.isUsersSelectedForEdit = false;
                this.isCustomSettingsSelectedForEdit = false;
                this.isScheduledJobsSelectedForEdit = false;
                //this.showSpinnerInsideAccordionsDataForEdit = false;
                this.disableNextFromDataPickerForEdit = false;
                this.hasFetchedUsersOnce = false;
                this.hasFetchedCustomSettingsOnce = false;
                this.hasFetchedScheduledJobsOnce = false;
            })
    
            .catch((error) => {
                console.error('❌ Error during Next execution chain:', error);
                this.showSpinnerInsideAccordionsDataForEdit = false;
                this.disableNextFromDataPickerForEdit = false;
                this.hasFetchedUsersOnce = false;
                this.hasFetchedCustomSettingsOnce = false;
                this.hasFetchedScheduledJobsOnce = false;
                console.log('handleNextFromFindAndReplacePageForEdit Catch disableNextFromDataPickerForEdit ='+this.disableNextFromDataPickerForEdit);
            });
    }

    continueToDataPickerForEdit() {
        this.isDataPickerForEdit = true;
        this.showFindAndReplacePageForEdit = false;
        this.showSpinnerInsideAccordionsDataForEdit = true;
    
        this.searchTermRulesForEdit = '';
        this.searchTermSuffixForEdit = '';
        this.searchTermapexScriptForEdit = '';
        this.pageSizeRulesForEdit = 5;
        this.pageSizeSuffixForEdit = 5;
        this.pageSizeApexForEdit = 5;
        this.currentPageRulesForEdit = 1;
        this.currentPageSuffixForEdit = 1;
        this.currentPageApexForEdit = 1;
    
        this.previousSelectedMaskingTypeForEdit = this.selectedMaskingTypeForEdit;
        this.updateSearchAndReplaceTableForEdit();
        this.updateSuffixTableForEdit();

       
    
        // Start chaining
        Promise.resolve()
    
            // ✅ USERS
            .then(() => {
                if (!this.hasFetchedUsersOnce) {
                    this.hasFetchedUsersOnce = true;
                    return this.fetchExistingSelectedUsersForEdit();
                }
                return Promise.resolve();
            })
    
            // ✅ CUSTOM SETTINGS
            .then(() => {
                if (!this.hasFetchedCustomSettingsOnce) {
                    this.hasFetchedCustomSettingsOnce = true;
                    return this.fetchSelectedCustomSettingsForEdit();
                    /*return fetchCustomSettings({ sandboxId: this.parentOrg }).then((result) => {
                        this.customSettingsDataforDatatableForEdit = result.map(objWrap => ({
                            customSettingName: String(objWrap.name)
                        }));
                        this.columnsForCustomSettingsForEdit = columnsForCustomSettingsForEdit;
                        return this.fetchSelectedCustomSettingsForEdit();
                    });*/
                }
                return Promise.resolve();
            })
    
            // ✅ SCHEDULED JOBS
            .then(() => {
                
                   return fetchScheduledJobs({ sandboxId: this.parentOrg }).then((result) => {
                    console.log('✅ Scheduled Jobs from Apex:', JSON.stringify(result));

                    this.scheduledJobsDataforDatatableForEdit = result.map(job => ({
                        jobName: String(job.jobName).trim(),
                        jobType: String(job.jobType).trim(),
                        apexClassName: String(job.apexClassName).trim(),
                        cronExpression: String(job.cronExpression).trim()
                    }));

                    this.columnsForScheduledJobsForEdit = columnsForScheduledJobsForEdit;
                    this.hasFetchedScheduledJobsOnce = true;

                    // ✅ If we already have user-modified data in the map, rehydrate instead of fetching again
                    if (this.selectedJobsMapForEdit && this.selectedJobsMapForEdit.size > 0) {
                        this.rehydrateScheduledJobsSelectionForEdit();
                    } else {
                        return this.fetchSelectedScheduledJobsForEdit();
                    }
                });

                
                  //  return this.fetchSelectedScheduledJobsForEdit(); // Only fetch if it's never hydrated
                    /*return fetchScheduledJobs({ sandboxId: this.parentOrg }).then((result) => {
                        console.log('✅ Scheduled Jobs from Apex:', JSON.stringify(result));
    
                        this.scheduledJobsDataforDatatableForEdit = result.map(job => ({
                            jobName: String(job.jobName).trim(),
                            jobType: String(job.jobType).trim(),
                            apexClassName: String(job.apexClassName).trim(),
                            cronExpression: String(job.cronExpression).trim()
                        }));
    
                        this.columnsForScheduledJobsForEdit = columnsForScheduledJobsForEdit;
                        this.hasFetchedScheduledJobsOnce = true;
    
                        // ✅ If we already have user-modified data in the map, rehydrate instead of fetching again
                        if (this.selectedJobsMapForEdit && this.selectedJobsMapForEdit.size > 0) {
                            this.rehydrateScheduledJobsSelectionForEdit();
                        } else {
                            return this.fetchSelectedScheduledJobsForEdit(); // Only fetch if it's never hydrated
                        }
                    });*/
                
              //  return Promise.resolve();
            })

    
            // ✅ Rehydrate based on current selection
            .then(() => {
                if (this.selectedDataForEdit === 'Users') {
                    this.filteredDataForEdit = [...this.userDataforDatatableForEdit];
                    this.updatePreselectedRowsForUsersForEdit();
                    this.refreshSelectedTableDataForEdit();
                } else if (this.selectedDataForEdit === 'Custom Settings') {
                    this.updateSelectedCustomSettingsDataForEdit();
                    this.updatePreselectedRowsForCSForEdit();
                } else if (this.selectedDataForEdit === 'Scheduled Jobs') {
                    this.updateSelectedJobsDataForEdit();
                    this.updatePreselectedRowsForEdit();
                 //   this.isSelectedScheduledJobsEmptyForEdit = this.selectedJobsTableDataForEdit.length === 0;
                }
            })
    
            // ✅ Finalize
            .finally(() => {
                this.selectedDataForEdit = ''; 
                this.isUsersSelectedForEdit = false;
                this.isCustomSettingsSelectedForEdit = false;
                this.isScheduledJobsSelectedForEdit = false;
                //this.showSpinnerInsideAccordionsDataForEdit = false;
                this.disableNextFromDataPickerForEdit = false;
                this.hasFetchedUsersOnce = false;
                this.hasFetchedCustomSettingsOnce = false;
                this.hasFetchedScheduledJobsOnce = false;
            })
    
            .catch((error) => {
                console.error('❌ Error during Next execution chain:', error);
                this.showSpinnerInsideAccordionsDataForEdit = false;
                this.disableNextFromDataPickerForEdit = false;
                console.log('handleNextFromFindAndReplacePageForEdit Catch disableNextFromDataPickerForEdit ='+this.disableNextFromDataPickerForEdit);
                this.hasFetchedUsersOnce = false;
                this.hasFetchedCustomSettingsOnce = false;
                this.hasFetchedScheduledJobsOnce = false;
            });
    }
    

    @track showDataPickerPageForEdit = false;

    get maskingTypeOptionsForEdit() {
        return [
            { label: 'Search & Replace', value: 'Search & Replace' },
            { label: 'Suffix', value: 'Suffix' },
            { label: 'Apex Script', value: 'Apex Script' },
        ];
    }

    handleMaskingTypeForEdit(event) {
        const selectedValue = event.target.value;
        this.selectedMaskingTypeForEdit = selectedValue;
    
        if (this.selectedMaskingTypeForEdit === 'Search & Replace') {
            this.showSearchAndReplaceForEdit = true;
    
            // ✅ DO NOT re-fetch if already loaded
            if (!this.findAndReplaceRulesForBackendForEdit.some(rule => rule.maskingType === 'Search & Replace')) {
                this.fetchSearchAndReplaceRulesForEdit(); // only loads from server once
            }
    
            this.showSuffixForEdit = false;
            this.showapexScriptForEdit = false;
        } else if (this.selectedMaskingTypeForEdit === 'Suffix') {
            this.showSearchAndReplaceForEdit = false;
            this.showSuffixForEdit = true;
    
            if (!this.findAndReplaceRulesForBackendForEdit.some(rule => rule.maskingType === 'Suffix')) {
                this.fetchSearchAndReplaceRulesForEdit(); // loads suffix rules
            }
    
            this.showapexScriptForEdit = false;
        } else if (this.selectedMaskingTypeForEdit === 'Apex Script') {
            this.showapexScriptForEdit = true;
            this.showSearchAndReplaceForEdit = false;
            this.showSuffixForEdit = false;

            this.fetchApexScriptsForEdit();
        }
    
        // ✅ Always update visible list based on selected masking type
        this.findAndReplaceRulesForEdit = this.findAndReplaceRulesForBackendForEdit.filter(
            rule => rule.maskingType === this.selectedMaskingTypeForEdit
        );
    
        this.currentPageRulesForEdit = 1;
        this.updatePaginationForEdit();
    }
    

    get metadataOptionsForFindAndReplaceForEdit() {
        return [
            { label: 'Auth. Providers', value: 'AuthProvider' },
            { label: 'Custom Labels', value: 'CustomLabel' },
            { label: 'Custom Metadata', value: 'CustomMetadata' },
            { label: 'Named Credentials', value: 'NamedCredential' },
            { label: 'Remote Site Settings', value: 'RemoteSiteSetting' },
            { label: 'Workflow Alerts', value: 'WorkflowAlert' }
        ];
    }

    get metadataOptionsForSuffixForEdit() {
        return [
            { label: 'Custom Labels', value: 'CustomLabel' },
            { label: 'Connected App', value: 'ConnectedApp' },
            { label: 'Custom Metadata', value: 'CustomMetadata' },
            { label: 'Email Service', value: 'EmailServicesFunction' },
            { label: 'Workflow Alerts', value: 'WorkflowAlert' }
        ];
    }

    @track searchRulesForEdit = [];
    @track suffixRulesForEdit = [];
    @track preselectedRowsOfSearchRulesForEdit = [];
    @track preselectedRowsOfSuffixRulesForEdit = [];

    
    handleMetadataTypeForFindAndReplaceForEdit(event) {
        if (this.selectedMaskingTypeForEdit === 'Search & Replace') {
            this.selectedMetadataTypesForSearchForEdit = event.target.value;
            this.hasSelectedMetadataTypesSearchForEdit = this.selectedMetadataTypesForSearchForEdit.length > 0;
        } else if (this.selectedMaskingTypeForEdit === 'Suffix') {
            this.selectedMetadataTypesForSuffixForEdit = event.target.value;
            this.hasSelectedMetadataTypesSuffixForEdit = this.selectedMetadataTypesForSuffixForEdit.length > 0;
        }
    }
   
    fetchSearchAndReplaceRulesForEdit() {
       // this.disabledNextFromFindAndReplacePageForEdit = true;

        getMetadataMaskingRules({ refreshTemplateId: this.templateRecordId })
            .then(result => {
                if (result) {
                    // ---------- Search & Replace Rules ----------
                    let newSearchRules = [];
                    if (result.searchRules && result.searchRules.length > 0) {
                        newSearchRules = result.searchRules.map((item, index) => {
                            return { ...item, id: 's-server-' + index };
                        });
    
                        const existingSearchKeys = new Set(this.findAndReplaceRulesForBackendForEdit.map(rule =>
                            rule.metadataTypesForFindAndReplace + rule.maskingType + rule.searchKey
                        ));
    
                        const uniqueNewSearchRules = newSearchRules.filter(rule =>
                            !existingSearchKeys.has(rule.metadataTypesForFindAndReplace + rule.maskingType + rule.searchKey)
                        );
    
                        this.findAndReplaceRulesForBackendForEdit = [
                            ...this.findAndReplaceRulesForBackendForEdit,
                            ...uniqueNewSearchRules
                        ];
                    }
    
                    // ---------- Suffix Rules ----------
                    let newSuffixRules = [];
                    if (result.suffixRules && result.suffixRules.length > 0) {
                        newSuffixRules = result.suffixRules.map((item, index) => {
                            return { ...item, id: 'x-server-' + index };
                        });
    
                        const existingSuffixKeys = new Set(this.findAndReplaceRulesForBackendForEdit.map(rule =>
                            rule.metadataTypesForFindAndReplace + rule.maskingType
                        ));
    
                        const uniqueNewSuffixRules = newSuffixRules.filter(rule =>
                            !existingSuffixKeys.has(rule.metadataTypesForFindAndReplace + rule.maskingType)
                        );
    
                        this.findAndReplaceRulesForBackendForEdit = [
                            ...this.findAndReplaceRulesForBackendForEdit,
                            ...uniqueNewSuffixRules
                        ];
                    }
    
                    // Update filtered UI lists
                    this.findAndReplaceRulesForEdit = this.findAndReplaceRulesForBackendForEdit.filter(
                        rule => rule.maskingType === this.selectedMaskingTypeForEdit
                    );
    
                    // Set flags and update tables
                    this.hasSearchAndReplaceRulesForEdit = this.findAndReplaceRulesForBackendForEdit.some(
                        rule => rule.maskingType === 'Search & Replace'
                    );
    
                    this.hasSuffixRulesForEdit = this.findAndReplaceRulesForBackendForEdit.some(
                        rule => rule.maskingType === 'Suffix'
                    );
    
                    this.preselectedRowsOfSearchRulesForEdit = this.findAndReplaceRulesForBackendForEdit.filter(
                        rule => rule.maskingType === 'Search & Replace'
                    );
    
                    this.preselectedRowsOfSuffixRulesForEdit = this.findAndReplaceRulesForBackendForEdit.filter(
                        rule => rule.maskingType === 'Suffix'
                    );
    
                    this.currentPageRulesForEdit = 1;
                    this.currentPageSuffixForEdit = 1;
    
                    this.updatePaginationForEdit();
                  //  this.disabledNextFromFindAndReplacePageForEdit = false;
                }
            })
            .catch(error => {
                console.error('Error fetching metadata masking rules:', error);
               // this.disabledNextFromFindAndReplacePageForEdit = false;
            });
    }
   
    handleSearchForEdit(event) {
        this.searchKeyForEdit = event.target.value;
    }

    handleReplaceForEdit(event) {
        this.replaceValueForEdit = event.target.value;
    }

    handleSuffixValueForEdit(event) {
        this.suffixValueForEdit = event.target.value;
    }

    handleSearchRulesForEdit(event) {
        this.searchTermRulesForEdit = event.target.value;
        // Reset to first page when search term changes
        this.currentPageRulesForEdit = 1;

        // If search term is cleared, show all rules
        if (!this.searchTermRulesForEdit) {
            this.findAndReplaceRulesForEdit = this.findAndReplaceRulesForBackendForEdit.filter(
                rule => rule.maskingType === 'Search & Replace'
            );
        } else {
            // Filter based on search term
            const lcSearchTerm = this.searchTermRulesForEdit.toLowerCase();
            this.findAndReplaceRulesForEdit = this.findAndReplaceRulesForBackendForEdit
                .filter(rule => rule.maskingType === 'Search & Replace')
                .filter(record =>
                    Object.values(record).some(value =>
                        String(value).toLowerCase().includes(lcSearchTerm)
                    )
                );
        }
        this.updatePaginationForEdit();
    }
   
   /* handleSearchsuffix(event) {
        this.searchTermSuffixForEdit = event.target.value;
        // Reset to first page when search term changes
        this.currentPageSuffixForEdit = 1;

        // If search term is cleared, show all rules
        if (!this.searchTermSuffixForEdit) {
            this.findAndReplaceRulesForEdit = this.findAndReplaceRulesForBackendForEdit.filter(
                rule => rule.maskingType === 'Suffix'
            );
        } else {
            // Filter based on search term
            const lcSearchTerm = this.searchTermSuffixForEdit.toLowerCase();
            this.findAndReplaceRulesForEdit = this.findAndReplaceRulesForBackendForEdit
                .filter(rule => rule.maskingType === 'Suffix')
                .filter(record =>
                    Object.values(record).some(value =>
                        String(value).toLowerCase().includes(lcSearchTerm)
                    )
                );
        }
        this.updatePaginationForEdit();
    }*/
   
    get isFirstPagerulesForEdit() {
        return this.currentPageRulesForEdit === 1;
    }

    get isLastPagerulesForEdit() {
        return this.currentPageRulesForEdit === this.totalPagesRulesForEdit;
    }

    get isFirstPagesuffixForEdit() {
        return this.currentPageSuffixForEdit === 1;
    }

    get isLastPagesuffixForEdit() {
        return this.currentPageSuffixForEdit === this.totalPagesSuffixForEdit;
    }

    get selectedCurrentPagerulesForEdit() {
        return this.currentPageRulesForEdit;
    }

    get totalSelectedPagesrulesForEdit() {
        return this.totalPagesRulesForEdit;
    }

    get selectedCurrentPagesuffixForEdit() {
        return this.currentPageSuffixForEdit;
    }

    get totalSelectedPagessuffixForEdit() {
        return this.totalPagesSuffixForEdit;
    }

    // Pagination Handlers
    handlePageSizeChangeRulesForEdit(event) {
        this.pageSizeRulesForEdit = parseInt(event.target.value, 10);
        this.currentPageRulesForEdit = 1;
        this.updatePaginationForEdit();
    }
   
    handlePageSizeChangesuffixForEdit(event) {
        this.pageSizeSuffixForEdit = parseInt(event.target.value, 10);
        this.currentPageSuffixForEdit = 1;
        this.updatePaginationForEdit();
    }

    handleFirstPagerulesForEdit() {
        this.currentPageRulesForEdit = 1;
        this.updatePaginationForEdit();
    }

    handlePreviousPagerulesForEdit() {
        if (this.currentPageRulesForEdit > 1) {
            this.currentPageRulesForEdit--;
            this.updatePaginationForEdit();
        }
    }

    handleNextPagerulesForEdit() {
        if (this.currentPageRulesForEdit < this.totalPagesRulesForEdit) {
            this.currentPageRulesForEdit++;
            this.updatePaginationForEdit();
        }
    }

    handleLastPagerulesForEdit() {
        this.currentPageRulesForEdit = this.totalPagesRulesForEdit;
        this.updatePaginationForEdit();
    }

    handleFirstPagesuffixForEdit() {
        this.currentPageSuffixForEdit = 1;
        this.updatePaginationForEdit();
    }
   
    handlePreviousPagesuffixForEdit() {
        if (this.currentPageSuffixForEdit > 1) {
            this.currentPageSuffixForEdit--;
            this.updatePaginationForEdit();
        }
    }

    handleNextPagesuffixForEdit() {
        if (this.currentPageSuffixForEdit < this.totalPagesSuffixForEdit) {
            this.currentPageSuffixForEdit++;
            this.updatePaginationForEdit();
        }
    }

    handleLastPagesuffixForEdit() {
        this.currentPageSuffixForEdit = this.totalPagesSuffixForEdit;
        this.updatePaginationForEdit();
    }

    // Sorting Handlers
    handleSortSearchForEdit(event) {
        this.sortedBySearchForEdit = event.detail.fieldName;
        this.sortDirectionSearchForEdit = event.detail.sortDirection;
        this.sortDataForEdit('search');
    }

    handleSortSuffixForEdit(event) {
        this.sortedBySuffixForEdit = event.detail.fieldName;
        this.sortDirectionSuffixForEdit = event.detail.sortDirection;
        this.sortDataForEdit('suffix');
    }
   
    getSelectedMetadataTypesForEdit() {
        return this.selectedMaskingTypeForEdit === 'Search & Replace'
            ? this.selectedMetadataTypesForSearchForEdit
            : this.selectedMetadataTypesForSuffixForEdit;
    }
   
    // Rule Management
    handleCreateRuleForEdit() {
        console.log('I am in handleCreateRuleForEdit');
        if (!this.validateRuleForEdit()) {
            return;
        }
        console.log('this.findAndReplaceRulesForBackendForEdit handleCreateRuleForEdit='+this.findAndReplaceRulesForBackendForEdit);

        const newRules = [];
        const nextId = this.findAndReplaceRulesForBackendForEdit.length;
        const selectedMetadataTypes = this.getSelectedMetadataTypesForEdit();

        // Create a separate rule for each selected metadata type
        selectedMetadataTypes.forEach((metadataType, index) => {
            const baseRule = {
                id: nextId + index + 1,
                metadataType: metadataType, // ✅ This must match your datatable fieldName
                maskingType: this.selectedMaskingTypeForEdit
            };

            if (this.selectedMaskingTypeForEdit === 'Search & Replace') {
                // Check if a rule with same metadata type and search key already exists
                const duplicateRule = this.findAndReplaceRulesForBackendForEdit.find(
                    rule => rule.metadataType === metadataType &&
                        rule.maskingType === 'Search & Replace' &&
                        rule.searchKey?.trim().toLowerCase() === this.searchKeyForEdit?.trim().toLowerCase()
                );
                console.log('duplicateRule ='+duplicateRule);

                if (duplicateRule) {
                    this.showToast(
                        'Error',
                        `A Search & Replace rule for metadata type "${metadataType}" with search key "${this.searchKeyForEdit}" already exists!`,
                        'error'
                    );
                    return;
                }

                newRules.push({
                    ...baseRule,
                    searchKey: this.searchKeyForEdit.trim(),
                    replaceValue: this.replaceValueForEdit.trim()
                });
            } else if (this.selectedMaskingTypeForEdit === 'Suffix') {
                // For Suffix, keep existing validation - only one rule per metadata type
                const existingRule = this.findAndReplaceRulesForBackendForEdit.find(
                    rule => rule.metadataType === metadataType &&
                        rule.maskingType === 'Suffix'
                );

                if (existingRule) {
                    this.showToast(
                        'Error',
                        `A Suffix rule for metadata type "${metadataType}" already exists!`,
                        'error'
                    );
                    return;
                }

                newRules.push({
                    ...baseRule,
                    suffixValue: this.suffixValueForEdit.trim()
                });
            }
        });

        // Only proceed if we have valid rules to add
        if (newRules.length > 0) {
            // Add all new rules
            this.findAndReplaceRulesForBackendForEdit = [...this.findAndReplaceRulesForBackendForEdit, ...newRules];
            this.findAndReplaceRulesForEdit = this.findAndReplaceRulesForBackendForEdit.filter(
                rule => rule.maskingType === this.selectedMaskingTypeForEdit
            );

            this.resetFormForEdit();
            this.updatePaginationForEdit();
            
            // Show success toast
            const ruleCount = newRules.length;
            this.showToast(
                'Success',
                `${ruleCount} rule${ruleCount > 1 ? 's' : ''} created successfully`,
                'success'
            );
        }
    }
       
    // Update the resetForm method to handle both types
    resetFormForEdit() {
        if (this.selectedMaskingTypeForEdit === 'Search & Replace') {
            this.selectedMetadataTypesForSearchForEdit = [];
            this.hasSelectedMetadataTypesSearchForEdit = false;
            this.searchKeyForEdit = '';
            this.replaceValueForEdit = '';
        } else if (this.selectedMaskingTypeForEdit === 'Suffix') {
            this.selectedMetadataTypesForSuffixForEdit = [];
            this.hasSelectedMetadataTypesSuffixForEdit = false;
            this.suffixValueForEdit = '';
        } else if (this.selectedMaskingTypeForEdit === 'Apex Script') {
            this.newScriptOrderForEdit = '';
            this.newScriptNameForEdit = '';
            this.newScriptDetailsForEdit = '';
            // Also clear any validation warnings
            this.showValidationWarningsForEdit = false;
            this.validationWarningsForEdit = [];
        }
    }

    handleFindAndReplaceRowSelectionForEdit(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName.startsWith('delete')) {
            this.deleteRuleForEdit(row);
        }
    }
   
    validateRuleForEdit() {
        const selectedTypes = this.selectedMaskingTypeForEdit === 'Search & Replace'
            ? this.selectedMetadataTypesForSearchForEdit
            : this.selectedMetadataTypesForSuffixForEdit;

        if (!selectedTypes.length) {
            this.showToast('Error', 'No Metadata Types selected for Metadata Masking...', 'error');
            return false;
        }

        if (this.selectedMaskingTypeForEdit === 'Search & Replace') {
            if (!this.searchKeyForEdit) {
                this.showToast('Error', 'Search Key cannot be empty...', 'error');
                return false;
            }
            if (!this.replaceValueForEdit) {
                this.showToast('Error', 'Replace Value cannot be empty...', 'error');
                return false;
            }
            if (this.searchKeyForEdit === this.replaceValueForEdit) {
                this.showToast('Error', 'Search Key and Replace Value cannot be same...', 'error');
                return false;
            }
        } else if (this.selectedMaskingTypeForEdit === 'Suffix' && !this.suffixValueForEdit) {
            this.showToast('Error', 'Suffix Value cannot be empty...', 'error');
            return false;
        }

        return true;
    }

    createNewRuleForEdit() {
        const nextId = this.findAndReplaceRulesForBackendForEdit.length;
        const newRules = [];

        // Create a separate rule for each selected metadata type
        this.selectedMetadataTypesForFindAndReplaceForEdit.forEach((metadataType, index) => {
            const baseRule = {
                id: nextId + index + 1,
                metadataTypesForFindAndReplace: metadataType, // Single metadata type per rule
                maskingType: this.selectedMaskingTypeForEdit
            };

            if (this.selectedMaskingTypeForEdit === 'Search & Replace') {
                newRules.push({
                    ...baseRule,
                    searchKey: this.searchKeyForEdit,
                    replaceValue: this.replaceValueForEdit
                });
            } else {
                newRules.push({
                    ...baseRule,
                    suffixValue: this.suffixValueForEdit
                });
            }
        });

        return newRules;
    }
       
    deleteRuleForEdit(row) {
        try {
            this.findAndReplaceRulesForBackendForEdit = this.findAndReplaceRulesForBackendForEdit
                .filter(rule => rule.id !== row.id);

            this.findAndReplaceRulesForBackendForEdit = this.findAndReplaceRulesForBackendForEdit
                .map((record, index) => ({
                    ...record,
                    id: index + 1
                }));

            const isSearchRule = row.maskingType === 'Search & Replace';
            const filteredRules = this.findAndReplaceRulesForBackendForEdit.filter(
                rule => rule.maskingType === row.maskingType
            );

            if (isSearchRule) {
                const totalPages = Math.ceil(filteredRules.length / this.pageSizeRulesForEdit);
                if (this.currentPageRulesForEdit > totalPages) {
                    this.currentPageRulesForEdit = Math.max(1, totalPages);
                }
            } else {
                const totalPages = Math.ceil(filteredRules.length / this.pageSizeSuffixForEdit);
                if (this.currentPageSuffixForEdit > totalPages) {
                    this.currentPageSuffixForEdit = Math.max(1, totalPages);
                }
            }

            this.findAndReplaceRulesForEdit= filteredRules;
            this.updatePaginationForEdit();

            this.showToast(
                'Success',
                'Rule deleted successfully',
                'success'
            );
        } catch (error) {
            this.showToast(
                'Error',
                'Error deleting rule: ' + error.message,
                'error'
            );
            console.error('Error in deleteRule:', error);
        }
    }

    updatePaginationForEdit() {
        if (this.showCreateTemplatePageForEdit) {
            // On final screen, update both tables
            this.updateSearchAndReplaceTableForEdit();
            this.updateSuffixTableForEdit();
        } else {
            // During rule creation, update based on selected type
            if (this.selectedMaskingTypeForEdit === 'Search & Replace') {
                this.updateSearchAndReplaceTableForEdit();
            } else if (this.selectedMaskingTypeForEdit === 'Suffix') {
                this.updateSuffixTableForEdit();
            }
        }
    }
   
    updateSearchAndReplaceTableForEdit() {
        const searchRules = this.findAndReplaceRulesForBackendForEdit.filter(
            rule => rule.maskingType === 'Search & Replace'
        );

        let filteredData = [...searchRules];

        // Apply search term filtering
        if (this.searchTermRulesForEdit) {
            const lcSearchTerm = this.searchTermRulesForEdit.toLowerCase();
            filteredData = filteredData.filter(record =>
                Object.values(record).some(value =>
                    String(value).toLowerCase().includes(lcSearchTerm)
                )
            );
        }

        // Apply sorting before pagination
        if (this.sortedBySearchForEdit) {
            filteredData.sort((a, b) => {
                let valueA = a[this.sortedBySearchForEdit];
                let valueB = b[this.sortedBySearchForEdit];

                // Handle null/undefined values
                valueA = valueA === null || valueA === undefined ? '' : valueA;
                valueB = valueB === null || valueB === undefined ? '' : valueB;

                // Convert to lowercase if strings
                if (typeof valueA === 'string') {
                    valueA = valueA.toLowerCase();
                }
                if (typeof valueB === 'string') {
                    valueB = valueB.toLowerCase();
                }

                // Perform the comparison
                if (valueA < valueB) {
                    return this.sortDirectionSearchForEdit === 'asc' ? -1 : 1;
                }
                if (valueA > valueB) {
                    return this.sortDirectionSearchForEdit === 'asc' ? 1 : -1;
                }
                return 0;
            });
        }

        this.hasSearchAndReplaceRulesForEdit = searchRules.length > 0;
        this.totalPagesRulesForEdit = Math.ceil(filteredData.length / this.pageSizeRulesForEdit);

        if (this.currentPageRulesForEdit > this.totalPagesRulesForEdit) {
            this.currentPageRulesForEdit = Math.max(1, this.totalPagesRulesForEdit);
        }

        const startIndex = (this.currentPageRulesForEdit - 1) * this.pageSizeRulesForEdit;
        const endIndex = startIndex + this.pageSizeRulesForEdit;

        this.paginatedSearchAndReplaceDataForEdit = filteredData.slice(startIndex, endIndex);
    }
       
    updateSuffixTableForEdit() {
        const suffixRules = this.findAndReplaceRulesForBackendForEdit.filter(
            rule => rule.maskingType === 'Suffix'
        );

        let filteredData = [...suffixRules];

        // Apply search term filtering
        if (this.searchTermSuffixForEdit) {
            const lcSearchTerm = this.searchTermSuffixForEdit.toLowerCase();
            filteredData = filteredData.filter(record =>
                Object.values(record).some(value =>
                    String(value).toLowerCase().includes(lcSearchTerm)
                )
            );
        }

        // Apply sorting before pagination
        if (this.sortedBySuffixForEdit) {
            filteredData.sort((a, b) => {
                let valueA = a[this.sortedBySuffixForEdit];
                let valueB = b[this.sortedBySuffixForEdit];

                // Handle null/undefined values
                valueA = valueA === null || valueA === undefined ? '' : valueA;
                valueB = valueB === null || valueB === undefined ? '' : valueB;

                // Convert to lowercase if strings
                if (typeof valueA === 'string') {
                    valueA = valueA.toLowerCase();
                }
                if (typeof valueB === 'string') {
                    valueB = valueB.toLowerCase();
                }

                // Perform the comparison
                if (valueA < valueB) {
                    return this.sortDirectionSuffixForEdit === 'asc' ? -1 : 1;
                }
                if (valueA > valueB) {
                    return this.sortDirectionSuffixForEdit === 'asc' ? 1 : -1;
                }
                return 0;
            });
        }

        this.hasSuffixRulesForEdit = suffixRules.length > 0;
        this.totalPagesSuffixForEdit = Math.ceil(filteredData.length / this.pageSizeSuffixForEdit);

        if (this.currentPageSuffixForEdit > this.totalPagesSuffixForEdit) {
            this.currentPageSuffixForEdit = Math.max(1, this.totalPagesSuffixForEdit);
        }

        const startIndex = (this.currentPageSuffixForEdit - 1) * this.pageSizeSuffixForEdit;
        const endIndex = startIndex + this.pageSizeSuffixForEdit;

        this.paginatedSuffixDataForEdit = filteredData.slice(startIndex, endIndex);
    }
       
    sortDataForEdit(type) {
        let sortBy, sortDirection;
        if (type === 'search') {
            sortBy = this.sortedBySearchForEdit;
            sortDirection = this.sortDirectionSearchForEdit;
        } else {
            sortBy = this.sortedBySuffixForEdit;
            sortDirection = this.sortDirectionSuffixForEdit;
        }

        // Get the data for the correct type
        const dataToSort = type === 'search'
            ? this.findAndReplaceRulesForBackendForEdit.filter(rule => rule.maskingType === 'Search & Replace')
            : this.findAndReplaceRulesForBackendForEdit.filter(rule => rule.maskingType === 'Suffix');

        // Create a copy for sorting
        const sortedData = [...dataToSort];

        // Perform the sort
        sortedData.sort((a, b) => {
            let valueA = a[sortBy];
            let valueB = b[sortBy];

            // Handle null/undefined values
            valueA = valueA === null || valueA === undefined ? '' : valueA;
            valueB = valueB === null || valueB === undefined ? '' : valueB;

            // Convert to lowercase if strings
            if (typeof valueA === 'string') {
                valueA = valueA.toLowerCase();
            }
            if (typeof valueB === 'string') {
                valueB = valueB.toLowerCase();
            }

            // Perform the comparison
            if (valueA < valueB) {
                return sortDirection === 'asc' ? -1 : 1;
            }
            if (valueA > valueB) {
                return sortDirection === 'asc' ? 1 : -1;
            }
            return 0;
        });

        // Update the appropriate data array
        if (type === 'search') {
            this.findAndReplaceRulesForEdit = sortedData;
            const startIndex = (this.currentPageRulesForEdit - 1) * this.pageSizeRulesForEdit;
            const endIndex = startIndex + this.pageSizeRulesForEdit;
            this.paginatedSearchAndReplaceDataForEdit = sortedData.slice(startIndex, endIndex);
        } else {
            this.findAndReplaceRulesForEdit = sortedData;
            const startIndex = (this.currentPageSuffixForEdit - 1) * this.pageSizeSuffixForEdit;
            const endIndex = startIndex + this.pageSizeSuffixForEdit;
            this.paginatedSuffixDataForEdit = sortedData.slice(startIndex, endIndex);
        }
    }
   
    get totalRecordsrulesForEdit() {
        if (this.showCreateTemplatePageForEdit) {
            // If we're on the final screen, always count Search & Replace rules
            return this.findAndReplaceRulesForBackendForEdit.filter(
                rule => rule.maskingType === 'Search & Replace'
            ).length;
        }
        // During creation, show filtered view
        return this.findAndReplaceRulesForEdit.filter(
            rule => rule.maskingType === 'Search & Replace'
        ).length;
    }

    get totalRecordssuffixForEdit() {
        if (this.showCreateTemplatePageForEdit) {
            // If we're on the final screen, always count Suffix rules
            return this.findAndReplaceRulesForBackendForEdit.filter(
                rule => rule.maskingType === 'Suffix'
            ).length;
        }
        // During creation, show filtered view
        return this.findAndReplaceRulesForEdit.filter(
            rule => rule.maskingType === 'Suffix'
        ).length;
    }
   
    handleSearchsuffixForEdit(event) {
        this.searchTermSuffixForEdit = event.target.value;
        // Reset to first page when search term changes
        this.currentPageSuffixForEdit = 1;

        // If search term is cleared, show all rules
        if (!this.searchTermSuffixForEdit) {
            this.findAndReplaceRulesForEdit = this.findAndReplaceRulesForBackendForEdit.filter(
                rule => rule.maskingType === 'Suffix'
            );
        } else {
            // Filter based on search term
            const lcSearchTerm = this.searchTermSuffixForEdit.toLowerCase();
            this.findAndReplaceRulesForEdit = this.findAndReplaceRulesForBackendForEdit
                .filter(rule => rule.maskingType === 'Suffix')
                .filter(record =>
                    Object.values(record).some(value =>
                        String(value).toLowerCase().includes(lcSearchTerm)
                    )
                );
        }
        this.updatePaginationForEdit();
    }

    // Handlers for Apex Script modal
    handleYesInApexScriptModalForEdit() {
        this.disableNextFromDataPickerForEdit = true;
        this.isShowModalForApexscriptValidationForEdit = false;
        this.resetFormForEdit(); // Clear form fields
        this.continueToDataPickerForEdit();
    }

    handleNoInApexScriptModalForEdit() {
        this.isShowModalForApexscriptValidationForEdit = false;
        this.showFindAndReplacePageForEdit = true;
        this.isDataPickerForEdit = false;
        // Stay on the current page
    }
       
    // Handlers for Suffix modal
    handleYesInSuffixModalForEdit() {
        this.disableNextFromDataPickerForEdit = true;
        this.isShowModalForSuffixValidationForEdit = false;
        this.resetFormForEdit(); 
        this.continueToDataPickerForEdit();
    }

    handleNoInSuffixModalForEdit() {
        this.isShowModalForSuffixValidationForEdit = false;
        this.showFindAndReplacePageForEdit = true;
        this.isDataPickerForEdit = false;
    }

    handleYesInFindAndReplaceModalForEdit() {
        this.disableNextFromDataPickerForEdit = true;
        this.isShowModalForFindAndReplaceValidationForEdit = false;
        this.isShowModalForFindAndReplaceValidationfortheallselectionForEdit = false;
        this.resetFormForEdit();
        this.continueToDataPickerForEdit();
        
    }

    handleNoInFindAndReplaceModalForEdit() {
        this.isShowModalForFindAndReplaceValidationForEdit = false;
        this.isShowModalForFindAndReplaceValidationfortheallselectionForEdit = false;
        this.showFindAndReplacePageForEdit = true;
        this.isDataPickerForEdit = false;
    }
   

    /****************** START OF EDIT APEX SCRIPT PAGE CODE BLOCK ******************/
    @track scriptsForEdit = [];
    @track originalScriptsForEdit = [];
    @track newScriptOrderForEdit = '';
    @track newScriptNameForEdit = '';
    @track newScriptDetailsForEdit = '';
    @track searchTermapexScriptForEdit = '';

    // Pagination variables
    @track pageSizeApexForEdit = 5;
    @track currentPageApexForEdit = 1;
    @track sortedByapexForEdit = 'order';
    @track sortDirectionapexForEdit = 'asc';
    @track selectedCurrentPageApexscriptForEdit = 1;
    @track totalSelectedPagesApexscriptForEdit = 1;
    @track totalRecordsApexscriptForEdit = 0;
    @track showapexScriptForEdit = false;
    @track selectedMaskingTypeForEdit = '';
    @track validationWarningsForEdit = [];
    @track showValidationWarningsForEdit = false;
    validateDebounceTimeoutForEdit;
    @track isDataPickerForEdit = false;

    columnsForEdit = [
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
            fieldName: 'ScriptName',
            type: 'text',
            sortable: true
        },
        {
            label: 'Script Details',
            fieldName: 'ScriptData',
            type: 'text',
            sortable: true
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Delete', name: 'delete' }
                ]
            }
        }
    ];
   
    fetchApexScriptsForEdit() {
       // this.disabledNextFromFindAndReplacePageForEdit = true;
        readCSVFile({ recordId: this.templateRecordId })
            .then(result => {
                if (result && result.length > 0) {
                    const newScripts = result.map((item, index) => ({
                        id: 'apex-server-' + index,
                        order: parseInt(item.order, 10),
                        ScriptName: item.scriptName,       // Fix case here
                        ScriptData: item.scriptData        // Fix case here
                    }));
    
                    const existingKeys = new Set(
                        this.originalScriptsForEdit.map(script =>
                            `${script.order}-${script.ScriptName}-${script.ScriptData}`
                        )
                    );
    
                    const uniqueNewScripts = newScripts.filter(script =>
                        !existingKeys.has(`${script.order}-${script.ScriptName}-${script.ScriptData}`)
                    );
    
                    this.originalScriptsForEdit = [
                        ...this.originalScriptsForEdit,
                        ...uniqueNewScripts
                    ].sort((a, b) => a.order - b.order);
    
                    this.scriptsForEdit = [...this.originalScriptsForEdit];
                    // this.hasapexScriptForEdit = this.originalScriptsForEdit.length > 0;
                    this.currentPageApexForEdit = 1;
                    this.updatePaginationDetailsForEdit();
                  //  this.disabledNextFromFindAndReplacePageForEdit = false;
                }
            })
            .catch(error => {
                console.error('Error loading Apex Scripts:', error);
              //  this.disabledNextFromFindAndReplacePageForEdit = false;
            });
    }

    pageSizeOptionsApexForEdit = [
        { label: '5', value: 5 },
        { label: '10', value: 10 },
        { label: '25', value: 25 },
        { label: '50', value: 50 }
    ];

    get hasapexScriptForEdit() {
        return this.originalScriptsForEdit && this.originalScriptsForEdit.length > 0;
    }

    get hasValidationIssuesForEdit() {
        return this.validationWarningsForEdit && this.validationWarningsForEdit.length > 0;
    }

    get hasValidationErrorsForEdit() {
        return this.validationWarningsForEdit && this.validationWarningsForEdit.length > 0;
    }

    get scriptDetailsContainerClassForEdit() {
        let baseClass = 'slds-textarea_container';

        if (this.hasValidationIssuesForEdit) {
            const hasErrors = this.validationWarningsForEdit.some(warning =>
                warning.includes('bracket') ||
                warning.includes('Error during validation'));

            if (hasErrors) {
                return `${baseClass} has-error`;
            } else {
                return `${baseClass} has-warning`;
            }
        }
        return baseClass;
    }

    get validationSummaryForEdit() {
        if (!this.hasValidationIssuesForEdit) return '';

        const errorCount = this.validationWarningsForEdit.filter(warning =>
            warning.includes('bracket') ||
            warning.includes('Error during validation')).length;

        const warningCount = this.validationWarningsForEdit.filter(warning =>
            warning.startsWith('Warning:')).length;

        const suggestionCount = this.validationWarningsForEdit.filter(warning =>
            warning.startsWith('Suggestion:')).length;

        if (errorCount > 0) {
            return `${errorCount} syntax ${errorCount === 1 ? 'error' : 'errors'} found - Add button is disabled`;
        } else if (warningCount > 0) {
            return `${warningCount} ${warningCount === 1 ? 'warning' : 'warnings'} found`;
        } else if (suggestionCount > 0) {
            return `${suggestionCount} ${suggestionCount === 1 ? 'suggestion' : 'suggestions'} available`;
        }
        return 'Validation issues found';
    }
   
    get validationIconNameForEdit() {
        if (!this.hasValidationIssuesForEdit) return '';

        const hasErrors = this.validationWarningsForEdit.some(warning =>
            warning.includes('bracket') ||
            warning.includes('Error during validation'));

        if (hasErrors) {
            return 'utility:error';
        }

        const hasWarnings = this.validationWarningsForEdit.some(warning =>
            warning.startsWith('Warning:'));

        if (hasWarnings) {
            return 'utility:warning';
        }

        return 'utility:info';
    }

    get validationIconVariantForEdit() {
        if (!this.hasValidationIssuesForEdit) return '';

        const hasErrors = this.validationWarningsForEdit.some(warning =>
            warning.includes('bracket') ||
            warning.includes('Error during validation'));

        if (hasErrors) {
            return 'error';
        }

        return 'warning';
    }

    get validationMessagesByTypeForEdit() {
        if (!this.validationWarningsForEdit || this.validationWarningsForEdit.length === 0) {
            return [];
        }

        // Group messages by type
        const errors = [];
        const warnings = [];
        const suggestions = [];

        this.validationWarningsForEdit.forEach((message, index) => {
            const messageObj = {
                id: `message-${index}`,
                text: message.replace(/^(Suggestion:|Warning:)\s+/, ''),
                style: ''
            };

            if (message.startsWith('Suggestion:')) {
                messageObj.style = 'color: #0070d2';
                suggestions.push(messageObj);
            } else if (message.startsWith('Warning:')) {
                messageObj.style = 'color: #706e6b';
                warnings.push(messageObj);
            } else if (message.includes('bracket') || message.includes('Error during validation')) {
                messageObj.style = 'color: #c23934';
                errors.push(messageObj);
            } else {
                messageObj.style = 'color: #706e6b';
                warnings.push(messageObj);
            }
        });

        const groups = [];

        if (errors.length > 0) {
            groups.push({
                type: 'errors',
                heading: 'Syntax Errors',
                icon: 'utility:error',
                variant: 'error',
                messages: errors
            });
        }

        if (warnings.length > 0) {
            groups.push({
                type: 'warnings',
                heading: 'Warnings',
                icon: 'utility:warning',
                variant: 'warning',
                messages: warnings
            });
        }

        if (suggestions.length > 0) {
            groups.push({
                type: 'suggestions',
                heading: 'Suggestions',
                icon: 'utility:info',
                variant: 'info',
                messages: suggestions
            });
        }

        return groups;
    }
   
    toggleValidationPanelForEdit() {
        this.showValidationWarningsForEdit = !this.showValidationWarningsForEdit;
    }

    get totalPagesApexForEdit() {
        return Math.ceil(this.scriptsForEdit.length / this.pageSizeApexForEdit);
    }

    get isFirstPageapexForEdit() {
        return this.currentPageApexForEdit === 1;
    }

    get isLastPageapexForEdit() {
        return this.currentPageApexForEdit === this.totalPagesApexForEdit;
    }

    get paginatedScriptsForEdit() {
        const start = (this.currentPageApexForEdit - 1) * this.pageSizeApexForEdit;
        const end = start + this.pageSizeApexForEdit;
        return this.scriptsForEdit.slice(start, end);
    }

    get showApexScriptContentForEdit() {
        return this.showapexScriptForEdit && this.selectedMaskingTypeForEdit === 'Apex Script';
    }
   
    handleSearchApexScriptsForEdit(event) {
        this.searchTermapexScriptForEdit = event.target.value;
        this.currentPageApexForEdit = 1;

        if (!this.searchTermapexScriptForEdit) {
            this.scriptsForEdit = [...this.originalScriptsForEdit];
        } else {
            const searchTerm = this.searchTermapexScriptForEdit.toLowerCase();
            this.scriptsForEdit = this.originalScriptsForEdit.filter(script =>
                script.ScriptName.toLowerCase().includes(searchTerm) ||
                script.ScriptData.toLowerCase().includes(searchTerm) ||
                script.order.toString().includes(searchTerm)
            );
        }
        this.updatePaginationDetailsForEdit();
    }
   
    updatePaginationDetailsForEdit() {
        this.totalSelectedPagesApexscriptForEdit = this.totalPagesApexForEdit;
        this.selectedCurrentPageApexscriptForEdit = this.currentPageApexForEdit;
        this.totalRecordsApexscriptForEdit = this.scriptsForEdit.length;
    }

    handleOrderChangeForEdit(event) {
        this.newScriptOrderForEdit = event.target.value;
    }

    handleNameChangeForEdit(event) {
        this.newScriptNameForEdit = event.target.value;
    }

    handleDetailsChangeForEdit(event) {
        this.newScriptDetailsForEdit = event.target.value;
        // Validate with debounce for better performance
        if (this.validateDebounceTimeoutForEdit) {
            clearTimeout(this.validateDebounceTimeoutForEdit);
        }

        this.validateDebounceTimeoutForEdit = setTimeout(() => {
            this.validateCurrentScriptForEdit(true); // true = show warnings only, not errors
        }, 500); // Validate after 0.5 seconds of inactivity
    }
   
    validateScriptSyntaxForEdit(scriptCode) {
        //if (!scriptCode) return { isValid: false, errors: ['Script details cannot be empty'] };

        try {
            const errors = [];

            // Check for balanced brackets/parentheses/braces
            const openBrackets = [];
            const bracketPairs = {
                '(': ')',
                '{': '}',
                '[': ']'
            };

            // Track if we're inside a string or comment to ignore brackets there
            let inSingleQuoteString = false;
            let inDoubleQuoteString = false;
            let inLineComment = false;
            let inBlockComment = false;

            for (let i = 0; i < scriptCode.length; i++) {
                const char = scriptCode[i];
                const nextChar = scriptCode[i + 1] || '';

                // Handle string and comment tracking
                if (char === '/' && nextChar === '/' && !inSingleQuoteString && !inDoubleQuoteString && !inBlockComment) {
                    inLineComment = true;
                } else if (char === '/' && nextChar === '*' && !inSingleQuoteString && !inDoubleQuoteString && !inLineComment) {
                    inBlockComment = true;
                } else if (char === '*' && nextChar === '/' && inBlockComment) {
                    inBlockComment = false;
                    i++; // Skip the next character
                } else if (char === '\n' && inLineComment) {
                    inLineComment = false;
                } else if (char === "'" && !inDoubleQuoteString && !inLineComment && !inBlockComment) {
                    // Toggle single quote string if not escaped
                    if (i > 0 && scriptCode[i - 1] !== '\\') {
                        inSingleQuoteString = !inSingleQuoteString;
                    }
                } else if (char === '"' && !inSingleQuoteString && !inLineComment && !inBlockComment) {
                    // Toggle double quote string if not escaped
                    if (i > 0 && scriptCode[i - 1] !== '\\') {
                        inDoubleQuoteString = !inDoubleQuoteString;
                    }
                }

                // Check for brackets only when not in a string or comment
                if (!inSingleQuoteString && !inDoubleQuoteString && !inLineComment && !inBlockComment) {
                    if (char === '(' || char === '{' || char === '[') {
                        openBrackets.push({ char, position: i });
                    } else if (char === ')' || char === '}' || char === ']') {
                        const lastOpen = openBrackets.pop();

                        if (!lastOpen) {
                            errors.push(`Extra closing bracket '${char}' at position ${i + 1}`);
                        } else if (bracketPairs[lastOpen.char] !== char) {
                            errors.push(`Mismatched bracket at position ${i + 1}: expected '${bracketPairs[lastOpen.char]}', found '${char}'`);
                        }
                    }
                }
            }

            if (openBrackets.length > 0) {
                openBrackets.forEach(bracket => {
                    errors.push(`Unclosed '${bracket.char}' at position ${bracket.position + 1}`);
                });
            }

            // Check for semicolons at end of statements
            const lines = scriptCode.split('\n');
            for (let i = 0; i < lines.length; i++) {
                let line = lines[i].trim();

                // Skip empty lines and comments
                if (!line || line.startsWith('//') || line.startsWith('/*') || line.endsWith('*/')) {
                    continue;
                }

                // Skip lines that end with opening or closing braces
                if (line.endsWith('{') || line.endsWith('}')) {
                    continue;
                }

                // Skip if/for/while statements without a body (just a condition)
                if (/^\s*(if|else if|for|while|else)\s*\(.*\)\s*$/i.test(line)) {
                    continue;
                }

                // Skip annotations - lines that start with @
                if (line.trim().startsWith('@')) {
                    continue;
                }

                // Check if line needs a semicolon - only suggest it rather than treating it as an error
                if (!line.endsWith(';')) {
                    errors.push(`Suggestion: Line ${i + 1} may need a semicolon: "${line}"`);
                }
            }

            // Check for Apex specific patterns - but be case-insensitive
            if (/\bclass\b/i.test(scriptCode) && !/(public|private|global)\s+class/i.test(scriptCode)) {
                errors.push('Suggestion: Class definition should include an access modifier (public, private, or global)');
            }

            // Check for common errors in conditions
            const ifConditions = scriptCode.match(/if\s*\((.*?)\)/g) || [];
            for (const condition of ifConditions) {
                const innerCondition = condition.match(/if\s*\((.*?)\)/)[1];

                // Check for assignment in condition (= instead of ==)
                if (/ = /.test(innerCondition) && !/ == /.test(innerCondition) && !/ != /.test(innerCondition) && !/ >= /.test(innerCondition) && !/ <= /.test(innerCondition)) {
                    errors.push(`Warning: Possible assignment in condition: "${condition}". Did you mean to use == instead of =?`);
                }
            }

            // Check for SOQL-specific issues
            const soqlPatterns = [
                { regex: /select\s+.*\s+from\s+/i, keywords: ['select', 'from'] },
                { regex: /\bwhere\b/i, keywords: ['where'] },
                { regex: /\border\s+by\b/i, keywords: ['order by'] },
                { regex: /\bgroup\s+by\b/i, keywords: ['group by'] },
                { regex: /\bhaving\b/i, keywords: ['having'] },
                { regex: /\blimit\b/i, keywords: ['limit'] }
            ];

            // Check for SOQL queries without LIMIT clause
            if (/select\s+.*\s+from\s+/i.test(scriptCode) && !/\blimit\b/i.test(scriptCode)) {
                errors.push('Warning: SOQL query is missing LIMIT clause, which can lead to governor limit issues');
            }

            return {
                isValid: errors.length === 0,
                errors: errors
            };
        } catch (error) {
            return {
                isValid: false,
                errors: ['Error during validation: ' + error.message]
            };
        }
    }
   
    // Add this method to dismiss validation warnings
    dismissValidationWarningsForEdit() {
        // We don't want to hide the validation warnings if there are errors
        // Only allow dismissing if there are only suggestions
        const hasErrors = this.validationWarningsForEdit.some(warning =>
            warning.includes('bracket') ||
            warning.includes('Error during validation') ||
            warning.startsWith('Warning:'));

        if (!hasErrors) {
            this.validationWarningsForEdit = [];
        } else {
            // Show a toast message explaining why it can't be dismissed
            this.showToast('Info', 'Please fix validation issues before dismissing this panel.', 'info');
        }
    }

    // Add this method to validate on blur
    validateOnBlurForEdit() {
        this.validateCurrentScriptForEdit(true);
    }
   
    validateCurrentScriptForEdit(warningsOnly = false) {
        const result = this.validateScriptSyntaxForEdit(this.newScriptDetailsForEdit);

        // Filter warnings vs. errors
        const criticalErrors = result.errors.filter(err =>
            !err.startsWith('Suggestion:') &&
            !err.startsWith('Warning:') &&
            (err.includes('bracket') || err.includes('Error during validation'))
        );

        const warnings = result.errors.filter(err =>
            err.startsWith('Warning:') ||
            (!err.includes('bracket') && !err.includes('Error during validation') && !err.startsWith('Suggestion:'))
        );

        const suggestions = result.errors.filter(err =>
            err.startsWith('Suggestion:')
        );

        // Store all issues in the warnings array
        this.validationWarningsForEdit = [...criticalErrors, ...warnings, ...suggestions];

        // Only show critical errors as toast messages that block submission
        if (!warningsOnly && criticalErrors.length > 0) {
            this.showToast('Syntax Errors', `Please correct syntax errors before continuing.`, 'error');
            return false;
        }

        // Return true if there are no critical errors
        return criticalErrors.length === 0;
    }
   
    // Added this getter to replace the direct function call
    get formattedWarningsForEdit() {
        return this.validationWarningsForEdit.map((warning, index) => {
            let cssClass = 'warning-text';

            if (warning.startsWith('Suggestion:')) {
                cssClass = 'suggestion-text';
            } else if (warning.startsWith('Warning:')) {
                cssClass = 'warning-text';
            } else if (warning.includes('bracket') || warning.includes('Error during validation')) {
                cssClass = 'error-text';
            }

            return {
                id: index.toString(), // Unique key for the template iteration
                message: warning,
                class: cssClass
            };
        });
    }
   
    handleAddScriptForEdit() {
        if (!this.newScriptOrderForEdit || !this.newScriptNameForEdit || !this.newScriptDetailsForEdit) {
            let missingFields = [];

            if (!this.newScriptOrderForEdit) missingFields.push('Order');
            if (!this.newScriptNameForEdit) missingFields.push('Script Name');
            if (!this.newScriptDetailsForEdit) missingFields.push('Script Details');

            const message = `${missingFields.join(', ')} are required`;
            this.showToast('Error', message, 'error');
            return;
        }

        // Validate script syntax before adding
        if (!this.validateCurrentScriptForEdit()) {
            return;
        }

        const orderNum = parseInt(this.newScriptOrderForEdit, 10);
        // Check if the order is less than or equal to 0
        if (orderNum <= 0) {
            this.showToast('Error', 'Order must start from 1. Please enter a valid positive order number.', 'error');
            return;
        }
        console.log('Before adding - originalScripts:', [...this.originalScriptsForEdit]);

        // Check if a script with the same name already exists
        if (this.originalScriptsForEdit.some(script => script.ScriptName === this.newScriptNameForEdit)) {
            this.showToast('Error', `Script with name "${this.newScriptNameForEdit}" already exists!`, 'error');
            return;
        }

        // Check if script with this order already exists
        if (this.originalScriptsForEdit.some(script => script.order === orderNum)) {
            this.showToast('Error', `Script with order ${orderNum} already exists!`, 'error');
            return;
        }

        // Check for sequential order
        // Check for sequential order
        if (orderNum > 1) {
            // Find the highest existing order
            const existingOrders = this.originalScriptsForEdit.map(script => script.order);
            const highestOrder = existingOrders.length > 0 ? Math.max(...existingOrders) : 0;

            // New order should be exactly one more than the highest existing order
            if (orderNum !== highestOrder + 1) {
                this.showToast('Error', `Please add script with order ${highestOrder + 1} next!`, 'error');
                return;
            }
        }

        const script = {
            id: Date.now().toString(),
            order: orderNum,
            ScriptName: this.newScriptNameForEdit,
            ScriptData: this.newScriptDetailsForEdit || ''
        };
        // Reset validation warnings after successful addition
        this.showValidationWarningsForEdit = false;
        this.validationWarningsForEdit = [];
        console.log('New script to be added:', script);

        this.originalScriptsForEdit = [...this.originalScriptsForEdit, script].sort((a, b) => a.order - b.order);
        console.log('After adding - originalScripts:', [...this.originalScriptsForEdit]);

        if (this.searchTermapexScriptForEdit) {
            const searchTerm = this.searchTermapexScriptForEdit.toLowerCase();
            this.scriptsForEdit = this.originalScriptsForEdit.filter(script =>
                script.ScriptName.toLowerCase().includes(searchTerm) ||
                script.ScriptData.toLowerCase().includes(searchTerm) ||
                script.order.toString().includes(searchTerm)
            );
        } else {
            this.scriptsForEdit = [...this.originalScriptsForEdit];
        }

        this.clearApexScriptFormForEdit();
        this.updatePaginationDetailsForEdit();
        this.showToast('Success', 'Script added successfully', 'success');
    }
   
    clearApexScriptFormForEdit() {
        this.newScriptOrderForEdit = '';
        this.newScriptNameForEdit = '';
        this.newScriptDetailsForEdit = '';
    }

    handleRowActionApexScriptForEdit(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'delete') {
            this.deleteScriptForEdit(row.id);
        }
    }

    deleteScriptForEdit(scriptId) {
        this.originalScriptsForEdit = this.originalScriptsForEdit.filter(script => script.id !== scriptId);

        if (this.searchTermapexScriptForEdit) {
            const searchTerm = this.searchTermapexScriptForEdit.toLowerCase();
            this.scriptsForEdit = this.originalScriptsForEdit.filter(script =>
                script.ScriptName.toLowerCase().includes(searchTerm) ||
                script.ScriptData.toLowerCase().includes(searchTerm) ||
                script.order.toString().includes(searchTerm)
            );
        } else {
            this.scriptsForEdit = [...this.originalScriptsForEdit];
        }

        this.updatePaginationDetailsForEdit();
        this.showToast('Success', 'Script deleted successfully', 'success');
    }
   
    handlePageSizeChangeApexForEdit(event) {
        this.pageSizeApexForEdit = parseInt(event.target.value, 10);
        this.currentPageApexForEdit = 1;
        this.updatePaginationDetailsForEdit();
    }

    handleFirstapexForEdit() {
        this.currentPageApexForEdit = 1;
        this.updatePaginationDetailsForEdit();
    }

    handlePreviousapexForEdit() {
        if (this.currentPageApexForEdit > 1) {
            this.currentPageApexForEdit--;
            this.updatePaginationDetailsForEdit();
        }
    }

    handleNextapexForEdit() {
        if (this.currentPageApexForEdit < this.totalPagesApexForEdit) {
            this.currentPageApexForEdit++;
            this.updatePaginationDetailsForEdit();
        }
    }

    handleLastapexForEdit() {
        this.currentPageApexForEdit = this.totalPagesApexForEdit;
        this.updatePaginationDetailsForEdit();
    }
   
    handleSortapexForEdit(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortedByapexForEdit = fieldName;
        this.sortDirectionapexForEdit = sortDirection;

        const clonedData = [...this.scriptsForEdit];
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

        this.scriptsForEdit = clonedData;
        this.updatePaginationDetailsForEdit();
    }
   
    /****************** END OF EDIT APEX SCRIPT CODE BLOCK ******************/
   

    /****************** START OF EDIT DATA RETRIEVAL CODE BLOCK ******************/
    // Common Properties
    @track selectedDataForEdit = '';
    @track showSpinnerInsideAccordionsDataForEdit = false;
    @track selectedAccordionSectionForEdit = '';

    // Data Selection Properties
    @track isSelectedUserEmptyForEdit = true;
  //  @track isSelectedCustomSettingsEmptyForEdit = true;
    //@track isSelectedScheduledJobsEmptyForEdit = true;
    @track isSelectedMetadataForEdit = false;
    @track showUsersDatatableForEdit = false;
    @track showCustomSettingsDatatableForEdit = false;
    @track showScheduledJobsDatatableForEdit = false;
    @track isUsersSelectedForEdit = false;
    @track isCustomSettingsSelectedForEdit = false;
    @track isScheduledJobsSelectedForEdit = false;
    @track hasFetchedUsersOnce = false;
    @track hasFetchedCustomSettingsOnce = false;
    @track hasFetchedScheduledJobsOnce = false;


    // Common Methods
    get dataOptionsForEdit() {
        return [
            { label: 'Users', value: 'Users' },
            { label: 'Custom Settings', value: 'Custom Settings' },
            { label: 'Scheduled Jobs', value: 'Scheduled Jobs' },
        ];
    }
       
    handleDataSelectionForEdit(event) {
        console.log('i am in handleDataSelection');
        const newSelectedData = event.target.value;
    
        // Reset visible sections
        this.isUsersSelectedForEdit = false;
        this.isCustomSettingsSelectedForEdit = false;
        this.isScheduledJobsSelectedForEdit = false;
        this.showUsersDatatableForEdit = false;
        this.showCustomSettingsDatatableForEdit = false;
        this.showScheduledJobsDatatableForEdit = false;
    
        this.selectedDataForEdit = newSelectedData;
    
        if (newSelectedData === 'Users') {
            this.isUsersSelectedForEdit = true;
            this.showUsersDatatableForEdit = true;
    
            // Hydrate Users from memory
            this.filteredDataForEdit = [...this.userDataforDatatableForEdit];
            this.updatePreselectedRowsForUsersForEdit();
            this.refreshSelectedTableDataForEdit();
    
        } else if (newSelectedData === 'Custom Settings') {
            this.isCustomSettingsSelectedForEdit = true;
            this.showCustomSettingsDatatableForEdit = true;

            // ✅ Hydrate if map is not already populated
            if (!this.selectedCustomSettingsMapForEdit || this.selectedCustomSettingsMapForEdit.size === 0) {
                this.fetchSelectedCustomSettingsForEdit();
            } else {
                this.customSettingsSelectedRowsForEdit = new Set([...this.selectedCustomSettingsMapForEdit.keys()]);
                this.selectedCustomSettingsForEdit = [...this.selectedCustomSettingsMapForEdit.values()];
                this.customSettingNamesListForEdit = [...this.customSettingsSelectedRowsForEdit];
                this.updateSelectedCustomSettingsDataForEdit();
                this.updatePreselectedRowsForCSForEdit();
            }
    
        } else if (newSelectedData === 'Scheduled Jobs') {
            this.isScheduledJobsSelectedForEdit = true;
            this.showScheduledJobsDatatableForEdit = true;

            if (!this.selectedJobsMapForEdit || this.selectedJobsMapForEdit.size === 0) {
                //this.fetchSelectedScheduledJobsForEdit();
                this.fetchAllDataComponentsForEdit('Scheduled Jobs');
            } else {
                this.selectedScheduledJobsForEdit = [...this.selectedJobsMapForEdit.values()];
                console.log('this.selectedScheduledJobsForEdit handleDataSelectionForEdit = '+this.selectedScheduledJobsForEdit.length);
                this.selectedJobsTableDataForEdit = [...this.selectedScheduledJobsForEdit];

                this.selectedRowsForEdit = new Set(
                    this.selectedScheduledJobsForEdit.map(job => job.jobName?.trim().toLowerCase())
                );
                console.log('this.selectedScheduledJobsForEdit selectedRowsForEdit = '+this.selectedRowsForEdit);
                this.updateSelectedJobsDataForEdit();
                this.updatePreselectedRowsForEdit();
            }
        }
    
        // Accordion opening
        setTimeout(() => {
            if (!this.selectedDataForEdit) return;
            const accordion = this.template.querySelector('lightning-accordion');
            if (accordion) {
                accordion.activeSectionName = newSelectedData === 'Users' ? 'Users' : 
                                                newSelectedData === 'Custom Settings' ? 'CustomSettings' : 
                                                newSelectedData === 'Scheduled Jobs' ? 'ScheduledJobs' : '';
            }
        }, 0);
    }
                      
               
    handleBackFromDataPickerForEdit() {
        this.searchTermRulesForEdit = '';
        this.searchTermSuffixForEdit = '';
        this.searchTermForEdit = '';
        this.selectedTableSearchTermUSERForEdit = '';
        
        // Custom Settings section
        this.searchTermavailCusForEdit = '';
        this.searchTermselCusForEdit = '';

        // Scheduled Jobs section
        this.searchTermSJForEdit = '';
        this.searchTermSelectedSJForEdit = '';


        // Reset page sizes to default for all sections
        // Users section
        this.selectedTablePageSizeForEdit = 10;
        this.pageSizeRulesForEdit = 5;
        this.pageSizeSuffixForEdit = 5;

        // Custom Settings section
        this.pageSizeCSForEdit = 5;
        this.selectedPageSizeCSForEdit = 5;

        // Scheduled Jobs section
        this.pageSizeSJForEdit = 5;
        this.selectedPageSizeSJForEdit = 5;
        this.currentPageRulesForEdit = 1;
        this.currentPageSuffixForEdit = 1;
        this.currentPageAvailCSForEdit = 1;
        this.selectedCurrentPageCSForEdit = 1;
        this.currentPageSJForEdit = 1;
        this.selectedCurrentPageSJForEdit = 1;
        this.selectedTablePageForEdit = 1;
        this.searchTermapexScriptForEdit = '';
        //this.pageSizeApex = 5;


        // Reset table data to reflect cleared search terms
        if (this.selectedDataForEdit === 'Users') {
            this.filteredDataForEdit = [...this.userDataforDatatableForEdit];
            this.refreshSelectedTableDataForEdit();
            
        } else if (this.selectedDataForEdit === 'Custom Settings') {
            this.updateSelectedCustomSettingsDataForEdit();
            this.updatePreselectedRowsForCSForEdit();
        } else if (this.selectedDataForEdit === 'Scheduled Jobs') {
            this.updateSelectedJobsDataForEdit();
            this.updatePreselectedRowsForEdit();   
        }
        this.isDataPickerForEdit = false;
        this.showFindAndReplacePageForEdit = true;

        console.log("Before filtering: ", JSON.stringify(this.findAndReplaceRulesForBackendForEdit));

        // Initially hide both sections
        this.showSearchAndReplaceForEdit = false;
        this.showSuffixForEdit = false;

        // Only show appropriate section if we have a previous masking type
        if (this.previousSelectedMaskingTypeForEdit) {
            this.selectedMaskingTypeForEdit = this.previousSelectedMaskingTypeForEdit;

            if (this.selectedMaskingTypeForEdit === 'Search & Replace') {
                this.showSearchAndReplaceForEdit = true;
                this.showSuffixForEdit = false;
                this.showapexScriptForEdit = false;
            } else if (this.selectedMaskingTypeForEdit === 'Suffix') {
                this.showSearchAndReplaceForEdit = false;
                this.showSuffixForEdit = true;
                this.showapexScriptForEdit = false;
            } else if (this.selectedMaskingTypeForEdit === 'Apex Script') {
                this.showapexScriptForEdit = true;
                this.showSearchAndReplaceForEdit = false;
                this.showSuffixForEdit = false;
            }

            // Reload rules for the selected masking type
            this.findAndReplaceRulesForEdit = this.findAndReplaceRulesForBackendForEdit.filter(
                rule => rule.maskingType === this.selectedMaskingTypeForEdit
            );
        } else {
            // If no previous masking type, clear the selection and hide both sections
            this.selectedMaskingTypeForEdit = '';
            this.findAndReplaceRulesForEdit = [];
        }

        console.log("Selected Masking Type:", this.selectedMaskingTypeForEdit);
        console.log("Filtered Rules:", JSON.stringify(this.findAndReplaceRulesForEdit));
    }
       
    handleNextFromDataPickerForEdit() {
        console.log('this.selectedScheduledJobsForEdit handleNextFromDataPickerForEdit'+this.selectedScheduledJobsForEdit);
        this.searchTermRulesForEdit = '';
        this.searchTermSuffixForEdit = '';
        this.searchTermForEdit = '';
        this.selectedTableSearchTermUSERForEdit = '';
        
        // Custom Settings section
        this.searchTermavailCusForEdit = '';
        this.searchTermselCusForEdit = '';

        // Scheduled Jobs section
        this.searchTermSJForEdit = '';
        this.searchTermSelectedSJForEdit = '';

        // Reset page sizes to default for all sections
        // Users section
        this.selectedTablePageSizeForEdit = 10;
        this.pageSizeRulesForEdit = 5;
        this.pageSizeSuffixForEdit = 5;

        // Custom Settings section
        this.pageSizeCSForEdit = 5;
        this.selectedPageSizeCSForEdit = 5;

        // Scheduled Jobs section
        this.pageSizeSJForEdit = 5;
        this.selectedPageSizeSJForEdit = 5;
        this.currentPageRulesForEdit = 1;
        this.currentPageSuffixForEdit = 1;
        this.currentPageAvailCSForEdit = 1;
        this.selectedCurrentPageCSForEdit = 1;
        this.currentPageSJForEdit = 1;
        this.selectedCurrentPageSJForEdit = 1;
        this.selectedTablePageForEdit = 1;
        this.searchTermapexScriptForEdit = '';

        // Reset table data to reflect cleared search terms
        if (this.selectedDataForEdit === 'Users') {
            console.log('I am in user handleNextFromDataPickerForEdit');
            console.log('this.selectedDataForEdit'+this.selectedDataForEdit);
            this.filteredDataForEdit = [...this.userDataforDatatableForEdit];
            this.refreshSelectedTableDataForEdit();
        } 
         if (this.selectedDataForEdit === 'Custom Settings') {
            console.log('I am in user handleNextFromDataPickerForEdit');
            this.updateSelectedCustomSettingsDataForEdit();
            this.updatePreselectedRowsForCSForEdit();
        } 
         if (this.selectedDataForEdit === 'Scheduled Jobs') {
            console.log('I am in schedule handleNextFromDataPickerForEdit');
            this.updateSelectedJobsDataForEdit();
            this.updatePreselectedRowsForEdit();
            console.log('I am in schedule handleNextFromDataPickerForEdit after');
        }
        console.log('this.selectedScheduledJobsForEdit handleNextFromDataPickerForEdit 2'+this.selectedScheduledJobsForEdit);

        // Reset search terms
        this.searchTermRulesForEdit = '';
        this.searchTermSuffixForEdit = '';

        // Reset page sizes to default
        this.pageSizeRulesForEdit = 5;
        this.pageSizeSuffixForEdit = 5;

        // Reset current pages to first page
        this.currentPageRulesForEdit = 1;
        this.currentPageSuffixForEdit = 1;
        this.previousSelectedMaskingTypeForEdit = this.selectedMaskingTypeForEdit;
        this.findAndReplaceRulesForEdit = this.findAndReplaceRulesForBackendForEdit.filter(
            rule => rule.maskingType === this.selectedMaskingTypeForEdit
        );
        
        this.updateSearchAndReplaceTableForEdit();
        this.updateSuffixTableForEdit();
        this.showSearchAndReplaceForEdit = true;
        this.showSuffixForEdit = true;
        this.showapexScriptForEdit = true;

        // Check specifically for search key without replace value
        if (this.selectedMaskingTypeForEdit === 'Search & Replace') {
            if (this.searchKeyForEdit && !this.replaceValueForEdit) {
                // Show popup if replace value is missing
                this.isShowModalForFindAndReplaceValidationForEdit = true;
                this.showSuffixForEdit = false;
                return;
            } else if (this.searchKeyForEdit && this.replaceValueForEdit) {
                // Clear form if both values are present
                this.resetFormForEdit();
            }
        }

        // Handle Suffix validation
        if (this.selectedMaskingTypeForEdit === 'Suffix' && this.suffixValueForEdit) {
            this.resetFormForEdit();
        }
        // Handle Apex Script validation
        if (this.selectedMaskingTypeForEdit === 'Apex Script' &&
            this.newScriptOrderForEdit &&
            this.newScriptNameForEdit &&
            this.newScriptDetailsForEdit) {
            this.resetFormForEdit();
        }

        // Navigate to next page
        this.isDataPickerForEdit = false;
        this.showCreateTemplatePageForEdit = true;
        console.log('this.selectedScheduledJobsForEdit handleNextFromDataPickerForEdit 3 '+this.selectedScheduledJobsForEdit);
    }
       
       
    fetchAllDataComponentsForEdit(type) {
        console.log('fetchAllDataComponents called with type:', type);
        this.showUsersDatatableForEdit = false;
        this.showCustomSettingsDatatableForEdit = false;
        this.showScheduledJobsDatatableForEdit = false;

        if (type.includes('Users')) {
            const previousNextRecordsUrl = this.nextRecordsUrlForEdit; 
            console.log('nextRecordsUrl --- ' + this.nextRecordsUrlForEdit);

            const queryEndpoint = this.nextRecordsUrlForEdit || ''; // Use an empty string for the first page
            console.log('this.parentOrg fetchAllDataComponentsForEdit ='+this.parentOrg);

            fetchAllUsers({ sandboxId: this.parentOrg, queryEndpoint, SearchString: '', sortBy: '' })
                //fetchAllUsers({ sandboxId: this.selectedOrg, queryEndpoint : this.nextRecordsUrl })
                .then(result => {

                    console.log('result --- ', JSON.stringify(result));
                    this.showSpinnerInsideAccordionsDataForEdit = false;
                    this.showUsersDatatableForEdit = true;
                    this.showCustomSettingsDatatableForEdit = false;
                    this.showScheduledJobsDatatableForEdit = false;

                    this.userDataforDatatableForEdit = [];
                    this.columnsForUserDataForEdit = columnsForUserDataForEdit;

                    // Populate the datatable data and calculate serial numbers
                    result.users.forEach((user, index) => {
                        this.userDataforDatatableForEdit.push({
                            Name: user.name,
                            Email: user.email,
                            Username: user.username,
                            Profile: user.profile,
                        });
                    });

                    // 👇 Restore from map
                    this.selectedRowsForEdit = new Set([...this.selectedUsersMapForEdit.keys()]);
                    this.selectedUsersTableDataForEdit = [...this.selectedUsersMapForEdit.values()];

                    this.preselectedUsernamesForEdit = Object.keys(this.selectedUserMapForEdit).filter(username =>
                        this.userDataforDatatableForEdit.some(user => user.Username === username)
                    );
                    this.filteredDataForEdit = [...this.userDataforDatatableForEdit];
                    this.nextRecordsUrlForEdit = result.nextRecordsUrl || null;
                    console.log('nextRecordsUrl after response --- ', this.nextRecordsUrlForEdit);
                    // Save oldNextRecordsUrl for Previous button if nextRecordsUrl becomes null
                    if (this.nextRecordsUrlForEdit != previousNextRecordsUrl) {
                        console.log('Setting oldNextRecordsUrl for previous navigation:', previousNextRecordsUrl);
                        this.oldNextRecordsUrlForEdit = previousNextRecordsUrl;
                    }
                    this.updatePaginationControlsForEdit();
                    this.totalRecordsUSERForEdit = result.totalRecords || 0;
                    console.log('Total Records Count:', this.totalRecordsUSERForEdit);


                    this.showPaginationForEdit = true;
                    this.updatePreselectedRowsForUsersForEdit();
                    console.log('I am in fetchAllDataComponentsForEdit');

                })
                .catch(error => {
                    console.error('Error queuing job:', error);
                    this.showSpinnerInsideAccordionsDataForEdit = false;
                });
        }

        if (type.includes('Custom Settings')) {
            console.log('min custom setting type.includes');
            fetchCustomSettings({ sandboxId: this.parentOrg })
                .then(result => {
                    this.customSettingsDataforDatatableForEdit = result.map(obj => ({
                        customSettingName: obj.name
                    }));
        
                    this.columnsForCustomSettingsForEdit = columnsForCustomSettingsForEdit;
                    this.showCustomSettingsDatatableForEdit = true;
        
                    // ✅ Rehydrate if map is already populated
                    if (this.selectedCustomSettingsMapForEdit.size > 0) {
                        this.customSettingsSelectedRowsForEdit = new Set([...this.selectedCustomSettingsMapForEdit.keys()]);
                        this.selectedCustomSettingsForEdit = [...this.selectedCustomSettingsMapForEdit.values()];
                        this.customSettingNamesListForEdit = [...this.customSettingsSelectedRowsForEdit];
                        this.updateSelectedCustomSettingsDataForEdit();
                        this.updatePreselectedRowsForCSForEdit();
                    } else {
                        this.fetchSelectedCustomSettingsForEdit();
                    }
                })
                .catch(error => {
                    console.error('Custom Settings fetch error:', error);
                });
        }

        if (type.includes('Scheduled Jobs')) {
            console.log('min schedule setting type.includes');
            fetchScheduledJobs({ sandboxId: this.parentOrg })
                .then(result => {
                    console.log('✅ Fetched scheduled jobs:', JSON.stringify(result));
        
                    this.scheduledJobsDataforDatatableForEdit = result.map(objWrap => ({
                        jobName: String(objWrap.jobName)?.replace(/"/g, '').trim(), // Clean
                        jobType: String(objWrap.jobType),
                        apexClassName: String(objWrap.apexClassName),
                        cronExpression: String(objWrap.cronExpression),
                    }));
        
                    this.columnsForScheduledJobsForEdit = columnsForScheduledJobsForEdit;
                    this.showSpinnerInsideAccordionsDataForEdit = false;
                    this.showUsersDatatableForEdit = false;
                    this.showCustomSettingsDatatableForEdit = false;
                    this.showScheduledJobsDatatableForEdit = true;
        
                    // ✅ Always fetch selected jobs AFTER scheduledJobsDataforDatatableForEdit is populated
                    this.fetchSelectedScheduledJobsForEdit();
                })
                .catch(error => {
                    console.error('❌ Error fetching scheduled jobs:', JSON.stringify(error));
                    this.showSpinnerInsideAccordionsDataForEdit = false;
                });
        }  
    }
       
    updatePreselectedRowsForMetadataForEdit() {
        this.preselectedRowsForEdit = Object.keys(this.selectedMetadataMapForEdit).filter(metadata =>
            this.selectedMetadataListToDisplayForEdit.some(row => row.name === metadata)
        );
        console.log('Preselected Metadata Rows:', this.preselectedRowsForEdit);
    }

    /*User section*/
    // API Properties
    @api isUsersSelectedForEdit = false;

    // Track variables for user data
    @track selectedUsersForEdit = [];
    @track selectedUsernamesForEdit = [];
    @track selectedUserMapForEdit = {};
    @track preselectedUsernamesForEdit = [];
    @track filteredDataForEdit = [];
    @track userDataforDatatableForEdit = [];

    // Track variables for pagination and search
    @track pageNumberUsersForEdit = 1;
    @track searchTermForEdit = '';
    @track selectedTablePageForEdit = 1;
    @track selectedTablePageSizeForEdit = 10;
    @track selectedTableSearchTermUSERForEdit = '';
    @track pageSizeOptionsselectedUserForEdit = [10, 25, 50, 100];
    @track totalSelectedRecordsForEdit = 0;

    // Track variables for filtering
    @track alphabetForEdit = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
    @track filterLetterForEdit = '';
    @track activeLetterForEdit = '';
    @track allDataForEdit = [];

    // Track variables for UI state
    @track showSpinnerForFilterForEdit = false;
    @track showSpinnerForSelectionForEdit = false;
    @track selectedTableRowsForEdit = [];
    @track nextRecordsUrlForEdit = '';
    @track oldNextRecordsUrlForEdit = '';
    @track selectedTableSelectedRowsForEdit = [];
    @track totalPagesUserForEdit = 0;
    @track currentPageUserForEdit = 1;
    @track sortedByForEdit = '';
    @track sortDirectionForEdit = 'asc';
    @track selectedTableSortedByForEdit = '';
    @track selectedTableSortDirectionForEdit = 'asc';
    pageSizeOptionsAvailUserForEdit = [2000];
    @track columnsForScheduledJobsForEdit = columnsForScheduledJobsForEdit;
    @track selectedJobsMapForEdit = new Map();
    @track selectedUsersMapForEdit = new Map();
    @track selectedCustomSettingsMapForEdit = new Map();
   
   
    fetchExistingSelectedUsersForEdit() {
        if (!this.templateRecordId) {
            console.error('❌ templateRecordId is undefined. Cannot fetch selected users.');
            return;
        }
        this.showSpinnerInsideAccordionsDataForEdit = true;
    
        console.log('this.disableNextFromDataPickerForEdit fetchExistingSelectedUsersForEdit ='+this.disableNextFromDataPickerForEdit);
        readJSONFromRelatedFiles({ recordId: this.templateRecordId })
            .then((result) => {
                if (result && Array.isArray(result)) {
                    this.selectedUserMapForEdit = {};
                    result.forEach(user => {
                        const userObj = {
                            id: user.Username || user.Id,
                            type: 'Users',
                            name: user.Name,
                            email: user.Email,
                            profile: user.Profile,
                            Username: user.Username
                        };
                        this.selectedUserMapForEdit[userObj.Username] = userObj;
                    });
                    console.log('this.selectedUserMapForEdit ='+this.selectedUserMapForEdit);
    
                    this.selectedUsersForEdit = Object.values(this.selectedUserMapForEdit);
                    console.log('this.selectedUsersForEdit='+this.selectedUsersForEdit );

                    this.selectedUsernamesForEdit = Object.keys(this.selectedUserMapForEdit);
                    console.log('this.selectedUsernamesForEdit='+this.selectedUsernamesForEdit );

                    this.selectedTableRowsForEdit = [...this.selectedUsernamesForEdit];
                    console.log('this.selectedTableRowsForEdit='+this.selectedTableRowsForEdit );

                    this.totalSelectedRecordsForEdit = this.selectedUsersForEdit.length;
                    console.log('this.totalSelectedRecordsForEdit='+this.totalSelectedRecordsForEdit );

                    // ✅ Only call this if org is defined
                    if (this.parentOrg) {
                        console.log('this.parentOrg ='+this.parentOrg);

                        this.fetchAllDataComponentsForEdit('Users').then(() => {
                            this.preselectedUsernamesForEdit = Object.keys(this.selectedUserMapForEdit).filter(username =>
                                this.userDataforDatatableForEdit.some(user => user.Username === username)
                            );
                            console.log('this.preselectedUsernamesForEdit ='+this.preselectedUsernamesForEdit);
                            this.showSpinnerInsideAccordionsDataForEdit = false;
                            this.refreshSelectedTableDataForEdit(); 
                          //  this.disableNextFromDataPickerForEdit = false;
                            console.log('this.disableNextFromDataPickerForEdit fetchExistingSelectedUsersForEdit 2 ='+this.disableNextFromDataPickerForEdit);
                        });
                    } else {
                        console.warn(' Skipping fetchAllDataComponentsForEdit because parentOrg is undefined.');
                    }
                }
            })
            .catch(error => {
                console.error('❌ Error fetching existing selected users:', error);
                
            });
    }
           
    handleAvailTablePageSizeChangeForEdit(event) {
        const selectedPageSize = event.target.value;
        console.log('Selected Page Size:', selectedPageSize);
        // Perform any logic needed when the page size changes, like pagination
    }

    get letterButtonsForEdit() {
        return this.alphabetForEdit.map(letter => ({
            letter,
            className: `alphabet-button ${this.activeLetterForEdit === letter ? 'active' : ''}`
        }));
    }
    get allButtonClassForEdit() {
        return `alphabet-button ${!this.activeLetterForEdit ? 'active' : ''}`;
    }
       
    // Getters for computed properties
    get hasSelectedUsersForEdit() {
        return this.selectedUsersForEdit && this.selectedUsersForEdit.length > 0;
    }
    get isSelectedUserEmptyForEdit() {
        return Object.keys(this.selectedUserMapForEdit).length === 0
    }
    get paginationTextForEdit() {
        return `Showing ${this.pageNumberUsersForEdit} of ${this.totalPagesAvailableForEdit} Page(s)`;
    }
    get totalPagesAvailableForEdit() {
        return Math.ceil(this.totalRecordsUSERForEdit / 2000);
    }
       
    get paginatedSelectedDataUserForEdit() {
        console.log('==== PAGINATED SELECTED DATA USER START ====');
        console.log('Selected user map size:', Object.keys(this.selectedUserMapForEdit).length);
        console.log('Current search term:', this.selectedTableSearchTermUSERForEdit);

        // Memoize the conversion of selectedUserMap to array
        if (!this._cachedSelectedDataForEdit || this._lastMapUpdateForEdit !== JSON.stringify(this.selectedUserMapForEdit)) {
            console.log('Rebuilding cached selected data');
            this._cachedSelectedDataForEdit = Object.values(this.selectedUserMapForEdit).map(user => ({
                Name: user.name,
                Email: user.email,
                Username: user.Username || user.id,
                Profile: user.profile
            }));
            this._lastMapUpdateForEdit = JSON.stringify(this.selectedUserMapForEdit);
        }

        let allSelectedData = this._cachedSelectedDataForEdit;
        console.log('Initial data count:', allSelectedData.length);

        // Apply search filter if there's a search term
        if (this.selectedTableSearchTermUSERForEdit) {
            const searchTerm = this.selectedTableSearchTermUSERForEdit.toLowerCase();
            allSelectedData = allSelectedData.filter(user =>
            (user.Name?.toLowerCase().includes(searchTerm) ||
                user.Email?.toLowerCase().includes(searchTerm) ||
                user.Username?.toLowerCase().includes(searchTerm) ||
                user.Profile?.toLowerCase().includes(searchTerm))
            );
            console.log('Filtered data count after search:', allSelectedData.length);
        }

        // Apply sorting if needed
        if (this.selectedTableSortedByForEdit) {
            console.log('Sorting by:', this.selectedTableSortedByForEdit, 'direction:', this.selectedTableSortDirectionForEdit);
            allSelectedData = [...allSelectedData].sort((a, b) => {
                let valueA = a[this.selectedTableSortedByForEdit] || '';
                let valueB = b[this.selectedTableSortedByForEdit] || '';

                valueA = typeof valueA === 'string' ? valueA.toLowerCase() : valueA;
                valueB = typeof valueB === 'string' ? valueB.toLowerCase() : valueB;

                const sortResult = valueA > valueB ? 1 : -1;
                return this.selectedTableSortDirectionForEdit === 'desc' ? -sortResult : sortResult;
            });
        }

        // Update total records count
       // this.totalSelectedRecordsForEdit = allSelectedData.length;
      //  console.log('Total selected records:', this.totalSelectedRecordsForEdit);

        // Calculate pagination
        const startIndex = (this.selectedTablePageForEdit - 1) * this.selectedTablePageSizeForEdit;
        const endIndex = Math.min(startIndex + this.selectedTablePageSizeForEdit, allSelectedData.length);
        console.log('Pagination start:', startIndex, 'end:', endIndex);

        const paginatedData = allSelectedData.slice(startIndex, endIndex);
        console.log('Returning paginated data count:', paginatedData.length);
        console.log('==== PAGINATED SELECTED DATA USER END ====');

        return paginatedData;
    }
   
    get totalPagesselUSRForEdit() {
        return Math.ceil(this.totalSelectedRecordsForEdit / this.selectedTablePageSizeForEdit);
    }

    get currentPagesselUSRForEdit() {
        return Math.min(this.selectedTablePageForEdit, this.totalPagesselUSRForEdit);
    }

    get isSelectedPreviousDisabledForEdit() {
        return this.selectedTablePageForEdit <= 1;
    }

    get isSelectedNextDisabledForEdit() {
        return this.selectedTablePageForEdit >= this.totalPagesselUSRForEdit;
    }

    get getLetterButtonClassForEdit() {
        return (letter) => `slds-button ${this.activeLetterForEdit === letter ? 'slds-button_brand' : 'slds-button_neutral'}`;
    }
       
    // Event Handlers for main table
    handleInputChangeForEdit(event) {
        this.searchTermForEdit = event.target.value.toLowerCase();
        if (!this.searchTermForEdit) {
            this.resetFilterForEdit();
        }
    }

    handleKeyPressForEdit(event) {
        if (event.key === 'Enter') {
            this.handleSearchClickForEdit();
        }
    }

    handleSearchClickForEdit() {
        this.allDataForEdit = [];
        this.showSpinnerForFilterForEdit = true;
        this.nextRecordsUrlForEdit = '';
        this.getFilteredDataForEdit(this.searchTermForEdit, '')
            .then(() => {
                if (this.activeLetterForEdit) {
                    this.filteredDataForEdit = this.filteredDataForEdit.filter(user =>
                        user.Name.startsWith(this.activeLetterForEdit)
                    );
                }
                this.updatePreselectedRowsForUsersForEdit();
            });
    }
       
    // Event Handlers for selected table
    handleSelectedTableSearchUSERForEdit(event) {
        const searchTerm = event.target.value.toLowerCase();

        // Preserve full selection state
        const currentSelections = { ...this.selectedUserMapForEdit };

        this.selectedTableSearchTermUSERForEdit = searchTerm;
        this.selectedTablePageForEdit = 1;

        // After search, restore all previous selections
        this.selectedUserMapForEdit = currentSelections;
        this.selectedUsersForEdit = Object.values(currentSelections);
        this.selectedUsernamesForEdit = Object.keys(currentSelections);

        // Update selected rows based on current page and existing selections
        this.selectedTableRowsForEdit = this.paginatedSelectedDataUserForEdit
            .filter(row => this.selectedUserMapForEdit[row.Username])
            .map(row => row.Username);

        this.refreshSelectedTableDataForEdit();
        //this.updateTotalSelectedUserCountForEdit();
    }
       
    handleSelectedTablePageSizeChangeForEdit(event) {
        const newPageSize = parseInt(event.target.value, 10);
        this.selectedTablePageSizeForEdit = newPageSize;

        // Retain all current selections
        const currentSelections = { ...this.selectedUserMapForEdit };

        // Reset page to 1 but keep all selections intact
        this.selectedTablePageForEdit = 1;

        // Update selections without losing existing data
        this.selectedUserMapForEdit = currentSelections;
        this.selectedUsersForEdit = Object.values(currentSelections);
        this.selectedUsernamesForEdit = Object.keys(currentSelections);

        // Ensure selected rows reflect current selections
        this.selectedTableRowsForEdit = this.paginatedSelectedDataUserForEdit
            .filter(row => this.selectedUserMapForEdit[row.Username])
            .map(row => row.Username);

        this.refreshSelectedTableDataForEdit();
        // this.updateTotalSelectedUserCountForEdit();
    }
       
    // Pagination handlers
    handleSelectedTablePreviousForEdit() {
        if (this.selectedTablePageForEdit > 1) {
            // Store current selections before page change
            const currentSelections = this.paginatedSelectedDataUserForEdit.map(row => row.Username);

            // Move to previous page
            this.selectedTablePageForEdit--;

            // After page change, mark all rows as selected
            this.selectedTableRowsForEdit = this.paginatedSelectedDataUserForEdit.map(row => row.Username);
        }
    }

    handleSelectedTableNextForEdit() {
        if (this.selectedTablePageForEdit < this.totalPagesselUSRForEdit) {
            // Store current selections before page change
            const currentSelections = this.paginatedSelectedDataUserForEdit.map(row => row.Username);

            // Move to next page
            this.selectedTablePageForEdit++;

            // After page change, mark all rows as selected
            this.selectedTableRowsForEdit = this.paginatedSelectedDataUserForEdit.map(row => row.Username);
        }
    }
       
    // Filter handlers
    filterByLetterForEdit(event) {
        this.allDataForEdit = [];
        this.showSpinnerForFilterForEdit = true;
        const letter = event.target.dataset.letter;
        this.filterLetterForEdit = letter;
        this.activeLetterForEdit = letter;

        if (this.filterLetterForEdit === 'All') {
            this.resetFilterForEdit();
            return;
        }

        this.nextRecordsUrlForEdit = '';
        this.getFilteredDataForEdit('', this.filterLetterForEdit)
            .then(() => {
                // Only update preselected rows if we have actual data
                if (!this.isPlaceholderDataForEdit) {
                    this.updatePreselectedRowsForUsersForEdit();
                }
            });

        if (this.pageNumberUsersForEdit <= 1) {
            this.pageNumberUsersForEdit = 1;
        }
    }
       
    resetFilterForEdit() {
        this.searchTermForEdit = '';
        this.filterLetterForEdit = '';
        this.allDataForEdit = [];
        this.pageNumberUsersForEdit = 1;
        this.nextRecordsUrlForEdit = '';
        this.oldNextRecordsUrlForEdit = '';
        this.activeLetterForEdit = '';
        this.fetchAllDataComponentsForEdit('Users');
        this.updatePaginationControlsForEdit();
    }
       
    handleRowSelectionForUserDataForEdit(event) {
        try {
            if (this.isPlaceholderDataForEdit) {
                return;
            }
            this.showSpinnerForSelectionForEdit = true;
    
            const selectedRows = event.detail.selectedRows || [];
    
            // Create a new map to merge existing + current page selections
            const newSelectedUserMap = new Map();
    
            // Step 1: Retain selections that are not part of the current page
            const visibleUsernames = new Set(this.filteredDataForEdit.map(user => user.Username));
            Object.entries(this.selectedUserMapForEdit).forEach(([username, userData]) => {
                if (!visibleUsernames.has(username)) {
                    newSelectedUserMap.set(username, userData);
                }
            });
    
            // Step 2: Add current page selections
            selectedRows.forEach(user => {
                const row = {
                    id: user.Username,
                    type: 'Users',
                    name: user.Name,
                    email: user.Email,
                    profile: user.Profile,
                    Username: user.Username
                };
                newSelectedUserMap.set(user.Username, row);
    
                // ✅ Update persistent selection map
                this.selectedUsersMapForEdit.set(user.Username, row);
                this.selectedRowsForEdit.add(user.Username);
            });
    
            // Step 3: Remove any deselected rows from persistent map
            this.filteredDataForEdit.forEach(user => {
                const isSelected = selectedRows.some(row => row.Username === user.Username);
                if (!isSelected) {
                    this.selectedUsersMapForEdit.delete(user.Username);
                    this.selectedRowsForEdit.delete(user.Username);
                }
            });
    
            // Step 4: Update standard component state (unchanged)
            this.selectedUserMapForEdit = Object.fromEntries(newSelectedUserMap);
            this.selectedUsersForEdit = Object.values(this.selectedUserMapForEdit);
            this.selectedUsernamesForEdit = Object.keys(this.selectedUserMapForEdit);
            this.preselectedUsernamesForEdit = [...this.selectedUsernamesForEdit];
            this.selectedTableRowsForEdit = [...this.selectedUsernamesForEdit];
            this.totalSelectedRecordsForEdit = this.selectedUsersForEdit.length;
            this.refreshSelectedTableDataForEdit();
            
            //this.updateTotalSelectedUserCountForEdit();
    
        } catch (error) {
            console.error('Error in row selection:', error);
        } finally {
            this.showSpinnerForSelectionForEdit = false;
        }
    }    
       
    handleDeselectUsersForEdit(event) {
        try {
            console.log('==== DESELECT USERS START ====');
            // Debounce to prevent multiple rapid deselections
            if (this._deselectionInProgressForEdit) {
                console.log('Deselection already in progress, skipping');
                return;
            }

            this._deselectionInProgressForEdit = true;
            this.showSpinnerForSelectionForEdit = true;

            // Get the current selected rows from the event
            const currentSelectedRows = event.detail.selectedRows || [];
            const allCurrentPageRecords = this.paginatedSelectedDataUserForEdit || [];

            // Create sets for easier comparison
            const currentSelectedUsernames = new Set(currentSelectedRows.map(row => row.Username));
            console.log('Selected map before deselection:', Object.keys(this.selectedUserMapForEdit).length);
            console.log('Current page records:', allCurrentPageRecords.length);
            console.log('Current selections on page:', currentSelectedRows.length);

            // CASE 1: Header checkbox was unchecked to deselect all rows
            if (currentSelectedRows.length === 0 && allCurrentPageRecords.length > 0) {
                console.log('Deselect all operation');

                const newSelectedUserMap = { ...this.selectedUserMapForEdit };
                console.log('Selected map size before removing:', Object.keys(newSelectedUserMap).length);

                // Remove all records from the current page
                allCurrentPageRecords.forEach(row => {
                    console.log('Removing user:', row.Username);
                    delete newSelectedUserMap[row.Username];
                });

                console.log('Selected map size after removing:', Object.keys(newSelectedUserMap).length);

                // Update all the tracking variables
                this.selectedUserMapForEdit = newSelectedUserMap;
                this.selectedUsersForEdit = Object.values(this.selectedUserMapForEdit);
                this.selectedUsernamesForEdit = Object.keys(this.selectedUserMapForEdit);
                this.preselectedUsernamesForEdit = this.selectedUsernamesForEdit;
                this.selectedTableRowsForEdit = []; // Clear selected rows for this page

                console.log('Final selection counts ForEdit:');
                console.log('  Selected map ForEdit:', Object.keys(this.selectedUserMapForEdit).length);
                console.log('  Selected users ForEdit:', this.selectedUsersForEdit.length);
                console.log('  Selected usernames ForEdit:', this.selectedUsernamesForEdit.length);
            }
            // CASE 2: Individual row deselection
            else {
                console.log('Individual deselection ForEdit');

                // Get current known state before the event
                const previousSelectedUsernamesSet = new Set(Object.keys(this.selectedUserMapForEdit));
                const previousSelectedCount = previousSelectedUsernamesSet.size;
                console.log('Previous selected count ForEdit:', previousSelectedCount);

                // Update selection state directly based on the event
                // This guarantees we match exactly what the UI shows
                const newSelectedUserMap = {};

                // First, preserve all selections not on current page
                Object.entries(this.selectedUserMapForEdit).forEach(([username, userData]) => {
                    // If username is not on current page, preserve it
                    if (!allCurrentPageRecords.some(record => record.Username === username)) {
                        newSelectedUserMap[username] = userData;
                    }
                });

                console.log('Selections not on current page ForEdit:', Object.keys(newSelectedUserMap).length);

                // Then add all current selections
                currentSelectedRows.forEach(row => {
                    if (this.selectedUserMapForEdit[row.Username]) {
                        newSelectedUserMap[row.Username] = this.selectedUserMapForEdit[row.Username];
                    }
                });

                console.log('Total selections after adding current page selections ForEdit:', Object.keys(newSelectedUserMap).length);

                // Update all the tracking variables
                this.selectedUserMapForEdit = newSelectedUserMap;
                this.selectedUsersForEdit = Object.values(this.selectedUserMapForEdit);
                this.selectedUsernamesForEdit = Object.keys(this.selectedUserMapForEdit);
                this.preselectedUsernamesForEdit = this.selectedUsernamesForEdit;

                // Update selected rows to match the current selection
                this.selectedTableRowsForEdit = Array.from(currentSelectedUsernames);
                console.log('Updated selectedTableRows length ForEdit:', this.selectedTableRowsForEdit.length);

                // Log the difference for debugging
                console.log('Records before ForEdit:', previousSelectedCount);
                console.log('Records after:', Object.keys(newSelectedUserMap).length);
                console.log('Difference:', previousSelectedCount - Object.keys(newSelectedUserMap).length);
            }

            // Check if current page is now invalid after deselection
            const totalPagesselUSR = Math.ceil(this.selectedUsernamesForEdit.length / this.selectedTablePageSizeForEdit);
            console.log('Total pages after update:', totalPagesselUSR);

            if (this.selectedTablePageForEdit > totalPagesselUSR && totalPagesselUSR > 0) {
                // If current page is now invalid, move to the last valid page
                console.log('Page adjustment needed, moving from', this.selectedTablePageForEdit, 'to', totalPagesselUSR);
                this.selectedTablePageForEdit = totalPagesselUSR;
            }

            // Refresh the data
            console.log('Refreshing selected table data');
            this.refreshSelectedTableDataForEdit();
            // this.updateTotalSelectedUserCountForEdit();
        } catch (error) {
            console.error('Error in deselection:', error);
        } finally {
            this.showSpinnerForSelectionForEdit = false;
            console.log('==== DESELECT USERS END ====');

            // Reset the debounce flag after a short delay
            setTimeout(() => {
                this._deselectionInProgressForEdit = false;
            }, 300);
        }
    }
       
    // Helper methods
    refreshSelectedTableDataForEdit() {
        console.log('==== REFRESH TABLE DATA START ====');
        console.log('Current selectedUserMap size:', Object.keys(this.selectedUserMapForEdit).length);
        console.log('Current page:', this.selectedTablePageForEdit);
        console.log('Current page size:', this.selectedTablePageSizeForEdit);

        // Debounce the refresh to prevent multiple rapid updates
        if (this._refreshTimeoutForEdit) {
            clearTimeout(this._refreshTimeoutForEdit);
            console.log('Cleared previous refresh timeout');
        }

        this._refreshTimeoutForEdit = setTimeout(() => {
            console.log('Executing refresh inside timeout');
            // Ensure current page is valid
            const maxPages = this.totalPagesselUSRForEdit;
            console.log('Max pages:', maxPages);

            if (this.selectedTablePageForEdit > maxPages) {
                console.log('Page adjustment needed, setting to:', Math.max(1, maxPages));
                this.selectedTablePageForEdit = Math.max(1, maxPages);
            }

            requestAnimationFrame(() => {
                console.log('Inside requestAnimationFrame');

                const currentPageData = this.paginatedSelectedDataUserForEdit;
                console.log('Current page data count:', currentPageData.length);
                console.log('Selected table rows before update:', [...this.selectedTableRowsForEdit]);

                this.selectedTableRowsForEdit = currentPageData.map(row => row.Username);

                console.log('Selected table rows after update:', [...this.selectedTableRowsForEdit]);
                console.log('Selected user map count after update:', Object.keys(this.selectedUserMapForEdit).length);

                this.totalSelectedRecordsForEdit = this.selectedUsersForEdit.length;
                console.log('Total selected records:', this.totalSelectedRecordsForEdit);
            });
        }, 100);

        console.log('==== REFRESH TABLE DATA END (timeout set) ====');
    }
       
    updatePaginationControlsForEdit() {
        this.isNextDisabledAvailUSERForEdit = !this.nextRecordsUrlForEdit;
        this.isPreviousDisabledAvailUSERForEdit = this.pageNumberUsersForEdit <= 1;
        this.totalPagesUserForEdit = this.totalPagesAvailableForEdit;
    }

    updatePreselectedRowsForUsersForEdit() {
        this.preselectedUsernamesForEdit = Object.keys(this.selectedUserMapForEdit).filter(username =>
            this.userDataforDatatableForEdit.some(user => user.Username === username)
        );
    }

    async getFilteredDataForEdit(searchValue, sortValue) {
        this.filteredDataForEdit = [];
        this.userDataforDatatableForEdit = [];
        this.showSpinnerForFilterForEdit = true;
        const previousNextRecordsUrl = this.nextRecordsUrlForEdit;

        try {
            const result = await fetchAllUsers({
                sandboxId: this.parentOrg,
                queryEndpoint: this.nextRecordsUrlForEdit,
                searchString: searchValue,
                sortBy: sortValue
            });

            if (result?.users?.length > 0) {
                result.users.forEach(user => {
                    this.userDataforDatatableForEdit.push({
                        Name: user.name,
                        Email: user.email,
                        Username: user.username,
                        Profile: user.profile,
                        _isPlaceholder: false
                    });
                });
            } else {
                // ❌ Do not create a fake record
                console.warn('⚡ No users found matching search.');
                this.filteredDataForEdit = []; // ✅ really empty
            }

            if (this.nextRecordsUrlForEdit !== previousNextRecordsUrl) {
                this.oldNextRecordsUrlForEdit = previousNextRecordsUrl;
            }

            this.nextRecordsUrlForEdit = result.nextRecordsUrl || '';
            this.filteredDataForEdit = [...this.userDataforDatatableForEdit];
            this.updatePaginationControlsForEdit();
            this.totalRecordsUSERForEdit = result.totalRecords || 0;
            this.updatePreselectedRowsForUsersForEdit();
        } catch (error) {
            console.error('Error in getFilteredData:', error);
            throw error;
        } finally {
            this.showSpinnerForFilterForEdit = false;
        }
    }
       
    get isPlaceholderDataForEdit() {
        return this.userDataforDatatableForEdit.length === 1 && this.userDataforDatatableForEdit[0]._isPlaceholder;
    }

    // Main table pagination handlers
    handlePreviousAvailUSRForEdit() {
        if (this.pageNumberUsersForEdit > 1) {
            this.pageNumberUsersForEdit--;
            if (this.pageNumberUsersForEdit === 1) {
                if (this.filterLetterForEdit || this.searchTermForEdit) {
                    this.pageNumberUsersForEdit = 1;
                    this.allDataForEdit = [];
                    this.oldNextRecordsUrlForEdit = null;
                    this.nextRecordsUrlForEdit = '';
                    this.getFilteredDataForEdit(this.searchTermForEdit, this.filterLetterForEdit)
                        .then(() => {
                            this.updatePreselectedRowsForUsersForEdit();
                        });
                    return;
                } else {
                    this.nextRecordsUrlForEdit = null;
                }
            } else {
                const currentUrl = this.oldNextRecordsUrlForEdit;
                if (currentUrl) {
                    const baseUrl = currentUrl.substring(0, currentUrl.lastIndexOf('-') + 1);
                    const currentOffset = parseInt(currentUrl.split('-').pop(), 10);
                    const newOffset = currentOffset - 2000;
                    this.nextRecordsUrl = newOffset > 0 ? `${baseUrl}${newOffset}` : null;
                }
            }

            this.oldNextRecordsUrlForEdit = this.nextRecordsUrlForEdit;
            this.fetchAllDataComponentsForEdit('Users');
            this.updatePaginationControlsForEdit();
        }
    }
       
    handleNextAvailUSRForEdit() {
        if (this.nextRecordsUrlForEdit) {
            this.allDataForEdit.push({
                nextRecordsUrl: this.nextRecordsUrlForEdit,
                currentPageData: [...this.filteredDataForEdit]
            });
            this.pageNoForEdit++;
            this.oldNextRecordsUrlForEdit = this.nextRecordsUrlForEdit;
            this.pageNumberUsersForEdit++;
            this.fetchAllDataComponentsForEdit('Users');
            this.updatePaginationControlsForEdit();
        }
    }

    handleSortForEdit(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedByForEdit = sortedBy;
        this.sortDirectionForEdit = sortDirection;

        // Clone the data for sorting
        let clonedData = [...this.filteredDataForEdit];

        // Sort the data
        clonedData.sort((a, b) => {
            let valueA = a[sortedBy] || '';
            let valueB = b[sortedBy] || '';

            valueA = typeof valueA === 'string' ? valueA.toLowerCase() : valueA;
            valueB = typeof valueB === 'string' ? valueB.toLowerCase() : valueB;

            let sortResult = valueA > valueB ? 1 : -1;

            return sortDirection === 'desc' ? -sortResult : sortResult;
        });

        this.filteredDataForEdit = clonedData;
    }

    handleSelectedTableSortForEdit(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.selectedTableSortedByForEdit = sortedBy;
        this.selectedTableSortDirectionForEdit = sortDirection;

        // Store current selections
        const currentSelections = new Set(this.selectedTableRowsForEdit);

        // Update sort parameters without modifying the data structure
        this.refreshSelectedTableDataForEdit();

        // After refresh, restore selections
        this.selectedTableRowsForEdit = [...currentSelections];

        // Ensure all rows on the current page are marked as selected
        const currentPageUsernames = this.paginatedSelectedDataUserForEdit.map(row => row.Username);
        this.selectedTableRowsForEdit = currentPageUsernames.filter(username =>
            this.selectedUserMapForEdit[username] !== undefined
        );
    }
       
    // Add these handlers for Selected Users table
    handleSelectedTableFirstForEdit() {
        if (!this.isSelectedFirstDisabledForEdit) {
            // Store current selections
            const currentSelections = this.paginatedSelectedDataUserForEdit.map(row => row.Username);

            // Move to first page
            this.selectedTablePageForEdit = 1;

            // After page change, mark all rows as selected
            this.selectedTableRowsForEdit = this.paginatedSelectedDataUserForEdit.map(row => row.Username);
        }
    }

    handleSelectedTableLastForEdit() {
        if (!this.isSelectedLastDisabledForEdit) {
            // Store current selections
            const currentSelections = this.paginatedSelectedDataUserForEdit.map(row => row.Username);

            // Move to last page
            this.selectedTablePageForEdit = this.totalPagesselUSRForEdit;

            // After page change, mark all rows as selected
            this.selectedTableRowsForEdit = this.paginatedSelectedDataUserForEdit.map(row => row.Username);
        }
    }

    // Add these getters for button disable conditions
    get isSelectedFirstDisabledForEdit() {
        return this.selectedTablePageForEdit <= 1;
    }

    get isSelectedLastDisabledForEdit() {
        return this.selectedTablePageForEdit >= this.totalPagesselUSRForEdit;
    }
       
    /*Custom settings */
    @track customSettingsDataforDatatableForEdit = [];
    @track currentPageAvailCSForEdit = 1;
    @track pageSizeCSForEdit = 5;
    @track searchTermavailCusForEdit = '';
    @track sortedByAvCSForEdit = 'customSettingName';
    @track sortedDirectionAvCSForEdit = 'asc';
    @track customSettingsSelectedRowsForEdit = new Set();
    @track selectedCustomSettingsForEdit = [];
    @track preselectedCSForEdit = [];
    @track selectedcustomSelectedRowsForEdit = [];
   // @track isSelectedCustomSettingsEmptyForEdit = true;
    @track showSpinnerInsideAccordionsDataForEdit = false;
    @track showCustomSettingsDatatableForEdit = false;

    @track selectedCurrentPageCSForEdit = 1;
    @track selectedPageSizeCSForEdit = 5;
    @track searchTermselCusForEdit = '';
    @track selectedSortedByForEdit = 'customSettingName';
    @track selectedSortedDirectionCSForEdit = 'asc';

    pageSizeOptionsavailCsForEdit = [5, 10, 25, 50];
    pageSizeOptionsselCsForEdit = [5, 10, 25, 50];
    
    @track selectedCustomSettingsMapForEdit = new Map(); 

    fetchSelectedCustomSettingsForEdit() {
        if (!this.templateRecordId) return;
    
        this.showSpinnerInsideAccordionsDataForEdit = true;
        //this.disableNextFromDataPickerForEdit = true;
        console.log('this.disableNextFromDataPickerForEdit fetchSelectedCustomSettingsForEdit ='+this.disableNextFromDataPickerForEdit);

        fetchCustomSettings({ sandboxId: this.parentOrg }).then((result) => {
            this.customSettingsDataforDatatableForEdit = result.map(objWrap => ({
                customSettingName: String(objWrap.name)
            }));
            this.columnsForCustomSettingsForEdit = columnsForCustomSettingsForEdit;

            fetchExistingCustomSettings({ recordId: this.templateRecordId })
            .then(result => {
                console.log('result fetchSelectedCustomSettingsForEdit ='+result);
                const rawList = result || [];

                const nameArray = rawList
                    .map(name => name.replace(/\s*\(\d+\)$/, '').trim()) 
                    .filter(Boolean);
          
    
                // 1. Store into Set
                this.customSettingsSelectedRowsForEdit = new Set(nameArray);
    
                // 2. Store into Map and Array
                this.selectedCustomSettingsMapForEdit = new Map();
                this.selectedCustomSettingsForEdit = [];
    
                nameArray.forEach(name => {
                    const obj = { customSettingName: name };
                    this.selectedCustomSettingsMapForEdit.set(name, obj);
                    this.selectedCustomSettingsForEdit.push(obj);
                });
    
                // 3. Hydrate preselected rows
                this.customSettingNamesListForEdit = [...this.customSettingsSelectedRowsForEdit];
                this.showSpinnerInsideAccordionsDataForEdit = false;
                this.updateSelectedCustomSettingsDataForEdit();
                this.updatePreselectedRowsForCSForEdit();
              //  this.disableNextFromDataPickerForEdit = false;
                console.log('this.disableNextFromDataPickerForEdit fetchSelectedCustomSettingsForEdit 2 ='+this.disableNextFromDataPickerForEdit);
            })
            .catch(error => {
                console.error('❌ Error fetching custom settings:', error);
              //  this.disableNextFromDataPickerForEdit = false;
              //  console.log('this.disableNextFromDataPickerForEdit fetchSelectedCustomSettingsForEdit Catch='+this.disableNextFromDataPickerForEdit);
            });
            /*.finally(() => {
                this.showSpinnerInsideAccordionsDataForEdit = false;
            });*/
        });
    }
       
    // Filter methods for both tables
    filterAvailableDataForEdit() {
        let filteredData = [...this.customSettingsDataforDatatableForEdit];

        // Apply search filter
        if (this.searchTermavailCusForEdit) {
            const searchTerm = this.searchTermavailCusForEdit.toLowerCase();
            filteredData = filteredData.filter(setting =>
                setting.customSettingName.toLowerCase().includes(searchTerm)
            );
        }

        // Apply sorting
        if (this.sortedByAvCSForEdit) {
            filteredData.sort((a, b) => {
                let val1 = a[this.sortedByAvCSForEdit] || '';
                let val2 = b[this.sortedByAvCSForEdit] || '';

                val1 = typeof val1 === 'string' ? val1.toLowerCase() : val1;
                val2 = typeof val2 === 'string' ? val2.toLowerCase() : val2;

                const sortMultiplier = this.sortedDirectionAvCSForEdit === 'asc' ? 1 : -1;
                return val1 > val2 ? sortMultiplier : -sortMultiplier;
            });
        }

        return filteredData;
    }

    filterSelectedDataForEdit() {
        let filteredData = [...this.selectedCustomSettingsForEdit];

        if (this.searchTermselCusForEdit) {
            const searchTerm = this.searchTermselCusForEdit.toLowerCase();
            filteredData = filteredData.filter(setting =>
                setting.customSettingName.toLowerCase().includes(searchTerm)
            );
        }

        if (this.selectedSortedByForEdit) {
            filteredData = [...filteredData].sort((a, b) => {
                let val1 = a[this.selectedSortedByForEdit] || '';
                let val2 = b[this.selectedSortedByForEdit] || '';

                val1 = typeof val1 === 'string' ? val1.toLowerCase() : val1;
                val2 = typeof val2 === 'string' ? val2.toLowerCase() : val2;

                if (val1 < val2) return this.selectedSortedDirectionCSForEdit === 'asc' ? -1 : 1;
                if (val1 > val2) return this.selectedSortedDirectionCSForEdit === 'asc' ? 1 : -1;
                return 0;
            });
        }
        return filteredData;
    }
       
    // Getters for paginated data
    get paginatedAvailableDataForEdit() {
        const filteredData = this.filterAvailableDataForEdit();
        const startIndex = (this.currentPageAvailCSForEdit - 1) * this.pageSizeCSForEdit;
        const endIndex = Math.min(startIndex + this.pageSizeCSForEdit, filteredData.length);
        return filteredData.slice(startIndex, endIndex);
    }

    get paginatedSelectedDataCsForEdit() {
        const filteredData = this.filterSelectedDataForEdit();
        console.log('🔍 Paginated Selected CS:', JSON.stringify(filteredData));
        const startIndex = (this.selectedCurrentPageCSForEdit - 1) * this.selectedPageSizeCSForEdit;
        const endIndex = startIndex + this.selectedPageSizeCSForEdit;
        return filteredData.slice(startIndex, endIndex);
    }

    get isSelectedCustomSettingsEmptyForEdit() {
        return !this.selectedCustomSettingsForEdit || this.selectedCustomSettingsForEdit.length === 0;
    }  
           
    handleRowSelectionForCustomSettingsForEdit(event) {
        try {
            const selectedRows = event.detail.selectedRows || [];
            const currentPageRows = this.paginatedAvailableDataForEdit;
    
            // Track selected names from current page
            const currentSelectedNames = new Set(selectedRows.map(row => row.customSettingName));
    
            // Update persistent map based on this page's selection
            currentPageRows.forEach(row => {
                const name = row.customSettingName;
                if (currentSelectedNames.has(name)) {
                    // ✅ Add to persistent map
                    this.selectedCustomSettingsMapForEdit.set(name, row);
                } else {
                    // ❌ Remove from persistent map
                    this.selectedCustomSettingsMapForEdit.delete(name);
                }
            });
    
            // Reflect persistent selections in working variables
            this.customSettingsSelectedRowsForEdit = new Set([...this.selectedCustomSettingsMapForEdit.keys()]);
            this.selectedCustomSettingsForEdit = [...this.selectedCustomSettingsMapForEdit.values()];
            this.customSettingNamesListForEdit = [...this.customSettingsSelectedRowsForEdit];
    
            // Update table pre-selection
            this.selectedcustomSelectedRowsForEdit = this.paginatedSelectedDataCsForEdit.map(row => row.customSettingName);
            this.updateSelectedCustomSettingsDataForEdit();
            this.updatePreselectedRowsForCSForEdit();
    
            console.log('✅ Updated Custom Settings Map:', [...this.selectedCustomSettingsMapForEdit.keys()]);
        } catch (error) {
            console.error('❌ Error in handleRowSelectionForCustomSettingsForEdit:', error);
        }
    }   
       
    handleDeselectionselCusForEdit(event) {
        console.log(' In handleDeselectionselCusForEdit');
        const selectedRows = event.detail.selectedRows || [];
        const currentSelectedPageRows = [...this.paginatedSelectedDataCsForEdit];
    
        // Create a Set of selected names for faster lookup
       // const stillSelectedNames = new Set(selectedRows.map(row => row.customSettingName));
       // Set of still-selected names from this page

        const stillSelectedNames = new Set(selectedRows.map(row => row.customSettingName));

        // Update the persistent Set and Map based on current page's deselections
        currentSelectedPageRows.forEach(row => {
            const name = row.customSettingName;
            const isStillSelected = stillSelectedNames.has(name);
    
            if (!isStillSelected) {
                // ❌ Remove from Set
                this.customSettingsSelectedRowsForEdit.delete(name);
                // ❌ Remove from persistent map
                this.selectedCustomSettingsMapForEdit.delete(name);
            }
        });
    
        // ✅ Sync display list
        this.customSettingsSelectedRowsForEdit = new Set([...this.selectedCustomSettingsMapForEdit.keys()]);
        this.selectedCustomSettingsForEdit = [...this.selectedCustomSettingsMapForEdit.values()];
        this.customSettingNamesListForEdit = [...this.customSettingsSelectedRowsForEdit];
    
        // ✅ Update checkboxes and UI
        this.updateSelectedCustomSettingsDataForEdit();

        //  Reset to valid page if current page becomes empty after deselection
        const totalPages = this.totalSelectedPagesCSForEdit;
        if (this.selectedCurrentPageCSForEdit > totalPages && totalPages > 0) {
            this.selectedCurrentPageCSForEdit = totalPages;
        }

        this.updatePreselectedRowsForCSForEdit();
        console.log('✅ Remaining Custom Settings:', [...this.customSettingsSelectedRowsForEdit]);
        console.log('⬅️ handleDeselectionselCusForEdit END');
    }
   
    updateSelectedCustomSettingsDataForEdit() {
        const newList = Array.from(this.customSettingsSelectedRowsForEdit);
        this.selectedCustomSettingsForEdit = newList.map(name => ({
            customSettingName: name
        }));
    
        // Make sure the map has all selected values
        newList.forEach(name => {
            if (!this.selectedCustomSettingsMapForEdit.has(name)) {
                this.selectedCustomSettingsMapForEdit.set(name, { customSettingName: name });
            }
        });
    
     //   this.isSelectedCustomSettingsEmptyForEdit = this.selectedCustomSettingsForEdit.length === 0;
    }

    updatePreselectedRowsForCSForEdit() {
        this.preselectedCSForEdit = this.paginatedAvailableDataForEdit
            .filter(row => this.customSettingsSelectedRowsForEdit.has(row.customSettingName))
            .map(row => row.customSettingName);
    
        this.selectedcustomSelectedRowsForEdit = this.paginatedSelectedDataCsForEdit
            .map(row => row.customSettingName);
    }

    // Pagination getters
    get totalPagesAvailCSForEdit() {
        const totalRecords = this.filterAvailableDataForEdit().length;
        return Math.ceil(totalRecords / this.pageSizeCSForEdit);
    }

    get totalSelectedPagesCSForEdit() {
        const filteredData = this.filterSelectedDataForEdit();
        return Math.ceil(filteredData.length / this.selectedPageSizeCSForEdit) || 1;
    }

    get isPreviousDisabledavilCSForEdit() {
        return this.currentPageAvailCSForEdit <= 1;
    }

    get isNextDisabledavilCSForEdit() {
        return this.currentPageAvailCSForEdit >= this.totalPagesAvailCSForEdit;
    }

    get isSelectedPreviousDisabledCSForEdit() {
        return this.selectedCurrentPageCSForEdit <= 1;
    }

    get isSelectedNextDisabledCSForEdit() {
        return this.selectedCurrentPageCSForEdit >= this.totalSelectedPagesCSForEdit;
    }

    get totalRecordscustomForEdit() {
        return this.customSettingsDataforDatatableForEdit?.length || 0;
    }
       
    // Event handlers for pagination
    handlePageSizeChangeAvlCusForEdit(event) {
        const newPageSize = parseInt(event.target.value, 10);
        // Store current selections
        const currentSelections = new Set(this.customSettingsSelectedRowsForEdit);

        // Update page size and reset to first page
        this.pageSizeCSForEdit = newPageSize;
        this.currentPageAvailCSForEdit = 1;

        // Restore selections
        this.customSettingsSelectedRowsForEdit = currentSelections;

        // Update tables
        this.updateSelectedCustomSettingsDataForEdit();
        this.updatePreselectedRowsForCSForEdit();
    }
       
    handleSelectedPageSizeChangeSelCSForEdit(event) {
        const newPageSize = parseInt(event.target.value, 10);
        this.selectedPageSizeCSForEdit = newPageSize;
        this.selectedCurrentPageCSForEdit = 1;
        this.updatePreselectedRowsForCSForEdit();
    }

    handlePreviousavailCSForEdit() {
        if (this.currentPageAvailCSForEdit > 1) {
            this.currentPageAvailCSForEdit--;
            this.updatePreselectedRowsForCSForEdit();
        }
    }

    handleNextavailCSForEdit() {
        if (this.currentPageAvailCSForEdit < this.totalPagesAvailCSForEdit) {
            this.currentPageAvailCSForEdit++;
            this.updatePreselectedRowsForCSForEdit();
        }
    }

    handleSelectedPreviousCSForEdit() {
        if (!this.isSelectedPreviousDisabledCSForEdit) {
            this.selectedCurrentPageCSForEdit -= 1;
            this.updatePreselectedRowsForCSForEdit();
        }
    }

    handleSelectedNextCSForEdit() {
        if (!this.isSelectedNextDisabledCSForEdit) {
            this.selectedCurrentPageCSForEdit += 1;
            this.updatePreselectedRowsForCSForEdit();
        }
    }

    // Search handlers
    handleSearchavailCusForEdit(event) {
        this.searchTermavailCusForEdit = event.target.value;
        // Reset to first page when searching
        this.currentPageAvailCSForEdit = 1;
        this.updatePreselectedRowsForCSForEdit();
    }
       
    handleSearchselCusForEdit(event) {
        this.searchTermselCusForEdit = event.target.value;
        this.selectedCurrentPageCSForEdit = 1;
        this.updatePreselectedRowsForCSForEdit();
    }

    // Sort handlers
    // Sort handlers for available custom settings table
    handleSortavailCusForEdit(event) {
        // Store current selections before sorting
        const currentSelections = new Set(this.customSettingsSelectedRowsForEdit);

        this.sortedByAvCS = event.detail.fieldName;
        this.sortedDirectionAvCSForEdit = event.detail.sortDirection;

        // After sorting, ensure preselected rows are updated
        this.customSettingsSelectedRowsForEdit = currentSelections;
        this.updatePreselectedRowsForCSForEdit();
    }
       
    // Sort handler for selected custom settings table
    handleSelectedSortCSForEdit(event) {
        // Store current page selections
        const currentPageSelections = new Set(this.selectedcustomSelectedRowsForEdit);

        this.selectedSortedByForEdit = event.detail.fieldName;
        this.selectedSortedDirectionCSForEdit = event.detail.sortDirection;

        // After sorting, restore selections for current page
        this.selectedcustomSelectedRowsForEdit = Array.from(currentPageSelections);
        this.updatePreselectedRowsForCSForEdit();
    }

    handleFirstsavailCSForEdit() {
        if (!this.isFirstDisabledavilCSForEdit) {
            this.currentPageAvailCSForEdit = 1;
            this.updatePreselectedRowsForCSForEdit();
        }
    }
       
    handleLastavailCSForEdit() {
        if (!this.isLasrDisabledavilCSForEdit) {
            this.currentPageAvailCSForEdit = this.totalPagesAvailCSForEdit;
            this.updatePreselectedRowsForCSForEdit();
        }
    }

    handleSelectedFirstCSForEdit() {
        if (!this.isSelectedFirstDisabledCSForEdit) {
            this.selectedCurrentPageCSForEdit = 1;
            this.updatePreselectedRowsForCSForEdit();
        }
    }

    handleSelectedLastCSForEdit() {
        if (!this.isSelectedLastDisabledCSForEdit) {
            this.selectedCurrentPageCSForEdit = this.totalSelectedPagesCSForEdit;
            this.updatePreselectedRowsForCSForEdit();
        }
    }
       
    // Add these getters for button disable conditions
    get isFirstDisabledavilCSForEdit() {
        return this.currentPageAvailCSForEdit <= 1;
    }

    get isLasrDisabledavilCSForEdit() {
        return this.currentPageAvailCSForEdit >= this.totalPagesAvailCSForEdit;
    }

    get isSelectedFirstDisabledCSForEdit() {
        return this.selectedCurrentPageCSForEdit <= 1;
    }

    get isSelectedLastDisabledCSForEdit() {
        return this.selectedCurrentPageCSForEdit >= this.totalSelectedPagesCSForEdit;
    }
       
    /*end custom settings*/

    /** schedulejobs*/
    @track currentPageSJForEdit = 1;
    @track pageSizeSJForEdit = 5;
    @track searchTermSJForEdit = '';
    @track sortBySJForEdit;
    @track sortDirectionSJForEdit = 'asc';
    @track selectedCurrentPageSJForEdit = 1;
    @track selectedPageSizeSJForEdit = 5;
    @track searchTermSelectedSJForEdit = '';
    @track selectedScheduledJobsForEdit = [];
    @track preselectedSJForEdit = [];
    @track selectedRowsForEdit = new Set(); // To maintain all selected rows across pages
    @track scheduleSelectedRowsForEdit = new Set(); // For selected table selections
    @track selectedJobsTableDataForEdit = [];
    @track selectedTablePreselectedRowsForEdit = [];
    @track showSpinnerInsideAccordionsDataForEdit = false;

    // Page size options
    pageSizeOptionsASJForEdit = [5, 10, 25, 50];
    pageSizeOptionsSSJForEdit = [5, 10, 25, 50];
    @track selectedSortedByForEdit;
    @track selectedSortedDirectionForEdit = 'asc';

    fetchSelectedScheduledJobsForEdit() {
        if (!this.templateRecordId) return;
    
        this.showSpinnerInsideAccordionsDataForEdit = true;
       // this.disableNextFromDataPickerForEdit = true;
        console.log('this.disableNextFromDataPickerForEdit fetchSelectedScheduledJobsForEdit ='+this.disableNextFromDataPickerForEdit);

        getScheduleJobCSVData({ recordId: this.templateRecordId })
        .then((result) => {
            console.log('Raw Scheduled Jobs from Apex:', JSON.stringify(result, null, 2));

            if (!Array.isArray(result)) {
                console.error(' Apex returned data is not an array.');
                this.showSpinnerInsideAccordionsDataForEdit = false;
                return;
            }

            if (!Array.isArray(this.scheduledJobsDataforDatatableForEdit) || this.scheduledJobsDataforDatatableForEdit.length === 0) {
                console.warn('scheduledJobsDataforDatatableForEdit is empty at matching time.');
                this.showSpinnerInsideAccordionsDataForEdit = false;
                return;
            }

            // Normalize selected names
            const selectedJobNames = result
            .map(job => job.name?.replace(/"/g, '').trim().toLowerCase())
            .filter(Boolean);

            console.log('🔍 selectedJobNames:', selectedJobNames);

            const matchedJobs = this.scheduledJobsDataforDatatableForEdit.filter(job =>
                selectedJobNames.includes(job.jobName?.trim().toLowerCase())
            );

            //this.selectedScheduledJobsForEdit = matchedJobs;
            this.selectedScheduledJobsForEdit = matchedJobs.map(job => ({
                id: job.jobName,
                type: 'Scheduled Jobs',
                formattedString: `Job Name: ${job.jobName}, Job Type: ${job.jobType}, Apex Class: ${job.apexClassName}, Cron Expression: ${job.cronExpression}`
            }));
            this.selectedJobsTableDataForEdit = matchedJobs.map(job => ({
                ...job,
                type: 'Scheduled Jobs',
                selected: true
            }));

            matchedJobs.forEach(job => {
                const jobKey = job.jobName?.trim().toLowerCase();
                this.selectedRowsForEdit.add(jobKey);
                this.selectedJobsMapForEdit.set(jobKey, job);

            });
            

          //  this.selectedJobsTableDataForEdit = [...this.selectedJobsTableDataForEdit];
            this.updateSelectedJobsDataForEdit();
          //  this.isSelectedScheduledJobsEmptyForEdit = this.selectedJobsTableDataForEdit.length === 0;
          //  console.log('this.isSelectedScheduledJobsEmptyForEdit = '+this.isSelectedScheduledJobsEmptyForEdit);
            this.updatePreselectedRowsForEdit();
            this.showSpinnerInsideAccordionsDataForEdit = false;
        })
        .catch(error => {
            console.error('Error fetching scheduled jobs:', error);
            this.showSpinnerInsideAccordionsDataForEdit = false;
        });
    }
           
       
    get paginatedScheduledJobsDataForEdit() {
        let filteredData = this.scheduledJobsDataforDatatableForEdit;

        if (this.searchTermSJForEdit) {
            const searchTerm = this.searchTermSJForEdit.toLowerCase();
            filteredData = filteredData.filter(job =>
                job.jobName?.toLowerCase().includes(searchTerm) ||
                job.jobType?.toLowerCase().includes(searchTerm) ||
                job.apexClassName?.toLowerCase().includes(searchTerm) ||
                job.cronExpression?.toLowerCase().includes(searchTerm)
            );
        }
       
        if (this.sortBySJForEdit) {
            filteredData = [...filteredData].sort((a, b) => {
                let val1 = a[this.sortBySJForEdit] || '';
                let val2 = b[this.sortBySJForEdit] || '';

                val1 = typeof val1 === 'string' ? val1.toLowerCase() : val1;
                val2 = typeof val2 === 'string' ? val2.toLowerCase() : val2;

                if (val1 < val2) return this.sortDirectionSJForEdit === 'asc' ? -1 : 1;
                if (val1 > val2) return this.sortDirectionSJForEdit === 'asc' ? 1 : -1;
                return 0;
            });
        }

        const startIndex = (this.currentPageSJForEdit - 1) * this.pageSizeSJForEdit;
        const endIndex = startIndex + this.pageSizeSJForEdit;

        return filteredData.slice(startIndex, endIndex);
    }
       
    handleRowSelectionForScheduledJobsForEdit(event) {
        console.log('I am in handleRowSelectionForScheduledJobsForEdit');
       
            const selectedRows = event.detail.selectedRows;
            const currentPageRows = this.paginatedScheduledJobsDataForEdit;

            // Track which rows were selected/deselected on current page
         /*   currentPageRows.forEach(row => {
                const isSelected = selectedRows.some(selected => selected.jobName === row.jobName);
                if (isSelected) {
                    this.selectedRowsForEdit.add(row.jobName);
                    this.selectedJobsMapForEdit.set(row.jobName, row);
                    
                } else {
                    this.selectedRowsForEdit.delete(row.jobName);
                    this.selectedJobsMapForEdit.delete(row.jobName); 
                }
            });*/

            currentPageRows.forEach(row => {
                const key = row.jobName?.trim().toLowerCase();
                const isSelected = selectedRows.some(sel => sel.jobName?.trim().toLowerCase() === key);
                if (isSelected) {
                    this.selectedRowsForEdit.add(key);
                    this.selectedJobsMapForEdit.set(key, row);
                } else {
                    this.selectedRowsForEdit.delete(key);
                    this.selectedJobsMapForEdit.delete(key);
                }
            });

            // Transform for template format
            // Transform selected rows directly for template format
            this.selectedScheduledJobsForEdit = selectedRows.map(job => ({
                id: job.jobName,
                type: 'Scheduled Jobs',
                formattedString: `Job Name: ${job.jobName}, Job Type: ${job.jobType}, Apex Class: ${job.apexClassName}, Cron Expression: ${job.cronExpression}`
            }));


            // Update both tables
            this.updateSelectedJobsDataForEdit();
            this.updatePreselectedRowsForEdit();
      
    }
   
    rehydrateScheduledJobsSelectionForEdit() {
        this.selectedScheduledJobsForEdit = [...this.selectedJobsMapForEdit.values()];
        this.selectedJobsTableDataForEdit = [...this.selectedScheduledJobsForEdit];
        this.selectedRowsForEdit = new Set([...this.selectedJobsMapForEdit.keys()]);
        this.updatePreselectedRowsForEdit();
    }
       
    // Helper method to get selected rows for current page
    getSelectedRowsForPageForEdit(data) {
        return data
            .filter(row => this.selectedRowsForEdit.has(row.jobName))
            .map(row => row.jobName);
    }

    handleDeselectionForEdit(event) {
        console.log('I am in handleDeselectionForEdit');
        const selectedRowsFromDeselectionTable = event.detail.selectedRows;
        const currentSelectedPageRows = this.paginatedSelectedJobsDataForEdit;

        // Update selectedRows Set based on deselections
     /*   currentSelectedPageRows.forEach(row => {
            const isStillSelected = selectedRowsFromDeselectionTable.some(
                selected => selected.jobName === row.jobName
            );
            if (!isStillSelected) {
                this.selectedRowsForEdit.delete(row.jobName);
                this.selectedJobsMapForEdit.delete(row.jobName);
            }
        });*/
        currentSelectedPageRows.forEach(row => {
            const key = row.jobName?.trim().toLowerCase();
            const isStillSelected = selectedRowsFromDeselectionTable.some(
                sel => sel.jobName?.trim().toLowerCase() === key
            );
            if (!isStillSelected) {
                this.selectedRowsForEdit.delete(key);
                this.selectedJobsMapForEdit.delete(key);
            }
        });

        this.selectedScheduledJobsForEdit = [...this.selectedJobsMapForEdit.values()].map(job => ({
            id: job.jobName,
            type: 'Scheduled Jobs',
            formattedString: `Job Name: ${job.jobName}, Job Type: ${job.jobType}, Apex Class: ${job.apexClassName}, Cron Expression: ${job.cronExpression}`
        }));

       
        console.log('this.selectedScheduledJobsForEdit ='+this.selectedScheduledJobsForEdit);
        console.log('this.selectedScheduledJobsForEdit ='+this.selectedScheduledJobsForEdit.length );
    
        this.updateSelectedJobsDataForEdit();
        // Check if current page is now invalid after deselection
        const totalSelectedPagesSJ = Math.ceil(this.selectedJobsTableDataForEdit.length / this.selectedPageSizeSJForEdit);
        if (this.selectedCurrentPageSJForEdit > totalSelectedPagesSJ && totalSelectedPagesSJ > 0) {
           this.selectedCurrentPageSJForEdit = totalSelectedPagesSJ;
        }

        this.updatePreselectedRowsForEdit();
    }
   
  /*  updatePreselectedRowsForEdit() {
        console.log('i am in updatePreselectedRowsForEdit');
        console.log('this.selectedRowsForEdit ='+this.selectedRowsForEdit);
    
        if (this.selectedRowsForEdit.size === 0) {
            console.log('this.selectedRowsForEdit if='+this.selectedRowsForEdit);
            // Clear all preselected values if nothing is selected
            this.preselectedSJForEdit = [];
            this.selectedTablePreselectedRowsForEdit = [];
            console.log('No selected jobs, cleared all preselected rows.');
        } else {
            console.log('this.selectedRowsForEdit else='+this.selectedRowsForEdit);
            console.log('this.paginatedScheduledJobsDataForEdit='+this.paginatedScheduledJobsDataForEdit);
            console.log('this.paginatedSelectedJobsDataForEdit='+this.paginatedSelectedJobsDataForEdit);
            // Populate preselected values for current page
            this.preselectedSJForEdit = this.paginatedScheduledJobsDataForEdit
                .filter(row => this.selectedRowsForEdit.has(row.jobName))
                .map(row => row.jobName);
    
            this.selectedTablePreselectedRowsForEdit = this.paginatedSelectedJobsDataForEdit
                .filter(row => this.selectedRowsForEdit.has(row.jobName))
                .map(row => row.jobName);
        }
    
        console.log('this.preselectedSJForEdit ==', this.preselectedSJForEdit);
        console.log('this.selectedTablePreselectedRowsForEdit ==', this.selectedTablePreselectedRowsForEdit);
        console.log('i am done in updatePreselectedRowsForEdit');
    }*/

        updatePreselectedRowsForEdit() {
            const normalizedSelectedKeys = new Set(
                [...this.selectedRowsForEdit].map(key => key?.toLowerCase())
            );
        
            this.preselectedSJForEdit = this.paginatedScheduledJobsDataForEdit
                .filter(row => normalizedSelectedKeys.has(row.jobName?.trim().toLowerCase()))
                .map(row => row.jobName);
        
            this.selectedTablePreselectedRowsForEdit = this.paginatedSelectedJobsDataForEdit
                .filter(row => normalizedSelectedKeys.has(row.jobName?.trim().toLowerCase()))
                .map(row => row.jobName);
        
            console.log('✅ preselectedSJForEdit:', JSON.stringify(this.preselectedSJForEdit));
            console.log('✅ selectedTablePreselectedRowsForEdit:', JSON.stringify(this.selectedTablePreselectedRowsForEdit));
        }
        
        

      /*  updatePreselectedRowsForEdit() {
            console.log('🔄 updatePreselectedRowsForEdit START');
        
            const availablePageRows = this.paginatedScheduledJobsDataForEdit;
            const selectedPageRows = this.paginatedSelectedJobsDataForEdit;
        
            // For Available table
            this.preselectedSJForEdit = availablePageRows
                .filter(row => normalizedSelectedKeys.has(row.jobName?.toLowerCase()))
                .map(row => row.jobName);
        
            // For Selected table
            this.selectedTablePreselectedRowsForEdit = selectedPageRows
                .filter(row => normalizedSelectedKeys.has(row.jobName?.toLowerCase()))
                .map(row => row.jobName);
        
            console.log('✅ preselectedSJForEdit:', JSON.stringify(this.preselectedSJForEdit));
            console.log('✅ selectedTablePreselectedRowsForEdit:', JSON.stringify(this.selectedTablePreselectedRowsForEdit));
            console.log('🔄 updatePreselectedRowsForEdit END');
        }*/
        

         updateSelectedJobsDataForEdit() {
                const normalizedKeys = new Set(
                    [...this.selectedRowsForEdit].map(key => key?.toLowerCase())
                );
            
                this.selectedJobsTableDataForEdit = this.scheduledJobsDataforDatatableForEdit
                    .filter(job => normalizedKeys.has(job.jobName?.trim().toLowerCase()))
                    .map(job => ({
                        ...job,
                        type: 'Scheduled Jobs',
                        selected: true
                    }));
            
                if (this.selectedJobsTableDataForEdit.length === 0) {
                    this.selectedScheduledJobsForEdit = [];
                } else {
                    this.selectedScheduledJobsForEdit = this.selectedJobsTableDataForEdit.map(job => ({
                        id: job.jobName,
                        type: 'Scheduled Jobs',
                        formattedString: `Job Name: ${job.jobName}, Job Type: ${job.jobType}, Apex Class: ${job.apexClassName}, Cron Expression: ${job.cronExpression}`
                    }));
                }
            }
            

       
    get paginatedSelectedJobsDataForEdit() {
        let filteredData = this.selectedJobsTableDataForEdit;
    
        if (this.searchTermSelectedSJForEdit) {
            const searchTerm = this.searchTermSelectedSJForEdit.toLowerCase();
            filteredData = filteredData.filter(job =>
                job.jobName?.toLowerCase().includes(searchTerm) ||
                job.jobType?.toLowerCase().includes(searchTerm) ||
                job.apexClassName?.toLowerCase().includes(searchTerm) ||
                job.cronExpression?.toLowerCase().includes(searchTerm)
            );
        }
    
        if (this.selectedSortedByForEdit) {
            filteredData = [...filteredData].sort((a, b) => {
                let val1 = a[this.selectedSortedByForEdit] || '';
                let val2 = b[this.selectedSortedByForEdit] || '';
                val1 = typeof val1 === 'string' ? val1.toLowerCase() : val1;
                val2 = typeof val2 === 'string' ? val2.toLowerCase() : val2;
                if (val1 < val2) return this.selectedSortedDirectionForEdit === 'asc' ? -1 : 1;
                if (val1 > val2) return this.selectedSortedDirectionForEdit === 'asc' ? 1 : -1;
                return 0;
            });
        }
    
        const startIndex = (this.selectedCurrentPageSJForEdit - 1) * this.selectedPageSizeSJForEdit;
        const endIndex = startIndex + this.selectedPageSizeSJForEdit;
        return filteredData.slice(startIndex, endIndex);
    }

    // Computed properties for pagination controls
    get totalPagesSJForEdit() {
        const filteredData = this.scheduledJobsDataforDatatableForEdit.filter(job => {
            if (!this.searchTermSJForEdit) return true;
            const searchTerm = this.searchTermSJForEdit.toLowerCase();
            return job.jobName?.toLowerCase().includes(searchTerm) ||
                job.jobType?.toLowerCase().includes(searchTerm) ||
                job.apexClassName?.toLowerCase().includes(searchTerm) ||
                job.cronExpression?.toLowerCase().includes(searchTerm);
        });
        return Math.ceil(filteredData.length / this.pageSizeSJForEdit);
    }

   /* updatePreselectedRowsForSJForEdit() {
        this.preselectedSJForEdit = this.selectedScheduledJobsForEdit.map(job => job.jobName);
        console.log('Preselected Scheduled Jobs ForEdit:', JSON.stringify(this.preselectedSJForEdit));
    }*/
       
    get totalSelectedPagesSJForEdit() {
        const filteredData = this.selectedJobsTableDataForEdit.filter(job => {
            if (!this.searchTermSelectedSJForEdit) return true;
            const searchTerm = this.searchTermSelectedSJForEdit.toLowerCase();
            return job.jobName?.toLowerCase().includes(searchTerm) ||
                job.jobType?.toLowerCase().includes(searchTerm) ||
                job.apexClassName?.toLowerCase().includes(searchTerm) ||
                job.cronExpression?.toLowerCase().includes(searchTerm);
        });
        return Math.ceil(filteredData.length / this.selectedPageSizeSJForEdit);
    }

    get isPreviousDisabledSJForEdit() {
        return this.currentPageSJForEdit <= 1;
    }

    get isNextDisabledSJForEdit() {
        return this.currentPageSJForEdit >= this.totalPagesSJForEdit;
    }

    get isSelectedPreviousDisabledSJForEdit() {
        return this.selectedCurrentPageSJForEdit <= 1;
    }
       
    get isSelectedNextDisabledSJForEdit() {
        return this.selectedCurrentPageSJForEdit >= this.totalSelectedPagesSJForEdit;
    }
    get isSelectedScheduledJobsEmptyForEdit() {
        return !this.selectedJobsTableDataForEdit || this.selectedJobsTableDataForEdit.length === 0;
    }
       
    // Event handlers
    handleSearchSJForEdit(event) {
        // Store current selections before searching
        const currentSelections = new Set(this.selectedRowsForEdit);

        // Update search term and reset to first page
        this.searchTermSJForEdit = event.target.value;
        this.currentPageSJForEdit = 1;

        // Restore selections
        this.selectedRowsForEdit = currentSelections;

        // Update preselected rows for the current page
        this.updatePreselectedRowsForEdit();
    }
       
    handleSearchSelectedSJForEdit(event) {
        this.searchTermSelectedSJForEdit = event.target.value;
        this.selectedCurrentPageSJForEdit = 1;
        this.updateSelectedJobsDataForEdit();
        this.updatePreselectedRowsForEdit();
    }

    handleSortSJForEdit(event) {
        // Store current selections before sorting
        const currentSelections = new Set(this.selectedRowsForEdit);

        // Update sort parameters
        this.sortBySJ = event.detail.fieldName;
        this.sortDirectionSJForEdit = event.detail.sortDirection;

        // Restore selections
        this.selectedRowsForEdit = currentSelections;

        // Update preselected rows for the current page
        this.updatePreselectedRowsForEdit();
    }
       
    handleSelectedSortForEdit(event) {
        this.selectedSortedByForEdit = event.detail.fieldName;
        this.selectedSortedDirectionForEdit = event.detail.sortDirection;
        this.updateSelectedJobsDataForEdit();
        this.updatePreselectedRowsForEdit();
    }

    handlePageSizeSJForEdit(event) {
        const newPageSize = parseInt(event.target.value, 10);

        // Store current selections before changing page size
        const currentSelections = new Set(this.selectedRowsForEdit);

        // Update page size and reset to first page
        this.pageSizeSJForEdit = newPageSize;
        this.currentPageSJForEdit = 1;

        // Restore selections
        this.selectedRowsForEdit = currentSelections;

        // Update both tables
        this.updateSelectedJobsDataForEdit();
        this.updatePreselectedRowsForEdit();

        // Force checkbox refresh for current page
        this.preselectedSJForEdit = this.getSelectedRowsForPageForEdit(this.paginatedScheduledJobsDataForEdit);
    }
       
    handleSelectedPageSizeSJForEdit(event) {
        const newPageSize = parseInt(event.target.value, 10);

        // Store current selections before changing page size
        const currentSelections = new Set(this.selectedRowsForEdit);

        // Update page size and reset to first page
        this.selectedPageSizeSJForEdit = newPageSize;
        this.selectedCurrentPageSJForEdit = 1;

        // Restore selections
        this.selectedRowsForEdit = currentSelections;

        // Update both tables
        this.updateSelectedJobsDataForEdit();
        this.updatePreselectedRowsForEdit();
        this.selectedTablePreselectedRowsForEdit = this.paginatedSelectedJobsDataForEdit.map(row => row.jobName);
    }
       
    handlePreviousSJForEdit() {
        if (!this.isPreviousDisabledSJForEdit) {
            this.currentPageSJForEdit -= 1;
            this.updatePreselectedRowsForEdit();
        }
    }

    handleNextSJForEdit() {
        if (!this.isNextDisabledSJForEdit) {
            this.currentPageSJForEdit += 1;
            this.updatePreselectedRowsForEdit();
        }
    }

    handleSelectedPreviousSJForEdit() {
        if (!this.isSelectedPreviousDisabledSJForEdit) {
            this.selectedCurrentPageSJForEdit -= 1;
            this.updatePreselectedRowsForEdit();
        }
    }
       
    handleSelectedNextSJForEdit() {
        if (!this.isSelectedNextDisabledSJForEdit) {
            this.selectedCurrentPageSJForEdit += 1;
            this.updatePreselectedRowsForEdit();
        }
    }

    handleFirstSJForEdit() {
        if (!this.isFirstDisabledSJForEdit) {
            this.currentPageSJForEdit = 1;
            this.updatePreselectedRowsForEdit();
        }
    }

    handleLastSJForEdit() {
        if (!this.isLastDisabledSJForEdit) {
            this.currentPageSJForEdit = this.totalPagesSJForEdit;
            this.updatePreselectedRowsForEdit();
        }
    }

    // Add these handlers for Selected Scheduled Jobs
    handleSelectedFirstSJForEdit() {
        if (!this.isSelectedFirstDisabledSJForEdit) {
            this.selectedCurrentPageSJForEdit = 1;
            this.updatePreselectedRowsForEdit();
        }
    }
       
    handleSelectedLastSJForEdit() {
        if (!this.isSelectedLastDisabledSJForEdit) {
            this.selectedCurrentPageSJForEdit = this.totalSelectedPagesSJForEdit;
            this.updatePreselectedRowsForEdit();
        }
    }

    // Add these getters for button disable conditions
    get isFirstDisabledSJForEdit() {
        return this.currentPageSJForEdit <= 1;
    }

    get isLastDisabledSJForEdit() {
        return this.currentPageSJForEdit >= this.totalPagesSJForEdit;
    }

    get isSelectedFirstDisabledSJForEdit() {
        return this.selectedCurrentPageSJForEdit <= 1;
    }

    get isSelectedLastDisabledSJForEdit() {
        return this.selectedCurrentPageSJForEdit >= this.totalSelectedPagesSJForEdit;
    }
    /*end**/
       
       
    get isFilteredDataEmptyForEdit() {
        // Check if the original data is empty (no users from the org)
        return (!this.userDataforDatatableForEdit || this.userDataforDatatableForEdit.length === 0) &&
            (!this.searchTermForEdit && !this.filterLetterForEdit);
    }

    get isAvailableCustomSettingsEmptyForEdit() {
        return !this.customSettingsDataforDatatableForEdit || this.customSettingsDataforDatatableForEdit.length === 0;
    }

    get isAvailableScheduledJobsEmptyForEdit() {
        return !this.scheduledJobsDataforDatatableForEdit || this.scheduledJobsDataforDatatableForEdit.length === 0;
    }

    /****************** END OF DATA PICKER CODE BLOCK FOR CREATE NEW TEMPLATE ******************/
   
   
    /****************** START UPDATE TEMPLATE CODE BLOCK FOR UPDATE EXISTING TEMPLATE ******************/

    @track showCreateTemplatePageForEdit = false;
    @track selectedMetadataColumnsForEdit = selectedMetadataColumnsForEdit;
        

    @track templateNameForEdit = '';
    

    handleBackFromTemplateCreationPageForEdit() {
        this.searchTermRulesForEdit = '';
        this.searchTermSuffixForEdit = '';
        this.searchTermForEdit = '';
        this.selectedTableSearchTermUSERForEdit = '';
        

        // Custom Settings section
        this.searchTermavailCusForEdit = '';
        this.searchTermselCusForEdit = '';

        // Scheduled Jobs section
        this.searchTermSJForEdit = '';
        this.searchTermSelectedSJForEdit = '';


        // Reset page sizes to default for all sections
        // Users section
        this.selectedTablePageSizeForEdit = 10;
        this.pageSizeRulesForEdit = 5;
        this.pageSizeSuffixForEdit = 5;

        // Custom Settings section
        this.pageSizeCSForEdit = 5;
        this.selectedPageSizeCSForEdit = 5;

        // Scheduled Jobs section
        this.pageSizeSJForEdit = 5;
        this.selectedPageSizeSJForEdit = 5;
        this.currentPageRulesForEdit = 1;
        this.currentPageSuffixForEdit = 1;
        this.currentPageAvailCSForEdit = 1;
        this.selectedCurrentPageCSForEdit = 1;
        this.currentPageSJForEdit = 1;
        this.selectedCurrentPageSJForEdit = 1;
        this.selectedTablePageForEdit = 1;
        this.searchTermapexScriptForEdit = '';
        //this.pageSizeApex = 5;


        // Reset table data to reflect cleared search terms
        if (this.selectedDataForEdit === 'Users') {
            this.filteredDataForEdit = [...this.userDataforDatatableForEdit];
            this.refreshSelectedTableDataForEdit();
        } else if (this.selectedDataForEdit === 'Custom Settings') {
            this.updateSelectedCustomSettingsDataForEdit();
            this.updatePreselectedRowsForCSForEdit();
        } else if (this.selectedDataForEdit === 'Scheduled Jobs') {
            this.updateSelectedJobsDataForEdit();
            this.updatePreselectedRowsForEdit();
        }

        // Restore selected metadata list to display
        this.selectedMetadataListToDisplayForEdit = Object.values(this.selectedMetadataMapForEdit);

        // 👉 Force display on the last page
        this.selectedTotalPagesForEdit = Math.ceil(this.selectedMetadataListToDisplayForEdit.length / this.selectedPageSizeForEdit) || 1;
        this.selectedCurrentPageForEdit = this.selectedTotalPagesForEdit;
        this.updatePaginatedSelectedMetadataForEdit();

        this.showCreateTemplatePageForEdit = false;
        this.isDataPickerForEdit = true;

        console.log("Before filtering: ", JSON.stringify(this.findAndReplaceRulesForBackendForEdit));

        // Initially hide both sections
        this.showSearchAndReplaceForEdit = false;
        this.showSuffixForEdit = false;

        // Only show appropriate section if we have a previous masking type
        if (this.previousSelectedMaskingTypeForEdit) {
            this.selectedMaskingTypeForEdit = this.previousSelectedMaskingTypeForEdit;

            if (this.selectedMaskingTypeForEdit === 'Search & Replace') {
                this.showSearchAndReplaceForEdit = true;
                this.showSuffixForEdit = false;
                this.showapexScriptForEdit = false;
            } else if (this.selectedMaskingTypeForEdit === 'Suffix') {
                this.showSearchAndReplaceForEdit = false;
                this.showSuffixForEdit = true;
                this.showapexScriptForEdit = false;
            } else if (this.selectedMaskingTypeForEdit === 'Apex Script') {
                this.showapexScriptForEdit = true;
                this.showSearchAndReplaceForEdit = false;
                this.showSuffixForEdit = false;
            }

            // Reload rules for the selected masking type
            this.findAndReplaceRulesForEdit = this.findAndReplaceRulesForBackendForEdit.filter(
                rule => rule.maskingType === this.selectedMaskingTypeForEdit
            );
        } else {
            // If no previous masking type, clear the selection and hide both sections
            this.selectedMaskingTypeForEdit = '';
            this.findAndReplaceRulesForEdit = [];
        }

        console.log("Selected Masking Type:", this.selectedMaskingTypeForEdit);
        console.log("Filtered Rules:", JSON.stringify(this.findAndReplaceRulesForEdit));
    }
           
           
    /*** show modal  ***/
    @track isShowModalForEdit = false;

    showModalBox() {
        this.isShowModalForEdit = true;
    }

    hideModalBox() {
        this.isShowModalForEdit = false;
    }
    

    progressForEdit = 0;
    isProgressingForEdit = false;

    get computedLabelForEdit() {
        return this.isProgressingForEdit ? 'Stop' : 'Start';
    }

    toggleProgressForEdit() {
        console.log('this.isProgressing ForEdit--- ' + this.isProgressingForEdit);

        if (this.isProgressingForEdit) {
            // stop
            this.isProgressingForEdit = false;
            clearInterval(this._intervalForEdit);
        } else {
            // start
            const url = `/lightning/r/Refresh_Template__c/${this.templateRecordId}/view?reloadRecord=true`;

            this.isProgressingForEdit = true;
            this._intervalForEdit = setInterval(() => {
                this.progressForEdit = this.progressForEdit === 100 ? (window.location.href = url) : this.progressForEdit + 1;
            }, 100);
        }
    }
           
    disconnectedCallbackForEdit() {
        clearInterval(this._intervalForEdit);
    }
    // Add to your existing properties
    @track selectedAccordionSectionForEdit = '';
           
    /*** end of progress bar ***/

    handleCreateTemplateForEdit() {
        console.log('this.selectedScheduledJobsForEdit --- ' + JSON.stringify(this.selectedScheduledJobsForEdit)); 
        if (this.templateNameForEdit != '') {
            console.log('selected user length ForEdit= ' + Object.keys(this.selectedUsersForEdit).length);
            console.log('selected custom settings lengthForEdit = ' + Object.keys(this.selectedCustomSettingsForEdit).length);
           // console.log('selected scheduled jobs length ForEdit= ' + Object.keys(this.selectedScheduledJobsForEdit).length);
            console.log('selected metadata length ForEdit = ' + Object.keys(this.selectedMetadataListToDisplayForEdit).length);
            console.log('template for find and replace ForEdit = ' + JSON.stringify(this.findAndReplaceRulesForBackendForEdit));
            console.log('apex scripts = ForEdit' + JSON.stringify(this.originalScriptsForEdit));

            console.log('this.selectedOrg --- ' + this.parentOrg); 
            console.log('this.templateRecordId --- ' + this.templateRecordId);
            console.log('this.templateNameForEdit --- ' + this.templateNameForEdit);
            console.log('this.metadataPackageXmlContentForEdit --- ' + this.metadataPackageXmlContentForEdit);
            console.log('this.selectedUsernamesForEdit --- ' + this.selectedUsernamesForEdit);
            console.log('this.customSettingNamesListForEdit --- ' + this.customSettingNamesListForEdit);
            console.log('this.selectedScheduledJobsForEdit --- ' + JSON.stringify(this.selectedScheduledJobsForEdit));
            console.log('this.findAndReplaceRulesForBackendForEdit --- ' + JSON.stringify(this.findAndReplaceRulesForBackendForEdit));
            console.log('jsonData --- ' + JSON.stringify(this.originalScriptsForEdit));
            console.log('csvString --- ' + this.convertApexScriptsToCSV(this.originalScriptsForEdit));

            let isTempNull = (Object.keys(this.selectedUsersForEdit).length === 0 && Object.keys(this.selectedCustomSettingsForEdit).length === 0 && Object.keys(this.selectedScheduledJobsForEdit).length == 0 && Object.keys(this.selectedMetadataListToDisplayForEdit).length === 0 && this.originalScriptsForEdit.length === 0) ? true : false;
            console.log('is everything empty --- ' + isTempNull);

            if (isTempNull) {
                const dispEvent = new ShowToastEvent({
                    title: 'Error',
                    message: 'There is no metadata/data to create a template...',
                    variant: 'error'
                });
                this.dispatchEvent(dispEvent);
                this.showCreateTemplatePageForEdit = true;
            }
            else {
                console.log('template creation successfull');
                this.isShowModalForEdit = true;
                this.toggleProgressForEdit();
                const jsonData = JSON.stringify(this.originalScriptsForEdit);
                //const csvString = this.convertApexScriptsToCSV(this.originalScripts);
                let csvString = '';
                if (this.originalScriptsForEdit && this.originalScriptsForEdit.length > 0) {
                    csvString = this.convertApexScriptsToCSVForEdit(this.originalScriptsForEdit);
                }

                updateTemplate({
                    parentOrgId: this.parentOrg, refTempId: this.templateRecordId, templateName: this.templateNameForEdit,
                    metadataPackageXmlContent: this.metadataPackageXmlContentForEdit, selectedUsernames: this.selectedUsernamesForEdit,
                    customSettingNames: this.customSettingNamesListForEdit, sJobs: JSON.stringify(this.selectedScheduledJobsForEdit),
                    findAndReplaceTemplate: JSON.stringify(this.findAndReplaceRulesForBackendForEdit), jsonData: jsonData,
                    csvString: csvString
                })
                    .then(result => {
                        console.log('result from update template --- ' + JSON.stringify(result));
                        //const url = `/lightning/r/Refresh_Template__c/${this.templateRecordId}/view`;
                        //window.location.href = url;
                    })
                    .catch(error => {
                        console.log('error --- ' + JSON.stringify(error));
                    })
            }

        }
        else {
            const dispEvent = new ShowToastEvent({
                title: 'Error',
                message: 'Please provide a template name...',
                variant: 'error'
            });
            this.dispatchEvent(dispEvent);
            this.showCreateTemplatePageForEdit = true;
        }

    }
           
    convertApexScriptsToCSVForEdit(scripts) {
        if (!scripts || scripts.length === 0) return 'order,scriptname,ScriptData\n';

        const header = 'order,scriptname,ScriptData\n';
        const rows = scripts.map(script => {
            // Escape any commas in the script data
            const sanitizedScriptData = script.ScriptData.replace(/,/g, '\\,');
            const sanitizedScriptName = script.ScriptName.replace(/,/g, '\\,');
            return `${script.order},${sanitizedScriptName},${sanitizedScriptData}`;
        }).join('\n');

        return header + rows;
    }
    /****************** END UPDATE TEMPLATE CODE BLOCK FOR UPDATE EXISTING TEMPLATE ******************/
   
}