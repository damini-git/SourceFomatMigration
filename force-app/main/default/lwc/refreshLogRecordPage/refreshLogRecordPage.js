import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import checkValidationStatus from '@salesforce/apex/SandboxRefreshClass.checkValidationStatus';
import checkDeploymentStatus from '@salesforce/apex/SandboxRefreshClass.checkDeploymentStatus';
import getSandboxStatus from '@salesforce/apex/SandboxRefreshClass.getSandboxStatus';
import getValidationResult from '@salesforce/apex/SandboxRefreshClass.getValidationResult';
import getDeployResult from '@salesforce/apex/SandboxRefreshClass.getDeployResult';
import getMetadataMaskingLogRecordofRefreshTemplate from '@salesforce/apex/PostRefreshAutomationClass.getMetadataMaskingLogRecordofRefreshTemplate';
import getSuffixLogRecordofRefreshTemplate from '@salesforce/apex/PostRefreshAutomationClass.getSuffixLogRecordofRefreshTemplate';

const FIELDS = ['Logs__c.Log_Type__c', 'Logs__c.Status__c', 'Logs__c.Parent_Template__c'];

const columnsForValidationResultForSucess = [
    { label: 'S.No.', fieldName: 'serialNumber', type: 'number', initialWidth: 70, cellAttributes: { alignment: 'center' } },
    { label: 'Component Name', fieldName: 'successCompName', type: 'text',  sortable: true },
    { label: 'Component Type', fieldName: 'successCompType', type: 'text',  sortable: true }
];

const columnsForValidationResultForFailure = [
    { label: 'S.No.', fieldName: 'serialNumber', type: 'number', initialWidth: 80, cellAttributes: { alignment: 'center' } },
    { label: 'Component Name', fieldName: 'compName', type: 'text',  sortable: true },
    { label: 'Component Type', fieldName: 'compType', type: 'text',  sortable: true },
    { label: 'Problem', fieldName: 'problem', type: 'text',  sortable: true },
    { label: 'Problem Type', fieldName: 'problemType', type: 'text', sortable: true },
    //{ label: 'Success', fieldName: 'success', type: 'text', initialWidth: 150 },
    //{ label: 'Warning', fieldName: 'warning', type: 'text', initialWidth: 150 },
    { label: 'Line Number', fieldName: 'lineNumber', type: 'text',  sortable: true },
    { label: 'Column Number', fieldName: 'columnNumber', type: 'text',  sortable: true }
];

const columnsForDeploymentResultForSucess = [
    { label: 'S.No.', fieldName: 'serialNumber', type: 'number', initialWidth: 70, cellAttributes: { alignment: 'center' } },
    { label: 'Component Name', fieldName: 'successCompName', type: 'text',  sortable: true },
    { label: 'Component Type', fieldName: 'successCompType', type: 'text',  sortable: true }
];

const columnsForDeploymentResultForFailure = [
    { label: 'S.No.', fieldName: 'serialNumber', type: 'number', initialWidth: 70, cellAttributes: { alignment: 'center' } },
    { label: 'Component Name', fieldName: 'compName', type: 'text', sortable: true },
    { label: 'Component Type', fieldName: 'compType', type: 'text',  sortable: true },
    { label: 'Problem', fieldName: 'problem', type: 'text',  sortable: true },
    { label: 'Problem Type', fieldName: 'problemType', type: 'text',  sortable: true },
    //{ label: 'Success', fieldName: 'success', type: 'text', initialWidth: 150 },
    //{ label: 'Warning', fieldName: 'warning', type: 'text', initialWidth: 150 },
    { label: 'Line Number', fieldName: 'lineNumber', type: 'text',  sortable: true },
    { label: 'Column Number', fieldName: 'columnNumber', type: 'text',  sortable: true }
];

export default class RefreshLogRecordPage extends LightningElement {
    @api recordId;
    wiredRecordData;
    @track isValidationFailed = false;
    @track isDeploymentFailed = false;

