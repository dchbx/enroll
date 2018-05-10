require 'rails_helper'
require File.join(Rails.root, "lib/mongoid_migration_task")
require File.join(Rails.root, "app/helpers/config/aca_helper")
require File.join(Rails.root, "app/helpers/config/site_helper")
require File.join(Rails.root, "app/helpers/config/contact_center_helper")
include Config::AcaHelper
include Config::SiteHelper
include Config::ContactCenterHelper

RSpec.describe 'The employees of MA new groups received a notice in their accounts that their coverage was terminated because no payment was received from their employer', :type => :task do
  let(:employer_profile)     { FactoryGirl.build(:employer_profile) }  
	let!(:organization1) { FactoryGirl.create(:organization, fein: "876456787", employer_profile: employer_profile) }
	let!(:organization2) { FactoryGirl.create(:organization, fein: "555123457", employer_profile:employer_profile) }
	
	before do
    load File.expand_path("#{Rails.root}/lib/tasks/migrations/disregard_termination_of_coverage_notice_er.rake", __FILE__)
    Rake::Task.define_task(:environment)    
    ENV['fein'] = "876456787 555123457"
    Rake::Task["secure_message:disregard_termination_of_coverage_notice_er"].invoke(fein: "876456787 555123457")
    employer_profile.reload
  end

  context "create employee messages" do
	  it 'should create secure inbox message for employee' do
      allow(Organization).to receive(:where).with(hbx_id: "3382429").and_return(organization1)
      allow(Organization).to receive(:where).with(hbx_id: "3504641").and_return(organization2)

	    message=employer_profile.inbox.messages.last      
	    expect(message.subject).to eq "Disregard Termination of Coverage Notice"
	    expect(message.from).to eq "#{aca_state_abbreviation} #{site_short_name}"
	    expect(message.body).to eq "Your employees should please disregard the notice that they received on #{ENV['notice_date']} stating that their employer was not offering health coverage through the #{aca_state_name} #{site_short_name}. This notice was sent in error. We apologize for any inconvenience this may have caused."+ 
    "<br><br>Your employees have received a correction message clarifying that their employer has completed its open enrollment period and has successfully met all eligibility requirements. It also confirms that the employees plan selection, if any, will go into effect on the coverage effective date shown in your account."+ 
    "<br><br>Thank you for enrolling into employer-sponsored coverage through the #{site_short_name}." + 
    "<br><br>If you have any questions, please call #{contact_center_phone_number} (TTY: #{contact_center_tty_number}), press option 1."
	  end
  end
end
