import "core-js/";
import { calculateEmployerContributions, calculateEmployeeCosts } from "./benefit_application";

function enableNewAddBenefitPackageButton() {
  var addBenefitPackageButton = document.getElementById('addBenefitPackage');
  if (addBenefitPackageButton)
    addBenefitPackageButton.classList.remove('disabled');
}

function disableNewAddBenefitPackageButton() {
  var addBenefitPackageButton = document.getElementById('addBenefitPackage');
  if (addBenefitPackageButton)
    addBenefitPackageButton.classList.add('disabled');
}

function disableDentalBenefitPackage() {
  var addBenefitPackageButton = document.getElementById('dentalBenefits');
  if (addBenefitPackageButton)
    addBenefitPackageButton.classList.add('disabled');
}

function enableDentalBenefitPackage() {
  var addBenefitPackageButton = document.getElementById('dentalBenefits');
  if (addBenefitPackageButton)
    addBenefitPackageButton.classList.remove('disabled');
}

function preventSubmissionOnEnter() {
  var newBenefitPackageSubmit = document.getElementById('new_benefit_package') || document.getElementById('new_sponsored_benefits');
  newBenefitPackageSubmit.onkeypress = function(e) {
    var key = e.charCode || e.keyCode || 0;
    if (key == 13)
      e.preventDefault();
  }
}

function disableNewPlanYearButton() {
  var savePlanYearButton = document.getElementById('submitBenefitPackage') || document.getElementById('submitDentalBenefits');
  savePlanYearButton.classList.add('disabled');

  disableNewAddBenefitPackageButton();
  disableDentalBenefitPackage();
  preventSubmissionOnEnter();
}

function enableNewPlanYearButton() {
  var savePlanYearButton = document.getElementById('submitBenefitPackage') || document.getElementById('submitDentalBenefits');
  savePlanYearButton.classList.remove('disabled');
  enableNewAddBenefitPackageButton();
  enableDentalBenefitPackage();
}

function disableEmployeeContributionLevel(){
  var elements = document.querySelectorAll(".contribution_handler");
  for (var i = 0; i < elements.length; i++) {
    var element = elements[i];
    if(element.dataset.displayname == 'Employee' || element.dataset.displayname == "Employee Only" ) {
      element.parentElement.getElementsByTagName('span')[0].classList.add("blocking");
    }
  }
}

function setCircle(element) {
  var items = document.querySelectorAll('#metal-level-select ul li');

  for (var i = 0; i < items.length; i++) {
    var li = items[i];
    li.querySelector('i').classList.remove('fa-dot-circle');
  }
  // Sets radio icon to selected
  window.setTimeout(function() {
    if (element.classList.contains('active')) {
      element.querySelector('i').classList.add('fa-dot-circle');
    }
  },200);

  // Gets product option info
  window.productOptionKind = element.querySelector('a').dataset.name;
  // Sets kind to hidden input field for form submission
  var ppKind;
  if (ppKind = document.getElementById('ppKind'))
    ppKind.setAttribute('value', window.productOptionKind);

  document.getElementById('referencePlans').classList.add('hidden');
}

function showFormButtons() {
  var addBenefitPackage = document.getElementById('addBenefitPackage')
  if (addBenefitPackage)
    addBenefitPackage.classList.remove('hidden');
  var dentalBenefits = document.getElementById('dentalBenefits');
  if(dentalBenefits) {
    dentalBenefits.classList.remove('hidden');
  }
  var submitButton = document.getElementById('submitBenefitPackage') || document.getElementById('submitDentalBenefits');
  submitButton.classList.remove('hidden');
  var cancelButton = document.getElementById('cancelBenefitPackage') || document.querySelector('form .interaction-click-control-cancel');
  cancelButton.classList.remove('hidden');
}

function viewSummary(element) {
  window.selectedSummaryTitle = element.dataset.planTitle;
  window.selectedReferencePlanID = element.dataset.planId;
  document.getElementById('viewSummaryTitle').innerHTML = window.selectedSummaryTitle;
  var query_address = '/benefit_sponsors/benefit_sponsorships/'+window.selectedBenefitSponsorsID+'/benefit_applications/'+window.selectedBenefitApplicationID+'/benefit_packages/reference_product_summary?reference_plan_id='+window.selectedReferencePlanID;
  fetch(query_address)
    .then(function(res) { return res.json() })
    .then(function(data) {
      data[1].map(function(s) {
        document.getElementById('sbcLink').setAttribute('href', data[2]);
        var tr = document.createElement('tr');
        var tbody = document.getElementById('modalSummaryData');
        tr.innerHTML = '<td style="background-color:#f5f5f5">' + s.visit_type + '</td><td>' + s.copay_in_network_tier_1 + '</td><td>' + s.co_insurance_in_network_tier_1 + '</td>';
        tbody.insertBefore(tr, tbody.children[-1] || null);
      });
    })
    .then(window.$('#viewSummaryModal').modal('show'));
    window.showLess = false;
}

