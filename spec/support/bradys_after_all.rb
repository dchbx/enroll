module BradysAfterAll
  shared_context "BradyBunchAfterAll" do
    def dob(num_years)
      Date.today - num_years.years
    end

    def build_brady_address
      FactoryBot.build(:address,
                        kind: "home",
                        address_1:
                        "4222 Clinton Way NE",
                        address_2: nil,
                        city: "Washington",
                        state: "DC",
                        zip: "20011"
                       )
    end

    def build_brady_phone
      FactoryBot.build(:phone, kind: "home", area_code: "202", number: "7620799", extension: nil)
    end

    def female_brady(name, age)
      female = FactoryBot.create(:female, first_name: name, last_name: "Brady", dob: dob(age), addresses: [build_brady_address], phones: [build_brady_phone])
      female.reload
    end

    def male_brady(name, age)
      male = FactoryBot.create(:male, first_name: name, last_name: "Brady", dob: dob(age), addresses: [build_brady_address], phones: [build_brady_phone])
      male.reload
    end

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
      mike.person_relationships << PersonRelationship.new(relative_id: mike.id, kind: "self")
      mike.person_relationships << PersonRelationship.new(relative_id: carol.id, kind: "spouse")
      brady_children.each do |child|
        mike.person_relationships << PersonRelationship.new(relative_id: child.id, kind: "child")
      end
      mike.save

      family = FactoryBot.build(:family)
      family.add_family_member(mike, is_primary_applicant: true)
      (bradys - [mike]).each do |brady|
        family.add_family_member(brady)
      end
      family.save
      family
    end

    def create_carols_family
      carol.person_relationships << PersonRelationship.new(relative_id: carol.id, kind: "self")
      carol.person_relationships << PersonRelationship.new(relative_id: mike.id, kind: "spouse")
      brady_children.each do |child|
        carol.person_relationships << PersonRelationship.new(relative_id: child.id, kind: "child")
      end
      carol.save

      family = FactoryBot.build(:family)
      family.add_family_member(carol, is_primary_applicant: true)
      (bradys - [carol]).each do |brady|
        family.add_family_member(brady)
      end
      family.save
      family
    end

    def create_tax_household_for_mikes_family
      create_brady_families
      mikes_family.family_members.each do |fm|
        FactoryBot.build(:consumer_role, person: fm.person)
      end

      last_year = TimeKeeper.date_of_record - 1.years
      mikes_family.latest_household.tax_households << TaxHousehold.new(effective_ending_on: nil, effective_starting_on: last_year)
      mikes_family.latest_household.tax_households.first.eligibility_determinations << EligibilityDetermination.new(max_aptc: 200, csr_eligibility_kind: 'csr_100', csr_percent_as_integer: 100, determined_at: last_year, determined_on: last_year, source: 'Admin')

      current_date = TimeKeeper.date_of_record
      mikes_family.latest_household.tax_households << TaxHousehold.new(effective_ending_on: nil, effective_starting_on: current_date)
      mikes_family.latest_household.tax_households.last.eligibility_determinations << EligibilityDetermination.new(max_aptc: 100, csr_eligibility_kind: 'csr_87', csr_percent_as_integer: 87, determined_at: current_date, determined_on: current_date, source: 'Admin')
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

    attr_reader :mikes_benefit_group, :mikes_plan_year, :mikes_census_employee, :mikes_census_family, :mikes_hired_on, :mikes_employee_role, :mikes_benefit_sponsorship
    attr_reader :carols_benefit_group, :carols_plan_year, :carols_census_employee, :carols_census_family, :carols_hired_on

    def create_brady_census_families
      @site = create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key.to_sym)

      create_brady_coverage_households
      create_brady_employers

      issuer_profile = FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: @site

      current_effective_date   = TimeKeeper.date_of_record.beginning_of_month
      benefit_market = @site.benefit_markets.first
      current_benefit_market_catalog =  create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                                benefit_market: benefit_market,
                                                title: "SHOP Benefits for #{current_effective_date.year}",
                                                issuer_profile: issuer_profile,
                                                application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year)
                                              )
                                          
      package_kind             = :single_issuer
      effective_period         = current_effective_date..current_effective_date.next_year.prev_day
      open_enrollment_period   = effective_period.min.prev_month..(effective_period.min - 10.days)

      @mikes_benefit_sponsorship = @mikes_employer.add_benefit_sponsorship
      @mikes_benefit_sponsorship.save

      recorded_service_areas  = mikes_benefit_sponsorship.service_areas_on(effective_period.min)
  
      @mikes_plan_year        = create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog,
                                        :with_benefit_package,
                                        benefit_sponsorship: mikes_benefit_sponsorship,
                                        effective_period: effective_period,
                                        aasm_state: :active,
                                        open_enrollment_period: open_enrollment_period,
                                        recorded_rating_area: mikes_benefit_sponsorship.rating_area,
                                        recorded_service_areas: recorded_service_areas
                                      )

      @mikes_benefit_group   = @mikes_plan_year.benefit_packages[0] 

      # @mikes_benefit_group = FactoryBot.build(:benefit_group, plan_year: nil)
      # @mikes_plan_year = FactoryBot.create(:plan_year, employer_profile: mikes_employer, benefit_groups: [mikes_benefit_group])
      @mikes_hired_on = 1.year.ago.beginning_of_year.to_date
      # @mikes_benefit_group_assignments = FactoryBot.build(:benefit_group_assignment,
      #                                                      benefit_group_id: @mikes_benefit_group.id,
      #                                                      start_on: @mikes_plan_year.start_on,
      #                                                      aasm_state: "initialized"
      #                                                      )
      
      @mikes_census_employee = FactoryBot.create(:census_employee, :with_active_assignment,
                                                  first_name: mike.first_name,  last_name: mike.last_name,
                                                  dob: mike.dob, address: mike.addresses.first, hired_on: mikes_hired_on,
                                                  benefit_sponsorship: @mikes_benefit_sponsorship, employer_profile: @mikes_employer, 
                                                  benefit_group: @mikes_benefit_group
                                                )

      # @carols_hired_on = 1.year.ago.beginning_of_year.to_date
      # @carols_benefit_group = FactoryBot.build(:benefit_group, plan_year: nil)
      # @carols_plan_year = FactoryBot.create(:plan_year, employer_profile: carols_employer, benefit_groups: [carols_benefit_group])
      # @carols_benefit_group_assignments = FactoryBot.build(:benefit_group_assignment,
      #                                                      benefit_group_id: @carols_benefit_group.id,
      #                                                      start_on: @carols_plan_year.start_on,
      #                                                      aasm_state: "initialized"
      #                                                      )
      # @carols_census_employee = FactoryBot.create(:census_employee,
      #                                               first_name: carol.first_name,  last_name: carol.last_name,
      #                                               dob: carol.dob, address: carol.addresses.first, hired_on: carols_hired_on,
      #                                               employer_profile_id: @carols_employer.id,
      #                                               benefit_group_assignments: [@carols_benefit_group_assignments]
      #                                              )
      create_brady_employee_roles
    end

    def create_brady_employee_roles
      mike.ssn = "4423445555"

      @mikes_employee_role = FactoryBot.create(:employee_role,
        :person => mike,
        benefit_sponsors_employer_profile_id: mikes_employer.id,
        employer_profile_id: nil,
        hired_on: @mikes_census_employee.hired_on, 
        census_employee_id: @mikes_census_employee.id)
    end

    attr_reader :mikes_employer, :carols_employer
    def create_brady_employers
      create_brady_work_organizations
      @mikes_employer = @mikes_organization.employer_profile
      # @carols_employer = FactoryBot.build(:employer_profile)
    end

    attr_reader :mikes_organization, :carols_organization
    def create_brady_work_organizations
      create_brady_office_locations
      @mikes_organization = FactoryBot.create(:benefit_sponsors_organizations_general_organization, 
                                               :with_aca_shop_cca_employer_profile, site: @site,
                                               legal_name: "Mike's Architects Limited",
                                               dba: "MAL"
                                               # office_locations: [mikes_office_location]
                                               )
    end

    attr_reader :mikes_office_location, :carols_office_location
    def create_brady_office_locations
      create_brady_work_addresses
      create_brady_work_phones
      @mikes_office_location = FactoryBot.build(:office_location,
                        address: mikes_work_addr,
                        phone: mikes_work_phone
                       )
      @carols_office_location = FactoryBot.build(:office_location,
                                                  address: carols_work_addr,
                                                  phone: carols_work_phone
                                                 )
    end

    attr_reader :mikes_work_phone, :carols_work_phone
    def create_brady_work_phones
      @mikes_work_phone = FactoryBot.build(:phone, kind: "home", area_code: "202", number: "5069292", extension: nil)
      @carols_work_phone = FactoryBot.build(:phone, kind: "home", area_code: "202", number: "6109987", extension: nil)
    end

    attr_reader :carols_work_addr, :mikes_work_addr
    def create_brady_work_addresses
      @carols_work_addr = FactoryBot.build(:address,
                                              kind: "work",
                                              address_1:
                                              "1321 Carter Court",
                                              address_2: nil,
                                              city: "Washington",
                                              state: "DC",
                                              zip: "20011"
                                             )
      @mikes_work_addr = FactoryBot.build(:address,
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
