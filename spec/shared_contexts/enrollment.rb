RSpec.shared_context "setup families enrollments", :shared_context => :metadata do

  let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
  let!(:renewal_calender_date) {HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period.start_on}
  let!(:renewal_calender_year) {renewal_calender_date.year}

  let!(:current_calender_date) {HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.start_on}
  let!(:current_calender_year) {current_calender_date.year}
  let!(:family_unassisted) {FactoryBot.create(:individual_market_family)}
  let!(:enrollment_unassisted) {FactoryBot.create(:hbx_enrollment, :individual_unassisted, :with_enrollment_members,
                                                   family: family_unassisted,
                                                   household: family_unassisted.active_household,
                                                   enrollment_members: [family_unassisted.family_members.first],
                                                   plan: active_individual_health_plan, effective_on: current_calender_date)}

  let!(:family_assisted) {FactoryBot.create(:individual_market_family)}
  let!(:tax_household) {FactoryBot.create(:tax_household, effective_starting_on: renewal_calender_date,
                                            effective_ending_on: nil, household: family_assisted.active_household)}
  let!(:eligibility_determination1) {FactoryBot.create(:eligibility_determination, tax_household: tax_household, csr_percent_as_integer: 87)}
  let!(:tax_household_member1) {tax_household.tax_household_members.create(applicant_id: family_assisted.family_members.first.id,
                                                                            is_ia_eligible: true)}
  let!(:enrollment_assisted) {FactoryBot.create(:hbx_enrollment, :individual_assisted, :with_enrollment_members,
                                                 applied_aptc_amount: 110,
                                                 family: family_assisted,
                                                 consumer_role_id: family_assisted.primary_family_member.person.consumer_role.id,
                                                 household: family_assisted.active_household,
                                                 enrollment_members: [family_assisted.family_members.first],
                                                 plan: active_csr_87_plan, effective_on: current_calender_date)}

  let!(:active_individual_health_plan) {FactoryBot.create(:active_individual_health_plan, renewal_plan: renewal_individual_health_plan)}
  let!(:active_csr_87_plan) {FactoryBot.create(:active_csr_87_plan, renewal_plan: renewal_csr_87_plan)}

  let!(:renewal_individual_health_plan) {FactoryBot.build(:renewal_individual_health_plan)}
  let!(:renewal_csr_87_plan) {FactoryBot.create(:renewal_csr_87_plan)}

  before do
    renewal_individual_health_plan.update_attributes!(hios_id: active_individual_health_plan.hios_id,
                                                      hios_base_id: active_individual_health_plan.hios_base_id)

    renewal_csr_87_plan.update_attributes!(hios_id: active_csr_87_plan.hios_id,
                                                                        hios_base_id: active_csr_87_plan.hios_base_id)
  end
end