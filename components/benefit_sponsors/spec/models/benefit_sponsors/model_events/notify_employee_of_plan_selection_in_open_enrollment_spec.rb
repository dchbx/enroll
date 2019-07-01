require 'rails_helper'

module BenefitSponsors
  RSpec.describe 'ModelEvents::NotifyEmployeeOfPlanSelectionInOpenEnrollment', dbclean: :around_each  do
    let(:current_effective_date)  { TimeKeeper.date_of_record }
    let(:start_on)                { (TimeKeeper.date_of_record - 2.months).beginning_of_month }
    let!(:site)                   { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
    let!(:organization)           { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
    let(:employer_profile)        { organization.employer_profile }
    let(:benefit_sponsorship)     { employer_profile.add_benefit_sponsorship }
    let!(:benefit_application)    { FactoryBot.create(:benefit_sponsors_benefit_application,
                                  :with_benefit_package,
                                  :benefit_sponsorship => benefit_sponsorship,
                                  :aasm_state => 'active',
                                  :effective_period =>  start_on..(start_on + 1.year) - 1.day
    )}
    let(:person)                  { FactoryBot.create(:person, :with_family) }
    let(:family)                  { person.primary_family }
    let!(:census_employee)        { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile, first_name: person.first_name, last_name: person.last_name ) }
    let!(:employee_role)          { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: employer_profile, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: employer_profile.id)}
    let!(:model_instance)         { FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product, 
                                    household: family.active_household, 
                                    family: family,
                                    aasm_state: "shopping",
                                    submitted_at: benefit_application.open_enrollment_period.max,
                                    rating_area_id: benefit_application.recorded_rating_area_id,
                                    sponsored_benefit_id: benefit_application.benefit_packages.first.health_sponsored_benefit.id,
                                    sponsored_benefit_package_id: benefit_application.benefit_packages.first.id,
                                    benefit_sponsorship_id:benefit_application.benefit_sponsorship.id, 
                                    employee_role_id: employee_role.id
    )}

    before do
      employee_role.update_attributes(census_employee_id: census_employee.id)
    end

    describe "when employee selects coverage in Open Enrollment" do
      context "ModelEvent" do
        before do
          allow(model_instance).to receive(:can_select_coverage?).and_return(true)
        end

        it "should trigger model event" do
          model_instance.class.observer_peers.keys.select { |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
            expect(observer).to receive(:process_enrollment_events) do |_model_instance, model_event|
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
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employee.notify_employee_of_plan_selection_in_open_enrollment"
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
          "employee_profile.first_name",
          "employee_profile.last_name",
          "employee_profile.employer_name",
          "employee_profile.enrollment.coverage_end_on",
          "employee_profile.enrollment.coverage_kind",
          "employee_profile.enrollment.plan_name"
        ]
      }

      let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          "event_object_kind" => "HbxEnrollment",
          "event_object_id" => model_instance.id
      } }
      let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
      let(:merge_model) { subject.construct_notice_object }

      before do
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
        employee_role.update_attributes(census_employee_id: census_employee.id) 
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return notice_date" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employee first_name" do
        expect(merge_model.first_name).to eq model_instance.census_employee.first_name
      end

      it "should return employee last_name" do
        expect(merge_model.last_name).to eq model_instance.census_employee.last_name
      end

      it "should return employer legal_name" do
        expect(merge_model.employer_name).to eq model_instance.employer_profile.legal_name
      end

      it "should return enrollment coverage_kind" do
        expect(merge_model.enrollment.coverage_kind).to eq model_instance.coverage_kind
      end

      it "should return plan name" do
        expect(merge_model.enrollment.plan_name).to eq model_instance.product.name
      end
    end
  end
end
