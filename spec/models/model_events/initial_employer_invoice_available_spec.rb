require 'rails_helper'

describe 'ModelEvents::InitialEmployerInvoiceAvailable', dbclean: :after_each do

  let(:model_event) { "initial_employer_invoice_available" }
  let(:notice_event) { "initial_employer_invoice_available" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let!(:employer_profile) {FactoryGirl.create(:employer_profile)}
  let!(:organization) { FactoryGirl.create(:organization, employer_profile: employer_profile) }
  let(:model_instance) {Document.new({ title: "file_name_1", 
    date: TimeKeeper.date_of_record, 
    creator: "hbx_staff", 
    subject: "initial_invoice", 
    identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:#bucket_name#key",
    format: "file_content_type" })}
  let!(:plan_year) { build(:plan_year, employer_profile: employer_profile, start_on: start_on, aasm_state: 'enrolled') }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year) }

  before do
    organization.employer_profile.documents << model_instance
  end

  describe "ModelEvent" do
    context "when initial invoice is generated" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:document_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :initial_employer_invoice_available, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.save!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when initial invoice is generated" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:initial_employer_invoice_available, model_instance, {}) }
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.initial_employer_invoice_available"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq plan_year.id.to_s
        end
        subject.document_update(model_event)
      end
    end
  end
end