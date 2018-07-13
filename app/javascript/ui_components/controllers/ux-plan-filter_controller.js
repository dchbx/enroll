import { Controller } from "stimulus"

export default class extends Controller {
  
  initialize() {
    let filteredDiv = document.querySelector('#filteredPlans');
    filteredDiv.classList.add('hidden')
  }
  
  sortPlans() {
    let plansDiv = document.querySelector('#plans');
    let filteredDiv = document.querySelector('#filteredPlans');
    let avalilablePlans = JSON.parse(filteredDiv.dataset.members);
    let avalilableEnrollments = JSON.parse(filteredDiv.dataset.groupEnrollment);
    let avalilableProducts = JSON.parse(filteredDiv.dataset.availableProduct);
    let avalilableCarriers = JSON.parse(filteredDiv.dataset.planCarrier);
    
    let sortBy = event.target.dataset.sortBy;
    
    plansDiv.classList.add('hidden');
    filteredDiv.classList.remove('hidden')
    
    this.showFilteredPlans(sortBy,avalilablePlans,avalilableEnrollments,avalilableProducts, avalilableCarriers)
  }
  
  showFilteredPlans(sortBy,avalilablePlans,enrollments,products, avalilableCarriers) {
    //console.log(sortBy)
    var productArray = new Array;
    let title = document.getElementById('planTitleShell');
    
    if (sortBy = "plan-name") {
      
      products.forEach(function(product){productArray.push(product)})
      productArray.sort(function(a,b) {
        let titleA = JSON.parse(a).title.toLowerCase();
        let titleB = JSON.parse(b).title.toLowerCase();
        if (titleA < titleB) //sort string ascending
          return -1
        if (titleA > titleB)
          return 1
        return 0 //default return value (no sorting)*/
      })
      
      productArray.map((p)=> {
        
        title.innerHTML = JSON.parse(p).title;
      });

    }
    
    
    
  }

}
