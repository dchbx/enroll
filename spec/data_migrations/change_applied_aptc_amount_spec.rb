require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_applied_aptc_amount")

describe ChangeAppliedAptcAmount, dbclean: :after_each do

  let(:given_task_name) { "change_applied_aptc_amount" }
  subject { ChangeAppliedAptcAmount.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating applied aptc amount for a given hbx_id" do

    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
      allow(ENV).to receive(:[]).with("applied_aptc_amount").and_return(450)
    end

    it "should update the applied aptc amount" do
      hbx_enrollment.applied_aptc_amount = 100
      hbx_enrollment.save
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.applied_aptc_amount.to_f).to eq 450.0
    end
  end
end
