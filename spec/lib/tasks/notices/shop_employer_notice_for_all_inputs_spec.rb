require 'rails_helper'
Rake.application.rake_require "tasks/notices/shop_employer_notice_for_all_inputs"
include ActiveJob::TestHelper
Rake::Task.define_task(:environment)

RSpec.describe 'Generate notices to employer by taking hbx_ids, feins, employer_ids and event name', :type => :task, dbclean: :after_each do

  let!(:event_name)       { 'rspec-event' }
  let!(:employer_profile) { FactoryGirl.create(:employer_profile, plan_years: [plan_year]) }
  let!(:organization)     { FactoryGirl.create(:organization, employer_profile: employer_profile) }
  let!(:plan_year)        { FactoryGirl.create(:plan_year) }
  let!(:params)           { {recipient: employer_profile, event_object: plan_year, notice_event: event_name} }

  after :each do
    ['event', 'hbx_ids', 'feins', 'employer_ids'].each do |env_key|
      ENV[env_key] = nil
    end
  end

  context "when hbx_ids are given", dbclean: :after_each do
    it "should trigger notice" do
      ENV['event'] = event_name
      ENV['hbx_ids'] = employer_profile.hbx_id
      expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(params).and_return(true)
      Rake::Task['notice:shop_employer_notice_event'].execute
    end
  end

  context "when event name is not given", dbclean: :after_each do
    it "should not trigger notice" do
      ENV['hbx_ids'] = employer_profile.hbx_id
      expect_any_instance_of(Observers::NoticeObserver).not_to receive(:deliver)
      Rake::Task['notice:shop_employer_notice_event'].execute
    end
  end

  context "when feins are given", dbclean: :after_each do
    it "should trigger notice when fein is given" do
      ENV['event'] = event_name
      ENV['feins'] = employer_profile.organization.fein
      expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(params).and_return(true)
      Rake::Task['notice:shop_employer_notice_event'].execute
    end
  end

  context "when feins are given", dbclean: :after_each do
    it "should trigger when one employer_id is given" do
      ENV['employer_ids'] = employer_profile.id
      ENV['event'] = event_name
      expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(params).and_return(true)
      Rake::Task['notice:shop_employer_notice_event'].execute(employer_ids: "987", event: event_name)
    end
  end

end