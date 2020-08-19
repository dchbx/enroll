$(document).ready(function() {
  if ($("#origin_source").val() == "fa_application_edit_add_member")  {
    $('#household_info_add_member').click();
  }

  $("body").on("click", ".close_member_form", function () {
    $(".append_consumer_info").html("");
    $(".faa-row").removeClass('hide');
  });

  // Check for Eligibility Result response every "interval_time" seconds a total of "number_of_times" times.
  if (/wait_for_eligibility_response/.test(window.location.href)) {
    var i = 1;
    var number_of_times = 10;
    var interval_time = 2000;
    var repeater = setInterval(function () {
      if ( i < number_of_times) {
        $.ajax({
          type: "GET",
          data:{},
          url: window.location.href.replace(/wait_for_eligibility_response/, "check_eligibility_results_received"),
          success: function (response_received_flag) {
            if (response_received_flag == "true"){
              // redirect to the existing eligibility_results page
              window.location = window.location.href.replace(/wait_for_eligibility_response/, "eligibility_results?cur=1")
            }
          }
        });
        i += 1;
      } else {
        clearInterval(repeater);
        if ( i > 9 ){
          window.location = window.location.href.replace(/wait_for_eligibility_response/, "eligibility_response_error")
        }
      }
    }, interval_time);
  }
});
// Provides functionality to display modal then navigate to household income on confirming
var toLocation = '';

function notifyUserPrompt(element) {
  toLocation = element.dataset.path;
  $('#backModal').modal('show');
}

function backToHouseHolds() {
  $('#backModal').modal('hide');
  window.location = toLocation;
  toLocation = '';
}
