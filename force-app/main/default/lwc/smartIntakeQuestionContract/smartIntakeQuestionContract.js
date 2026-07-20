import { api, LightningElement } from 'lwc';

export default class SmartIntakeQuestionContract extends LightningElement {
    @api value;
    @api configuration;
}