import { Component, Injector, ElementRef, Inject, ViewChild  } from '@angular/core';
import { QleKindSortingOrderResource } from './qle_kind_sorting_order_data';
import { FormGroup, FormControl, AbstractControl, FormArray, FormBuilder, Validators } from '@angular/forms';
// import { ErrorLocalizer } from '../../../error_localizer';
// import { ErrorMapper, ErrorResponse } from '../../../error_mapper';
import {CdkDragDrop, moveItemInArray} from '@angular/cdk/drag-drop';
// import { __core_private_testing_placeholder__ } from '@angular/core/testing';
import { QleKindSortingOrderService } from '../qle_kind_services';
import { HttpResponse } from "@angular/common/http";

@Component({
  selector: 'admin-qle-kind-sorting-order-form',
  templateUrl: 'qle_kind_sorting_order_form.component.html',
  //styleUrls: ['qle_kind_sorting_order_form.component.css'],
})
export class QleKindSortingOrderFormComponent {
  public qleKindToSortingOrder : QleKindSortingOrderResource | null = null;
  public sortingOrderUri : string | null = null;
  public sortingOrderFormGroup : FormGroup;
  public marketKindsList : Array<string> | null = null;
  @ViewChild('headerRef') headerRef: ElementRef;
  constructor(
    injector: Injector,
    // private errorLocalizer: ErrorLocalizer,
    private _sortingOrderForm: FormBuilder,
    private _elementRef : ElementRef,
    @Inject("QleKindSortingOrderService") private SortingOrderService : QleKindSortingOrderService,
    ) {
    this.buildInitialForm(_sortingOrderForm);
  }
  private buildInitialForm(formBuilder : FormBuilder) {
  }

  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }

  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  movies = [
    'Episode I - The Phantom Menace',
    'Episode II - Attack of the Clones',
    'Episode III - Revenge of the Sith',
    'Episode IV - A New Hope',
    'Episode V - The Empire Strikes Back',
    'Episode VI - Return of the Jedi',
    'Episode VII - The Force Awakens',
    'Episode VIII - The Last Jedi'
  ];

  drop(event: CdkDragDrop<string[]>) {
   moveItemInArray(this.movies, event.previousIndex, event.currentIndex);
  }
  ngOnInit() {
    var submissionUriAttribute = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-sorting-order-url");
    if (submissionUriAttribute != null) {
      this.sortingOrderUri = submissionUriAttribute;
    }
  }

  submitSorting() {
    var form = this;
    // var errorMapper = new ErrorMapper();

    if (this.sortingOrderFormGroup != null) {
      if (this.sortingOrderUri != null) {
        var invocation = this.SortingOrderService.submitSortingOrder(this.sortingOrderUri, this.sortingOrderFormGroup.value);
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

