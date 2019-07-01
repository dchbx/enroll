require 'rails_helper'

RSpec.describe "insured/families/_enrollment.html.erb" do
  let(:person) { double(id: '31111113') }
  let(:family) { double(is_eligible_to_enroll?: true, updateable?: true, list_enrollments?: true) }

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
      allow(view).to receive(:disable_make_changes_button?).with(hbx_enrollment).and_return(true)
    end

    it "when kind is employer_sponsored" do
      allow(hbx_enrollment).to receive(:kind).and_return('employer_sponsored')
      allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(false)
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
      expect(rendered).to have_content(employer_legal_name)
      expect(rendered).to have_selector('strong', text: "#{HbxProfile::ShortName}")
      expect(rendered).to have_content(/#{hbx_enrollment.hbx_id}/)
    end

    it "when kind is employer_sponsored_cobra" do
      allow(hbx_enrollment).to receive(:kind).and_return('employer_sponsored_cobra')
      allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(true)
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
      expect(rendered).to have_content(employer_profile.legal_name)
    end

    if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
    it "when kind is individual" do
      allow(hbx_enrollment).to receive(:kind).and_return('individual')
      allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      allow(hbx_enrollment).to receive(:applied_aptc_amount).and_return(100.0)
      allow(hbx_enrollment).to receive(:is_any_enrollment_member_outstanding).and_return false
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
      expect(rendered).to have_content('Individual & Family')
      expect(rendered).to have_selector('strong', text: "#{HbxProfile::ShortName}")
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
                      :identifier=>"urn:openhbx:terms:v1:file_storage:s3:bucket:#{Settings.site.s3_prefix}-enroll-sbc-#{aws_env}#7816ce0f-a138-42d5-89c5-25c5a3408b82"})
    end

    let(:employer_profile) do
      instance_double(
        BenefitSponsors::Organizations::AcaShopCcaEmployerProfile,
        hbx_id: "3241251524", legal_name: "ACME Agency", dba: "Acme", fein: "034267010")
    end

    before :each do
      allow(hbx_enrollment).to receive(:kind).and_return('employer_sponsored')
      allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(false)
      allow(view).to receive(:disable_make_changes_button?).with(hbx_enrollment).and_return(false)
      allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
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
        allow(hbx_enrollment).to receive(:kind).and_return('employer_sponsored')
        allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
        allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(false)
        allow(view).to receive(:disable_make_changes_button?).with(hbx_enrollment).and_return(false)
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

=begin
  These scenarios need to be refactored for the IVL market in DC new model - refs#41775
  if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  context "with consumer_role", dbclean: :before_each do
<<<<<<< HEAD
    let(:plan) {FactoryBot.build(:benefit_markets_products_health_products_health_product, :created_at =>  TimeKeeper.date_of_record)}
    let(:employee_role) { FactoryBot.create(:employee_role) }
    let(:census_employee) { FactoryBot.create(:census_employee, employee_role_id: employee_role.id)}

    let(:hbx_enrollment) do
      instance_double(
        HbxEnrollment,
        product: plan,
        id: "12345",
        total_premium: 200,
        kind: 'individual',
        covered_members_first_names: ["name"],
        can_complete_shopping?: false,
        enroll_step: 1,
        subscriber: nil,
        coverage_terminated?: false,
        coverage_termination_pending?: false,
        may_terminate_coverage?: true,
        effective_on: Date.new(2015,8,10),
        consumer_role: double,
        applied_aptc_amount: 100,
        employee_role: employee_role,
        census_employee: census_employee,
        status_step: 2,
        aasm_state: 'coverage_selected'
      )
    end

   let(:benefit_group) { FactoryBot.create(:benefit_group) }
=======
    let(:plan) {FactoryBot.build(:plan, :created_at =>  TimeKeeper.date_of_record)}
    let(:employee_role) { FactoryBot.create(:employee_role) }
    let(:census_employee) { FactoryBot.create(:census_employee, employee_role_id: employee_role.id)}
    let(:hbx_enrollment) {instance_double("HbxEnrollment", plan: plan, id: "12345", total_premium: 200, kind: 'individual',
                                 covered_members_first_names: ["name"], can_complete_shopping?: false,
                                 enroll_step: 1, subscriber: nil, coverage_terminated?: false,
                                 may_terminate_coverage?: true, effective_on: Date.new(2015,8,10),
                                 consumer_role: double, applied_aptc_amount: 100, employee_role: employee_role, census_employee: census_employee,
                                  aasm_state: 'coverage_selected', :is_ivl_actively_outstanding? => false)}
   let(:benefit_group) { FactoryBot.create(:benefit_group) }
