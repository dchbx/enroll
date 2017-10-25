RSpec.shared_examples "person params examples" do |class_name|

  let!(:primary_member_person_attr1) {
    {
        first_name: 'ivl',
        middle_name: 'X',
        last_name: 'test',
        gender: "male",
        dob: dob.to_date,
        ssn: '123121234',
        no_ssn: "0",
        us_citizen: 'true',
        naturalized_citizen: 'true',
        indian_tribe_member: 'true',
        tribal_id: '1234',
        is_incarcerated: 'true',
        is_physically_disabled: 'true',
        eligible_immigration_status: "false",
        ethnicity: ["", "", "", "", "", "", ""],
        addresses: class_address1.to_a,
        phones: class_phone1.to_a,
        emails: class_email1.to_a,
        no_dc_address: "false"
    }
  }

  let!(:family_member_person_attr1) {
    {
        first_name: 'ivl',
        middle_name: 'X',
        last_name: 'test',
        gender: "male",
        dob: dob.to_date,
        ssn: '123121234',
        no_ssn: "0",
        us_citizen: 'true',
        naturalized_citizen: 'true',
        indian_tribe_member: 'true',
        tribal_id: '1234',
        is_incarcerated: 'true',
        is_physically_disabled: 'true',
        eligible_immigration_status: "false",
        ethnicity: ["", "", "", "", "", "", ""],
        addresses: class_address1.to_a,
        no_dc_address: "false"
    }
  }


  let!(:person_params2) {
    {
        "first_name" => 'ivl',
        "middle_name" => 'X',
        "last_name" => 'test',
        "gender" => "male",
        "dob" => dob.to_date,
        "ssn" => '123121234',
        "no_ssn" => "0",
        "relationship" => 'spouse',
        "is_applying_coverage" => 'true',
        "us_citizen" => 'true',
        "naturalized_citizen" => 'true',
        "indian_tribe_member" => 'true',
        "tribal_id" => '1234',
        "is_incarcerated" => 'true',
        "is_physically_disabled" => 'true',
        "eligible_immigration_status" => "false",
        "ethnicity" => ["", "", "", "", "", "", ""],
        "no_dc_address" => "false"
    }
  }

  let!(:person_primary_params2) {
    {
        "first_name" => 'ivl',
        "middle_name" => 'X',
        "last_name" => 'test',
        "name_sfx" => "",
        "gender" => "male",
        "is_applying_coverage" => 'true',
        "us_citizen" => 'true',
        "naturalized_citizen" => 'true',
        "indian_tribe_member" => 'true',
        "tribal_id" => '1234',
        "is_incarcerated" => 'true',
        "is_physically_disabled" => 'true',
        "eligible_immigration_status" => "false",
        "ethnicity" => ["", "", "", "", "", "", ""],
        "no_dc_address" => "false"
    }
  }

end
