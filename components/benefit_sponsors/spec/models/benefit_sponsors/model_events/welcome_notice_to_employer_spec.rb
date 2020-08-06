# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::WelcomeNoticeToEmployer', dbclean: :around_each  do
  let(:notice_event)  { "welcome_notice_to_employer" }
  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
  let!(:model_instance)     { FactoryBot.build(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
  let(:employer_profile)    { model_instance.employer_profile }
  let(:person){ create :person}

  describe "when ER successfully creates account" do
    context "ModelEvent" do
      it "should trigger model event" do
        model_instance.class.observer_peers.keys.select { |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
          expect(observer).to receive(:process_organization_events) do |model_instance, model_event|
            expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :welcome_notice_to_employer, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.save!
      end
    end

    context "NoticeTrigger" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:welcome_notice_to_employer, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.welcome_notice_to_employer"
          expect(payload[:event_object_kind]).to eq "BenefitSponsors::Organizations::AcaShop#{Settings.site.key.capitalize}EmployerProfile"
          expect(payload[:event_object_id]).to eq employer_profile.id.to_s
        end
        subject.process_organization_events(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) do
      [
          "employer_profile.notice_date",
          "employer_profile.employer_name"
      ]
    end
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload) do
      {
        "event_object_kind" => "BenefitSponsors::Organizations::AcaShop#{Settings.site.key.capitalize}EmployerProfile",
        "event_object_id" => employer_profile.id
      }
    end
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employer_profile)
      allow(subject).to receive(:payload).and_return(payload)
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
  end
end
