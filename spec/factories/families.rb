FactoryBot.define do
  factory :family do
    association :person
    sequence(:e_case_id) {|n| "abc#{n}12xyz#{n}"}
    renewal_consent_through_year  { 2017 }
    submitted_at { Time.now }
    updated_at { "user" }

    transient do
      people { [] }
    end

    trait :with_primary_family_member do
      family_members { [FactoryBot.build(:family_member, family: self,
          is_primary_applicant: true, is_active: true, person: person)] }
    end

    trait :with_family_members do
      family_members { people.map{|person| FactoryBot.build(:family_member, family: self, is_primary_applicant: (self.person == person), is_active: true, person: person) }}
    end

    after(:create) do |f, evaluator|
      household = f.households.first
      f.family_members.each do |fm|
        household.add_household_coverage_member(fm)
      end
      f.save
    end

    trait :with_nuclear_family do
      before(:create) do |family, _evaluator|
        FactoryBot.build(:family_member, is_primary_applicant: true, is_active: true, person: family.person, family: family)

        { 'Kelly' => 'spouse', 'Danny' => 'child' }.each do |first_name, relationship|
          person = FactoryBot.create(:person, :with_consumer_role, first_name: first_name, last_name: family.person.last_name)
          family.person.person_relationships.push PersonRelationship.new(relative_id: person.id, kind: relationship, family_id: family.id, successor_id: person.id, predecessor_id: family.person.id)
          person.person_relationships = [PersonRelationship.new(kind: relationship, family_id: family.id, successor_id: person.id, predecessor_id: family.person.id)]
          person.save
          FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, person: person, family: family)
        end
      end

      after(:create) do |family, evaluator|
        #new_person = FactoryBot.build :person, last_name: family.person.last_name
        #family.family_members.push FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, person: new_person, relationship: 'spouse')
      end
    end

    trait :with_primary_family_member_and_dependent do
      family_members {
        [
          FactoryBot.build(:family_member, family: self, is_primary_applicant: true, is_active: true, person: person),
          FactoryBot.build(:family_member, family: self, is_primary_applicant: false, is_active: true, person: FactoryBot.create(:person, first_name: "John", last_name: "Doe")),
          FactoryBot.build(:family_member, family: self, is_primary_applicant: false, is_active: true, person:  FactoryBot.create(:person, first_name: "Alex", last_name: "Doe"))
        ]
      }
      before(:create)  do |family, evaluator|
        primary_person = family.primary_applicant.person
        family.dependents.each do |dependent|
          primary_person.ensure_relationship_with(dependent.person, 'child', family.id)
        end
        primary_person.save
      end
    end

    trait :with_persisted_primary_family_member_and_dependent do
      family_members do
        [
          FactoryBot.build(:family_member, family: self, is_primary_applicant: true, is_active: true, person: person),
          FactoryBot.build(:family_member, family: self, is_primary_applicant: false, is_active: true, person: FactoryBot.create(:person, first_name: "John", last_name: "Doe")),
          FactoryBot.build(:family_member, family: self, is_primary_applicant: false, is_active: true, person:  FactoryBot.create(:person, first_name: "Alex", last_name: "Doe"))
        ]
      end
      before(:create)  do |family|
        family.family_members.each(&:save!)
        primary_person = family.primary_applicant.person
        family.dependents.each do |dependent|
          primary_person.ensure_relationship_with(dependent.person, 'child', family.id)
        end
        primary_person.save
        family.households.first.add_household_coverage_member(family.family_members.first)
        family.save
      end
    end
  end
end

FactoryBot.define do
  factory(:individual_market_family, class: Family) do

    transient do
      primary_person    { FactoryBot.create(:person, :with_consumer_role) }
      significant_other { FactoryBot.create(:person, :with_consumer_role, gender: "female") }
      disabled_child    { FactoryBot.create(:person, :with_consumer_role,
                                              is_disabled: true,
                                              dob: (Date.today - 27.years)) }
      second_disabled_child    { FactoryBot.create(:person, :with_consumer_role,
                                              first_name: "Tony",
                                              is_disabled: true,
                                              dob: (Date.today - 30.years)) }
    end

    family_members { [
        FactoryBot.build(:family_member, family: self, is_primary_applicant: true, is_active: true,
            person: primary_person)
      ] }

    after(:create) do |f, evaluator|
      f.households.first.add_household_coverage_member(f.family_members.first)
    end

    factory :individual_market_family_with_spouse do

      after(:create) do |f, evaluator|
        spouse = FactoryBot.create(:family_member, family: f, is_primary_applicant: false,
                  is_active: true, person: evaluator.significant_other)
        f.active_household.add_household_coverage_member(spouse)
      end

    end

    factory :individual_market_family_with_disabled_overage_child do

      after(:create) do |f, evaluator|
        child = FactoryBot.create(:family_member, family: f, is_primary_applicant: false,
                  is_active: true, person: evaluator.disabled_child)
        f.active_household.add_household_coverage_member(child)
      end

    end

    factory :individual_market_family_with_spouse_and_two_disabled_children do
      after(:create) do |f, evaluator|
        primary_person = evaluator.primary_person
        spouse = FactoryBot.create(:family_member, family: f, is_primary_applicant: false,
                  is_active: true, person: evaluator.significant_other)
        f.active_household.add_household_coverage_member(spouse)
        primary_person.ensure_relationship_with(spouse.person, 'spouse', f.id)
        child = FactoryBot.create(:family_member, family: f, is_primary_applicant: false,
                  is_active: true, person: evaluator.disabled_child)
        f.active_household.add_household_coverage_member(child)
        primary_person.ensure_relationship_with(child.person, 'child', f.id)
        second_child = FactoryBot.create(:family_member, family: f, is_primary_applicant: false,
                  is_active: true, person: evaluator.second_disabled_child)
        f.active_household.add_household_coverage_member(second_child)
        primary_person.ensure_relationship_with(second_child.person, 'child', f.id)

        primary_person.save
      end
    end
  end
end