>>>>>>> a9619997ea... refs #33617 remove enrolled contingent aasm state in EA

    before :each do
      allow(hbx_enrollment).to receive(:coverage_canceled?).and_return(false)
      allow(hbx_enrollment).to receive(:coverage_expired?).and_return(false)
      allow(hbx_enrollment).to receive(:is_coverage_waived?).and_return(false)
      allow(hbx_enrollment).to receive(:coverage_year).and_return(plan.active_year)
      allow(hbx_enrollment).to receive(:created_at).and_return(plan.created_at)
      allow(hbx_enrollment).to receive(:hbx_id).and_return(true)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(hbx_enrollment).to receive(:consumer_role_id).and_return(person.id)
      allow(census_employee.employee_role).to receive(:is_under_open_enrollment?).and_return(true)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      allow(hbx_enrollment).to receive(:coverage_termination_pending?).and_return(false)
      allow(hbx_enrollment).to receive(:future_enrollment_termination_date).and_return(nil)
      allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
    end

    it "should display the title" do
      expect(rendered).to match /#{plan.active_year} health Coverage/i
      expect(rendered).to match /#{Settings.site.short_name}/
    end

    it "should display the aptc amount" do
      expect(rendered).to have_selector('label', text: 'APTC amount:')
      expect(rendered).to have_selector('strong', text: '$100')
    end


    it "should not disable the Make Changes button" do
      expect(rendered).to_not have_selector('.cna')
    end

  end
<<<<<<< HEAD
=======

  context "about covered_members_first_names of hbx_enrollment" do
    let(:plan) {FactoryBot.build(:plan, :created_at => TimeKeeper.date_of_record)}
    let(:employee_role) { FactoryBot.create(:employee_role) }
    let(:census_employee) { FactoryBot.create(:census_employee, employee_role_id: employee_role.id)}
    let(:hbx_enrollment) {double(plan: plan, id: "12345", total_premium: 200, kind: 'individual',
                                 covered_members_first_names: [], can_complete_shopping?: false,
                                 enroll_step: 1, subscriber: nil, coverage_terminated?: false,
                                 may_terminate_coverage?: true, effective_on: Date.new(2015,8,10),
                                 consumer_role: double, applied_aptc_amount: 100, employee_role: employee_role, census_employee: census_employee,
                                  aasm_state: 'coverage_selected', :is_ivl_actively_outstanding? => true)}
    let(:benefit_group) { FactoryBot.create(:benefit_group) }

    before :each do
      allow(hbx_enrollment).to receive(:coverage_canceled?).and_return(false)
      allow(hbx_enrollment).to receive(:coverage_expired?).and_return(false)
      allow(hbx_enrollment).to receive(:is_coverage_waived?).and_return(false)
      allow(hbx_enrollment).to receive(:coverage_year).and_return(plan.active_year)
      allow(hbx_enrollment).to receive(:created_at).and_return(plan.created_at)
      allow(hbx_enrollment).to receive(:hbx_id).and_return(true)
      allow(hbx_enrollment).to receive(:in_time_zone).and_return(true)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(hbx_enrollment).to receive(:consumer_role_id).and_return(person.id)
      allow(census_employee.employee_role).to receive(:is_under_open_enrollment?).and_return(true)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      allow(hbx_enrollment).to receive(:coverage_termination_pending?).and_return(false)
      allow(hbx_enrollment).to receive(:future_enrollment_termination_date).and_return(nil)
      allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
    end

    it "should not disable the Make Changes button" do
      expect(rendered).to_not have_selector('.cna')
    end
