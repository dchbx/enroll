# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"

RSpec.describe 'ModelEvents::EmployeeSepRequestDeniedNotice', :dbclean => :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:person){ FactoryBot.create(:person, :with_family)}
  let(:family) {person.primary_family}
  let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id)}
  let(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile) }
  let(:qle) { FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: 'shop') }
  let(:notice_event1) {'sep_denial_notice_for_ee_active_on_single_roster'}
  let(:notice_event2) {'sep_denial_notice_for_ee_active_on_multiple_rosters'}

  before do
    today = TimeKeeper.date_of_record.strftime("%m/%d/%Y")
    @qle_date = TimeKeeper.date_of_record.next_month.strftime("%m/%d/%Y")
    @reporting_deadline = @qle_date > today ? today : @qle_date + 30.days
    census_employee.update_attributes(employee_role_id: employee_role.id)
  end

  describe "NoticeTrigger when employee is active on single roster" do
    context "when employee sep is denied" do
      subject { BenefitSponsors::Services::NoticeService.new }

      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.#{notice_event1}"
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq initial_application.id.to_s
        end
        subject.deliver(recipient: employee_role, event_object: initial_application, notice_event: notice_event1, notice_params: {:qle_title => qle.title, :qle_reporting_deadline => @reporting_deadline, :qle_event_on => @qle_date})
      end
    end
  end

  describe "NoticeTrigger when employee is active on single roster" do
    context "when employee sep is denied" do
      let(:employee_role2) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id)}
      subject { BenefitSponsors::Services::NoticeService.new }

      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.#{notice_event2}"
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq initial_application.id.to_s
        end
        subject.deliver(recipient: employee_role2, event_object: initial_application, notice_event: notice_event2, notice_params: {:qle_title => qle.title, :qle_reporting_deadline => @reporting_deadline, :qle_event_on => @qle_date})
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
        "employee_profile.broker_present?",
        'employee_profile.benefit_application.current_py_start_date_plus_one_year',
        "employee_profile.special_enrollment_period.title",
        "employee_profile.special_enrollment_period.reporting_deadline",
        "employee_profile.special_enrollment_period.event_on",
        "employee_profile.special_enrollment_period.qle_reported_on"
      ]
    end

    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload) do
      { "event_object_kind" => 'BenefitSponsors::BenefitApplications::BenefitApplication',
        "event_object_id" => initial_application.id,
        "notice_params" => {"qle_title" => qle.title,
                            "qle_reporting_deadline" => @reporting_deadline,
                            "qle_event_on" => @qle_date} }
    end
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }

    before do
      allow(subject).to receive(:resource).and_return(employee_role)
      allow(subject).to receive(:payload).and_return(payload)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
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

    it "should return next effective plan year start date" do
      expect(merge_model.benefit_application.current_py_start_date_plus_one_year).to eq initial_application.start_on.next_year.strftime('%m/%d/%Y')
    end

    context "with QLE data_elements" do
      it "should return qle_title" do
        expect(merge_model.special_enrollment_period.title).to eq qle.title
      end

      it "should return qle_reporting_deadline" do
        expect(merge_model.special_enrollment_period.reporting_deadline).to eq @reporting_deadline
      end

      it "should return event_on" do
        expect(merge_model.special_enrollment_period.event_on).to eq @qle_date
      end

      it "should return qle_reported_on" do
        expect(merge_model.special_enrollment_period.qle_reported_on).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it 'should return true if event date is in future' do
        expect(merge_model.future_sep?).to be_truthy
      end

      context 'with valid/past event on date' do

        let(:payload) do
          { "event_object_kind" => 'BenefitSponsors::BenefitApplications::BenefitApplication',
            "event_object_id" => initial_application.id,
            "notice_params" => {"qle_title" => qle.title,
                                "qle_reporting_deadline" => @reporting_deadline,
                                "qle_event_on" => TimeKeeper.date_of_record.prev_day.strftime("%m/%d/%Y")} }
        end

        it 'should return false' do
          expect(merge_model.future_sep?).to be_falsey
        end
      end
    end
  end
end