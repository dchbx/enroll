# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"

RSpec.describe 'BenefitSponsors::ModelEvents::OutOfPocketNotice', dbclean: :after_each do
  include_context 'setup benefit market with market catalogs and product packages'
  include_context 'setup initial benefit application'

  let(:notice_event) { 'out_of_pocket_url_notifier' }

  describe "NoticeTrigger" do

    subject { BenefitSponsors::Services::NoticeService.new }

    it "should trigger model event" do
      expect(subject).to receive(:notify) do |event_name, payload|
        expect(event_name).to eq "acapi.info.events.employer.out_of_pocket_url_notifier"
        expect(payload[:event_object_kind]).to eq "BenefitSponsors::Organizations::AcaShop#{Settings.site.key.capitalize}EmployerProfile"
        expect(payload[:event_object_id]).to eq abc_profile.id.to_s
      end
      subject.deliver(recipient: abc_profile, event_object: abc_profile, notice_event: notice_event, notice_params: {})
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) do
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.broker.primary_fullname",
        "employer_profile.broker.organization",
        "employer_profile.broker.phone",
        "employer_profile.broker.email",
        "employer_profile.benefit_application.benefit_packages",
        "employer_profile.broker_present?"
      ]
    end
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let(:payload) do
      {
        "event_object_kind" => "BenefitSponsors::Organizations::AcaShop#{Settings.site.key.capitalize}EmployerProfile",
        "event_object_id" => abc_profile.id.to_s
      }
    end

    let(:benefit_package) { abc_profile.benefit_applications.first.benefit_packages[0] }
    let(:sponsored_benefit) {benefit_package.sponsored_benefits[0]}

    context "when notice event is received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(abc_profile)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should retrun merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq abc_profile.legal_name
      end

      it "should return benefit package information" do
        expect(merge_model.benefit_application.benefit_packages[0].title).to eq benefit_package.title.titleize
      end

      it "should return sponsored benefit information" do
        expect(merge_model.benefit_application.benefit_packages[0].sponsored_benefits[0].plan_offerings_text).to eq "All plans from #{sponsored_benefit.reference_product.issuer_profile.legal_name.titleize}"
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end
