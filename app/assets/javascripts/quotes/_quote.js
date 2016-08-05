var Quote = ( function() {
  var set_plan_costs = function() {
    var plan_ids = Object.keys(QuotePageLoad.roster_premiums())
    for(var i = 0; i< plan_ids.length; i++){
      premium = 0
      plan_id = plan_ids[i]
      premiums = QuotePageLoad.roster_premiums()[plan_ids[i]]
      kinds = Object.keys(premiums) 
      for (var j=0; j<kinds.length; j++) {
        kind = kinds[j]
        premium = premium + premiums[kind] *  QuotePageLoad.relationship_benefits()[kind]
      }
     premium = Math.round(premium)/100.
     plan_button = "[value='" + plan_id + "']"
     employee_cost_div = $(plan_button).parent().children()[1]
     $(employee_cost_div).html(Math.ceil(parseFloat(premium)))
    }
  }
  var set_dental_plan_costs = function() {
    var plan_ids = Object.keys(QuotePageLoad.dental_roster_premiums())
    for(var i = 0; i< plan_ids.length; i++){
      premium = 0
      plan_id = plan_ids[i]
      premiums = QuotePageLoad.dental_roster_premiums()[plan_ids[i]]
      kinds = Object.keys(premiums) 
      for (var j=0; j<kinds.length; j++) {
        kind = kinds[j]
        premium = premium + premiums[kind] * QuotePageLoad.dental_relationship_benefits[kind]
      }
      premium = Math.round(premium)/100.
      plan_button = "[value='" + plan_id + "']"
      employee_cost_div = $(plan_button).parent().children()[1]
      $(employee_cost_div).html(Math.ceil(parseFloat(premium)))
    }
  }
  var selected_plans = function(){
    var plans=[];
    $.each($('.btn.active input'), function(i,item){plans.push( $(item).attr("value"))})
    return(plans)
  }
  var sort_plans = function(){
    var sort_by = $(this.parentNode).text();
    var plans = selected_plans()
    if(plans.length == 0) {
      alert('Please select one or more plans for comparison');
      return;
    }
    $.ajax({
      type: "GET",
      url: "/broker_agencies/quotes/plan_comparison",
      data: {plans: plans, sort_by: sort_by.substring(0, sort_by.length-2)},
      success: function(response) {
        $('#plan_comparison_frame').html(response);
        $('#compare_plans_table').dragtable({dragaccept: '.movable'});
        $('.cost_sort').on('click', sort_plans);
        _export_compare_plans_listener();
        $('#plan_ids').val(null);
      }
    })
  }
  var _compared_plans_export = function(){
    $.get('/broker_agencies/quotes/export_to_pdf');
  }
  var _compared_plans_export = function(){
    $.get('/broker_agencies/quotes/export_to_pdf');
  }
  var _export_compare_plans_listener = function(){
    $('#pdf_export_compare_plans').on('click', _compared_plans_export);
  }
  var _open_quote = function() {
    $('[aria-controls="quote-mgmt"]').attr('aria-expanded', false)
    $('#quote-mgmt').removeClass('in')
    $('[aria-controls="feature-mgmt"]').attr('aria-expanded', false)
    $('#feature-mgmt').removeClass('in')
    $('[aria-controls="plan-selection-mgmt"]').attr('aria-expanded', false)
    $('#plan-selection-mgmt').removeClass('in')
    $('[aria-controls="dental-plan-selection-mgmt"]').attr('aria-expanded', false)
    $('#dental-plan-selection-mgmt').removeClass('in')
    $('[aria-controls="publish-quote"]').attr('aria-expanded', true)
    $('#publish-quote').addClass('in')
  }
  var _set_quote_toolbar =  function(summary) {
    $('#quote-name').html(summary['name'])
    $('#quote-status').html(summary['status'])
    $('#quote-plan-name').html(summary['plan_name'])
    $('#quote-dental-plan-name').html(summary['dental_plan_name'])
  }
  var inject_plan_into_quote = function(quote_id, benefit_group_id, plan_id, elected) {
    $.ajax({
      type: "GET",
      url: "/broker_agencies/quotes/set_plan",
      data: {quote_id: quote_id,
             benefit_group_id: benefit_group_id,
             plan_id: plan_id,
             elected: elected},
      success: function(response){
        $('#publish-quote').html(response);
      }
    })    
  }
  var load_publish_listeners= function() {
    $('.publish td').on('click', function(){
        td = $(this)
        quote_id=$('#quote_id').val()
        plan_id=td.parent().attr('id')
        benefit_group_id = $('#benefit_group_select').val()
        elected=td.index()
        inject_plan_into_quote(quote_id, benefit_group_id, plan_id, elected)
        $.ajax({
          type: 'GET',
          data: {quote_id: quote_id, benefit_group_id: benefit_group_id},
          url: '/broker_agencies/quotes/get_quote_info.js'
        }).done(function(response){
          _set_quote_toolbar(response['summary'])
        })
        _open_quote()
    })
  }
  var show_benefit_group=function(quote_id, benefit_group_id){
    QuoteSliders.slider_listeners()
    QuotePageLoad.configure_benefit_group(quote_id, benefit_group_id)
    inject_plan_into_quote(quote_id, benefit_group_id)
    QuotePageLoad.page_load_listeners()
  }
  return {
    set_plan_costs: set_plan_costs,
    set_dental_plan_costs: set_dental_plan_costs,
    load_publish_listeners: load_publish_listeners,
    show_benefit_group: show_benefit_group,
    selected_plans: selected_plans,
    sort_plans: sort_plans,
  }
})();  