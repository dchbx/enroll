require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"

RSpec.describe 'BenefitSponsors::ModelEvents::ApplicationCoverageSelected', :dbclean => :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:aasm_state) { "enrollment_eligible" }
  let!(:person){ FactoryBot.create(:person, :with_family)}
  let!(:family) {person.primary_family}
  let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id)}
  let!(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile) }
  let!(:model_instance) { 
    hbx_enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product, 
                        household: family.active_household, 
                        aasm_state: "shopping",
                        effective_on: initial_application.start_on,
                        rating_area_id: initial_application.recorded_rating_area_id,
                        sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
                        benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
                        employee_role_id: employee_role.id) 
    hbx_enrollment.benefit_sponsorship = benefit_sponsorship
    hbx_enrollment.save!
    hbx_enrollment
  }

  describe "when employee plan coverage selected" do
    context "ModelEvent" do
      before do
        allow(model_instance).to receive(:can_select_coverage?).and_return(true)
      end
      it "should trigger model event" do
        model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
          expect(observer).to receive(:process_enrollment_events) do |_instance, model_event|
            expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :application_coverage_selected, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.select_coverage!
      end
    end

    context "NoticeTrigger" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:application_coverage_selected, model_instance, {}) }

      it "should trigger notice event" do
        allow(model_instance).to receive(:is_shop?).and_return(true)
        allow(model_instance).to receive(:enrollment_kind).and_return('special_enrollment')
        allow(model_instance).to receive(:census_employee).and_return(census_employee)
        allow(census_employee).to receive(:employee_role).and_return(employee_role)

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.employee_mid_year_plan_change_notice_to_employer"
          expect(payload[:employer_id]).to eq model_instance.employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_plan_selection_confirmation_sep_new_hire"
          expect(payload[:employee_role_id]).to eq model_instance.employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.process_enrollment_events(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.enrollment.employee_first_name",
        "employee_profile.enrollment.employee_last_name",
        "employee_profile.enrollment.coverage_start_on"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let!(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:merge_model) { subject.construct_notice_object }
    let!(:payload)   { {
      "event_object_kind" => "HbxEnrollment",
      "event_object_id" => model_instance.id
    } }

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(model_instance).to receive(:is_shop?).and_return(true)
        allow(model_instance).to receive(:enrollment_kind).and_return('special_enrollment')
        allow(model_instance).to receive(:census_employee).and_return(census_employee)
        allow(census_employee).to receive(:employee_role).and_return(employee_role)
        allow(subject).to receive(:resource).and_return(model_instance.employee_role)
        allow(subject).to receive(:payload).and_return(payload)
        allow(employee_role).to receive(:person).and_return(person)
        allow(model_instance).to receive(:can_select_coverage?).and_return(true)
        model_instance.select_coverage!
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return notice date" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq model_instance.employer_profile.legal_name
      end

      it "should return employee first_name" do
        expect(merge_model.enrollment.employee_first_name).to eq model_instance.census_employee.first_name
      end

      it "should return employee last_name" do
        expect(merge_model.enrollment.employee_last_name).to eq model_instance.census_employee.last_name
      end

      it "should return enrollment coverage_kind" do
        expect(merge_model.enrollment.coverage_start_on).to eq model_instance.effective_on.strftime('%m/%d/%Y')
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.enrollment.employee_first_name",
        "employer_profile.enrollment.employee_last_name",
        "employer_profile.enrollment.coverage_start_on",
        "employer_profile.broker.primary_fullname",
        "employer_profile.broker.organization",
        "employer_profile.broker.phone",
        "employer_profile.broker_present?"
      ]
    }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "HbxEnrollment",
        "event_object_id" => model_instance.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(abc_profile)
      allow(subject).to receive(:payload).and_return(payload)
      employee_role.update_attributes(census_employee_id: census_employee.id)
      allow(model_instance).to receive(:can_select_coverage?).and_return(true)
      model_instance.select_coverage!
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq abc_profile.legal_name
    end

    it "should return employee first_name" do
      expect(merge_model.enrollment.employee_first_name).to eq model_instance.census_employee.first_name
    end

    it "should return employee last_name" do
      expect(merge_model.enrollment.employee_last_name).to eq model_instance.census_employee.last_name
    end

    it "should return enrollment effective date " do
      expect(merge_model.enrollment.coverage_start_on).to eq model_instance.effective_on.strftime('%m/%d/%Y')
    end
  end
end
