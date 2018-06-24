require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "assign_attested_residency_state")

describe AssignAttestedResidency, :dbclean => :after_each do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let(:active_household) { family.active_household }
  let(:enrollment) { FactoryGirl.create(:hbx_enrollment,
                       household: active_household,
                       coverage_kind: "health",
                       effective_on: TimeKeeper.date_of_record.beginning_of_month,
                       enrollment_kind: "open_enrollment",
                       kind: "individual",
                       submitted_at: TimeKeeper.date_of_record,
                       aasm_state: 'coverage_selected') }

  subject { AssignAttestedResidency.new("assign_attested_residency_state", double(:current_scope => nil)) }

  shared_examples_for "attested residency" do |current_state, kind, updated_residency_state|
    before do
      enrollment.update_attributes(:aasm_state => current_state, :kind => kind)
      allow(active_household).to receive(:hbx_enrollments).and_return([enrollment])
      subject.migrate
      person.reload
    end

    it "test" do
      expect(family.family_members.first.person.consumer_role.local_residency_validation).to eq updated_residency_state
    end
  end

  HbxEnrollment::ENROLLED_STATUSES.each do |status|
    it_behaves_like "attested residency", status, "individual", "attested"
    it_behaves_like "attested residency", status, "employer_sponsored", nil
  end

  (HbxEnrollment::TERMINATED_STATUSES - ["unverified"]).each do |status|
    it_behaves_like "attested residency", status, "individual", nil
  end
end
