require 'rails_helper'
require 'rake'
require 'csv'

describe 'Shop monthly enrollments report', :dbclean => :after_each do
  context 'reports:shop_monthly_enrollments' do

    let(:effective_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }

    before do
      load File.expand_path("#{Rails.root}/lib/tasks/hbx_reports/shop_monthly_enrollments.rake", __FILE__)
      Rake::Task.define_task(:environment)
    end

    after(:all) do
      dir_path = "#{Rails.root}/hbx_report/"
      Dir.foreach(dir_path) do |file|
        File.delete File.join(dir_path, file) if File.file?(File.join(dir_path, file))
      end
      Dir.delete(dir_path)
    end

    it 'should generate csv report with given headers' do
      Rake::Task["reports:shop_monthly_enrollments"].invoke
      result =  [['Employer Name', 'Employer FEIN', 'Initial/Renewing', 'Enrollment Group ID', 'Carrier', 'Enrollment Status', 'Submitted On']]
      data = CSV.read "#{Rails.root}/hbx_report/shop_monthly_enrollments_#{effective_on.strftime('%m_%d_%Y')}.csv"
      expect(data).to eq result
    end

    it 'should generate user csv report in hbx_report' do
      Rake::Task["reports:shop_monthly_enrollments"].invoke
      expect(File.exists?("#{Rails.root}/hbx_report/shop_monthly_enrollments_#{effective_on.strftime('%m_%d_%Y')}.csv")).to be true
    end
  end
end
