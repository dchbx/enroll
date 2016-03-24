function enableBrokerApplicantFilters() {

  var url = '/exchanges/broker_applicants.js';

  if( $('#broker_agency_profile_id').length ) {
     url = $('#broker_agency_profile_id').attr("href") + ".js";
  }


  $('div[name=broker_applicants_tabs] > ').children().each( function() {
    $(this).change(function(){
      filter = $(this).val();
      $.ajax({
        url: url,
        type: "GET",
        data : { 'status': filter }
      });
    });
  });
}
