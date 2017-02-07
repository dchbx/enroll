 // check that dob entered is not a future date
$(document).on('change', '#jq_datepicker_ignore_person_dob, #family_member_dob_, #jq_datepicker_ignore_organization_dob, #jq_datepicker_ignore_census_employee_dob, [name="jq_datepicker_ignore_dependent[dob]"]', function() {
  var entered_dob = new Date($(this).val());
  var todays_date = dchbx_enroll_date_of_record();
  
  if(entered_dob > todays_date) {
    alert("Please enter a birthdate that does not take place in the future.");
    $(this).val("");
    $(this).focus();
  }
});