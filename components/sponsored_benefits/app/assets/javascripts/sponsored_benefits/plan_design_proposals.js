$(document).on('click', '.health-plan-design .nav-tabs li label', fetchCarriers);
$(document).on('change', '.health-plan-design .nav-tabs li input', carrierSelected);
$(document).on('click', '.reference-plan input[type=radio] + label', planSelected);
$(document).on('slideStop', '#new_forms_plan_design_proposal .benefits-fields .slider', setSliderDisplayVal);
$(document).on('click', '.plan_design_proposals .checkbox', calcPlanDesignContributions);
// $(document).on('change', '#new_forms_plan_design_proposal input.premium-storage-input', reconcileSliderAndInputVal);
$(document).on('click', ".health-plan-design li:has(label.elected_plan)", attachEmployerHealthContributionShowHide);

$(document).on('click', '.reference-plan input[type=checkbox]', comparisonPlans);
$(document).on('click', '#clear-comparison', clearComparisons);
$(document).on('click', '#view-comparison', viewComparisons);
$(document).on('click', '#hide-detail-comparisons', hideDetailComparisons);
$(document).on('click', '.plan-type-filters .plan-search-option', sortPlans);

$(document).on('submit', '#new_forms_plan_design_proposal', preventSubmitPlanDesignProposal);
$(document).on('click', '#reviewPlanDesignProposal', saveProposalAndNavigateToReview);
$(document).on('click', '#submitPlanDesignProposal', saveProposal);
$(document).on('click', '#copyPlanDesignProposal', saveProposalAndCopy);
$(document).on('click', '#publishPlanDesignProposal', saveProposalAndPublish);

$(document).on('click', '#downloadReferencePlanDetailsButton.plan-not-saved', checkIfSbcIncluded);
$(document).on('click', '#downloadReferencePlanDetailsButton.plan-saved', sendPdf);


$(document).on('ready', pageInit);
$(document).on('page:load', pageInit);

function pageInit() {
  if ($("#reference_plan_id").val() != '') {
    calcPlanDesignContributions();
  } else {
    disableActionButtons();
    $('li.sole-source-tab').find('label').trigger('click');
  }
  initSlider();
  $('.loading-plans-button').hide();
  disableCompareButton();
}

function attachEmployerHealthContributionShowHide() {
  var offering_id = $(this).attr("data-offering-id");
  var option_kind = $(this).attr("data-offering-kind");
  if (option_kind == "sole_source") {
    $("div[data-offering-target='" + offering_id + "']").removeClass('enabled');
    $("div[data-offering-target='composite_" + offering_id + "']").addClass("enabled");
  } else {
    $("div[data-offering-target='composite_" + offering_id + "']").removeClass("enabled");
    $("div[data-offering-target='" + offering_id + "']").addClass("enabled");
  }
}

function fetchCarriers() {
  var active_year = $("#forms_plan_design_proposal_effective_date").val().substr(0,4);
  var selected_carrier_level = $(this).siblings('input').val();
  var plan_design_organization_id = $('#plan_design_organization_id').val();
  $(this).closest('.health-plan-design').find('.nav-tabs li').removeClass('active');
  $(this).closest('li').addClass('active');
  hideDetailComparisons;

  $.ajax({
    type: "GET",
    data:{
      active_year: active_year,
      selected_carrier_level: selected_carrier_level,
    },
    success: function() {
      setTimeout(function() {
        formatRadioButtons()
      },400);
    },
    url: "/sponsored_benefits/organizations/plan_design_organizations/" + plan_design_organization_id + "/carriers"
  });

  displayActiveCarriers();
  hidePlanContainer();
  toggleSliders(selected_carrier_level);
  clearComparisons();
}

function setSBC(plan) {
  if ($("#include_sbc").prop('checked')) {
   $('#downloadReferencePlanDetailsButton').attr('href',plan+"?sbc_included=true");
  } else {
   $('#downloadReferencePlanDetailsButton').attr('href',plan);
  }
}

