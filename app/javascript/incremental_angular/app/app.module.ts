import { BrowserModule } from '@angular/platform-browser';
import { NgModule, Injector } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { createCustomElement } from '@angular/elements';
import { HttpClientModule } from '@angular/common/http';
import { NgxMaskModule } from 'ngx-mask'
export const options = {};


import { DragDropModule } from '@angular/cdk/drag-drop'
import { BrokerAgencyProfileCreateComponent } from './broker_agency_profile/broker_agency_profile_create.component';
import { TrustedHtmlPipe } from './trusted_html_pipe';
import { PhoneComponent } from './contact_information/phone.component';
import { OfficeLocationComponent } from './office_locations/office_location.component';
import { AchInformationComponent } from './financial/ach_information.component';
import { BrokerAgencyProfileResourceService } from './broker_agency_profile/broker_agency_profile_resource.service'
import { FieldErrorsComponent } from './errors/field_errors.component';
import { QleKindWizardComponent } from  './admin/qle_kinds/qle_kind_wizard.component';
import { QleKindDeactivationFormComponent } from  './admin/qle_kinds/qle_kind_deactivation_form.component';
import { QleKindResourceService } from  './admin/qle_kinds/qle_kind_resource.service';
import { QleKindEditFormComponent } from './admin/qle_kinds/edit/qle_kind_edit_form.component';
import { QleKindCreationFormComponent } from  './admin/qle_kinds/new/qle_kind_creation_form.component';
import { QleKindQuestionFormComponent } from './admin/qle_kinds/new/qle_kind_question_form.component';
import { QleKindWizardSelectionComponent } from './admin/qle_kinds/wizard/qle_kind_wizard_selection.component';
import { QleKindResponseFormComponent } from './admin/qle_kinds/new/qle_kind_question_response_form.component';
import { QleKindSortingOrderFormComponent } from './admin/qle_kinds/sorting_order/qle_kind_sorting_order_form.component';

import { ErrorLocalizer } from './error_localizer';

@NgModule({
  declarations: [
    AchInformationComponent,
    BrokerAgencyProfileCreateComponent,
    FieldErrorsComponent,
    QleKindCreationFormComponent,
    QleKindSortingOrderFormComponent,
    QleKindResponseFormComponent,
    PhoneComponent,
    OfficeLocationComponent,
    QleKindWizardComponent,
    TrustedHtmlPipe,
    QleKindQuestionFormComponent,
    QleKindDeactivationFormComponent,
    QleKindWizardSelectionComponent,
    QleKindEditFormComponent
  ],
  entryComponents: [
    BrokerAgencyProfileCreateComponent,
    QleKindCreationFormComponent,
    QleKindEditFormComponent,
    QleKindSortingOrderFormComponent,
    QleKindResponseFormComponent,
    QleKindWizardComponent,
    QleKindQuestionFormComponent,
    QleKindDeactivationFormComponent
  ],
  imports: [
    BrowserModule,
    HttpClientModule,
    FormsModule,
    ReactiveFormsModule,
    DragDropModule,
    NgxMaskModule.forRoot(options)
  ],
  providers: 
  [
    BrokerAgencyProfileResourceService.provides('BrokerAgencyProfileCreationService'),
    QleKindResourceService.provides("QleKindDeactivationService"),
    QleKindResourceService.provides("QleKindCreationService"),
    QleKindResourceService.provides("QleKindEditService"),
    QleKindResourceService.provides("QleKindSortingOrderService"),
    ErrorLocalizer
  ]
})
export class AppModule {
  constructor(private injector: Injector) {
  }
  ngDoBootstrap() {
    const bapc_custom = createCustomElement(BrokerAgencyProfileCreateComponent, {injector: this.injector });
    customElements.define("broker-agency-profile-create",bapc_custom);
    const qlewk_custom = createCustomElement(QleKindWizardComponent, {injector: this.injector });
    customElements.define("admin-qle-management-wizard",qlewk_custom);
    // Deactivation
    const qle_kind_deactivation_form_custom = createCustomElement(QleKindDeactivationFormComponent, { injector: this.injector });
    customElements.define("admin-qle-kind-deactivation-form",qle_kind_deactivation_form_custom);
    // Creation
    const qle_kind_creation_form_custom = createCustomElement(QleKindCreationFormComponent, { injector: this.injector });
    customElements.define("admin-qle-kind-creation-form",qle_kind_creation_form_custom);
    // Edit
    const qle_kind_edit_form_custom = createCustomElement(QleKindEditFormComponent, { injector: this.injector });
    customElements.define("admin-qle-kind-edit-form", qle_kind_edit_form_custom);
    // Sorting Order
    const qle_kind_sorting_order_form_custom = createCustomElement(QleKindSortingOrderFormComponent, { injector: this.injector });
    customElements.define("admin-qle-kind-sorting-order-form", qle_kind_sorting_order_form_custom);
  }
}