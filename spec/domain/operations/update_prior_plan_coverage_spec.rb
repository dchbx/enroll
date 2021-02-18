# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_product_spec_helpers"


RSpec.describe Operations::UpdatePriorPlanCoverage, type: :model, dbclean: :after_each do

  context 'ivl enrollment' do
    let(:ivl_enrollment) {FactoryBot.build_stubbed(:hbx_enrollment, kind: 'individual')}

    it 'should return nil' do
      expect(subject.call({enrollment: ivl_enrollment})).to be_nil
    end
  end

  describe '#SHOP_enrollment' do
    include_context "setup benefit market with market catalogs and product packages"

    let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
    let(:coverage_kind)     { :health }
    let(:person)          { FactoryBot.create(:person) }
    let(:shop_family)     { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:employee_role)   { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person, census_employee: census_employee) }
    let(:hired_on)        { expired_benefit_application.start_on - 10.days }

    let(:qle_kind) {FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date)}
    context "when:
             - employee has active plan year and prior expired plan year
             - employee has no coverage in expired py and active py
             - employee purchased enrollment in expired plan year using admin added sep with coverage renewal flag true
             ",  dbclean: :after_each do

      include_context "setup expired, and active benefit applications"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      let!(:enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: expired_benefit_application.start_on + 1.month,
                          special_enrollment_period_id: sep.id,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: expired_benefit_package.id,
                          sponsored_benefit_id: expired_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: expired_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_selected')
      end

      let(:sep) do
        sep = shop_family.special_enrollment_periods.new
        sep.effective_on_kind = 'date_of_event'
        sep.qualifying_life_event_kind = qle_kind
        sep.qle_on = expired_benefit_application.start_on + 1.month
        sep.start_on = sep.qle_on
        sep.end_on = sep.qle_on + 30.days
        sep.coverage_renewal_flag = true
        sep.save
        sep
      end

      before do
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: expired_benefit_package, census_employee: census_employee, start_on: expired_benefit_package.start_on, end_on: expired_benefit_package.end_on)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: active_benefit_package, census_employee: census_employee, start_on: active_benefit_package.start_on, end_on: active_benefit_package.end_on)
        census_employee.save
        census_employee
      end

      let(:params) {{:enrollment => enrollment}}

      it 'should expire prior py enrollment and renew current py enrollment' do
        expect(shop_family.hbx_enrollments.count).to eq 1
        subject.call(params)
        shop_family.reload
        expect(shop_family.hbx_enrollments.count).to eq 2
        expect(shop_family.hbx_enrollments.map(&:aasm_state)).to include('coverage_enrolled')
      end
    end

    context "when:
             - employee has active plan year and prior expired plan year
             - employee has coverage in active py and no coverage in expired py
             - employee purchased enrollment in expired plan year using admin added sep with coverage renewal flag true
            ", dbclean: :after_each do

      include_context "setup expired, and active benefit applications"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }

      let!(:active_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: active_benefit_application.start_on,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: active_benefit_package.id,
                          sponsored_benefit_id: active_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: active_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_enrolled')
      end

      let!(:enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: expired_benefit_application.start_on + 1.month,
                          special_enrollment_period_id: sep.id,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: expired_benefit_package.id,
                          sponsored_benefit_id: expired_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: expired_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_selected')
      end


      let(:sep) do
        sep = shop_family.special_enrollment_periods.new
        sep.effective_on_kind = 'date_of_event'
        sep.qualifying_life_event_kind = qle_kind
        sep.qle_on = expired_benefit_application.start_on + 1.month
        sep.start_on = sep.qle_on
        sep.end_on = sep.qle_on + 30.days
        sep.coverage_renewal_flag = true
        sep.save
        sep
      end

      let(:params) {{:enrollment => enrollment}}

      before do
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: expired_benefit_package, census_employee: census_employee, start_on: expired_benefit_package.start_on, end_on: expired_benefit_package.end_on)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: active_benefit_package, census_employee: census_employee, start_on: active_benefit_package.start_on, end_on: active_benefit_package.end_on)
        census_employee.save
        census_employee
      end

      it 'should cancel active enrollment and renew new one, and expire prior py enrollment' do
        expect(shop_family.hbx_enrollments.count).to eq 2
        subject.call(params)
        shop_family.reload
        expect(shop_family.hbx_enrollments.count).to eq 3
        expect(shop_family.hbx_enrollments.map(&:aasm_state)).to match_array(['coverage_canceled', 'coverage_expired', 'coverage_enrolled'])
      end
    end


    context "when:
              - employee has active plan year and prior terminated plan year
              - employee has coverage in active py and no coverage in terminated py
              - employee purchased enrollment in terminated plan year using admin added sep with coverage renewal flag true
            ",  dbclean: :after_each do

      include_context "setup terminated and active benefit applications"
      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }

      let!(:active_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: active_benefit_application.start_on,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: active_benefit_package.id,
                          sponsored_benefit_id: active_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: active_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_enrolled')
      end

      let!(:enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: terminated_benefit_package.start_on + 1.month,
                          special_enrollment_period_id: sep.id,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: terminated_benefit_package.id,
                          sponsored_benefit_id: terminated_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: terminated_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_selected')
      end

      let(:params) {{:enrollment => enrollment}}


      let(:sep) do
        sep = shop_family.special_enrollment_periods.new
        sep.effective_on_kind = 'date_of_event'
        sep.qualifying_life_event_kind = qle_kind
        sep.qle_on = terminated_benefit_application.start_on + 1.month
        sep.start_on = sep.qle_on
        sep.end_on = sep.qle_on + 30.days
        sep.coverage_renewal_flag = true
        sep.save
        sep
      end

      before do
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: active_benefit_package, census_employee: census_employee, start_on: active_benefit_package.start_on, end_on: active_benefit_package.end_on)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: terminated_benefit_package, census_employee: census_employee, start_on: terminated_benefit_application.start_on,
                                                                                      end_on: terminated_benefit_application.end_on)
        census_employee.save
        census_employee
      end

      it 'should terminate prior enrollment, and should not cancel and create continuous coverage enrollment' do
        expect(shop_family.hbx_enrollments.count).to eq 2
        subject.call(params)
        shop_family.reload
        expect(shop_family.hbx_enrollments.count).to eq 2
        expect(shop_family.hbx_enrollments.map(&:aasm_state)).to match_array(['coverage_terminated','coverage_enrolled'])
        terminated_enrollment = shop_family.hbx_enrollments.select{|enr| enr.aasm_state == 'coverage_terminated'}.first
        expect(terminated_enrollment.terminated_on).to eq terminated_benefit_application.end_on
      end
    end

    context "when:
             - employee has active plan year and prior terminated plan year
             - employee has no coverage in active py and no coverage in terminated py
             - employee purchased enrollment in terminated plan year using admin added sep with coverage renewal flag true
            ",  dbclean: :after_each do

      include_context "setup terminated and active benefit applications"

      let(:sep) do
        sep = shop_family.special_enrollment_periods.new
        sep.effective_on_kind = 'date_of_event'
        sep.qualifying_life_event_kind = qle_kind
        sep.qle_on = terminated_benefit_application.start_on + 1.month
        sep.start_on = sep.qle_on
        sep.end_on = sep.qle_on + 30.days
        sep.coverage_renewal_flag = true
        sep.save
        sep
      end
      let!(:enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: terminated_benefit_package.start_on + 1.month,
                          special_enrollment_period_id: sep.id,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: terminated_benefit_package.id,
                          sponsored_benefit_id: terminated_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: terminated_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_selected')
      end
      let(:params) {{:enrollment => enrollment}}

      before do
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: terminated_benefit_package, census_employee: census_employee, start_on: terminated_benefit_application.start_on,
                                                                                      end_on: terminated_benefit_application.end_on)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: active_benefit_package, census_employee: census_employee, start_on: active_benefit_package.start_on, end_on: active_benefit_package.end_on)
        census_employee.save
        census_employee
      end

      it 'should terminate prior enrollment, and should not create continuous coverage enrollment' do
        expect(shop_family.hbx_enrollments.count).to eq 1
        subject.call(params)
        shop_family.reload
        expect(shop_family.hbx_enrollments.count).to eq 1
        expect(shop_family.hbx_enrollments.map(&:aasm_state)).to match_array(['coverage_terminated'])
        terminated_enrollment = shop_family.hbx_enrollments.select{|enr| enr.aasm_state == 'coverage_terminated'}.first
        expect(terminated_enrollment.terminated_on).to eq terminated_benefit_application.end_on
      end
    end

    context "when:
             - employee has expired, active, and renewing plan year
             - employee has no coverage in expired, active py, or renewal py
             - employee purchased enrollment in expired plan year using admin added sep  with coverage renewal flag true
            ",  dbclean: :after_each do

      include_context "setup expired, active and renewing benefit applications"
      let!(:current_benefit_market_catalog) do
        ::BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_and_previous_catalog(
          site,
          benefit_market,
          (TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year)
        )
        benefit_market.benefit_market_catalogs.where(
          "application_period.min" => TimeKeeper.date_of_record.beginning_of_year
        ).first
      end

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      let(:renewal_effective_date) { TimeKeeper.date_of_record.beginning_of_year.next_year }
      let(:sep) do
        sep = shop_family.special_enrollment_periods.new
        sep.effective_on_kind = 'date_of_event'
        sep.qualifying_life_event_kind = qle_kind
        sep.qle_on = expired_benefit_application.start_on + 1.month
        sep.start_on = sep.qle_on
        sep.end_on = sep.qle_on + 30.days
        sep.coverage_renewal_flag = true
        sep.save
        sep
      end
      let!(:enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: expired_benefit_package.start_on + 1.month,
                          special_enrollment_period_id: sep.id,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: expired_benefit_package.id,
                          sponsored_benefit_id: expired_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: expired_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_selected')
      end
      let(:params) {{:enrollment => enrollment}}

      before do
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: expired_benefit_package, census_employee: census_employee, start_on: expired_benefit_application.start_on,
                                                                                      end_on: expired_benefit_application.end_on)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: active_benefit_package, census_employee: census_employee, start_on: active_benefit_package.start_on, end_on: active_benefit_package.end_on)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: renewal_benefit_package, census_employee: census_employee, start_on: renewal_benefit_application.start_on,
                                                                                      end_on: renewal_benefit_application.end_on)
        census_employee.save
        census_employee
      end

      it 'should expire prior py enrollment, and should create continuous coverage enrollments for active and renewal py' do
        expect(shop_family.hbx_enrollments.count).to eq 1
        subject.call(params)
        shop_family.reload
        expect(shop_family.hbx_enrollments.count).to eq 3
        expect(shop_family.hbx_enrollments.map(&:aasm_state)).to match_array(["coverage_expired", "coverage_enrolled", "auto_renewing"])
      end
    end

    context "when:
             - employee has expired, active, and renewing plan year
             - employee has coverage in active py, renewal py but not in expired py
             - employee purchased enrollment in expired plan year using admin added sep with coverage renewal flag true
            ",  dbclean: :after_each do

      include_context "setup expired, active and renewing benefit applications"
      let!(:current_benefit_market_catalog) do
        ::BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_and_previous_catalog(
          site,
          benefit_market,
          (TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year)
        )
        benefit_market.benefit_market_catalogs.where(
          "application_period.min" => TimeKeeper.date_of_record.beginning_of_year
        ).first
      end
      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      let(:renewal_effective_date) { TimeKeeper.date_of_record.beginning_of_year.next_year }
      let(:sep) do
        sep = shop_family.special_enrollment_periods.new
        sep.effective_on_kind = 'date_of_event'
        sep.qualifying_life_event_kind = qle_kind
        sep.qle_on = expired_benefit_application.start_on + 1.month
        sep.start_on = sep.qle_on
        sep.end_on = sep.qle_on + 30.days
        sep.coverage_renewal_flag = true
        sep.save
        sep
      end
      let!(:active_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: active_benefit_package.start_on,
                          special_enrollment_period_id: sep.id,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: active_benefit_package.id,
                          sponsored_benefit_id: active_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: active_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_selected')
      end

      let!(:renewal_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: renewal_benefit_package.start_on,
                          special_enrollment_period_id: sep.id,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: renewal_benefit_package.id,
                          sponsored_benefit_id: renewal_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.renewal_benefit_group_assignment,
                          product_id: renewal_sponsored_benefit.reference_product.id,
                          aasm_state: 'auto_renewing')
      end

      let!(:enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: expired_benefit_package.start_on + 1.month,
                          special_enrollment_period_id: sep.id,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: expired_benefit_package.id,
                          sponsored_benefit_id: expired_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: expired_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_selected')
      end
      let(:params) {{:enrollment => enrollment}}

      before do
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: expired_benefit_package, census_employee: census_employee, start_on: expired_benefit_application.start_on,
                                                                                      end_on: expired_benefit_application.end_on)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: active_benefit_package, census_employee: census_employee, start_on: active_benefit_package.start_on, end_on: active_benefit_package.end_on)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: renewal_benefit_package, census_employee: census_employee, start_on: renewal_benefit_application.start_on,
                                                                                      end_on: renewal_benefit_application.end_on)
        census_employee.save
        census_employee
      end
      it 'should expire prior py enrollment, and should create continuous coverage enrollments for active and renewal py' do
        expect(shop_family.hbx_enrollments.count).to eq 3
        subject.call(params)
        shop_family.reload
        expect(shop_family.hbx_enrollments.count).to eq 5
        expect(shop_family.hbx_enrollments.map(&:aasm_state)).to match_array(["coverage_canceled", "coverage_canceled", "coverage_expired", "coverage_enrolled", "auto_renewing"])
      end
    end

    context "when:
              - employee has expired, active, and renewing plan year
              - employee has coverage in active py, renewal py but not in expired py
              - employee purchased enrollment in expired plan year using admin added sep with coverage renewal flag false
            ",  dbclean: :after_each do

      include_context "setup expired, active and renewing benefit applications"
      let!(:current_benefit_market_catalog) do
        ::BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_and_previous_catalog(
          site,
          benefit_market,
          (TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year)
        )
        benefit_market.benefit_market_catalogs.where(
          "application_period.min" => TimeKeeper.date_of_record.beginning_of_year
        ).first
      end
      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      let(:renewal_effective_date) { TimeKeeper.date_of_record.beginning_of_year.next_year }
      let(:sep) do
        sep = shop_family.special_enrollment_periods.new
        sep.effective_on_kind = 'date_of_event'
        sep.qualifying_life_event_kind = qle_kind
        sep.qle_on = expired_benefit_application.start_on + 1.month
        sep.start_on = sep.qle_on
        sep.end_on = sep.qle_on + 30.days
        sep.coverage_renewal_flag = false
        sep.save
        sep
      end
      let!(:active_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: active_benefit_package.start_on,
                          special_enrollment_period_id: sep.id,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: active_benefit_package.id,
                          sponsored_benefit_id: active_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: active_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_selected')
      end

      let!(:renewal_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: renewal_benefit_package.start_on,
                          special_enrollment_period_id: sep.id,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: renewal_benefit_package.id,
                          sponsored_benefit_id: renewal_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.renewal_benefit_group_assignment,
                          product_id: renewal_sponsored_benefit.reference_product.id,
                          aasm_state: 'auto_renewing')
      end

      let!(:enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: expired_benefit_package.start_on + 1.month,
                          special_enrollment_period_id: sep.id,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: expired_benefit_package.id,
                          sponsored_benefit_id: expired_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: expired_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_selected')
      end
      let(:params) {{:enrollment => enrollment}}

      before do
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: expired_benefit_package, census_employee: census_employee, start_on: expired_benefit_application.start_on,
                                                                                      end_on: expired_benefit_application.end_on)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: active_benefit_package, census_employee: census_employee, start_on: active_benefit_package.start_on, end_on: active_benefit_package.end_on)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: renewal_benefit_package, census_employee: census_employee, start_on: renewal_benefit_application.start_on,
                                                                                      end_on: renewal_benefit_application.end_on)
        census_employee.save
        census_employee
      end

      it 'should expire prior py enrollment, and should not create continuous coverage enrollments for active and renewal py' do
        expect(shop_family.hbx_enrollments.count).to eq 3
        subject.call(params)
        shop_family.reload
        expect(shop_family.hbx_enrollments.count).to eq 3
        expect(shop_family.hbx_enrollments.map(&:aasm_state)).to match_array(["coverage_expired", "coverage_selected", "auto_renewing"])
      end
    end
  end
end