>>>>>>> a9619997ea... refs #33617 remove enrolled contingent aasm state in EA
  end

  context "when the enrollment is coverage_terminated" do
    let(:hbx_enrollment) do
      instance_double(
        HbxEnrollment,
        id: "some hbx enrollment id",
        hbx_id: "some hbx enrollment hbx id",
        enroll_step: 1,
        aasm_state: "coverage_terminated",
        is_shop?: true,
        is_cobra_status?: false,
        product: product,
        employee_role: employee_role,
        census_employee: census_employee,
        effective_on: 1.month.ago.to_date,
        updated_at: DateTime.now,
        created_at: DateTime.now,
        terminated_on: DateTime.now - 1.day,
        may_terminate_coverage?: false,
        kind: "employer_sponsored",
        is_coverage_waived?: false,
        coverage_year: 2018,
        employer_profile: employer_profile,
        coverage_termination_pending?: false,
        coverage_terminated?: true,
        coverage_expired?: false,
        total_premium: 200.00,
        total_employer_contribution: 100.00,
        total_employee_cost: 100.00,
        benefit_group: nil,
        consumer_role_id: nil,
        consumer_role: nil,
        future_enrollment_termination_date: "",
        covered_members_first_names: []
      )
    end

    before :each do
      allow(view).to receive(:disable_make_changes_button?).with(hbx_enrollment).and_return(true)
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
    end

    it "should not display status as Coverage Terminated" do
      expect(rendered).not_to have_text(/Coverage Terminated/)
    end

    it "should display as Terminated" do
      expect(rendered).to have_text(/Terminated/)
    end
  end

  context "when the enrollment is coverage_expired" do
    let(:hbx_enrollment) do
      instance_double(
        HbxEnrollment,
        id: "some hbx enrollment id",
        hbx_id: "some hbx enrollment hbx id",
        enroll_step: 1,
        aasm_state: "coverage_expired",
        coverage_kind: "health",
        submitted_at: DateTime.now,
        is_shop?: true,
        is_cobra_status?: false,
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
        coverage_termination_pending?: false,
        coverage_expired?: true,
        total_premium: 200.00,
        total_employer_contribution: 100.00,
        total_employee_cost: 100.00,
        benefit_group: nil,
        consumer_role_id: nil,
        consumer_role: nil,
        future_enrollment_termination_date: "",
        covered_members_first_names: []
      )
    end

    let(:end_on) { Date.today }

    before :each do
      allow(view).to receive(:disable_make_changes_button?).with(hbx_enrollment).and_return true
      allow(view).to receive(:enrollment_coverage_end).with(hbx_enrollment).and_return end_on
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
    end

    it "should not display status as Coverage Expired" do
      expect(rendered).not_to have_text(/Coverage Expired/)
    end

    it "should display coverage_expired enrollment as Coverage Period Ended" do
      expect(rendered).to have_text(/Coverage Period Ended/)
    end

    it "should display coverage end date for expired enrollment" do
      expect(rendered).to have_text(/Coverage End/)
      expect(rendered).to have_text(/#{end_on.strftime("%m/%d/%Y")}/)
    end
  end

  context "when the enrollment is_coverage_waived" do
    let(:hbx_enrollment) do
      instance_double(
        HbxEnrollment,
        id: "some hbx enrollment id",
        hbx_id: "some hbx enrollment hbx id",
        enroll_step: 1,
        aasm_state: "coverage_waived",
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
        covered_members_first_names: []
      )
    end

    before :each do
      allow(view).to receive(:disable_make_changes_button?).with(hbx_enrollment).and_return true
    end

    context "it should render waived_coverage_widget " do

      before :each do
        render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
      end

      it "should render waiver template with read_only param as true" do
        expect(response).to render_template(partial: "insured/families/waived_coverage_widget", locals: {read_only: true, hbx_enrollment: hbx_enrollment})
      end

      it "should display waiver text" do
        expect(rendered).to have_text(/You have selected to waive your employer health coverage/)
      end
    end

    context "it should render waived_coverage_widget with read_only param value as helper method result" do

      before :each do
        render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
      end

      it "should render waiver template with read_only param" do
        expect(response).to render_template(partial: "insured/families/waived_coverage_widget", locals: {read_only: view.disable_make_changes_button?(hbx_enrollment), hbx_enrollment: hbx_enrollment})
      end
    end
  end
=end
end
