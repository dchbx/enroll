# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::EmployeeSepRequestAccepted', :dbclean => :after_each do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month - 2.months }
  let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:benefit_application) do
    FactoryBot.create(:benefit_sponsors_benefit_application,
                      :with_benefit_package,
                      :benefit_sponsorship => benefit_sponsorship,
                      :aasm_state => 'active',
                      :effective_period => start_on..(start_on + 1.year) - 1.day)
  end
  let!(:person){ FactoryBot.create(:person, :with_family)}
  let!(:family) {person.primary_family}
  let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: employer_profile, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: employer_profile.id)}
  let!(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile, first_name: person.first_name, last_name: person.last_name) }
  let(:qle) { FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: "shop") }
  let(:model_instance) { FactoryBot.build(:special_enrollment_period, family: family, qualifying_life_event_kind_id: qle.id, title: "Married") }


  describe "ModelEvent" do
    context "when employee sep request accepted" do
      it "should trigger model event" do
        model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
          expect(observer).to receive(:process_special_enrollment_events) do |_instance, model_event|
            expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :employee_sep_request_accepted, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.save!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when employee active on single roster" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let!(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:employee_sep_request_accepted, model_instance, {}) }

      before do
        fm = family.family_members.first
        allow(model_instance).to receive(:family).and_return(family)
        allow(family).to receive(:primary_applicant).and_return(fm)
        allow(fm).to receive(:person).and_return(person)
      end

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.sep_accepted_notice_for_ee_active_on_single_roster"
          expect(payload[:event_object_kind]).to eq 'SpecialEnrollmentPeriod'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.process_special_enrollment_events(model_instance, model_event)
      end
    end

    context "when employee active on multiplr rosters" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let!(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:employee_sep_request_accepted, model_instance, {}) }

      before do
        fm = family.family_members.first
        allow(model_instance).to receive(:family).and_return(family)
        allow(family).to receive(:primary_applicant).and_return(fm)
        allow(fm).to receive(:person).and_return(person)
        allow(person).to receive(:has_multiple_active_employers?).and_return(true)
      end

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.sep_accepted_notice_for_ee_active_on_multiple_rosters"
          expect(payload[:event_object_kind]).to eq 'SpecialEnrollmentPeriod'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.process_special_enrollment_events(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) do
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.first_name",
        "employee_profile.last_name",
        "employee_profile.broker.primary_fullname",
        "employee_profile.broker.organization",
        "employee_profile.broker.phone",
        "employee_profile.broker.email",
        "employee_profile.broker_present?",
        "employee_profile.special_enrollment_period.title",
        "employee_profile.special_enrollment_period.start_on",
        "employee_profile.special_enrollment_period.end_on",
        "employee_profile.special_enrollment_period.qle_reported_on",
        "employee_profile.special_enrollment_period.submitted_at"
      ]
    end

    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   do
      {
        "event_object_kind" => "SpecialEnrollmentPeriod",
        "event_object_id" => model_instance.id
      }
    end
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      model_instance.save!
      allow(subject).to receive(:resource).and_return(employee_role)
      allow(subject).to receive(:payload).and_return(payload)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq census_employee.employer_profile.legal_name
    end

    it "should return employee first name " do
      expect(merge_model.first_name).to eq person.first_name
    end

    it "should return employee last name " do
      expect(merge_model.last_name).to eq person.last_name
    end

    it "should return false when there is no broker linked to employer" do
      expect(merge_model.broker_present?).to be_falsey
    end

    context "with QLE data_elements" do
      it "should return qle_title" do
        expect(merge_model.special_enrollment_period.title).to eq model_instance.title
      end

      it "should return qle_start_on" do
        expect(merge_model.special_enrollment_period.start_on).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should return qle_end_on" do
        expect(merge_model.special_enrollment_period.end_on).to eq model_instance.end_on.strftime('%m/%d/%Y')
      end

      it "should return qle_event_on" do
        expect(merge_model.special_enrollment_period.qle_reported_on).to eq model_instance.qle_on.strftime('%m/%d/%Y')
      end

      it "should return submitted_at" do
        expect(merge_model.special_enrollment_period.submitted_at).to eq model_instance.submitted_at.strftime('%m/%d/%Y')
      end
    end
  end
end
