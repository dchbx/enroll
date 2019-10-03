import { QleKindWizardSelectionComponent } from "./qle_kind_wizard_selection.component";
import { ElementRef, Injector, InjectionToken, Type, InjectFlags } from '@angular/core';

class MockInjector extends Injector {
   get<T>(token: Type<T> | InjectionToken<T>, notFoundValue?: T, flags?: InjectFlags): T {
     return notFoundValue;
   }
}

class MockElementRef extends ElementRef {

}

describe('QleKindWizardSelectionComponent', () => {
  it("is created successfully", () => {
    var component = new QleKindWizardSelectionComponent();
  });
});
