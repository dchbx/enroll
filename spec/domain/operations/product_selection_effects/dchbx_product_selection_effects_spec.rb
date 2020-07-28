# frozen_string_literal: true

require "rails_helper"

describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
- there is no current coverage
- there is no renewal
- the selection is IVL
- it is not open enrollment prior to plan year start
", dbclean: :after_each do

  let(:coverage_year) { Date.today.year + 1}

  let(:consumer_role) { FactoryBot.create(:consumer_role) }
  let(:hbx_profile) do
    FactoryBot.create(
      :hbx_profile,
      :normal_ivl_open_enrollment,
      coverage_year: coverage_year
    )
  end
  let(:benefit_package) { benefit_coverage_period.benefit_packages.first }
  let(:benefit_coverage_period) do
    hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect do |bcp|
      (bcp.start_on.year == coverage_year) &&
        bcp.start_on > bcp.open_enrollment_start_on
    end
  end
  let(:family) do
    FactoryBot.create(
      :family,
      :with_primary_family_member,
      person: consumer_role.person
    )
  end
  let(:product) do
    BenefitMarkets::Products::Product.find(benefit_package.benefit_ids.first)
  end
  let(:ivl_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :individual_unassisted,
      household: family.active_household,
      effective_on: Date.new(coverage_year, 11, 1),
      family: family,
      benefit_package_id: benefit_package.id
    )
  end

  let(:product_selection) do
    Entities::ProductSelection.new(
      {
        :enrollment => ivl_enrollment,
        :product => product,
        :family => family
      }
    )
  end

  subject do
    product_selection
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end

  it "does not create a renewal after purchase" do
    subject
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(coverage_year, 10, 31))
    subject.call(product_selection)
    family.reload
    expect(family.hbx_enrollments.count).to eq 1
  end
end

describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
- there is no current coverage
- there is no renewal
- the selection is IVL
- it is open enrollment prior to plan year start
", dbclean: :after_each do

  let(:coverage_year) { Date.today.year + 1}

  let(:consumer_role) { FactoryBot.create(:consumer_role) }
  let(:hbx_profile) do
    FactoryBot.create(
      :hbx_profile,
      :normal_ivl_open_enrollment,
      coverage_year: coverage_year
    )
  end
  let(:benefit_package) { benefit_coverage_period.benefit_packages.first }
  let(:benefit_coverage_period) do
    hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect do |bcp|
      (bcp.start_on.year == coverage_year) &&
        bcp.start_on > bcp.open_enrollment_start_on
    end
  end
  let(:family) do
    FactoryBot.create(
      :family,
      :with_primary_family_member,
      person: consumer_role.person
    )
  end
  let(:product) do
    BenefitMarkets::Products::Product.find(benefit_package.benefit_ids.first)
  end
  let(:ivl_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :individual_unassisted,
      household: family.active_household,
      effective_on: Date.new(coverage_year, 11, 1),
      family: family,
      benefit_package_id: benefit_package.id
    )
  end

  let(:product_selection) do
    Entities::ProductSelection.new(
      {
        :enrollment => ivl_enrollment,
        :product => product,
        :family => family
      }
    )
  end

  subject do
    product_selection
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end

  it "does not create a renewal after purchase" do
    subject
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(coverage_year, 11, 15))
    subject.call(product_selection)
  end
end