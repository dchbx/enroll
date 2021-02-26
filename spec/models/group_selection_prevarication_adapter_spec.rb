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
  let(:current_effective_date) { start_on }
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
        result = adapter.is_eligible_for_dental?(employee_role, 'change_plan', hbx_enrollment, enrollment_effective_date)
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
          result = adapter.is_eligible_for_dental?(employee_role, 'change_by_qle', nil, qle_on)
          expect(result).to be_truthy
        end
      end

      context "employer not offering dental" do 
        let(:dental_sponsored_benefit) { false }

        it "checks if dental eligible using SEP and returns false" do
          result = adapter.is_eligible_for_dental?(employee_role, 'change_by_qle', nil, qle_on)
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
          result = adapter.is_eligible_for_dental?(employee_role, 'change_by_qle', nil, qle_on)
          expect(result).to be_truthy
        end
      end

      context "employer not offering dental" do
        let(:dental_sponsored_benefit) { false }

        it "returns false" do 
          result = adapter.is_eligible_for_dental?(employee_role, 'change_by_qle', nil, qle_on)
          expect(result).to be_falsey
        end 
      end 
    end
  end

  context 'set_mc_variables for coverall' do
    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product)}
    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        household: family.active_household,
                        family: family,
                        coverage_kind: 'health',
                        effective_on: enrollment_effective_date,
                        enrollment_kind: 'special_enrollment',
                        kind: 'coverall',
                        product: product)
    end

    let(:group_selection_params) do
      {
        :person_id => person.id,
        :market_kind => 'coverall',
        :coverage_kind => 'health',
        :change_plan => 'change_plan',
        :hbx_enrollment_id => hbx_enrollment.id
      }
    end

    let(:params2) { ActionController::Parameters.new(group_selection_params) }
    subject(:adapter2) { GroupSelectionPrevaricationAdapter.initialize_for_common_vars(params2) }

    it 'should set market' do
      adapter2.set_mc_variables do |market_kind, coverage_kind|
        m_kind = market_kind
        c_kind = coverage_kind
        expect(m_kind).to eq 'coverall'
        expect(c_kind).to eq 'health'
      end
    end
  end

  context '.if_family_has_active_shop_sep' do
    let(:person1) { FactoryBot.create(:person, :with_family, :with_employee_role, first_name: "mock")}
    let(:family1) { person1.primary_family }
    let(:family_member_ids) {{"0" => family1.family_members.first.id}}
    let!(:new_household) {family1.households.where(:id => {"$ne" => family.households.first.id.to_s}).first}
    let(:start_on) { TimeKeeper.date_of_record }
    let(:benefit_package) {hbx_enrollment.sponsored_benefit_package}
    let(:special_enrollment_period) {[double("SpecialEnrollmentPeriod")]}
    let!(:sep) do
      family1.special_enrollment_periods.create(
        qualifying_life_event_kind: qle,
        qle_on: qle.created_at,
        effective_on_kind: qle.event_kind_label,
        effective_on: benefit_package.effective_period.min,
        start_on: start_on,
        end_on: start_on + 30.days
      )
    end
    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product)}

    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        household: family.active_household,
                        family: family,
                        coverage_kind: 'health',
                        effective_on: enrollment_effective_date,
                        enrollment_kind: 'special_enrollment',
                        kind: 'employer_sponsored',
                        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
                        product: product)
    end

    let(:group_selection_params) do
      {
        :person_id => person1.id,
        :employee_role_id => person1.employee_roles.first.id,
        :market_kind => "shop",
        :change_plan => "change_plan",
        :hbx_enrollment_id => hbx_enrollment.id,
        :family_member_ids => family_member_ids,
        :enrollment_kind => 'special_enrollment',
        :coverage_kind => hbx_enrollment.coverage_kind
      }
    end

    let(:params2) { ActionController::Parameters.new(group_selection_params) }
    subject(:adapter2) { GroupSelectionPrevaricationAdapter.initialize_for_common_vars(params2) }

    context 'change_plan for shop qle' do
      let(:qle) do
        QualifyingLifeEventKind.create(
          title: "Married",
          tool_tip: "Enroll or add a family member because of marriage",
          action_kind: "add_benefit",
          event_kind_label: "Date of married",
          market_kind: "shop",
          ordinal_position: 15,
          reason: "marriage",
          edi_code: "32-MARRIAGE",
          effective_on_kinds: ["first_of_next_month"],
          pre_event_sep_in_days: 0,
          post_event_sep_in_days: 30,
          is_self_attested: true
        )

        it 'should set change_plan' do
          expect(adapter2.change_plan).to eq 'change_plan'
          adapter2.if_family_has_active_shop_sep do
            expect(adapter2.change_plan).to eq 'change_by_qle'
          end
        end
      end
    end

    context 'change_plan for fehb qle' do
      let(:qle) do
        QualifyingLifeEventKind.create(
          title: "Married",
          tool_tip: "Enroll or add a family member because of marriage",
          action_kind: "add_benefit",
          event_kind_label: "Date of married",
          market_kind: "fehb",
          ordinal_position: 15,
          reason: "marriage",
          edi_code: "32-MARRIAGE",
          effective_on_kinds: ["first_of_next_month"],
          pre_event_sep_in_days: 0,
          post_event_sep_in_days: 30,
          is_self_attested: true,
          is_active: true
        )
      end

      it 'should set change_plan' do
        expect(adapter2.change_plan).to eq 'change_plan'
        adapter2.if_family_has_active_shop_sep do
          expect(adapter2.change_plan).to eq 'change_by_qle'
        end
      end
    end
  end

end