function sendPdf(event) {
  $(this).addClass('plan-not-saved');
  $(this).removeClass('plan-saved');
  window.location.href = $(this).attr('href');
}

function checkIfSbcIncluded(event) {
  var elem_id = $(this).attr('id');
  var obj = $('#'+elem_id);
  if(obj.hasClass('plan-not-saved')) {
      event.preventDefault();
      var data = buildBenefitGroupParams();
      if (proposalIsInvalid(data)) {
        // handle error messaging
        return;
      } else {
        url = $("#benefit_groups_url").val();
        $.ajax({
          type: "POST",
          data: data,
          url: url
        }).done(function(){
          obj.removeClass('plan-not-saved');
          obj.addClass('plan-saved');
          obj.click();
        });
      }
    }
}

function displayActiveCarriers() {
  $(this).closest('.health-plan-design').find('.nav-tabs li').removeClass('active');
  $(this).closest('li').addClass('active');
  $(this).closest('.health-plan-design').find('.nav-tabs li.active label').attr('style', '');
  $(this).closest('.health-plan-design').find('.nav-tabs li:not(.active) label').css({borderBottom: "none", borderBottomLeftRadius: "0", borderBottomRightRadius: "0" });

  if ($(this).find('input[type=radio]').is(':checked')) {
  } else {
    $(this).find('input[type=radio]').prop('checked', true );
    $(this).closest('.health-plan-design').find('.plan-options > *').hide();
    $(this).closest('.health-plan-design').find('.loading-container').html("<div class=\'col-xs-12 loading\'><i class=\'fa fa-spinner fa-spin fa-2x\'></i></div>");
  }
}

function hidePlanContainer() {
  $('.reference-plans').hide();
  $('.selected-plan').html("");
}

function carrierSelected() {
  $('.tab-container').hide();
  var elected_plan_kind = $(this).attr('value');
  selected_rpids = [];
  $('.plan-comparison-container').hide();

  $("#elected_plan_kind").val(elected_plan_kind);
  $("#reference_plan_id").val("");

  if (elected_plan_kind == "single_carrier") {
    $(this).closest('.health-plan-design').find('.carriers-tab').show();
    $(this).closest('.health-plan-design').find('.plan-options').slideDown();
  }
  else if (elected_plan_kind == "metal_level") {
    $(this).closest('.health-plan-design').find('.metals-tab').show();
    $(this).closest('.health-plan-design').find('.plan-options').slideDown();
  }
  else if (elected_plan_kind == "single_plan") {
    $(this).closest('.health-plan-design').find('.single-plan-tab').show();
    $(this).closest('.health-plan-design').find('.plan-options').slideDown();
  }
  else if (elected_plan_kind == 'sole_source') {
    $(this).closest('.health-plan-design').find('.sole-source-plan-tab').show();
    $(this).closest('.health-plan-design').find('.plan-options').slideDown();
  }
}

function planSelected() {
  toggleSliders($("#elected_plan_kind").val());

  var reference_plan_id = $(this).siblings('input').val();
  $("#reference_plan_id").val(reference_plan_id);
  $(this).closest('.benefit-group-fields').find('.health-plan-design .selected-plan').html("<br/><br/><div class=\'col-xs-12\'><i class=\'fa fa-spinner fa-spin fa-2x\'></i><h4 style='text-align: center;'>Loading your reference plan preview...</h4></div>");

  if (reference_plan_id != "" && reference_plan_id != undefined){
    $('.health-plan-design .selected-plan').show();
    calcPlanDesignContributions();
    $(this).siblings('input').prop('checked', true);
  };

  clearComparisons();
}

function setSliderDisplayVal(slideEvt) {
  $(this).closest('.form-group').find('.hidden-param').val(slideEvt.value).attr('value', slideEvt.value);
  $(this).closest('.form-group').find('.slide-label').text(slideEvt.value + "%");
  calcPlanDesignContributions();
}

