require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::InitialEmployerInvoiceAvailable', dbclean: :after_each do

  let(:model_event) { "initial_employer_invoice_available" }
  let(:notice_event) { "initial_employer_invoice_available" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application,
    :with_benefit_package,
    :benefit_sponsorship => benefit_sponsorship,
    :aasm_state => 'enrollment_eligible',
    :effective_period =>  start_on..(start_on + 1.year) - 1.day
  )}

  let(:model_instance) {BenefitSponsors::Documents::Document.new({ title: "file_name_1", 
    date: TimeKeeper.date_of_record, 
    creator: "hbx_staff", 
    subject: "initial_invoice", 
    identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:#bucket_name#key",
    format: "file_content_type" 
  })}

  describe "ModelEvent" do
    context "when initial invoice is generated" do
      it "should trigger model event" do
        model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
          expect(observer).to receive(:process_document_events) do |_instance, model_event|
            expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :initial_employer_invoice_available, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.save!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when initial invoice is generated" do
      subject { BenefitSponsors::Observers::NoticeObserver.new}
      let!(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:initial_employer_invoice_available, model_instance, {}) }
      before do
        organization.employer_profile.documents << model_instance
      end

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.initial_employer_invoice_available"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq benefit_application.id.to_s
        end
        subject.process_document_events(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.benefit_application.binder_payment_due_date",
        "employer_profile.broker.primary_fullname",
        "employer_profile.broker.organization",
        "employer_profile.broker.phone",
        "employer_profile.broker.email",
        "employer_profile.broker_present?"
      ]
    }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let(:payload)   { {
        "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication",
        "event_object_id" => benefit_application.id
    } }

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
        organization.employer_profile.documents << model_instance
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

      it "should return plan year start date" do
        schedular = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
        expect(merge_model.benefit_application.binder_payment_due_date).to eq ((schedular.map_binder_payment_due_date_by_start_on(false, benefit_application.start_on)).strftime("%m/%d/%Y"))
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end
