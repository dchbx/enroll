# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "insured/families/_enrollment.html.erb" do
  let(:person) { double(id: '31111113') }
  let(:family) { double(is_eligible_to_enroll?: true, updateable?: true, list_enrollments?: true, id: 'familyid') }
  let(:is_eligible_to_enroll) { family.is_eligible_to_enroll? }

  let(:employee_role) do
    instance_double(EmployeeRole)
  end

  let(:census_employee) do
    instance_double(CensusEmployee)
  end

  let(:carrier_profile) { instance_double(BenefitSponsors::Organizations::IssuerProfile, legal_name: "carefirst") }

  let(:employer_profile) do
    instance_double(
      BenefitSponsors::Organizations::AcaShopCcaEmployerProfile,
      legal_name: employer_legal_name
    )
  end

  let(:employer_legal_name) { "employer_legal_name" }

  let(:product) do
    instance_double(
      BenefitMarkets::Products::HealthProducts::HealthProduct,
      issuer_profile: carrier_profile,
      title: "A Plan Name",
      kind: plan_coverage_kind,
      active_year: plan_active_year,
      metal_level_kind: :gold,
      product_type: "A plan type",
      id: "Productid",
      hios_id: "producthiosid",
      health_plan_kind: :hmo,
      sbc_document: sbc_document
    )
  end

  let(:plan_active_year) { 2018 }
  let(:plan_coverage_kind) { "health" }
  let(:sbc_document) { nil }

  before(:each) do
    allow(view).to receive(:policy_helper).and_return(family)
    @family = family
    @person = person
  end

  context "should display legal_name" do
    let(:hbx_enrollment) do
      instance_double(
        HbxEnrollment,
        id: "hbxenrollmentid",
        family: family,
        hbx_id: "hbxenrollmenthbxid",
        enroll_step: 1,
        aasm_state: "coverage_selected",
        product: product,
        employee_role: employee_role,
        census_employee: census_employee,
        effective_on: 1.month.ago.to_date,
        updated_at: DateTime.now,
        created_at: DateTime.now,
        kind: "employer_sponsored",
        is_coverage_waived?: false,
        coverage_year: 2018,
        employer_profile: employer_profile,
        coverage_terminated?: false,
        coverage_canceled?: false,
        coverage_kind: "dental",
        coverage_termination_pending?: true,
        coverage_expired?: false,
        total_premium: 200.00,
        terminated_on: TimeKeeper.date_of_record.next_month.end_of_month,
        total_employer_contribution: 100.00,
        total_employee_cost: 100.00,
        benefit_group: nil,
        consumer_role_id: nil,
        consumer_role: nil,
        future_enrollment_termination_date: "",
        :is_ivl_actively_outstanding? => false,
        covered_members_first_names: []
      )
    end

    before :each do
      allow(hbx_enrollment).to receive(:is_reinstated_enrollment?).and_return(false)
      allow(hbx_enrollment).to receive(:can_make_changes?).and_return(true)
    end

    it "when kind is employer_sponsored" do
      allow(hbx_enrollment).to receive(:kind).and_return('employer_sponsored')
      allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(false)
      allow(hbx_enrollment).to receive(:can_make_changes?).and_return(true)
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
      expect(rendered).to match(/Plan Contact Info/)
      expect(rendered).to have_content(employer_legal_name)
      expect(rendered).to have_selector('strong', text: HbxProfile::ShortName.to_s)
      expect(rendered).to have_content(/#{hbx_enrollment.hbx_id}/)
    end

    it "when kind is employer_sponsored_cobra" do
      allow(hbx_enrollment).to receive(:kind).and_return('employer_sponsored_cobra')
      allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      allow(hbx_enrollment).to receive(:can_make_changes?).and_return(true)
      allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(true)
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
      expect(rendered).to have_content(employer_profile.legal_name)
    end

    if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
      it "when kind is individual" do
        allow(hbx_enrollment).to receive(:kind).and_return('individual')
        allow(hbx_enrollment).to receive(:is_ivl_by_kind?)
        allow(hbx_enrollment).to receive(:is_enrolled_by_aasm_state?)
        allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
        allow(hbx_enrollment).to receive(:can_make_changes?).and_return(true)
        allow(hbx_enrollment).to receive(:applied_aptc_amount).and_return(100.0)
        allow(hbx_enrollment).to receive(:is_any_enrollment_member_outstanding).and_return false
        render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
        expect(rendered).to have_content('Individual & Family')
        expect(rendered).to have_selector('strong', text: HbxProfile::ShortName.to_s)
        expect(rendered).to have_content(/#{hbx_enrollment.hbx_id}/)
      end
    end
  end

  context "without consumer_role" do

    let(:hbx_enrollment) do
      instance_double(
        HbxEnrollment,
        family: family,
        id: "hbxenrollmentid",
        hbx_id: "hbxenrollmenthbxid",
        enroll_step: 1,
        aasm_state: enrollment_aasm_state,
        product: product,
        employee_role: employee_role,
        census_employee: census_employee,
        effective_on: Date.new(2015,8,10),
        updated_at: DateTime.now,
        created_at: DateTime.now,
        kind: "employer_sponsored",
        is_coverage_waived?: false,
        coverage_year: 2018,
        employer_profile: employer_profile,
        coverage_terminated?: false,
        coverage_canceled?: false,
        coverage_kind: "dental",
        coverage_termination_pending?: false,
        coverage_expired?: false,
        total_premium: 200.00,
        total_employer_contribution: 100.00,
        total_employee_cost: 100.00,
        benefit_group: nil,
        terminated_on: terminated_on,
        consumer_role_id: nil,
        consumer_role: nil,
        future_enrollment_termination_date: future_enrollment_termination_date,
        covered_members_first_names: []
      )
    end

    let(:terminated_on) { nil }
    let(:enrollment_aasm_state) { "coverage_selected" }
    let(:future_enrollment_termination_date) { "" }

    let(:product) do
      instance_double(
        BenefitMarkets::Products::HealthProducts::HealthProduct,
        issuer_profile: carrier_profile,
        title: "A Plan Name",
        kind: plan_coverage_kind,
        active_year: plan_active_year,
        metal_level_kind: :gold,
        product_type: "A plan type",
        id: "productid",
        hios_id: "producthiosid",
        health_plan_kind: :hmo,
        sbc_document: sbc_document
      )
    end

    let(:aws_env) { ENV['AWS_ENV'] || "qa" }
    let(:sbc_document) do
      Document.new({title: 'sbc_file_name', subject: "SBC",
                    :identifier => "urn:openhbx:terms:v1:file_storage:s3:bucket:#{Settings.site.s3_prefix}-enroll-sbc-#{aws_env}#7816ce0f-a138-42d5-89c5-25c5a3408b82"})
    end

    let(:employer_profile) do
      instance_double(
        BenefitSponsors::Organizations::AcaShopCcaEmployerProfile,
        hbx_id: "3241251524", legal_name: "ACME Agency", dba: "Acme", fein: "034267010"
      )
    end

    before :each do
      allow(hbx_enrollment).to receive(:is_reinstated_enrollment?).and_return(false)
      allow(hbx_enrollment).to receive(:kind).and_return('employer_sponsored')
      allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      allow(hbx_enrollment).to receive(:can_make_changes?).and_return(true)
      allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(false)
      allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
    end

    context "internationalization" do
      let(:file_location) { "app/views/insured/families/_enrollment.html.erb"}
      it "should have all expected translations" do
        expect(translations_in_erb_tags_present?(file_location)).to eq(true)
        expect(translations_outside_erb_tags_present?(file_location)).to eq(true)
      end
    end

    it "should open the sbc pdf" do
      expect(rendered).to have_selector("a[href='#{"/document/download/#{Settings.site.s3_prefix}-enroll-sbc-#{aws_env}/7816ce0f-a138-42d5-89c5-25c5a3408b82?content_type=application/pdf&filename=APlanName.pdf&disposition=inline"}']")
    end

    it "should display the title" do
      expect(rendered).to match /#{plan_active_year} #{plan_coverage_kind.titleize} Coverage/
      expect(rendered).to match /#{Settings.site.short_name}/
    end

    it "should display the link of view detail" do
      expect(rendered).to have_selector("a[href='/products/plans/summary?active_year=#{product.active_year}&hbx_enrollment_id=#{hbx_enrollment.id}&source=account&standard_component_id=#{product.hios_id}']", text: "View Details")
    end

    it "should display the plan start" do
      expect(rendered).to have_selector('strong', text: 'Plan Start:')
      expect(rendered).to match /#{Date.new(2015,8,10)}/
    end

    it "should not disable the Make Changes button" do
      expect(rendered).to_not have_selector('.cna')
    end

    it "should display the Plan Start" do
      expect(rendered).to have_selector('strong', text: 'Plan Start:')
      expect(rendered).to match /#{Date.new(2015,8,10)}/
    end

    it "should display effective date when terminated enrollment" do
      allow(hbx_enrollment).to receive(:coverage_terminated?).and_return(true)
      expect(rendered).to match /plan start/i
    end

    it "should display market" do
      expect(rendered).to match /Market/
    end

    it "should not show a Plan End if cobra" do
      allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(true)
      expect(rendered).not_to match /plan ending/i
    end

    context "coverage_termination_pending" do
      let(:terminated_on) { TimeKeeper.date_of_record.end_of_month }
      let(:enrollment_aasm_state) { "coverage_termination_pending" }
      let(:future_enrollment_termination_date) { Date.today }

      before :each do
        allow(hbx_enrollment).to receive(:is_reinstated_enrollment?).and_return(false)
        allow(hbx_enrollment).to receive(:kind).and_return('employer_sponsored')
        allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
        allow(hbx_enrollment).to receive(:can_make_changes?).and_return(true)
        allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(false)
        allow(hbx_enrollment).to receive(:can_make_changes?).and_return(false)
        allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
        allow(hbx_enrollment).to receive(:coverage_termination_pending?).and_return(true)
        render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
      end

      it 'displays future_enrollment_termination_date when enrollment is in coverage_termination_pending state' do
        expect(rendered).to match /Future enrollment termination date:/
      end

      it 'displays terminated_on when coverage_termination_pending and not future_enrollment_termination_date' do
        expect(rendered).to have_text(/#{terminated_on.strftime("%m/%d/%Y")}/)
      end
    end
  end

  context "reinstated enrollment" do
    let!(:person) { FactoryBot.create(:person, last_name: 'John', first_name: 'Doe') }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, :person => person) }
    let(:issuer_profile) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01', issuer_profile: issuer_profile)}
    let!(:hbx_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        created_at: (TimeKeeper.date_of_record.in_time_zone("Eastern Time (US & Canada)") - 2.days),
        family: family,
        household: family.households.first,
        coverage_kind: "health",
        kind: "individual",
        aasm_state: 'coverage_selected',
        product: product
      )
    end

    before :each do
      allow(hbx_enrollment).to receive(:is_reinstated_enrollment?).and_return(true)
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
    end

    it "should have reinstated enrollment text" do
      expect(rendered).to have_text("Reinstated Enrollment")
    end
    it "should show month text" do
      expect(rendered).to match(/month/)
    end
  end

  context "when the enrollment is coverage_selected" do
    let!(:person) { FactoryBot.create(:person, last_name: 'John', first_name: 'Doe') }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, :person => person) }
    let(:issuer_profile) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
    let!(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01', issuer_profile: issuer_profile)}
    let!(:hbx_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        created_at: (TimeKeeper.date_of_record.in_time_zone("Eastern Time (US & Canada)") - 2.days),
        family: family,
        household: family.households.first,
        coverage_kind: "health",
        kind: "individual",
        aasm_state: 'coverage_selected',
        product: product
      )
    end

    before :each do
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
    end

    it "should display make changes button" do
      expect(rendered).to have_text("Make Changes")
    end
  end

  context "when the enrollment is_coverage_waived" do
    let(:waived_hbx_enrollment) do
      instance_double(
        HbxEnrollment,
        id: "some hbx enrollment id",
        hbx_id: "some hbx enrollment hbx id",
        enroll_step: 1,
        aasm_state: "inactive",
        coverage_kind: "health",
        submitted_at: DateTime.now,
        waiver_reason: "because",
        is_shop?: true,
        is_cobra_status?: false,
        product: product,
        employee_role: employee_role,
        census_employee: census_employee,
        effective_on: 1.month.ago.to_date,
        updated_at: DateTime.now,
        created_at: DateTime.now,
        kind: "employer_sponsored",
        is_coverage_waived?: true,
        coverage_year: 2018,
        employer_profile: employer_profile,
        coverage_terminated?: false,
        coverage_termination_pending?: false,
        coverage_expired?: false,
        total_premium: 200.00,
        total_employer_contribution: 100.00,
        total_employee_cost: 100.00,
        benefit_group: nil,
        consumer_role_id: nil,
        consumer_role: nil,
        future_enrollment_termination_date: "",
        covered_members_first_names: [],
        :renewing_waived? => false,
        :parent_enrollment => nil
      )
    end

    before :each do
      allow(waived_hbx_enrollment).to receive(:can_make_changes?).and_return(true)
    end

    context "it should render waived_coverage_widget " do
      context "voluntary waived" do
        before :each do
          render partial: "insured/families/enrollment", collection: [waived_hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
        end

        it "should render waiver template with read_only param as true" do
          expect(response).to render_template(partial: "insured/families/waived_coverage_widget", locals: {read_only: true, hbx_enrollment: waived_hbx_enrollment})
        end

        it "should display waiver text" do
          expect(rendered).to have_text(/You have selected to waive your employer health coverage/)
        end
      end

      context "automatically waived renewal" do
        before :each do
          allow(waived_hbx_enrollment).to receive(:aasm_state).and_return("renewing_waived")
          allow(waived_hbx_enrollment).to receive(:renewing_waived?).and_return(true)
          render partial: "insured/families/enrollment", collection: [waived_hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
        end

        it "should display automatic waive renewal text" do
          expect(rendered).to have_text(/Based upon your choice in a previous year, the system has automatically renewed your decision to waive health coverage for/)
        end
      end
    end
  end
end