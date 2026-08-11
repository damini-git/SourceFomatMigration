import { LightningElement, api } from 'lwc';

export default class Button extends LightningElement {
    @api label;
    @api icon;

    handleButton(event) {
        this.dispatchEvent(new CustomEvent('multiply', {
            detail: {
                factor: Number(this.label)
            },
            bubbles: true
        }));
    }
}