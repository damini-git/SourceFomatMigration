import { LightningElement, api } from 'lwc';

export default class Numerator extends LightningElement {
    // Step 3: use getter/setter instead of direct @api counter
    _currentCount = 0;
    priorCount = 0;

    @api
    get counter() {
        return this._currentCount;
    }

    set counter(value) {
        this.priorCount = this._currentCount;
        this._currentCount = value;
    }

    handleIncrement() {
        this._currentCount += 1;
    }

    handleDecrement() {
        this._currentCount -= 1;
    }

    handleMultiply(event) {
        this._currentCount *= event.detail.factor;
    }

    @api
    maximizeCounter(amount = 1000000) {
        this._currentCount += amount;
    }

    get currentCount() {
        return `Count: ${this._currentCount}`;
    }
}