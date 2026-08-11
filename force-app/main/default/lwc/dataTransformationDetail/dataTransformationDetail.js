import { LightningElement, api, wire,track } from 'lwc';
import getUniqueFilesForRecord from '@salesforce/apex/DTDetailController.getUniqueFilesForRecord';
import getMergedFileBodyByName from '@salesforce/apex/DTDetailController.getMergedFileBodyByName';

export default class DataTransformationDetail extends LightningElement {
    @api recordId;

    fileOptions = [];
    selectedFileName = null;
    parsedData = [];
    columns = [];
    isLoading = false;
    searchQuery = '';
    @track sortBy;
    @track sortDirection = 'asc';
    @track showSearchBar = false;
    @track hasLoadedCsv = false;

    pageSize = 5;
    /*pageSizeOptions = [
        { label: '10', value: 10 },
        { label: '25', value: 25 },
        { label: '50', value: 50 },
        { label: '100', value: 100 }
    ];*/
    @track pageSizeOptions = [5, 10, 25, 50, 100];
    currentPage = 1;
    totalPages = 1;
    pagedData = [];
    filteredData = [];

    @wire(getUniqueFilesForRecord, { recordId: '$recordId' })
    wiredFiles({ error, data }) {
        if (data) {
            this.fileOptions = data.map(file => ({
                label: file.title,
                value: file.name
            }));
        } else if (error) {
            console.error('Error loading files:', error);
        }
    }

    handleFileChange(event) {
        this.selectedFileName = event.detail.value;
        this.loadFileBody(this.selectedFileName);

        if(this.selectedFileName){
            this.showSearchBar = true;
        }else{
            this.showSearchBar = false;
        }
    }

    loadFileBody(fileName) {
        this.isLoading = true;
        getMergedFileBodyByName({ recordId: this.recordId, fileName: fileName })
            .then(result => {
                this.isLoading = false;
                this.parseCsv(result);
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error fetching file body:', error);
                this.parsedData = [];
                this.columns = [];
                this.pagedData = [];
            });
    }

    parseCsv(raw) {
        if (!raw) {
            this.parsedData = [];
            this.columns = [];
            this.pagedData = [];
            return;
        }

        const lines = raw.trim().split('\n').map(line => line.trim()).filter(line => line !== '');
        if (lines.length === 0) return;

        const headers = lines[0].split(',').map(h => h.trim().replace(/^"|"$/g, ''));

       // this.columns = headers.map(h => ({ label: h, fieldName: h }));

       this.columns = headers.map(h => ({
                        label: h.replace(/^"|"$/g, ''),
                        fieldName: h.replace(/^"|"$/g, ''),
                        sortable: true
                    }));
    

        const dataRows = [];
        for (let i = 1; i < lines.length; i++) {
            const values = lines[i].split(',').map(val => val.trim());
            const isDuplicateHeader = values.every((val, idx) => val === headers[idx]);
            if (isDuplicateHeader) continue;

            const row = {};
            headers.forEach((h, idx) => {
                const cleanValue = values[idx] ? values[idx].replace(/^"|"$/g, '') : '';
                row[h] = cleanValue;
            });
            
            row.id = `${i}`; // Add ID for datatable
            dataRows.push(row);
        }

        this.parsedData = dataRows;
        this.filteredData = dataRows;
        this.setupPagination();
        this.hasLoadedCsv = true;
    }

    handleSearchChange(event) {
        this.searchQuery = event.target.value.toLowerCase();
        this.applySearch();
    }

    applySearch() {
        if (!this.searchQuery) {
            this.filteredData = this.parsedData;
        } else {
            this.filteredData = this.parsedData.filter(row =>
                Object.values(row).some(value =>
                    value?.toLowerCase().includes(this.searchQuery)
                )
            );
        }
        this.setupPagination();
    }

    setupPagination() {
        this.totalPages = Math.ceil(this.filteredData.length / this.pageSize) || 1;
        this.currentPage = Math.min(this.currentPage, this.totalPages); // Prevent overflow
        this.updatePagedData();
    }
    
    updatePagedData() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.pagedData = this.filteredData.slice(start, end);
    }
    
    handlePageSizeChange(event) {
        const newSize = event.target.value || event.detail.value; // Handles both <select> and combobox
        this.pageSize = parseInt(newSize, 10);
        this.currentPage = 1;
        this.setupPagination();
    }
    
    handleFirst() {
        if (this.currentPage > 1) {
            this.currentPage = 1;
            this.updatePagedData();
        }
    }
    
    handlePrev() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePagedData();
        }
    }
    
    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePagedData();
        }
    }
    
    handleLast() {
        if (this.currentPage < this.totalPages) {
            this.currentPage = this.totalPages;
            this.updatePagedData();
        }
    }
    
    get isFirstPage() {
        return this.currentPage <= 1;
    }
    
    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }
    
    get totalRecords() {
        return this.filteredData.length;
    }

    handleSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData();
        this.setupPagination(); // reapply pagination after sorting
    }
    
    sortData() {
        const data = [...this.filteredData];
        const { sortBy, sortDirection } = this;
    
        data.sort((a, b) => {
            let valA = a[sortBy] || '';
            let valB = b[sortBy] || '';
    
            // Handle numeric values if possible
            if (!isNaN(valA) && !isNaN(valB)) {
                valA = Number(valA);
                valB = Number(valB);
            } else {
                valA = valA.toString().toLowerCase();
                valB = valB.toString().toLowerCase();
            }
    
            return sortDirection === 'asc'
                ? valA > valB ? 1 : valA < valB ? -1 : 0
                : valA < valB ? 1 : valA > valB ? -1 : 0;
        });
    
        this.filteredData = data;
    }
    
    
}