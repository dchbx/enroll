require 'rails_helper'

describe 'ModelEvents::GenerateInitialEmployerInvoice', dbclean: :after_each do

  let(:model_event) { "generate_initial_employer_invoice" }
  let(:notice_event) { "generate_initial_employer_invoice" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let!(:model_instance){ create :employer_profile}
  let!(:plan_year) { build(:plan_year, employer_profile: model_instance, start_on: start_on, aasm_state: 'enrolled') }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year) }

  describe "ModelEvent" do
    context "when initial invoice is generated" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:employer_profile_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :generate_initial_employer_invoice, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.trigger_model_event(:generate_initial_employer_invoice)
      end
    end
  end

  describe "NoticeTrigger" do
    context "when initial invoice is generated" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:generate_initial_employer_invoice, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.generate_initial_employer_invoice"
          expect(payload[:employer_id]).to eq model_instance.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq plan_year.id.to_s
        end
        subject.employer_profile_update(model_event)
      end
    end
  end
end
