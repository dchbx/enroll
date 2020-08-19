FactoryGirl.define do
  factory :family do
    association :person
    sequence(:e_case_id) {|n| "abc#{n}12xyz#{n}"}
    renewal_consent_through_year  2017
    submitted_at Time.now
    updated_at "user"

    transient do
      people []
    end

    trait :with_primary_family_member do
      family_members { [FactoryGirl.build(:family_member, family: self,
          is_primary_applicant: true, is_active: true, person: person)] }
    end

    trait :with_family_members do
      family_members { people.map{|person| FactoryGirl.build(:family_member, family: self, is_primary_applicant: (self.person == person), is_active: true, person: person) }}
    end

    after(:create) do |f, evaluator|
      f.households.first.add_household_coverage_member(f.family_members.first)
      f.save
    end

    trait :with_nuclear_family do
      before(:create) do |family, evaluator|
        FactoryGirl.build(:family_member, is_primary_applicant: true, is_active: true, person: family.person, family: family)

        { 'Kelly' => 'spouse', 'Danny' => 'child' }.each do |first_name, relationship|
          person = FactoryGirl.create(:person, :with_consumer_role, first_name: first_name, last_name: family.person.last_name)
          family.person.person_relationships.push PersonRelationship.new(kind: relationship, family_id: family.id, successor_id: person.id, predecessor_id: family.person.id)
          person.person_relationships = [ PersonRelationship.new(kind: relationship, family_id: family.id, successor_id: person.id, predecessor_id: family.person.id) ]
          person.save
          FactoryGirl.build(:family_member, is_primary_applicant: false, is_active: true, person: person, family: family)
        end
      end

      after(:create) do |family, evaluator|
        #new_person = FactoryGirl.build :person, last_name: family.person.last_name
        #family.family_members.push FactoryGirl.build(:family_member, is_primary_applicant: false, is_active: true, person: new_person, relationship: 'spouse')
      end
    end

    trait :with_primary_family_member_and_dependent do
      family_members {
        [
          FactoryGirl.build(:family_member, family: self, is_primary_applicant: true, is_active: true, person: person),
          FactoryGirl.build(:family_member, family: self, is_primary_applicant: false, is_active: true, person: FactoryGirl.create(:person, first_name: "John", last_name: "Doe")),
          FactoryGirl.build(:family_member, family: self, is_primary_applicant: false, is_active: true, person:  FactoryGirl.create(:person, first_name: "Alex", last_name: "Doe"))
        ]
      }
      before(:create)  do |family, evaluator|
        family.dependents.each do |dependent|
          family.relate_new_member(dependent.person, "child")
        end
      end
    end
  end
end

FactoryGirl.define do
  factory(:individual_market_family, class: Family) do

    transient do
      primary_person    { FactoryGirl.create(:person, :with_consumer_role) }
      significant_other { FactoryGirl.create(:person, :with_consumer_role, gender: "female") }
      disabled_child    { FactoryGirl.create(:person, :with_consumer_role,
                                              is_disabled: true,
                                              dob: (Date.today - 27.years)) }
    end

    family_members { [
        FactoryGirl.build(:family_member, family: self, is_primary_applicant: true, is_active: true,
            person: primary_person)
      ] }

    after(:create) do |f, evaluator|
      f.households.first.add_household_coverage_member(f.family_members.first)
    end

    factory :individual_market_family_with_spouse do

      after(:create) do |f, evaluator|
        spouse = FactoryGirl.create(:family_member, family: f, is_primary_applicant: false,
                  is_active: true, person: evaluator.significant_other)
        f.active_household.add_household_coverage_member(spouse)
      end

    end

    factory :individual_market_family_with_disabled_overage_child do

      after(:create) do |f, evaluator|
        child = FactoryGirl.create(:family_member, family: f, is_primary_applicant: false,
                  is_active: true, person: evaluator.disabled_child)
        f.active_household.add_household_coverage_member(child)
      end

    end
  end
end
