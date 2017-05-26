require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_conversion_flag")

describe PopulateConversionFlag, dbclean: :after_each do

  let(:given_task_name) { "populate_conversion_flag" }
  subject { PopulateConversionFlag.new(given_task_name, double(:current_scope => nil)) }

  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:profile_source) { 'self_serve' }
  let!(:employer_profile) { FactoryGirl.create(:employer_with_renewing_planyear, profile_source: profile_source, start_on: start_on, registered_on: 3.months.ago)}

  context "non conversion employer" do
    it "should set conversion flag to false" do
      subject.migrate
      employer_profile.reload
      expect(employer_profile.active_plan_year.is_conversion).to be_falsey
      expect(employer_profile.renewing_plan_year.is_conversion).to be_falsey
    end
  end

  context "conversion employer" do
    let(:profile_source) { "conversion" }

    it "should set conversion flag to true" do
      subject.migrate
      employer_profile.reload
      expect(employer_profile.active_plan_year.is_conversion).to be_truthy
      expect(employer_profile.renewing_plan_year.is_conversion).to be_falsey
    end
  end
end