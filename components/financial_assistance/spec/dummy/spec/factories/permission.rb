# frozen_string_literal: true

FactoryBot.define do
  factory :permission do
    modify_family { true }
    modify_employer { true }
    revert_application { true }
    list_enrollments { true }
    send_broker_agency_message { true }
    approve_broker { true }
    approve_ga { true }
    modify_admin_tabs { true }
    view_admin_tabs { true }
    can_lock_unlock { false }
    can_reset_password { false }

    trait :hbx_staff do
      can_complete_resident_application { true }
      can_add_sep { true }
    end
  end
end