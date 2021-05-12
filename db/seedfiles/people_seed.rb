puts "*"*80

ENV["ENROLL_SEEDING"] = "true"

puts "::: Generating People :::"
wk_addr = Address.new(kind: "work", address_1: "1600 Pennsylvania Ave NE", city: "Washington", state: "DC", zip: "20001")
hm_addr = Address.new(kind: "home", address_1: "609 H St, NE", city: "Washington", state: "DC", zip: "20002")
ml_addr = Address.new(kind: "mailing", address_1: "440 4th St, NW", city: "Washington", state: "DC", zip: "20001")

wk_phone = Phone.new(kind: "work", area_code: 202, number: 5551211)
hm_phone = Phone.new(kind: "home", area_code: 202, number: 5551212)
mb_phone = Phone.new(kind: "mobile", area_code: 202, number: 5551213)
wk_phone1 = Phone.new(kind: "home", area_code: 202, number: 5551214)


wk_email = Email.new(kind: "work", address: "dude@dc.gov")
hm_email = Email.new(kind: "home", address: "dudette@me.com")
wk_dan_email = Email.new(kind: "work", address: "thomas.dan@dc.gov")


npn0 = "1682443"
npn1 = "2068981"

p0 = Person.create!(first_name: "Bill", last_name: "Murray", addresses: [hm_addr], phones: [hm_phone], emails: [hm_email])
p1 = Person.create!(first_name: "Dan", last_name: "Aykroyd")
p2 = Person.create!(first_name: "Chevy", last_name: "Chase")
p3 = Person.create!(first_name: "Jane", last_name: "Curtin", addresses: [hm_addr, ml_addr], phones: [mb_phone])
p4 = Person.create!(first_name: "Martina", last_name: "Williams", ssn: "151482930", dob: "01/25/1990", gender: "female", phones: [wk_phone1], emails: [wk_dan_email])


def generate_approved_broker (broker, wk_addr, wk_phone, wk_email, email)
  broker.person.addresses << wk_addr
  broker.person.phones << wk_phone
  broker.person.emails << wk_email
  broker.save!
  broker.approve!
  broker.broker_agency_accept!
  broker.person.user = User.create!(email: email, oim_id: email, 'password'=>'aA1!aA1!aA1!', roles: ['broker'])
  broker.person.save!
end


puts "::: Generating Broker Roles :::"
bk0 = p0.build_broker_role(npn: npn0, provider_kind: "assister")
generate_approved_broker(bk0, wk_addr, wk_phone, wk_email, 'bill.murray@example.com')
#bk0.person.addresses << wk_addr
#bk0.person.phones << wk_phone
#bk0.person.emails << wk_email
#bk0.save!

bk1 = p3.build_broker_role(npn: npn1, provider_kind: "broker")
generate_approved_broker(bk1, wk_addr, wk_phone, wk_email, 'jane.curtin@example.com')
#bk1.person.addresses << wk_addr
#bk1.person.phones << wk_phone
#bk1.person.emails << wk_email
#bk1.save!
#bk1.approve!
#bk1.broker_agency_accept!
#p3.user = User.create!(email: 'jane.curtin@example.com', 'password'=>'aA1!aA1!aA1!')
#p3.save!
puts "::: Creating ConsumerRole Roles:::"
c0 = ConsumerRole.new(person: p0, is_incarcerated: false, is_applicant: true, is_state_resident: true, citizen_status: "us_citizen")
c0.gender = "male"
c0.dob = Date.new(1950,9,21)
c0.ssn = "444556666"
c0.save!

c1 = ConsumerRole.new(person: p1, is_incarcerated: false, is_applicant: true, is_state_resident: true, citizen_status: "us_citizen")
c1.gender = "male"
c1.dob = Date.new(1952,7,01)
c1.ssn = "444556665"
c1.save!

# first_name: "Bill", last_name: "Murray", gender: "male", dob: "09/21/1950", employee_relationship: "self", hired_on: "01/16/2015", ssn: "444556666"
# first_name: "Dan", last_name: "Aykroyd", gender: "male", dob: "07/01/1952", employee_relationship: "self", hired_on: "01/20/2015", ssn: "444666655"
# first_name: "Chevy", last_name: "Chase", gender: "male", dob: "10/08/1943", employee_relationship: "self", hired_on: "08/11/2012", ssn: "666554444"
# first_name: "Jane", last_name: "Curtin", gender: "female", dob: "09/06/1947", employee_relationship: "self", hired_on: "01/16/2015", ssn: "555446666"

puts "::: People Complete :::"
puts "*"*80
