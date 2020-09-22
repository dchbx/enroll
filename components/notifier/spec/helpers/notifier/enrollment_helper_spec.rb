# frozen_string_literal: true

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"

RSpec.describe Notifier::EnrollmentHelper, :type => :helper, dbclean: :after_each do
  let!(:hbx_enrollment)  do
    double(
      coverage_start_on: "",
      premium_amount: "",
      product: double(
        application_period: (Date.today..(Date.today + 1.week)),
        title: "Product Title",
        metal_level_kind: "bronze",
        kind: "health",
        issuer_profile: double(legal_name: "Legal Name"),
        hsa_eligibility: "",
        deductible: "",
        is_csr?: true,
        family_deductible: ""
      ),
      dependents: "",
      kind: "",
      enrolled_count: "",
      enrollment_kind: "",
      coverage_kind: "",
      aptc_amount: "",
      is_receiving_assistance: "",
      responsible_amount: "",
      effective_on: "",
      total_premium: 10,
      hbx_enrollment_members: [],
      applied_aptc_amount: 1
    )
  end

  context "#enrollment_hash" do
    it "should return a MergeDataModels::Enrollment when enrollment is passed through" do
      expect(helper.enrollment_hash(hbx_enrollment).class).to eq(Notifier::MergeDataModels::Enrollment)
    end
  end

  context "#is_receiving_assistance?" do
    let(:hbx_enrollment1) do
      double(
        applied_aptc_amount: 1,
        product: double(is_csr?: true)
      )
    end

    it "should return a boolean" do
      expect(helper.is_receiving_assistance?(hbx_enrollment1)).to eq(true)
    end
  end

  context "#responsible_amount" do
    it "should return the amount" do
      expect(helper.responsible_amount(hbx_enrollment)).to eq("$9.00")
    end
  end

  context '#enrollment_members_hash' do
    include_context 'setup benefit market with market catalogs and product packages'

    let!(:person3) { FactoryBot.create(:person, :with_consumer_role) }
    let!(:family3) { FactoryBot.create(:family, :with_primary_family_member, person: person3) }
    let(:dependents) { family3.family_members }
    let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year }
    let(:application_period) { effective_on..effective_on.end_of_year }

    let!(:current_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        family: family3,
        product: product,
        household: family3.active_household,
        coverage_kind: "health",
        effective_on: effective_on,
        kind: 'individual',
        hbx_enrollment_members: [hbx_en_member3],
        aasm_state: 'coverage_selected'
      )
    end

    let(:product) do
      FactoryBot.create(
        :benefit_markets_products_health_products_health_product,
        :with_renewal_product,
        :with_issuer_profile,
        benefit_market_kind: :aca_individual,
        kind: :health,
        assigned_site: site,
        service_area: service_area,
        renewal_service_area: renewal_service_area,
        csr_variant_id: '01',
        application_period: application_period
      )
    end

    let(:hbx_en_member3) do
      FactoryBot.build(
        :hbx_enrollment_member,
        eligibility_date: effective_on,
        coverage_start_on: effective_on,
        applicant_id: dependents[0].id
      )
    end

    it "should return Notifier::MergeDataModels::Person" do
      expect(helper.enrollment_members_hash(current_enrollment)[0].class).to eq(Notifier::MergeDataModels::Person)
    end

    it 'should return enrollment member name' do
      expect(helper.enrollment_members_hash(current_enrollment)[0].first_name).to eq(person3.first_name)
    end

    it 'should return enrollment member age' do
      expect(helper.enrollment_members_hash(current_enrollment)[0].age).to eq(person3.age_on(TimeKeeper.date_of_record))
    end
  end
end