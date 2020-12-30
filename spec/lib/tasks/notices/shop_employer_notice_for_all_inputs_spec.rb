require 'rails_helper'
Rake.application.rake_require "tasks/notices/shop_employer_notice_for_all_inputs"
Rake::Task.define_task(:environment)

RSpec.describe 'Generate notices to employer by taking hbx_ids, feins, employer_ids and event name', :type => :task, dbclean: :after_each do

  let(:event_name)       { 'rspec-event' }
  let(:employer_profile) { FactoryBot.create(:employer_with_planyear) }
  let(:organization)     { FactoryBot.create(:organization, employer_profile: employer_profile) }
  let(:plan_year)        { employer_profile.plan_years.first }
  let(:params)           { {recipient: employer_profile, event_object: plan_year, notice_event: event_name} }

  context "when hbx_ids are given", dbclean: :after_each do
    pending "should trigger notice"

    # it "should trigger notice" do
    #   ClimateControl.modify event: event_name, hbx_ids: employer_profile.hbx_id do
    #     expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(params).and_return(true)
    #     Rake::Task['notice:shop_employer_notice_event'].execute
    #   end
    # end
  end

  context "when event name is not given", dbclean: :after_each do
    pending "should not trigger notice"

    # it "should not trigger notice" do
    #  ClimateControl.modify hbx_ids: employer_profile.hbx_id do
    #    expect_any_instance_of(Observers::NoticeObserver).not_to receive(:deliver)
    #    Rake::Task['notice:shop_employer_notice_event'].execute
    #  end
    # end
  end

  context "when feins are given", dbclean: :after_each do
    pending "should trigger notice when fein is given"
    # it "should trigger notice when fein is given" do
      # ClimateControl.modify event: event_name, feins: employer_profile.organization.fein do
      #  expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(params).and_return(true)
      #  Rake::Task['notice:shop_employer_notice_event'].execute
      # end
    # end
  end

  context "when feins are given", dbclean: :after_each do
    pending "should trigger when one employer_id is given"
    # it "should trigger when one employer_id is given" do
    #   ClimateControl.modify employer_ids: employer_profile.id, event: event_name do
    #   expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(params).and_return(true)
    #    Rake::Task['notice:shop_employer_notice_event'].execute(employer_ids: "987", event: event_name)
    #   end
    # end
  end
end
