require 'rails_helper'

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe Subscribers::EmployerBenefitRenewalSubscriber, :dbclean => :after_each do

    subject do
      Subscribers::EmployerBenefitRenewalSubscriber.new
    end
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
    let(:benefit_renewal_event) { "acapi.info.events.benefit_sponsorship.execute_benefit_renewal" }
    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
    let(:aasm_state) { :active }
    let(:correlation_id) { "a correlation id" }

    let(:payload) {
      double(:headers => {
        benefit_sponsorship_id: benefit_sponsorship.id.to_s,
        new_date: renewal_effective_date.strftime("%Y-%m-%d")
        },
        :correlation_id => correlation_id)
    }

    context "when benefit sponsorship exists" do
      context "when renewal success" do

        it "should renew and return ack" do
          expect(benefit_sponsorship.renewal_benefit_application).to be_blank
          return_status = subject.work_with_params("", nil, payload)
          benefit_sponsorship.reload
          expect(benefit_sponsorship.renewal_benefit_application).to be_present
          expect(benefit_sponsorship.renewal_benefit_application.predecessor_id).to eq initial_application.id
          expect(return_status).to eq :ack
        end
      end
    end

    context "when benefit sponsorship not found" do
      let(:benefit_sponsorship_id) { BSON::ObjectId.new }
      let(:payload) {
        double(:headers => {
          benefit_sponsorship_id: benefit_sponsorship_id.to_s,
          new_date: renewal_effective_date.strftime("%Y-%m-%d")
          },
          :correlation_id => correlation_id)
      }
      it "should notify the error" do
        expect(subject).to receive(:notify).with(
          "acapi.error.events.benefit_sponsorship.execute_benefit_renewal.benefit_sponsorship_not_found",
          {
            :return_status => "404",
            :benefit_sponsorship_id => benefit_sponsorship_id.to_s,
            :new_date => renewal_effective_date.strftime("%Y-%m-%d"),
            :body => JSON.dump({
              "benefit sponsorship" => ["can't be found"]
            }),
            :correlation_id => correlation_id
          }
        )
        subject.work_with_params("", nil, payload)
      end
    end
  end
end
