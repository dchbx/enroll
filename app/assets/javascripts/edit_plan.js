$(document).on("ready ajax:success", function() {

  // Cancel Confirmation
  $("#agreement_action-confirm-yes").click(function(){
    $(".interaction-click-control-action-confirm").attr("disabled", false);
    $("#action-confirm-date").attr("hidden", false);
    $("#update-aptc-button").attr("disabled", false);
  });
  $("#agreement_action-confirm-no").click(function(){
    $(".interaction-click-control-action-confirm").attr("disabled", true);
    $("#action-confirm-date").attr("hidden", true);
    $("#update-aptc-button").attr("disabled", true);
  });

  // Change Tax Credit Confirmation
  $("#agreement_action-confirm-yes-change-tax-credit").click(function(){
    $(".interaction-click-control-action-confirm").attr("disabled", false);
    $("#action-confirm-date").attr("hidden", false);
    $("#update-aptc-button").attr("disabled", false);
  });
  $("#agreement_action-confirm-no-change-tax-credit").click(function(){
    $(".interaction-click-control-action-confirm").attr("disabled", true);
    $("#action-confirm-date").attr("hidden", true);
    $("#update-aptc-button").attr("disabled", true);
  });

  // Cancel Plan Form
  $('#cancel-button').click(function(e){
    e.preventDefault();
    $('.confirmation').addClass('hidden');
    $('#cancel-plan-form').removeClass('hidden');
    $('.action-msg').addClass('hidden');
    $('#cancel-msg').removeClass('hidden');
    $('#cancel-form').removeClass('hidden');
    $('#calendar-div').addClass('hidden');
    $('#applied-aptc-text').addClass('hidden');
  });

  // Change Tax Credit Form
  $('#aptc-button').click(function(e){
    e.preventDefault();
    //Check if cancel plan form is open, and hide it if necessary
    $('#cancel-plan-form').addClass('hidden');
    $('#change-tax-credit-form').removeClass('hidden');
    $('#aptc-msg').removeClass('hidden');
    $('#calendar-div').removeClass('hidden');
    $('#applied-aptc-text').removeClass('hidden');
    $('#cancel-form').addClass('hidden');
  });


  // APTC JS
  $('#applied_pct_1').change(function(){
    calculatePercent('#applied_pct_1', 100);
  });
  $('#aptc_applied_5cf6c9ec9ee4f43836000020').change(function(){
    calculatePercent('#aptc_applied_total', 1);
  });

  function calculatePercent(selector, multiplier) {
    var percent = parseFloat($(selector).val()).toFixed(2) * multiplier;
    $('#aptc_applied_pct_1_percent').val(percent + '%');
    $('#aptc_applied_total').val(percent);
    // TODO: Fix the value being subtracted from new premium
    var current_total_premium_value = document.getElementById("current_total_premium").innerHTML;
    console.log("Currentn value of total premium is " + current_total_premium_value);
    var current_total_premium = parseFloat(current_total_premium_value);
    console.log("Integer value of current toal premium is " + current_total_premium) 
    var new_premium = (current_total_premium - parseInt($('#aptc_applied_total').val()).toFixed(2)).toFixed(2);
    $('#new-premium').html(new_premium);
  }

});