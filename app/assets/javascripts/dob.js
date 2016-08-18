function check_dob_change_implication(person_id, new_dob) {
	var new_ssn = $('#person_ssn').val();
  $.ajax({
      type: "GET",
      data:{person_id: person_id, new_dob: new_dob, new_ssn: new_ssn},
      url: "/hbx_profiles/verify_dob_change"
    }); 
}