    // Search, pagination, and display properties
    @track recordsPerPageOptions = [5, 10, 25, 50, 100];
    @track successRecordsPerPage = 5;
    @track recordsPerPage = 5;

    // Search terms
    @track successSearchTerm = '';
    @track failureSearchTerm = '';
    @track deploySuccessSearchTerm = '';
    @track deployFailureSearchTerm = '';

    // Current page tracking
    @track currentPageSuccess = 1;
    @track currentPageFailure = 1;
    @track currentPageDeploySuccess = 1;
    @track currentPageDeployFailure = 1;

    // Filtered data arrays
    @track filteredSuccessData = [];
    @track filteredFailureData = [];
    @track filteredDeploySuccessData = [];
    @track filteredDeployFailureData = [];
    // Sorting properties
    @track successSortedBy = 'successCompName';
    @track successSortedDirection = 'asc';
    @track failureSortedBy = 'compName';
    @track failureSortedDirection = 'asc';
    @track deploySuccessSortedBy = 'successCompName';
    @track deploySuccessSortedDirection = 'asc';
    @track deployFailureSortedBy = 'compName';
    @track deployFailureSortedDirection = 'asc';

    // Paginated data (what gets displayed)
    @track paginatedSuccessData = [];
    @track paginatedFailureData = [];
    @track paginatedDeploySuccessData = [];
    @track paginatedDeployFailureData = [];


    @track showSpinnerValidationSuccess = false;
    @track showSpinnerDeploySuccess = false;
    


