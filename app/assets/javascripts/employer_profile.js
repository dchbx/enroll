var EmployerProfile = ( function( window, undefined ) {

  function changeCensusEmployeeStatus($thisObj) {
    $('.injected-edit-status').html('<br/><h3 class="no-buffer">'+$thisObj.text()+'</h3><div class="module change-employee-status hbx-panel panel panel-default"><div class="panel-body"><div class="vertically-aligned-row"><div><label class="enroll-label">Enter Date of '+$thisObj.text()+':</label><input title="&#xf073; &nbsp;" placeholder="&#xf073; &nbsp;'+$thisObj.text()+' Date" type="text" class="date-picker date-field form-control"/></div><div class="text-center"><span class="btn btn-primary btn-sm disabled">'+$thisObj.text()+'</span></div></div></div></div>');
    if ( $thisObj.text() == 'Terminate' ) {
      $('.injected-edit-status .change-employee-status label').text('Enter Date of Termination:')
      $('.injected-edit-status .change-employee-status .date-picker').attr('placeholder', $('.injected-edit-status .change-employee-status .date-picker').attr('title')+'Termination Date (must be within the past 60 days)');
      $('.injected-edit-status .change-employee-status label').text('Enter Date of Termination:')
    }
    $('.injected-edit-status').slideDown();
    $('.injected-edit-status .date-picker').on('change', function() {
      $(this).closest('.injected-edit-status').find('.btn-primary').removeClass('disabled');
      var url = $(this).closest('.census-employee').data('rehire-url');
      var rehiring_date = $(this).val();
      var status = $(this).closest('.census-employee').data('status');
      $(this).closest('.injected-edit-status').find('.btn-primary').off('click');
      $(this).closest('.injected-edit-status').find('.btn-primary:contains("Rehire")').on('click', function() {
        $.ajax({
          url: url,
          data: {
            rehiring_date: rehiring_date,
            status: status
          }
        })
      });
      $(this).closest('.injected-edit-status').find('.btn-primary:contains("Terminate")').on('click', function() {
        var url = $(this).closest('.census-employee').data('terminate-url');
        var termination_date = $(this).val();
        $.ajax({
          url: url,
          data: {
            termination_date: termination_date,
            status: status
          }
        })
      });
    });
  }

  function viewDetails($thisObj) {
    if ( $thisObj.hasClass('view') ) {
      $thisObj.closest('.benefit-package').find('.health-offering, .dental-offering').slideDown();
      $thisObj.html('Hide Details<i class="fa fa-chevron-up fa-lg"></i>');
      $thisObj.removeClass('view');
    } else {
      $thisObj.closest('.benefit-package').find('.health-offering, .dental-offering').slideUp();
      $thisObj.html('View Details<i class="fa fa-chevron-down fa-lg"></i>');
      $thisObj.addClass('view');
    }
  }

  function validateEditPlanYear() {
    editbgtitles = $('.plan-title').find('label.title').parents('.form-group').find('input');
    editbgemployeepremiums = $('.benefits-fields').find('input[value=employee]').closest('fieldset').find('input.hidden-param.premium-storage-input');
    edit_all_premiums = $('.benefits-fields').find('input').closest('fieldset').find('input.hidden-param.premium-storage-input');
    editreferenceplanselections = $('.reference-plan input[type=radio]:checked');
    editselectedplan = $('input.ref-plan');

    editbgtitles.each(function() {
        editplantitle = $(this).val();
        if ( $(this).val().length > 0 && $('.plan-title input[value=' + "\"editplantitle\"" + ']').size() < 2 ) {
          editvalidatedbgtitles = true;
          editvalidated = true;
          var values = [];
          editbgtitles.each(function() {
              if ( $.inArray(this.value, values) >= 0 ) {
                $('.interaction-click-control-save-plan-year').attr('data-original-title', 'Before you can save, each benefit group must have a unique title.');
                editvalidatedbgtitles = false;
                editvalidated = false;
                return false; // <-- stops the loop
              } else {
                  values.push( this.value );
                  editvalidatedbgtitles = true;
                  editvalidated = true;
              }
          });
        } else {
          $('.interaction-click-control-save-plan-year').attr('data-original-title', 'Before you can save, each benefit group must have a unique title.');
          editvalidatedbgtitles = false;
          editvalidated = false;
          return false;
        }

    });
    if ( $('#plan_year_start_on').val().substring($('#plan_year_start_on').val().length - 5) == "01-01" ) {
      editvalidatedbgemployeepremiums = true;
      editvalidated = true;
    } else {
      editbgemployeepremiums.each(function() {
        if ( $(this).closest('.benefit-group-fields').hasClass('edit-additional') && $(this).closest('.select-dental-plan').length ) {
        } else {
          if ( parseInt($(this).val() ) >= parseInt(50) ) {
            editvalidatedbgemployeepremiums = true
            editvalidated = true;
          } else {
            $('.interaction-click-control-save-plan-year').attr('data-original-title', 'Employee premium must be atleast 50%');
            editvalidatedbgemployeepremiums = false;
            editvalidated = false;
            return false;
          }
        }
      });
    }

    if ( editreferenceplanselections.length != $('.benefit-group-fields').length ) {
      editvalidatedreferenceplanselections = true
      editvalidated = true;
    } else {
      editbgemployeepremiums.each(function() {
        if ( $(this).closest('.benefit-group-fields').hasClass('edit-additional') && $(this).closest('.select-dental-plan').length ) {
        } else {
        if ( parseInt($(this).val() ) >= parseInt(50) ) {
          editvalidatedbgemployeepremiums = true
          editvalidated = true;
        } else {
          $('.interaction-click-control-save-plan-year').attr('data-original-title', 'Employee premium for Health must be atleast 50%');
          editvalidatedbgemployeepremiums = false;
          editvalidated = false;
          return false;
        }
      }
      });
    }

    edit_all_premiums.each(function() {
      if ( parseInt($(this).val()) >= parseInt(0) && parseInt($(this).val()) <= parseInt(100)) {
        edit_validated_all_premiums = true;
        editvalidated = true;
      } else {
        $('.interaction-click-control-save-plan-year').attr('data-original-title', 'Premium contribution amounts must be between 0 and 100%');
        edit_validated_all_premiums = false;
        editvalidated = false;
        return false;
      }
    });

    $('.benefit-group-fields').each(function() {
      if ( $(this).hasClass('edit-additional') ) {
        if ( $(this).find('.reference-steps:first').is(':visible') && $(this).find('.reference-steps:first').find('input:checked').length >= 4 ) {
         editvalidatedreferenceplanselections = true
          editvalidated = true;
        } else if ( $(this).find('.reference-steps:first').is(':hidden')) {
            editvalidatedreferenceplanselections = true
            editvalidated = true;
        }
          else {
            $('.interaction-click-control-save-plan-year').attr('data-original-title', "Before you can save, you must finish your plan year selection. Click 'Cancel' above to keep your existing selection");
            editvalidatedreferenceplanselections = false
            editvalidated = false;
            return false;
        }
      } else {
      if ( $(this).find('.reference-steps').is(':first') ) {
        if ( $(this).find('.reference-steps:first').is(':visible') && $(this).find('.reference-steps:first').find('input:checked').length >= 4 ) {
         editvalidatedreferenceplanselections = true
          editvalidated = true;
        } else if ( $(this).find('.reference-steps:first').is(':hidden')) {
            editvalidatedreferenceplanselections = true
            editvalidated = true;
        }
          else {
            $('.interaction-click-control-save-plan-year').attr('data-original-title', "Before you can save, you must finish your plan year selection. Click 'Cancel' above to keep your existing selection");
            editvalidatedreferenceplanselections = false
            editvalidated = false;
            return false;
        }
      } else {
        if ( $(this).find('.reference-steps:last').find('.edit-add-dental').length ) {
          if ( $('.edit-add-dental').is(':hidden') ) {
            if ( $(this).find('.reference-steps:last').find('.plan-options').is(':hidden') && $(this).find('.reference-steps:last').find('.nav-tabs').is(':hidden') && $(this).find('.reference-steps:last').find('.dental-reference-plans').is(':hidden')) {
              editvalidatedreferenceplanselections = true
              editvalidated = true;
            } else if ( $(this).find('.reference-steps:last').is(':hidden')) {
                editvalidatedreferenceplanselections = true
                editvalidated = true;
            }
              else {
                $('.interaction-click-control-save-plan-year').attr('data-original-title', "Before you can save, you must finish your plan year selection. Click 'Cancel' above to keep your existing selection");
                editvalidatedreferenceplanselections = false
                editvalidated = false;
                return false;
            }
          }

        } else {
          if ( $(this).find('.reference-steps:last').find('.plan-options').is(':hidden') && $(this).find('.reference-steps:last').find('.nav-tabs').is(':hidden') && $(this).find('.reference-steps:last').find('.dental-reference-plans').is(':hidden')) {
            editvalidatedreferenceplanselections = true
            editvalidated = true;
          }   else {
                $('.interaction-click-control-save-plan-year').attr('data-original-title', "Before you can save, you must finish your plan year selection. Click 'Cancel' above to keep your existing selection");
                editvalidatedreferenceplanselections = false
                editvalidated = false;
                return false;
          }
        }
      }
    }
    });

    if ( editvalidatedbgtitles == true && editvalidatedbgemployeepremiums == true && editvalidatedreferenceplanselections == true && edit_validated_all_premiums == true ) {
        $('.interaction-click-control-save-plan-year').removeAttr('data-original-title');
        $('.interaction-click-control-save-plan-year').removeClass('disabled');
        $('.interaction-click-control-save-plan-year').attr('data-original-title', 'Click here to save your plan year');
      } else {
        $('.interaction-click-control-save-plan-year').addClass('disabled');
      }
      Freebies.tooltip();
  }

  function validatePlanYear() {
    bgtitles = $('.plan-title').find('label.title').parents('.form-group').find('input');
    bgemployeepremiums = $('.benefits-fields').find('input[value=employee]').closest('fieldset').find('input.hidden-param.premium-storage-input');
    all_premiums = $('.benefits-fields').find('input').closest('fieldset').find('input.hidden-param.premium-storage-input');
    referenceplanselections = $('.reference-plan input[type=radio]:checked');

    bgtitles.each(function() {
      plantitle = $(this).val();
      if ( $(this).val().length > 0 && $('.plan-title input[value=' + "\"plantitle\"" + ']').size() < 2 ) {
        validatedbgtitles = true;
        validated = true;
        var values = [];
        bgtitles.each(function() {
            if ( $.inArray(this.value, values) >= 0 ) {

              $('.interaction-click-control-create-plan-year').attr('data-original-title', 'Before you can save, each benefit group must have a unique title.');
              validatedbgtitles = false;
              validated = false;
              return false; // <-- stops the loop
            } else {
                values.push( this.value );
                validatedbgtitles = true;
                validated = true;
            }
        });
      } else {
        $('.interaction-click-control-create-plan-year').attr('data-original-title', 'Before you can save, each benefit group must have a unique title.');
        validatedbgtitles = false;
        validated = false;
        return false;
      }
    });
    if ( $('#plan_year_start_on').val().substring($('#plan_year_start_on').val().length - 5) == "01-01" ) {
      validatedbgemployeepremiums = true;
      validated = true;
    } else {
      bgemployeepremiums.each(function() {
        if ( parseInt($(this).val()) >= parseInt(50) ) {
          validatedbgemployeepremiums = true;
          validated = true;
        } else {
          $('.interaction-click-control-create-plan-year').attr('data-original-title', 'Employee premium for Health must be atleast 50%');
          validatedbgemployeepremiums = false;
          validated = false;
          return false;
        }
      });
    }

    all_premiums.each(function() {
      if ( parseInt($(this).val()) >= parseInt(0) && parseInt($(this).val()) <= parseInt(100)) {
        validated_all_premiums = true;
        validated = true;
      } else {
        $('.interaction-click-control-create-plan-year').attr('data-original-title', 'Premium contribution amounts must be between 0 and 100%');
        validated_all_premiums = false;
        validated = false;
        return false;
      }
    });

    dental_bgs = $('.select-dental-plan:visible').length
    health_bgs = $('.benefit-group-fields > .health:visible').length
    selected_reference_plans = dental_bgs + health_bgs;

    if ( referenceplanselections.length != selected_reference_plans ) {
      validatedreferenceplanselections = false;
      validated = false;
    } else {
      referenceplanselections.each(function() {
        if ( $(this).length && $(this).val() != 'undefined' ) {
          validatedreferenceplanselections = true;
          validated = true;
        } else {
          $('.interaction-click-control-create-plan-year').attr('data-original-title', 'Each benefit group is required to have a reference plan selection before it can be saved');
          validatedreferenceplanselections = false
          validated = false;
          return false;
        }
      });
    }

    if ( validatedbgtitles == true && validatedbgemployeepremiums == true && validatedreferenceplanselections == true && validated_all_premiums == true ) {
        $('.interaction-click-control-create-plan-year').removeClass('disabled');
        $('.interaction-click-control-create-plan-year').removeAttr('data-original-title');
        $('.interaction-click-control-create-plan-year').attr('data-original-title', 'Click here to create your plan year');
        $('.interaction-click-control-create-plan-year').unbind('click');
      } else {
        $('.interaction-click-control-create-plan-year').addClass('disabled');
        $('.interaction-click-control-create-plan-year').click(function(event){
          event.preventDefault();
        });
      }
      Freebies.tooltip();
  }

  return {
      changeCensusEmployeeStatus: changeCensusEmployeeStatus,
      validateEditPlanYear : validateEditPlanYear,
      validatePlanYear : validatePlanYear,
      viewDetails : viewDetails
    };

} )( window );