function toggleSliders(plan_kind) {
  if (plan_kind == 'sole_source') {
    $('.composite-offerings').removeClass('hidden');
    $('.offerings').addClass('hidden');
  } else {
    $('.offerings').removeClass('hidden');
    $('.composite-offerings').addClass('hidden');
  }
}

function calcPlanDesignContributions() {
  data = buildBenefitGroupParams();

  if (proposalIsInvalid(data)) {
    disableActionButtons();
  } else {
    enableActionButtons();
  }
  if (data == undefined || data == {} || !('benefit_group' in data)) {
    return;
  }

  var url = $("#contribution_url").val();

  $.ajax({
    type: "GET",
    url: url,
    dataType: 'script',
    data: data
  }).done(function() {
    // do something on completion?
  });

}

function buildBenefitGroupParams() {
  var reference_plan_id = $('#reference_plan_id').val();
  if (reference_plan_id == "" || reference_plan_id == undefined) {
    return {};
  }

  var plan_option_kind = $("#elected_plan_kind").val();

  var premium_pcts = $('.enabled .benefits-fields input.hidden-param').map(function() {
    return $(this).val();
  }).get();
  var is_offered = $('.enabled .benefits-fields .checkbox label > input[type=checkbox]').map(function() {
    return $(this).is(":checked");
  }).get();

  var composite_rating_tier_types = [ 'employee_only', 'family', 'employee_and_spouse', 'employee_and_one_or_more_dependents']
  var relationship_benefit_types = [ 'employee', 'spouse', 'domestic_partner', 'child_under_26', 'child_26_and_over']
  relation_benefits = {};

  if (plan_option_kind === 'sole_source') {
    premium_pcts.push(premium_pcts[premium_pcts.length - 1]);
    premium_pcts.push(premium_pcts[premium_pcts.length - 1]);

    composite_rating_tier_types.forEach(function(compositeTierType, index, composite_tier_types) {
      relation_benefits[index] = {
        "composite_rating_tier": compositeTierType,
        "employer_contribution_percent": premium_pcts[index],
        "offered":  is_offered[index]
      }
    });
  } else {
    relationship_benefit_types.forEach(function(relationshipType, index, relationships) {
      relation_benefits[index] = {
        "relationship": relationshipType,
        "premium_pct": premium_pcts[index],
        "offered":  is_offered[index]
      }
    });
  }

  var data = {
    'benefit_group': {
      "reference_plan_id": reference_plan_id,
      "plan_option_kind": plan_option_kind,
    }
  }

  if(plan_option_kind == 'sole_source') {
    data['benefit_group']["composite_tier_contributions_attributes"] = relation_benefits;
  } else {
    data['benefit_group']["relationship_benefits_attributes"] = relation_benefits;
  }
  return data;
}

function initSlider() {
  $('.benefits-fields input.hidden-param, .dental-benefits-fields input.hidden-param').each(function() {
    $(this).closest('.form-group').find('.slider').attr('data-slider-value', $(this).val());
    $(this).closest('.form-group').find('.slide-label').html($(this).val()+"%");
  });

  $('.benefits-fields .slider').bootstrapSlider({
    formatter: function(value) {
      return 'Contribution Percentage: ' + value + '%';
    },
    max: 100,
    min: 0,
    step: 1
  });
}

function formatRadioButtons() {
  $('.fa-circle-o').each(function() {
    $(this).click(function() {
      input = $(this).closest('div').find('input');
      input.prop('checked', true)
    });
  })
}

function preventSubmitPlanDesignProposal(event) {
  event.preventDefault();
}

