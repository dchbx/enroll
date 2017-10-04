
$(document).ready(function() {
 setGroupSelectionHandlers();
});

function setGroupSelectionHandlers(){
  $('.group-selection-table .dental input').prop('checked', false);
  var employers = $("[id^=census_employee_]");

  if($('#market_kinds').length) {

    if ( $('#market_kind_individual').is(':checked') ) {
      $('#shop-coverage-household input').removeProp('checked');
      $('#market_kind_individual').prop("checked", true);
      $('#dental-radio-button').show();
      disableEmployerSelection();
    }
    $('#market_kind_individual').on('change', function() {
      disableEmployerSelection();

      $('#dental-radio-button').slideDown();
      $('#ivl-coverage-household').show();
      $('#shop-coverage-household').hide();
      $('#shop-coverage-household input').removeProp('checked');
      $('#ivl-coverage-household tr').not(".ineligible_row").find('input').prop('checked', 'checked');

    });

    $('#market_kind_shop').on('change', function() {
      employers.each( function() {
        $(this).prop("disabled", false);
        if($(this).hasClass('selected_employer')) {
          $(this).prop("checked", true);
          $(this).removeClass('selected_employer');
          setDentalBenefits($(this).attr('dental_benefits'));
        }
      });

      $("#coverage_kind_health").prop("checked", true);
      $('#shop-coverage-household').show();
      $('#ivl-coverage-household').hide();
      $('#ivl-coverage-household input').removeProp('checked');

      if ($('#coverage_kind_health').is(':checked')) {
        $('#shop-coverage-household .health tr').not(".ineligible_row").find('input').prop('checked', 'checked');
      }
      if ($('#coverage_kind_dental').is(':checked')) {
        $('#shop-coverage-household .dental tr').not(".ineligible_row").find('input').prop('checked', 'checked');
      }
    });
  }

  if ( ($('#market_kind_shop').length && $('#market_kind_shop').is(':checked')) || (!($('#market_kind_shop').length) && $('#shop-coverage-household').length) ) {
    // $("#coverage_kind_health").prop("checked", true);
    $("#ivl-coverage-household input[type=checkbox]").prop("checked", false);
    employers.each(function(){
      if($(this).is(":checked")){
        if($(this).attr('dental_benefits') == 'true'){
          $('#dental-radio-button').slideDown();
          $('#coverage_kind_health').on('change', function() {
            $('#shop-coverage-household .health').show();
            $('#shop-coverage-household .health tr').not(".ineligible_row").find('input').prop('checked', 'checked');
            $('#shop-coverage-household .dental').hide();
            $('#shop-coverage-household .dental input').removeProp('checked');
          });

          $('#coverage_kind_dental').on('change', function() {
            $('#shop-coverage-household .dental').show();
            $('#shop-coverage-household .dental tr').not(".ineligible_row").find('input').prop('checked', 'checked');
            $('#shop-coverage-household .health').hide();
            $('#shop-coverage-household .health input').removeProp('checked');
          });

        } else {
          $('#dental-radio-button').slideUp();
        }
      }
    })
  }

  employers.on("change", function(){
    $("#coverage_kind_health").prop("checked", true);
    if($(this).is(":checked")){
      setDentalBenefits($(this).attr('dental_benefits'));
    }
  })

  $("input[type='checkbox']").change(function() {
    if ($("#coverage_kind_health").is(":checked")){
      if($(this).is(":checked")) {
        $(this).attr( "checked", true );
      }else{
        $(this).removeProp('checked');
        $('#shop-coverage-household .dental input').removeProp('checked');
        }
      }
  });
}

function disableEmployerSelection(){
  var employers = $("[id^=census_employee_]");
  employers.each( function() {
    if($(this).is(":checked")) {
      $(this).addClass('selected_employer');
    }
    $(this).prop("disabled", true);
    $(this).prop("checked", false);
  });
}

function setDentalBenefits(dental_benefits){
  if(dental_benefits == 'true'){
    $('#dental-radio-button').slideDown();
  } else {
    $('#dental-radio-button').slideUp();
  }
}

$(function(){
  if ( $("#find_sep_link").length ) {
    $("#find_sep_link").click(function() {
      $(this).closest('form').attr('action', '<%= find_sep_insured_families_path %>');
      $(this).closest('form').attr('method', 'get');
      $(this).closest('form').submit();
    });
  }
})
