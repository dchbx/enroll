require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_person_aasm_terminated_on")
describe ChangePersonDob, dbclean: :after_each do
  let(:given_task_name) { "change_person_aasm_terminated_on" }
  subject { ChangePersonAasmTerminatedOn.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "changing enrollment aasm and terminated on date" do
   let(:person) { FactoryGirl.create(:person) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("terminated_on").and_return("01/01/2011")
      allow(ENV).to receive(:[]).with("enrollment_hbx_id").and_return(hbx_enrollment.hbx_id)
      allow(ENV).to receive(:[]).with("aasm_state").and_return("coverage_enrolled")
    end

    it "should change aasm state on date" do
       subject.migrate
       person.reload
       expect(person.primary_family.active_household.hbx_enrollments.first.aasm_state).to eq "coverage_enrolled"
    end
  end
end
