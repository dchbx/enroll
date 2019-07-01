require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe GroupSelectionPrevaricationAdapter, dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"
  include_context "setup employees with benefits"
  
  let(:product_kinds)  { [:health, :dental] }
  let(:dental_sponsored_benefit) { true }
  let(:roster_size) { 2 }
  let(:start_on) { TimeKeeper.date_of_record.prev_month.beginning_of_month }
  let(:effective_period) { start_on..start_on.next_year.prev_day }
  let(:ce) { benefit_sponsorship.census_employees.non_business_owner.first }

  let!(:family) {
    person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
    employee_role = FactoryBot.create(:employee_role, person: person, census_employee: ce, employer_profile: abc_profile)
    ce.update_attributes({employee_role: employee_role})
    Family.find_or_build_from_employee_role(employee_role)
  }

  let(:person) { family.primary_applicant.person }
  let(:employee_role) { person.active_employee_roles.first }

  let(:group_selection_params) { {
    "person_id"=> person.id, 
    "market_kind"=>"shop", 
    "employee_role_id"=> employee_role.id, 
    "coverage_kind"=>"dental", 
    "change_plan"=>"change_by_qle"
  } }

  let(:params) { ActionController::Parameters.new(group_selection_params) }
  let(:enrollment_effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
  subject(:adapter) { GroupSelectionPrevaricationAdapter.initialize_for_common_vars(params) }

  describe ".is_eligible_for_dental?" do

    context "when employee making changes to existing enrollment" do 

      let!(:hbx_enrollment) {
        FactoryBot.create(:hbx_enrollment,
          household: family.active_household,
          family: family,
          coverage_kind: "dental",
          effective_on: enrollment_effective_date,
          enrollment_kind: "open_enrollment",
          kind: "employer_sponsored",
          employee_role_id: person.active_employee_roles.first.id,
          benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
          benefit_sponsorship: benefit_sponsorship,
          sponsored_benefit_package: current_benefit_package,
          sponsored_benefit: current_benefit_package.sponsored_benefit_for("dental"),
          product: dental_product_package.products[0]
        )
      }

      let(:params) { ActionController::Parameters.new(
        group_selection_params.merge({
          "hbx_enrollment_id"=>hbx_enrollment.id, 
          "change_plan"=>"change_plan"
          })
      )}

      it "checks if dental offered using existing enrollment benefit package and returns true" do
        result = adapter.is_eligible_for_dental?(employee_role, 'change_plan', hbx_enrollment)
        expect(result).to be_truthy
      end
    end

    context "when employee purchasing coverage through qle" do 

      let(:qualifying_life_event_kind) { FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date) }
      let(:qle_on) { TimeKeeper.date_of_record - 2.days }

      let!(:special_enrollment_period) {
        special_enrollment = family.special_enrollment_periods.build({
          qle_on: qle_on,
          effective_on_kind: "date_of_event",
          })

        special_enrollment.qualifying_life_event_kind = qualifying_life_event_kind
        special_enrollment.save!
        special_enrollment
      }

      context "employer offering dental" do 

        it "checks if dental eligible using SEP and returns true" do
          result = adapter.is_eligible_for_dental?(employee_role, 'change_by_qle', nil)
          expect(result).to be_truthy
        end
      end

      context "employer not offering dental" do 
        let(:dental_sponsored_benefit) { false }

        it "checks if dental eligible using SEP and returns false" do
          result = adapter.is_eligible_for_dental?(employee_role, 'change_by_qle', nil)
          expect(result).to be_falsey
        end
      end
    end

    context "When employee purchasing coverage through future application using qle" do
      let(:qualifying_life_event_kind) { FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date) }
      let(:qle_on) { TimeKeeper.date_of_record - 2.days }
      let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }

      let!(:special_enrollment_period) {
        special_enrollment = family.special_enrollment_periods.build({
          qle_on: qle_on,
          effective_on_kind: "date_of_event",
          })

        special_enrollment.qualifying_life_event_kind = qualifying_life_event_kind
        special_enrollment.save!
        special_enrollment
      }

      context "employer offering dental" do 
        it "returns true" do 
          result = adapter.is_eligible_for_dental?(employee_role, 'change_by_qle', nil)
          expect(result).to be_truthy
        end
      end

      context "employer not offering dental" do
        let(:dental_sponsored_benefit) { false }

        it "returns false" do 
          result = adapter.is_eligible_for_dental?(employee_role, 'change_by_qle', nil)
          expect(result).to be_falsey
        end 
      end 
    end
  end
end
