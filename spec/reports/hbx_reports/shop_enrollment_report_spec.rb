require "rails_helper"
require 'csv'
require File.join(Rails.root, "app", "reports", "hbx_reports", "shop_enrollment_report")

describe ShopEnrollmentReport do
  subject { ShopEnrollmentReport.new("shop_enrollment_report", double(:current_scope => nil)) }

  before(:each) do
    # allow(ENV).to receive(:[]).with("purchase_date_start").and_return('06/01/2018')
    # allow(ENV).to receive(:[]).with("purchase_date_end").and_return('06/10/2018')
    subject.migrate
    @file = "#{Rails.root}/hbx_report/shop_enrollment_report.csv"
  end

  it "creates csv file" do
    ClimateControl.modify purchase_date_start:"#{06/01/2018}", purchase_date_end:"#{06/10/2018}" do 
      file_context = CSV.read(@file)
      expect(file_context.size).to be > 0
    end
  end

  it "returns correct fields" do
    ClimateControl.modify purchase_date_start:"#{06/01/2018}", purchase_date_end:"#{06/10/2018}" do 

      CSV.foreach(@file, :headers => true) do |csv|
        expect(csv).to eq ['Employer ID', 'Employer FEIN', 'Employer Name', 'Plan Year Start', 'Plan Year State', 'Employer State',
                           'Enrollment GroupID', 'Purchase Date', 'Coverage Start', 'Coverage Kind', 'Enrollment State', 'Subscriber HBXID',
                           'Subscriber First Name','Subscriber Last Name', 'HIOS ID', 'Family Size', 'Enrollment Reason', 'In Glue']
      end
    end
  end

  after(:all) do
    FileUtils.rm_rf(Dir["#{Rails.root}//hbx_report"])
  end
end
