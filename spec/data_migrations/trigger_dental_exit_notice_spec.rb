require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "trigger_dental_exit_notice")

describe TriggerDentalExitNotice do

  let(:given_task_name) { "trigger_dental_exit_notice" }
  subject { TriggerDentalExitNotice.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "triggering dental notice for renewal groups", dbclean: :after_each do
    let(:organization) { FactoryGirl.create(:organization, :with_active_and_renewal_plan_years)}
    let(:organization2) { FactoryGirl.create(:organization, :with_active_and_renewal_plan_years)}

    before(:each) do
      organization.employer_profile.renewing_plan_year.update_attribute(:start_on, Date.new(2018, 1, 1))
      organization2.employer_profile.renewing_plan_year.update_attribute(:start_on, Date.new(2018, 4, 1))
    end

    shared_examples_for "it should trigger notice for 1/1, 2/1, 3/1 ER groups" do |start_on|
      it "should call notice trigger for 1/1 group" do
        organization.employer_profile.renewing_plan_year.update_attribute(:start_on, start_on)
        expect(ShopNoticesNotifierJob).to receive(:perform_later).with(organization.employer_profile.id.to_s, "employer_renewal_dental_carriers_exiting_notice")
        subject.migrate
      end
    end

    it_behaves_like "it should trigger notice for 1/1, 2/1, 3/1 ER groups", Date.new(2018, 1, 1)
    it_behaves_like "it should trigger notice for 1/1, 2/1, 3/1 ER groups", Date.new(2018, 2, 1)
    it_behaves_like "it should trigger notice for 1/1, 2/1, 3/1 ER groups", Date.new(2018, 3, 1)

    shared_examples_for "it should not trigger notice for 12/1, 4/1 ER groups" do |start_on|
      it "should call notice trigger for 1/1 group" do
        organization.employer_profile.renewing_plan_year.update_attribute(:start_on, start_on)
        expect(ShopNoticesNotifierJob).not_to receive(:perform_later).with(organization2.employer_profile.id.to_s, "employer_renewal_dental_carriers_exiting_notice")
        subject.migrate
      end
    end

    it_behaves_like "it should not trigger notice for 12/1, 4/1 ER groups", Date.new(2018, 4, 1)
    it_behaves_like "it should not trigger notice for 12/1, 4/1 ER groups", Date.new(2017, 12, 1)

  end
end
