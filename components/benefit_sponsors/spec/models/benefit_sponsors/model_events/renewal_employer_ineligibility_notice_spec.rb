require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::RenewalEmployerIneligibilityNotice', dbclean: :after_each do

  let(:model_event) { "application_denied" }
  let(:notice_event) { "renewal_employer_ineligibility_notice" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:model_instance) { FactoryBot.create(:benefit_sponsors_benefit_application,
    :with_benefit_package,
    :benefit_sponsorship => benefit_sponsorship,
    :aasm_state => 'enrollment_closed'
  )}
  let!(:person){ FactoryBot.create(:person, :with_family)}
  let!(:family) {person.primary_family}
  let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: employer_profile, census_employee_id: census_employee.id)}
  let!(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile ) }


  before do
    allow(model_instance).to receive(:is_renewing?).and_return(true)
    census_employee.update_attributes(:employee_role_id => employee_role.id )
  end

  describe "ModelEvent" do
    context "when initial employer application is denied" do
      it "should trigger model event" do
        model_instance.class.observer_peers.keys.select { |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
          expect(observer).to receive(:process_application_events) do |_model_instance, model_event|
            expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :application_denied, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.deny_enrollment_eligiblity!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when initial application denied" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }

      let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(:application_denied, model_instance, {}) }

      it "should trigger model event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.renewal_employer_ineligibility_notice"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_renewal_employer_ineligibility_notice"
          expect(payload[:employee_role_id]).to eq census_employee.employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.process_application_events(model_instance,model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
          "employer_profile.notice_date",
          "employer_profile.employer_name",
          "employer_profile.benefit_application.renewal_py_start_date",
          "employer_profile.benefit_application.current_py_end_date",
          "employer_profile.benefit_application.renewal_py_oe_end_date",
          "employer_profile.benefit_application.enrollment_errors",
          "employer_profile.broker_present?"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let(:payload)   { {
        "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication",
        "event_object_id" => model_instance.id
    } }
    let(:merge_model) { subject.construct_notice_object }

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.deny_enrollment_eligiblity!
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return notice date" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

       it "should return renewal plan_year open_enrollment_end_date" do
        expect(merge_model.benefit_application.renewal_py_oe_end_date).to eq model_instance.open_enrollment_end_on.strftime('%m/%d/%Y')
      end

      it "should return plan year start date" do
        expect(merge_model.benefit_application.renewal_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should return broker status" do
        expect(merge_model.broker_present?).to be_falsey
      end

      it "should return enrollment errors" do
        enrollment_errors = []
      enrollment_policy = BenefitSponsors::BenefitApplications::AcaShopEnrollmentEligibilityPolicy.new
        policy = enrollment_policy.business_policies_for(model_instance, :end_open_enrollment)
        unless policy.is_satisfied?(model_instance)
          policy.fail_results.each do |k, _|
            case k.to_s
            when 'minimum_eligible_member_count'
              enrollment_errors << 'at least one employee must be eligible to enroll'
            when 'non_business_owner_enrollment_count'
              enrollment_errors << "at least #{Settings.aca.shop_market.non_owner_participation_count_minimum} non-owner employee must enroll"
            when 'minimum_participation_rule'
              unless model_instance.effective_date.yday == 1
                enrollment_errors << "number of eligible participants enrolling (#{model_instance.all_enrolled_and_waived_member_count}) is less than minimum required #{model_instance.minimum_enrolled_count}"
              end
            end
          end
        end
        expect(merge_model.benefit_application.enrollment_errors).to eq (enrollment_errors.join(' AND/OR '))
      end
    end
  end
end
