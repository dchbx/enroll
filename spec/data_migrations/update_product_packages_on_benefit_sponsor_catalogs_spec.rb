# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'update_product_packages_on_benefit_sponsor_catalogs')
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe UpdateProductPackagesOnBenefitSponsorCatalogs, dbclean: :after_each do

  let(:given_task_name) { "update_product_packages_on_benefit_sponsor_catalogs" }
  subject { UpdateProductPackagesOnBenefitSponsorCatalogs.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'migrate' do

    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'

    let(:current_effective_date) { Date.new(2020,1,1) }
    let!(:catalog) do
      benefit_sponsor_catalog.update_attributes(benefit_application_id: initial_application.id, created_at: initial_application.created_at.next_day)
    end

    it 'should update product packages on sponsor catalog' do
      health_product_packages = initial_application.benefit_sponsor_catalog.product_packages.where(benefit_kind: :aca_shop, product_kind: :health)
      initial_application.update_attributes(created_at: Date.new(2019,10,15))
      expect(health_product_packages.count).to eq 3
      expect(health_product_packages.first.created_at.present?).to eq false
      subject.migrate
      initial_application.benefit_sponsor_catalog.reload
      migrated_product_packages = initial_application.benefit_sponsor_catalog.product_packages.where(benefit_kind: :aca_shop, product_kind: :health)
      expect(migrated_product_packages.count).to eq 3
      expect(migrated_product_packages.first.created_at.present?).to eq true
    end
  end
end