// $(document).ready(function() {
//   if ('input.typeahead') {
//     var employers = new Bloodhound({
//       datumTokenizer: Bloodhound.tokenizers.obj.whitespace('legal_name'),
//       queryTokenizer: Bloodhound.tokenizers.whitespace,
//       remote: {
//         prepare: function (query, settings) {
//           settings.type = "POST";
//           settings.data = { q: query };
//           return settings;
//         },
//         url: '/employers/search'
//       }
//     });
//
//     // initialize the bloodhound suggestion engine
//     employers.initialize();
//     // instantiate the typeahead UI
//     $('input.typeahead').typeahead({
//       hint: false,
//       minLength: 2
//     },{
//       display: 'legal_name',
//       name: 'employers',
//       source: employers.ttAdapter()
//     });
//
//     $('input.typeahead').on('blur keyup', function(e) {
//       if (e.keyCode == 8 && $('input#organization_fein').val() != "") {
//         $('#office_locations_buttons a.btn').removeAttr('disabled');
//         $('input#employer_id').val("");
//         $('input#organization_dba').val("").removeAttr('readonly');
//         $('input#organization_fein').val("").removeAttr('readonly');
//         $('select#organization_entity_kind').val("").removeAttr('disabled').selectric('refresh');
//         $('select#organization_office_locations_attributes_0_address_attributes_kind').val("primary").removeAttr('disabled').selectric('refresh');
//         $('input#organization_office_locations_attributes_0_address_attributes_address_1').val("").removeAttr('readonly');
//         $('input#organization_office_locations_attributes_0_address_attributes_address_2').val("").removeAttr('readonly');
//         $('input#organization_office_locations_attributes_0_address_attributes_city').val("").removeAttr('readonly');
//         $('select#organization_office_locations_attributes_0_address_attributes_state').val("").removeAttr('disabled').selectric('refresh');
//         $('input#organization_office_locations_attributes_0_address_attributes_zip').val("").removeAttr('readonly');
//
//         $('input#organization_office_locations_attributes_0_phone_attributes_area_code').val("").removeAttr('readonly');
//         $('input#organization_office_locations_attributes_0_phone_attributes_number').val("").removeAttr('readonly');
//         $('input#organization_office_locations_attributes_0_phone_attributes_extension').val("").removeAttr('readonly');
//       };
//     });
//
//     $('input.typeahead').bind('typeahead:select', function(e, suggestion) {
//
//       $('#office_locations_buttons a.btn').attr('disabled', 'disabled');
//       $('input#employer_id').val(suggestion._id);
//       $('input#organization_dba').val(suggestion.dba).attr('readonly', 'readonly');
//       $('input#organization_fein').val(suggestion.fein).attr('readonly', 'readonly');
//       $('select#organization_entity_kind').val(suggestion.employer_profile.entity_kind).attr('disabled', 'disabled').selectric('refresh').removeAttr('disabled');
//       var primary_office = suggestion.office_locations[0]
//       if (primary_office) {
//         $('select#organization_office_locations_attributes_0_address_attributes_kind').val(primary_office.address.kind).attr('disabled', 'disabled').selectric('refresh').removeAttr('disabled');
//         $('input#organization_office_locations_attributes_0_address_attributes_address_1').val(primary_office.address.address_1).attr('readonly', 'readonly');
//         $('input#organization_office_locations_attributes_0_address_attributes_address_2').val(primary_office.address.address_2).attr('readonly', 'readonly');
//         $('input#organization_office_locations_attributes_0_address_attributes_city').val(primary_office.address.city).attr('readonly', 'readonly');
//         $('select#organization_office_locations_attributes_0_address_attributes_state').val(primary_office.address.state).attr('disabled', 'disabled').selectric('refresh').removeAttr('disabled');
//         $('input#organization_office_locations_attributes_0_address_attributes_zip').val(primary_office.address.zip).attr('readonly', 'readonly');
//
//         $('input#organization_office_locations_attributes_0_phone_attributes_area_code').val(primary_office.phone.area_code).attr('readonly', 'readonly');
//         $('input#organization_office_locations_attributes_0_phone_attributes_number').val(primary_office.phone.number).attr('readonly', 'readonly');
//         $('input#organization_office_locations_attributes_0_phone_attributes_extension').val(primary_office.phone.extension).attr('readonly', 'readonly');
//       }
//     });
//   }
// });

