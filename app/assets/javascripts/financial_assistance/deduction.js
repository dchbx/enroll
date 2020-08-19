function stopEditingDeduction() {
  $('.driver-question, .instruction-row, .deduction-kind').removeClass('disabled');
  $('input#deduction_kind').prop('disabled', false);
  $('a.deduction-edit').removeClass('disabled');
  $('.col-md-3 > .interaction-click-control-continue').removeClass('disabled');
};

function startEditingDeduction(deduction_kind) {
  $('.driver-question, .instruction-row, .deduction-kind:not(#' + deduction_kind + ')').addClass('disabled');
  $('input#deduction_kind').prop('disabled', true);
  $('a.deduction-edit').addClass('disabled');
  $('.col-md-3 > .interaction-click-control-continue').addClass('disabled');
};

function currentlyEditing() {
  return $('.interaction-click-control-continue').hasClass('disabled');
};

$(document).ready(function() {
  if ($('.deduction-kinds').length) {
    $(window).bind('beforeunload', function(e) {
      if (!currentlyEditing() || $('#unsavedDeductionChangesWarning:visible').length)
        return undefined;

      (e || window.event).returnValue = 'You have an unsaved deduction, are you sure you want to proceed?'; //Gecko + IE
      return 'You have an unsaved deduction, are you sure you want to proceed?';
    });

    /* Saving Responses to Deduction  Driver Questions */
    $('#has_deductions_true, #has_deductions_false').on('change', function(e) {
      var attributes = {};
      attributes[$(this).attr('name')] = $(this).val();
      $.ajax({
        type: 'POST',
        url: window.location.pathname.replace('/deductions', ''),
        data: { financial_assistance_applicant: attributes },
        success: function(response){
        }
      })
    });

    $(document).on('click', 'a[href]:not(.disabled)', function(e) {
      if (currentlyEditing()) {
        e.preventDefault();
        var self = this;

        $('#unsavedDeductionChangesWarning').modal('show');
        $('.btn.btn-danger').click(function() {
          window.location.href = $(self).attr('href');
        });

        return false;
      } else
      return true;
    });

    if (!$('#has_deductions_true').is(':checked')) $('.deduction-kinds').addClass('hidden');

    $("#has_deductions_true").change(function(e) {
      if ($(this).is(':checked')) $('.deduction-kinds').removeClass('hidden');
    });

    $("#has_deductions_false").change(function(e) {
      if ($(this).is(':checked')) $('.deduction-kinds').addClass('hidden');
    });

    $('.deduction-kinds').on('click', 'input[type="checkbox"]', function(e) {
      var value = e.target.checked,
          self = this;
      if (value) {
        var newDeductionFormEl = $(this).parents('.deduction-kind').children('.new-deduction-form'),
            deductionListEl = $(this).parents('.deduction-kind').find('.deductions-list');
        if (newDeductionFormEl.find('select').data('selectric')) newDeductionFormEl.find('select').selectric('destroy');
        var clonedForm = newDeductionFormEl.clone(true, true)
          .removeClass('hidden')
          .appendTo(deductionListEl);
        startEditingDeduction($(this).parents('.deduction-kind').attr('id'));
        $(clonedForm).find('select').selectric();
        $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
        e.stopImmediatePropagation();
      } else {
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllDeductions").modal();
        var deduction_kind_name = $(this).val().replace(/_/g, ' ');
        deduction_kind_name = deduction_kind_name.charAt(0).toUpperCase() + deduction_kind_name.slice(1);
        $('#deduction_kind_modal').text(deduction_kind_name);
        $("#destroyAllDeductions .modal-cancel-button").click(function(e) {
          $("#destroyAllDeductions").modal('hide');
        });

        $("#destroyAllDeductions .modal-continue-button").click(function(e) {
          $("#destroyAllDeductions").modal('hide');
          stopEditingDeduction();
          $(self).prop('checked', false);
          $(self).parents('.deduction-kind').find('.deductions-list > .new-deduction-form').remove();

          $(self).parents('.deduction-kind').find('.deductions-list > .deduction').each(function(i, deduction) {
            var url = $(deduction).attr('id').replace('financial_assistance_deduction_', 'deductions/');
            $(deduction).remove();

            $.ajax({
              type: 'DELETE',
              url: url
            });
          });
        });
      }
    });

    $(document).on('click', "#add_new_deduction_kind", function(e) {
      $(this).addClass("hidden");
      var newDeductionFormEl = $(this).closest('.deduction-kind').children('.new-deduction-form'),
          deductionListEl = $(this).closest('.deduction-kind').find('.deductions-list');
      if (newDeductionFormEl.find('select').data('selectric')) newDeductionFormEl.find('select').selectric('destroy');
      var clonedForm = newDeductionFormEl.clone(true, true)
          .removeClass('hidden')
          .appendTo(deductionListEl);
      startEditingDeduction($(this).parents('.deduction-kind').attr('id'));
      $(clonedForm).find('select').selectric();
      $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
      e.stopImmediatePropagation();
    });

    /* edit existing deductions */
    $('.deduction-kinds').on('click', 'a.deduction-edit:not(.disabled)', function(e) {
      e.preventDefault();
      var deductionEl = $(this).parents('.deduction');
      deductionEl.find('.deduction-show').addClass('hidden');
      deductionEl.find('.edit-deduction-form').removeClass('hidden');
      startEditingDeduction($(this).parents('.deduction-kind').attr('id'));

      $(deductionEl).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
    });

    /* destroy existing deducitons */
    $('.deduction-kinds').on('click', 'a.deduction-delete:not(.disabled)', function(e) {
      var self = this;
      e.preventDefault();
      $("#destroyDeduction").modal();

      $("#destroyDeduction .modal-cancel-button").click(function(e) {
        $("#destroyDeduction").modal('hide');
      });

      $("#destroyDeduction .modal-continue-button").click(function(e) {
        $("#destroyDeduction").modal('hide');
        $(self).parents('.deduction').remove();

        var url = $(self).parents('.deduction').attr('id').replace('financial_assistance_deduction_', 'deductions/');
        $.ajax({
          type: 'DELETE',
          url: url
        })
      });
    });

    /* DELETING all Deductions on selcting 'no' on Driver Question */
    $('#has_deductions_false').on('change', function(e) {
      self = this;
      //$('#DestroyExistingJobIncomesWarning').modal('show');
      if ($('.deductions-list .deduction').length) {
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllDeductions").modal();

        $("#destroyAllDeductions .modal-cancel-button").click(function(e) {
          $("#destroyAllDeductions").modal('hide');
          $('#has_deductions_true').prop('checked', true).trigger('change');
        });

        $("#destroyAllDeductions .modal-continue-button").click(function(e) {
          $("#destroyAllDeductions").modal('hide');
          //$(self).prop('checked', false);

          $('.deductions-list > .deduction').each(function(i, deduction) {
            var url = $(deduction).attr('id').replace('financial_assistance_deduction_', 'deductions/');
            $(deduction).remove();
            $.ajax({
              type: 'DELETE',
              url: url
            });
          });
        });
      }
    });

    /* cancel benefit edits */
    $('.deduction-kinds').on('click', 'a.deduction-cancel', function(e) {
      e.preventDefault();
      stopEditingDeduction();

      var benefitEl = $(this).parents('.deduction');
      if (benefitEl.length) {
        $(this).closest('.deduction-kind').find('a#add_new_deduction_kind').removeClass("hidden");
        benefitEl.find('.deduction-show').removeClass('hidden');
        benefitEl.find('.edit-deduction-form').addClass('hidden');
      } else {
        if (!$(this).parents('.deductions-list').find('div.deduction').length) {
          $(this).parents('.deduction-kind').find('input[type="checkbox"]').prop('checked', false);
        } else {
          $(this).parents('.deduction-kind').find('a#add_new_deduction_kind').removeClass("hidden");
        }

        $(this).parents('.new-deduction-form').remove();
      }
    });
  }
});
