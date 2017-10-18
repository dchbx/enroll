module BradysAfterAll
  shared_context "BradyBunchAfterAll" do
    def dob(num_years)
      Date.today - num_years.years
    end

    def build_brady_address
      FactoryGirl.build(:address,
                        kind: "home",
                        address_1:
                        "4222 Clinton Way",
                        address_2: nil,
                        city: "Washington",
                        state: "DC",
                        zip: "20011"
                       )
    end

    def build_brady_phone
      FactoryGirl.build(:phone, kind: "home", area_code: "202", number: "7620799", extension: nil)
    end

    def female_brady(name, age)
      FactoryGirl.create(:female, first_name: name, last_name: "Brady", dob: dob(age), addresses: [build_brady_address], phones: [build_brady_phone])
    end

    def male_brady(name, age)
      FactoryGirl.create(:male, first_name: name, last_name: "Brady", dob: dob(age), addresses: [build_brady_address], phones: [build_brady_phone])
    end

    attr_reader :mike, :carol

    def mikes_age; 40; end
    def carols_age; 35; end
    def gregs_age; 16; end
    def marcias_age; 15; end
    def peters_age; 14; end
    def jans_age; 12; end
    def bobbys_age; 8; end
    def cindys_age; 6; end

    attr_reader :mike, :carol, :greg, :marcia, :peter, :jan, :bobby, :cindy

    def create_brady_people
      @mike = male_brady("Mike", mikes_age)
      @carol = female_brady("Carol", carols_age)
      @greg = male_brady("Greg", gregs_age)
      @marcia = female_brady("Marcia", marcias_age)
      @peter = male_brady("Peter", peters_age)
      @jan = female_brady("Jan", jans_age)
      @bobby = male_brady("Bobby", bobbys_age)
      @cindy = female_brady("Cindy", cindys_age)
    end

    attr_reader :brady_daughters, :brady_sons, :brady_children, :bradys, :carols_family, :mikes_family

    def create_brady_families
      create_brady_people
      @brady_daughters = [marcia, jan, cindy]
      @brady_sons = [greg, peter, bobby]
      @brady_children = brady_sons + brady_daughters
      @bradys = [mike, carol, greg, marcia, peter, jan, bobby, cindy]
      @mikes_family = create_mikes_family
      @carols_family = create_carols_family
    end

    def create_mikes_family
      # mike.person_relationships << PersonRelationship.new(relative_id: mike.id, kind: "self") #old_code
      family = FactoryGirl.build(:family)
      family.add_family_member(mike, is_primary_applicant: true)

      # mike.person_relationships << PersonRelationship.new(relative_id: carol.id, kind: "spouse") #old_code
      mike.person_relationships.build(predecessor_id: mike.id, :successor_id => carol.id, :kind => "spouse", family_id: family.id)
      carol.person_relationships.build(successor_id: mike.id, :predecessor_id => carol.id, :kind => "spouse", family_id: family.id)
      brady_children.each do |child|
        mike.person_relationships.build(predecessor_id: mike.id, :successor_id => child.id, :kind => "parent", family_id: family.id)
        child.person_relationships.build(successor_id: mike.id, :predecessor_id => child.id, :kind => "child", family_id: family.id)
      end
      mike.save

      (bradys - [mike]).each do |brady|
        family.add_family_member(brady)
      end
      family.save
      family
    end

    def create_carols_family
      family = FactoryGirl.build(:family)
      family.add_family_member(carol, is_primary_applicant: true)

      # carol.person_relationships << PersonRelationship.new(relative_id: carol.id, kind: "self") #old_code
      # carol.person_relationships << PersonRelationship.new(relative_id: mike.id, kind: "spouse") #old_code
      mike.person_relationships.build(predecessor_id: mike.id, :successor_id => carol.id, :kind => "spouse", family_id: family.id)
      carol.person_relationships.build(successor_id: mike.id, :predecessor_id => carol.id, :kind => "spouse", family_id: family.id)
      brady_children.each do |child|
        carol.person_relationships.build(predecessor_id: carol.id, :successor_id => child.id, :kind => "parent", family_id: family.id)
        child.person_relationships.build(successor_id: carol.id, :predecessor_id => child.id, :kind => "child", family_id: family.id)
      end
      carol.save


      (bradys - [carol]).each do |brady|
        family.add_family_member(brady)
      end
      family.save
      family
    end

    def create_tax_household_for_mikes_family
      create_brady_families
      mikes_family.family_members.each do |fm|
        FactoryGirl.build(:consumer_role, person: fm.person)
      end

      last_year = TimeKeeper.date_of_record - 1.years
      mikes_family.latest_household.tax_households << TaxHousehold.new(effective_ending_on: nil, effective_starting_on: last_year, is_eligibility_determined: true)
      mikes_family.latest_household.tax_households.first.eligibility_determinations << EligibilityDetermination.new(max_aptc: 200, csr_eligibility_kind: 'csr_100', csr_percent_as_integer: 100, determined_at: last_year, determined_on: last_year)

      current_date = TimeKeeper.date_of_record
      mikes_family.latest_household.tax_households << TaxHousehold.new(effective_ending_on: nil, effective_starting_on: current_date, is_eligibility_determined: true)
      mikes_family.latest_household.tax_households.last.eligibility_determinations << EligibilityDetermination.new(max_aptc: 100, csr_eligibility_kind: 'csr_87', csr_percent_as_integer: 87, determined_at: current_date, determined_on: current_date)
    end

    attr_reader :mikes_coverage_household, :carols_coverage_household

    def create_brady_coverage_households
      create_brady_families
      @mikes_coverage_household = mikes_family.households.first.coverage_households.first
      @carols_coverage_household = carols_family.households.first.coverage_households.first
    end
  end

  shared_context "BradyWorkAfterAll" do
    include_context "BradyBunchAfterAll"

    attr_reader :mikes_benefit_group, :mikes_plan_year, :mikes_census_employee, :mikes_census_family, :mikes_hired_on, :mikes_employee_role
    attr_reader :carols_benefit_group, :carols_plan_year, :carols_census_employee, :carols_census_family, :carols_hired_on

    def create_brady_census_families
      create_brady_coverage_households
      create_brady_employers
      @mikes_benefit_group = FactoryGirl.build(:benefit_group, plan_year: nil)
      @mikes_plan_year = FactoryGirl.create(:plan_year, employer_profile: mikes_employer, benefit_groups: [mikes_benefit_group])
      @mikes_hired_on = 1.year.ago.beginning_of_year.to_date
      @mikes_benefit_group_assignments = FactoryGirl.build(:benefit_group_assignment,
                                                           benefit_group_id: @mikes_benefit_group.id,
                                                           start_on: @mikes_plan_year.start_on,
                                                           aasm_state: "initialized"
                                                           )
      @mikes_census_employee = FactoryGirl.create(:census_employee,
                                                   first_name: mike.first_name,  last_name: mike.last_name,
                                                   dob: mike.dob, address: mike.addresses.first, hired_on: mikes_hired_on,
                                                   employer_profile_id: @mikes_employer.id,
                                                   benefit_group_assignments: [@mikes_benefit_group_assignments]
                                                  )
      @carols_hired_on = 1.year.ago.beginning_of_year.to_date
      @carols_benefit_group = FactoryGirl.build(:benefit_group, plan_year: nil)
      @carols_plan_year = FactoryGirl.create(:plan_year, employer_profile: carols_employer, benefit_groups: [carols_benefit_group])
      @carols_benefit_group_assignments = FactoryGirl.build(:benefit_group_assignment,
                                                           benefit_group_id: @carols_benefit_group.id,
                                                           start_on: @carols_plan_year.start_on,
                                                           aasm_state: "initialized"
                                                           )
      @carols_census_employee = FactoryGirl.create(:census_employee,
                                                    first_name: carol.first_name,  last_name: carol.last_name,
                                                    dob: carol.dob, address: carol.addresses.first, hired_on: carols_hired_on,
                                                    employer_profile_id: @carols_employer.id,
                                                    benefit_group_assignments: [@carols_benefit_group_assignments]
                                                   )
      create_brady_employee_roles
    end

    def create_brady_employee_roles
      mike.ssn = "4423445555"
      @mikes_employee_role = EmployeeRole.create!({
        :person => mike,
        :employer_profile_id => mikes_employer.id,
        :benefit_group_id => mikes_benefit_group.id,
        :census_employee_id => @mikes_census_employee.id,
        :hired_on => mikes_hired_on
      })
    end

    attr_reader :mikes_employer, :carols_employer
    def create_brady_employers
      create_brady_work_organizations
      @mikes_employer = FactoryGirl.build(:employer_profile, organization: mikes_organization)
      @carols_employer = FactoryGirl.build(:employer_profile)
    end

    attr_reader :mikes_organization, :carols_organization
    def create_brady_work_organizations
      create_brady_office_locations
      @mikes_organization = FactoryGirl.create(:organization,
                                                 legal_name: "Mike's Architects Limited",
                                                 dba: "MAL",
                                                 office_locations: [mikes_office_location]
                                                )
      @carols_organization = FactoryGirl.create(:organization,
                                                  legal_name: "Care Real S Tates",
                                                  dba: "CRST",
                                                  office_locations: [carols_office_location],
                                                  employer_profile: carols_employer
                                                 )
    end

    attr_reader :mikes_office_location, :carols_office_location
    def create_brady_office_locations
      create_brady_work_addresses
      create_brady_work_phones
      @mikes_office_location = FactoryGirl.build(:office_location,
                        address: mikes_work_addr,
                        phone: mikes_work_phone
                       )
      @carols_office_location = FactoryGirl.build(:office_location,
                                                  address: carols_work_addr,
                                                  phone: carols_work_phone
                                                 )
    end

    attr_reader :mikes_work_phone, :carols_work_phone
    def create_brady_work_phones
      @mikes_work_phone = FactoryGirl.build(:phone, kind: "home", area_code: "202", number: "5069292", extension: nil)
      @carols_work_phone = FactoryGirl.build(:phone, kind: "home", area_code: "202", number: "6109987", extension: nil)
    end

    attr_reader :carols_work_addr, :mikes_work_addr
    def create_brady_work_addresses
      @carols_work_addr = FactoryGirl.build(:address,
                                              kind: "work",
                                              address_1:
                                              "1321 Carter Court",
                                              address_2: nil,
                                              city: "Washington",
                                              state: "DC",
                                              zip: "20011"
                                             )
      @mikes_work_addr = FactoryGirl.build(:address,
                                             kind: "work",
                                             address_1:
                                             "6345 Reagan Road",
                                             address_2: nil,
                                             city: "Washington",
                                             state: "DC",
                                             zip: "20011"
                                            )
    end

  end
end