$(function() {
  $('div[name=employee_family_tabs] > ').children().each( function() {
    $(this).change(function(){
      filter = $(this).val();
      search = $("#census_employee_search input#employee_name").val();
      $('#employees_' + filter).siblings().hide();
      $('#employees_' + filter).show();
      $.ajax({
        url: $('span[name=employee_families_url]').text() + '.js',
        type: "GET",
        data : { 'status': filter, 'employee_name': search },
        crossDomain: true,
        xhrFields: {
          withCredentials: true
        }
      });
    })
  })
})

$(document).on('click', ".show_confirm", function(){
  var el_id = $(this).attr('id');
  $( "td." + el_id ).toggle();
  $( "#confirm-terminate-2" ).hide();
  return false
});

$(document).on('click', ".delete_confirm", function(){
  var termination_date = $(this).closest('div').find('input').val();
  var link_to_delete = $(this).data('link');

  $.ajax({
    type: 'get',
    datatype : 'js',
    url: link_to_delete,
    data: {termination_date: termination_date},
    success: function(response){

        window.location.reload();

    },
    error: function(response){
      Alert("Sorry, something went wrong");
    }
  });
});

$(document).on('click', ".rehire_confirm", function(){
  var element_id = $(this).attr('id');
  var rehiring_date = $(this).siblings().val();
  var rehire_link = $(this).data('link');
  $.ajax({
    type: 'get',
    datatype : 'js',
    url: rehire_link,
    data: {rehiring_date: rehiring_date},
    success: function(response){
        window.location.reload();
    },
    error: function(response){
      Alert("Sorry, something went wrong");
    }
  });
});

