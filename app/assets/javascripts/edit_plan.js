$(document).on("ready ajax:success", function() {

  // Max Date for Cancellation Datepicker
  // Minimum date is current date
  // maximum date is end of current year (I.E. 12/31/2019)
  $("#term-date").datepicker({minDate: 0, maxDate: new Date(new Date().getFullYear(), 11, 31)});
  $("#term-date").change(function(){
    if( $("#agreement_action-confirm-yes").attr('checked') ){
      $("#btn-cancel").attr("disabled", false);
    }
  });

  // Cancel Confirmation
  $("#agreement_action-confirm-yes").click(function(){
    $(".interaction-click-control-action-confirm").attr("disabled", false);
    $("#action-confirm-date").attr("hidden", false);
    $(this).attr('checked','checked');
    if($('#term-date') && $('#term-date').val() != "") {
      $("#btn-cancel").attr("disabled", false);
    }
  });
  $("#agreement_action-confirm-no").click(function(){
    $(".interaction-click-control-action-confirm").attr("disabled", true);
    $("#action-confirm-date").attr("hidden", true);
    $("#agreement_action-confirm-yes").removeAttr('checked');
    $("#btn-cancel").attr("disabled", true);
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
    calculateValue('#applied_pct_1', 100);
  });

  $('#aptc_applied_total').change(function(){


    $('#applied_pct_1').attr('step',0.01)
    var total = parseFloat($('#aptc_applied_total').val().replace(/\$/, ""));
    var max_aptc_available = parseFloat(document.getElementById("max_aptc_available").innerHTML);

    if (total >= max_aptc_available) {
      $('#aptc_applied_pct_1_percent').val('100%');
      $('#aptc_applied_total').val("$" + max_aptc_available);
      $('#applied_pct_1').val("1");
    }
    if (total < 0) {
      $('#aptc_applied_pct_1_percent').val('0%');
      $('#aptc_applied_total').val("$0");
      $('#applied_pct_1').val("0");
    }

    var new_total = parseFloat($('#aptc_applied_total').val().replace(/\$/, ""));

    var new_percent = toFixedTrunc(new_total/max_aptc_available);
    $('#applied_pct_1').val(new_percent);
    calculatePercent(new_total);
    $('#applied_pct_1').attr('step',0.05)
  });

  function calculatePercent(tax_value) {
    // Starting variables
    // var applied_aptc_total = $('#aptc_applied_total').val();
    var total_premium_value = document.getElementById("enrollment_total_premium").innerHTML;
    var total_premium = toFixedTrunc(parseFloat(total_premium_value));
    // Max available tax credit per month for month
    var max_aptc_available = document.getElementById("max_aptc_available").innerHTML;
    var new_percent = tax_value/max_aptc_available;

    var aptc_total_cash_amount_to_apply = toFixedTrunc(max_aptc_available * new_percent);
    // Update the percentage
    var percent_string = (new_percent.toFixed(2) * 100) + "%";
    $('#aptc_applied_pct_1_percent').val(percent_string);
    // Show dollar amount of Tax Credit value
    var new_premium = (total_premium - aptc_total_cash_amount_to_apply);
    $('#new-premium').html(toFixedTrunc(new_premium.toFixed(8)));
  }

  function toFixedTrunc(x) {
    var with2Decimals = x.toString().match(/^-?\d+(?:\.\d{0,2})?/)[0];
    return with2Decimals;
  }

  function calculateValue(selector, multiplier) {
    // Starting variables
    var applied_aptc_total = $('#aptc_applied_total').val();
    var total_premium_value = document.getElementById("enrollment_total_premium").innerHTML;
    var total_premium = toFixedTrunc(parseFloat(total_premium_value));
    // Percentage of max aptc available that user wishes to apply
    var percent = Math.round(parseFloat($(selector).val()).toFixed(2) * multiplier);
    // Max available tax credit per month for month
    var max_aptc_available = document.getElementById("max_aptc_available").innerHTML;
    var aptc_total_cash_amount_to_apply = toFixedTrunc(max_aptc_available * (percent / 100))
    // Update the percentage
    $('#aptc_applied_pct_1_percent').val(percent + '%');
    // Update the view to reflect the total cash to be applied
    $('#aptc_applied_total').val("$" + aptc_total_cash_amount_to_apply);
    // Show dollar amount of Tax Credit value
    var new_premium = (total_premium - aptc_total_cash_amount_to_apply);
    $('#new-premium').html(toFixedTrunc(new_premium.toFixed(8)));
  }

});
