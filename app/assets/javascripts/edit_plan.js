$(document).on("ready ajax:success", function() {

  $("#agreement_action-confirm-yes").click(function(){
    $(".interaction-click-control-action-confirm").attr("disabled", false);
    $("#action-confirm-date").attr("hidden", false);
  });
  $("#agreement_action-confirm-no").click(function(){
    $(".interaction-click-control-action-confirm").attr("disabled", true);
    $("#action-confirm-date").attr("hidden", true);
  });

  $('#cancel-button').click(function(e){
    e.preventDefault();
    $('.confirmation').addClass('hidden');
    $('#action-confirm').removeClass('hidden');
    $('.action-msg').addClass('hidden');
    $('#cancel-msg').removeClass('hidden');
    $('#cancel-form').removeClass('hidden');
    $('#calendar-div').addClass('hidden');
    $('#applied-aptc-text').addClass('hidden');
  });

  // Mockup temporarily disabled
  // $('#aptc-button').click(function(e){
  //   e.preventDefault();
  //   $('.confirmation').addClass('hidden');
  //   $('#action-confirm').removeClass('hidden');
  //   $('.action-msg').addClass('hidden');
  //   $('#aptc-msg').removeClass('hidden');
  //   $('#calendar-div').removeClass('hidden');
  //   $('#enter-text').addClass('hidden');
  //   $('#aptc_date').val('07/01/2019');
  //   $('#applied-aptc-text').removeClass('hidden');
  //   $('#cancel-form').addClass('hidden');
  // });


  // APTC JS
  $('#applied_pct_1').change(function(){
    calculatePercent('#applied_pct_1', 100);
  });
  $('#aptc_applied_5cf6c9ec9ee4f43836000020').change(function(){
    calculatePercent('#aptc_applied_5cf6c9ec9ee4f43836000020', 1);
  });

  //
  function calculatePercent(selector, multiplier) {
    var percent = parseFloat($(selector).val()).toFixed(2) * multiplier;
    $('#aptc_applied_pct_1_percent').val(percent + '%');
    $('#aptc_applied_5cf6c9ec9ee4f43836000020').val(percent);
    var new_premium = (377.28 - parseFloat($('#aptc_applied_5cf6c9ec9ee4f43836000020').val()).toFixed(2)).toFixed(2);
    $('#new-premium').html(new_premium);
  }

});