function showMoreDetails() {
  if (window.showLess) {
    document.getElementById('modalSummaryData').innerHTML = '';
    fetch('/benefit_sponsors/benefit_sponsorships/'+window.selectedBenefitSponsorsID+'/benefit_applications/'+window.selectedBenefitApplicationID+'/benefit_packages/reference_product_summary?reference_plan_id='+window.selectedReferencePlanID)
      .then(function(res) { return res.json() })
      .then(function(data) {
        data[1].map(function(s) {
          document.getElementById('sbcLink').setAttribute('href', data[2]);
          var tr = document.createElement('tr');
          var tbody = document.getElementById('modalSummaryData');
          tr.innerHTML = '<td style="background-color:#f5f5f5">' + s.visit_type + '</td><td>' + s.copay_in_network_tier_1 + '</td><td>' + s.co_insurance_in_network_tier_1 + '</td>';
          tbody.insertBefore(tr, tbody.children[-1] || null);
        });
      })
      .then(document.getElementById('btnMoreDetails').innerHTML = "More Details");
      window.showLess = false;
  } else {
    fetch('/benefit_sponsors/benefit_sponsorships/' + window.selectedBenefitSponsorsID + '/benefit_applications/' + window.selectedBenefitApplicationID + '/benefit_packages/reference_product_summary?reference_plan_id=' + window.selectedReferencePlanID + '&details=details')
      .then(function(res) { return res.json() })
      .then(function(data) {
        data[1].map(function(s) {
          var tr = document.createElement('tr');
          var tbody = document.getElementById('modalSummaryData');
          tr.innerHTML = '<td style="background-color:#f5f5f5">' + s.visit_type + '</td><td>' + s.copay_in_network_tier_1 + '</td><td>' + s.co_insurance_in_network_tier_1 + '</td>';
          tbody.insertBefore(tr, tbody.children[-1] || null);
        });
      })
      .then(document.getElementById('btnMoreDetails').innerHTML = "Fewer Details");
      window.showLess = true;
  }
}

function displayReferencePlanDetails(element, options) {
  if(!(element || options)) {
    return;
  }

  options = options || {};
  var planTitle = options.planTitle || element.dataset.planTitle;
  var metalLevel = options.metalLevel || element.dataset.planMetalLevel;
  var carrierName = options.carrierName || element.dataset.planCarrier;
  var planType = options.planType || element.dataset.planType;
  var network = options.network || element.dataset.network;
  var referencePlanID = options.referencePlanID || element.id;
  var sponsoredBenefitId = options.sponsoredBenefitId;
  showFormButtons();

  document.getElementById('yourReferencePlanDetails').innerHTML = window.MetalLevelSelect_ReferencePlanDetailsShell;

  document.getElementById('referencePlanTitle').innerHTML = planTitle;
  document.getElementById('rpType').innerHTML = planType;
  document.getElementById('rpCarrier').innerHTML = carrierName;
  document.getElementById('rpMetalLevel').innerHTML = metalLevel;
  document.getElementById('rpNetwork').innerHTML = network;
  document.getElementById('planOfferingsTitle').innerHTML = '';
  document.getElementById('planOfferingsTitle').innerHTML = 'Plan Offerings - ' + planTitle + '(' + window.productsTotal + ')';
  if (document.querySelector('input#sponsored_benefits_kind')) {
    calculateEmployerContributions(window.productOptionKind, referencePlanID, sponsoredBenefitId, "sponsored_benefits")
    calculateEmployeeCosts(window.productOptionKind, referencePlanID, sponsoredBenefitId, "sponsored_benefits")
  } else {
    calculateEmployerContributions(window.productOptionKind, referencePlanID, sponsoredBenefitId);
    calculateEmployeeCosts(window.productOptionKind, referencePlanID, sponsoredBenefitId);
  }
}

function radioSelected(element) {
  setCircle(element);
  disableNewPlanYearButton();
  // Store radio title to localStorage
  window.selectedTitle = element.querySelector('a').innerText;
  localStorage.setItem("title",window.selectedTitle);
}