$(document).on('change', '.dependent_info input.dob-picker', function(){
  var element = $(this).val().split("/");
  year = parseInt(element[2]);
  month = parseInt(element[0]);
  day = parseInt(element[1]);
  var mydate = dchbx_enroll_date_of_record();
  mydate.setFullYear(year + 26,month-1,day);
  var target = $(this).parents('.dependent_info').find('select');
  selected_option_index = $(target).get(0).selectedIndex

  if (mydate > dchbx_enroll_date_of_record()){
    data = "<option value=''>SELECT RELATIONSHIP</option><option value='spouse'>Spouse</option><option value='domestic_partner'>Domestic partner</option><option value='child_under_26'>Child</option>";
  }else{
    data = "<option value=''>SELECT RELATIONSHIP</option><option value='spouse'>Spouse</option><option value='domestic_partner'>Domestic partner</option><option value='child_26_and_over'>Child</option>";
  }
  $(target).html(data);
  $(target).prop('selectedIndex', selected_option_index).selectric('refresh');
});

$(function() {
  $("#publishPlanYear .close").click(function(){
    location.reload();
  });
  setProgressBar();
})

function setProgressBar(){

    // ignore this call by returning if no presense of progress-wrapper and employer-dummy classes
    if($('.progress-wrapper.employer-dummy').length == 0) {
      return;
    }



  maxVal = parseInt($('.progress-val .pull-right').data('value'));
  dividerVal = parseInt($('.divider-progress').data('value'));
  currentVal = parseInt($('.progress-bar').data('value'));
  percentageDivider = dividerVal/maxVal * 100;
  percentageCurrent = currentVal/maxVal * 100;

  $('.progress-bar').css({'width': percentageCurrent + "%"});
  $('.divider-progress').css({'left': (percentageDivider - 1) + "%"});

  barClass = currentVal < dividerVal ? 'progress-bar-danger' : 'progress-bar-success';
  $('.progress-bar').addClass(barClass);

  if(maxVal == 0){
    $('.progress-val strong').html('');
  }

  if(dividerVal == 0){
    $('.divider-progress').html('');
  }

  if(currentVal == 0){
    $('.progress-current').html('');
  }
}

