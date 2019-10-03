import { FormGroup, FormControl, AbstractControl, FormArray, FormBuilder, Validators } from '@angular/forms';

export interface ResponseComponentRemover {

  questionFormGroup : FormGroup

  removeResponse(responseIndex: number) : void;
}