$(document).on 'click', 'form .add_fields', (event) ->
  if $(this).closest('.census-employee').length || $(this).closest('.census-employee-add').length
    $('.add-dependent-text').hide();
  event.preventDefault()
  time = new Date().getTime()
  regexp = new RegExp($(this).data('id'), 'g')
  html = $(this).data('fields').replace(regexp, time)
  target = $(this).closest('.form-inputs')
  if $(target).children('fieldset:last').length > 0
    $(target).children('fieldset:last').after(html)
  else
    $(target).prepend(html)
  $(target).children('fieldset:last').find('select').selectric()
  $(target).children('fieldset:last').find("input.floatlabel").floatlabel slideInput: false

  update_delete_buttons()
  applyJQDatePickers()

  if $('#plan_year_start_on').length
    EmployerProfile.validatePlanYear



  # get all dental plan options for all plans option or for elected dental plans
  $('span:contains("Select Reference Plan"), label.elected_plan:contains("Custom")').on 'click', ->
    `var url`
    `var nav_option`
    # $(this).closest('.reference-steps').find('div:first').hide();
    # $(this).closest('.nav-tabs').hide();
    if $(this).is(':contains("Custom")')
      nav_option = 'custom'
      url = $(this).closest('li').find('.dental-reference-plans-link').attr('href')
    else
      nav_option = 'all_plans'
      url = $(this).closest('.reference-steps').find('.dental-reference-plans-link').attr('href')
    plan_year_id = $('a#generate-dental-carriers-and-plans').data('plan-year-id')
    location_id = $(this).closest('.benefit-group-fields').attr('id')
    carrier_id = 'all_plans'
    start_on = $('#plan_year_start_on').val().substr(0, 4)
    $.ajax
      type: 'GET'
      data:
        plan_year_id: plan_year_id
        location_id: location_id
        carrier_id: carrier_id
        start_on: start_on
        nav_option: nav_option
      url: url
    return
  $('.benefit-group-fields:last').attr 'id', 'benefit-group-' + time
  $('.benefit-group-fields:last').data 'time', time
  $('.benefit-group-fields:last').attr 'data-benefit-group-index', $('.benefit-group-fields').length - 1
  $('.benefit-group-fields:last .dental-relationship-benefits-attributes-time').val time

  $('.benefit-group-fields:last .elected-plans-tab .reference-plan input[checkbox]').each ->
    name = $(this).attr('name')
    alert name
    return
  # get dental plan carrier namespace
  dental_target_url = $('a#generate-dental-carriers-and-plans').attr('href')
  plan_year_id = $('a#generate-dental-carriers-and-plans').data('planYearId')
  location_id = $('.benefit-group-fields:last').attr('id')
  if $('#plan_year_start_on').length
    active_year = $('#plan_year_start_on').val().substr(0, 4)
  $.ajax
    type: 'GET'
    data:
      active_year: active_year
      plan_year_id: plan_year_id
      location_id: location_id
    url: dental_target_url

  # match health with dental offering selections
  $('.health .offerings input[type=checkbox]').on 'change', ->
    checkedValue = $(this).closest('label').find('span').find('p').text()
    if $(this).is(':checked')
      $(this).closest('.benefit-group-fields').find('.dental-benefits-fields').find('label span p:contains(' + checkedValue + ')').closest('label').find('input[type=checkbox]').removeProp 'disabled', false
      $(this).closest('.benefit-group-fields').find('.dental-benefits-fields').find('label span p:contains(' + checkedValue + ')').closest('label').find('input[type=checkbox]').trigger 'click'
    else
      $(this).closest('.benefit-group-fields').find('.dental-benefits-fields').find('label span p:contains(' + checkedValue + ')').closest('label').find('input[type=checkbox]').removeProp 'checked'
    return

  if window.location.href.indexOf('edit') > -1 and window.location.href.indexOf('plan_years') > -1
    $('.benefit-group-fields:last .edit-add-dental').hide();
    $('.benefit-group-fields:last').attr 'custom', false
    $('.benefit-group-fields:last').addClass 'edit-additional'
    $('.benefit-group-fields:last .edit-offering, .benefit-group-fields:last .reference-steps .cancel-plan-change').remove()
    $('.benefit-group-fields:last .reference-steps h1').html '<h1>Select Your Plan Offering</h1>'
    $('.benefit-group-fields:last .reference-steps .currently-offering').html 'Let your plan participants choose any plan they want offered by a single carrier, from a given metal level, or offer just a single plan.'
    $('.benefit-group-fields:last .health .col-md-12.top-pd').hide();
    $('.benefit-group-fields:last .health .col-xs-12:first').hide();
  else


  $('.benefit-group-fields:last').find('.benefits-fields .slider, .dental-benefits-fields .slider').bootstrapSlider
    formatter: (value) ->
      return 'Contribution Percentage: ' + value + '%'
  $('.benefit-group-fields:last').find('.benefits-fields .slider, .dental-benefits-fields .slider').on 'slideStop', (slideEvt) ->
    $(this).closest('.form-group').find('.hidden-param').val(slideEvt.value).attr 'value', slideEvt.value
    $(this).closest('.form-group').find('.slide-label').text slideEvt.value + '%'
    return
  $('.benefit-group-fields:last input[value="child_under_26"]').closest('.row-form-wrapper').attr('style','border-bottom: 0px;')
  $('.benefit-group-fields:last input:first').focus()
  $('.remove_fields:last').css('display', 'inline-block')

  $('.benefit-group-fields:last .contribution_slide_handler').each ->
    $(this).on 'slideStop', (slideEvt) ->
      if $(this).closest('.health').length > 0
        coverage_type = '.health'
      else
        coverage_type = '.dental'
      location_id = $(this).parents('.benefit-group-fields').attr('id')
      calcEmployerContributions $('a#calc_employer_contributions_link').data('href'), location_id, coverage_type
      return
    return


  start_on = $('#plan_year_start_on').val()
  if start_on
    start_on = start_on.substr(0, 4)

    $('.plan-options a').each ->
      url = $(this).attr('href')
      $(this).attr 'href', url + '&start_on=' + start_on
  return

