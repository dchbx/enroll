# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'update_minimum_contribution_factor_on_contribution_unit')
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"

describe UpdateMinimumContributionFactorOnContributionUnit do

  let(:given_task_name) { "update_minimum_contribution_factor_on_contribution_unit" }
  subject { UpdateMinimumContributionFactorOnContributionUnit.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'migrate' do

    include_context 'setup benefit market with market catalogs and product packages'

    let(:min_contribution_factor) { '0' }
    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
    let!(:product_packages) { current_benefit_market_catalog.product_packages }

    around do |example|
      ClimateControl.modify benefit_market_catalog_application_date: current_effective_date.to_s, min_contribution_factor: min_contribution_factor do
        example.run
      end
    end

    it 'should update minimum_contribution_factor on all contribution units' do
      subject.migrate
      current_benefit_market_catalog.reload
      product_packages.each do |product_package|
        product_package.reload
        product_package.contribution_model.contribution_units.each do |contribution_unit|
          contribution_unit.reload
          expect(contribution_unit.minimum_contribution_factor).to eq min_contribution_factor.to_i
        end
      end
    end
  end
end
