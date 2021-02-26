require "rails_helper"
require 'csv'
require File.join(Rails.root, "app", "reports", "hbx_reports", "outstanding_monthly_enrollments")
require "#{Rails.root}/app/helpers/config/aca_helper"

describe OutstandingMonthlyEnrollments, dbclean: :around_each do
  
  context 'reports:outstanding_monthly_enrollments_report' do

    before(:each) do 
      # allow(ENV).to receive(:[]).with("start_date").and_return(start_date)
    end

    let!(:start_date) {"2/1/2019"}
    let!(:effective_on) {Date.strptime(start_date,'%m/%d/%Y')}
    let(:given_task_name) { "outstanding_monthly_enrollments"}
    subject { OutstandingMonthlyEnrollments.new(given_task_name, double(:current_scope => nil)) }

    after(:all) do
      dir_path = "#{Rails.root}/hbx_report/"
      Dir.foreach(dir_path) do |file|
        File.delete File.join(dir_path, file) if File.file?(File.join(dir_path, file))
      end
      Dir.delete(dir_path)
    end

    it 'should generate csv report with given headers' do
      ClimateControl.modify start_date:start_date do 

        subject.migrate
        result =  [[ "Employer ID",
        "Employer FEIN", 
        "Employer Name",
        "Open Enrollment Start",
        "Open Enrollment End",
        "Employer Plan Year Start Date",
        "Plan Year State",
        "Covered Lives",
        "Enrollment Reason",
        "Employer State",
        "Initial/Renewal?",
        "Binder Paid?",
        "Enrollment Group ID",
        "Carrier",
        "Plan",
        "Plan Hios ID",
        "Enrollment Purchase Date/Time",
        "Coverage Start Date",
        "Enrollment State",
        "Subscriber HBX ID", 
        "Subscriber First Name",
        "Subscriber Last Name",
        "Policy in Glue?",
        "Quiet Period?"]]
        data = CSV.read "#{Rails.root}/hbx_report/#{effective_on.strftime('%Y%m%d')}_employer_enrollments_#{Time.now.strftime('%Y%m%d%H%M')}.csv"
        expect(data).to eq result
      end
    end

    it 'should generate user csv report in hbx_report' do
      ClimateControl.modify start_date:start_date do 
        subject.migrate
        expect(File.exists?( "#{Rails.root}/hbx_report/#{effective_on.strftime('%Y%m%d')}_employer_enrollments_#{Time.now.strftime('%Y%m%d%H%M')}.csv")).to be true
      end
    end
  end
end
