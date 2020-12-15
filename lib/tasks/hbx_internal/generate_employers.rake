require "json"
include FactoryBot::Syntax::Methods if Rails.env == "development"

namespace :hbxinternal do
  desc "build hbx internals team db"
  task :generate_employers => :environment do
    if Rails.env == "development"
        file = Rails.root.join('db', 'seedfiles', 'hbxit', 'seed_data', 'companies.json')
        surnames = Rails.root.join('db', 'seedfiles', 'hbxit', 'seed_data', 'surnames.json')
        givennames = Rails.root.join('db', 'seedfiles', 'hbxit', 'seed_data', 'firstnames.json')
        companies = data_hash = JSON.parse(File.read(file))
        last_names = data_hash = JSON.parse(File.read(surnames))
        first_names = data_hash = JSON.parse(File.read(givennames))
        aca_state = Settings.aca.state_abbreviation
        street_type = %w[Way Drive Lane Court Avenue]
        gender = %w['Male' 'Female']
        benefit_market = BenefitSponsors::Site.first.benefit_markets.first
        site = BenefitSponsors::Site.first
        this_year = Date.today.year
        effective_date = Date.new(this_year,6,1)
        benefit_market_benefit_sponsor_catalog = BenefitMarkets::BenefitSponsorCatalog.new(
          effective_date: effective_date,
          effective_period: effective_date..(effective_date + 1.year - 1.day),
          open_enrollment_period: (effective_date - 1.month)..(effective_date - 1.month + 9.days),
          probation_period_kinds: [:first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days],
          service_areas: [BenefitMarkets::Locations::ServiceArea.first],
          member_market_policy: FactoryBot.build(:benefit_markets_market_policies_member_market_policy)
        )
        benefit_market_benefit_sponsor_catalog.product_packages = [
          FactoryBot.build(:benefit_markets_products_product_package),
          FactoryBot.build(:benefit_markets_products_product_package, product_kind: :dental, package_kind: :single_product)
        ]
        if benefit_market_benefit_sponsor_catalog.save!
          puts "::: Created Benefit Market Benefit Sponsor Catalog :::"
        end

        puts "::: Generating Employers :::"
        BenefitSponsors::Organizations::GeneralOrganization.all.destroy_all
        companies.each_with_index do |company, i|
          if i <= 40
            fein = 9.times.map{rand(10)}.join
            hbx_id = 9.times.map{rand(10)}.join
            address = BenefitSponsors::Locations::Address.new(kind: "primary", address_1: "#{rand(5..200)} #{company['city']} #{street_type.sample}", city: "Washington", state: aca_state, zip: "20001", county: "County")
            phone = BenefitSponsors::Locations::Phone.new(kind: "main", area_code: "202", number: "#{3.times.map{rand(10)}.join}-#{4.times.map{rand(10)}.join}")
            office_location = BenefitSponsors::Locations::OfficeLocation.new(is_primary: true, address: address, phone: phone)
            office_locations = [office_location]
            gender = %w['male' 'female']
            email = Email.new(kind: "work", address: "hr@#{company['company'].strip}.com")
            organization = BenefitSponsors::Organizations::GeneralOrganization.new(
              site: site,
              hbx_id: hbx_id,
              legal_name: company['company'],
              dba: company['company'],
              fein: fein,
              entity_kind: :s_corporation,
            )
            organization.profiles << BenefitSponsors::Organizations::AcaShopDcEmployerProfile.new(organization: organization, office_locations: office_locations)
            if organization.save!
              puts "::: Created Employer #{company['company']} :::"
              benefit_sponsorship = organization.profiles.first.add_benefit_sponsorship
              benefit_sponsorship.aasm_state = :active
              benefit_sponsorship.save
              total = rand(3..30)
              1.upto(total).each do |n|
                ssn = 9.times.map{rand(10)}.join
                gender = ['male', 'female']
                census_employee = benefit_sponsorship.census_employees.new(first_name: first_names.sample, last_name: last_names.sample, ssn: ssn, employee_relationship: 'self', dob: Date.today - rand(20..50).years, gender: gender.sample, hired_on: Date.today - rand(1..15).days)
                if census_employee.save!
                  puts "::: Created Census Employee #{census_employee.full_name} for #{organization['legal_name']} :::"
                end
              end
              effective_period = TimeKeeper.date_of_record.beginning_of_month..TimeKeeper.date_of_record.beginning_of_month + 1.year - 1.day
              benefit_applications = benefit_sponsorship.benefit_applications.new(fte_count: benefit_sponsorship.census_employees.count, open_enrollment_period: effective_period.min.prev_month..effective_period.min.prev_month + 9.days, recorded_service_areas: [BenefitMarkets::Locations::ServiceArea.first], recorded_rating_area: FactoryBot.create(:benefit_markets_locations_rating_area), recorded_sic_code: "021", benefit_sponsor_catalog: benefit_market_benefit_sponsor_catalog, effective_period: effective_period)
              if benefit_applications.save!
                puts "::: Created Benefit Application for #{company['company']}"
              end
            end
          end
        end
      puts "::: Done Generating Employers :::"
    end
  end
end
