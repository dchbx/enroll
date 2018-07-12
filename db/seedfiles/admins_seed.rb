puts "*"*80
puts "::: Creating HBX Admin:::"

aca_state_abbreviation = Settings.aca.state_abbreviation
address  = Address.new(kind: "work", address_1: "1225 I St, NW", city: "Washington", state: aca_state_abbreviation, zip: "20002")
phone    = Phone.new(kind: "main", area_code: "855", number: "532-5465")
# email    = Email.new(kind: "work", address: "admin@dc.gov")
office_location = OfficeLocation.new(is_primary: true, address: address, phone: phone)

supported_states_to_fip = {
  'DC': '11001',
  'MA': '25001'
}
geographic_rating_area = GeographicRatingArea.new(
    rating_area_code: "R-DC001",
    us_counties: UsCounty.where(county_fips_code: supported_states_to_fip[aca_state_abbreviation]).to_a
  )



organization = Organization.new(
      dba: "DCHL",
      legal_name: "#{Settings.site.short_name}",
      fein: 123123456,
      office_locations: [office_location]
    )

hbx_profile = organization.build_hbx_profile(
    cms_id: "#{aca_state_abbreviation}0",
    us_state_abbreviation: aca_state_abbreviation,
    benefit_sponsorship: BenefitSponsorship.new(
        geographic_rating_areas: [geographic_rating_area],
        service_markets: Settings.aca.market_kinds,
        benefit_coverage_periods: [
            BenefitCoveragePeriod.new(
                start_on: Date.new(2015, 1, 1),
                end_on:   Date.new(2015, 12, 31),
                open_enrollment_start_on: Date.new(2014, 11, 1),
                open_enrollment_end_on:   Date.new(2015, 3, 31),
                service_market: "individual"
              ),
            BenefitCoveragePeriod.new(
                start_on: Date.new(2016, 1, 1),
                end_on:   Date.new(2016, 12, 31),
                open_enrollment_start_on: Date.new(2015, 11, 1),
                open_enrollment_end_on:   Date.new(2016, 1, 31),
                service_market: "individual"
              ),
              BenefitCoveragePeriod.new(
                    start_on: Date.new(2017, 1, 1),
                    end_on:   Date.new(2017, 12, 31),
                    open_enrollment_start_on: Date.new(2016, 11, 1),
                    open_enrollment_end_on:   Date.new(2017, 1, 31),
                    service_market: "individual"
                  ),
              BenefitCoveragePeriod.new(
                      start_on: Date.new(2018, 1, 1),
                      end_on:   Date.new(2018, 12, 31),
                      open_enrollment_start_on: Date.new(2017, 11, 1),
                      open_enrollment_end_on:   Date.new(2018, 1, 31),
                      service_market: "individual"
              )
          ]
      )
  )

organization.save!

admin_user    = User.create!(email: "admin@dc.gov", oim_id: "admin@dc.gov", password: "aA1!aA1!aA1!", password_confirmation: "aA1!aA1!aA1!", roles: ["hbx_staff"])
admin_person  = Person.new(first_name: "system", last_name: "admin", dob: "1976-07-04", user: admin_user)
admin_person.save!
admin_person.build_hbx_staff_role(hbx_profile_id: hbx_profile._id, job_title: "grand poobah", department: "accountability")
admin_person.save!

def create_staff member
   user = User.create!(email: member[:email], oim_id: member[:email], password: "aA1!aA1!aA1!", password_confirmation: "aA1!aA1!aA1!", roles: [member[:role]])
   person = Person.new(first_name: member[:first_name], last_name: member[:last_name], user: user)
   person.save!
   if member[:role] == 'assister'
      person.build_assister_role(organization: member[:organization])
   elsif member[:role] == 'csr'
     person.build_csr_role(organization: member[:organization], shift: member[:shift], cac: member[:cac])
   end
   person.save!
end

assisters = [
  {email: 'test@test.org',first_name:  'test', last_name: 'test', organization: 'test', role: 'assister'}
]

csr =[
 {last_name: "LAST",first_name: "FIRST",shift: "10:00AM-6:30PM",organization: "ASHLIN",email: "example.email@someplace.gov", cac: false, role: 'csr'},
 {last_name: "EXAMPLE",first_name: "EXAMPLE",shift: "07:45AM-04:15PM",organization: "KIDD",email: "test.email@someplace.gov", cac: false, role: 'csr'}
]

cac = [
  {first_name:"SAMPLE",last_name:"SAMPLE", email: "sample@example.com", organization: "SAMPL", cac: true, role: 'csr'}
]


staff = assisters + csr + cac
# This would create staff members for HBX
#staff.each{|member| create_staff member}

puts "::: HBX Admins including CSR, CAC and Assisters Complete :::"
