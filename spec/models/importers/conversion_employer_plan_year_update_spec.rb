# require 'rails_helper'

# RSpec.describe Importers::ConversionEmployerPlanYearUpdate, dbclean: :after_each do

#   describe ".save" do
#     context 'when employer already imported and renewing plan year not published' do

#       let!(:employer_profile)      { FactoryGirl.create(:employer_profile, profile_source: 'conversion') }

#       let!(:carrier_profile) { FactoryGirl.create(:carrier_profile) }

#       let(:renewal_health_plan)   {
#         FactoryGirl.create(:plan, :with_premium_tables, coverage_kind: "health", active_year: 2016, carrier_profile_id: carrier_profile.id)
#       }

#       let(:current_health_plan)   {
#         FactoryGirl.create(:plan, :with_premium_tables, coverage_kind: "health", active_year: 2015, renewal_plan_id: renewal_health_plan.id, carrier_profile_id: carrier_profile.id)
#       }

#       let!(:plan_year)            {
#         py = FactoryGirl.create(:plan_year,
#           start_on: Date.new(2015, 7, 1),
#           end_on: Date.new(2016, 6, 30),
#           open_enrollment_start_on: Date.new(2015, 6, 1),
#           open_enrollment_end_on: Date.new(2015, 6, 10),
#           employer_profile: employer_profile
#           )

#         py.benefit_groups = [
#           FactoryGirl.build(:benefit_group,
#             title: "blue collar",
#             plan_year: py,
#             reference_plan_id: current_health_plan.id,
#             elected_plans: [current_health_plan]
#             )
#         ]
#         py.save(:validate => false)
#         py.update_attributes({:aasm_state => 'active'})
#         py
#       }

#       let!(:renewing_plan_year)   {
#         py = FactoryGirl.create(:plan_year,
#           start_on: Date.new(2016, 7, 1),
#           end_on: Date.new(2017, 6, 30),
#           open_enrollment_start_on: Date.new(2016, 6, 1),
#           open_enrollment_end_on: Date.new(2016, 6, 13),
#           employer_profile: employer_profile,
#           aasm_state: 'renewing_draft'
#           )

#         py.benefit_groups = [
#           FactoryGirl.build(:benefit_group,
#             title: "blue collar (2016)",
#             plan_year: py,
#             reference_plan_id: renewal_health_plan.id,
#             elected_plans: [renewal_health_plan]
#             )
#         ]
#         py.save(:validate => false)
#         py
#       }


#       let!(:new_renewal_health_plan)   {
#         FactoryGirl.create(:plan, :with_premium_tables, coverage_kind: "health", active_year: 2016, carrier_profile_id: carrier_profile.id)
#       }

#       let!(:new_current_health_plan)   {
#         FactoryGirl.create(:plan, :with_premium_tables, coverage_kind: "health", active_year: 2015, renewal_plan_id: new_renewal_health_plan.id, carrier_profile_id: carrier_profile.id)
#       }

#       let(:record_attrs) {
#         {
#           :action=>"Update",
#           :fein=> employer_profile.fein,
#           :coverage_start=>"7/1/16",
#           :carrier=>"united healthcare",
#           :enrolled_employee_count=>"23",
#           :plan_selection=>"Single Plan from Carrier",
#           :single_plan_hios_id=>new_current_health_plan.hios_id
#         }
#       }

#       it 'should update both current and renewing plan year with new reference plans' do
#         record = ::Importers::ConversionEmployerPlanYearUpdate.new(record_attrs.merge({:default_plan_year_start => plan_year.start_on}))
#         record.save
#         if EmployerProfile.all.count > 1
#           EmployerProfile.all.each do |employer_profile|
#             employer_profile.destroy unless employer_profile.profile_source == 'conversion'
#           end
#         end
#         expect(EmployerProfile.all.count).to eq 1
#         expect(EmployerProfile.first.plan_years.map(&:aasm_state)).to eq ["active", "renewing_draft"]
#         expect(EmployerProfile.first.plan_years.map{|py| py.benefit_groups.count}).to eq [1,1]
#         expect(EmployerProfile.first.plan_years.where(aasm_state: "active").first.benefit_groups.first.reference_plan_id).to eq(new_current_health_plan.id)
#         expect(EmployerProfile.first.plan_years.where(aasm_state: "renewing_draft").first.benefit_groups.first.reference_plan_id).to eq(new_renewal_health_plan.id)
#       end
#     end
#   end
# end
