# frozen_string_literal: true

RSpec.shared_context 'family with one member and one enrollment', :shared_context => :metadata do
  let(:start_of_year) { Date.new(current_year).beginning_of_year }
  let(:end_of_year) { Date.new(current_year).end_of_year }
  let(:next_year_date) { Date.new(current_year).next_year }
  let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period, coverage_year: current_year) }
  let!(:current_bcp) do
    bcp = hbx_profile.benefit_sponsorship.current_benefit_coverage_period
    bcp.update_attributes!(open_enrollment_start_on: Date.new(start_of_year.year - 1, 11, 1),
                           open_enrollment_end_on: Date.new(start_of_year.year, 1, 31))
    successor_bcp = bcp.successor
    successor_bcp.update_attributes!(open_enrollment_start_on: Date.new(next_year_date.year - 1, 11, 1),
                                     open_enrollment_end_on: Date.new(next_year_date.year, 1, 31))
    bcp
  end
  let!(:benefit_package) { current_bcp.benefit_packages.first }
  let!(:person) do
    FactoryBot.create(:person,
                      :with_consumer_role,
                      :with_active_consumer_role,
                      dob: (start_of_year - 22.years))
  end

  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:family_member) { family.primary_applicant }
  let!(:renewal_product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product,
                      :ivl_product,
                      :silver,
                      application_period: next_year_date.beginning_of_year..next_year_date.end_of_year)
  end

  let!(:product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product,
                      :ivl_product,
                      :silver,
                      renewal_product_id: renewal_product.id,
                      application_period: start_of_year..end_of_year)
  end

  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      product_id: product.id,
                      kind: 'individual',
                      family: family,
                      consumer_role_id: family.primary_person.consumer_role.id,
                      benefit_package_id: benefit_package.id,
                      effective_on: start_of_year)
  end

  let!(:enrollment_member) do
    FactoryBot.create(:hbx_enrollment_member,
                      hbx_enrollment: enrollment,
                      applicant_id: family_member.id)
  end
end

RSpec.shared_context 'family with one member and one enrollment and one renewal enrollment', :shared_context => :metadata do
  include_context 'family with one member and one enrollment'

  let!(:successor_product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product,
                      :ivl_product,
                      :silver,
                      issuer_name: 'Kaiser',
                      application_period: next_year_date.beginning_of_year..next_year_date.end_of_year)
  end

  let!(:successor_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      product_id: successor_product.id,
                      kind: 'individual',
                      family: family,
                      consumer_role_id: family.primary_person.consumer_role.id,
                      benefit_package_id: benefit_package.id,
                      effective_on: current_bcp.successor.start_on)
  end

  let!(:successor_enrollment_member) do
    FactoryBot.create(:hbx_enrollment_member,
                      hbx_enrollment: successor_enrollment,
                      applicant_id: family_member.id)
  end
end

RSpec.shared_context 'family with one member and one enrollment and one predecessor enrollment', :shared_context => :metadata do
  include_context 'family with one member and one enrollment'
  let(:previous_year) { start_of_year.prev_year }
  let!(:predecessor_product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product,
                      :ivl_product,
                      :silver,
                      issuer_name: 'Kaiser',
                      renewal_product_id: product.id,
                      application_period: previous_year..previous_year.end_of_year)
  end

  let!(:predecessor_bcp) do
    FactoryBot.create(:benefit_coverage_period,
                      benefit_sponsorship: hbx_profile.benefit_sponsorship,
                      open_enrollment_start_on: Date.new(previous_year.year - 1, 11, 1),
                      open_enrollment_end_on: Date.new(previous_year.year, 1, 31),
                      start_on: Date.new(previous_year.year, 1, 1),
                      end_on: Date.new(previous_year.year, 12, 31))
  end

  let!(:predecessor_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      product_id: predecessor_product.id,
                      kind: 'individual',
                      family: family,
                      consumer_role_id: family.primary_person.consumer_role.id,
                      benefit_package_id: predecessor_bcp.benefit_packages.first.id,
                      effective_on: predecessor_bcp.start_on)
  end

  let!(:predecessor_enrollment_member) do
    FactoryBot.create(:hbx_enrollment_member,
                      hbx_enrollment: predecessor_enrollment,
                      applicant_id: family_member.id)
  end
end
