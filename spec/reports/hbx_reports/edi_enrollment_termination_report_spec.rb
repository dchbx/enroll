require "rails_helper"
require 'csv'
require File.join(Rails.root, "app", "reports", "hbx_reports", "edi_enrollment_termination_report")
require "#{Rails.root}/app/helpers/config/aca_helper"

describe TerminatedHbxEnrollments do

  let(:given_task_name) { "enrollment_termination_on" }
  let(:person1) {FactoryBot.create(:person,
                                    :with_consumer_role,
                                    first_name: "F_name1",
                                    last_name:"L_name1")}
  let(:person2) {FactoryBot.create(:person,
                                    :with_employee_role,
                                    first_name: "Lis2",
                                    last_name:"L_name1")}
  let(:hbx_enrollment_member1){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family1.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let(:hbx_enrollment_member2){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family2.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  subject { TerminatedHbxEnrollments.new(given_task_name, double(:current_scope => nil)) }
  let(:from_state) { "applicant" }
  let(:to_state1) { "coverage_terminated" }
  let(:to_state2) { "coverage_termination_pending" }
  let(:transition_at) { Date.yesterday.midday }
  let(:valid_params1) { {from_state: from_state, to_state: to_state1, transition_at: transition_at} }
  let(:params1) { valid_params1 }
  let(:workflow_state_transition1) { WorkflowStateTransition.new(params1) }
  let(:valid_params2) { {from_state: from_state, to_state: to_state2, transition_at: transition_at} }
  let(:params2) { valid_params2 }
  let(:workflow_state_transition2) { WorkflowStateTransition.new(params2) }
  let(:family1) { FactoryBot.create(:family, :with_primary_family_member, :person => person1)}
  let(:site)                  { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let(:issuer_profile)  { FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
  let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile: issuer_profile)}
  let(:hbx_enrollment1) { FactoryBot.create(:hbx_enrollment,
                                            household: family1.active_household,
                                            product: product,
                                            family: family1,
                                            aasm_state:"coverage_terminated",
                                            hbx_enrollment_members: [hbx_enrollment_member1],
                                            termination_submitted_on: Date.yesterday.midday,
                                            workflow_state_transitions: [workflow_state_transition1])}
  let(:family2) { FactoryBot.create(:family, :with_primary_family_member, :person => person2)}
  let(:hbx_enrollment2) { FactoryBot.create(:hbx_enrollment,
                                             household: family2.active_household,
                                             family: family2,
                                             product: product,
                                             aasm_state:"coverage_termination_pending",
                                             hbx_enrollment_members: [hbx_enrollment_member2],
                                             termination_submitted_on: Date.yesterday.midday,
                                             workflow_state_transitions: [workflow_state_transition2])}

  before :all do
    DatabaseCleaner.clean
  end

  describe "correct data input" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end

    it "has the families with hbx_enrollments and correct states" do
      expect(hbx_enrollment1.coverage_terminated?).to be_truthy
      expect(hbx_enrollment2.coverage_termination_pending?).to be_truthy
    end

    it "has the families with hbx_enrollments and termination submitted on" do
      expect(hbx_enrollment1.workflow_state_transitions.first.transition_at.to_date).to eq Date.yesterday
      expect(hbx_enrollment2.workflow_state_transitions.first.transition_at.to_date).to eq Date.yesterday
    end
  end

  shared_examples_for "returns csv file list with terminated hbx_enrollments" do |field_name, result|
    let(:file) { Array.new }

    before :each do
      family1
      family2
      hbx_enrollment1
      hbx_enrollment2
      allow(CSV).to receive(:open).and_yield(file)
      subject.migrate
    end

    it "check the records included in file" do
      expect(file.length).to be > 1
    end

    it "returns correct #{field_name} in csv file" do
      file.map! { |line| line.map! { |field| "\"#{field}\"" }.join(',') }
      CSV.parse(file.join("\n"), :headers => true) do |line|
        expect(line[field_name]).to eq result
      end
    end
  end

  it_behaves_like "returns csv file list with terminated hbx_enrollments", 'Enrolled_Member_First_Name', "F_name1"
  it_behaves_like "returns csv file list with terminated hbx_enrollments", 'Enrolled_Member_Last_Name', "L_name1"
  it_behaves_like "returns csv file list with terminated hbx_enrollments", 'Employee_Census_State', "IVL"
  it_behaves_like "returns csv file list with terminated hbx_enrollments", 'Coverage_Type', "health"
  it_behaves_like "returns csv file list with terminated hbx_enrollments", 'Enrollment_State', "coverage_terminated"
  it_behaves_like "returns csv file list with terminated hbx_enrollments", 'Market_Kind', "employer_sponsored"

end
