import { Component, Injector, ElementRef, Inject, ViewChild  } from '@angular/core';
import { QleKindCreationResource, QleKindCreationRequest } from './qle_kind_creation_data';
import { FormGroup, FormControl, AbstractControl, FormArray, FormBuilder, Validators } from '@angular/forms';
import { QleKindCreationService } from '../qle_kind_services';
import { ErrorLocalizer } from '../../../error_localizer';
import { ErrorMapper, ErrorResponse } from '../../../error_mapper';
import { QleKindQuestionFormComponent } from './qle_kind_question_form.component';
import { __core_private_testing_placeholder__ } from '@angular/core/testing';
import { HttpResponse } from "@angular/common/http";

@Component({
  selector: 'admin-qle-kind-creation-form',
  templateUrl: './qle_kind_creation_form.component.html'
})
export class QleKindCreationFormComponent {
  public qleKindToCreate : QleKindCreationResource | null = null;
  public creationFormGroup : FormGroup;
  public questionArray : FormArray;
  public creationUri :  string | null = null;
  public marketKindsList : Array<string> | null = null;
  public questionCreated : boolean = false;
  public lastQuestion : boolean = false;
  public showQuestionMultipleChoiceForm : boolean = false;

  public effectiveOnOptionsArray =  [
    {name: 'Date of Event', code: 'date_of_event'},
    {name: 'First of Next Month', code: 'first_of_next_month'},
    {name: 'First of Month', code: 'first_of_month'},
    {name: 'First Fixed of Next Month', code: 'fixed_first_of_next_month'},
    {name: 'Next 15 of the month', code: ''}, // TBD
    {name: 'Exact Date', code: 'exact_date'},
    {name: 'Date options available', code: ''} // TBD
  ]
  
  public reasonList = [
    {name:"Not Applicable", code: "not_applicable"},
    {name:"Natural Disaster", code: "exceptional_circumstances_natural_disaster"},
    {name:"Medical Emergency", code: "exceptional_circumstances_medical_emergency"},
    {name:"System Outage", code: "exceptional_circumstances_system_outage"},
    {name:"Domestic Abuse", code: "exceptional_circumstances_domestic_abuse"},
    {name:"Civic Service",code: "exceptional_circumstances_civic_service"},
    {name:"Exceptional Circumstances", code: "exceptional_circumstances"}  
  ]
  
  @ViewChild('headerRef') headerRef: ElementRef;

  constructor(
     injector: Injector,
     private _elementRef : ElementRef,
     private _creationForm: FormBuilder,
     @Inject("QleKindCreationService") private CreationService : QleKindCreationService,
     ) {
     this.buildInitialForm(_creationForm);
  }

  private buildInitialForm(formBuilder : FormBuilder) {
    var qControls = formBuilder.array([]);
    var formGroup = formBuilder.group({
      title: ['', Validators.required],
      tool_tip: ['', [Validators.required, Validators.minLength(1)]],
      action_kind: ['not_applicable'],
      reason: ['not_applicable'],
      market_kind: ['', [Validators.required, Validators.minLength(1)]],
      is_self_attested: [''],
      visible_to_customer: [''],
      effective_on_kinds:  new FormArray([]),
      custom_qle_questions: qControls,
      pre_event_sep_in_days:[0, Validators.required],
      post_event_sep_in_days:[0, Validators.required],
      start_on: [''],   
      end_on: ['']
    });
    this.creationFormGroup = formGroup;
    this.questionArray = qControls;
    this.addCheckboxes();

  }

  private addCheckboxes() {
    this.effectiveOnOptionsArray.map((o, i) => {
      const control = new FormControl(i === 0); // if first item set to true, else false
      (this.creationFormGroup.controls.effective_on_kinds as FormArray).push(control);
    });
  }

  public getOptions(){
    return this.effectiveOnOptionsArray
  }

  public questionControls() : FormGroup[] {
    return this.questionArray.controls.map(
      function(item) {
        return <FormGroup>item;
      }
    );
  }

  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }
  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  ngOnInit() {
    var submissionUriAttribute = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-create-url");
    if (submissionUriAttribute != null) {
      this.creationUri = submissionUriAttribute;
    }
    var marketKindsAttribute = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-market-kinds");
    if (marketKindsAttribute != null) {
      var marketKindsArrayJson = JSON.parse(marketKindsAttribute)
      this.marketKindsList = marketKindsArrayJson;
    }
  }

  addQuestion() {
    this.questionArray.push(
      QleKindQuestionFormComponent.newQuestionFormGroup(this._creationForm)
    );
  }

  removeQuestion(questionIndex: number) {
    this.questionArray.removeAt(questionIndex);
  }

  showQuestions(){
    return this.questionArray.length > 0;
  }

  submitCreation() {
    var form = this;
    var errorMapper = new ErrorMapper();
    if (this.creationFormGroup != null) {
      if (this.creationUri != null) {  
        console.log(this.creationFormGroup.value);
        var invocation = this.CreationService.submitCreate(this.creationUri, <QleKindCreationRequest>this.creationFormGroup.value);
        invocation.subscribe(
          function(data: HttpResponse<any>) {
            var location_header = data.body.next_url;
            if (location_header != null) {
              window.location.href = location_header;
            }
          },
        )
      }
    }
  }
}
