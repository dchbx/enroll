import { Component, Injector, ElementRef, Inject, ViewChild } from '@angular/core';
import { QleKindDeactivationResource } from './qle_kind_deactivation_data';
import { FormGroup, FormControl, AbstractControl, Validators } from '@angular/forms';
import { QleKindDeactivationService } from './qle_kind_services';
import { ErrorLocalizer } from '../../error_localizer';
import { ErrorMapper, ErrorResponse } from '../../error_mapper';
import { HttpResponse } from "@angular/common/http";

@Component({
  selector: 'admin-qle-kind-deactivation-form',
  templateUrl: './qle_kind_deactivation_form.component.html'
})
export class QleKindDeactivationFormComponent {
  public qleKindToDeactivate : QleKindDeactivationResource | null = null;
  public deactivationUri : string | null = null;
  public deactivationFormGroup : FormGroup = new FormGroup({});
  @ViewChild('headerRef') headerRef: ElementRef;

  constructor(
    injector: Injector,
    @Inject("QleKindDeactivationService") private deactivationService : QleKindDeactivationService,
    private errorLocalizer: ErrorLocalizer,
    private _elementRef : ElementRef) {
  }

  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }

  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  ngOnInit() {
    var qleKindToDeactivateJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-to-deactivate");
    if (qleKindToDeactivateJson != null) {
      this.qleKindToDeactivate = JSON.parse(qleKindToDeactivateJson)
      if (this.qleKindToDeactivate != null) {
        this.deactivationFormGroup.addControl(
          "_id",
          new FormControl(this.qleKindToDeactivate._id),
        )
        this.deactivationFormGroup.addControl(
          "end_on",
          new FormControl(""),
        )
      }
    }
    var submissionUriAttribute = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-deactivate-url");
    if (submissionUriAttribute != null) {
      this.deactivationUri = submissionUriAttribute;
    }
  }

  hasResource() {
    return this.qleKindToDeactivate != null;
  }

  submitDeactivation() {
    var form = this;
    var errorMapper = new ErrorMapper();
    if (this.deactivationFormGroup.valid) {
      if (this.deactivationUri != null) {
        var invocation = this.deactivationService.submitDeactivate(this.deactivationUri, this.deactivationFormGroup.value);
        invocation.subscribe(
          function(data: HttpResponse<any>) {
            var location_header = data.headers.get("Location");
            if (location_header != null) {
              // TODO: Can we add a div append here to show the success or decline message
              // or should we add a new function?
              window.location.href = location_header;
            }
          },
          function(error) {
            errorMapper.mapParentErrors(form.deactivationFormGroup, <ErrorResponse>(error.error.errors));
            errorMapper.processErrors(form.deactivationFormGroup, <ErrorResponse>(error.error.errors));
            form.headerRef.nativeElement.scrollIntoView();
          }
        )
      }
    } else {
        errorMapper.cascadeTouch(this.deactivationFormGroup);
        errorMapper.invalidParentForm(this.deactivationFormGroup);
        form.headerRef.nativeElement.scrollIntoView();
    }
  }
}
