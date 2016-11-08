FactoryGirl.define do
  factory :permission do
    modify_family true
    modify_employer true
    revert_application true
    list_enrollments true
    send_broker_agency_message true
    approve_broker true
    approve_ga true
  	modify_admin_tabs true
  	view_admin_tabs  true

    trait :hbx_staff do
    end

    trait :hbx_read_only do
      modify_family true
      modify_employer false
      revert_application false
      list_enrollments true
      send_broker_agency_message false
      approve_broker false
      approve_ga false
    	modify_admin_tabs false
    	view_admin_tabs  true
    end

    trait :hbx_csr_supervisor do
      modify_family true
      modify_employer true
      revert_application true
      list_enrollments true
      send_broker_agency_message false
      approve_broker false
      approve_ga false
    	modify_admin_tabs false
      view_admin_tabs  false
    end

    trait :hbx_csr_tier2 do
      modify_family true
      modify_employer true
      revert_application false
      list_enrollments false
      send_broker_agency_message false
      approve_broker false
      approve_ga false
    	modify_admin_tabs false
    	view_admin_tabs false
    end

    trait :hbx_csr_tier1 do
      modify_family true
      modify_employer false
      revert_application false
      list_enrollments false
      send_broker_agency_message false
      approve_broker false
      approve_ga false
    	modify_admin_tabs false
    	view_admin_tabs  false
    end


    trait :developer do
      modify_family false
      modify_employer false
      revert_application false
      list_enrollments false
      send_broker_agency_message false
      approve_broker false
      approve_ga false
      modify_admin_tabs false
      view_admin_tabs  false
    end
  end
end