import { QleKindQuestionFormComponent } from "./qle_kind_question_form.component";
import { ElementRef, Injector, InjectionToken, Type, InjectFlags } from '@angular/core';
import { FormGroup, FormControl, AbstractControl, FormArray, FormBuilder, Validators } from '@angular/forms';

describe('QleKindQuestionFormComponent', () => {
  it("is created successfully", () => {
    var component = new QleKindQuestionFormComponent(
      new FormBuilder()
    )
  });

  it("is successfully adds response", () => {
    var form_builder = new FormBuilder();
    var component = new QleKindQuestionFormComponent(
      form_builder
    )
    component.questionFormGroup = QleKindQuestionFormComponent.newQuestionFormGroup(form_builder);
    component.addResponse();
    component.getResponseArray();
  });
});
