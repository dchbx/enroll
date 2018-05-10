require 'rails_helper'

RSpec.describe "insured/families/_enrollment.html.erb" do
  let(:person) { double(id: '31111113') }
  let(:family) { double(is_eligible_to_enroll?: true, updateable?: true, list_enrollments?: true) }

  before(:each) do
    allow(view).to receive(:policy_helper).and_return(family)
    @family = family
    @person = person
  end

  context "should display legal_name" do
    let(:employer_profile) { FactoryGirl.build(:employer_profile) }
    let(:plan) { FactoryGirl.build(:plan) }
    let(:hbx) { HbxEnrollment.new(created_at: TimeKeeper.date_of_record, effective_on: TimeKeeper.date_of_record) }
    before :each do
      allow(hbx).to receive(:employer_profile).and_return(employer_profile)
      allow(hbx).to receive(:plan).and_return(plan)
      allow(hbx).to receive(:coverage_year).and_return(2016)
    end

    it "when kind is employer_sponsored" do
      allow(hbx).to receive(:kind).and_return('employer_sponsored')
      render partial: "insured/families/enrollment", collection: [hbx], as: :hbx_enrollment, locals: { read_only: false }
      expect(rendered).to have_content(employer_profile.legal_name)
    end

    it "when kind is employer_sponsored_cobra" do
      allow(hbx).to receive(:kind).and_return('employer_sponsored_cobra')
      render partial: "insured/families/enrollment", collection: [hbx], as: :hbx_enrollment, locals: { read_only: false }
      expect(rendered).to have_content(employer_profile.legal_name)
    end

    it "when kind is individual" do
      allow(hbx).to receive(:kind).and_return('individual')
      render partial: "insured/families/enrollment", collection: [hbx], as: :hbx_enrollment, locals: { read_only: false }
      expect(rendered).to have_content('Individual & Family')
    end
  end

  context "without consumer_role", dbclean: :before_each do
    let(:aws_env) { ENV['AWS_ENV'] || "qa" }
    let(:mock_organization){ instance_double("Organization", hbx_id: "3241251524", legal_name: "ACME Agency", dba: "Acme", fein: "034267010")}
    let(:mock_carrier_profile) { instance_double("CarrierProfile", :dba => "a carrier name", :legal_name => "name", :organization => mock_organization) }
    let(:plan) { double("Plan",
      :name => "A Plan Name",
      :carrier_profile_id => "a carrier profile id",
      :carrier_profile => mock_carrier_profile,
      :metal_level => "Silver",
      :coverage_kind => "health",
      :hios_id => "19393939399",
      :plan_type => "A plan type",
      :created_at =>  TimeKeeper.date_of_record,
      :active_year => TimeKeeper.date_of_record.year,

      :nationwide => true,
      :deductible => 0,
      :total_premium => 100,
      :total_employer_contribution => 20,
      :total_employee_cost => 30,
      :id => "1234234234",
      :sbc_document => Document.new({title: 'sbc_file_name', subject: "SBC",
                      :identifier=>"urn:openhbx:terms:v1:file_storage:s3:bucket:#{Settings.site.s3_prefix}-enroll-sbc-#{aws_env}#7816ce0f-a138-42d5-89c5-25c5a3408b82"})
    ) }


    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id)}
    #let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:hbx_enrollment) {instance_double("HbxEnrollment", plan: plan, id: "12345", total_premium: 200, kind: 'individual',
                                 subscriber: nil,
                                 covered_members_first_names: ["name"], can_complete_shopping?: false,
                                 enroll_step: 2, coverage_terminated?: false,
                                 may_terminate_coverage?: true, effective_on: Date.new(2015,8,10), consumer_role: nil, census_employee: census_employee,
                                 employee_role: employee_role, status_step: 2, applied_aptc_amount: 23.00, aasm_state: 'coverage_selected')}

    let(:benefit_group) { FactoryGirl.create(:benefit_group) }

    before :each do
      allow(hbx_enrollment).to receive(:is_special_enrollment?).and_return(false)
      allow(hbx_enrollment).to receive(:coverage_terminated?).and_return(false)
      allow(hbx_enrollment).to receive(:coverage_expired?).and_return(false)
      allow(hbx_enrollment).to receive(:is_coverage_waived?).and_return(false)
      allow(hbx_enrollment).to receive(:coverage_canceled?).and_return(false)
      allow(hbx_enrollment).to receive(:coverage_year).and_return(plan.active_year)
      allow(hbx_enrollment).to receive(:created_at).and_return(plan.created_at)
      allow(hbx_enrollment).to receive(:hbx_id).and_return(true)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(hbx_enrollment).to receive(:consumer_role_id).and_return(false)
      allow(census_employee.employee_role).to receive(:is_under_open_enrollment?).and_return(true)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      allow(hbx_enrollment).to receive(:coverage_termination_pending?).and_return(true)
      allow(hbx_enrollment).to receive(:future_enrollment_termination_date).and_return(TimeKeeper.date_of_record)
      allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
    end
    it "should open the sbc pdf" do
      expect(rendered).to have_selector("a[href='#{"http://test.host/document/download/#{Settings.site.s3_prefix}-enroll-sbc-qa/7816ce0f-a138-42d5-89c5-25c5a3408b82?content_type=application/pdf&filename=APlanName.pdf&disposition=inline"}']")
    end

    it "should display the title" do
      expect(rendered).to match /#{plan.active_year} #{plan.coverage_kind} Coverage/
      expect(rendered).to match /#{Settings.site.short_name}/
    end

    it "should display the link of view detail" do
      expect(rendered).to have_selector("a[href='/products/plans/summary?active_year=#{plan.active_year}&hbx_enrollment_id=#{hbx_enrollment.id}&source=account&standard_component_id=#{plan.hios_id}']", text: "View Details")
    end

    it "should display the plan start" do
      expect(rendered).to have_selector('strong', text: 'Plan Start:')
      expect(rendered).to match /#{Date.new(2015,8,10)}/
    end


    it "should not disable the Make Changes button" do
      expect(rendered).to_not have_selector('.cna')
    end

    context "when outside Employers open enrollment period but new hire" do
      before :each do
        allow(census_employee.employee_role).to receive(:is_under_open_enrollment?).and_return(false)
        render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
      end

      it "should disable the Make Changes button" do
        expect(rendered).to_not have_selector('.cna')
      end

    end

    context "when outside Employers open enrollment period and not a new hire" do
      let(:employer_profile) { FactoryGirl.create(:employer_profile) }
      before :each do
        allow(census_employee.employee_role).to receive(:is_under_open_enrollment?).and_return(false)
        allow(census_employee).to receive(:new_hire_enrollment_period).and_return(TimeKeeper.datetime_of_record - 20.days .. TimeKeeper.datetime_of_record - 10.days)
        allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
        allow(hbx_enrollment).to receive(:employer_profile).and_return(employer_profile)
        allow(hbx_enrollment).to receive(:total_employee_cost).and_return(111)
        allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(false)
        render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
      end

      it "should disable the Make Changes button" do
        expect(rendered).to have_selector('.cna')
      end

    end

    context "when under a special enrollment but hbx_enrollment is missing a special_enrollment_period id" do
      before :each do
        allow(hbx_enrollment).to receive(:is_special_enrollment?).and_return(true)
        render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
      end
      it "should not disable the Make Changes button" do
        expect(rendered).to_not have_selector('.cna')
      end
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

    it "should display future_enrollment_termination_date when coverage_termination_pending" do
      expect(rendered).to match /Future enrollment termination date:/
    end

    it "should not show a Plan End if cobra" do
      allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(true)
      expect(rendered).not_to match /plan ending/i
    end
  end

  context "with consumer_role", dbclean: :before_each do
    let(:plan) {FactoryGirl.build(:plan, :created_at =>  TimeKeeper.date_of_record)}
    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id)}
    let(:hbx_enrollment) {instance_double("HbxEnrollment", plan: plan, id: "12345", total_premium: 200, kind: 'individual',
                                 covered_members_first_names: ["name"], can_complete_shopping?: false,
                                 enroll_step: 1, subscriber: nil, coverage_terminated?: false,
                                 may_terminate_coverage?: true, effective_on: Date.new(2015,8,10),
                                 consumer_role: double, applied_aptc_amount: 100, employee_role: employee_role, census_employee: census_employee,
                                 status_step: 2, aasm_state: 'coverage_selected')}
   let(:benefit_group) { FactoryGirl.create(:benefit_group) }

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

  context "about covered_members_first_names of hbx_enrollment" do
    let(:plan) {FactoryGirl.build(:plan, :created_at => TimeKeeper.date_of_record)}
    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id)}
    let(:hbx_enrollment) {double(plan: plan, id: "12345", total_premium: 200, kind: 'individual',
                                 covered_members_first_names: [], can_complete_shopping?: false,
                                 enroll_step: 1, subscriber: nil, coverage_terminated?: false,
                                 may_terminate_coverage?: true, effective_on: Date.new(2015,8,10),
                                 consumer_role: double, applied_aptc_amount: 100, employee_role: employee_role, census_employee: census_employee,
                                 status_step: 2, aasm_state: 'coverage_selected')}
    let(:benefit_group) { FactoryGirl.create(:benefit_group) }

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
  end

  context "when the enrollment is coverage_terminated" do
    let(:plan) {FactoryGirl.create(:plan)}
    let!(:person) { FactoryGirl.create(:person, last_name: 'John', first_name: 'Doe') }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, :person => person) }

    let!(:enrollment) {
      FactoryGirl.create(:hbx_enrollment,
                       household: family.active_household,
                       coverage_kind: "health",
                       effective_on: TimeKeeper.date_of_record.beginning_of_month,
                       enrollment_kind: "open_enrollment",
                       kind: "individual",
                       submitted_at: TimeKeeper.date_of_record.prev_month,
                       aasm_state: 'coverage_terminated',
                       plan_id: plan.id
    )}

    before :each do
      render partial: "insured/families/enrollment", collection: [enrollment], as: :hbx_enrollment, locals: { read_only: false }
    end

    it "should not display status as Coverage Terminated" do
      expect(rendered).not_to have_text(/Coverage Terminated/)
    end

    it "should display as Terminated" do
      expect(rendered).to have_text(/Terminated/)
    end
  end

  context "when the enrollment is coverage_expired" do
    let(:plan) {FactoryGirl.create(:plan)}
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile, :last_years_coverage_period) }
    let(:start_on) { TimeKeeper.date_of_record.beginning_of_month.prev_year }
    let(:end_on) { TimeKeeper.date_of_record.prev_year.end_of_year }
    let(:person) { FactoryGirl.create(:person, last_name: 'John', first_name: 'Doe') }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, :person => person) }

    let(:enrollment) {
      FactoryGirl.create(:hbx_enrollment,
                       household: family.active_household,
                       coverage_kind: "health",
                       effective_on: start_on,
                       enrollment_kind: "open_enrollment",
                       kind: "individual",
                       submitted_at: TimeKeeper.date_of_record.prev_month,
                       aasm_state: 'coverage_expired',
                       plan_id: plan.id
    )}

    before :each do
      DatabaseCleaner.clean
      hbx_profile.save!
      family.save!
      enrollment.save!
      render partial: "insured/families/enrollment", collection: [enrollment], as: :hbx_enrollment, locals: { read_only: false }
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
    let(:employer_profile) { FactoryGirl.build_stubbed(:employer_profile) }
    let(:enrollment) { double("enrollment", aasm_state: "inactive", coverage_kind: "health", is_shop?: true,
                        employer_profile: employer_profile, effective_on: TimeKeeper.date_of_record - 1.month,
                        submitted_at: TimeKeeper.date_of_record - 1.month, waiver_reason: nil, id: nil) }

    context "it should render waived_coverage_widget " do

      before :each do
        allow(enrollment).to receive(:is_coverage_waived?).and_return true
        allow(view).to receive(:disable_make_changes_button?).with(enrollment).and_return true
        render partial: "insured/families/enrollment", collection: [enrollment], as: :hbx_enrollment, locals: { read_only: false }
      end

      it "should render waiver template with read_only param as true" do
        expect(response).to render_template(partial: "insured/families/waived_coverage_widget", locals: {read_only: true, hbx_enrollment: enrollment})
      end

      it "should display waiver text" do
        expect(rendered).to have_text(/You have selected to waive your employer health coverage/)
      end
    end

    context "it should render waived_coverage_widget with read_only param value as helper method result" do

      before :each do
        allow(enrollment).to receive(:is_coverage_waived?).and_return true
        allow(view).to receive(:disable_make_changes_button?).with(enrollment).and_return false
        render partial: "insured/families/enrollment", collection: [enrollment], as: :hbx_enrollment, locals: { read_only: false }
      end

      it "should render waiver template with read_only param" do
        expect(response).to render_template(partial: "insured/families/waived_coverage_widget", locals: {read_only: view.disable_make_changes_button?(enrollment), hbx_enrollment: enrollment})
      end
    end
  end
end
