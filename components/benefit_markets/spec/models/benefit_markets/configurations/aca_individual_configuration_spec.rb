require 'rails_helper'

module BenefitMarkets
  module Configurations
    RSpec.describe AcaIndividualConfiguration, type: :model do

      let(:aca_individual_configuration) { AcaIndividualConfiguration.new }

      let(:mm_enr_due_on)       { 15 }
      let(:vr_os_window)    	  { 0 }
      let(:vr_due)              { 95 }
      let(:open_enrl_start_on)  { Date.new(2017,11,1) }
      let(:open_enrl_end_on)    { Date.new(2017,01,31) }

      let(:params) do
        {
          mm_enr_due_on: mm_enr_due_on,
          vr_os_window: vr_os_window,
          vr_due: vr_due,
          open_enrl_start_on: open_enrl_start_on,
          open_enrl_end_on: open_enrl_end_on,
        }
      end

      context "with all required arguments" do
        let(:valid_aca_individual_configuration) { described_class.new(params) }

        it "should be valid" do
          valid_aca_individual_configuration.validate
          expect(valid_aca_individual_configuration).to be_valid
        end

        it "all provided attributes should be set" do
          expect(valid_aca_individual_configuration.mm_enr_due_on).to eq mm_enr_due_on
          expect(valid_aca_individual_configuration.vr_os_window).to eq vr_os_window
          expect(valid_aca_individual_configuration.vr_due).to eq vr_due
          expect(valid_aca_individual_configuration.open_enrl_start_on).to eq open_enrl_start_on
          expect(valid_aca_individual_configuration.open_enrl_end_on).to eq open_enrl_end_on
        end
      end
    end
  end
end
