# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, 'spec/shared_contexts/dchbx_product_selection')

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
  let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: consumer_role.person)}
  let(:product) do
    BenefitMarkets::Products::Product.find(benefit_package.benefit_ids.first)
  end
  let(:ivl_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :individual_unassisted,
      household: family.active_household,
      effective_on: Date.new(coverage_year, 11, 1),
      family: family
    )
  end

  let(:product_selection) do
    Entities::ProductSelection.new({:enrollment => ivl_enrollment, :product => product, :family => family})
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
  let(:renewal_benefit_coverage_period) {benefit_coverage_period.successor}
  let(:renewal_benefit_package) {renewal_benefit_coverage_period.benefit_packages.first}

  let(:renewal_product) do
    r_product = BenefitMarkets::Products::Product.find(renewal_benefit_package.benefit_ids.first)
    product.renewal_product_id = r_product.id
    product.save!
    product.reload
    r_product
  end
  let(:ivl_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :individual_unassisted,
      :with_enrollment_members,
      enrollment_members: family.family_members,
      household: family.active_household,
      effective_on: Date.new(coverage_year, 11, 1),
      family: family,
      product: product
    )
  end

  let(:product_selection) do
    Entities::ProductSelection.new({:enrollment => ivl_enrollment, :product => product, :family => family})
  end

  subject do
    renewal_product
    product_selection
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end

  it "does creates a renewal after purchase" do
    subject
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(coverage_year, 11, 15))
    subject.call(product_selection)
    family.reload
    enrollments = family.hbx_enrollments.sort_by(&:effective_on)
    expect(enrollments.length).to eq 2
    renewal_enrollment = enrollments.last
    renewal_start_date = renewal_enrollment.effective_on
    expect(renewal_benefit_coverage_period.start_on).to eq renewal_start_date
    expect(renewal_enrollment.product_id).to eq renewal_product.id
  end
end

RSpec.describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, type: :model do
  before { DatabaseCleaner.clean }

  context 'Prospective' do
    let(:current_year) { TimeKeeper.date_of_record.year }

    before do
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
    end

    include_context 'family with one member and one enrollment and one renewal enrollment'

    context 'new enrollment in existing plan year' do

      before do
        product_selection = Entities::ProductSelection.new({:enrollment => enrollment, :product => enrollment.product, :family => family})
        @result = subject.call(product_selection)
      end

      it 'should create a renewal enrollment' do
        expect(family.hbx_enrollments.count).to eq(3)
      end

      it 'should renew enrollment with start_on of successor bcp' do
        expect(@result.success.effective_on).to eq(current_bcp.successor.start_on)
      end

      it 'should generate renewal in auto_renewing state' do
        expect(@result.success.aasm_state).to eq('auto_renewing')
      end

      it 'should cancel existing renewel enrollment' do
        successor_enrollment.reload
        expect(successor_enrollment.aasm_state).to eq('coverage_canceled')
      end
    end

    context 'new enrollment in renewal plan year' do
      before do
        enrollment.update_attributes!(effective_on: enrollment.effective_on + 1.year)
        product_selection = Entities::ProductSelection.new({:enrollment => enrollment, :product => enrollment.product, :family => family})
        @result = subject.call(product_selection)
      end

      it 'should not create renewal enrollment' do
        expect(family.hbx_enrollments.count).to eq(2)
      end

      it 'should return ok as success' do
        expect(@result.success).to eq(:ok)
      end
    end
  end

  context 'Retrospective' do
    let(:current_year) { TimeKeeper.date_of_record.year + 1 }

    before do
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 1, 1))
    end

    include_context 'family with one member and one enrollment and one predecessor enrollment'

    context 'new enrollment in prior plan year' do

      before do
        predecessor_enrollment.expire_coverage!
        product_selection = Entities::ProductSelection.new({:enrollment => predecessor_enrollment, :product => predecessor_product, :family => family})
        @result = subject.call(product_selection)
      end

      it 'should create a renewal enrollment' do
        expect(family.hbx_enrollments.count).to eq(3)
      end

      it 'should renew enrollment with start_on of successor bcp' do
        expect(@result.success.effective_on).to eq(predecessor_bcp.successor.start_on)
      end

      it 'should generate renewal in coverage_selected state' do
        expect(@result.success.aasm_state).to eq('coverage_selected')
      end

      it 'should cancel existing renewel enrollment' do
        enrollment.reload
        expect(enrollment.aasm_state).to eq('coverage_canceled')
      end
    end

    context 'new enrollment in current plan year' do
      before do
        predecessor_enrollment.update_attributes!(effective_on: predecessor_enrollment.effective_on + 1.year)
        product_selection = Entities::ProductSelection.new({:enrollment => predecessor_enrollment, :product => predecessor_product, :family => family})
        @result = subject.call(product_selection)
      end

      it 'should not create renewal enrollment' do
        expect(family.hbx_enrollments.count).to eq(2)
      end

      it 'should return ok as success' do
        expect(@result.success).to eq(:ok)
      end
    end
  end
end
