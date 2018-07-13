function getCostDetails(min,max,cost) {
  document.getElementById('employerCostTitle').innerHTML = '';
  document.getElementById('employerCostTitle').append(`Employer Lowest/Reference/Highest - $${min}/$${cost}/$${max}`);
}

function showCostDetails(cost,min,max) {
  document.getElementById('rpEstimatedMonthlyCost').innerHTML = ('$ '+cost);
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
  table.querySelectorAll('tr').forEach(function(element) {
    element.remove()
  });
  //modal = document.getElementById('modalInformation')
  //row = document.createElement('col-xs-12')
  //row.innerHTML = `Plan Offerings - <br/>Employer Lowest/Reference/Highest -`
  //modal.appendChild(row)

  for (var employee in employees_cost) {
    var tr = document.createElement('tr')
    estimate = employees_cost[employee];
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


function calculateEmployeeCostsImmediate(productOptionKind,referencePlanID, sponsoredBenefitId)  {
  var thing = $("input[name^='benefit_package['").serializeArray();
  var submitData = {};
  for (item in thing) {
    submitData[thing[item].name] = thing[item].value;
  }
  // We have to append this afterwards because somehow, somewhere, there is an empty field corresponding
  // to product package kind.
  submitData['benefit_package'] = {
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

const calculateEmployeeCosts = debounceRequest(calculateEmployeeCostsImmediate, 1000);

function calculateEmployerContributionsImmediate(productOptionKind,referencePlanID, sponsoredBenefitId)  {
  var thing = $("input[name^='benefit_package['").serializeArray();
  var submitData = { };
  for (item in thing) {
    submitData[thing[item].name] = thing[item].value;
  }
  // We have to append this afterwards because somehow, somewhere, there is an empty field corresponding
  // to product package kind.
  submitData['benefit_package'] = {
    sponsored_benefits_attributes: { "0": { product_package_kind: productOptionKind,reference_plan_id: referencePlanID, id: sponsoredBenefitId } }
  };
  $.ajax({
    type: "GET",
    data: submitData,
    url: "calculate_employer_contributions",
    success: function (d) {
      var eeMin = parseFloat(d["estimated_enrollee_minimum"]).toFixed(2);
      var eeCost = parseFloat(d["estimated_total_cost"]).toFixed(2);
      var eeMax = parseFloat(d["estimated_enrollee_maximum"]).toFixed(2);
      showCostDetails(eeCost,eeMin,eeMax)
    }
  });
}

const calculateEmployerContributions = debounceRequest(calculateEmployerContributionsImmediate, 1000);

module.exports = {
  calculateEmployerContributions : calculateEmployerContributions,
  calculateEmployeeCosts : calculateEmployeeCosts
};
