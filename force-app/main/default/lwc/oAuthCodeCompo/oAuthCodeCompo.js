import { LightningElement,api } from 'lwc';
import getAuthCode from '@salesforce/apex/makeOauthCallCls.getAuthCode'

export default class OAuthCodeCompo extends LightningElement {
    @api recordId
    url
    result
    error

    @api async invoke(){
        getAuthCode({orgId : this.recordId})
        .then(result => {
            this.url = result;
            console.log('URL = '+this.url);
            window.open(this.url);
        })
        .catch(error =>{
            this.error = error;
            this.result = undefined
        })
    }
}