// Mouse event needed to enable tooltips css on pageload
function selectDefaultReferencePlan() {
  var input = document.querySelectorAll('.reference-plans')[0].querySelector('input');
  input.click();
  var myplans = document.querySelector('#yourPlans');
  myplans.onmouseover = function() {
    myplans.click();
    var form = document.getElementById('new_benefit_package') || document.getElementById('new_sponsored_benefits');
    form.click();
  };
  var contributions = document.querySelector('#yourSponsorContributions');
  contributions.onmouseover = function() {
    contributions.click();
    var form = document.getElementById('new_benefit_package') || document.getElementById('new_sponsored_benefits');
    form.click();
  };
}

function setTempCL() {
  var myLevels = localStorage.getItem("contributionLevels");
  window.selectedTitle = localStorage.getItem("title");

  if (myLevels) {
    var contributions = {};
    if (myLevels)
      contributions = JSON.parse(myLevels);
    else
      contributions = window.tempContributionValues;

    window.setTimeout(function() {
      var employee = document.querySelectorAll("[data-displayname='Employee']");
      var spouse = document.querySelectorAll("[data-displayname='Spouse']");
      var domesticPartner = document.querySelectorAll("[data-displayname='Domestic Partner']");
      var childUnder26 = document.querySelectorAll("[data-displayname='Child Under 26']");
      var employeeOnly = document.querySelectorAll("[data-displayname='Employee Only']");
      var family = document.querySelectorAll("[data-displayname='Family']");

      if (window.selectedTitle == "ONE CARRIER") {
        employee[1].value = contributions.eeContribution;
        employee[2].value = contributions.eeContribution;
        spouse[1].value = contributions.spouse;
        spouse[2].value = contributions.spouse;
        domesticPartner[1].value = contributions.domesticPartner;
        domesticPartner[2].value = contributions.domesticPartner;
        childUnder26[1].value = contributions.childUnder26;
        childUnder26[2].value = contributions.childUnder26;
      }

      if (window.selectedTitle == "ONE LEVEL") {
        employee[1].value = contributions.eeContribution;
        employee[2].value = contributions.eeContribution;
        spouse[1].value = contributions.spouse;
        spouse[2].value = contributions.spouse;
        domesticPartner[1].value = contributions.domesticPartner;
        domesticPartner[2].value = contributions.domesticPartner;
        childUnder26[1].value = contributions.childUnder26;
        childUnder26[2].value = contributions.childUnder26;
      }

      if (window.selectedTitle == "ONE PLAN") {
        employeeOnly[1].value = contributions.employeeOnly;
        employeeOnly[2].value = contributions.employeeOnly;
        family[1].value = contributions.familyOnly;
        family[2].value = contributions.familyOnly;
      }

    },500);
  }
}

