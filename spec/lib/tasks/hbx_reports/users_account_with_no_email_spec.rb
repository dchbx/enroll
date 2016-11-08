require 'rails_helper'
require 'rake'
require 'csv'

describe 'user account with no email address' do
  describe 'report:user_account:with_no_email_address' do
    let(:person) { FactoryGirl.create(:person) }
    let(:user) { FactoryGirl.create(:user, person: person, oim_id:'example1', email:'', roles: ['consumer'], created_at: TimeKeeper.date_of_record) }
    before do
      load File.expand_path("#{Rails.root}/lib/tasks/hbx_reports/users_account_with_no_email.rake", __FILE__)
      Rake::Task.define_task(:environment)
    end

    it 'should generate csv report with user and person information' do
      user.reload
      start_date = (TimeKeeper.date_of_record-5.days).strftime('%d/%m/%Y')
      end_date = TimeKeeper.date_of_record.strftime('%d/%m/%Y')
      Rake::Task["report:user_account:with_no_email_address"].invoke(start_date,end_date)
      result =  [["username", "user_first_name", "user_last_name", "user_roles", "person_hbx_id", "person_home_email", "person_work_email", "user_created_at"], ["example1", "John", person.last_name, "[\"consumer\"]", person.hbx_id, person.emails.first.address, "", person.user.created_at.to_s]]
      data = CSV.read "#{Rails.root}/hbx_report/users_account_with_no_email.csv"
      expect(data).to eq result
    end

    it 'should generate user csv report in hbx_report' do
      start_date = (Date.today-10).strftime('%d/%m/%Y')
      end_date = Date.today.strftime('%d/%m/%Y')
      Rake::Task["report:user_account:with_no_email_address"].invoke(start_date,end_date)
      expect(File.directory?("#{Rails.root}/hbx_report")).to be true
      expect(File.exists?("#{Rails.root}/hbx_report/users_account_with_no_email.csv")).to be true
    end

    after :all do
      File.delete("#{Rails.root}/hbx_report/users_account_with_no_email.csv") if File.exist?("#{Rails.root}/hbx_report/users_account_with_no_email.csv")
    end
  end
end
