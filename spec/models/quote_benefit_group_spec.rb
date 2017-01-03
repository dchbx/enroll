# require 'rails_helper'

# RSpec.describe QuoteBenefitGroup, dbclean: :before_each do

#   let(:quote) {FactoryGirl.create(:quote, :with_household_and_members, start_on: TimeKeeper.date_of_record.beginning_of_month)}
#   let(:quote_family) {FactoryGirl.create(:quote, :with_two_families, start_on: TimeKeeper.date_of_record.beginning_of_month)}
#   let(:quote_next_year) {FactoryGirl.create(:quote, :with_household_and_members, start_on: TimeKeeper.date_of_record.beginning_of_month + 1.year)}

#   context 'benefit group calculations' do

#     before :all do
#       Plan.all.delete
#       @plan_silver = FactoryGirl.create(:plan, :with_premium_tables, metal_level: 'silver')
#       @plan_gold = FactoryGirl.create(:plan, :with_premium_tables, metal_level: 'gold')
#       @dental_this_year = FactoryGirl.create(:plan, :with_dental_coverage, :with_premium_tables)
#       @dental_next_year = FactoryGirl.create(:plan, :with_dental_coverage, :with_next_year_premium_tables)
#       @plan_silver_next_year = FactoryGirl.create(:plan, :with_next_year_premium_tables)
#       Caches::PlanDetails.load_record_cache!
#       sleep 1
#       @current_year = TimeKeeper.date_of_record.year
#       @next_year = @current_year + 1
#       Plan.shop_health_plans @current_year
#       Plan.shop_health_plans @next_year
#       @quote = FactoryGirl.create(:quote, :with_household_and_members, start_on: TimeKeeper.date_of_record.beginning_of_month)

#       @silver_age_29 =  Proc.new {|bg| Caches::PlanDetails.lookup_rate(@plan_silver.id, bg.quote.start_on, 29)}
#       @silver_age_30 = Proc.new {|bg| Caches::PlanDetails.lookup_rate(@plan_silver.id, bg.quote.start_on, 30)}
#       @silver_age_30_next_year = Proc.new {|bg| Caches::PlanDetails.lookup_rate(@plan_silver_next_year.id, bg.quote.start_on, 30)}
#     end

#     describe 'different quotes, this year and next' do
#       it 'should have two current year health plans' do
#         expect(Plan.shop_plans('health', @current_year).count).to eq(2)
#         expect(Plan.shop_plans('dental', @current_year).count).to eq(1)
#         expect(Plan.shop_plans('health', @next_year).count).to eq(1)
#         expect(Plan.shop_plans('dental', @next_year).count).to eq(1)

#       #describe 'one household, one employee' do
#         @bg = quote.quote_benefit_groups.first
#         expect(@bg.flat_roster_for_premiums.values.first).to eq(29)
#         expect(@bg.roster_premium(@plan_silver).size).to eq(1)
#         expect(@bg.roster_premium(@plan_silver)["employee"]).to eq(@silver_age_29.call(@bg))
#         plans_cost_by_relationship = @bg.roster_cost_all_plans
#         expect(plans_cost_by_relationship.size).to eq(2)
#         expect(plans_cost_by_relationship[@plan_silver.id.to_s]['employee']).to eq(@silver_age_29.call(@bg))

#       #describe 'two families, spouse different age'
#         @bg = quote_family.quote_benefit_groups.first
#         expect(@bg.flat_roster_for_premiums.values).to eq([29, 30, 29, 30])
#         expect(@bg.roster_premium(@plan_silver)["employee"]).to eq(2 * @silver_age_29.call(@bg))
#         expect(@bg.roster_premium(@plan_silver)["spouse"]).to eq(2 * @silver_age_30.call(@bg))

#       #describe next year
#         @bg = quote_next_year.quote_benefit_groups.first
#         expect(@bg.roster_premium(@plan_silver).size).to eq(1)
#         expect(@bg.roster_premium(@plan_silver_next_year)["employee"]).to eq(@silver_age_30_next_year.call(@bg))
#       end
#     end
#   end
# end
