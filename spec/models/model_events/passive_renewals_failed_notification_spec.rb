require 'rails_helper'

describe 'ModelEvents::PassiveRenewalsFailedNotification' do

  let(:model_event)  { "employee_coverage_passive_renewal_failed" }
  let(:notice_event) { "employee_coverage_passive_renewal_failed" }
  let(:renewal_year) { (TimeKeeper.date_of_record.end_of_month + 1.day + 2.months).year }

  let!(:renewal_plan) {
    FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: renewal_year, hios_id: "11111111122302-01", csr_variant_id: "01")
  }

  let!(:plan) {
    FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: renewal_year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id)
  }

  let!(:organization) {
    org = FactoryGirl.create :organization, legal_name: "Corp 1"
    employer_profile = FactoryGirl.create :employer_profile, organization: org
    FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop")
    org.reload
  }

  let(:employer_profile) { organization.employer_profile }

  let!(:build_plan_years_and_employees) {
    owner = FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
    employee = FactoryGirl.create :census_employee, employer_profile: employer_profile

    benefit_group = FactoryGirl.create :benefit_group, plan_year: active_plan_year, reference_plan_id: plan.id
    employee.add_benefit_group_assignment benefit_group, benefit_group.start_on

    employee.add_renew_benefit_group_assignment renewal_benefit_group
  }

  let(:open_enrollment_start_on) { TimeKeeper.date_of_record }
  let(:open_enrollment_end_on) { open_enrollment_start_on + 12.days }
  let(:start_on) { (open_enrollment_start_on + 2.months).beginning_of_month }
  let(:end_on) { start_on + 1.year - 1.day }

  let(:active_plan_year) {
    FactoryGirl.create :plan_year, employer_profile: employer_profile, start_on: start_on - 1.year, end_on: end_on - 1.year, open_enrollment_start_on: open_enrollment_start_on - 1.year, open_enrollment_end_on: open_enrollment_end_on - 1.year - 3.days, fte_count: 2, aasm_state: :published
  }

  let(:renewing_plan_year) {
    FactoryGirl.create :plan_year, employer_profile: employer_profile, start_on: start_on, end_on: end_on, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_end_on, fte_count: 2, aasm_state: :renewing_draft
  }

  let(:renewal_benefit_group){
    FactoryGirl.create :benefit_group, plan_year: renewing_plan_year, reference_plan_id: renewal_plan.id
  }
  let!(:model_instance) {
    organization.employer_profile.census_employees.non_business_owner.first
  }

  let!(:new_renewal_plan) {
    FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'silver', active_year: renewal_year, hios_id: "11111111122301-01", csr_variant_id: "01")
  }

  let!(:family) {
    person = FactoryGirl.create(:person, last_name: model_instance.last_name, first_name: model_instance.first_name)
    employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: model_instance, employer_profile: organization.employer_profile)
    model_instance.update_attributes({employee_role: employee_role})
    family_rec = Family.find_or_build_from_employee_role(employee_role)

    FactoryGirl.create(:hbx_enrollment,
      household: person.primary_family.active_household,
      coverage_kind: "health",
      effective_on: model_instance.active_benefit_group_assignment.benefit_group.start_on,
      enrollment_kind: "open_enrollment",
      kind: "employer_sponsored",
      submitted_at: model_instance.active_benefit_group_assignment.benefit_group.start_on - 20.days,
      benefit_group_id: model_instance.active_benefit_group_assignment.benefit_group.id,
      employee_role_id: person.active_employee_roles.first.id,
      benefit_group_assignment_id: model_instance.active_benefit_group_assignment.id,
      plan_id: plan.id
      )

    family_rec.reload
  }

  describe "ModelEvent" do
    context "when passive renewals failed" do

      it "should trigger model event" do
        factory = Factories::FamilyEnrollmentRenewalFactory.new
        factory.family = family
        factory.census_employee = model_instance
        factory.employer = employer_profile
        factory.renewing_plan_year = renewing_plan_year
        allow(factory).to receive(:renewal_plan_offered_by_er?).and_return false
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:census_employee_update) do |model_event_instance|
            expect(model_event_instance).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event_instance).to have_attributes(:event_key => model_event.to_sym, :klass_instance => model_instance, :options => {:event_object => renewing_plan_year})
          end
        end
        factory.renew
      end
    end
  end

  describe "NoticeTrigger" do
    context "when passive renewals failed" do
      subject { Observers::NoticeObserver.new }

      let(:model_event_instance) { ModelEvents::ModelEvent.new(model_event.to_sym, model_instance, {event_object:renewing_plan_year}) }

      it "should trigger notice event" do
        factory = Factories::FamilyEnrollmentRenewalFactory.new
        factory.family = family
        factory.census_employee = model_instance
        factory.employer = employer_profile
        factory.renewing_plan_year = renewing_plan_year
        allow(factory).to receive(:renewal_plan_offered_by_er?).and_return false
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.#{notice_event}"
          expect(payload[:employee_role_id]).to eq model_instance.employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq renewing_plan_year.id.to_s
        end
        subject.census_employee_update(model_event_instance)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.plan_year.renewal_py_start_date",
        "employee_profile.plan_year.renewal_py_submit_soft_due_date",
        "employee_profile.plan_year.renewal_py_oe_end_date",
        "employee_profile.plan_year.current_py_start_on.year",
        "employee_profile.plan_year.renewal_py_start_on.year",
        "employee_profile.broker.primary_fullname",
        "employee_profile.broker.organization",
        "employee_profile.broker.phone",
        "employee_profile.broker.email",
        "employee_profile.broker_present?"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let!(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let!(:payload)   { {
      "event_object_kind" => "PlanYear",
      "event_object_id" => renewing_plan_year.id
    } }

    let!(:soft_dead_line) { Date.new(start_on.prev_month.year, start_on.prev_month.month, Settings.aca.shop_market.renewal_application.application_submission_soft_deadline) }

    context "when notice event received" do
      let(:employer_profile2) { model_instance.employee_role.employer_profile  }

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(model_instance.employee_role)
        allow(subject).to receive(:payload).and_return(payload)
        factory = Factories::FamilyEnrollmentRenewalFactory.new
        factory.family = family
        factory.census_employee = model_instance
        factory.employer = employer_profile
        factory.renewing_plan_year = renewing_plan_year
        factory.renew
      end

      it "should build the data elements for the notice" do
        merge_model = subject.construct_notice_object

        expect(merge_model).to be_a(recipient.constantize)
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
        expect(merge_model.employer_name).to eq employer_profile2.legal_name
        expect(merge_model.plan_year.renewal_py_start_date).to eq employer_profile2.plan_years.renewing.first.start_on.strftime('%m/%d/%Y')
        expect(merge_model.plan_year.renewal_py_submit_soft_due_date).to eq soft_dead_line.strftime('%m/%d/%Y')
        expect(merge_model.plan_year.renewal_py_oe_end_date).to eq employer_profile2.plan_years.renewing.first.open_enrollment_end_on.strftime('%m/%d/%Y')
        expect(merge_model.broker_present?).to be_falsey
        expect(merge_model.plan_year.current_py_start_on).to eq employer_profile2.plan_years.first.start_on
        expect(merge_model.plan_year.renewal_py_start_on).to eq employer_profile2.plan_years.renewing.first.start_on
      end
    end
  end
end
