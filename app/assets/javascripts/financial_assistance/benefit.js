function stopEditingBenefit() {
  $('.driver-question, .instruction-row, .benefit-kind').removeClass('disabled');
  $('input.benefit-checkbox').prop('disabled', false);
  $('a.benefit-edit').removeClass('disabled');
  // $('a.benefit-delete').removeClass('disabled');
  $('.col-md-3 > .interaction-click-control-continue').removeClass('disabled');
};

function startEditingBenefit(benefit_kind) {
  $('.driver-question, .instruction-row, .benefit-kind:not(#' + benefit_kind + ')').addClass('disabled');
  $('input.benefit-checkbox').prop('disabled', true);
  $('a.benefit-edit').addClass('disabled');
  // $('a.benefit-delete').removeClass('disabled');
  $('.col-md-3 > .interaction-click-control-continue').addClass('disabled');
};

function currentlyEditing() {
  return $('.interaction-click-control-continue').hasClass('disabled');
};

function afterDestroyHide(selector_id, kind){
  $(".benefits #"+selector_id+" input[type='checkbox'][value='"+kind+"']").prop('checked', false);
  $(".benefits #"+selector_id+" .add-more-link-"+kind).addClass('hidden');
};

$(document).ready(function() {
  if ($('.benefit-kinds').length) {
    $(window).bind('beforeunload', function(e) {
      if (!currentlyEditing() || $('#unsavedBenefitChangesWarning:visible').length)
        return undefined;

      (e || window.event).returnValue = 'You have an unsaved benefit, are you sure you want to proceed?'; //Gecko + IE
      return 'You have an unsaved benefit, are you sure you want to proceed?';
    });

    $(document).on('click', 'a[href]:not(.disabled):not(.benefit-support-modal)', function(e) {
      if (currentlyEditing()) {
        e.preventDefault();
        var self = this;

        $('#unsavedBenefitChangesWarning').modal('show');
        $('.btn.btn-danger').click(function() {
          window.location.href = $(self).attr('href');
        });

        return false;
      } else
      return true;
    });

    $(document).on('click', 'input[type="checkbox"]', function(e) {
      var value = e.target.checked,
          self = this;
      if (value) {
        var newBenefitFormEl = $(this).parents('.benefit-kind').children('.new-benefit-form'),
            benefitListEl = $(this).parents('.benefit-kind').find('.benefits-list');
        if (newBenefitFormEl.find('select').data('selectric')) newBenefitFormEl.find('select').selectric('destroy');
        var clonedForm = newBenefitFormEl.clone(true, true)
          .removeClass('hidden')
          .appendTo(benefitListEl);
        startEditingBenefit($(this).parents('.benefit-kind').attr('id'));
        $(clonedForm).find('select').selectric();
        $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
        e.stopImmediatePropagation();
      } else {
        // prompt to delete all these benefits
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllBenefits").modal();

        $("#destroyAllBenefits .modal-cancel-button").click(function(e) {
          $("#destroyAllBenefits").modal('hide');
        });

        $("#destroyAllBenefits .modal-continue-button").click(function(e) {
          $("#destroyAllBenefits").modal('hide');
          $(self).prop('checked', false);

          $(self).parents('.benefit-kind').find('.benefits-list > .benefit').each(function(i, benefit) {
            var url = $(benefit).attr('id').replace('financial_assistance_benefit_', 'benefits/');
            $(benefit).remove();

            $.ajax({
              type: 'DELETE',
              url: url
            });
          });
        });
      }
    });

    /* Add more benefits */
    $(document).on('click', "#add_new_insurance_kind", function(e){
        $(this).addClass("hidden");
        var newBenefitFormEl = $(this).closest('.benefit-kind').children('.new-benefit-form'),
          benefitListEl = $(this).closest('.benefit-kind').find('.benefits-list');
        if (newBenefitFormEl.find('select').data('selectric')) newBenefitFormEl.find('select').selectric('destroy');
        var clonedForm = newBenefitFormEl.clone(true, true)
          .removeClass('hidden')
          .appendTo(benefitListEl);
          startEditingBenefit($(this).parents('.benefit-kind').attr('id'));
        $(clonedForm).find('select').selectric();
        $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
        e.stopImmediatePropagation();
    });

    /* edit existing benefits */
    $('.benefit-kinds').on('click', 'a.benefit-edit:not(.disabled)', function(e) {
      e.preventDefault();
      var benefitEl = $(this).parents('.benefit');
      benefitEl.find('.benefit-show').addClass('hidden');
      benefitEl.find('.edit-benefit-form').removeClass('hidden');
      benefitEl.find('select').selectric();
      $(benefitEl).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
      startEditingBenefit($(this).parents('.benefit-kind').attr('id'));
    });


    /* destroy existing benefits */
    $('.benefit-kinds').on('click', 'a.benefit-delete:not(.disabled)', function(e) {
      var self = this;
      e.preventDefault();
      $("#destroyBenefit").modal();

      $("#destroyBenefit .modal-cancel-button").click(function(e) {
        $("#destroyBenefit").modal('hide');
      });

      $("#destroyBenefit .modal-continue-button").click(function(e) {
        $("#destroyBenefit").modal('hide');
        $(self).parents('.benefit').remove();

        var url = $(self).parents('.benefit').attr('id').replace('financial_assistance_benefit_', 'benefits/')
        $.ajax({
          type: 'delete',
          url: url
        })
      });
    });

    /* DELETING all enrolled benefits on selcting 'no' on Driver Question */
    $('#has_enrolled_health_coverage_false').on('change', function(e) {
      self = this;
      //$('#DestroyExistingJobIncomesWarning').modal('show');
      if ($('.benefits-list.is_enrolled .benefit').length) {
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllBenefits").modal();

        $("#destroyAllBenefits .modal-cancel-button").click(function(e) {
          $("#destroyAllBenefits").modal('hide');
          $('#has_enrolled_health_coverage_true').prop('checked', true).trigger('change');
        });

        $("#destroyAllBenefits .modal-continue-button").click(function(e) {
          $("#destroyAllBenefits").modal('hide');
          //$(self).prop('checked', false);

          $('.benefits-list.is_enrolled .benefit').each(function(i, benefit) {
            var url = $(benefit).attr('id').replace('financial_assistance_benefit_', 'benefits/');
            $(benefit).remove();
            $.ajax({
              type: 'DELETE',
              url: url
            });
          });
        });
      }
    });

    /* DELETING all enrolled benefits on selcting 'no' on Driver Question */
    $('#has_eligible_health_coverage_false').on('change', function(e) {
      self = this;
      if ($('.benefits-list.is_eligible .benefit').length) {
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllBenefits").modal();

        $("#destroyAllBenefits .modal-cancel-button").click(function(e) {
          $("#destroyAllBenefits").modal('hide');
          $('#has_eligible_health_coverage_true').prop('checked', true).trigger('change');
        });

        $("#destroyAllBenefits .modal-continue-button").click(function(e) {
          $("#destroyAllBenefits").modal('hide');
          //$(self).prop('checked', false);

          $('.benefits-list.is_eligible .benefit').each(function(i, benefit) {
            var url = $(benefit).attr('id').replace('financial_assistance_benefit_', 'benefits/');
            $(benefit).remove();
            $.ajax({
              type: 'DELETE',
              url: url
            });
          });
        });
      }
    });
    /* cancel benefit edits */
    $('.benefit-kinds').on('click', 'a.benefit-cancel', function(e) {
      e.preventDefault();
      stopEditingBenefit();

      var benefitEl = $(this).parents('.benefit');
      if (benefitEl.length) {
        $(this).closest('.benefit-kind').find('a#add_new_insurance_kind').removeClass("hidden");
        benefitEl.find('.benefit-show').removeClass('hidden');
        benefitEl.find('.edit-benefit-form').addClass('hidden');
      } else {
        if (!$(this).parents('.benefits-list').find('div.benefit').length) {
          $(this).parents('.benefit-kind').find('input[type="checkbox"]').prop('checked', false);
          $(this).closest('.benefit-kind').find('a#add_new_insurance_kind').addClass("hidden");
        }else{
          $(this).closest('.benefit-kind').find('a#add_new_insurance_kind').removeClass("hidden");
        }
        $(this).parents('.new-benefit-form').remove();
        $(this).parents('.edit-benefit-form').remove();
      }
    });

    /* Condtional Display Enrolled Benefit Questions */
    if (!$("#has_enrolled_health_coverage_true").is(':checked')) $("#enrolled-benefit-kinds").addClass('hide');
    /* Condtional Display Eligible Benefit Questions */
    if (!$("#has_eligible_health_coverage_true").is(':checked')) $("#eligible-benefit-kinds").addClass('hide');

    $("body").on("change", "#has_enrolled_health_coverage_true", function(){
      if ($('#has_enrolled_health_coverage_true').is(':checked')) {
        $("#enrolled-benefit-kinds").removeClass('hide');
      } else{
        $("#enrolled-benefit-kinds").addClass('hide');
      }
    });

    $("body").on("change", "#has_enrolled_health_coverage_false", function(){
      if ($('#has_enrolled_health_coverage_false').is(':checked')) {
        $("#enrolled-benefit-kinds").addClass('hide');
      } else{
        $("#enrolled-benefit-kinds").removeClass('hide');
      }
    });

    $("body").on("change", "#has_eligible_health_coverage_true", function(){
      if ($('#has_eligible_health_coverage_true').is(':checked')) {
        $("#eligible-benefit-kinds").removeClass('hide');
      } else{
        $("#eligible-benefit-kinds").addClass('hide');
      }
    });

    $("body").on("change", "#has_eligible_health_coverage_false", function(){
      if ($('#has_eligible_health_coverage_false').is(':checked')) {
        $("#eligible-benefit-kinds").addClass('hide');
      } else{
        $("#eligible-benefit-kinds").removeClass('hide');
      }
    });

    /* Saving Responses to Income  Driver Questions */
    $('#has_enrolled_health_coverage_false, #has_eligible_health_coverage_false, #has_enrolled_health_coverage_true, #has_eligible_health_coverage_true').on('change', function(e) {
      var attributes = {};
      attributes[$(this).attr('name')] = $(this).val();
      $.ajax({
        type: 'POST',
        url: window.location.pathname.replace('/benefits', ''),
        data: { financial_assistance_applicant: attributes },
        success: function(response){
        }
      })
    });
  }
    $('body').on('keyup keydown keypress', '#financial_assistance_benefit_employer_phone_full_phone_number', function (e) {
        $(this).mask('(000) 000-0000');
        return (key == 8 ||
            key == 9 ||
            key == 46 ||
            (key >= 37 && key <= 40) ||
            (key >= 48 && key <= 57) ||
            (key >= 96 && key <= 105) );

    });

    $('body').on('keyup keydown keypress', '#financial_assistance_benefit_employer_address_zip', function (e) {
        var key = e.which || e.keyCode || e.charCode;
        $(this).attr('maxlength', '5');
        return (key == 8 ||
            key == 9 ||
            key == 46 ||
            (key >= 37 && key <= 40) ||
            (key >= 48 && key <= 57) ||
            (key >= 96 && key <= 105) );
    });

    $('body').on('keyup keydown keypress', '#financial_assistance_benefit_employer_id', function (e) {
        var key = e.which || e.keyCode || e.charCode;
        $(this).mask("00-0000000");
        return (key == 8 ||
            key == 9 ||
            key == 46 ||
            (key >= 37 && key <= 40) ||
            (key >= 48 && key <= 57) ||
            (key >= 96 && key <= 105) );

    });
    
});

