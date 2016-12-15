function check_dob_change_implication(person_id, new_dob, element_to_replace_id) {
	var new_ssn = $('#person_ssn').val();
  $.ajax({
      type: "GET",
      data:{person_id: person_id, new_dob: new_dob, new_ssn: new_ssn, family_actions_id: element_to_replace_id},
      url: "/hbx_profiles/verify_dob_change"
    });
}
