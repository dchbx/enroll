require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "move_enrollment_between_two_accounts")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe MoveEnrollmentBetweenTwoAccount, dbclean: :after_each do

  let(:given_task_name) { "move_enrollment_between_two_accounts" }
  subject { MoveEnrollmentBetweenTwoAccount.new(given_task_name, double(:current_scope => nil)) }

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "it should move an ivl enrollment" do
    let(:family1) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:family2) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) {
       FactoryBot.create(:hbx_enrollment,
                           household: family1.active_household,
                           coverage_kind: "health",
                           kind: "individual",
                           submitted_at: TimeKeeper.date_of_record,
                           consumer_role: consumer_role,
                           family: family1,
                           aasm_state: 'shopping')
                        }
    let!(:consumer_role) {FactoryBot.create(:consumer_role,person: family1.family_members[0].person)}
    let!(:consumer_role1) {FactoryBot.create(:consumer_role,person: family2.family_members[0].person)}
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile,:open_enrollment_coverage_period)}
    around do |example|
      ClimateControl.modify old_account_hbx_id: family1.family_members[0].person.hbx_id,  
                            new_account_hbx_id: family2.family_members[0].person.hbx_id,    
                            enrollment_hbx_id: hbx_enrollment.hbx_id do
        example.run
      end
    end

    before do
      coverage_household_member = family1.households.first.coverage_households.first.coverage_household_members.first
      h = HbxEnrollmentMember.new_from(coverage_household_member: coverage_household_member)
      h.eligibility_date = TimeKeeper.date_of_record-2
      h.coverage_start_on = TimeKeeper.date_of_record-2
      hbx_enrollment.hbx_enrollment_members << h
      hbx_enrollment.save
      consumer_role1=consumer_role1
    end
    it "should move an ivl enrollment" do
      expect(family1.active_household.hbx_enrollments).to include(hbx_enrollment)
      expect(family2.active_household.hbx_enrollments).not_to include(hbx_enrollment)
      @size1=family1.active_household.hbx_enrollments.size
      @size2=family2.active_household.hbx_enrollments.size
      subject.migrate
      family1.reload
      family2.reload
      expect(family1.active_household.hbx_enrollments).not_to include(hbx_enrollment)
      expect(family2.active_household.hbx_enrollments.last.kind).to eq "individual"
      expect(family2.active_household.hbx_enrollments.last.consumer_role).to eq consumer_role1
      expect(family1.active_household.hbx_enrollments.size).to eq @size1-1
      expect(family2.active_household.hbx_enrollments.size).to eq @size2+1
    end
  end
  describe "it should move a shop enrollment", dbclean: :after_each do
    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'

    let(:product) do
      current_benefit_market_catalog
      BenefitMarkets::Products::Product.where({
        _type: /Health/,
        "application_period.min" => current_benefit_market_catalog.application_period.min
      }).first
    end

    let(:family1) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:family2) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:enr_env_support) {{old_account_hbx_id: family1.family_members[0].person.hbx_id, new_account_hbx_id: family2.family_members[0].person.hbx_id, enrollment_hbx_id: hbx_enrollment.hbx_id}}
    let(:hbx_enrollment) {
      FactoryBot.create(:hbx_enrollment,
                         household: family1.active_household,
                         coverage_kind: "health",
                         kind: "employer_sponsored",
                         family: family1,
                         submitted_at: TimeKeeper.date_of_record,
                         employee_role: employee_role,
                         aasm_state: 'shopping',
                         benefit_group_assignment: benefit_group_assignment,
                         benefit_group_id: benefit_group_assignment.benefit_group.id,
                         product_id: product.id,
                         benefit_sponsorship_id: benefit_sponsorship.id,
                         sponsored_benefit_package_id: current_benefit_package.id)}

    let(:employee_role) {FactoryBot.create(:employee_role,person: family1.family_members[0].person, census_employee:census_employee, employer_profile: benefit_sponsorship.profile)}
    let!(:employee_role2) {FactoryBot.create(:employee_role,person: family2.family_members[0].person, census_employee:census_employee, employer_profile: benefit_sponsorship.profile)}
    let(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package) }
    let(:benefit_group_assignment) {census_employee.benefit_group_assignments.first}
    before do
      coverage_household_member = family1.households.first.coverage_households.first.coverage_household_members.first
      h = HbxEnrollmentMember.new_from(coverage_household_member: coverage_household_member)
      h.eligibility_date = TimeKeeper.date_of_record
      h.coverage_start_on = TimeKeeper.date_of_record
      hbx_enrollment.hbx_enrollment_members << h
      hbx_enrollment.save
    end
    it "should move a shop enrollment" do
      with_modified_env enr_env_support do 
        expect(family1.active_household.hbx_enrollments).to include(hbx_enrollment)
        expect(family2.active_household.hbx_enrollments).not_to include(hbx_enrollment)
        @size1=family1.active_household.hbx_enrollments.size
        @size2=family2.active_household.hbx_enrollments.size
        subject.migrate
        family1.reload
        family2.reload
        expect(family1.active_household.hbx_enrollments).not_to include(hbx_enrollment)
        expect(family2.active_household.hbx_enrollments.last.kind).to eq "employer_sponsored"
        expect(family1.active_household.hbx_enrollments.size).to eq @size1-1
        expect(family2.active_household.hbx_enrollments.size).to eq @size2+1
      end
    end
  end
end
