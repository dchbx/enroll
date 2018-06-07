function stopEditingIncome() {
  $('.driver-question, .instruction-row, .income, .other-income-kind').removeClass('disabled');
  $('a.new-income').removeClass('hide');
  $('a.income-edit').removeClass('disabled');
  $('.col-md-3 > .interaction-click-control-continue').removeClass('disabled');
  $("a.interaction-click-control-add-more").removeClass('hide');
  $('input.interaction-choice-control-value-other-income-kind').prop('disabled', false);
};

function startEditingIncome(income_kind) {
  $('.driver-question, .instruction-row, .income:not(#' + income_kind + '), .other-income-kind:not(#' + income_kind + ')').addClass('disabled');
  $('a.new-income').addClass('hide');
  $('a.income-edit').addClass('disabled');
  $('.col-md-3 > .interaction-click-control-continue').addClass('disabled');
  $("a.interaction-click-control-add-more").addClass('hide');
  $('input.interaction-choice-control-value-other-income-kind').prop('disabled', true);
};

function currentlyEditing() {
  return $('.interaction-click-control-continue').hasClass('disabled');
};

$(document).ready(function() {
  if ($('.incomes-list, .other-incomes-list').length) {
    $(window).bind('beforeunload', function(e) {
      if (!currentlyEditing() || $('#unsavedIncomeChangesWarning:visible').length)
        return undefined;

      (e || window.event).returnValue = 'You have an unsaved income, are you sure you want to proceed?'; //Gecko + IE
      return 'You have an unsaved income, are you sure you want to proceed?';
    });

    $(document).on('click', 'a[href]:not(.disabled)', function(e) {
      if (currentlyEditing()) {
        e.preventDefault();
        var self = this;

        $('#unsavedIncomeChangesWarning').modal('show');
        $('.btn.btn-danger').click(function() {
          window.location.href = $(self).attr('href');
        });

        return false;
      } else
      return true;
    });

    /* Saving Responses to  Job Income & Self Employment Driver Questions */
    $('#has_job_income_true, #has_job_income_false, #has_self_employment_income_true, #has_self_employment_income_false').on('change', function(e) {

      var attributes = {};
      attributes[$(this).attr('name')] = $(this).val();
      $.ajax({
        type: 'POST',
        url: window.location.pathname.replace('/incomes', ''),
        data: { financial_assistance_applicant: attributes },
        success: function(response){
        }
      })
    });

    /* Saving Responses to Other Income Driver Questions */
    $('#has_other_income_true, #has_other_income_false').on('change', function(e) {
      var attributes = {};
      attributes[$(this).attr('name')] = $(this).val();
      $.ajax({
        type: 'POST',
        url: window.location.pathname.replace('/incomes', '').replace('/other', ''),
        data: { financial_assistance_applicant: attributes },
        success: function(response){
        }
      })
    });

    /* DELETING all Job Incomes on selcting 'no' on Driver Question */
    $('#has_job_income_false').on('change', function(e) {
      var self = this;
      //$('#DestroyExistingJobIncomesWarning').modal('show');
      if ($('.incomes-list:not(.self-employed-incomes-list) .income').length) {
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllJobIncomes").modal();

        $("#destroyAllJobIncomes .modal-cancel-button").click(function(e) {
          $("#destroyAllJobIncomes").modal('hide');
          $('#has_job_income_true').prop('checked', true).trigger('change');
        });

        $("#destroyAllJobIncomes .modal-continue-button").click(function(e) {
          $("#destroyAllJobIncomes").modal('hide');
          //$(self).prop('checked', false);

          $('#job_income').find('.incomes-list > .income').each(function(i, job_income) {
            var url = $(job_income).attr('id').replace('financial_assistance_income_', 'incomes/');
            $(job_income).remove();
            $.ajax({
              type: 'DELETE',
              url: url
            });
          });
        });
      }
    });

    /* DELETING all Self Employment Incomes on selcting 'no' on Driver Question */
    $('#has_self_employment_income_false').on('change', function(e) {
      self = this;
      //$('#DestroyExistingJobIncomesWarning').modal('show');
      if ($('.self-employed-incomes-list .income').length) {
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllSelfEmploymentIncomes").modal();

        $("#destroyAllSelfEmploymentIncomes .modal-cancel-button").click(function(e) {
          $("#destroyAllSelfEmploymentIncomes").modal('hide');
          $('#has_self_employment_income_true').prop('checked', true).trigger('change');
        });

        $("#destroyAllSelfEmploymentIncomes .modal-continue-button").click(function(e) {
          $("#destroyAllSelfEmploymentIncomes").modal('hide');
          //$(self).prop('checked', false);

          $('#self_employed_incomes').find('.self-employed-incomes-list > .income').each(function(i, job_income) {
            var url = $(job_income).attr('id').replace('financial_assistance_income_', 'incomes/');
            $(job_income).remove();
            $.ajax({
              type: 'DELETE',
              url: url
            });
          });
        });
      }
    });

    /* edit existing incomes */
    $('.incomes-list').on('click', 'a.income-edit:not(.disabled)', function(e) {
      e.preventDefault();
      var incomeEl = $(this).parents('.income');
      incomeEl.find('.display-income').addClass('hidden');
      incomeEl.find('.income-edit-form').removeClass('hidden');
      $(incomeEl).find('select').selectric();
      $(incomeEl).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
      startEditingIncome($(this).parents('.income').attr('id'));
    });


    /* destroy existing job incomes */
    $('.incomes-list').on('click', 'a.income-delete:not(.disabled)', function(e) {
      var self = this;
      e.preventDefault();
      $("#DestroyJobIncomeWarning").modal();

      $("#DestroyJobIncomeWarning .modal-cancel-button").click(function(e) {
        $("#DestroyJobIncomeWarning").modal('hide');
      });

      $("#DestroyJobIncomeWarning .modal-continue-button").click(function(e) {
        $("#DestroyJobIncomeWarning").modal('hide');
        $(self).parents('.income').remove();

        var url = $(self).parents('.income').attr('id').replace('financial_assistance_income_', 'incomes/')
        $.ajax({
          type: 'delete',
          url: url
        })
      });
    });

    /* destroy existing Self Employed Incomes */
    $('.self-employed-incomes-list').on('click', 'a.self-employed-income-delete:not(.disabled)', function(e) {
      var self = this;
      e.preventDefault();
      $("#DestroySelfEmplyedIncomeWarning").modal();

      $("#DestroySelfEmplyedIncomeWarning .modal-cancel-button").click(function(e) {
        $("#DestroySelfEmplyedIncomeWarning").modal('hide');
      });

      $("#DestroySelfEmplyedIncomeWarning .modal-continue-button").click(function(e) {
        $("#DestroySelfEmplyedIncomeWarning").modal('hide');
        $(self).parents('.income').remove();

        var url = $(self).parents('.income').attr('id').replace('financial_assistance_income_', 'incomes/')
        $.ajax({
          type: 'delete',
          url: url
        })
      });
    });



    /* cancel income edits */
    $('.incomes-list').on('click', 'a.income-cancel', function(e) {
      e.preventDefault();
      var incomeEl = $(this).parents('.income');
      $(this).parents('.new-income-form').addClass("hidden");
      incomeEl.find('.income-edit-form').addClass('hidden');
      incomeEl.find('.display-income').removeClass('hidden');
      stopEditingIncome();
      /* TODO: Handle unchecking boxes if there are no more incomes of that kind */
    });

    $(document).on('click','a.other-income-cancel', function(e) {
      e.preventDefault();

      if ($(this).parents('.new-income-form').length) {
        $(this).parents('.new-income-form').addClass('hidden');
      } else {
        var incomeEl = $(this).parents('.income');
      }
      stopEditingIncome();

      /* TODO: Handle unchecking boxes if there are no more incomes of that kind */
    });

    /* new job incomes */
    $('a.new-income').click(function(e) {
        e.preventDefault();
        startEditingIncome($(this).parents('.income').attr('id'));
        var form = $(this).parents();
        if ($(this).parents('#job_income').children('.new-income-form').length){
           var  newIncomeForm = $(this).parents('#job_income').children('.new-income-form')
        } else{
           var  newIncomeForm = $(this).parents('#self_employed_incomes').children('.new-income-form')
        }

        if ($(this).parents('#job_income').find('.incomes-list').length){
           var  incomeListEl =  $(this).parents('#job_income').find('.incomes-list');
        } else{
           var  incomeListEl =  $(this).parents('#self_employed_incomes').find('.incomes-list');
        }
        if (newIncomeForm.find('select').data('selectric')) newIncomeForm.find('select').selectric('destroy');
        var clonedForm = newIncomeForm.clone(true, true)
            .removeClass('hidden')
            .appendTo(incomeListEl);
        var length = incomeListEl.find(".income").length;
        $(clonedForm).find('select').selectric();
        //$(newIncomeForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true});
        $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
    });

    $('#has_job_income_true').click(function(e) {
      startEditingIncome($(this).parents('.income').attr('id'));
      if ($('#job_income').children('.new-income-form').length) {
        var  newIncomeForm = $('#job_income').children('.new-income-form')
      }

      if ($('#job_income').find('.incomes-list').length) {
        var  incomeListEl =  $('#job_income').find('.incomes-list');
      }
      if (newIncomeForm.find('select').data('selectric')) newIncomeForm.find('select').selectric('destroy');
      var clonedForm = newIncomeForm.clone(true, true)
      .removeClass('hidden')
      .appendTo(incomeListEl);
      var length = incomeListEl.find(".income").length;
      $(clonedForm).find('select').selectric();
      $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
    });

    $('#has_self_employment_income_true').click(function(e) {
      startEditingIncome($(this).parents('.income').attr('id'));
      if ($('#self_employed_incomes').children('.new-income-form').length) {
        var  newIncomeForm = $('#self_employed_incomes').children('.new-income-form')
      }
      if ($('#self_employed_incomes').find('.incomes-list').length) {
        var  incomeListEl =  $('#self_employed_incomes').find('.incomes-list');
      }
      if (newIncomeForm.find('select').data('selectric')) newIncomeForm.find('select').selectric('destroy');
      var clonedForm = newIncomeForm.clone(true, true)
      .removeClass('hidden')
      .appendTo(incomeListEl);
      var length = incomeListEl.find(".income").length;
      $(clonedForm).find('select').selectric();
      $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
    });

    /* Condtional Display Job Income Question */
    if (!$("#has_job_income_true").is(':checked')) $("#job_income").addClass('hidden');
    if (!$("#has_self_employment_income_true").is(':checked')) $("#self_employed_incomes").addClass('hidden');
    if (!$("#has_other_income_true").is(':checked')) $(".other_income_kinds").addClass('hidden');

    $("body").on("change", "#has_job_income_true", function(){
      if ($('#has_job_income_true').is(':checked')) {
        $("#job_income").removeClass('hidden');
      } else{
        $("#job_income").addClass('hidden');
      }
    });

    $("body").on("change", "#has_job_income_false", function(){
      if ($('#has_job_income_false').is(':checked')) {
        $("#job_income").addClass('hidden');
      } else{
        $("#job_income").removeClass('hidden');
      }
    });

    $("body").on("change", "#has_self_employment_income_true", function(){
      if ($('#has_self_employment_income_true').is(':checked')) {
        $("#self_employed_incomes").removeClass('hidden');
      } else{
        $("#self_employed_incomes").addClass('hidden');
      }
    });

    $("body").on("change", "#has_self_employment_income_false", function(){
      if ($('#has_self_employment_income_false').is(':checked')) {
        $("#self_employed_incomes").addClass('hidden');
      } else{
        $("#self_employed_incomes").removeClass('hidden');
      }
    });

    /* Condtional Display Other Income Question */
    $("body").on("change", "#has_other_income_true", function(){
      if ($('#has_other_income_true').is(':checked')) {
        $(".other_income_kinds").removeClass('hidden');
      } else{
        $(".other_income_kinds").addClass('hidden');
      }
    });

    $("body").on("change", "#has_other_income_false", function(){
      if ($('#has_other_income_false').is(':checked')) {
        $(".other_income_kinds").addClass('hidden');
      } else{
        $(".other_income_kinds").removeClass('hidden');
      }
    });
  }
});

