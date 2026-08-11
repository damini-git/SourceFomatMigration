import { LightningElement, api} from 'lwc';
import auth from '@salesforce/apex/AuthorizationCodeFlow.auth';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class OAuthCodeCall extends LightningElement {
    @api recordId;
    url
    result
    error

    connectedCallback() {
        console.log('recordId --- ' + this.recordId);
    }

    @api async invoke() {
        let params ={
            "orgId" : this.recordId
        };
        console.log('Parameter=='+params);
        console.log('Parameter=='+JSON.stringify(params));

       
                    await auth(params)
                        .then( (result) => {    
                            this.url = result;
                            console.log('this.url==='+this.url);
                            window.open(this.url);
                            this.error = undefined
                            console.log(this.result );
                            
                        })
                        .catch( (error) => {
                        this.result = undefined;
                        this.error = error;
                        console.log(this.error);
                    })


      /*  await auth(params)
        .then(result => {
            this.resultMsg= result
            console.log('this.result====='+this.resultMsg);

            if(this.resultMsg != null){
                    window.open(this.resultMsg)
                }
       })
    .catch(error => {
            this.result = undefined;
            this.error = error;
            console.log(this.error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Failed',
                    message: 'Authentication Failed',
                    variant: 'error',
                }),
            );
        })*/
}



}