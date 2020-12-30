require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::RosterUploadService, type: :model, :dbclean => :after_each do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"
    let(:service_class) { BenefitSponsors::Services::RosterUploadService }
    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
    let!(:user) { FactoryBot.create(:user) }
    let!(:person) { FactoryBot.create(:person) }
    let(:ce) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile) }
    let(:address_params) {ce.address.attributes}
    let(:ini_address_form) {Organizations::OrganizationForms::AddressForm.new(address_params)}
    let(:params) {{first_name: ce.first_name, last_name: ce.last_name, gender: ce.gender, ssn: ce.ssn, dob: ce.dob, hired_on: ce.hired_on.strftime("%m/%d/%Y"), address: ini_address_form }}

    describe "init_census_record" do
      before :each do
        file = Dir.glob(File.join(Rails.root, "spec/test_data/census_employee_import/DCHL Employee Census.xlsx")).first
        allow(user).to receive(:person).and_return(person)
        @form = BenefitSponsors::Forms::CensusRecordForm.new(params)
        @result = service_class.new({file: file, profile: benefit_sponsorship.profile}).init_census_record(ce, @form)
      end

      it "should return date in date format" do
        expect(@result.hired_on).to eq ce.hired_on.to_date
      end
    end

    describe "terminate_census_record" do
      let(:params) {{first_name: ce.first_name, last_name: ce.last_name, gender: ce.gender, ssn: ce.ssn, dob: ce.dob, hired_on: ce.hired_on.strftime("%m/%d/%Y"), employment_terminated_on: TimeKeeper.date_of_record.strftime("%m/%d/%Y"), address: ini_address_form }}

      before :each do
        termination_hash = {}
        EmployeeTerminationMap = Struct.new(:employee, :employment_terminated_on)
        termination_hash[0] = EmployeeTerminationMap.new(ce, TimeKeeper.date_of_record.strftime("%m/%d/%Y"))
        file = Dir.glob(File.join(Rails.root, "spec/test_data/census_employee_import/DCHL Employee Census.xlsx")).first
        allow(user).to receive(:person).and_return(person)
        @form = BenefitSponsors::Forms::CensusRecordForm.new(params)
        @result = service_class.new({file: file, profile: benefit_sponsorship.profile})
        @result.instance_variable_set(:@terminate_queue, termination_hash)
      end

      it 'should return employment termination date in string format' do
        expect(@form.employment_terminated_on.class).to eq String
      end

      it "should terminate census employee if present" do
        expect(@result.terminate_census_records).to eq true
        expect(ce.employment_terminated_on).to eq TimeKeeper.date_of_record
      end
    end
  end
end
