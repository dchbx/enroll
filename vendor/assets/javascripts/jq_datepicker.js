function applyJQDatePickerSetup(ele) {
    var el = $(ele);

    if (el.is(".jq_datepicker_already_applied")) {
      return;
    }
    var yearMax = dchbx_enroll_date_of_record().getFullYear() + 10;
    var yearMin = dchbx_enroll_date_of_record().getFullYear() - 110;
    var otherFieldSelector = el.attr("data-submission-field");
    var otherField = $(otherFieldSelector);
    otherField.hide();
    el.show();
    var otherFieldId = otherField.attr("id");
    var labelFields = $("label[for='" + otherFieldId + "']");
    if (labelFields.length > 0) {
        labelFields.hide();
    }
    otherField.attr("class", "");

    var ofParentControl = otherField.parent();
    var ofGrandparentControl = ofParentControl.parent();

    var inErrorState = false;

    var dateMax = null;
    var dateMin = null;
    var currentYear = dchbx_enroll_date_of_record().getFullYear();

    if (ofParentControl.is(".floatlabel-wrapper")) {
        if (ofGrandparentControl.is(".field_with_errors")) {
            inErrorState = true;
        }
    } else if (ofParentControl.is(".field_with_errors")) {
        inErrorState = true;
    }

    if (inErrorState) {
        var parentControl = el.parent();
        if (parentControl.is(".floatlabel-wrapper")) {
            parentControl.wrap("<div class=\"field_with_errors\"></div>");
        } else {
            el.wrap("<div class=\"field_with_errors\"></div>");
        }
    }

    if (el.is("[data-year-max]")) {
        yearMax = el.attr("data-year-max");
    }

    if (el.is("[data-year-min]")) {
        yearMin = el.attr("data-year-min");
    }

    if (el.is("[data-date-max]")) {
        dateMax = el.attr("data-date-max");
    }

    if (el.is("[data-date-min]")) {
        dateMin = el.attr("data-date-min");
    }

    el.datepicker({
        changeMonth: true,
        changeYear: true,
        dateFormat: 'mm/dd/yy',
        altFormat: 'yy-mm-dd',
        altField: otherFieldSelector,
        yearRange: yearMin + ":" + yearMax,
        maxDate: new Date(currentYear, 11, 31),
        onSelect: function(dateText, dpInstance) {
            $(this).datepicker("hide");
            $(this).trigger('change');
    
    var date = $(this).val();
    var entered_dob = $(this).val();
    var entered_year = entered_dob.substring(entered_dob.length -4);
    var entered_month = entered_dob.substring(0, 2);
    var entered_day = entered_dob.substring(3, 5);
    var todays_date = dchbx_enroll_date_of_record();
    var todays_year = todays_date.getFullYear();
    var todays_month = todays_date.getMonth() + 1;
    var todays_day = todays_date.getDate();

    if (entered_year > todays_year) {
      alert("Please enter a birthdate that does not take place in the future.");
      $(this).val("");
      $(this).focus();
    }
    else if (entered_year == todays_year) {
      if (entered_month == todays_month) {
        if (entered_day > todays_day) {
          alert("Please enter a birthdate that does not take place in the future.");
          $(this).val("");
          $(this).focus();
        } else {
        }
      }
      else if (entered_month > todays_month) {
        alert("Please enter a birthdate that does not take place in the future.");
        $(this).val("");
        $(this).focus();
      }
    }
        }
    });
    el.datepicker("refresh");
    el.addClass("jq_datepicker_already_applied");
   }

function applyJQDatePickers() {
    $(".jq-datepicker").each(function(idx, ele) {
        applyJQDatePickerSetup(ele);
        if ($(this).attr("readonly") != undefined){
            $(ele).datepicker('disable');
        }
    });
}
