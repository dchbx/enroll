require 'rails_helper'
RSpec.describe EligibilityDetermination, type: :model, dbclean: :after_each do
  let(:current_date) { TimeKeeper.date_of_record }

  context 'include mongoid_document ' do
    it { is_expected.to be_mongoid_document }
  end

  context '.modelFeilds' do
    it { is_expected.to have_field(:e_pdc_id).of_type(String) }
    it { is_expected.to have_field(:benchmark_plan_id).of_type(BSON::ObjectId) }
    it { is_expected.to have_field(:max_aptc).of_type(Money).with_default_value_of(0.00) }
    it { is_expected.to have_field(:magi_medicaid_monthly_household_income).of_type(Money).with_default_value_of(0.00) }
    it { is_expected.to have_field(:magi_medicaid_monthly_allowable_limit_income).of_type(Money).with_default_value_of(0.00) }
    it { is_expected.to have_field(:csr_household_income).of_type(Money).with_default_value_of(0.00) }
    it { is_expected.to have_field(:csr_allowable_limit_income).of_type(Money).with_default_value_of(0.00) }
    it { is_expected.to have_field(:aptc_csr_annual_household_income).of_type(Money).with_default_value_of(0.00) }
    it { is_expected.to have_field(:aptc_annual_income_limit).of_type(Money).with_default_value_of(0.00) }
    it { is_expected.to have_field(:csr_annual_income_limit).of_type(Money).with_default_value_of(0.00) }
    it { is_expected.to have_field(:premium_credit_strategy_kind).of_type(String) }
    it { is_expected.to have_field(:csr_percent_as_integer).of_type(Integer).with_default_value_of(0) }
    it { is_expected.to have_field(:csr_eligibility_kind).of_type(String).with_default_value_of('csr_100') }
    it { is_expected.to have_field(:determined_at).of_type(DateTime) }
    it { is_expected.to have_field(:determined_on).of_type(DateTime) }
    it { is_expected.to have_field(:source).of_type(String) }
  end

  context '.associations' do
    it 'embedded many tax_household' do
      assc = described_class.reflect_on_association(:tax_household)
      expect(assc.macro).to eq :embedded_in
    end
  end

  context '.constants' do
    it 'should have CSR_KINDS constant' do
      subject.class.should be_const_defined(:CSR_KINDS)
      expect(described_class::CSR_KINDS).to eq(%w(csr_100 csr_94 csr_87 csr_73))
    end
    it 'should have SOURCE_KINDS constant' do
      subject.class.should be_const_defined(:SOURCE_KINDS)
      expect(described_class::SOURCE_KINDS).to eq(%w(Admin Curam Haven))
    end
    it 'should have CSR_KIND_TO_PLAN_VARIANT_MAP constant' do
      subject.class.should be_const_defined(:CSR_KIND_TO_PLAN_VARIANT_MAP)
      expect(described_class::CSR_KIND_TO_PLAN_VARIANT_MAP).to eq({ 'csr_100' => '01', 'csr_94' => '06', 'csr_87' => '05', 'csr_73' => '04', 'csr_0' => '02', 'limited' => '03' })
    end
  end

  context '.validate preesence of' do
    it { is_expected.to validate_presence_of(:determined_on) }
    it { is_expected.to validate_presence_of(:max_aptc) }
    it { is_expected.to validate_presence_of(:csr_percent_as_integer) }
  end

  describe 'new instance eligibility_determination' do
    let!(:plan)                          { FactoryGirl.create(:plan, active_year: 2019, hios_id: '86052DC0400001-01') }
    let(:family)                         { FactoryGirl.create(:family, :with_primary_family_member) }
    let!(:hbx_profile)                   { FactoryGirl.create(:hbx_profile,:open_enrollment_coverage_period) }
    let(:household)                      { family.active_household }
    let(:application)                    { FactoryGirl.create(:application, family: family) }
    let(:tax_household)                  { FactoryGirl.create(:tax_household, effective_starting_on: Date.new(current_date.year, 1, 1), effective_ending_on: nil, household: household, application_id: application.id) }
    let(:eligibility_determination)      { FactoryGirl.create(:eligibility_determination, tax_household: tax_household, source: 'Curam', csr_eligibility_kind: 'csr_87') }
    let(:determined_on)                  { TimeKeeper.datetime_of_record }
    let(:max_aptc)                       { 217.85 }
    let(:csr_percent_as_integer)         { 94 }
    let(:csr_eligibility_kind)           { 'csr_94' }
    let(:e_pdc_id)                       { '3110344' }
    let(:premium_credit_strategy_kind)   { 'allocated_lump_sum_credit' }

    let(:max_aptc_default)               { 0.00 }
    let(:csr_percent_as_integer_default) { 0 }
    let(:csr_eligibility_kind_default)   { 'csr_100' }

    let(:valid_params)                   { { tax_household: tax_household, determined_on: determined_on, max_aptc: max_aptc, csr_percent_as_integer: csr_percent_as_integer, e_pdc_id: e_pdc_id, premium_credit_strategy_kind: premium_credit_strategy_kind, source: 'Curam' } }

    context 'a new instance' do
      context 'with no arguments' do
        let(:params) { {} }

        it 'should set all default values' do
          expect(described_class.new.max_aptc).to eq max_aptc_default
          expect(described_class.new.csr_percent_as_integer).to eq csr_percent_as_integer_default
          expect(described_class.new.csr_eligibility_kind).to eq csr_eligibility_kind_default
        end

        it 'should not save' do
          eligibility_determination = described_class.new(**params)
          eligibility_determination.tax_household = tax_household
          expect(eligibility_determination.save).to be_falsey
        end
      end

      context 'with no determined on' do
        let(:params) { valid_params.except(:determined_on) }

        it 'should fail validation' do
          expect(described_class.create(**params).errors[:determined_on].any?).to be_truthy
        end
      end

      context 'with a value for csr percent as integer' do
        let(:params) { { csr_percent_as_integer: csr_percent_as_integer } }

        it 'should set the csr eligibility value' do
          expect(described_class.new(**params).csr_percent_as_integer).to eq csr_percent_as_integer
          expect(described_class.new(**params).csr_eligibility_kind).to eq csr_eligibility_kind
        end
      end

      context 'with all required attributes' do
        let(:params)                    { valid_params }
        let(:eligibility_determination) { tax_household.eligibility_determinations.new(**params) }

        it 'should be valid' do
          expect(eligibility_determination.valid?).to be_truthy
        end

        it 'should save' do
          expect(eligibility_determination.save).to be_truthy
        end

        it 'should set the premium credit strategy value' do
          expect(eligibility_determination.premium_credit_strategy_kind).to eq premium_credit_strategy_kind
        end

        context 'and it is saved' do
          it 'should exist for the family' do
            application.reload
            eligibility_determination.save
            expect(family.active_approved_application.eligibility_determinations.first).to eq eligibility_determination
          end
        end
      end
    end

    context '.benchmark_plan' do
      it 'returns benchmark plan' do
        eligibility_determination.benchmark_plan = plan
        expect(eligibility_determination.benchmark_plan).to eq(plan)
      end

      it 'returns nil' do
        expect(application.benchmark_plan).to eq(nil)
      end
    end

    context 'with eligibility determination' do
      it 'returns family object' do
        expect(eligibility_determination.family).to eq(family)
      end
    end

    context 'with eligibility determination csr_value' do
      it 'returns float value ' do
        expect(eligibility_determination.csr_percent).to eq(0.94)
      end
    end

    context 'with eligibility determination of application' do
      it 'returns application' do
        expect(eligibility_determination.application).to eq(application)
      end
    end
  end
end
