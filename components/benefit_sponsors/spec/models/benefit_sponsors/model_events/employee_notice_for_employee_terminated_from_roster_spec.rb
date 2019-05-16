require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::EmployeeTerminationNoticeToEmployee', :dbclean => :after_each do

  let!(:termination_date) {(TimeKeeper.date_of_record)}
  let(:start_on) { (TimeKeeper.date_of_record - 2.months).beginning_of_month }

  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application,
                              :with_benefit_package,
                              :benefit_sponsorship => benefit_sponsorship,
                              :aasm_state => 'active',
                              :effective_period =>  start_on..(start_on + 1.year) - 1.day
  )}
  let!(:benefit_package)  {benefit_application.benefit_packages.first}
  let!(:person)       { FactoryBot.create(:person, :with_family) }
  let!(:family)       { person.primary_family }
  let!(:model_instance)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile, active_benefit_group_assignment: benefit_package.id ) }
  let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: employer_profile, census_employee_id: model_instance.id)}
  let!(:hbx_enrollment) {  FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                        household: family.active_household,
                        aasm_state: "coverage_termination_pending",
                        effective_on: benefit_application.start_on,
                        rating_area_id: benefit_application.recorded_rating_area_id,
                        sponsored_benefit_id: benefit_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id:benefit_application.benefit_packages.first.id,
                        benefit_sponsorship_id:benefit_application.benefit_sponsorship.id,
                        employee_role_id: employee_role.id)
  }

  
  before do
    model_instance.update_attributes(employee_role_id: employee_role.id)
  end

  describe "when employee terminated from the roster" do

    context "ModelEvent" do
      it "should trigger model event" do
        model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
          expect(observer).to receive(:process_census_employee_events) do |_instance, model_event|
            expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :employee_terminated_from_roster, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.terminate_employment(termination_date)
      end
    end

    context "NoticeTrigger" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:employee_terminated_from_roster, model_instance, {}) }
      
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_notice_for_employee_terminated_from_roster"
          expect(payload[:employee_role_id]).to eq model_instance.employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'CensusEmployee'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.process_census_employee_events(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.first_name",
        "employee_profile.last_name",
        "employee_profile.termination_of_employment",
        "employee_profile.broker.primary_fullname",
        "employee_profile.broker.organization",
        "employee_profile.broker.phone",
        "employee_profile.broker.email",
        "employee_profile.broker_present?"
      ]
    }

    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let!(:terminated_employee) do
      ee = model_instance.terminate_employment(termination_date)
      ee.save
      ee
    end

    let(:payload)   { {
        "event_object_kind" => "CensusEmployee",
        "event_object_id" => terminated_employee.id,
        "event_name" => 'employee_matches_employer_rooster'
    } }

    context "when notice event received" do
      before do
        allow(subject).to receive(:resource).and_return(terminated_employee.employee_role)
        allow(subject).to receive(:payload).and_return(payload)
        # model_instance.terminate_employment(termination_date)
        # model_instance.save!
        # binding.pry
      end
      
      it "should retrun merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employee first name" do
        expect(merge_model.first_name).to eq terminated_employee.employee_role.person.first_name
      end

      it "should return employee last name" do
        expect(merge_model.last_name).to eq terminated_employee.employee_role.person.last_name
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq terminated_employee.employer_profile.legal_name
      end

      it "should return termination of employement" do
        expect(merge_model.termination_of_employment).to eq terminated_employee.employment_terminated_on.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end
