import { LightningElement } from 'lwc';
import getAccessToken from '@salesforce/apex/makeOauthCallCls.getAccessToken';

export default class AuthenticationCompo extends LightningElement {

   authUrl = 'https://login.salesforce.com/services/oauth2/authorize?client_id=3MVG9GCMQoQ6rpzThsEqyB5wIskWH5M2OwQUIAuyZYUh.BKN4VbC8RmiZie10y3N0hOcvKyw4XcRopFZc0oeK&redirect_uri=https://cloudfulcrumpvtlmt5-dev-ed--c.develop.vf.force.com/apex/LearningIntegration&response_type=code'

   accessToken
   authCode

   renderedCallback() {
    if (this.authCode) return;
    const url = new URL(window.location.href);
    this.authCode = url.searchParams.get("code");
    console.log('Extracted code:', this.authCode);
}





 /*  authHandler(){
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: this.authUrl
        }
    });
   }*/
    authHandler(){
        console.log('Login button clicked');
        window.open(this.authUrl, '_blank');
    }

   getAccessHandler(){
    console.log(this.authCode);
    getAccessToken({authCode : this.authCode})
        .then(result =>{
            console.log(result);
            const obj = JSON.parse(result);
            this.accessToken =obj['access_token'];
            console.log('this.accessToken'+this.accessToken);
        })
        .catch(error =>{
            console.log(error);
        })
   }
}