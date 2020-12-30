require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::GenerateInitialEmployerInvoice', dbclean: :after_each do

  let(:model_event) { "generate_initial_employer_invoice" }
  let(:notice_event) { "generate_initial_employer_invoice" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
  let!(:model_instance)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { model_instance.add_benefit_sponsorship }
  let!(:benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application,
    :with_benefit_package,
    :benefit_sponsorship => benefit_sponsorship,
    :aasm_state => 'enrollment_eligible',
    :effective_period =>  start_on..(start_on + 1.year) - 1.day
  )}

  describe "ModelEvent" do
    it "should trigger model event" do
      model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
        expect(observer).to receive(:process_employer_profile_events) do |_instance, model_event|
          expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
          expect(model_event).to have_attributes(:event_key => :generate_initial_employer_invoice, :klass_instance => model_instance, :options => {})
        end
      end
      model_instance.trigger_model_event(:generate_initial_employer_invoice)
    end
  end

  describe "NoticeTrigger" do
    context "when initial invoice is generated" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:generate_initial_employer_invoice, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.generate_initial_employer_invoice"
          expect(payload[:employer_id]).to eq model_instance.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq benefit_application.id.to_s
        end
        subject.process_employer_profile_events(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.account_number",
        "employer_profile.invoice_number",
        "employer_profile.invoice_date",
        "employer_profile.coverage_month",
        "employer_profile.date_due"
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
        allow(subject).to receive(:resource).and_return(model_instance)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.trigger_model_event(:generate_initial_employer_invoice)
      end

      it "should retrun merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should retrun account number" do
        expect(merge_model.account_number).to eq (model_instance.organization.hbx_id)
      end

      it "should retrun invoice number" do
        expect(merge_model.invoice_number).to eq (model_instance.organization.hbx_id+DateTime.now.next_month.strftime('%m%Y'))
      end

      it "should retrun invoice date" do
        expect(merge_model.invoice_date).to eq (TimeKeeper.date_of_record.strftime("%m/%d/%Y"))
      end

      it "should retrun coverage month" do
        expect(merge_model.coverage_month).to eq (TimeKeeper.date_of_record.next_month.strftime("%m/%Y"))
      end

      it "should retrun due date" do
        schedular = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
        expect(merge_model.date_due).to eq (schedular.calculate_open_enrollment_date(benefit_application.is_renewing? ,TimeKeeper.date_of_record.next_month.beginning_of_month)[:binder_payment_due_date].strftime("%m/%d/%Y"))
      end
    end
  end
end
