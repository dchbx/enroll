require 'rails_helper'
require 'rake'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe 'cancel employer benefit application & enrollments', :dbclean => :around_each do
  describe 'migrations:cancel_benefit_application' do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let!(:fein) {abc_profile.fein}
    let(:person) {FactoryBot.create(:person)}
    let(:user) { FactoryBot.create(:user, person: person) }
    let(:family){ FactoryBot.create(:family, :with_primary_family_member_and_dependent) }
    let(:family_members){ family.family_members.where(is_primary_applicant: false).to_a }
    let(:household){ family.active_household }
    let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber:true,  applicant_id: family.family_members.first.id, coverage_start_on: (TimeKeeper.date_of_record).beginning_of_month, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
    let(:reference_plan) {double("Product")}
    let(:hbx_enrollment){ FactoryBot.create(:hbx_enrollment, :with_product, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
      household: household,
      family: family,
      hbx_enrollment_members: [hbx_enrollment_member],
      coverage_kind: "health",
      external_enrollment: false )
    }
    let!(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, benefit_group: current_benefit_package ) }
    let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
    let!(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id) }

    before do
      hbx_enrollment.update_attributes(aasm_state:'coverage_selected')
      employee_role.update_attributes(census_employee_id: census_employee.id)
    end

    context 'should cancel benefit application & enrollment', :dbclean => :around_each do
      before do
        load File.expand_path("#{Rails.root}/lib/tasks/migrations/cancel_benefit_application.rake", __FILE__)
        Rake::Task.define_task(:environment)
        Rake::Task["migrations:cancel_employer_incorrect_renewal"].reenable
        Rake::Task["migrations:cancel_employer_incorrect_renewal"].invoke(fein)
        initial_application.reload
        hbx_enrollment.reload
      end
     
      it "should update application aasm_state" do
        expect(initial_application.aasm_state).to eq :canceled
      end

      it "should update enrollment aasm_state" do
        expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
      end
    end
  end
end