// otherincome checkbox fuctionality
$(document).ready(function() {
  function disableSave(form){
    form.find('.interaction-click-control-save').addClass("disabled");
  }

  function enableSave(form){
    form.find('.interaction-click-control-save').removeClass('disabled');
  }
  $(':input[required=""],:input[required]').on('change', function(){
    var form = $(this).closest('form');
    if (validateForm(form)){
      enableSave(form)
    }else{
      disableSave(form)
    }
  });

  function validateForm(form) {
    var isValid = true;
    // form.find('#financial_assistance_income_start_on, input[name*=financial_assistance_income[start_on]], input[name*=financial_assistance_income[end_on]]').each(function() {
    //   if ( $(this).val() == '' ||  $(this).val()=='0')
    //     isValid = false;
    // });
    return isValid;
  }

  // $(window).bind('beforeunload', function(e) {
  //   if (!currentlyEditing() || $('#unsavedIncomeChangesWarning:visible').length)
  //     return undefined;

  //   (e || window.event).returnValue = 'You have an unsaved income, are you sure you want to proceed?'; //Gecko + IE
  //   return 'You have an unsaved income, are you sure you want to proceed?';
  // });

  $('input[type="checkbox"]').click(function(e){
    var value = e.target.checked;
    self = this;
    if (value) {
      var newOtherIncomeFormEl = $(this).parents('.other-income-kind').children('.new-other-income-form')
      otherIncomeListEl = $(this).parents('.other-income-kind').find('.other-incomes-list');
      if (newOtherIncomeFormEl.find('select').data('selectric')) newOtherIncomeFormEl.find('select').selectric('destroy');
      var clonedForm = newOtherIncomeFormEl.clone(true, true)
      .removeClass('hidden')
      .appendTo(otherIncomeListEl);
      startEditingIncome($(this).parents('.other-income-kind').attr('id'));
      $(clonedForm).find('select').selectric();
      $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
    }
    else {
      // prompt to delete all these dedcutions
      $("#destroyAllOtherIncomes").modal();
      $("#destroyAllOtherIncomes .modal-cancel-button").click(function(e) {
        $("#destroyAllOtherIncomes").modal('hide');
      });

      $("#destroyAllOtherIncomes .modal-continue-button").click(function(e) {
        $("#destroyAllOtherIncomes").modal('hide');
        $(self).prop('checked', false);
        $(self).parents('.other-income-kind').find('.interaction-click-control-add-more').addClass('hidden');

        $(self).parents('.other-income-kind').find('.other-incomes-list > .other-income').each(function(i, other_income) {
          var url = $(other_income).attr('id').replace('financial_assistance_income_', '');
          $(other_income).remove();

          $.ajax({
            type: 'DELETE',
            url: url
          });
        });
      });
    }
  });
  // add more for other income

   $(document).on('click', "#add_new_other_income_kind", function(e){
       var newOtherIncomeFormEl = $(this).parents('.other-income-kind').children('.new-other-income-form'),
           otherIncomeListEl = $(this).parents('.other-income-kind').find('.other-incomes-list');
       if (newOtherIncomeFormEl.find('select').data('selectric')) newOtherIncomeFormEl.find('select').selectric('destroy');
       var clonedForm = newOtherIncomeFormEl.clone(true, true)
           .removeClass('hidden')
           .appendTo(otherIncomeListEl);
        startEditingIncome($(this).parents('.other-income-kind').attr('id'));
       $(clonedForm).find('select').selectric();
       $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
       $(this).addClass("hidden");
       e.stopImmediatePropagation();
   });

  /* edit existing other income */
  $('.other-incomes-list').on('click', 'a.other-income-edit:not(.disabled)', function(e) {
    e.preventDefault();
    var otherIncomeEl = $(this).parents('.other-income');
    otherIncomeEl.find('.other-income-show').addClass('hidden');
    otherIncomeEl.find('.edit-other-income-form').removeClass('hidden');
    startEditingIncome($(this).parents('.other-income-kind').attr('id'));

    $(otherIncomeEl).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
  });

  /* destroy existing other income */
  $('.other-incomes-list').on('click', 'a.other-income-delete:not(.disabled)', function(e) {
    var self = this;
    e.preventDefault();
    $("#destroyOtherIncome").modal();

    $("#destroyOtherIncome .modal-cancel-button").click(function(e) {
      $("#destroyOtherIncome").modal('hide');
    });

    $("#destroyOtherIncome .modal-continue-button").click(function(e) {
      $("#destroyOtherIncome").modal('hide');
      $(self).parents('.other-income').remove();
      $("a.interaction-click-control-add-more").addClass('hide');

      var url = $(self).parents('.other-income').attr('id').replace('financial_assistance_income_', '');
      console.log(url);
      $.ajax({
        type: 'DELETE',
        url: url,
        dataType: 'script',
      })
    });
  });

  /* cancel other income edits */
  $('.other-incomes-list').on('click', 'a.other-income-cancel', function(e) {
    e.preventDefault();
    stopEditingIncome();

    var otherIncomeEl = $(this).parents('.other-income');
    if (otherIncomeEl.length) {
      $(this).closest('.other-income-kind').find('a#add_new_other_income_kind').removeClass("hidden");
      otherIncomeEl.find('.other-income-show').removeClass('hidden');
      otherIncomeEl.find('.edit-other-income-form').addClass('hidden');
    } else {
      if (!$(this).parents('.other-incomes-list > div.other-income').length) {
        $(this).parents('.other-income-kind').find('input[type="checkbox"]').prop('checked', false);
        $(this).closest('.other-income-kind').find('a#add_new_other_income_kind').addClass("hidden");
      }
      $(this).parents('.new-other-income-form').remove();
      $(this).parents('.edit-other-income-form').remove();
    }
  });
// disable save button logic
function disableSave(form){
  form.find('.interaction-click-control-save').addClass("disabled");
}

function enableSave(form){
  form.find('.interaction-click-control-save').removeClass('disabled');
}

$(':input[required]').on('keyup change', function(){
  var form = $(this).closest('form');
  if (validateForm(form)){
    enableSave(form)
  }else{
    disableSave(form)
  }
});

function validateForm(form) {
  var isValid = true;
  form.find(':input[required]').each(function() {
    if ( $(this).val() == '' ||  $(this).val()=='0')
      isValid = false;
  });
  return isValid;
}


$('body').on('keyup keydown keypress', '#financial_assistance_income_employer_phone_full_phone_number', function (e) {
  var key = e.which || e.keyCode || e.charCode;
  $(this).mask('(000) 000-0000');
  return (key == 8 ||
    key == 9 ||
    key == 46 ||
    (key >= 37 && key <= 40) ||
    (key >= 48 && key <= 57) ||
    (key >= 96 && key <= 105) );
});

$('body').on('keyup keydown keypress', '#financial_assistance_income_employer_address_zip', function (e) {
  var key = e.which || e.keyCode || e.charCode;
  $(this).attr('maxlength', '5');
  return (key == 8 ||
    key == 9 ||
    key == 46 ||
    (key >= 37 && key <= 40) ||
    (key >= 48 && key <= 57) ||
    (key >= 96 && key <= 105) );
});
});
