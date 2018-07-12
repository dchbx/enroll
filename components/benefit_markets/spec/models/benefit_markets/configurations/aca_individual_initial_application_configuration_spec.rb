require 'rails_helper'

module BenefitMarkets
  module Configurations
    RSpec.describe Configurations::AcaIndividualInitialApplicationConfiguration, type: :model do

      let(:aca_initial_individual_configuration) { AcaIndividualInitialApplicationConfiguration.new }

      let(:pub_due_dom)       { 5 }
      let(:erlst_strt_prior_eff_months)    	  { -3 }
      let(:appeal_per_aft_app_denial_dys)              { 30 }
      let(:quiet_per_end)  { 28 }
      let(:inelig_per_aft_app_denial_dys)    { 90 }

      let(:params) do
        {
          pub_due_dom: pub_due_dom,
          erlst_strt_prior_eff_months: erlst_strt_prior_eff_months,
          appeal_per_aft_app_denial_dys: appeal_per_aft_app_denial_dys,
          quiet_per_end: quiet_per_end,
          inelig_per_aft_app_denial_dys: inelig_per_aft_app_denial_dys,
        }
      end

      context "with all required arguments" do
          let(:valid_aca_initial_individual_configuration) { described_class.new(params) }

          it "should be valid" do
            valid_aca_initial_individual_configuration.validate
            expect(valid_aca_initial_individual_configuration).to be_valid
          end

          it "all provided attributes should be set" do
            expect(valid_aca_initial_individual_configuration.pub_due_dom).to eq pub_due_dom
            expect(valid_aca_initial_individual_configuration.erlst_strt_prior_eff_months).to eq erlst_strt_prior_eff_months
            expect(valid_aca_initial_individual_configuration.appeal_per_aft_app_denial_dys).to eq appeal_per_aft_app_denial_dys
            expect(valid_aca_initial_individual_configuration.quiet_per_end).to eq quiet_per_end
            expect(valid_aca_initial_individual_configuration.inelig_per_aft_app_denial_dys).to eq inelig_per_aft_app_denial_dys
          end
      end
    end
  end
end