$(document).on('click', '#census_employee_search_clear', function() {
  $('form#census_employee_search input#employee_name').val('');
  $("form#census_employee_search").submit();
})

$(document).on('change', '#address_info .office_kind_select select', function() {
  if ($(this).val() == 'mailing') {
    $(this).parents('fieldset').find('#phone_info input.area_code').attr('required', false);
    $(this).parents('fieldset').find('#phone_info input.phone_number7').attr('required', false);
  };
  if ($(this).val() == 'primary' || $(this).val() == 'branch'){
    $(this).parents('fieldset').find('#phone_info input.area_code').attr('required', true);
    $(this).parents('fieldset').find('#phone_info input.phone_number7').attr('required', true);
  };
})

function checkPhone(textbox) {
  var phoneRegex = /^\d{3}-\d{4}$/;
  if (textbox.value == '') {
    textbox.setCustomValidity('Please fill out this phone number field.');
  } else if(!phoneRegex.test(textbox.value)){
    textbox.setCustomValidity('please enter a valid phone number.');
  } else {
    textbox.setCustomValidity('');
  }
  return true;
}

function checkZip(textbox) {
  var phoneRegex = /^\d{5}$/;
  if (textbox.value == '') {
    textbox.setCustomValidity('Please fill out this zipcode field.');
  } else if(!phoneRegex.test(textbox.value)){
    textbox.setCustomValidity('please enter a valid zipcode.');
  } else {
    textbox.setCustomValidity('');
  }
  return true;
}

function checkAreaCode(textbox) {
  var phoneRegex = /^\d{3}$/;
  if (textbox.value == '') {
    textbox.setCustomValidity('Please fill out this area code field.');
  } else if(!phoneRegex.test(textbox.value)){
    textbox.setCustomValidity('please enter a valid area code.');
  } else {
    textbox.setCustomValidity('');
  }
  return true;
}
