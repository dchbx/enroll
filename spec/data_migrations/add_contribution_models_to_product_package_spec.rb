# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'add_contribution_models_to_product_package')
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"

describe AddContributionModelsToProductPackage do

  let(:given_task_name) { "add_contribution_models_to_product_package" }
  subject { AddContributionModelsToProductPackage.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'migrate' do

    include_context 'setup benefit market with market catalogs and product packages'

    let(:current_effective_date) { TimeKeeper.date_of_record }
    let!(:product_packages) { current_benefit_market_catalog.product_packages }

    it 'should update minimum_contribution_factor on all contribution units' do
      subject.migrate
      current_benefit_market_catalog.reload
      current_benefit_market_catalog.product_packages.each do |product_package|
        product_package.reload
        expect(product_package.contribution_models.present?).to be_truthy
        product_package.contribution_models.each do |contribution_model|
          expect(contribution_model.contribution_units.present?).to be_truthy
        end
      end
    end
  end
end
