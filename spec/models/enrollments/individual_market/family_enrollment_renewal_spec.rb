# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/spec/shared_contexts/enrollment.rb"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe Enrollments::IndividualMarket::FamilyEnrollmentRenewal, type: :model, :dbclean => :after_each do
    include FloatHelper

    let(:current_date) { Date.new(calender_year, 11, 1) }

    let(:current_benefit_coverage_period) { OpenStruct.new(start_on: current_date.beginning_of_year, end_on: current_date.end_of_year) }
    let(:renewal_benefit_coverage_period) { OpenStruct.new(start_on: current_date.next_year.beginning_of_year, end_on: current_date.next_year.end_of_year) }

    let(:aptc_values) {{}}
    let(:assisted) { nil }


    let!(:family) do
      primary = FactoryBot.create(:person, :with_consumer_role, dob: primary_dob)
      FactoryBot.create(:family, :with_primary_family_member, :person => primary)
    end

    let!(:coverall_family) do
      primary = FactoryBot.create(:person, :with_resident_role, dob: primary_dob)
      FactoryBot.create(:family, :with_primary_family_member, :person => primary)
    end

    let!(:spouse_rec) do
      FactoryBot.create(:person, dob: spouse_dob)
    end

    let!(:spouse) do
      FactoryBot.create(:family_member, person: spouse_rec, family: family)
    end

    let!(:child1) do
      child = FactoryBot.create(:person, dob: child1_dob)
      FactoryBot.create(:family_member, person: child, family: family)
    end

    let!(:child2) do
      child = FactoryBot.create(:person, dob: child2_dob)
      FactoryBot.create(:family_member, person: child, family: family)
    end

    let!(:child3) do
      child = FactoryBot.create(:person, dob: child3_dob)
      FactoryBot.create(:family_member, person: child, family: family)
    end

    let(:primary_dob){ current_date.next_month - 57.years }
    let(:spouse_dob) { current_date.next_month - 55.years }
    let(:child1_dob) { current_date.next_month - 26.years }
    let(:child2_dob) { current_date.next_month - 20.years }
    let(:child3_dob) { current_benefit_coverage_period.start_on + 2.months - 25.years}

    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        family: family,
                        enrollment_members: enrollment_members,
                        household: family.active_household,
                        coverage_kind: coverage_kind,
                        effective_on: current_benefit_coverage_period.start_on,
                        kind: "individual",
                        product_id: current_product.id,
                        aasm_state: 'coverage_selected')
    end

    let!(:coverall_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        family: coverall_family,
                        enrollment_members: coverall_enrollment_members,
                        household: coverall_family.active_household,
                        coverage_kind: coverage_kind,
                        resident_role_id: coverall_family.primary_person.resident_role.id,
                        effective_on: current_benefit_coverage_period.start_on,
                        kind: "coverall",
                        product_id: current_product.id,
                        aasm_state: 'coverage_selected')
    end

    let!(:catastrophic_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        family: family,
                        enrollment_members: enrollment_members,
                        household: family.active_household,
                        coverage_kind: coverage_kind,
                        resident_role_id: family.primary_person.consumer_role.id,
                        effective_on: Date.new(Date.current.year,1,1),
                        kind: "coverall",
                        product_id: current_cat_product.id,
                        aasm_state: 'coverage_selected')
    end

    let(:enrollment_members) { family.family_members }
    let(:coverall_enrollment_members) { coverall_family.family_members }
    let(:calender_year) { TimeKeeper.date_of_record.year }
    let(:coverage_kind) { 'health' }
    let(:current_product) { FactoryBot.create(:active_ivl_gold_health_product, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_product_id: renewal_product.id) }
    let(:renewal_product) { FactoryBot.create(:renewal_ivl_gold_health_product, hios_id: "11111111122302-01", csr_variant_id: "01") }
    let(:current_cat_product) { FactoryBot.create(:active_ivl_silver_health_product, hios_base_id: "94506DC0390008", csr_variant_id: "01", metal_level_kind: :catastrophic) }

    subject do
      enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
      enrollment_renewal.enrollment = enrollment
      enrollment_renewal.assisted = assisted
      enrollment_renewal.aptc_values = aptc_values
      enrollment_renewal.renewal_coverage_start = renewal_benefit_coverage_period.start_on
      enrollment_renewal
    end

    before do
      TimeKeeper.set_date_of_record_unprotected!(current_date)
    end

    after :each do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    describe ".clone_enrollment_members" do

      context "when dependent age off feature is turned off" do
        before do
          allow(child1).to receive(:relationship).and_return('child')
          allow(child2).to receive(:relationship).and_return('child')
          allow(EnrollRegistry[:age_off_relaxed_eligibility].feature).to receive(:is_enabled).and_return(false)
        end
        context "When a child is aged off" do
          it "should not include child" do

            applicant_ids = subject.clone_enrollment_members.collect(&:applicant_id)

            expect(applicant_ids).to include(family.primary_applicant.id)
            expect(applicant_ids).to include(spouse.id)
            expect(applicant_ids).not_to include(child1.id)
            expect(applicant_ids).to include(child2.id)
          end

          it "should generate passive renewal in coverage_selected state" do
            renewal = subject.renew
            expect(renewal.coverage_selected?).to be_truthy
          end
        end
      end

      context "when dependent age off feature is turned on" do
        before do
          allow(child1).to receive(:relationship).and_return('child')
          allow(child3).to receive(:relationship).and_return('child')
          allow(EnrollRegistry[:age_off_relaxed_eligibility].feature).to receive(:is_enabled).and_return(true)
        end
        context "When a child is aged off" do
          it "should include child" do
            applicant_ids = subject.clone_enrollment_members.collect(&:applicant_id)
            expect(applicant_ids).to include(family.primary_applicant.id)
            expect(applicant_ids).not_to include(child1.id)
            expect(applicant_ids).to include(child3.id)
          end

          it "should generate passive renewal" do
            renewal = subject.renew
            expect(renewal.aasm_state).to eq "coverage_selected"
            expect(renewal.effective_on).to eq renewal_benefit_coverage_period.start_on
          end
        end
      end

      # Don't we need this for all the dependents
      # Are we using is_disabled flag in the system
      context "When a child person record is disabled" do
        let!(:spouse_rec) do
          FactoryBot.create(:person, dob: spouse_dob, is_disabled: true)
        end

        it "should not include child person record" do
          applicant_ids = subject.clone_enrollment_members.collect(&:applicant_id)
          expect(applicant_ids).not_to include(spouse.id)
        end
      end

      context "all ineligible members" do
        before do
          enrollment.hbx_enrollment_members.each do |member|
            member.person.update_attributes(is_disabled: true)
          end
        end

        it "should raise an error" do
          expect { subject.clone_enrollment_members }.to raise_error(RuntimeError, /unable to generate enrollment with hbx_id /)
        end
      end
    end

    describe ".renew" do

      before do
        allow(child1).to receive(:relationship).and_return('child')
        allow(child2).to receive(:relationship).and_return('child')
      end

      context "when all the covered housedhold eligible for renewal" do
        let(:child1_dob) { current_date.next_month - 24.years }


        it "should generate passive renewal in auto_renewing state" do
          renewal = subject.renew
          expect(renewal.auto_renewing?).to be_truthy
        end
      end

      context "renew coverall product" do
        subject do
          enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
          enrollment_renewal.enrollment = coverall_enrollment
          enrollment_renewal.assisted = assisted
          enrollment_renewal.aptc_values = aptc_values
          enrollment_renewal.renewal_coverage_start = renewal_benefit_coverage_period.start_on
          enrollment_renewal
        end

        it "should generate passive renewal for coverall enrollment in auto renewing state" do
          renewal = subject.renew
          expect(renewal.auto_renewing?).to be_truthy
        end

        it "should generate passive renewal for coverall enrollment and assign resident role" do
          renewal = subject.renew
          expect(renewal.kind).to eq('coverall')
          expect(renewal.resident_role_id.present?).to eq true
        end
      end
    end


    describe ".renewal_product" do
      context "When consumer covered under catastrophic product" do
        let!(:renewal_cat_age_off_product) { FactoryBot.create(:renewal_ivl_silver_health_product,  hios_base_id: "94506DC0390010", hios_id: "94506DC0390010-01", csr_variant_id: "01") }
        let!(:renewal_product) { FactoryBot.create(:renewal_individual_catastophic_product, hios_id: "11111111122302-01", csr_variant_id: "01") }
        let!(:current_product) { FactoryBot.create(:active_individual_catastophic_product, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_product_id: renewal_product.id, catastrophic_age_off_product_id: renewal_cat_age_off_product.id) }

        let(:enrollment_members) { [child1, child2] }

        context "When one of the covered individuals aged off(30 years)" do
          let(:child1_dob) { current_date.next_month - 30.years }

          it "should return catastrophic aged off product" do
            expect(subject.renewal_product).to eq renewal_cat_age_off_product.id
          end
        end

        context "When all the covered individuals under 30" do
          let(:child1_dob) { current_date.next_month - 25.years }

          it "should return renewal product" do
            expect(subject.renewal_product).to eq renewal_product.id
          end
        end

        context "renew a current product to specific product" do
          subject do
            enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
            enrollment_renewal.enrollment = catastrophic_enrollment
            enrollment_renewal.assisted = assisted
            enrollment_renewal.aptc_values = aptc_values
            enrollment_renewal.renewal_coverage_start = Date.new(Date.current.year + 1,1,1)
            enrollment_renewal
          end
          let(:child1_dob) { current_date.next_month - 30.years }

          it "should return new renewal product" do
            expect(subject.renewal_product).to eq renewal_cat_age_off_product.id
          end
        end
      end
    end

    describe ".assisted_renewal_product", dbclean: :after_each do
      context "When individual currently enrolled under CSR product" do
        let!(:renewal_product) { FactoryBot.create(:renewal_ivl_silver_health_product,  hios_id: "11111111122302-04", hios_base_id: "11111111122302", csr_variant_id: "04") }
        let!(:current_product) { FactoryBot.create(:active_ivl_silver_health_product, hios_id: "11111111122302-04", hios_base_id: "11111111122302", csr_variant_id: "04", renewal_product_id: renewal_product.id) }
        let!(:csr_product) { FactoryBot.create(:renewal_ivl_silver_health_product, hios_id: "11111111122302-05", hios_base_id: "11111111122302", csr_variant_id: "05") }
        let!(:csr_01_product) { FactoryBot.create(:active_ivl_silver_health_product, hios_id: "11111111122302-01", hios_base_id: "11111111122302", csr_variant_id: "01") }

        context "and have different CSR amount for renewal product year" do
          let(:aptc_values) {{ csr_amt: "87" }}

          it "should be renewed into new CSR variant product" do
            expect(subject.assisted_renewal_product).to eq csr_product.id
          end
        end

        context "and aptc value didn't gave in renewal input CSV" do
          let(:family_enrollment_instance) { Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new}

          it "should return renewal product id" do
            family_enrollment_instance.enrollment = enrollment
            family_enrollment_instance.aptc_values = {}
            expect(family_enrollment_instance.assisted_renewal_product).to eq renewal_product.id
          end
        end

        context "and have CSR amount as 0 for renewal product year" do
          let(:aptc_values) {{ csr_amt: "0" }}

          it "should map to csr variant 01 product" do
            expect(subject.assisted_renewal_product).to eq csr_01_product.id
          end
        end

        context "and have same CSR amount for renewal product year" do
          let(:aptc_values) {{ csr_amt: "73" }}

          it "should be renewed into same CSR variant product" do
            expect(subject.assisted_renewal_product).to eq renewal_product.id
          end
        end
      end

      context "When individual not enrolled under CSR product" do
        let!(:renewal_product) { FactoryBot.create(:renewal_ivl_gold_health_product, hios_id: "11111111122302-01", csr_variant_id: "01") }
        let!(:current_product) { FactoryBot.create(:active_ivl_gold_health_product, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_product_id: renewal_product.id) }

        it "should return regular renewal product" do
          expect(subject.assisted_renewal_product).to eq renewal_product.id
        end
      end
    end

    describe ".clone_enrollment" do
      context "For QHP enrollment" do
        it "should set enrollment atrributes" do
        end
      end

      context "Assisted enrollment" do
        include_context "setup families enrollments"

        subject do
          enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
          enrollment_renewal.enrollment = enrollment_assisted
          enrollment_renewal.assisted = true
          enrollment_renewal.aptc_values = {applied_percentage: 87,
                                            applied_aptc: 150,
                                            csr_amt: 100,
                                            max_aptc: 200}
          enrollment_renewal.renewal_coverage_start = renewal_benefit_coverage_period.start_on
          enrollment_renewal
        end

        before do
          hbx_profile.benefit_sponsorship.benefit_coverage_periods.each do |bcp|
            slcsp_id = if bcp.start_on.year == renewal_csr_87_product.application_period.min.year
                         renewal_csr_87_product.id
                       else
                         active_csr_87_product.id
                       end
            bcp.update_attributes!(slcsp_id: slcsp_id)
          end
          hbx_profile.reload

          family_assisted.active_household.reload
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) {|_id, _start, age| age * 1.0}
        end

        it "should append APTC values" do
          enr = subject.clone_enrollment
          enr.save!
          expect(enr.kind).to eq subject.enrollment.kind
          renewel_enrollment = subject.assisted_enrollment(enr)
          #BigDecimal needed to round down
          expect(renewel_enrollment.applied_aptc_amount.to_f).to eq((BigDecimal.new((renewel_enrollment.total_premium * renewel_enrollment.product.ehb).to_s).round(2, BigDecimal::ROUND_DOWN)).round(2))
        end

        it "should append APTC values" do
          enr = subject.clone_enrollment
          enr.save!
          expect(subject.can_renew_assisted_product?(enr)).to eq true
        end

        it 'should create and assign new enrollment member objects to new enrollment' do
          new_enr = subject.clone_enrollment
          new_enr.save!
          expect(new_enr.subscriber.id).not_to eq(enrollment_assisted.subscriber.id)
        end
      end
    end
  end
end
