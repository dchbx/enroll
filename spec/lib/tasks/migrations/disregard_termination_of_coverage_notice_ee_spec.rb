require 'rails_helper'
require File.join(Rails.root, "lib/mongoid_migration_task")
require File.join(Rails.root, "app/helpers/config/aca_helper")
require File.join(Rails.root, "app/helpers/config/site_helper")
require File.join(Rails.root, "app/helpers/config/contact_center_helper")
include Config::AcaHelper
include Config::SiteHelper
include Config::ContactCenterHelper

RSpec.describe 'The employees of MA new groups received a notice in their accounts that their coverage was terminated because no payment was received from their employer', :type => :task do
	let!(:person1) { FactoryGirl.create(:person, :with_work_email, hbx_id: "3382429") }
	let!(:person2) { FactoryGirl.create(:person, :with_work_email, hbx_id: "3504641") }
	
	before do
    load File.expand_path("#{Rails.root}/lib/tasks/migrations/disregard_termination_of_coverage_notice_ee.rake", __FILE__)
    Rake::Task.define_task(:environment)
    notice_date = TimeKeeper::date_of_record.strftime("%m/%d/%Y")	  	
    ENV['notice_date'] = notice_date
    ENV['hbx_id'] = "3382429 3504641"
    Rake::Task["secure_message1:disregard_termination_of_coverage_notice_ee"].invoke(hbx_id: "3382429 3504641", notice_date: notice_date)
    person1.reload
  end

  context "create employee messages" do
	  it 'should create secure inbox message for employee' do
      allow(Person).to receive(:where).with(hbx_id: "3382429").and_return(person1)
      allow(Person).to receive(:where).with(hbx_id: "3504641").and_return(person2)
	    message=person1.inbox.messages.last
	    expect(message.subject).to eq "Disregard Termination of Coverage Notice"
	    expect(message.from).to eq "#{aca_state_abbreviation} #{site_short_name}"
	    expect(message.body).to eq "Please disregard the notice that you received on #{ENV['notice_date']} stating that your employer was not offering health coverage through the #{aca_state_name} #{site_short_name}. This notice was sent in error. We apologize for any inconvenience this may have caused." +
   "<br><br>Your employer has completed its open enrollment period and has successfully met all eligibility requirements." + 
   "<br><br>Your plan selection, if any, will go into effect on the coverage effective date shown in your account." +
   "<br><br>Thank you for enrolling into employer-sponsored coverage through the #{site_short_name}."+ 
   "<br> <br>If you have any questions, please call #{contact_center_phone_number} (TTY: #{contact_center_tty_number}), press option 1."   
	  end
  end
end
