require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "request_haven_timeout_verifications")

describe RequestHavenTimeoutVerifications, dbclean: :after_each do

  let(:given_task_name) { "request_haven_timeout_verifications" }
  subject { RequestHavenTimeoutVerifications.new(given_task_name, double(:current_scope => nil)) }

  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
  end

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "respond to Haven on TimeOut" do
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let!(:application) { FactoryGirl.create(:application, family: family) }
    let!(:applicant) { FactoryGirl.create(:applicant, application: application, is_ia_eligible: true) }

    it "should update date of termination" do
      expect(application.timeout_response_last_submitted_at).to eq nil
      expect(subject.migrate).to be_truthy
      application.reload
      expect(application.timeout_response_last_submitted_at).not_to eq nil
    end
  end
end