function newContributionAmounts() {
  var contributionInputs = document.querySelectorAll("[data-contribution-input='true']");
  var contributionHandlers = document.querySelectorAll(".contribution_handler");

  for (var i = 0; i < contributionInputs.length; i++) {
    var element = contributionInputs[i];
    switch (element.dataset.displayname) {
      case 'Employee':
        window.eeContribution = element.value;
        if (window.eeContribution > 0) {
          window.tempContributionValues.eeContribution = parseInt (window.eeContribution);
        }
      break;
      case 'Spouse':
        window.spouse = element.value;
        if (window.spouse > 0) {
          window.tempContributionValues.spouse = parseInt (window.spouse);
        }
      break;
      case 'Domestic Partner':
        window.domesticPartner = element.value;
        if (window.domesticPartner > 0) {
          window.tempContributionValues.domesticPartner = parseInt (window.domesticPartner);
        }
      break;
      case 'Child Under 26':
        window.childUnder26 = element.value;
        if (window.childUnder26 > 0) {
          window.tempContributionValues.childUnder26 = parseInt (window.childUnder26);
        }
      break;
      case 'Employee Only':
        window.employeeOnly = element.value;
        if (window.employeeOnly) {
          window.tempContributionValues.employeeOnly = parseInt (window.employeeOnly);
        }
      break;
      case 'Family':
        window.familyOnly = element.value;
        if (familyOnly > 0) {
          window.tempContributionValues.familyOnly = parseInt (window.familyOnly);
        }
      break;
    }

    var tempLevels = JSON.stringify(window.tempContributionValues);
    localStorage.setItem("contributionLevels",tempLevels);
  }

  for (i = 0; i < contributionHandlers.length; i++) {
    element = contributionHandlers[i];
    switch (element.dataset.displayname) {
      case 'Employee':
        if(!(element.checked)) {
          window.eeContribution = 100;
        }
      break;
      case 'Spouse':
        if(!(element.checked)) {
          window.spouse = 100;
        }
      break;
      case 'Domestic Partner':
        if(!(element.checked)) {
          window.domesticPartner = 100;
        }
      break;
      case 'Child Under 26':
        if(!(element.checked)) {
          window.childUnder26 = 100;
        }
      break;
      case 'Employee Only':
        if(!(element.checked)) {
          window.employeeOnly = 100;
        }
      break;
      case 'Family':
        if(!(element.checked)) {
          window.familyOnly = 100;
        }
      break;
    }
  }
  if (document.querySelector('input#sponsored_benefits_kind')) {
    if($(".benefit-package-dental").length || $("#edit_dental_form").length) {
      var sbErCL = erDentalCL
    } else {
      var sbErCL = erCL
    }
    if (window.eeContribution < sbErCL) {
      disableNewPlanYearButton()
    } else if (window.spouse < familyCL || window.domesticPartner < familyCL || window.childUnder26 < familyCL) {
      disableNewPlanYearButton()
    } else if (!(document.querySelectorAll(".reference-plans input[type='radio']:checked").length)) {
      disableNewPlanYearButton()
    } else {
      enableNewPlanYearButton()
    }
    // }
    displayReferencePlanDetails(document.querySelector("input[name='sponsored_benefits[reference_plan_id]']:checked"));
  } else {
    if (!(document.querySelectorAll(".reference-plans input[type='radio']:checked").length)) {
      disableNewPlanYearButton();
    }
    else {
      if (applicationStartOn === "01-01") {
        enableNewPlanYearButton();
      } else {
        if (window.eeContribution < window.erCL || window.employeeOnly < window.erCL) {
          disableNewPlanYearButton();
        } else if (window.familyOnly < window.familyCL || window.spouse < window.familyCL || window.domesticPartner < window.familyCL || window.childUnder26 < window.familyCL) {
          disableNewPlanYearButton();
        }  else {
          enableNewPlanYearButton();
        }
      }
    }
    displayReferencePlanDetails(document.querySelector("input[name='benefit_package[sponsored_benefits_attributes][0][reference_plan_id]']:checked"));
  }
}

function setNumberInputValue(element) {
  document.getElementById(element.dataset.id).value = element.value;
  newContributionAmounts();
}

function setInputSliderValue(element) {
  document.querySelector("[data-id='"+element.id+"']").value = element.value;
  newContributionAmounts();
}

function buildSponsorContributions(contributions) {
  var element = document.getElementById('benefitFields');
  Array.from(element.children).forEach(function(child) { child.remove(); });

  var index = 0;
  for (var i = 0; i < contributions.length; i++) {
    var contribution = contributions[i];
    index += 1;
    var attrPrefix ;
    if (document.querySelector('input#sponsored_benefits_kind'))
      attrPrefix = 'sponsored_benefits[sponsor_contribution_attributes][contribution_levels_attributes][' + index + ']';
    else
      attrPrefix = 'benefit_package[sponsored_benefits_attributes][0][sponsor_contribution_attributes][contribution_levels_attributes][' + index + ']';
    var div = document.createElement('div');
    div.setAttribute('id', 'yourAvailableContributions');
    div.innerHTML =
    '<div class="row">\
      <input id="' + attrPrefix + '[id]" name="' + attrPrefix + '[id]" type="hidden" value="' + contribution['id'] + '" />\
      <input id="' + attrPrefix + '[contribution_unit_id]" name="' + attrPrefix + '[contribution_unit_id]" type="hidden" value="' + contribution['contribution_unit_id'] + '" />\
        <div class="col-xs-6 pr-3">\
          <div class="row sc-container">\
            <div class="col-xs-12 ml-2 mt-2">\
              <label class="container ml-1">' +contribution.display_name+'\
                <input type="checkbox" checked="checked" id="' + attrPrefix + '[is_offered]" class="contribution_handler" name="' + attrPrefix +'[is_offered]" value="' + contribution["is_offered"] +'" data-displayname="'+contribution.display_name+'" onchange="MetalLevelSelect.newContributionAmounts()"/>\
                <span class="checkmark"></span>\
              </label>\
            </div>\
          </div>\
        </div>\
        <div class="col-xs-6">\
          <div class="col-xs-3">\
            <input id="' + attrPrefix + '[display_name]" name="' + attrPrefix + '[display_name]" type="hidden" value="' + contribution["display_name"] + '" />\
            <input type="number" id="'+contribution.id+'" name="'+ attrPrefix +'[contribution_factor]" value="' + (contribution["contribution_factor"] * 100) + '" onchange="MetalLevelSelect.setInputSliderValue(this)" data-displayname="'+contribution.display_name+'" data-contribution-input="true">\
          </div>\
          <div class="col-xs-9">\
            <input type="range" min="0" max="100" value="' + (contribution["contribution_factor"] * 100) + '" step="5" class="slider" id="'+contribution.id+'" onchange="MetalLevelSelect.setNumberInputValue(this)" data-id="'+contribution.id+'" data-displayname="'+contribution.display_name+'">\
          </div>\
        </div>\
    </div>';
    element.insertBefore(div, element.children[-1] || null);
  }
}

