import { QleKindDeactivationFormComponent } from "./qle_kind_deactivation_form.component";
import { ElementRef, Injector, InjectionToken, Type, InjectFlags } from '@angular/core';
import { Observable } from "rxjs";
import { HttpResponse } from '@angular/common/http';

class MockInjector extends Injector {
   get<T>(token: Type<T> | InjectionToken<T>, notFoundValue?: T, flags?: InjectFlags): T {
     return notFoundValue;
   }
}

class MockElementRef extends ElementRef {

}

class MockDeactivationService {
  public submitDeactivate(post_uri: string, obj_data : object) : Observable<HttpResponse<any>> {
    return null;
  };
}

describe('QleKindDeactivationFormComponent', () => {
  it("is created successfully", () => {
    var component = new QleKindDeactivationFormComponent(
      new MockInjector(),
      new MockDeactivationService(),
      null,
      new MockElementRef(null));
  });

  it("initializes successfully", () => {
    var qle_kind_item = {

    };
    var deactivation_uri = "SOME RANDOM URI";
    var qleKindToDeactivateJson = JSON.stringify(qle_kind_item);
    var myElement = {
      getAttribute(a_name: String) : String | null {
        if (a_name == "data-qle-kind-to-deactivate") {
          return qleKindToDeactivateJson;
        } else if (a_name == "data-qle-kind-deactivate-url") {
          return deactivation_uri;
        } else {
          return null;
        }
      }
    };
    var component = new QleKindDeactivationFormComponent(
      new MockInjector(),
      new MockDeactivationService(),
      null,
      new MockElementRef(myElement));
    component.ngOnInit();
    expect(component.deactivationFormGroup).not.toBe(null);
    expect(component.deactivationUri).toEqual(deactivation_uri);
  });
});
