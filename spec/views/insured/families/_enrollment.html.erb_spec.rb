require 'rails_helper'

RSpec.describe "insured/families/_enrollment.html.erb" do
  let(:person) { double(id: '31111113') }
  let(:family) { double(is_eligible_to_enroll?: true, updateable?: true, list_enrollments?: true) }

  before(:each) do
    allow(view).to receive(:policy_helper).and_return(family)
    @family = family
    @person = person
  end

  context "without consumer_role" do
    let(:mock_organization){ instance_double("Oganization", hbx_id: "3241251524", legal_name: "ACME Agency", dba: "Acme", fein: "034267010")}
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
                      :identifier=>'urn:openhbx:terms:v1:file_storage:s3:bucket:dchbx-enroll-sbc-local#7816ce0f-a138-42d5-89c5-25c5a3408b82'})
    ) }

    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id)}
    #let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:hbx_enrollment) {double(plan: plan, id: "12345", total_premium: 200, kind: 'individual',
                                 subscriber: nil,
                                 covered_members_first_names: ["name"], can_complete_shopping?: false,
                                 enroll_step: 2, coverage_terminated?: false,
                                 may_terminate_coverage?: true, effective_on: Date.new(2015,8,10), consumer_role: nil, census_employee: census_employee,
                                 employee_role: employee_role, status_step: 2, applied_aptc_amount: 23.00, aasm_state: 'coverage_selected')}

    let(:benefit_group) { FactoryGirl.create(:benefit_group) }

    before :each do
      allow(hbx_enrollment).to receive(:coverage_terminated?).and_return(false)
      allow(hbx_enrollment).to receive(:coverage_canceled?).and_return(false)
      allow(hbx_enrollment).to receive(:coverage_year).and_return(plan.active_year)
      allow(hbx_enrollment).to receive(:created_at).and_return(plan.created_at)
      allow(hbx_enrollment).to receive(:hbx_id).and_return(true)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(hbx_enrollment).to receive(:consumer_role_id).and_return(false)
      allow(census_employee.employee_role).to receive(:is_under_open_enrollment?).and_return(true)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
    end
    it "should open the sbc pdf" do
      expect(rendered).to have_selector("a[href='#{root_path + "document/download/dchbx-enroll-sbc-local/7816ce0f-a138-42d5-89c5-25c5a3408b82?content_type=application/pdf&filename=APlanName.pdf&disposition=inline"}']")
    end

    it "should display the title" do
      expect(rendered).to match /#{plan.active_year} #{plan.coverage_kind} Coverage/
      expect(rendered).to match /#{Settings.site.short_name}/
    end

    it "should display the link of view detail" do
      expect(rendered).to have_selector("a[href='/products/plans/summary?active_year=#{plan.active_year}&hbx_enrollment_id=#{hbx_enrollment.id}&source=account&standard_component_id=#{plan.hios_id}']", text: "View Details")
    end

    it "should display the effective date" do
      expect(rendered).to have_selector('strong', text: 'Effective date:')
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
      before :each do
        allow(hbx_enrollment).to receive(:is_special_enrollment?).and_return(false)
        allow(census_employee.employee_role).to receive(:is_under_open_enrollment?).and_return(false)
        allow(census_employee).to receive(:new_hire_enrollment_period).and_return(TimeKeeper.datetime_of_record - 20.days .. TimeKeeper.datetime_of_record - 10.days)

        render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
      end

      it "should disable the Make Changes button" do
        expect(rendered).to have_selector('.cna')
      end

    end

    context "when under a special enrollment but hbx_enrollment is missing a special_enrollment_period id" do
      before :each do
        allow(hbx_enrollment).to receive(:is_special_enrollment?).and_return(true)
        allow(hbx_enrollment).to receive(:special_enrollment_period?).and_return(nil)
        render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
      end
      it "should not disable the Make Changes button" do
        expect(rendered).to_not have_selector('.cna')
      end
    end

    it "should display the effective date" do
      expect(rendered).to have_selector('strong', text: 'Effective date:')
      expect(rendered).to match /#{Date.new(2015,8,10)}/
    end

    it "should display effective date when terminated enrollment" do
      allow(hbx_enrollment).to receive(:coverage_terminated?).and_return(true)
      expect(rendered).to match /effective date/i
    end

  end

  context "with consumer_role" do
    let(:plan) {FactoryGirl.build(:plan, :created_at =>  TimeKeeper.date_of_record)}
    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id)}
    let(:hbx_enrollment) {double(plan: plan, id: "12345", total_premium: 200, kind: 'individual',
                                 covered_members_first_names: ["name"], can_complete_shopping?: false,
                                 enroll_step: 1, subscriber: nil, coverage_terminated?: false,
                                 may_terminate_coverage?: true, effective_on: Date.new(2015,8,10),
                                 consumer_role: double, applied_aptc_amount: 100, employee_role: employee_role, census_employee: census_employee,
                                 status_step: 2, aasm_state: 'coverage_selected')}
   let(:benefit_group) { FactoryGirl.create(:benefit_group) }

    before :each do
      allow(hbx_enrollment).to receive(:coverage_canceled?).and_return(false)
      allow(hbx_enrollment).to receive(:coverage_year).and_return(plan.active_year)
      allow(hbx_enrollment).to receive(:created_at).and_return(plan.created_at)
      allow(hbx_enrollment).to receive(:hbx_id).and_return(true)
      allow(hbx_enrollment).to receive(:in_time_zone).and_return(true)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(hbx_enrollment).to receive(:consumer_role_id).and_return(person.id)
      allow(census_employee.employee_role).to receive(:is_under_open_enrollment?).and_return(true)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
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
      allow(hbx_enrollment).to receive(:coverage_year).and_return(plan.active_year)
      allow(hbx_enrollment).to receive(:created_at).and_return(plan.created_at)
      allow(hbx_enrollment).to receive(:hbx_id).and_return(true)
      allow(hbx_enrollment).to receive(:in_time_zone).and_return(true)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(hbx_enrollment).to receive(:consumer_role_id).and_return(person.id)
      allow(census_employee.employee_role).to receive(:is_under_open_enrollment?).and_return(true)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment, locals: { read_only: false }
    end

    it "should not disable the Make Changes button" do
      expect(rendered).to_not have_selector('.cna')
    end

  end
end
