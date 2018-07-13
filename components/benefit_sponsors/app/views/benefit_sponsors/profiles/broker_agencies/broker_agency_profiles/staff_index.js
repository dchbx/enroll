$('#inbox .col-md-10').html(("<%= escape_javascript render "benefit_sponsors/profiles/broker_agencies/broker_agency_profiles/staff"%>"))
$('#inbox').removeClass("hide")
$('#help_list').addClass('hide')
$('#help_type').html('Broker')
$('#back_to_help').removeClass('hide')

function show_broker(broker_id) {
  $("#broker_index_view").addClass('hide')
  $("#broker_show_" + broker_id).removeClass('hide')
  $("#help_index_status").html('')
}

$('.broker_select_button').click(function(){
  show_broker(this.getAttribute('data-broker'))
  $('#help_index_status').html('')
})
$('.close_broker_select').click(function(){
  $("#broker_index_view").removeClass('hide')
  $(".broker_selection_choice").addClass('hide')
})
