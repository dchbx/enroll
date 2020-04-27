function getCostDetails(min,max,cost) {
  document.getElementById('employerCostTitle').innerHTML = '';
  document.getElementById('employerCostTitle').append(`Employer Lowest/Reference/Highest - $${min}/$${cost}/$${max}`);
}

function showCostDetails(cost,min,max) {
  document.getElementById('rpEstimatedMonthlyCost').innerHTML = ('$ '+cost);

  if (min == 'NaN') {
    min = "0.00"
  }

  if (max == 'NaN') {
    max = "0.00"
  }

  document.getElementById('rpMin').innerHTML = ('$ '+ min);
  document.getElementById('rpMax').innerHTML = ('$ '+ max);
  if (document.getElementById('estimatedEEMin')) {
    document.getElementById('estimatedEEMin').innerHTML = '$ '+ min;
  }
  if (document.getElementById('estimatedEEMax')) {
    document.getElementById('estimatedEEMax').innerHTML = '$ '+ max;
  }
  if (document.getElementById('estimatedERCost')) {
    document.getElementById('estimatedERCost').innerHTML = '$ '+ cost;
  }
  getCostDetails(min,max,cost)
}

function showEmployeeCostDetails(employees_cost) {
  var table = document.getElementById('eeTableBody');
  Array.from(table.querySelectorAll('tr')).forEach(function(element) {
    element.remove()
  });
  //modal = document.getElementById('modalInformation')
  //row = document.createElement('col-xs-12')
  //row.innerHTML = `Plan Offerings - <br/>Employer Lowest/Reference/Highest -`
  //modal.appendChild(row)

  for (var employee in employees_cost) {
    var tr = document.createElement('tr')
    var estimate = employees_cost[employee];
    tr.innerHTML =
    `
      <td class="text-center">${estimate.name}</td>
      <td class="text-center">${estimate.dependent_count}</td>
      <td class="text-center">$ ${estimate.lowest_cost_estimate}</td>
      <td class="text-center">$ ${estimate.reference_estimate}</td>
      <td class="text-center">$ ${estimate.highest_cost_estimate}</td>
    `
    table.appendChild(tr)
  }
}

function debounceRequest(func, wait, immediate) {
	var timeout;
	return function() {
		var context = this, args = arguments;
		clearTimeout(timeout);
		timeout = setTimeout(function() {
			timeout = null;
			if (!immediate) func.apply(context, args);
		}, wait);
		if (immediate && !timeout) func.apply(context, args);
	};
}


function calculateEmployeeCostsImmediate(productOptionKind,referencePlanID, sponsoredBenefitId, referenceModel = "benefit_package")  {
  var thing = $("input[name^='"+referenceModel+"['").serializeArray();
  var submitData = {};
  for (var item in thing) {
    submitData[thing[item].name] = thing[item].value;
  }
  // We have to append this afterwards because somehow, somewhere, there is an empty field corresponding
  // to product package kind.
  submitData[referenceModel] = {
    sponsored_benefits_attributes: { "0": { product_package_kind: productOptionKind,reference_plan_id: referencePlanID, id: sponsoredBenefitId } }
  };
  $.ajax({
    type: "GET",
    data: submitData,
    url: "calculate_employee_cost_details",
    success: function (d) {
      showEmployeeCostDetails(d);
    }
  });
}

export const calculateEmployeeCosts = debounceRequest(calculateEmployeeCostsImmediate, 1000);

function calculateEmployerContributionsImmediate(productOptionKind,referencePlanID, sponsoredBenefitId, referenceModel = "benefit_package")  {
  var thing = $("input[name^='"+referenceModel+"['").serializeArray();
  var submitData = { };
  for (var item in thing) {
    submitData[thing[item].name] = thing[item].value;
  }
  // We have to append this afterwards because somehow, somewhere, there is an empty field corresponding
  // to product package kind.
  submitData[referenceModel] = {
    sponsored_benefits_attributes: { "0": { product_package_kind: productOptionKind,reference_plan_id: referencePlanID, id: sponsoredBenefitId } }
  };
  $.ajax({
    type: "GET",
    data: submitData,
    url: "calculate_employer_contributions",
    success: function (d) {
      var eeMin = parseFloat(d["estimated_enrollee_minimum"]).toFixed(2);
      var eeCost = parseFloat(d["estimated_sponsor_exposure"]).toFixed(2);
      var eeMax = parseFloat(d["estimated_enrollee_maximum"]).toFixed(2);
      showCostDetails(eeCost,eeMin,eeMax)
    }
  });
}

export const calculateEmployerContributions = debounceRequest(calculateEmployerContributionsImmediate, 1000);
