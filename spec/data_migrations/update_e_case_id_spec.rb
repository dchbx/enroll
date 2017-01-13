require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_e_case_id")

describe MigratePlanYear do
  let(:given_task_name) { "update_e_case_id" }
  subject { UpdateECaseId.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating the e_case_id" do
    let(:person)     { FactoryGirl.create(:person)}
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person, e_case_id: "urn:openhbx:hbx:dc0:resources:v1:curam:integrated_case#78907")}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("e_case_id").and_return(235)
    end
    context "given e_case_id is present for a family" do
      it "updating e_case_id" do
        subject.migrate
        family.reload
        expect(family.e_case_id).to eq "urn:openhbx:hbx:dc0:resources:v1:curam:integrated_case#235"
      end
    end
  end
end
