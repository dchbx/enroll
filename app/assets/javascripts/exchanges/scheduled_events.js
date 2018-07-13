$(document).on('change', '#selected_scheduled_event_type', function(){
    $.ajax({
      type: 'get',
      datatype: 'js',
      url: '/exchanges/scheduled_events/current_events',
      data: {event: this.value},
      success: function (response) {
        $('#scheduled_event').show();
        $('#scheduled_event').html(response);
      }
    });
  
});
