require 'rails_helper'
require 'rake'

describe 'terminating employer active benefit application & enrollments', :dbclean => :around_each do
  describe 'migrations:terminate_benefit_application' do

    let!(:site)  { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, :with_benefit_market_catalog_and_product_packages, :cca) }
    let!(:benefit_market) { site.benefit_markets.first }
    let!(:benefit_market_catalog)  { benefit_market.benefit_market_catalogs.first }
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    let(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employee_role)     { FactoryGirl.create(:employee_role)}
    let(:benefit_sponsorship) { FactoryGirl.create(:benefit_sponsors_benefit_sponsorship, organization: organization, profile_id: organization.profiles.first.id, benefit_market: site.benefit_markets[0], employer_attestation: employer_attestation) }
    let!(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, aasm_state: :active) }
    let!(:product_package_kind) { :single_issuer }
    let!(:product_package) { benefit_market_catalog.product_packages.where(package_kind: product_package_kind).first }
    let!(:benefit_package) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }
    let(:family) { FactoryGirl.build(:family, :with_primary_family_member)}
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: organization.employer_profile, employee_role_id: employee_role.id) }
    let!(:termination_date){TimeKeeper.date_of_record.strftime('%m/%d/%Y')}
    let(:enrollment)     { FactoryGirl.build(:hbx_enrollment, household: family.active_household, sponsored_benefit_package_id: benefit_package.id, employee_role_id: employee_role.id)}
    let!(:fein)          {organization.fein}
    let!(:py_end_on){TimeKeeper.date_of_record.end_of_month.strftime('%m/%d/%Y')}
    let(:effective_period) { start_on..end_on }
    let(:start_on)       { TimeKeeper.date_of_record.next_month.next_month.beginning_of_month - 1.year }
    let(:end_on)         { TimeKeeper.date_of_record.next_month.end_of_month }

    before do
      benefit_application.update_attributes(effective_period: effective_period)
      benefit_sponsorships = organization.benefit_sponsorships.select { |bs| bs.id != benefit_sponsorship.id}
      benefit_sponsorships.first.delete
      organization.reload
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
