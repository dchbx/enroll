import { Component, Input } from '@angular/core';
import { FormGroup, FormControl, FormArray, AbstractControl, Validators } from '@angular/forms';
import { ResponseComponentRemover } from './response_component_remover';
import { QleKindQuestionFormComponent } from './qle_kind_question_form.component';


@Component({
  selector: 'qle-question-response-form',
  templateUrl: './qle_kind_question_response_form.component.html'
})

export class QleKindResponseFormComponent {
  public showAddAnotherResponse : boolean = false;

  @Input("responseFormGroup")
  public responseFormGroup : FormGroup | null;

  @Input("responseIndex")
  public responseIndex : number | null;

  @Input("responseComponentParent")
  public responseComponentParent : ResponseComponentRemover | null;

  constructor() {
  }

  ngOnInit(){

  }

  public showIndex() {
    return this.responseIndex;
  }

  public removeResponse(responseIndex: number) {
    if (this.responseComponentParent != null) {
      if (responseIndex != null) {
        this.responseComponentParent.removeResponse(responseIndex);
      }
    }
  }

  public addNewResponse(questionComponent: ResponseComponentRemover, responseIndex: number){
    if (questionComponent != null) {
      if (questionComponent.questionFormGroup != null) {
        if (this.responseFormGroup != null) {
          questionComponent.questionFormGroup.value.responses[responseIndex] = this.responseFormGroup.value
   
        }     
      }
    }
  }

  public selectResponse(){
    if (this.responseFormGroup != null) {
      console.log(this.responseFormGroup.parent.value)
    }
  }

  public createResponse(){
    if(this.responseFormGroup != null){
      this.showAddAnotherResponse = true
    }
  }
  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }
  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  public static newResponseFormGroup() : FormGroup {
    var responseForm = new FormGroup({
      content: new FormControl('', Validators.required),
      action_to_take: new FormControl('select'),
    });
    return responseForm;
  }

  public static editResponseFormGroup(response:any) : FormGroup {
    var responseForm = new FormGroup({
      content: new FormControl(response.content, Validators.required),
      action_to_take: new FormControl(response.action_to_take),
    });
    return responseForm;
  }
  // public static editResponseFormGroups(responses:Array<string>) : FormArray[] {
  //   //  return new FormArray([])

  // }

}
