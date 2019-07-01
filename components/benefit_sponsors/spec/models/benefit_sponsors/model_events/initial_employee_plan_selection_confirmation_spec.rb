require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::InitialEmployeePlanSelectionConfirmation', dbclean: :around_each  do
  let(:model_event)  { "initial_employee_plan_selection_confirmation" }
  let!(:start_on) { TimeKeeper.date_of_record.beginning_of_month }
  let(:current_effective_date)  { TimeKeeper.date_of_record }

  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
  let!(:organization_with_hbx_profile)  { site.owner_organization }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application,
                              :with_benefit_package,
                              :benefit_sponsorship => benefit_sponsorship,
                              :aasm_state => :enrollment_closed,
                              :effective_period =>  start_on..(start_on + 1.year) - 1.day
  )}
  let!(:benefit_package)  {benefit_application.benefit_packages.first}
  let(:person)       { FactoryBot.create(:person, :with_family) }
  let(:family)       { person.primary_family }
  let!(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile, active_benefit_group_assignment: benefit_package.id ) }
  let(:employee_role)     { FactoryBot.create(:benefit_sponsors_employee_role, employer_profile: employer_profile, person: person, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: employer_profile.id) }
  let!(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }

  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product, 
                        household: family.active_household, 
                        family: family,
                        aasm_state: "coverage_selected",
                        effective_on: benefit_application.start_on,
                        rating_area_id: benefit_application.recorded_rating_area_id,
                        sponsored_benefit_id: benefit_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id:benefit_application.benefit_packages.first.id,
                        benefit_sponsorship_id:benefit_application.benefit_sponsorship.id, 
                        employee_role_id: employee_role.id,
  )}

  before do
    census_employee.update_attributes(employee_role_id: employee_role.id)
    benefit_group_assignment.update_attributes!(hbx_enrollment_id: hbx_enrollment.id, benefit_package_id: benefit_package.id)
  end

  describe "Plan selection confirmation when ER made binder payment" do
    context "ModelEvent" do
      it "should set to true after transition" do
        benefit_application.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
          expect(observer).to receive(:process_application_events) do |_model_instance, model_event|
            expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :initial_employee_plan_selection_confirmation, :klass_instance => benefit_application, :options => {})
          end
        end
        benefit_application.credit_binder!
      end
    end

    context "NoticeTrigger" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:initial_employee_plan_selection_confirmation, benefit_application, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.initial_employee_plan_selection_confirmation"
          expect(payload[:event_object_kind]).to eq 'CensusEmployee'
          expect(payload[:event_object_id]).to eq census_employee.id.to_s
        end
        subject.process_application_events(benefit_application, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.enrollment.coverage_start_on",
        "employee_profile.enrollment.plan_name",
        "employee_profile.enrollment.employee_responsible_amount",
        "employee_profile.enrollment.employer_responsible_amount",
      ]
    }
    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "CensusEmployee",
        "event_object_id" => census_employee.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient, event_name: "initial_employee_plan_selection_confirmation") }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employee_role)
      allow(subject).to receive(:payload).and_return(payload)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice_date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer_name" do
      expect(merge_model.employer_name).to eq employer_profile.legal_name
    end

    it "should return enrollment effective date " do
      expect(merge_model.enrollment.coverage_start_on).to eq hbx_enrollment.effective_on.strftime('%m/%d/%Y')
    end

    it "should return plan_name " do
      expect(merge_model.enrollment.plan_name).to eq hbx_enrollment.product.name
    end

    it "should return employee_responsible_amount" do
      expect(merge_model.enrollment.employer_responsible_amount.to_f).to eq hbx_enrollment.total_employee_cost
    end

    it "should return employer_responsible_amount" do
      expect(merge_model.enrollment.employer_responsible_amount.to_f).to eq hbx_enrollment.total_employer_contribution
    end
  end
end
