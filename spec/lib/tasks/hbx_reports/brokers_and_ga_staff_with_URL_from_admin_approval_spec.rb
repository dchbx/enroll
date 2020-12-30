require 'rails_helper'
require 'rake'
require 'csv'

describe 'Broker and GA Staff Roles Invitations Monthly report', :dbclean => :after_each do
  context 'reports:shop brokers_and_ga_staff_with_URL_from_admin_approval' do

    before do
      load File.expand_path("#{Rails.root}/lib/tasks/hbx_reports/brokers_and_ga_staff_with_URL_from_admin_approval.rake", __FILE__)
      Rake::Task.define_task(:environment)
    end

    it "should invoke without errors" do
      expect { Rake::Task["reports:shop:brokers_and_ga_staff_with_URL_from_admin_approval"].invoke }.to_not raise_error
    end
  end
end
