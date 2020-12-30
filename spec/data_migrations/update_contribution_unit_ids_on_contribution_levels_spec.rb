# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'update_contribution_unit_ids_on_contribution_levels')
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe PopulateAssignedContributionModel, dbclean: :after_each do

  let(:given_task_name) { "update_contribution_unit_ids_on_contribution_levels" }
  subject { UpdateContributionUnitIdsOnContributionLevels.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'migrate' do

    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'

    let(:current_effective_date) { (TimeKeeper.date_of_record + 2.months).beginning_of_month }

    let(:display_name) { 'Employee' }

    let!(:catalog) do
      benefit_sponsor_catalog.update_attributes(benefit_application_id: initial_application.id, created_at: initial_application.created_at.next_day)
    end

    let!(:contribution_level) do
      cl = initial_application.benefit_packages[0].health_sponsored_benefit.sponsor_contribution.contribution_levels.where(display_name: display_name).first
      cl.update_attributes(contribution_unit_id: BSON::ObjectId.new)
      cl
    end

    let!(:contribution_unit)  { initial_application.benefit_packages[0].health_sponsored_benefit.contribution_model.contribution_units.where(display_name: display_name).first }

    it 'should update contribution_unit_id on contribution_level' do
      expect(contribution_unit.id).not_to eq contribution_level.contribution_unit_id
      subject.migrate
      initial_application.reload
      cl = initial_application.benefit_packages[0].health_sponsored_benefit.sponsor_contribution.contribution_levels.where(display_name: display_name).first
      expect(contribution_unit.id).to eq cl.contribution_unit_id
    end
  end
end
