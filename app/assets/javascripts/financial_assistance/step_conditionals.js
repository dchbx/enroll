$(document).ready(function() {
  $('.step-tabs, .interaction-click-control-my-household').on('click', function(e) {
    //Leave without saving for all side nav items - this gathers all items 
    $('.btn.btn-primary').click(function() {
        window.location.href = e.target.href;
      });
  });

  /* attestations */
  $('#living_outside_yes, #living_outside_no').change(function(e) {
    $('#application_attestation_terms').attr('required', e.target.value == 'true');
  });

  if ($('#medicaid_pregnency_yes').length) {
    $.ajax({
      type: "GET",
      data:{},
      url: window.location.href.replace(/other_questions/, "age_of_applicant"),
      success: function (age) {
        hide_show_foster_care_related_qns(age);
      }
    });
  }

  // To hide/show the foster care related questions based on the age_of_applicant.
  function hide_show_foster_care_related_qns(age) {
    if ($('#is_pregnant_yes')) {
      if (age > 18 && age < 26){
        $('#is_former_foster_care_yes').parents('.row-form-wrapper').removeClass('hide');
      } else {
        $('#is_former_foster_care_yes').parents('.row-form-wrapper').addClass('hide');
        $('#foster_care_us_state, #age_left_foster_care, #had_medicaid_during_foster_care_yes').parents('.row-form-wrapper').addClass('hide');
        $('#is_former_foster_care_yes, #is_former_foster_care_no').prop('required', false);
        $('#had_medicaid_during_foster_care_yes, #had_medicaid_during_foster_care_no').prop('required', false);
      }
      if (age == 18 || age == 19){
        $('#is_student_yes').parents('.row-form-wrapper').removeClass('hide');
      } else {
        $('#is_student_yes').parents('.row-form-wrapper').addClass('hide');
        $('#student_kind, #applicant_student_status_end_on, #student_school_kind').parents('.row-form-wrapper').addClass('hide');
      }
    }
  }

  function hide_show_person_flling_jointly_question(){
    $.ajax({
      type: "GET",
      data:{},
      url: window.location.href.replace(/step(\/1)?/, 'primary_applicant_has_spouse'),
      success: function (has_spouse) {
        if(has_spouse == 'true'){
          $('#is_joint_tax_filing_no').parents('.row-form-wrapper').removeClass('hide');
        }
      }
    });
  }

  $('#income_kind').on('selectric-change', function(e){
    if ($(this).val() == 'wages_and_salaries')
      toggle_employer_contact_divs('show');
    else
      toggle_employer_contact_divs('hide');
  });

  if ($('#income_kind').val() == 'wages_and_salaries'){
    toggle_employer_contact_divs('show');
  } else {
    toggle_employer_contact_divs('hide');
  }


  function toggle_employer_contact_divs(hide_show) {
    if (hide_show == 'hide') {
      $('#income_kind').parents(".row").next().next().addClass('hide');
      $('#income_kind').parents(".row").next().next().next().addClass('hide');
      $('#income_kind').parents(".row").next().next().next().next().addClass('hide');
    } else {
      $('#income_kind').parents(".row").next().next().removeClass('hide');
      $('#income_kind').parents(".row").next().next().next().removeClass('hide');
      $('#income_kind').parents(".row").next().next().next().next().removeClass('hide');
    }
  }

  // Clear 0 value for Income
  if ($("#income_amount").val() == 0){
   $("#income_amount").val("");
  }

  $("body").on("change", "#is_required_to_file_taxes_no", function(){
    if ($('#is_required_to_file_taxes_no').is(':checked')) {
      $('#is_joint_tax_filing_no').parents('.row-form-wrapper').addClass('hide');
    } else{
      $('#is_claimed_as_tax_dependent_no').parents('.row-form-wrapper').removeClass('hide');
    }
  });

  $("body").on("change", "#is_required_to_file_taxes_yes", function(){
    if ($('#is_required_to_file_taxes_yes').is(':checked')) {
      hide_show_person_flling_jointly_question();
    } else{
      $('#is_claimed_as_tax_dependent_no').parents('.row-form-wrapper').addClass('hide');
    }
  });

  $('#is_claimed_as_tax_dependent_no').parents(".row").next().addClass('hide');

  $("body").on("change", "#is_claimed_as_tax_dependent_no", function(){
    if ($('#is_claimed_as_tax_dependent_no').is(':checked')) {
      $(this).parents(".row").next().addClass('hide');
    } else{
      $(this).parents(".row").next().next().removeClass('hide');
    }
  });

  $("body").on("change", "#is_claimed_as_tax_dependent_yes", function(){
    if ($('#is_claimed_as_tax_dependent_yes').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
    } else{
      $(this).parents(".row").next().next().addClass('hide');
    }
  });

  /* Benefit Form Related */

  /* employer phone & zip validations */
  $('#employer_phone_full_phone_number').on('keyup keydown keypress', function (e) {
    var key = e.which || e.keyCode || e.charCode;
    $(this).attr('maxlength', '10');
    return (key == 8 ||
      key == 9 ||
      key == 46 ||
      (key >= 37 && key <= 40) ||
      (key >= 48 && key <= 57) ||
      (key >= 96 && key <= 105) );
  })

  .on('focus', function () {
    $(this).val($(this).val().replace(/\W+/g, ''));
  })

  .on('blur', function () {
    $(this).val($(this).val().replace(/^(\d{3})(\d{3})(\d{4})+$/, "($1) $2-$3"));
  });

  $("#employer_address_zip").mask("99999");
  /* employer phone & zip validations */


  /* Toggle Show/Hide of  dates row when eligible/ enrolled types are selected */
  $("#is_eligible, #is_enrolled").on('change', function() {
    if ($('#is_eligible').is(':checked')) {
      $('#is_eligible').parents(".row").next().addClass('hide');
      $('#is_eligible').parents(".row").next().removeClass('show');
    } else {
      $('#is_eligible').parents(".row").next().addClass('show');
      $('#is_eligible').parents(".row").next().removeClass('hide');
    }
  });


  $('#benefit_insurance_kind').on('selectric-change', function(e){
    if ($(this).val() == 'employer_sponsored_insurance') {
      toggle_employer_contact_divs_benefit('show');
    } else {
      toggle_employer_contact_divs_benefit('hide');
    }
  });
  /* This is to show/hide ESI fields on Page Load. Will show ESI related
   * fields if InsuranceKind is selected as 'employer_sponsored_insurance'
   * when page loads (possible on a page reload due to validation error) */

  var selectedVal = $('#benefit_insurance_kind').val();
  if (selectedVal == 'employer_sponsored_insurance') {
    setTimeout(function() {
      toggle_employer_contact_divs_benefit('show');
    },300);
  } else {
    setTimeout(function() {
      toggle_employer_contact_divs_benefit('hide');
    },300);
  };

  function toggle_employer_contact_divs_benefit(hide_show) {
    if (hide_show == 'show') {
      $('#benefit_insurance_kind').parents(".row").next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().next().next().removeClass('hide');
    } else {
      $('#benefit_insurance_kind').parents(".row").next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().next().next().addClass('hide');
    }
  }
  /* Benefit Form Related */

  /* Submit Application Form Related */

  $('#living_outside_yes').parents(".row").next().addClass('hide');
  $('#living_outside_yes').parents(".row").next().next().addClass('hide');

  $("body").on("change", "#living_outside_no", function(){
    if ($('#living_outside_no').is(':checked')) {
      $(this).parents(".row").next().addClass('hide');
      $(this).parents(".row").next().next().addClass('hide');
    };
  });

  $("body").on("change", "#living_outside_yes", function(){
    if ($('#living_outside_yes').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
      $(this).parents(".row").next().next().removeClass('hide');
    };
  });

  // On Load, hide by default if checked no
  if($('#living_outside_no').is(':checked')) {
    $('#living_outside_no').parents(".row").next().addClass('hide');
    $('#living_outside_no').parents(".row").next().next().addClass('hide');
  }

  if($('#living_outside_yes').is(':checked')) {
    $('#living_outside_yes').parents(".row").next().removeClass('hide');
  }
  /* Submit Application Form Related */


  /* Preference Application Form Related */

  // On Load, hide by default if checked
  if ($('#eligibility_easier_yes').is(':checked')) {
      $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
      $('#eligibility_easier_yes').parents(".row").next().next().addClass('hide');
  };

  $("body").on("change", "#eligibility_easier_yes", function(){
    if ($('#eligibility_easier_yes').is(':checked')) {
      $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
      $('#eligibility_easier_yes').parents(".row").next().next().addClass('hide');
    };
  });

  $("body").on("change", "#eligibility_easier_no", function(){
    if ($('#eligibility_easier_no').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
      $(this).parents(".row").next().next().removeClass('hide');
    };
  });

  if($('#eligibility_easier_yes').is(':checked')) {
    $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
  }

  if($('#eligibility_easier_no').is(':checked')) {
    $('#eligibility_easier_no').parents(".row").next().removeClass('hide');
  }

/* Applicant's Tax Info Form Related */

  $('#is_joint_tax_filing_yes').parents('.row-form-wrapper').addClass('hide');

  if($('#is_required_to_file_taxes_no').is(':checked')) {
    $('#is_joint_tax_filing_yes').parents('.row-form-wrapper').addClass('hide');
  }

  if($('#is_required_to_file_taxes_yes').is(':checked')) {
    hide_show_person_flling_jointly_question();
  }

  if($('#is_claimed_as_tax_dependent_no').is(':checked')) {
    $('#is_claimed_as_tax_dependent_no').parents(".row").next().addClass('hide');
  }

  if($('#is_claimed_as_tax_dependent_yes').is(':checked')) {
    $('#is_claimed_as_tax_dependent_yes').parents(".row").next().removeClass('hide');
  }

  $("#is_required_to_file_taxes_yes, #is_required_to_file_taxes_no, #is_claimed_as_tax_dependent_yes, #is_claimed_as_tax_dependent_no").on('change', function() {
    if( $('.interaction-click-control-tax-info').parent('li').hasClass('active') && ($('#is_required_to_file_taxes_yes, #is_required_to_file_taxes_no').is(':checked') && $('#is_claimed_as_tax_dependent_yes, #is_claimed_as_tax_dependent_no').is(':checked'))){
     $('.interaction-click-control-continue').prop('disabled', false)
   }
 });
/* Applicant's Tax Info Form Related */

$(document).ready(function(){
  if( $('.interaction-click-control-tax-info').parent('li').hasClass('active') && ($('#is_required_to_file_taxes_yes, #is_required_to_file_taxes_no').is(':checked') && $('#is_claimed_as_tax_dependent_yes, #is_claimed_as_tax_dependent_no').is(':checked'))){
   $('.interaction-click-control-continue').prop('disabled', false)
 }
})

/* Applicant's Other Questions Form Related */

  if ($('#is_ssn_applied_yes').is(':checked')) {
    $('#no_ssn_reason').parents('.row-form-wrapper').addClass('hide');
  } else {
    $('#no_ssn_reason').parents('.row-form-wrapper').addClass('hide');
  }

  $("body").on("change", "#is_ssn_applied_yes", function(){
    if ($('#is_ssn_applied_yes').is(':checked')) {
      $('#no_ssn_reason').parents('.row-form-wrapper').addClass('hide');
    };
  });

  if ($('#is_ssn_applied_no').is(':checked')) {
    $('#no_ssn_reason').parents('.row-form-wrapper').removeClass('hide');
  } else {
    $('#no_ssn_reason').parents('.row-form-wrapper').addClass('hide');
  }

  $("body").on("change", "#is_ssn_applied_no", function(){
    if ($('#is_ssn_applied_no').is(':checked')) {
      $('#no_ssn_reason').parents('.row-form-wrapper').removeClass('hide');
    };
  });

  $('#applicant_pregnancy_end_on').parents('.row-form-wrapper').addClass('hide');

  $("body").on("change", "#is_pregnant_yes", function(){
    if ($('#is_pregnant_yes').is(':checked')) {
      $('#children_expected_count, #applicant_pregnancy_due_on').parents('.row-form-wrapper').removeClass('hide');
      $('#children_expected_count').selectric();
      $('#is_post_partum_period_yes, #applicant_pregnancy_end_on').parents('.row-form-wrapper').addClass('hide');
      $('#medicaid_pregnency_yes').parents('.row-form-wrapper').addClass('hide');
    };
  });

  if($('#is_pregnant_yes').is(':checked')) {
    $('#children_expected_count, #applicant_pregnancy_due_on').parents('.row-form-wrapper').removeClass('hide');
    $('#medicaid_pregnency_yes').parents('.row-form-wrapper').addClass('hide');
  } else {
    $('#children_expected_count, #applicant_pregnancy_due_on').parents('.row-form-wrapper').addClass('hide');
    $('#medicaid_pregnency_yes').parents('.row-form-wrapper').addClass('hide');
  }

  $("body").on("change", "#is_pregnant_no", function(){
    if ($('#is_pregnant_no').is(':checked')) {
      $('#is_post_partum_period_yes').parents('.row-form-wrapper').removeClass('hide');
      $('#is_post_partum_period_yes, #is_post_partum_period_no').attr('checked', false);
      $('#children_expected_count, #applicant_pregnancy_due_on').parents('.row-form-wrapper').addClass('hide');
      $('#medicaid_pregnency_yes').parents('.row-form-wrapper').addClass('hide');
    };
  });

  if($('#is_pregnant_no').is(':checked')) {
    $('#is_post_partum_period_yes').parents('.row-form-wrapper').removeClass('hide');
    $('#medicaid_pregnency_yes').parents('.row-form-wrapper').addClass('hide');
  } else {
    $('#is_post_partum_period_yes').parents('.row-form-wrapper').addClass('hide');
    $('#medicaid_pregnency_yes').parents('.row-form-wrapper').addClass('hide');
  }

  if($('#is_post_partum_period_yes').is(':checked')) {
    $('#medicaid_pregnency_yes, #applicant_pregnancy_end_on').parents('.row-form-wrapper').removeClass('hide');
  }

  $("body").on("change", "#is_post_partum_period_yes", function(){
    if ($('#is_post_partum_period_yes').is(':checked')) {
      $('#medicaid_pregnency_yes, #applicant_pregnancy_end_on').parents('.row-form-wrapper').removeClass('hide');
    };
  });

  if($('#is_post_partum_period_no').is(':checked')) {
    $('#medicaid_pregnency_yes, #applicant_pregnancy_end_on').parents('.row-form-wrapper').addClass('hide');
  }

  $("body").on("change", "#is_post_partum_period_no", function(){
    if ($('#is_post_partum_period_no').is(':checked')) {
      $('#medicaid_pregnency_yes, #applicant_pregnancy_end_on').parents('.row-form-wrapper').addClass('hide');
    };
  });


  $("body").on("change", "#is_former_foster_care_no", function(){
    if ($('#is_former_foster_care_no').is(':checked')) {
      $('#foster_care_us_state, #age_left_foster_care, #had_medicaid_during_foster_care_yes').parents('.row-form-wrapper').addClass('hide');
      $('#had_medicaid_during_foster_care_yes, #had_medicaid_during_foster_care_no').prop('required', false);
    };
  });

  $("body").on("change", "#is_former_foster_care_yes", function(){
    if ($('#is_former_foster_care_yes').is(':checked')) {
      $('#foster_care_us_state, #age_left_foster_care, #had_medicaid_during_foster_care_yes').parents('.row-form-wrapper').removeClass('hide');
    };
  });

  if($('#is_former_foster_care_yes').is(':checked')) {
    $('#foster_care_us_state, #age_left_foster_care, #had_medicaid_during_foster_care_yes').parents('.row-form-wrapper').removeClass('hide');
  } else {
    $('#foster_care_us_state, #age_left_foster_care, #had_medicaid_during_foster_care_yes').parents('.row-form-wrapper').addClass('hide');
    $('#had_medicaid_during_foster_care_yes, #had_medicaid_during_foster_care_no').prop('required', false);
  }

  $("body").on("change", "#is_student_no", function(){
    if ($('#is_student_no').is(':checked')) {
      $('#student_kind, #applicant_student_status_end_on, #student_school_kind').parents('.row-form-wrapper').addClass('hide');
    };
  });

  $("body").on("change", "#is_student_yes", function(){
    if ($('#is_student_yes').is(':checked')) {
      $('#student_kind, #applicant_student_status_end_on, #student_school_kind').parents('.row-form-wrapper').removeClass('hide');
    };
  });

  if($('#is_student_yes').is(':checked')) {
    $('#student_kind, #applicant_student_status_end_on, #student_school_kind').parents('.row-form-wrapper').removeClass('hide');
  } else {
    $('#student_kind, #applicant_student_status_end_on, #student_school_kind').parents('.row-form-wrapper').addClass('hide');
  }


  if($('#is_veteran_or_active_military_yes').is(':checked')) {
    $('#is_vets_spouse_or_child_yes').parents('.row-form-wrapper').addClass('hide');
  } else {
    $('#is_vets_spouse_or_child_yes').parents('.row-form-wrapper').addClass('hide');
  }

  $("body").on("change", "#is_veteran_or_active_military_yes", function(){
    if ($('#is_veteran_or_active_military_yes').is(':checked')) {
      $('#is_vets_spouse_or_child_yes').parents('.row-form-wrapper').addClass('hide');
    };
  });

  if($('#is_veteran_or_active_military_no').is(':checked')) {
    $('#is_vets_spouse_or_child_yes').parents('.row-form-wrapper').removeClass('hide');
  } else {
    $('#is_vets_spouse_or_child_yes').parents('.row-form-wrapper').addClass('hide');
  }

  $("body").on("change", "#is_veteran_or_active_military_no", function(){
    if ($('#is_veteran_or_active_military_no').is(':checked')) {
      $('#is_vets_spouse_or_child_yes').parents('.row-form-wrapper').removeClass('hide');
    };
  });

/* Applicant's Other Questions Form Related */

  /* Submit Application Form Related */
  $("body").on("change", "#living_outside_no", function(){
    if ($('#living_outside_no').is(':checked')) {
      $(this).parents(".row").next().addClass('hide');
      $(this).parents(".row").next().next().addClass('hide');
    };
  });

  $("body").on("change", "#living_outside_yes", function(){
    if ($('#living_outside_yes').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
      $(this).parents(".row").next().next().removeClass('hide');
    };
  });

  // On Load, hide by default if checked no
  if($('#living_outside_no').is(':checked')) {
    $('#living_outside_no').parents(".row").next().addClass('hide');
    $('#living_outside_no').parents(".row").next().next().addClass('hide');
  }

  if($('#living_outside_yes').is(':checked')) {
    $('#living_outside_yes').parents(".row").next().removeClass('hide');
  }
  /* Submit Application Form Related */

  /* Preference Application Form Related */

  // On Load, hide by default if checked
  if ($('#eligibility_easier_yes').is(':checked')) {
      $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
      $('#eligibility_easier_yes').parents(".row").next().next().addClass('hide');
  };

  $("body").on("change", "#eligibility_easier_yes", function(){
    if ($('#eligibility_easier_yes').is(':checked')) {
      $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
      $('#eligibility_easier_yes').parents(".row").next().next().addClass('hide');
    };
  });

  $("body").on("change", "#eligibility_easier_no", function(){
    if ($('#eligibility_easier_no').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
      $(this).parents(".row").next().next().removeClass('hide');
    };
  });

  if($('#eligibility_easier_yes').is(':checked')) {
    $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
  }

  if($('#eligibility_easier_no').is(':checked')) {
    $('#eligibility_easier_no').parents(".row").next().removeClass('hide');
  }

  $("#mailed_yes, #mailed_no").on('change', function() {
    if( $('#mailed_yes, #mailed_no').is(':checked')){
      $('.interaction-click-control-continue').prop('disabled', false)
     }
  });

  /* Preference Application Form Related */

  /* enable or disable submit application button by electronic siganture (first/last name match)*/

  function enable_submit_button_by_electronic_signature() {
    first_name_thank_you = $("#first_name_thank_you").val() ? $("#first_name_thank_you").val().toString().toLowerCase().trim() : '';
    last_name_thank_you = $("#last_name_thank_you").val() ? $("#last_name_thank_you").val().toString().toLowerCase().trim() : '';
    subscriber_first_name = $("#subscriber_first_name").val();
    subscriber_last_name = $("#subscriber_last_name").val();

    if(last_name_thank_you == ""){
      $('.interaction-click-control-submit-application').addClass('disabled');
    }
    if( first_name_thank_you == subscriber_first_name && last_name_thank_you == subscriber_last_name){
      $('.interaction-click-control-submit-application').removeClass('disabled');
    } else {
      $('.interaction-click-control-submit-application').addClass('disabled');
    }
  }

  $(window).load(function() {
    if ($("#first_name_thank_you").length) enable_submit_button_by_electronic_signature();
  });

  $(document).on('blur keyup', 'input.thank_you_field', function() {
    enable_submit_button_by_electronic_signature();
  });

 /* enable or disable submit application button by electronic siganture (first/last name match)*/
});