function disableActionButtons() {
  var minimum_employee_contribution = $("#employer_min_employee_contribution").val();
  var minimum_family_contribution = $("#employer_min_family_contribution").val();
  data = buildBenefitGroupParams();
  if (proposalIsInvalid(data)){
    $(function () {
      $('[data-toggle="tooltip"]').tooltip()
    });
    $('.plan_design_proposals .save-action').attr('disabled', 'disabled');
    $('.plan_design_proposals .plan-selection-button-group').attr({
     'data-toggle': "tooltip",
     'data-placement': "top",
      'data-title':"Employer premium contribution for Family Health Plans must be at least " + minimum_family_contribution + "%, and Employee Only Health Plans must be at least " + minimum_employee_contribution + "%"
   })
  }
}

function enableActionButtons() {
  $('.plan_design_proposals .save-action').removeAttr('disabled');
}

function contributionLevelsAreValid(benefit_group) {
  if ('composite_tier_contributions_attributes' in benefit_group) {
    var contributions = benefit_group['composite_tier_contributions_attributes'];
    return checkContributionLevels(Object.values(contributions));
  } else if ('relationship_benefits_attributes' in benefit_group) {
    var contributions = benefit_group['relationship_benefits_attributes'];
    return checkContributionLevels(Object.values(contributions));
  } else {
    return false;
  }
}

function checkContributionLevels(contributions) {
  var minimum_employee_contribution = $("#employer_min_employee_contribution").val();
  var minimum_family_contribution = $("#employer_min_family_contribution").val();
  var offered_contributions = contributions.filter(function( obj ) {
    return obj.offered;
  });

  values_to_check = offered_contributions.map(function(obj) {
    if('composite_rating_tier' in obj) {
      obj.relationship = obj.composite_rating_tier;
      obj.premium_pct = obj.employer_contribution_percent;
    }
    return obj;
  });
  var contributions_are_valid = [];

  values_to_check.forEach(function(contribution){
    if(contribution.relationship == 'employee' || contribution.relationship == 'employee_only') {
      contributions_are_valid.push((contribution.premium_pct >= minimum_employee_contribution));
    } else if (contribution.relationship == 'family'){
      contributions_are_valid.push((contribution.premium_pct >= minimum_family_contribution));
    } else if (contribution.relationship == 'spouse'){
      contributions_are_valid.push((contribution.premium_pct >= minimum_family_contribution));
    } else if (contribution.relationship == 'domestic_partner'){
      contributions_are_valid.push((contribution.premium_pct >= minimum_family_contribution));
    } else if (contribution.relationship == 'child_under_26'){
      contributions_are_valid.push((contribution.premium_pct >= minimum_family_contribution));
    }
  });
  return contributions_are_valid.every(function(val) {
    return val == true;
  });
}

function proposalIsInvalid(data) {
  if (data == undefined || data == {} || !('benefit_group' in data)) {
    return true;
  } else {
    return !contributionLevelsAreValid(data['benefit_group']);
  }
}

function saveProposal(event) {
  var data = buildBenefitGroupParams();
  if (proposalIsInvalid(data)) {
    // handle error messaging
    return;
  } else {
    url = $("#benefit_groups_url").val();
    $.ajax({
      type: "POST",
      data: data,
      url: url
    }).done(function(){
      $('.success-message').html('Plan successfully updated!');
    });
  }

}

function saveProposalAndCopy(event) {
  var data = buildBenefitGroupParams();
  if (proposalIsInvalid(data)) {

  } else {
    url = $("#benefit_groups_url").val();
    $.ajax({
      type: "POST",
      data: data,
      url: url
    }).done(function(data) {
      var copy_url = $('#copy_proposal_url').val();
      $.ajax({
        url: copy_url,
        type: 'POST',
        dataType: 'json',
        success: function(data) {
          window.location.href = data.url;
        },
        error: function(data) {
          resp = $.parseJSON(data.responseText);
        }
      });
    });
  }
}

function saveProposalAndPublish(event) {
  data = buildBenefitGroupParams();
  if (proposalIsInvalid(data)) {

  } else {
    var url = $("#benefit_groups_url").val();
    $.ajax({
      type: "POST",
      data: data,
      url: url
    }).done(function(data) {
      var publish_url = $('#publish_proposal_url').val();
      $.ajax({
        url: publish_url,
        type: 'POST',
        success: function(data) {
          window.location.href = data.url;
        },
        error: function(data) {
          var resp = $.parseJSON(data.responseText);
          window.location.href = resp.url;
        }
      });
    });
  }
}

