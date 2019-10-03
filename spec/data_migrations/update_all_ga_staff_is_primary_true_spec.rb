# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_all_ga_staff_is_primary_true")

describe UpdateAllGaStaffIsPrmaryTrue, dbclean: :after_each do
  let(:given_task_name) { "update_all_ga_staff_is_primary_true" }
  subject { UpdateAllGaStaffIsPrmaryTrue.new(given_task_name, double(:current_scope => nil)) }

  describe "updating the plan attributes" do
    let(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:general_agency_organization1) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
    let(:general_agency_profile1) { general_agency_organization1.general_agency_profile }
    let!(:general_agency_staff_role1) {FactoryBot.build(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile1.id, aasm_state: 'active')}
    let(:person1) {general_agency_staff_role1.person}

    let!(:general_agency_organization2) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
    let(:general_agency_profile2) { general_agency_organization2.general_agency_profile }
    let!(:general_agency_staff_role2) {FactoryBot.build(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile2.id, aasm_state: 'active')}
    let(:person2) {general_agency_staff_role2.person}

    before(:each) do
      person1.general_agency_staff_roles << general_agency_staff_role1
      person2.general_agency_staff_roles << general_agency_staff_role2
    end

    it "should update all general agency staff roles with is_primary true" do
      subject.migrate
      all_ga_staff_roles = Person.exists(general_agency_staff_roles: true).map(&:general_agency_staff_roles).flatten
      all_ga_staff_roles.each do |ga_staff|
        expect(ga_staff.is_primary).to be_truthy
      end
    end
  end
end
