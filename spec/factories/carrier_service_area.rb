FactoryGirl.define do
  factory :carrier_service_area do
    issuer_hios_id '12345'
    service_area_id 1
    service_area_name 'Primary Area'
    serves_entire_state true
    county_name nil
    county_code nil
    state_code nil
    service_area_zipcode nil
    partial_county_justification nil
    active_year { TimeKeeper.date_of_record.year }

    trait :for_partial_state do
      service_area_name 'Partial State Area'
      serves_entire_state false
      county_name "Foxboro"
      county_code '015'
      state_code '25'
      service_area_zipcode '10010'
    end

    trait :for_partial_county do
      service_area_name 'Partial County Area'
      serves_entire_state false
      county_name "Foxboro"
      county_code '015'
      state_code '25'
      service_area_zipcode "10210"
      partial_county_justification "A reason for only serving a partial county"
    end
  end
end
