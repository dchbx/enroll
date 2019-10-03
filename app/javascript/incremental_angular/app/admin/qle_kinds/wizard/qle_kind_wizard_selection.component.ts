import { Component, Input, ViewChild, ElementRef } from '@angular/core';
import { CategorizedDropdownOption } from '../../../dropdown_option';

@Component({
  selector: 'qle-kind-wizard-selection',
  templateUrl: './qle_kind_wizard_selection.component.html'
})
export class QleKindWizardSelectionComponent {
  @Input("selectionList")
  public selectionList : Array<CategorizedDropdownOption> = [];
  
  @Input("isVisible")
  public isVisible : boolean = false;

  @ViewChild('kindSelection') kindSelection : ElementRef | null;

  public selectedCategory : string | null;
  
  public filteredItems: Array<CategorizedDropdownOption> = [];

  constructor() {

  }

  categories() {
    return this.selectionList.map(function(item) {
      return item.category;
    }).filter(function(value, index, self) {
      return self.indexOf(value) === index;
    }).sort();
  }

  filterItems(cat: string) : Array<CategorizedDropdownOption> {
    if (!this.categorySelected()) {
      return [];
    }
    var fItems = this.selectionList.filter(function(item) {
      return item.category == cat;
    });
    return fItems;
  }

  categorySelected() {
    return this.selectedCategory != null;
  }

  selectCategory(cat: string) {
    this.selectedCategory = cat;
    this.filteredItems = this.filterItems(cat);
  }

  getSelection() : string | null {
    if (this.kindSelection != null) {
      if (this.kindSelection.nativeElement != null) {
        var selectedQle = this.kindSelection.nativeElement.value;
        return selectedQle;
      }
    }
    return null;
  }

  showSelection() {
    return this.categorySelected() && this.isVisible;
  }
}