function populateReferencePlans(plans) {
  window.sponsorContribution = window.sponsorContributions[window.productOptionKind]['contribution_levels'];

  document.getElementById('yourSponsorContributions').innerHTML = window.MetalLevelSelect_SponsorContributionsShell;

  // Replace below statement with plain Javascript
  window.$('[data-toggle="tooltip"]').tooltip();

  // Makes reference plans visible
  document.getElementById('referencePlans').classList.remove('hidden');
  // Removes reference plans if metal level changes
  var populatedReferencePlans = document.querySelectorAll("#yourAvailablePlans");

  if (populatedReferencePlans) {
    for (var i = 0; i < populatedReferencePlans.length; i++) {
      var rplans = populatedReferencePlans[i];
      rplans.remove();
    }
  }

  var referencePlanName;
  if (document.querySelector('input#sponsored_benefits_kind'))
    referencePlanName = "sponsored_benefits[reference_plan_id]";
  else
    referencePlanName = "benefit_package[sponsored_benefits_attributes][0][reference_plan_id]"

  // Build reference plans to be displayed in UI
  for (var i = 0; i < window.filteredProducts.length; i++) {
    var plan = window.filteredProducts[i];
    window.productsTotal = window.filteredProducts.length;
    var div = document.createElement('div');
    document.getElementById('yourPlanTotals').innerHTML = '<span class="pull-right mr-3">Displaying: <b>' + window.filteredProducts.length + ' plans</b></span>';
    div.setAttribute('id', 'yourAvailablePlans');
      var network = "";
      if (plan.network_information)
        network = 'NETWORK NOTES <a data-toggle="tooltip" data-placement="top" data-container="body" title="' + plan.network_information + '"><i class="fas fa-question-circle"></i></a>';
      div.innerHTML =
      '<div class="col-xs-4 reference-plans">' +
        '<div class="col-xs-12 p0 mb-1">' +
          '<label class="container">' +
            '<p class="heading-text reference-plan-title mb-1"> ' + plan.title + '</p>' +
            '<span class="plan-label">Type:</span> <span class="rp-plan-info">' + plan.product_type + '</span><br>' +
            '<span class="plan-label">Carrier:</span> <span class="rp-plan-info">' + plan.carrier_name + '</span><br>' +
            '<span class="plan-label">Level:</span> <span class="rp-plan-info">' + plan.metal_level_kind + '</span><br>' +
            '<span class="plan-label">Network:</span> <span class="rp-plan-info">' + plan.network + '</span><br>' +
            '<span class="plan-label mt-1" onclick="MetalLevelSelect.viewSummary(this)" data-plan-title="' + plan.title + '" data-plan-id="' + plan.id + '">View Summary</span><br>' +
            '<input type="radio" name="' + referencePlanName + '" id="' + plan.id + '" onclick="MetalLevelSelect.newContributionAmounts()" value="' + plan.id + '" data-plan-title="' + plan.title + '" data-plan-carrier="' + plan.carrier_name + '" data-plan-id="' + plan.id + '" data-plan-metal-level="' + plan.metal_level_kind + '" data-plan-type="' + plan.product_type + '" data-network="' + plan.network + '">' +
            '<span class="checkmark"></span>' +
          '</label>' +
        '</div>' +
      '</div>';

      var yourPlans = document.getElementById('yourPlans');
      yourPlans.insertBefore(div, yourPlans.children[-1] || null);
  }

  window.setTimeout(function() {
    selectDefaultReferencePlan();
    buildSponsorContributions(window.sponsorContribution);
    disableEmployeeContributionLevel();
    newContributionAmounts();
  },400);
}