$(document).on 'click', 'form .remove_fields', (event) ->
  if $('.dependent_info').length == 1
    $('.census-employee-dependents').prev().text('0 Dependents')
    if $(this).closest('.module').closest('.row').find('.add-dependent-text').length
      $('.census-employee-dependents').prev().find('.add-dependent-text').show()
      $('.add-dependent-text').show()
    else
      if $('.add-dependent-text').length
      else
      $('.census-employee-dependents').prev().after('<h4 class="add-dependent-text">Click "Add Dependent" to add a dependent</h4>')
      $(this).closest('.module').closest('.row').find('.add-dependent-text, .form-inputs:first').wrapAll('<div class="vertically-aligned-row"></div>');
    $(this).closest('fieldset').closest('.module').remove()
  else
    $(this).closest('.census-employee-dependents').remove()
    $(this).closest('fieldset').remove()
  event.preventDefault()

$(document).on 'click', '.benefits-setup-tab .remove_fields', (event) ->
  $('.benefit-group-fields:last').remove()
  event.preventDefault()
  if $('.benefit-group-fields').length == 1 || $('.benefit-group-fields').length == $('#plan_year').data('benefit-group-count')
    $('.remove_fields').hide();
  if window.location.href.indexOf('edit') > -1 and window.location.href.indexOf('plan_years') > -1
    EmployerProfile.validateEditPlanYear
  else
    EmployerProfile.validatePlanYear

@update_delete_buttons = ->
  nested_fields = $('.form-inputs')
  nested_fields.each ->
    visible_fieldsets = $(this).find('fieldset:visible')
    delete_button = visible_fieldsets.find('.remove_fields')
    if visible_fieldsets.length == 1
      delete_button.hide()
    else
      delete_button.show()

$(document).on 'click', 'form .add_fields', (event) ->
  if $(this).closest('.census-employee').length || $(this).closest('.census-employee-add').length
    $('.remove_fields').show();
    Freebies.floatlabels();
