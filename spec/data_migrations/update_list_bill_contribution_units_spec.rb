# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'update_list_bill_contribution_units')

describe UpdateListBillContributionUnits, dbclean: :after_each do

  let(:given_task_name) { "update_list_bill_contribution_units" }
  subject { UpdateListBillContributionUnits.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'migrate' do

    let(:title) { "#{Settings.site.key.to_s.upcase} Shop Simple List Bill Contribution Model" }
    let!(:contribution_model) { FactoryBot.create(:benefit_markets_contribution_models_contribution_model, title: title) }
    let(:ee_contribution_unit) { contribution_model.contribution_units.where(name: 'employee').first }
    let(:spouse_contribution_unit) { contribution_model.contribution_units.where(name: 'spouse').first }
    let(:domestic_partner_contribution_unit) { contribution_model.contribution_units.where(name: 'domestic_partner').first }
    let(:dependent_contribution_unit) { contribution_model.contribution_units.where(name: 'dependent').first }


    it 'should update minimum_contribution_factor & default_contribution_factor on employee contribution unit' do
      subject.migrate
      ee_contribution_unit.reload
      expect(ee_contribution_unit.minimum_contribution_factor).to eq 0.5
      expect(ee_contribution_unit.default_contribution_factor).to eq 0.5
    end

    it 'should update minimum_contribution_factor & default_contribution_factor on spouse contribution unit' do
      subject.migrate
      spouse_contribution_unit.reload
      expect(spouse_contribution_unit.minimum_contribution_factor).to eq 0.0
      expect(spouse_contribution_unit.default_contribution_factor).to eq 0.0
    end

    it 'should update minimum_contribution_factor & default_contribution_factor on domestic_partner contribution unit' do
      subject.migrate
      domestic_partner_contribution_unit.reload
      expect(domestic_partner_contribution_unit.minimum_contribution_factor).to eq 0.0
      expect(domestic_partner_contribution_unit.default_contribution_factor).to eq 0.0
    end

    it 'should update minimum_contribution_factor & default_contribution_factor on dependent contribution unit' do
      subject.migrate
      dependent_contribution_unit.reload
      expect(dependent_contribution_unit.minimum_contribution_factor).to eq 0.0
      expect(dependent_contribution_unit.default_contribution_factor).to eq 0.0
    end
  end
end