function getPlanInfo(element) {
  if (document.querySelector('input#sponsored_benefits_kind')) {
    if (productOptionKind == 'multi_product') {
      document.querySelector('.select_choice_reference_plan').classList.add("hidden");
      var choices = new Array;
      document.querySelectorAll('.multiProductOptions input[type=checkbox]:checked').forEach(function(ele, index){
        choices.push(ele.value);
      });
      var products = new Array;
      window.planOptions[productOptionKind].forEach(function(product, index) {
        if(choices.includes(product.id)) {
          products.push(product);
        }
      });
      filteredProducts = products;
    } else {
      var selectedRadio = element.value;
      var selectedName = element.dataset.name;
      window.filteredProducts = window.planOptions[window.productOptionKind][selectedName];
    }
    // Sort by plan title
    filteredProducts.sort(function(a,b) {
      if (a.title < b.title) return -1;
      if (a.title > b.title) return 1;
      return 0;
    })
    populateReferencePlans(window.filteredProducts)
    setTempCL()
    selectDefaultReferencePlan()
  } else {
    if (element.tagName != 'INPUT') {
      element = element.querySelector('input[type=radio][data-name]');
    }
    var selectedRadio = element.value;
    var selectedName = element.dataset.name;
    window.filteredProducts = window.planOptions[window.productOptionKind][selectedName];
    // Sort by plan title
    window.filteredProducts.sort(function(a,b) {
      if (a.title < b.title) return -1;
      if (a.title > b.title) return 1;
      return 0;
    })
    populateReferencePlans(window.filteredProducts);
    setTempCL();
  }
}

function showPlanSelection() {
  // document.getElementById('planSelection').classList.remove('hidden');
  document.getElementById('referencePlanEdit').classList.add('hidden');
  document.getElementById('scEdit').remove();
  document.getElementById('metal-level-select').classList.remove('hidden');
  document.getElementById('saveBenefitPackage').classList.add('hidden');
  document.getElementById('submitDentalBenefits').classList.remove('hidden');
}

function loadEmployeeCosts() {
  var table = document.getElementById('eeTableBody');

  table.querySelectorAll('tr').forEach(function(element) {
    element.remove()
    });

  var tr = document.createElement('tr')
  var productOptionKind = 'multi_product';
  var productsTotal;
  var estimate = window.employeeCostEstimate;
  var planOptions = window.planOptions;
  var element = document.querySelector("input[name='sponsored_benefits[reference_plan_id]']:checked");

  // var selectedName = element.dataset.carrierName;
  // var planTitle = element.dataset.planTitle;
  // filteredProducts = planOptions[productOptionKind][selectedName];

  document.getElementById('planOfferingsTitle').innerHTML = '';
  // document.getElementById('planOfferingsTitle').append(`Plan Offerings - ${planTitle} (${filteredProducts.length})`)

  tr.innerHTML =
    `
    <td class="text-center">${estimate[0].name}</td>
    <td class="text-center">${estimate[0].dependent_count}</td>
    <td class="text-center">$ ${estimate[0].lowest_cost_estimate}</td>
    <td class="text-center">$ ${estimate[0].reference_estimate}</td>
    <td class="text-center">$ ${estimate[0].highest_cost_estimate}</td>
    `
  table.appendChild(tr)
}

function setPlanOptionKind(element) {
  var productPackageKind = element.querySelector('a').dataset.name;
  document.getElementById('sponsored_benefits_product_package_kind').value = productPackageKind;
  if (productPackageKind == 'multi_product') {
    document.querySelector('.select_choice_reference_plan').classList.remove("hidden");
  }
  else {
    document.querySelector('.select_choice_reference_plan').classList.add("hidden");
  }
}

export const MetalLevelSelect = {
  disableDentalBenefitPackage: disableDentalBenefitPackage,
  disableNewAddBenefitPackageButton: disableNewAddBenefitPackageButton,
  disableNewPlanYearButton: disableNewPlanYearButton,
  displayReferencePlanDetails: displayReferencePlanDetails,
  getPlanInfo: getPlanInfo,
  loadEmployeeCosts: loadEmployeeCosts,
  newContributionAmounts: newContributionAmounts,
  radioSelected: radioSelected,
  setInputSliderValue: setInputSliderValue,
  setPlanOptionKind: setPlanOptionKind,
  setNumberInputValue: setNumberInputValue,
  showMoreDetails: showMoreDetails,
  viewSummary: viewSummary
};
