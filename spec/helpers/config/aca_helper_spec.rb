# frozen_string_literal: true

require "rails_helper"

RSpec.describe Config::AcaHelper, :type => :helper, dbclean: :after_each do

  describe "Aca settings" do

    context '.family_contribution_percent_minimum_for_application_start_on' do

      it 'should return family contribution percent for inital employers in flex period' do
        expect(helper.family_contribution_percent_minimum_for_application_start_on(Date.new(2020,5,1), false)).to eq 0
      end

      it 'should return family contribution percent for inital employers outside flex period' do
        expect(helper.family_contribution_percent_minimum_for_application_start_on(Date.new(2019,5,1), false)).to eq 0
      end

      it 'should return family contribution percent for renewal employers in flex period' do
        expect(helper.family_contribution_percent_minimum_for_application_start_on(Date.new(2021, 5, 1), true)).to eq 0
      end

      it 'should return family contribution percent for renewal employers outside flex period' do
        expect(helper.family_contribution_percent_minimum_for_application_start_on(Date.new(2020, 5, 1), true)).to eq 0
      end
    end

    context '.employer_contribution_percent_minimum_for_application_start_on' do

      it 'should return employer contribution percent for inital employers in flex period' do
        expect(helper.employer_contribution_percent_minimum_for_application_start_on(Date.new(2020,5,1), false)).to eq 0
      end

      it 'should return employer contribution percent for inital employers outside flex period' do
        expect(helper.employer_contribution_percent_minimum_for_application_start_on(Date.new(2019,5,1), false)).to eq 50
      end

      it 'should return employer contribution percent for renewal employers in flex period' do
        expect(helper.employer_contribution_percent_minimum_for_application_start_on(Date.new(2021, 5, 1), true)).to eq 0
      end

      it 'should return employer contribution percent for renewal employers outside flex period' do
        expect(helper.employer_contribution_percent_minimum_for_application_start_on(Date.new(2020, 5, 1), true)).to eq 50
      end
    end
  end
end
