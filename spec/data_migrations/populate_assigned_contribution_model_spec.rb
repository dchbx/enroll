# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'populate_assigned_contribution_model')
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe PopulateAssignedContributionModel do

  let(:given_task_name) { "populate_assigned_contribution_model" }
  subject { PopulateAssignedContributionModel.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'migrate' do

    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'

    let(:current_effective_date) { TimeKeeper.date_of_record }
    let!(:product_packages) { benefit_sponsor_catalog.product_packages }

    it 'should update assigned_contribution_model on health product_packages' do
      subject.migrate
      benefit_sponsor_catalog.reload
      benefit_sponsor_catalog.product_packages.by_product_kind(:health).each do |product_package|
        product_package.reload
        expect(product_package.assigned_contribution_model.present?).to be_truthy
      end
    end
  end
end