    connectedCallback() {
        console.log('recordId: --- ', this.recordId);
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredLogRecord(result) {
        this.wiredRecordData = result;
        const { error, data } = result;

        if (data) {
            const logType = data.fields.Log_Type__c.value;
            const status = data.fields.Status__c.value;
            const parentTemplate = data.fields.Parent_Template__c.value;

            console.log('logType --- ' + logType);
            console.log('status --- ' + status);
            if ((logType === 'Validate Template' || logType === 'Deploy - Metadata Restoration' || logType === 'Search & Replace - Metadata Transformation' || logType === 'Suffix - Metadata Transformation') && (status === 'InProgress' || status === 'Pending')) {
                this.callApexMethod(logType, parentTemplate);
            }

            if (logType === 'Sandbox Refresh' && (status !== 'Failed' || status !== 'Completed')) {
                this.callApexMethod(logType, parentTemplate);
            }

            if (logType === 'Validate Template' && status === 'Failed') {
                this.isValidationFailed = true;
                this.showSpinnerValidationSuccess = true;
                this.getValidationResult();
            }
            else {
                this.isValidationFailed = false;
            }

            if (logType === 'Deploy - Metadata Restoration' && status === 'Failed') {
                this.isDeploymentFailed = true;
                this.showSpinnerDeploySuccess = true;
                this.getDeployResult();
            }
            else {
                this.isDeploymentFailed = false;
            }

        } else if (error) {
            console.error('Error fetching Log record:', error);
        }
    }

    callApexMethod(logType, parentTemplate) {
        console.log('logType --- ', logType);
        let apexMethod;
        switch (logType) {
            case 'Validate Template':
                apexMethod = checkValidationStatus;
                break;
            case 'Deploy - Metadata Restoration':
                apexMethod = checkDeploymentStatus;
                break;
            case 'Sandbox Refresh':
                this.getSandboxStatus(parentTemplate);
                break;
            case 'Search & Replace - Metadata Transformation':
                this.getMetadataMaskingLogRecordofRefreshTemplate(parentTemplate);
                break;
            case 'Suffix - Metadata Transformation':
                this.getSuffixLogRecordofRefreshTemplate(parentTemplate);
                break;
        }

        console.log('apexMethod --- ', apexMethod);

        if (apexMethod) {
            console.log('Calling Apex method for:', logType);

            apexMethod({ logRecordId: this.recordId })
                .then(() => {
                    console.log('Apex method executed successfully, refreshing data...');
                    return refreshApex(this.wiredRecordData);
                })
                .catch(error => console.error('Error calling Apex method:', error));
        }
    }

    getSandboxStatus(parentTemplate) {
        getSandboxStatus({ logRecordId: this.recordId, templateId: parentTemplate })
            .then(() => {
                console.log('Apex method executed successfully')
                return refreshApex(this.wiredRecordData);
            })
            .catch(error => console.error('Error calling Apex method:', error));
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


    /***********  code for fetching the validation result ***********/

    @track dataOfValidationResultForSuccess;
    @track dataOfValidationResultForFailure;
    @track columnsForValidationResultForSucess = [];
    @track columnsForValidationResultForFailure = [];
    @track isValidationSuccess = false;
    @track isValidationFailure = false;
    @track failureComponentList = [];
    @track successComponentList = [];
    @track showSpinnerForValidation = false;

    getValidationResult() {
        

        console.log('log record id --- ' + this.recordId);
        getValidationResult({ logId: this.recordId })
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

                    // Initialize pagination for validation results
                    this.initializeValidationPagination();
                }
                /*else {
                    this.isValidated = false;
                    this.showSpinnerForValidation = true;
                    this.handleGetValidationStatus();
                }*/

            })
            .catch(error => {
                console.log('error -- ' + JSON.stringify(error));
            })
            .finally(() => {
                this.showSpinnerValidationSuccess = false;
            });
    }


    @track dataOfDeploymentResultForSuccess;
    @track dataOfDeploymentResultForFailure;
    @track columnsForDeploymentResultForSucess = [];
    @track columnsForDeploymentResultForFailure = [];
    @track isDeploymentSuccess = false;
    @track isDeploymentFailure = false;
    @track failureComponentListForDeployment = [];
    @track successComponentListForDeployment = [];
    @track showSpinnerForDeployment = false;

    getDeployResult() {
        

        console.log('log record id --- ' + this.recordId);
        getDeployResult({ logId: this.recordId })
            .then(result => {
                console.log('result -- ' + JSON.stringify(result));
                this.columnsForDeploymentResultForSucess = columnsForDeploymentResultForSucess;
                this.columnsForDeploymentResultForFailure = columnsForDeploymentResultForFailure;
                this.dataOfDeploymentResultForSuccess = [];
                this.dataOfDeploymentResultForFailure = [];

                console.log('result.allComponentsChecked --- ' + result.allComponentsChecked);
                let allComponentsChecked = result.allComponentsChecked || false;

                if (allComponentsChecked) {
                    this.successComponentListForDeployment = result.successList || [];
                    this.isDeploymentSuccess = (result.successList.length > 0) ? true : false;

                    this.failureComponentListForDeployment = result.failureList || [];
                    this.isDeploymentFailure = (result.failureList.length > 0) ? true : false;

                    console.log('this.isDeploymentSuccess --- ' + this.isDeploymentSuccess + ', this.isDeploymentFailure --- ' + this.isDeploymentFailure);

                    this.successComponentListForDeployment.forEach(objWrap => {
                        this.dataOfDeploymentResultForSuccess.push({
                            successCompName: String(objWrap['successCompName']),
                            successCompType: String(objWrap['successCompType'])
                        });
                    });

                    this.failureComponentListForDeployment.forEach(objWrap => {
                        this.dataOfDeploymentResultForFailure.push({
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
                    this.showSpinnerForDeployment = false;

                    // Initialize pagination for deployment results
                    this.initializeDeploymentPagination();
                }
                /*else {
                    this.isValidated = false;
                    this.showSpinnerForDeployment = true;
                    this.handleGetValidationStatus();
                }*/

            })
            .catch(error => {
                console.log('error -- ' + JSON.stringify(error));
            })
            .finally(() => {
                this.showSpinnerDeploySuccess = false;
            });
    }

    // ====== PAGINATION AND SEARCH INITIALIZATION ======

    initializeValidationPagination() {
        // Initialize filtered data
        this.filteredSuccessData = [...this.dataOfValidationResultForSuccess];
        this.filteredFailureData = [...this.dataOfValidationResultForFailure];

        // Reset current pages
        this.currentPageSuccess = 1;
        this.currentPageFailure = 1;

        // Update pagination
        this.updateSuccessPagination();
        this.updateFailurePagination();
    }

    initializeDeploymentPagination() {
        // Initialize filtered data
        this.filteredDeploySuccessData = [...this.dataOfDeploymentResultForSuccess];
        this.filteredDeployFailureData = [...this.dataOfDeploymentResultForFailure];

        // Reset current pages
        this.currentPageDeploySuccess = 1;
        this.currentPageDeployFailure = 1;

        // Update pagination
        this.updateDeploySuccessPagination();
        this.updateDeployFailurePagination();
    }

    // ====== VALIDATION SUCCESS TABLE HANDLERS ======

    // Handle search for validation success table
    handleSuccessSearch(event) {
        this.successSearchTerm = event.target.value;
        this.currentPageSuccess = 1; // Reset to first page on new search

        // If search term is empty, use all data
        if (!this.successSearchTerm) {
            this.filteredSuccessData = [...this.dataOfValidationResultForSuccess];
        } else {
            // Filter based on search term (case insensitive)
            const searchTerm = this.successSearchTerm.toLowerCase();
            this.filteredSuccessData = this.dataOfValidationResultForSuccess.filter(item => {
                // Search through all fields in the object
                return Object.values(item).some(value =>
                    value && value.toString().toLowerCase().includes(searchTerm)
                );
            });
        }

        this.updateSuccessPagination();
    }

  /*  // Update pagination for validation success table
    updateSuccessPagination() {
        const startIndex = (this.currentPageSuccess - 1) * this.successRecordsPerPage;
        const endIndex = startIndex + this.successRecordsPerPage;
        this.paginatedSuccessData = this.filteredSuccessData.slice(startIndex, endIndex);
    }*/

    handleSuccessRecordsPerPageChange(event) {
            this.successRecordsPerPage = parseInt(event.target.value, 10);
            this.currentPageSuccess = 1;
            this.updateSuccessPagination();
        }
        

    // Navigation handlers for validation success table
    handleSuccessFirst() {
        this.currentPageSuccess = 1;
        this.updateSuccessPagination();
    }
    
    handleSuccessPrev() {
        if (this.currentPageSuccess > 1) {
            this.currentPageSuccess--;
            this.updateSuccessPagination();
        }
    }
    
    handleSuccessNext() {
        if (this.currentPageSuccess < this.totalPagesSuccess) {
            this.currentPageSuccess++;
            this.updateSuccessPagination();
        }
    }
    
    handleSuccessLast() {
        this.currentPageSuccess = this.totalPagesSuccess;
        this.updateSuccessPagination();
    }
    

    // ====== VALIDATION FAILURE TABLE HANDLERS ======

    // Handle search for validation failure table
    handleFailureSearch(event) {
        this.failureSearchTerm = event.target.value;
        this.currentPageFailure = 1; // Reset to first page on new search

        // If search term is empty, use all data
        if (!this.failureSearchTerm) {
            this.filteredFailureData = [...this.dataOfValidationResultForFailure];
        } else {
            // Filter based on search term (case insensitive)
            const searchTerm = this.failureSearchTerm.toLowerCase();
            this.filteredFailureData = this.dataOfValidationResultForFailure.filter(item => {
                // Search through all fields in the object
                return Object.values(item).some(value =>
                    value && value.toString().toLowerCase().includes(searchTerm)
                );
            });
        }

        this.updateFailurePagination();
    }

  /*  // Update pagination for validation failure table
    updateFailurePagination() {
        const startIndex = (this.currentPageFailure - 1) * this.recordsPerPage;
        const endIndex = startIndex + this.recordsPerPage;
        this.paginatedFailureData = this.filteredFailureData.slice(startIndex, endIndex);
    }*/

    // Page size change handler for validation failure table
    handleFailureRecordsPerPageChange(event) {
        this.recordsPerPage = parseInt(event.target.value, 10);
        this.currentPageFailure = 1; // Reset to first page when changing page size
        this.updateAllPagination();
    }

    // Navigation handlers for validation failure table
    handleFailureFirst() {
        this.currentPageFailure = 1;
        this.updateFailurePagination();
    }

    handleFailurePrev() {
        if (this.currentPageFailure > 1) {
            this.currentPageFailure--;
            this.updateFailurePagination();
        }
    }

    handleFailureNext() {
        if (this.currentPageFailure < this.totalPagesFailure) {
            this.currentPageFailure++;
            this.updateFailurePagination();
        }
    }

    handleFailureLast() {
        this.currentPageFailure = this.totalPagesFailure;
        this.updateFailurePagination();
    }

    // ====== DEPLOYMENT SUCCESS TABLE HANDLERS ======

    // Handle search for deployment success table
    handleDeploySuccessSearch(event) {
        this.deploySuccessSearchTerm = event.target.value;
        this.currentPageDeploySuccess = 1; // Reset to first page on new search

        // If search term is empty, use all data
        if (!this.deploySuccessSearchTerm) {
            this.filteredDeploySuccessData = [...this.dataOfDeploymentResultForSuccess];
        } else {
            // Filter based on search term (case insensitive)
            const searchTerm = this.deploySuccessSearchTerm.toLowerCase();
            this.filteredDeploySuccessData = this.dataOfDeploymentResultForSuccess.filter(item => {
                // Search through all fields in the object
                return Object.values(item).some(value =>
                    value && value.toString().toLowerCase().includes(searchTerm)
                );
            });
        }

        this.updateDeploySuccessPagination();
    }

    /*// Update pagination for deployment success table
    updateDeploySuccessPagination() {
        const startIndex = (this.currentPageDeploySuccess - 1) * this.successRecordsPerPage;
        const endIndex = startIndex + this.successRecordsPerPage;
        this.paginatedDeploySuccessData = this.filteredDeploySuccessData.slice(startIndex, endIndex);
    }*/

    // Page size change handler for deployment success table
    handleDeploySuccessRecordsPerPageChange(event) {
        this.successRecordsPerPage = parseInt(event.target.value, 10);
        this.currentPageDeploySuccess = 1; // Reset to first page when changing page size
        this.updateAllSuccessPagination();
    }

    // Navigation handlers for deployment success table
    handleDeploySuccessFirst() {
        this.currentPageDeploySuccess = 1;
        this.updateDeploySuccessPagination();
    }

    handleDeploySuccessPrev() {
        if (this.currentPageDeploySuccess > 1) {
            this.currentPageDeploySuccess--;
            this.updateDeploySuccessPagination();
        }
    }

    handleDeploySuccessNext() {
        if (this.currentPageDeploySuccess < this.totalPagesDeploySuccess) {
            this.currentPageDeploySuccess++;
            this.updateDeploySuccessPagination();
        }
    }

    handleDeploySuccessLast() {
        this.currentPageDeploySuccess = this.totalPagesDeploySuccess;
        this.updateDeploySuccessPagination();
    }

    // ====== DEPLOYMENT FAILURE TABLE HANDLERS ======

    // Handle search for deployment failure table
    handleDeployFailureSearch(event) {
        this.deployFailureSearchTerm = event.target.value;
        this.currentPageDeployFailure = 1; // Reset to first page on new search

        // If search term is empty, use all data
        if (!this.deployFailureSearchTerm) {
            this.filteredDeployFailureData = [...this.dataOfDeploymentResultForFailure];
        } else {
            // Filter based on search term (case insensitive)
            const searchTerm = this.deployFailureSearchTerm.toLowerCase();
            this.filteredDeployFailureData = this.dataOfDeploymentResultForFailure.filter(item => {
                // Search through all fields in the object
                return Object.values(item).some(value =>
                    value && value.toString().toLowerCase().includes(searchTerm)
                );
            });
        }

        this.updateDeployFailurePagination();
    }

   /* // Update pagination for deployment failure table
    updateDeployFailurePagination() {
        const startIndex = (this.currentPageDeployFailure - 1) * this.recordsPerPage;
        const endIndex = startIndex + this.recordsPerPage;
        this.paginatedDeployFailureData = this.filteredDeployFailureData.slice(startIndex, endIndex);
    }*/

    
    handleDeployFailureRecordsPerPageChange(event) {
        this.recordsPerPage = parseInt(event.target.value, 10);
        this.currentPageDeployFailure = 1;
        this.updateAllPagination();
    }

    // Navigation handlers for deployment failure table
    handleDeployFailureFirst() {
        this.currentPageDeployFailure = 1;
        this.updateDeployFailurePagination();
    }

    handleDeployFailurePrev() {
        if (this.currentPageDeployFailure > 1) {
            this.currentPageDeployFailure--;
            this.updateDeployFailurePagination();
        }
    }

    handleDeployFailureNext() {
        if (this.currentPageDeployFailure < this.totalPagesDeployFailure) {
            this.currentPageDeployFailure++;
            this.updateDeployFailurePagination();
        }
    }

    handleDeployFailureLast() {
        this.currentPageDeployFailure = this.totalPagesDeployFailure;
        this.updateDeployFailurePagination();
    }

    
    updateAllSuccessPagination() {
        this.updateSuccessPagination();
        this.updateDeploySuccessPagination();
        this.updateDeployFailurePagination(); 
    }
    

    updateAllPagination() {
       // this.updateSuccessPagination();
        this.updateFailurePagination();
        this.updateDeploySuccessPagination();
        this.updateDeployFailurePagination();
    }

    // ====== GETTERS FOR COMPUTED VALUES ======

    // Total records counts
    get totalSuccessRecords() {
        return this.filteredSuccessData.length;
    }

    get totalFailureRecords() {
        return this.filteredFailureData.length;
    }

    get totalDeploySuccessRecords() {
        return this.filteredDeploySuccessData.length;
    }

    get totalDeployFailureRecords() {
        return this.filteredDeployFailureData.length;
    }

    // Total pages calculations
    get totalPagesSuccess() {
        return Math.ceil(this.filteredSuccessData.length / this.successRecordsPerPage) || 1;
    }
    
    get totalPagesFailure() {
        return Math.ceil(this.filteredFailureData.length / this.recordsPerPage) || 1;
    }
    
    get totalPagesDeploySuccess() {
        return Math.ceil(this.filteredDeploySuccessData.length / this.successRecordsPerPage) || 1;
    }
    
    get totalPagesDeployFailure() {
        return Math.ceil(this.filteredDeployFailureData.length / this.recordsPerPage) || 1;
    }
    

    // Button disable states
    get isSuccessPrevDisabled() {
        return this.currentPageSuccess <= 1;
    }

    get isSuccessNextDisabled() {
        return this.currentPageSuccess >= this.totalPagesSuccess;
    }

    get isFailurePrevDisabled() {
        return this.currentPageFailure <= 1;
    }

    get isFailureNextDisabled() {
        return this.currentPageFailure >= this.totalPagesFailure;
    }

    get isDeploySuccessPrevDisabled() {
        return this.currentPageDeploySuccess <= 1;
    }

    get isDeploySuccessNextDisabled() {
        return this.currentPageDeploySuccess >= this.totalPagesDeploySuccess;
    }

    get isDeployFailurePrevDisabled() {
        return this.currentPageDeployFailure <= 1;
    }

    get isDeployFailureNextDisabled() {
        return this.currentPageDeployFailure >= this.totalPagesDeployFailure;
    }

    // ====== SORTING HANDLERS ======

    // Handle sort for validation success table
    handleSuccessSort(event) {
        this.successSortedBy = event.detail.fieldName;
        this.successSortedDirection = event.detail.sortDirection;
        this.sortData(this.filteredSuccessData, this.successSortedBy, this.successSortedDirection);
        this.updateSuccessPagination();
    }
    

    // Handle sort for validation failure table
    handleFailureSort(event) {
        this.failureSortedBy = event.detail.fieldName;
        this.failureSortedDirection = event.detail.sortDirection;
        this.sortData(this.filteredFailureData, this.failureSortedBy, this.failureSortedDirection);
        this.updateFailurePagination();
    }

    // Handle sort for deployment success table
    handleDeploySuccessSort(event) {
        this.deploySuccessSortedBy = event.detail.fieldName;
        this.deploySuccessSortedDirection = event.detail.sortDirection;
        this.sortData(this.filteredDeploySuccessData, this.deploySuccessSortedBy, this.deploySuccessSortedDirection);
        this.updateDeploySuccessPagination();
    }

    // Handle sort for deployment failure table
    handleDeployFailureSort(event) {
        this.deployFailureSortedBy = event.detail.fieldName;
        this.deployFailureSortedDirection = event.detail.sortDirection;
        this.sortData(this.filteredDeployFailureData, this.deployFailureSortedBy, this.deployFailureSortedDirection);
        this.updateDeployFailurePagination();
    }

    sortData(dataArray, fieldName, direction) {
        if (!dataArray || dataArray.length === 0) return;
    
        const cloneData = [...dataArray];
    
        cloneData.sort((a, b) => {
            const valueA = a[fieldName];
            const valueB = b[fieldName];
    
            // Detect if value is numeric
            const isNumeric = !isNaN(parseFloat(valueA)) && !isNaN(parseFloat(valueB));
    
            if (isNumeric) {
                return direction === 'asc'
                    ? parseFloat(valueA) - parseFloat(valueB)
                    : parseFloat(valueB) - parseFloat(valueA);
            }
    
            const strA = valueA ? valueA.toString().toLowerCase() : '';
            const strB = valueB ? valueB.toString().toLowerCase() : '';
    
            if (strA === strB) return 0;
            if (!strA && strB) return direction === 'asc' ? -1 : 1;
            if (strA && !strB) return direction === 'asc' ? 1 : -1;
    
            return direction === 'asc' ? (strA > strB ? 1 : -1) : (strA > strB ? -1 : 1);
        });
    
        dataArray.splice(0, dataArray.length, ...cloneData);
    }
    

    updateSuccessPagination() {
        const startIndex = (this.currentPageSuccess - 1) * this.successRecordsPerPage;
        const endIndex = startIndex + this.successRecordsPerPage;
        this.paginatedSuccessData = this.filteredSuccessData.slice(startIndex, endIndex).map((item, index) => ({
            ...item,
            serialNumber: startIndex + index + 1
        }));
    }
    
    
    updateFailurePagination() {
        const startIndex = (this.currentPageFailure - 1) * this.recordsPerPage;
        const endIndex = startIndex + this.recordsPerPage;
        this.paginatedFailureData = this.filteredFailureData.slice(startIndex, endIndex).map((item, index) => ({
            ...item,
            serialNumber: startIndex + index + 1
        }));
    }
    
    updateDeploySuccessPagination() {
        const startIndex = (this.currentPageDeploySuccess - 1) * this.successRecordsPerPage;
        const endIndex = startIndex + this.successRecordsPerPage;
        this.paginatedDeploySuccessData = this.filteredDeploySuccessData.slice(startIndex, endIndex).map((item, index) => ({
            ...item,
            serialNumber: startIndex + index + 1
        }));
    }
    
    
    updateDeployFailurePagination() {
        const startIndex = (this.currentPageDeployFailure - 1) * this.recordsPerPage;
        const endIndex = startIndex + this.recordsPerPage;
        this.paginatedDeployFailureData = this.filteredDeployFailureData.slice(startIndex, endIndex).map((item, index) => ({
            ...item,
            serialNumber: startIndex + index + 1
        }));
    }
    
    
}