function saveProposalAndNavigateToReview(event) {
  var data = buildBenefitGroupParams();
  if (proposalIsInvalid(data)) {

  } else {
    var url = $("#benefit_groups_url").val();
    $.ajax({
      type: "POST",
      data: data,
      url: url
    }).done(function(data) {
      window.location.href = data.url;
    });
  }
}

selected_rpids = [];

function comparisonPlans() {
  $(this).each(function() {
    var value = $(this).val();
    if ($(this).is(":checked") && $.unique(selected_rpids).length <= 3) {
      selected_rpids.push(value)
    }
    if (!$(this).is(":checked")) {
      removeA($.unique(selected_rpids), value);
    }
    if ($.unique(selected_rpids).length > 3) {
      alert("You can only compare up to 3 plans");
      $(this).attr('checked', false);
      removeA($.unique(selected_rpids), value);
    }
  });
  disableCompareButton();
}

function viewComparisons() {
  var url = $("#plan_comparison_url").val();
  $('.view-plans-button').hide();
  $('.loading-plans-button').show();

    $.ajax({
      type: "GET",
      url: url,
      dataType: 'script',
      data: { plans: selected_rpids, sort_by: '' },
    }).done(function() {
      $('#compare_plans_table').dragtable({dragaccept: '.movable'});
      $('.view-plans-button').show();
      $('.loading-plans-button').hide();
    });

    $('.plan-comparison-container').show();
}

function clearComparisons() {
  $('.reference-plan').each(function() {
    var checkboxes = $(this).find('input[type=checkbox]');
    checkboxes.attr('checked', false);
    removeA($.unique(selected_rpids), checkboxes.val());
    disableCompareButton();
  });
}

function hideDetailComparisons() {
  selected_rpids = [];
  $('.plan-comparison-container').hide();
}

function disableCompareButton() {
  $('#view-comparison').addClass('disabled');
  $('#clear-comparison').addClass('disabled');
  $('.reference-plan input[type=checkbox]').each(function() {
    if ($(this).is(":checked")) {
      $('#view-comparison').removeClass('disabled');
      $('#clear-comparison').removeClass('disabled');
    }
  });
}

function removeA(arr) {
    var what, a = arguments, L = a.length, ax;
    while (L > 1 && arr.length) {
        what = a[--L];
        while ((ax= arr.indexOf(what)) !== -1) {
            arr.splice(ax, 1);
        }
    }
    return arr;
}

function sortPlans() {
  var $box = $(this).children('input').first();

  if ($box.is(":checked")) {
    // the name of the box is retrieved using the .attr() method
    // as it is assumed and expected to be immutable
    var group = "input:checkbox[data-search-type='" + $box.data("search-type") + "']";
    // the checked state of the group/box on the other hand will change
    // and the current value is retrieved using .prop() method
    $(group).prop("checked", false);
    $box.prop("checked", true);
  } else {
    $box.prop("checked", false);
  }

  var plans = $('.reference-plan');
  var search_types = {};

  $('.plan-search-option input').each(function(index) {
    var option = $(this);
    var option_is_checked = option.prop('checked');
    if (option_is_checked) {
      search_types[option.data('search-type').replace(/_/,'-')] = option.val();
    }
  });
  plans.parent().removeClass('hidden');
  plans.each(function(index) {
    var plan = $(this);
    var plan_matches = [];
    Object.keys(search_types).forEach(function(item) {
      var plan_value = plan.data(item);
      plan_matches.push((search_types[item].toString() === plan_value.toString()));
    });
    if(plan_matches.every(function(option){ return option; })) {
    } else {
      plan.parent().addClass('hidden');
    }
  });
}
