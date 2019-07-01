require 'rails_helper'
require 'rake'

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe 'terminating employer active benefit application & enrollments', :dbclean => :around_each do
  describe 'migrations:terminate_benefit_application' do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let!(:sponsored_benefit_package) { initial_application.benefit_packages[0] }
    let!(:employer_profile) {benefit_sponsorship.profile}
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    let(:employee_role)     { FactoryBot.create(:employee_role)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let!(:census_employee) { FactoryBot.create(:census_employee, employer_profile: employer_profile, employee_role_id: employee_role.id) }
    let!(:termination_date){TimeKeeper.date_of_record.strftime('%m/%d/%Y')}
    let(:enrollment)     { FactoryBot.create(:hbx_enrollment, household: family.active_household, family:family, benefit_sponsorship: benefit_sponsorship, sponsored_benefit_package_id:sponsored_benefit_package.id, employee_role_id: employee_role.id, aasm_state:'coverage_selected')}
    let!(:fein)          {abc_organization.fein}
    let!(:py_end_on){TimeKeeper.date_of_record.end_of_month.strftime('%m/%d/%Y')}
    let(:effective_period) { start_on..end_on }
    let(:start_on)       { TimeKeeper.date_of_record.next_month.next_month.beginning_of_month - 1.year }
    let(:end_on)         { TimeKeeper.date_of_record.next_month.end_of_month }
    let(:benefit_application)         { initial_application }

    before do
      enrollment.update_attributes(aasm_state:'coverage_selected')
      employee_role.update_attributes(census_employee_id: census_employee.id)
    end

    context 'should terminate benefit application & enrollment and update benefit application & enrollment end_on and terminated date', :dbclean => :around_each do

      before do
        load File.expand_path("#{Rails.root}/lib/tasks/migrations/terminate_benefit_application.rake", __FILE__)
        Rake::Task.define_task(:environment)
        Rake::Task["migrations:terminate_benefit_application"].reenable
        Rake::Task["migrations:terminate_benefit_application"].invoke(fein,py_end_on,termination_date)
        benefit_application.reload
        enrollment.reload
      end

      it "should update application end date" do
        expect(benefit_application.effective_period.max).to eq TimeKeeper.date_of_record.end_of_month
      end

      it "should update application terminated on date" do
        expect(benefit_application.terminated_on).to eq TimeKeeper.date_of_record
      end

      it "should update application aasm_state" do
        expect(benefit_application.aasm_state).to eq :terminated
      end

      it "should update enrollment terminated on date" do
        expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record.end_of_month
      end

      it "should update enrollment termination submitted on date" do
        expect(enrollment.termination_submitted_on).to eq TimeKeeper.date_of_record
      end

      it "should update enrollment aasm_state" do
        expect(enrollment.aasm_state).to eq "coverage_terminated"
      end
    end

    context 'should not terminate benefit application' do

      before do
        Rake::Task["migrations:terminate_benefit_application"].reenable
        Rake::Task["migrations:terminate_benefit_application"].invoke(fein,py_end_on,termination_date)
        benefit_application.update_attribute(:aasm_state,'published')
        benefit_application.reload
      end

      it "should NOT update application end date" do
        expect(benefit_application.effective_period.max).to eq benefit_application.effective_period.max
      end

      it "should NOT update application state" do
        expect(benefit_application.aasm_state).to eq :published
      end
    end
  end
end
