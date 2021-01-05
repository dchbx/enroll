# frozen_string_literal: true
=begin

require 'rails_helper'

describe Fix2020IvlBenefitPackages, dbclean: :after_each do
  before do
    DatabaseCleaner.clean
  end

  let(:given_task_name) { 'fix_csr_eligibility_kinds_for_eds_with_csr_percent_zero' }
  subject { Fix2020IvlBenefitPackages.new(given_task_name, double(:current_scope => nil)) }

  context 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  context 'valid curam determination' do
    let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :single_open_enrollment_coverage_period) }
    let!(:slcsp) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        hios_id: '94506DC0390006-01',
                        application_period: Date.new(2020, 1, 1)..Date.new(2020, 12, 31))
    end

    before do
      setup_data_for_migration
      subject.migrate
      @bc_period_2020.reload
      @csr_0_benefit_package = @bc_period_2020.benefit_packages.where(:"benefit_eligibility_element_group.cost_sharing" => 'csr_0').first
      @csr_100_benefit_package = @bc_period_2020.benefit_packages.where(:"benefit_eligibility_element_group.cost_sharing" => 'csr_100').first
      @csr_limited_benefit_package = @bc_period_2020.benefit_packages.where(:"benefit_eligibility_element_group.cost_sharing" => 'csr_limited').first
    end

    it 'should create a benefit_package associated with csr_0' do
      expect(@csr_0_benefit_package).to be_truthy
    end

    it 'should create a benefit_package associated with csr_limited' do
      expect(@csr_limited_benefit_package).to be_truthy
    end

    it 'should create a benefit_package associated with csr_limited' do
      expect(@csr_limited_benefit_package.cost_sharing).to eq('csr_limited')
    end

    it 'should update the benefit_package associated with csr_100 with new benefit_ids' do
      expect(@csr_100_benefit_package.benefit_ids.any?{|b_id| @csr_100_bp_benefit_ids.include? b_id}).to be_falsy
    end
  end

  private

  def setup_data_for_migration
    invoke_task
    @bc_period_2020 = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.detect{|bcp| bcp.start_on.year == 2020}
    @bc_period_2020.reload
    csr_0_benefit_package_id = @bc_period_2020.benefit_packages.where(:"benefit_eligibility_element_group.cost_sharing" => 'csr_0').first.id
    @bc_period_2020.benefit_packages.find(csr_0_benefit_package_id.to_s).destroy!
    csr_limited_benefit_package_id = @bc_period_2020.benefit_packages.where(:"benefit_eligibility_element_group.cost_sharing" => 'csr_limited').first.id
    @bc_period_2020.benefit_packages.find(csr_limited_benefit_package_id.to_s).destroy!
    ivl_health_plans_2020_for_csr_0 = BenefitMarkets::Products::Product.aca_individual_market.where(
      "$and" => [{ :kind => 'health'},
                 {"$or" => [{:metal_level_kind.in => %w[platinum gold bronze], hios_id: /-01$/ },
                            {:metal_level_kind => 'silver', hios_id: /-01$/ }]}]
    ).select{|a| a.active_year == 2020}.entries.collect(&:_id)
    csr_100_benefit_package = @bc_period_2020.benefit_packages.where(:"benefit_eligibility_element_group.cost_sharing" => 'csr_100').first
    csr_100_benefit_package.update_attributes!(benefit_ids: ivl_health_plans_2020_for_csr_0)
    csr_100_benefit_package.save!
    @bc_period_2020.save!
    @csr_100_bp_benefit_ids = csr_100_benefit_package.benefit_ids
  end

  def invoke_task
    load File.expand_path("#{Rails.root}/lib/tasks/migrations/create_2020_ivl_pacakges.rake", __FILE__)
    Rake::Task.define_task(:environment)
    Rake::Task['import:create_2020_ivl_packages'].reenable
    Rake::Task['import:create_2020_ivl_packages'].invoke
  end
end

=end
