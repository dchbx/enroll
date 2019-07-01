require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe 'BenefitSponsors::ModelEvents::RenewalEmployeeAutoRenewalNotification', dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"

  let(:model_event)  { "employee_coverage_passively_renewed" }
  let(:notice_event) { "employee_coverage_passively_renewed" }
  
  let(:renewal_effective_date)  { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:current_effective_date)  { renewal_effective_date.prev_year }
  let(:employer_profile) { abc_profile }

  let!(:person){ FactoryBot.create(:person, :with_family)}
  let!(:family) {person.primary_family}
  let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: employer_profile, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: employer_profile.id)}
  let!(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile ) }
  let!(:open_enrollment_start_date) { renewal_application.open_enrollment_period.min }
  let!(:hbx_enrollment) {  FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                        household: family.active_household,
                        family: family,
                        aasm_state: "auto_renewing",
                        effective_on: renewal_application.start_on,
                        rating_area_id: renewal_application.recorded_rating_area_id,
                        sponsored_benefit_id: renewal_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id:renewal_application.benefit_packages.first.id,
                        benefit_sponsorship_id:renewal_application.benefit_sponsorship.id,
                        employee_role_id: employee_role.id)
  }

  before do
    census_employee.update_attributes(:employee_role_id => employee_role.id )
  end

  describe "ModelEvent" do
    it "should trigger model event" do
      census_employee.class.observer_peers.keys.select { |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
        expect(observer).to receive(:process_census_employee_events) do |_instance, model_event|
          expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
          expect(model_event).to have_attributes(:event_key => :employee_coverage_passively_renewed, :klass_instance => census_employee, :options => {event_object: renewal_application})
        end
      end
      census_employee.trigger_model_event(:employee_coverage_passively_renewed, {event_object: renewal_application})
    end
  end

  describe "NoticeTrigger" do
    context "when renewal employee auto renewal" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }

      let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:employee_coverage_passively_renewed, census_employee, {event_object:renewal_application}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_coverage_passively_renewed"
          expect(payload[:employee_role_id]).to eq census_employee.employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq renewal_application.id.to_s
        end
        subject.process_census_employee_events(census_employee, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.benefit_application.renewal_py_start_date",
        "employee_profile.benefit_application.renewal_py_oe_start_date",
        "employee_profile.benefit_application.renewal_py_oe_end_date",
        "employee_profile.broker.primary_fullname",
        "employee_profile.broker.organization",
        "employee_profile.broker.phone",
        "employee_profile.broker.email",
        "employee_profile.broker_present?"
      ]
    }

    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let!(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let!(:payload)   { {
      "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication",
      "event_object_id" => renewal_application.id
    } }

    context "when notice event received" do
      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(census_employee.employee_role)
        allow(subject).to receive(:payload).and_return(payload)
        renewal_application.update_attributes(:predecessor_id => predecessor_application.id )
        census_employee.trigger_model_event(:employee_coverage_passively_renewed, {event_object: renewal_application})
      end

      it "should retrun merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it "should return renewal plan year start date" do
        expect(merge_model.benefit_application.renewal_py_start_date).to eq renewal_application.start_on.strftime('%m/%d/%Y')
      end

      it "should return renewal plan year open enrollment start date" do
        expect(merge_model.benefit_application.renewal_py_oe_start_date).to eq renewal_application.open_enrollment_start_on.strftime('%m/%d/%Y')
      end

      it "should return renewal plan year open enrollment end date" do
        expect(merge_model.benefit_application.renewal_py_oe_end_date).to eq renewal_application.open_enrollment_end_on.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end
