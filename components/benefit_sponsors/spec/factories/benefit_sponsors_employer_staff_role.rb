# frozen_string_literal: true

FactoryBot.define do

  factory :benefit_sponsor_employer_staff_role, class: 'EmployerStaffRole' do
    person
    is_owner { true }
    benefit_sponsor_employer_profile_id { create(:benefit_sponsors_organizations_aca_shop_cca_employer_profile, :with_organization_and_site).id }
  end
end
