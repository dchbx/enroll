FactoryGirl.define do
  factory :benefit_group do
    plan_year
    relationship_benefits { [
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :employee,                   premium_pct: 80, employer_max_amt: 1000.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :spouse,                     premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :domestic_partner,           premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :child_under_26,             premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :disabled_child_26_and_over, premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :child_26_and_over,          premium_pct:  0, employer_max_amt:    0.00, offered: false),
      ] }
    effective_on_kind "date_of_hire"
    terminate_on_kind "end_of_month"
    plan_option_kind "single_plan"
    description "my first benefit group"
    effective_on_offset 0
    default false
    reference_plan_id {FactoryGirl.create(:plan, :with_premium_tables)._id}
    elected_plan_ids { [ self.reference_plan_id ]}
    employer_max_amt_in_cents 1000_00

    trait :premiums_for_2015 do
      reference_plan_id {FactoryGirl.create(:plan, :premiums_for_2015 )._id}
    end
  end

  trait :with_valid_dental do
    dental_relationship_benefits { [
      FactoryGirl.build_stubbed(:dental_relationship_benefit, benefit_group: self, relationship: :employee,                   premium_pct: 49, employer_max_amt: 1000.00),
      FactoryGirl.build_stubbed(:dental_relationship_benefit, benefit_group: self, relationship: :spouse,                     premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build_stubbed(:dental_relationship_benefit, benefit_group: self, relationship: :domestic_partner,           premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build_stubbed(:dental_relationship_benefit, benefit_group: self, relationship: :child_under_26,             premium_pct: 40, employer_max_amt:  200.00, offered: false),
      FactoryGirl.build_stubbed(:dental_relationship_benefit, benefit_group: self, relationship: :disabled_child_26_and_over, premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build_stubbed(:dental_relationship_benefit, benefit_group: self, relationship: :child_26_and_over,          premium_pct:  0, employer_max_amt:    0.00, offered: false),
      ] }

      dental_plan_option_kind "single_plan"
      dental_reference_plan_id {FactoryGirl.create(:plan, :with_premium_tables)._id}
      elected_dental_plan_ids { [ self.reference_plan_id ]}
      employer_max_amt_in_cents 1000_00
  end

  trait :invalid_employee_relationship_benefit do
    relationship_benefits { [
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :employee,                   premium_pct: 49, employer_max_amt: 1000.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :spouse,                     premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :domestic_partner,           premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :child_under_26,             premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :disabled_child_26_and_over, premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :child_26_and_over,          premium_pct:  0, employer_max_amt:    0.00, offered: false),
      ] }
  end
end

FactoryGirl.define do
  factory :benefit_group_congress, class: BenefitGroup do
    plan_year
    is_congress true
    effective_on_kind "first_of_month"
    terminate_on_kind "end_of_month"
    plan_option_kind "metal_level"
    description "Congress Standard"
    effective_on_offset 30
    default true

    reference_plan_id {FactoryGirl.create(:plan, :with_premium_tables)._id}
    elected_plan_ids { [ self.reference_plan_id ]}

    relationship_benefits { [
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :employee,                   premium_pct: 75, employer_max_amt: 1000.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :spouse,                     premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :domestic_partner,           premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :child_under_26,             premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :disabled_child_26_and_over, premium_pct: 40, employer_max_amt:  200.00),
      FactoryGirl.build(:relationship_benefit, benefit_group: self, relationship: :child_26_and_over,          premium_pct:  0, employer_max_amt:    0.00, offered: false),
      ] }
  end
end