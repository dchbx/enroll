require "rails_helper"

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe Queries::PolicyAggregationPipeline, "Policy Queries", dbclean: :around_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"
  include_context "setup employees with benefits"

  let(:subject) { Queries::PolicyAggregationPipeline.new }
  let(:aggregation) { [
                             { "$match" => {"hbx_enrollment_members" => {"$ne" => nil}, "external_enrollment" => {"$ne" => true}}}
  ] }
   let(:step) { {'rspec' => "test"}}
   let(:open_enrollment_query) {{
                                "$match" => {
                                      "enrollment_kind" => "open_enrollment" }
                                }}
  let(:hbx_id_list) {[abc_organization.hbx_id]}
  let(:renewal_state) { :enrollment_eligible }
  let(:open_enrollment_period)   { (effective_period.min.prev_month - 2.days)..(effective_period.min - 10.days) }
  let!(:effective_on) {effective_period.min}
  let!(:organization) {abc_organization}
  let!(:benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, start_on: current_benefit_package.start_on, benefit_group_id: nil, benefit_package: current_benefit_package)}
  let(:reference_product) {current_benefit_package.sponsored_benefits.first.reference_product}
  let!(:ce)  { census_employees[0]}
  let!(:person) {FactoryBot.create(:person, first_name: ce.first_name, last_name: ce.last_name, ssn:ce.ssn)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person:person)}
  let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: ce.id, benefit_sponsors_employer_profile_id: abc_profile.id)}
  let!(:initial_enrollment) {
    hbx_enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                        household: family.active_household,
                        aasm_state: "coverage_enrolled",
                        family: family,
                        effective_on: effective_on,
                        rating_area_id: predecessor_application.recorded_rating_area_id,
                        sponsored_benefit_id: predecessor_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id: predecessor_application.benefit_packages.first.id,
                        benefit_sponsorship_id: predecessor_application.benefit_sponsorship.id,
                        employee_role_id: employee_role.id,
                        submitted_at: Date.new(2018,6,21)
                        )
    hbx_enrollment.benefit_sponsorship = benefit_sponsorship
    hbx_enrollment.save!
    hbx_enrollment
  }
  let!(:initial_hbx_enrollment_member) {FactoryBot.create(:hbx_enrollment_member, applicant_id: person.id, hbx_enrollment: initial_enrollment) }
  let!(:renewal_enrollment) {
    hbx_enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                        household: family.active_household,
                        family: family,
                        effective_on: effective_on,
                        aasm_state: "coverage_selected",
                        rating_area_id: renewal_application.recorded_rating_area_id,
                        sponsored_benefit_id: renewal_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id: renewal_application.benefit_packages.first.id,
                        benefit_sponsorship_id: renewal_application.benefit_sponsorship.id,
                        employee_role_id: employee_role.id
                        )
    hbx_enrollment.benefit_sponsorship = benefit_sponsorship
    hbx_enrollment.save!
    hbx_enrollment
  }

  let!(:bad_enrollment) {
    hbx_enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                        household: family.active_household,
                        aasm_state: "inactive",
                        family: family,
                        effective_on: (effective_on - 2.years),
                        rating_area_id: predecessor_application.recorded_rating_area_id,
                        sponsored_benefit_id: "12121212",
                        sponsored_benefit_package_id:"2323232323",
                        benefit_sponsorship_id: predecessor_application.benefit_sponsorship.id,
                        employee_role_id: employee_role.id,
                        submitted_at: Date.new(2015,6,21)
                        )
    hbx_enrollment.benefit_sponsorship = benefit_sponsorship
    hbx_enrollment.save!
    hbx_enrollment
  }
  let!(:renewal_hbx_enrollment_member) {FactoryBot.create(:hbx_enrollment_member, applicant_id: person.id, hbx_enrollment: renewal_enrollment) }
  let!(:good_enrollment_hbx_ids) {HbxEnrollment.where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES).map(&:hbx_id)}
  let!(:bad_enrollment_hbx_ids) {HbxEnrollment.where(:aasm_state.in => HbxEnrollment::SELECTED_AND_WAIVED).map(&:hbx_id)}

  before do
    ce.update_attributes(:employee_role_id => employee_role.id )
  end

  context 'aggregation methods' do

    it 'base_pipeline' do
      expect(subject.pipeline).to eq (aggregation)
      expect(subject.base_pipeline).to eq (aggregation)
    end

    it 'add' do
      value = subject.add(step)
      expect(value.length).to eq aggregation.length + 1
    end

    it 'open_enrollment' do
      value = subject.open_enrollment
      expect(value.pipeline[1]).to eq (open_enrollment_query)
    end

    it '.filter_to_employers_hbx_ids' do
      orgs = BenefitSponsors::Organizations::Organization.where(:hbx_id => {"$in" => hbx_id_list})
      benefit_group_ids = orgs.map(&:active_benefit_sponsorship).flat_map(&:benefit_applications).flat_map(&:benefit_packages).map(&:_id)
      expect(subject.pipeline.count).to be 1
      subject.filter_to_employers_hbx_ids(hbx_id_list)
      expect(subject.pipeline.count).to be 2
      expect([subject.pipeline[1]]).to eq [{"$match"=> {"sponsored_benefit_package_id"=>
                                                        {"$in"=>
                                                        [benefit_group_ids[0], benefit_group_ids[1]]}}}]

                                                        expect(subject.evaluate.map{|a|a['hbx_id']}).to eq good_enrollment_hbx_ids
    end

    it '.exclude_employers_by_hbx_ids' do
      expect(subject.pipeline.count).to be 1
      value = subject.exclude_employers_by_hbx_ids(hbx_id_list)
      expect(subject.pipeline.count).to be 2
    end

    it '.filter_to_active' do
      expect(subject.pipeline.count).to be 1
      value = subject.filter_to_active
      expect(subject.pipeline.count).to be 2
    expect(subject.evaluate.map{|a|a['hbx_id']}).to eq good_enrollment_hbx_ids
    end

    it '.with_effective_date' do
      value = subject.with_effective_date(effective_on)
    expect(subject.evaluate.map{|a|a['hbx_id']}).to eq good_enrollment_hbx_ids
    end

    it '.filter_to_shop' do
      value = subject.filter_to_shop
    expect(subject.evaluate.map{|a|a['hbx_id']}).to eq good_enrollment_hbx_ids
    end

    it '.list_of_hbx_ids' do
      expect(subject.list_of_hbx_ids).to eq good_enrollment_hbx_ids
    end

    it '.filter_to_shopping_completed' do
      subject.filter_to_shopping_completed
      expect(subject.evaluate.map{|a|a['hbx_id']}).to eq good_enrollment_hbx_ids
    end

    it '.eliminate_family_duplicates' do
      expect(good_enrollment_hbx_ids).to include subject.eliminate_family_duplicates.evaluate.map{|a|a['hbx_id']}.first
      expect(bad_enrollment_hbx_ids).to_not include subject.eliminate_family_duplicates.evaluate.map{|a|a['hbx_id']}.first
    end

  end
end
