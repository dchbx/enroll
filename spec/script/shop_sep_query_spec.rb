require 'rails_helper'
require File.join(Rails.root, "script", "shop_sep_query")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe '.can_publish_enrollment?', :dbclean => :after_each do
  let(:plan) { FactoryBot.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'silver', active_year: start_on.year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id, coverage_kind: 'health') }
  let(:renewal_plan) { FactoryBot.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'silver', active_year: start_on.year, hios_id: "11111111122302-01", csr_variant_id: "01", coverage_kind: 'health') }

  context 'initial employer' do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"
    let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 2.months }
    let(:submitted_at) { initial_application.enrollment_quiet_period.max + 5.hours }
    let(:enrollment_effective_on) { start_on }
    let(:person) {FactoryBot.create(:person)}
    let(:user) { FactoryBot.create(:user, person: person) }
    let(:family){ FactoryBot.create(:family, :with_primary_family_member_and_dependent) }
    let(:family_members){ family.family_members.where(is_primary_applicant: false).to_a }
    let(:household){ family.active_household }
    let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber:true,  applicant_id: family.family_members.first.id, coverage_start_on: (TimeKeeper.date_of_record).beginning_of_month, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
    let(:reference_plan) {double("Product")}
    let(:member_enrollment) {BenefitSponsors::Enrollments::MemberEnrollment.new(member_id:hbx_enrollment_member.id, product_price:BigDecimal(100),sponsor_contribution:BigDecimal(100))}
    let(:group_enrollment) {BenefitSponsors::Enrollments::GroupEnrollment.new(product: product, member_enrollments:[member_enrollment], product_cost_total:'')}
    let(:hbx_enrollment){ FactoryBot.create(:hbx_enrollment, :with_product, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                                             household: household,
                                             hbx_enrollment_members: [hbx_enrollment_member],
                                             coverage_kind: "health",
                                             family: family,
                                             external_enrollment: false,
                                             sponsored_benefit_id: sponsored_benefit.id,
                                             effective_on: enrollment_effective_on,
                                             rating_area_id: rating_area.id)
    }
    let(:benefit_group) { current_benefit_package }
    let(:effective_period)        { start_on..start_on.next_year.prev_day }
    let!(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, benefit_group: current_benefit_package ) }
    let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
    let!(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id) }
    let!(:sponsored_benefit) { initial_application.benefit_packages.first.sponsored_benefits.first }

    before do
      allow(hbx_enrollment).to receive(:employer_profile).and_return(abc_profile)
    end

    context 'when plan year is invalid' do

      before do
        allow(hbx_enrollment).to receive(:new_hire_enrollment_for_shop?).and_return(false)
        initial_application.update_attributes(aasm_state: "enrollment_ineligible")
        initial_application.save!
      end

      context 'enrollment submitted after quiet period' do
        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(hbx_enrollment, submitted_at)).to be_falsey
        end
      end
    end


    context 'when plan year is in coverage_termination_pending' do

      before do
        allow(hbx_enrollment).to receive(:new_hire_enrollment_for_shop?).and_return(false)
        initial_application.update_attributes(aasm_state: "termination_pending")
        hbx_enrollment.update_attributes(aasm_state: "coverage_termination_pending")
      end

      context 'coverage_termination_pending enrollment' do
        it 'should publish enrollment' do
          expect(can_publish_enrollment?(hbx_enrollment, submitted_at)).to be_truthy
        end
      end
    end

    context 'when plan year is valid' do

      before do
        allow(hbx_enrollment).to receive(:new_hire_enrollment_for_shop?).and_return(false)
      end

      context 'enrollment submitted after quiet period' do
        it 'should publish enrollment' do
          expect(can_publish_enrollment?(hbx_enrollment, submitted_at)).to be_truthy
        end
      end

      context 'enrollment submitted with in quiet period' do
        let(:submitted_at) { initial_application.enrollment_quiet_period.max - 5.days }

        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(hbx_enrollment, submitted_at)).to be_falsey
        end
      end

      context 'enrollment submitted during open enrollment' do
        let(:submitted_at) { initial_application.open_enrollment_end_on.prev_day }

        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(hbx_enrollment, submitted_at)).to be_falsey
        end
      end
    end

    context 'when enrollment is new hire enrollment'  do

      before do
        allow(hbx_enrollment).to receive(:new_hire_enrollment_for_shop?).and_return(true)
      end

      context 'enrollment effective date with in 2 months in the past' do
        let(:enrollment_effective_on) { TimeKeeper.date_of_record - 5.days }

        it 'should publish enrollment' do
          expect(can_publish_enrollment?(hbx_enrollment, submitted_at)).to be_truthy
        end
      end

      context 'enrollment effective date is more than 2 months in the past' do
        let(:enrollment_effective_on) { TimeKeeper.date_of_record - 3.months }

        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(hbx_enrollment, submitted_at)).to be_falsey
        end
      end
    end

    context 'OE end on is greater than the BA start_on' do
      before :each do
        open_enrollment_period = (initial_application.start_on - 10.days)..(initial_application.start_on + 3.days)
        initial_application.update_attributes(open_enrollment_period: open_enrollment_period)
        initial_application.save!
      end

      it 'should return true' do
        result = can_publish_enrollment?(hbx_enrollment, (initial_application.open_enrollment_end_on + 2.days))
        expect(result).to eq(true)
      end
    end
  end

  context 'renewing employer' do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup renewal application"

    let(:person) {FactoryBot.create(:person)}
    let(:user) { FactoryBot.create(:user, person: person) }
    let(:family){ FactoryBot.create(:family, :with_primary_family_member_and_dependent) }
    let(:family_members){ family.family_members.where(is_primary_applicant: false).to_a }
    let(:household){ family.active_household }
    let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber:true,  applicant_id: family.family_members.first.id, coverage_start_on: (TimeKeeper.date_of_record).beginning_of_month, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
    let!(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id) }
    let(:benefit_group){ renewal_application.benefit_packages.first}
    let(:benefit_group_assignment) {FactoryBot.build(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_group)}
    let!(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, benefit_group: benefit_group ) }
    let(:hbx_enrollment){ FactoryBot.create(:hbx_enrollment, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                                             household: household,
                                             hbx_enrollment_members: [hbx_enrollment_member],
                                             coverage_kind: "health",
                                             family: family,
                                             external_enrollment: false,
                                             sponsored_benefit_id: sponsored_benefit.id,
                                             effective_on: enrollment_effective_on,
                                             rating_area_id: rating_area.id)
    }
    let!(:sponsored_benefit) { renewal_application.benefit_packages.first.sponsored_benefits.first }
    let(:employer_status) { 'enrolled' }
    let(:enrollment_status) { 'coverage_selected' }
    let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 2.months }
    let(:submitted_at) { renewal_application.enrollment_quiet_period.max + 5.hours }
    let(:enrollment_effective_on) { start_on }

    before do
      allow(hbx_enrollment).to receive(:employer_profile).and_return(abc_profile)
      renewal_application.update_attributes(aasm_state: "enrollment_eligible")
      renewal_application.save!
    end

    context 'when plan year is invalid' do

      before do
        allow(hbx_enrollment).to receive(:employer_profile).and_return(abc_profile)
        renewal_application.update_attributes(aasm_state: "enrollment_ineligible")
        renewal_application.save!
      end

      context 'enrollment submitted after quiet period' do
        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(hbx_enrollment, submitted_at)).to be_falsey
        end
      end
    end

    context 'when plan year is valid' do

      before do
        allow(hbx_enrollment).to receive(:new_hire_enrollment_for_shop?).and_return(false)
      end

      context 'enrollment submitted after quiet period' do
        it 'should publish enrollment' do
          expect(can_publish_enrollment?(hbx_enrollment, submitted_at)).to be_truthy
        end
      end

      context 'enrollment submitted with in quiet period' do
        let(:submitted_at) { renewal_application.enrollment_quiet_period.max - 3.hours }

        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(hbx_enrollment, submitted_at)).to be_falsey
        end
      end

      context 'enrollment submitted during open enrollment' do
        let(:submitted_at) { renewal_application.open_enrollment_end_on.prev_day }

        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(hbx_enrollment, submitted_at)).to be_falsey
        end
      end
    end

    context 'when enrollment is new hire enrollment' do

      context 'enrollment effective date with in 2 months in the past' do
        let(:enrollment_effective_on) { TimeKeeper.date_of_record - 5.days }

        before do
          allow(hbx_enrollment).to receive(:new_hire_enrollment_for_shop?).and_return(true)
        end

        it 'should publish enrollment' do
          expect(can_publish_enrollment?(hbx_enrollment, submitted_at)).to be_truthy
        end
      end

      context 'enrollment effective date is more than 2 months in the past' do
        let(:enrollment_effective_on) { TimeKeeper.date_of_record - 3.months }

        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(hbx_enrollment, submitted_at)).to be_falsey
        end
      end
    end
  end
end
