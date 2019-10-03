import { QleKindWizardComponent } from "./qle_kind_wizard.component";
import { ElementRef, Injector, InjectionToken, Type, InjectFlags } from '@angular/core';

class MockInjector extends Injector {
   get<T>(token: Type<T> | InjectionToken<T>, notFoundValue?: T, flags?: InjectFlags): T {
     return notFoundValue;
   }
}

class MockElementRef extends ElementRef {

}

describe('QleKindWizardComponent', () => {
  it("is created successfully", () => {
    var component = new QleKindWizardComponent(new MockInjector(), new MockElementRef(null));
  });

  it("initializes successfully", () => {
    var element = {
      getAttribute: function(st: String) {
        return null;
      }
    };
    var component = new QleKindWizardComponent(new MockInjector(), new MockElementRef(element));
    component.ngOnInit();
  })

  it("properly sets attributes from the source element", () => {
    var newLocation = "/some/new/location";
    var editables = [
      {
        label: "Editable Label",
        category: "shop",
        value: "Editable Value"
      }
    ];
    var deactivatables = [
      {
        label: "Deactivatable Label",
        category: "shop",
        value: "Deactivatable Value"
      }
    ];
    var element = {
      getAttribute: function(st: String) {
        if (st == "data-new-location") {
          return newLocation;
        } else if (st == "data-editable-list") {
          return JSON.stringify(editables);
        } else if (st == "data-deactivatable-list") {
          return JSON.stringify(deactivatables);
        }
        return null;
      }
    };
    var component = new QleKindWizardComponent(new MockInjector(), new MockElementRef(element));
    component.ngOnInit();

    expect(component.newLocation).toEqual(newLocation);
    expect(component.editableList).toEqual(editables);
    // expect(component.createableList).toEqual(createables);
    expect(component.deactivatableList).toEqual(deactivatables);
  })
});