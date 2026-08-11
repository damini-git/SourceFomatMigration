import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// ✅ Import fields from schema
import FIRSTNAME_FIELD from '@salesforce/schema/Contact.FirstName';
import LASTNAME_FIELD from '@salesforce/schema/Contact.LastName';
import EMAIL_FIELD from '@salesforce/schema/Contact.Email';

export default class ContactCreator extends LightningElement {
    fields = [FIRSTNAME_FIELD, LASTNAME_FIELD, EMAIL_FIELD];

    handleSuccess(event) {
        const contactId = event.detail.id;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Contact Created',
                message: 'Contact ID: ' + contactId,
                variant: 'success'
            })
        );
    }
}