QuotePageLoad = (function() {
  var relationship_benefits = {}
  var dental_relationship_benefits = {}
  var roster_premiums =  {}
  var dental_roster_premiums = {}
  var available_health_plans = 0
  var _select_health_plans
  var set_select_health_plans = function(plans){_select_health_plans = plans}

  var set_relationship_pct = function(relationship, val) {
    relationship_benefits[relationship] = val
    $("[name~='" + relationship + "']").val(val)
    $.ajax({
      type: 'POST',
      data: {benefits: relationship_benefits, quote_id: $('#quote_id').val(),benefit_id: $('#benefit_group_select option:selected').val() },
      url: '/broker_agencies/broker_roles/'+$('#broker_role_id').val()+'/quotes/update_benefits.js',
    })
    Quote.set_plan_costs()
  }
  var set_dental_relationship_pct = function(relationship, val) {
    dental_relationship_benefits[relationship] = val
    $("[name~='" + relationship + "']").val(val)
    $.ajax({
      type: 'POST',
      data: {benefits: dental_relationship_benefits,
             quote_id: $('#quote_id').val(),
             benefit_id: $('#benefit_group_select option:selected').val(),
             coverage_kind: 'dental'
      },
      url: '/broker_agencies/broker_roles/'+$('#broker_role_id').val()+'/quotes/update_benefits.js',
    })
    Quote.set_dental_plan_costs()
  }
  var _plan_test = function(plan, criteria){
    var result = true
    var critters = criteria.length
    for (var j=0; j< critters; j++){
      var criteria_type = criteria[j][0]
      var criteria_value = criteria[j][1]
      if ((criteria_type == 'carriers') && (criteria_value != plan['carrier_abbrev']))   {result=false; break; }
      if ((criteria_type == 'metals') && (criteria_value != plan['metal']))     {result=false; break; }
      if ((criteria_type == 'plan_types') && (criteria_value != plan['plan_type'])) {result=false; break; }
      if ((criteria_type == 'nationwide') && (criteria_value != String(plan['nationwide']))) {result=false; break; }
      if ((criteria_type == 'dc_in_network') && (criteria_value != String(plan['dc_in_network']))) {result=false; break; }
    }
    if (parseInt(plan['deductible']) > parseInt(deductible_value)) {result=false}

    return result
  }
  var _set_plan_counts = function() {
      $('#show_plan_criteria_count').text('Plans that meet your criteria: ' + String(available_health_plans))
      $('#show_plan_selected_count').text('You have selected ' + String($('.btn.active').size()) +' plans.')
      $('#show_dental_plan_criteria_count').text('Plans that meet your criteria: ' + '13')
      $('#show_dental_plan_selected_count').text('You have selected ' + String($('.btn.active').size()) +' plans.')
  }
  var _turn_off_criteria = function() {
      $.each($('#feature-mgmt .active'), function(index,value){ $(value).addClass('criteria').removeClass('active') })
  }
  var toggle_plans = function(criteria){
    if(criteria.length== 0){
        $.each($('.plan_selectors .active'), function() {
            var criteria_type = this.parentNode.id
            var criteria_value = this.id
            if (criteria_value != 'any') {criteria.push([criteria_type,criteria_value])}
     })
    }
    else{
      _turn_off_criteria()
      for(var i = 0; i<criteria.length; i++){
        $('#' + criteria[i][0] +' #' + criteria[i][1]).addClass('active')
      }
    }
    var health_plan_count = Object.keys(_select_health_plans).length
    available_health_plans = 0;
    for(var i = 0; i < health_plan_count; i++) {
      var plan = _select_health_plans[i]
      var value = "[value~=" + plan['plan_id'] + "]"
      var display = _plan_test(plan, criteria) ? 'inline' : 'none'
      $(value).parent().css('display', display)
      if (display=='inline') {available_health_plans += 1}
    }
    $('#x-of-plans').html($('#quote-plan-list > label:visible').length);
    _set_plan_counts()
    $.ajax({
      type: 'GET',
      data: {
        quote_id: $('#quote_id').val(),
        broker_role_id: $('#broker_role_id').val(),
        benefit_id: $('#benefit_group_select option:selected').val(),
        criteria_for_ui: JSON.stringify(criteria),
        deductible_for_ui: deductible_value },
      url: '/broker_agencies/broker_roles/'+$('#broker_role_id').val()+'/quotes/criteria.js'
    })
  }
  var reset_selected_plans =  function(){
      $.each($('.plan_buttons .btn.active input'), function(){
      $(this).prop('checked', false)
      $(this).parent().removeClass('active')
      })
      _set_plan_counts()
      $('[aria-labelledby="compare_costs"]').html('')
      $('[aria-labelledby="compare_benefits"]').html('')
      setTimeout( function(){
        $('[aria-controls="plan-selection-mgmt"]').attr('aria-expanded', true)
        $('#plan-selection-mgmt').addClass('in')
      }, 0)
  }
  var _set_benefits = function() {
      $('#pct_employee').bootstrapSlider('setValue', employee_value = relationship_benefits['employee']);
      $('#employee_slide_input').val(employee_value)
      $('#employee_slide_label').html(employee_value + '%')
      $('#pct_spouse').bootstrapSlider('setValue', spouse_value = relationship_benefits['spouse']);
      $('#spouse_input').val(spouse_value)
      $('#spouse_label').html(spouse_value + '%')
      $('#pct_domestic_partner').bootstrapSlider('setValue', domestic_value = relationship_benefits['domestic_partner']);
      $('#domestic_input').val(domestic_value)
      $('#domestic_label').html(domestic_value + '%')
      $('#pct_child_under_26').bootstrapSlider('setValue', child_value = relationship_benefits['child_under_26']);
      $('#child_input').val(child_value)
      $('#child_label').html(child_value + '%')
      $('#dental_pct_employee').bootstrapSlider('setValue',employee_value = dental_relationship_benefits['employee']);
      $('.dental #employee_slide_input').val(employee_value)
      $('.dental #employee_slide_label').html(employee_value + '%')
      $('#dental_pct_spouse').bootstrapSlider('setValue',  spouse_value = dental_relationship_benefits['spouse']);
      $('.dental #spouse_input').val(spouse_value)
      $('.dental #spouse_label').html(spouse_value + '%')
      $('#dental_pct_domestic_partner').bootstrapSlider('setValue', domestic_value = dental_relationship_benefits['domestic_partner']);
      $('.dental #domestic_input').val(domestic_value)
      $('.dental #domestic_label').html(domestic_value + '%')
      $('#dental_pct_child_under_26').bootstrapSlider('setValue', child_value = dental_relationship_benefits['child_under_26']);
      $('.dental #child_input').val(child_value)
      $('.dental #child_label').html(child_value + '%')
  }
  var configure_benefit_group = function(quote_id, broker_role_id,benefit_group_id) {
    $.ajax({
            type: 'GET',
            data: {quote_id: quote_id, broker_role_id: broker_role_id, benefit_group_id: benefit_group_id},
            url: '/broker_agencies/broker_roles/' + broker_role_id +'/quotes/get_quote_info.js'
          }).done(function(response){
              relationship_benefits = response['relationship_benefits']
              dental_relationship_benefits = response['dental_relationship_benefits']
              roster_premiums = response['roster_premiums']
              dental_roster_premiums = response['dental_roster_premiums']
              _turn_off_criteria()
              deductible_value = parseInt(response['summary']['deductible_value'])
              $('#ex1').bootstrapSlider('setValue', deductible_value)
              $('#ex1_input').val(deductible_value)
              toggle_plans(response['criteria'])
              _set_benefits()
              Quote.set_plan_costs()
              Quote.set_dental_plan_costs()
          })
  }

  var _get_health_cost_comparison =function(){
    var plans = Quote.selected_plans('health');
    if(plans.length == 0) {
      alert('Please select one or more plans for comparison');
      return;
     }
    $.ajax({
      type: "GET",
      url: "/broker_agencies/broker_roles/"+$('#broker_role_id').val()+"/quotes/health_cost_comparison",
      data: {
        plans: plans,
        quote_id: $('#quote_id').val(),
        broker_role_id: $('#broker_role_id').val(),
        benefit_id: $('#benefit_group_select option:selected').val()
      },
      success: function(response) {
        $('#plan_comparison_frame').html(response);
        Quote.load_publish_listeners();
      }
    })
  }
  var _get_dental_cost_comparison= function() {
    plans = Quote.selected_plans('dental');
    quote_id=$('#quote').val();
    if(plans.length == 0) {
      alert('Please select one or more plans for comparison');
      return;
     }
    $.ajax({
      type: "GET",
      url: "/broker_agencies/broker_roles/"+$('#broker_role_id').val()+"/quotes/dental_cost_comparison",
      data: {
        plans: plans,
        quote_id: $('#quote_id').val(),
        benefit_id: $('#benefit_group_select option:selected').val(),
      },
      success: function(response) {
        $('#dental_plan_comparison_frame').html(response);
        Quote.load_publish_listeners();
      }
    })
  }

  var page_load_listeners = function() {
      $('.plan_selectors .criteria').on('click',function(){
          selected=this; sibs = $(selected).siblings();
          $.each(sibs, function(){ this.className='criteria' }) ;
          selected.className='active';
          toggle_plans([])
          reset_selected_plans()
      })
      $('.dental_carrier, .dental_metal, .dental_plan_type, .dc_network, .nationwide').on('click', function(){
        class_name = $(this).attr('class')
        $("." + class_name).each(function(){
          $(this).removeClass('active1')
        });
        $(this).addClass('active1')
        carrier_id = $('#dental-carriers').find('div.active1').attr('data-carrier')
        dental_level = $('#dental-metals').find('div.active1').attr('id')
        plan_type = $('#dental-plan_types').find('div.active1').attr('id')
        dc_network = $('#dental-dc_in_network').find('div.active1').attr('id')
        nationwide = $('#dental-nationwide').find('div.active1').attr('id')
        quote = $('#quote').val()
        $.ajax({
          type: 'GET',
          url: '/broker_agencies/broker_roles/'+$('#broker_role_id').val()+'/quotes/dental_plans_data/',
          data: {
            carrier_id: carrier_id,
            dental_level: dental_level,
            plan_type: plan_type,
            dc_network: dc_network,
            nationwide: nationwide,
            quote: quote
          },
          success: function(response) {
            $('#dental_plan_container').html(response)
            Quote.set_dental_plan_costs()
            $('#DentalCostComparison').on('click', _get_dental_cost_comparison)
          }
        });
      });
      $('.plan_buttons .btn').on('click', function() {
          var plan = $(this)
          delta = plan.hasClass('active') ? -1 : 1;
          adjusted_count = $('.btn.active').size() + delta
          if ( (adjusted_count > 25) && (delta == 1)  ) {
            alert('You may not select more than 25 plans at a time')
            setTimeout(function(){
              plan.removeClass('active')
              var input = $(plan.children()[0])
              input.prop('checked', false)
            },20)
          }
          else {
           $('#show_plan_selected_count').text('You have selected ' + String(adjusted_count) + ' plans.' )
          }
      })
      $('#benefit_group_select').on('change',
         function(){
          quote_id = $("#quote_id").val()
          broker_role_id = $("#broker_role_id").val()
          benefit_group_id = $(this).val()
          configure_benefit_group(quote_id, broker_role_id, benefit_group_id)
      })
      $('#reset_selected').on('click', reset_selected_plans)
      $('#CostComparison').on('click', _get_health_cost_comparison)
      $('#DentalCostComparison').on('click', _get_dental_cost_comparison)
      $('#PlanComparison').on('click', function(){
         Quote.sort_plans()
      })
  }
  var view_details=function($thisObj) {
    if ( $thisObj.hasClass('view') ) {
      $thisObj.html('Hide Details <i class="fa fa-chevron-up fa-lg"></i>');
      $thisObj.removeClass("view");
    } else {
      $thisObj.html('View Details <i class="fa fa-chevron-down fa-lg"></i>');
      $thisObj.addClass("view");
    }
    $thisObj.find('i').attr('data-toggle', 'collapse');
    $thisObj.find('i').attr('href', $thisObj.attr('href'));
  }

  return {
      page_load_listeners: page_load_listeners,
      configure_benefit_group: configure_benefit_group,
      view_details: view_details,
      toggle_plans: toggle_plans,
      reset_selected_plans: reset_selected_plans,
      set_select_health_plans: set_select_health_plans,
      relationship_benefits: function(){return relationship_benefits},
      dental_relationship_benefits: function(){return dental_relationship_benefits},
      roster_premiums: function(){return roster_premiums},
      dental_roster_premiums: function(){ return dental_roster_premiums},
      set_relationship_pct: set_relationship_pct,
      set_dental_relationship_pct: set_dental_relationship_pct,
  }
})();
