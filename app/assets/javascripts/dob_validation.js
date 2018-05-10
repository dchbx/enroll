 // check that dob entered is not a future date and 110 years ago
$(document).on('change', '#jq_datepicker_ignore_person_dob, #family_member_dob_, #jq_datepicker_ignore_organization_dob, #jq_datepicker_ignore_census_employee_dob, #census_members_plan_design_census_employee_dob, [name="jq_datepicker_ignore_dependent[dob]"]', function() {
  var entered_date = $(this).val();
  var entered_dob = new Date($(this).val());
  var entered_year =  entered_date.substring(entered_date.length -4);
  var todays_date = dchbx_enroll_date_of_record();
  if (entered_date.value == '') {
    this.setCustomValidity('Please fill out this date of birth field.');
  }
  else if(entered_dob > todays_date){
    this.setCustomValidity('Please enter a date of birth that does not take place in the future.');
  }
  else if(entered_year < (new Date().getFullYear() - 110)) {
    this.setCustomValidity('Please enter a date of birth not more than 110 years ago.');
  }
  else {
    this.setCustomValidity('');
  }
});

// check that dob entered is not current year for employer
$(document).on('change', '#jq_datepicker_ignore_organization_dob', function() {
  var entered_date = $(this).val();
  var entered_dob = new Date($(this).val());
  var entered_year =  entered_date.substring(entered_date.length -4);
  var todays_date = dchbx_enroll_date_of_record();
  if (entered_date.value == '') {
    this.setCustomValidity('Please fill out this date of birth field.');
  }
  else if(entered_dob > todays_date){
    this.setCustomValidity('Please enter a date of birth that does not take place in the future.');
  }
  else if(entered_year == new Date().getFullYear()){
    this.setCustomValidity('Please enter a date of birth that is not in the current year.');
  }
  else if(entered_year < (new Date().getFullYear() - 110)) {
    this.setCustomValidity('Please enter a date of birth not more than 110 years ago.');
  }
  else {
    this.setCustomValidity('');
  }
});
