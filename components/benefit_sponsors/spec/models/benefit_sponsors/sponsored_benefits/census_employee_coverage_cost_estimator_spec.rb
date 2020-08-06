# frozen_string_literal: true

require "rails_helper"

module BenefitSponsors
  RSpec.describe BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator::CensusEmployeeMemberGroupMapper, "given:
    - a census employee
    - with a domestic partner
    - a disabled child > age 26", :dbclean => :after_each do

    let(:census_employee) do
      double({
               :id => "census_employee_id",
               :dob => Date.new(1965, 12, 3),
               :census_dependents => [domestic_partner, disabled_child],
               :aasm_state => "eligible"
             })
    end
    let(:domestic_partner) do
      double({
               :id => "domestic_partner_id",
               :dob => Date.new(1967, 3, 15),
               :employee_relationship => "domestic_partner"
             })
    end
    let(:disabled_child) do
      double({
               :id => "disabled_child_id",
               :dob => Date.new(1987, 1, 1),
               :employee_relationship => "disabled_child_26_and_over"
             })
    end
    let(:reference_product) { instance_double(::BenefitMarkets::Products::Product, :id => "reference_product_id") }
    let(:sponsored_benefit) do
      instance_double(
        ::BenefitSponsors::SponsoredBenefits::SponsoredBenefit,
        {
          :rate_schedule_date => Date.new(2018, 5, 1),
          :recorded_rating_area => rating_area
        }
      )
    end

    let(:rating_area) do
      instance_double(
        ::BenefitMarkets::Locations::RatingArea,
        {
          :exchange_provided_code => "MA5"
        }
      )
    end
    let(:census_employees) { [census_employee] }
    let(:coverage_start) { Date.new(2018, 5, 1) }

    subject { ::BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator::CensusEmployeeMemberGroupMapper.new(census_employees, reference_product, coverage_start, sponsored_benefit) }

    let(:group_enrollments) do
      subject.map { |a| a }
    end

    let(:employee_group_enrollment) { group_enrollments.first }

    it "has 3 members" do
      expect(employee_group_enrollment.members.length).to eq 3
    end

    it "has a domestic partner member" do
      domestic_partner = employee_group_enrollment.members.detect { |m| m.member_id == "domestic_partner_id" }
      expect(domestic_partner.relationship).to eq "domestic_partner"
    end

    it "has a disabled child member" do
      disabled_child = employee_group_enrollment.members.detect { |m| m.member_id == "disabled_child_id" }
      expect(disabled_child.relationship).to eq "child"
      expect(disabled_child.is_disabled?).to be_truthy
    end

    describe 'eligible_employee_criteria' do
      let!(:rating_area)         { FactoryBot.create_default :benefit_markets_locations_rating_area }
      let!(:service_area)        { FactoryBot.create_default :benefit_markets_locations_service_area }
      let!(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let!(:organization)        { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let!(:employer_profile)    { organization.employer_profile }
      let!(:benefit_sponsorship) { employer_profile.add_benefit_sponsorship }
      let!(:ce2)                 { FactoryBot.create(:census_employee, benefit_sponsorship_id: benefit_sponsorship.id, expected_selection: 'will_not_participate') }
      let!(:ces)                 { create_list(:census_employee, 5, :with_enrolled_census_employee, benefit_sponsorship_id: benefit_sponsorship.id)}

      before :each do
        ces.first.update_attributes!(expected_selection: "enroll")
        ces[1].update_attributes!(expected_selection: "waive")
        ce2.update_attribute(:aasm_state, 'employment_terminated')
        ce_cost_instance = ::BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator.new(benefit_sponsorship, TimeKeeper.date_of_record)
        @census_employees = ce_cost_instance.send(:eligible_employee_criteria)
        @ce_count = ce_cost_instance.send(:eligible_employee_count)
        @employees_enrolling = ce_cost_instance.send(:employees_enrolling)
        @employees_enrolling_and_waiving = ce_cost_instance.send(:employees_enrolling_and_waiving)
      end

      context 'for various criteria' do
        it 'should return array with ce1 id as it is active' do
          ces.each do |ce|
            expect(@census_employees.pluck(:id)).to include(ce.id)
          end
        end

        it 'should return array without ce2 id as it is not active' do
          expect(@census_employees.pluck(:id)).not_to include(ce2.id)
        end

        it 'should return count for eligible_employee_criteria' do
          expect(@ce_count).to eq 5
        end

        it 'should return ces with enroll as expected_selection only' do
          expect(@employees_enrolling.pluck(:id)).to include(ces.first.id)
        end

        it 'should return count for employees_enrolling' do
          expect(@employees_enrolling.count).to eq 4
        end

        it 'should not return ces with enroll as expected_selection only' do
          expect(@employees_enrolling.pluck(:id)).not_to include(ce2.id)
        end

        it 'should return ces with enroll or waive as expected_selection only' do
          expect(@employees_enrolling_and_waiving.pluck(:id)).to include(ces.first.id)
        end

        it 'should return count for employees_enrolling_and_waiving' do
          expect(@employees_enrolling_and_waiving.count).to eq 5
        end
      end
    end
  end
end
