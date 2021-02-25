require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe EligibilityDetermination, type: :model, dbclean: :after_each do
  it { should validate_presence_of :determined_at }
  it { should validate_presence_of :max_aptc }
  it { should validate_presence_of :csr_percent_as_integer }

  let(:family)                        { FactoryBot.create(:family, :with_primary_family_member) }
  let(:family_member) {FactoryBot.create(:family_member, family: household.family)}
  let(:household)                     { family.households.first }
  let(:tax_household)                 { FactoryBot.create(:tax_household, household: household, effective_starting_on: start_on, effective_ending_on: nil) }
  let(:determined_at)                 { TimeKeeper.datetime_of_record }
  let(:max_aptc)                      { 217.85 }
  let(:csr_percent_as_integer)        { 94 }
  let(:csr_eligibility_kind)          { "csr_94" }
  let(:e_pdc_id)                      { "3110344" }
  let(:premium_credit_strategy_kind)  { "allocated_lump_sum_credit" }
  let!(:start_on) {TimeKeeper.date_of_record.beginning_of_year}

  let(:max_aptc_default)                { 0.00 }
  let(:csr_percent_as_integer_default)  { 0 }
  let(:csr_eligibility_kind_default)    { 'csr_0' }

  let(:valid_params){
      {
        tax_household: tax_household,
        determined_at: determined_at,
        max_aptc: max_aptc,
        csr_percent_as_integer: csr_percent_as_integer,
        e_pdc_id: e_pdc_id,
        premium_credit_strategy_kind: premium_credit_strategy_kind,
        source: 'Admin'
      }
    }

  context 'for after create' do
    let(:product1) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01', metal_level_kind: :silver)}
    let(:hbx_with_aptc_1) do
      enr = FactoryBot.create(:hbx_enrollment,
                              product: product1,
                              family: family,
                              household: household,
                              is_active: true,
                              aasm_state: 'coverage_selected',
                              changing: false,
                              effective_on: start_on,
                              kind: "individual",
                              applied_aptc_amount: 100,
                              elected_aptc_pct: 0.7)
      FactoryBot.create(:hbx_enrollment_member, applicant_id: family_member.id, hbx_enrollment: enr)
      enr
    end
    let!(:hbx_enrollments) {[hbx_with_aptc_1]}
    before do
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) {|_id, _start, age| age * 1.0}
      FactoryBot.create(:eligibility_determination, tax_household: tax_household)
      @enrollments = family.reload.hbx_enrollments
    end

    it 'should call after create' do
      expect(@enrollments.count).to eq(2)
    end
  end

  context "a new instance" do
    context "with no arguments" do
      let(:params) {{}}

      it "should set all default values" do
        expect(EligibilityDetermination.new().max_aptc).to eq max_aptc_default
        expect(EligibilityDetermination.new().csr_percent_as_integer).to eq csr_percent_as_integer_default
        expect(EligibilityDetermination.new().csr_eligibility_kind).to eq csr_eligibility_kind_default
      end

      it "should not save" do
        expect(EligibilityDetermination.create(**params).valid?).to be_falsey
      end
    end

    context "with no determined at" do
      let(:valid_params){
        {
          tax_household: tax_household,
          determined_at: nil,
          max_aptc: max_aptc,
          csr_percent_as_integer: csr_percent_as_integer,
          e_pdc_id: e_pdc_id,
          premium_credit_strategy_kind: premium_credit_strategy_kind,
        }
      }
      before :each do
        allow(tax_household).to receive(:submitted_at).and_return(nil)
      end

      it "should fail validation" do
        expect(EligibilityDetermination.create(**valid_params).errors[:determined_at].any?).to be_truthy
      end
    end

    context "with a value for csr percent as integer" do
      let(:params)  {{ csr_percent_as_integer: csr_percent_as_integer }}

      it "should set the csr eligibility value" do
        expect(EligibilityDetermination.new(**params).csr_percent_as_integer).to eq csr_percent_as_integer
        expect(EligibilityDetermination.new(**params).csr_eligibility_kind).to eq csr_eligibility_kind
      end
    end

    context "with all required attributes" do
      let(:params)                    { valid_params }
      let(:eligibility_determination) { EligibilityDetermination.new(**params) }

      it "should be valid" do
        expect(eligibility_determination.valid?).to be_truthy
      end

      it "should save" do
        expect(eligibility_determination.save).to be_truthy
      end

      it "should set the premium credit strategy value" do
        expect(eligibility_determination.premium_credit_strategy_kind).to eq premium_credit_strategy_kind
      end

      context "and it is saved" do
        before { eligibility_determination.save }

        it "should be findable by ID" do
          expect(EligibilityDetermination.find(eligibility_determination.id)).to eq eligibility_determination
        end
      end
    end

    context 'for csr_eligibility_kind' do
      shared_examples_for 'ensures csr_eligibility_kind field value' do |csr_percent_as_integer, csr_eligibility_kind|
        before do
          @eligibility_determination = EligibilityDetermination.new({csr_percent_as_integer: csr_percent_as_integer})
        end

        it 'should match with expected csr_eligibility_kind for given csr_percent_as_integer' do
          expect(@eligibility_determination.csr_eligibility_kind).to eq(csr_eligibility_kind)
        end
      end

      context 'a valid csr_percent_as_integer' do
        it_behaves_like 'ensures csr_eligibility_kind field value', 100, 'csr_100'
        it_behaves_like 'ensures csr_eligibility_kind field value', 94, 'csr_94'
        it_behaves_like 'ensures csr_eligibility_kind field value', 87, 'csr_87'
        it_behaves_like 'ensures csr_eligibility_kind field value', 73, 'csr_73'
        it_behaves_like 'ensures csr_eligibility_kind field value', 0, 'csr_0'
        it_behaves_like 'ensures csr_eligibility_kind field value', -1, 'csr_limited'
      end
    end
  end

  context 'SOURCE_KINDS' do
    it 'should have constant SOURCE_KINDS' do
      expect(subject.class).to be_const_defined(:SOURCE_KINDS)
    end

    it 'should have constant SOURCE_KINDS with a specific set of list' do
      expect(::EligibilityDetermination::SOURCE_KINDS).to eq(['Curam', 'Admin', 'Renewals', 'Faa'])
    end
  end
end
end
