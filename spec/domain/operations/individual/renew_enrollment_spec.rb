# frozen_string_literal: true

require File.join(Rails.root, 'spec/shared_contexts/ivl_eligibility')

RSpec.describe Operations::Individual::RenewEnrollment, type: :model, dbclean: :after_each do
  before do
    DatabaseCleaner.clean
  end

  include_context 'setup one tax household with one ia member'

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  let!(:person) do
    FactoryBot.create(:person,
                      :with_consumer_role,
                      :with_active_consumer_role,
                      dob: (TimeKeeper.date_of_record - 22.years))
  end

  let(:next_year_date) { TimeKeeper.date_of_record.next_year }
  let!(:renewal_product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product,
                      :ivl_product,
                      :silver,
                      application_period: next_year_date.beginning_of_year..next_year_date.end_of_year)
  end

  let!(:product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product,
                      :ivl_product,
                      :silver,
                      renewal_product_id: renewal_product.id)
  end

  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      product_id: product.id,
                      kind: 'individual',
                      family: family,
                      consumer_role_id: family.primary_person.consumer_role.id)
  end

  let!(:enrollment_member) do
    FactoryBot.create(:hbx_enrollment_member,
                      hbx_enrollment: enrollment,
                      applicant_id: family_member.id)
  end

  let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }

  let(:effective_on) { HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period.start_on }

  context 'for successfully renewal' do
    before do
      BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.last.update_attributes!(slcsp_id: renewal_product.id)
    end

    context 'assisted cases' do
      context 'renewal enrollment with assigned aptc' do
        before :each do
          tax_household.update_attributes!(effective_starting_on: next_year_date.beginning_of_year)
          tax_household.tax_household_members.first.update_attributes!(applicant_id: family_member.id)
        end

        context 'ehb premium is less than the max aptc' do
          before do
            @result = subject.call(hbx_enrollment: enrollment, effective_on: effective_on)
          end

          it 'should return success' do
            expect(@result).to be_a(Dry::Monads::Result::Success)
          end

          it 'should renew the given enrollment' do
            expect(@result.success).to be_a(HbxEnrollment)
          end

          it 'should assign aptc value to the enrollment which is same as ehb_premium' do
            expect(@result.success.applied_aptc_amount.to_f).to eq(@result.success.ivl_decorated_hbx_enrollment.total_ehb_premium)
          end

          it 'should renew enrollment with silver product of 01 variant' do
            expect(@result.success.product_id).to eq(renewal_product.id)
          end
        end

        context 'ehb premium is greater than the max aptc' do
          before do
            eligibilty_determination.update_attributes!(max_aptc: 100.00)
            @result = subject.call(hbx_enrollment: enrollment, effective_on: effective_on)
          end

          it 'should return success' do
            expect(@result).to be_a(Dry::Monads::Result::Success)
          end

          it 'should renew the given enrollment' do
            expect(@result.success).to be_a(HbxEnrollment)
          end

          it 'should assign aptc value to the enrollment which is default_percentage times of max_aptc' do
            default_percentage = EnrollRegistry[:aca_individual_assistance_benefits].setting(:default_applied_aptc_percentage).item
            expect(@result.success.applied_aptc_amount.to_f).to eq((eligibilty_determination.max_aptc * default_percentage).to_f)
          end

          it 'should assign aptc value to the enrollment which is not same as ehb_premium' do
            expect(@result.success.applied_aptc_amount.to_f).not_to eq(@result.success.ivl_decorated_hbx_enrollment.total_ehb_premium)
          end

          it 'should renew enrollment with silver product of 01 variant' do
            expect(@result.success.product_id).to eq(renewal_product.id)
          end
        end

        context 'current enrollment has some aptc applied' do
          before do
            enrollment.update_attributes!(elected_aptc_pct: 0.5, applied_aptc_amount: 50.0)
            eligibilty_determination.update_attributes!(max_aptc: 100.00)
            @result = subject.call(hbx_enrollment: enrollment, effective_on: effective_on)
          end

          it 'should return success' do
            expect(@result).to be_a(Dry::Monads::Result::Success)
          end

          it 'should renew the given enrollment' do
            expect(@result.success).to be_a(HbxEnrollment)
          end

          it 'should assign aptc value to the enrollment which is elected_aptc_pct times of max_aptc' do
            expect(@result.success.applied_aptc_amount.to_f).to eq((eligibilty_determination.max_aptc * enrollment.elected_aptc_pct).to_f)
          end

          it 'should assign aptc value to the enrollment which is not same as ehb_premium' do
            expect(@result.success.applied_aptc_amount.to_f).not_to eq(@result.success.ivl_decorated_hbx_enrollment.total_ehb_premium)
          end

          it 'should renew enrollment with silver product of 01 variant' do
            expect(@result.success.product_id).to eq(renewal_product.id)
          end
        end
      end

      context 'renewal enrollment with csr product' do
        let!(:renewal_product_87) do
          FactoryBot.create(:benefit_markets_products_health_products_health_product,
                            :ivl_product,
                            :silver,
                            application_period: next_year_date.beginning_of_year..next_year_date.end_of_year,
                            hios_base_id: renewal_product.hios_base_id,
                            csr_variant_id: '05',
                            hios_id: "#{renewal_product.hios_base_id}-05")
        end

        before do
          BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
          tax_household.update_attributes!(effective_starting_on: next_year_date.beginning_of_year)
          tax_household.tax_household_members.first.update_attributes!(applicant_id: family_member.id)
          @result = subject.call(hbx_enrollment: enrollment, effective_on: effective_on)
        end

        it 'should return success' do
          expect(@result).to be_a(Dry::Monads::Result::Success)
        end

        it 'should renew the given enrollment' do
          expect(@result.success).to be_a(HbxEnrollment)
        end

        it 'should assign aptc values to the enrollment' do
          expect(@result.success.applied_aptc_amount.to_f).to eq(198.86)
        end

        it 'should renew enrollment with silver product of 01 variant' do
          expect(@result.success.product_id).to eq(renewal_product_87.id)
        end
      end
    end

    context 'unassisted enrollment renewal' do
      before do
        @result = subject.call(hbx_enrollment: enrollment, effective_on: effective_on)
      end

      it 'should return success' do
        expect(@result).to be_a(Dry::Monads::Result::Success)
      end

      it 'should renew the given enrollment' do
        expect(@result.success).to be_a(HbxEnrollment)
      end

      it 'should not assign any aptc to the enrollment' do
        expect(@result.success.applied_aptc_amount.to_f).to be_zero
      end

      it 'should renew enrollment with silver product of 01 variant' do
        expect(@result.success.product_id).to eq(renewal_product.id)
      end
    end
  end

  context 'for renewal failure' do
    context 'bad input object' do
      before :each do
        @result = subject.call(hbx_enrollment: 'enrollment string', effective_on: effective_on)
      end

      it 'should return failure' do
        expect(@result).to be_a(Dry::Monads::Result::Failure)
      end

      it 'should return failure with message' do
        expect(@result.failure).to eq('Given object is not a valid enrollment object')
      end
    end

    context 'shop enrollment object' do
      before :each do
        enrollment.update_attributes!(kind: 'employer_sponsored')
        @result = subject.call(hbx_enrollment: enrollment, effective_on: effective_on)
      end

      it 'should return failure' do
        expect(@result).to be_a(Dry::Monads::Result::Failure)
      end

      it 'should return failure with message' do
        expect(@result.failure).to eq('Given enrollment is not IVL by kind')
      end
    end

    context 'with an existing renewal enrollment' do
      let!(:renewal_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          product_id: product.id,
                          aasm_state: 'auto_renewing',
                          effective_on: HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period.start_on,
                          kind: 'individual',
                          family: family,
                          consumer_role_id: family.primary_person.consumer_role.id)
      end

      let!(:renewal_enrollment_member) do
        FactoryBot.create(:hbx_enrollment_member,
                          hbx_enrollment: renewal_enrollment,
                          applicant_id: family_member.id)
      end

      before :each do
        @result = subject.call(hbx_enrollment: enrollment, effective_on: effective_on)
      end

      it 'should return failure' do
        expect(@result).to be_a(Dry::Monads::Result::Failure)
      end

      it 'should return failure with message' do
        expect(@result.failure).to eq('There exists active enrollments for given family in the year with renewal_benefit_coverage_period')
      end
    end
  end
end
