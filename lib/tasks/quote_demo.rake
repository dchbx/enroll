# bundle exec rake quote_demo:gen
# bundle exec rake quote_demo:clear
# bundle exec rake quote_demo:delete_quotes

namespace :quote_demo do
  desc "generate demo data"

  task :delete_quotes => :environment do

    puts "::: Deleting All Quotes :::"


    Quote.all.try(:destroy)

    puts "All Quotes Deleted"
  end

  task :clear => :environment do

    puts "::: Clear Existing Demo Data :::"

    broker_role_id = BrokerRole.find_by_npn("1234567").id
    BrokerRole.find_by_npn("1234567").try(:destroy)
    Person.where("first_name" => "Quote", "last_name" => "Demo").first.try(:destroy)
    User.by_email("quote.demo@dc.gov").try(:destroy)
    Organization.where("fein" => "000777000").try(:destroy)
    Quote.where("broker_role_id"=> broker_role_id).try(:destroy)

    puts "Broker for Demo Deleted"
  end

  task :gen => :environment do

    puts "::: Checking if Demo data exists :::"
    if BrokerRole.find_by_npn("1234567")
      puts "Broker already exists. Run bundle exec rake quote_demo:clear to reset data"
      exit
    end

    puts "::: Generating Broker for Quote Demo :::"
    wk_addr = Address.new(kind: "work", address_1: "1600 Pennsylvania Ave", city: "Washington", state: "DC", zip: "20001")
    hm_addr = Address.new(kind: "home", address_1: "609 H St, NE", city: "Washington", state: "DC", zip: "20002")
    ml_addr = Address.new(kind: "mailing", address_1: "440 4th St, NW", city: "Washington", state: "DC", zip: "20001")

    wk_phone = Phone.new(kind: "work", area_code: 202, number: 5551211)
    hm_phone = Phone.new(kind: "home", area_code: 202, number: 5551212)
    mb_phone = Phone.new(kind: "mobile", area_code: 202, number: 5551213)

    wk_email = Email.new(kind: "work", address: "quote.demo@dc.gov")
    hm_email = Email.new(kind: "home", address: "quote.demo@dc.gov")


    npn0 = "1234567"

    p0 = Person.create!(first_name: "Quote", last_name: "Demo", addresses: [hm_addr], phones: [hm_phone], emails: [hm_email])

    def generate_approved_broker (broker, wk_addr, wk_phone, wk_email, email)
      broker.person.addresses << wk_addr
      broker.person.phones << wk_phone
      broker.person.emails << wk_email
      broker.save!
      broker.approve!
      broker.broker_agency_accept!
      broker.person.user = User.create!(email: email, oim_id: email, password: 'P@55word', roles: ['broker'])
      broker.person.save!




    end

    def gen_quote (broker_id)

      q = Quote.new
      #q.claim_code = q.employer_claim_code

      q.broker_role_id = broker_id
      q.quote_name = "Demo Quote"
      q.plan_year = 2016
      q.start_on = Date.new(2016,7,2)

      plan1 = Plan.where("active_year"=>2016, "hios_base_id" => "73987DC0040025").first.id
      plan2 = Plan.where("active_year"=>2016, "hios_base_id" => "75753DC0010066").first.id

      qbg = q.quote_benefit_groups.build
      qbg.plan_option_kind = "single_carrier"
      qbg.title = "Office Workers"
      qbg.build_relationship_benefits
      qbg.published_reference_plan = plan1
      qbg.published_lowest_cost_plan = plan1
      qbg.published_highest_cost_plan = plan1

      qbg.relationship_benefit_for("employee").premium_pct=(70)
      qbg.relationship_benefit_for("spouse").premium_pct=(50)
      qbg.relationship_benefit_for("child_under_26").premium_pct=(100)

      qbg1 = q.quote_benefit_groups.build
      qbg1.plan_option_kind = "single_carrier"
      qbg1.title = "Outside Workers"
      qbg1.build_relationship_benefits
      qbg1.published_reference_plan = plan2
      qbg1.published_lowest_cost_plan = plan2
      qbg1.published_highest_cost_plan = plan2


      qbg1.relationship_benefit_for("employee").premium_pct=(80)
      qbg1.relationship_benefit_for("spouse").premium_pct=(65)
      qbg1.relationship_benefit_for("child_under_26").premium_pct=(90)

      qh = q.quote_households.build
      qh.family_id = "1"
      qh.quote_benefit_group_id = qbg.id

      qm = qh.quote_members.build

      qm.first_name = "Tony"
      qm.last_name = "Maloney"
      qm.dob = Date.new(1980,7,26)
      qm.employee_relationship = "employee"

      qm = qh.quote_members.build

      qm.first_name = "Gabriel"
      qm.last_name = "Escobar"
      qm.dob = Date.new(2012,1,10)
      qm.employee_relationship = "child_under_26"


      qm = qh.quote_members.build

      qm.first_name = "Steve"
      qm.last_name = "Onder"
      qm.dob = Date.new(2012,1,10)
      qm.employee_relationship = "child_under_26"

      qm = qh.quote_members.build

      qm.first_name = "Lucas"
      qm.last_name = "Artz"
      qm.dob = Date.new(2012,1,10)
      qm.employee_relationship = "child_under_26"

      qm = qh.quote_members.build

      qm.first_name = "Enzo"
      qm.last_name = "Menzo"
      qm.dob = Date.new(2012,1,10)
      qm.employee_relationship = "child_under_26"

      qm = qh.quote_members.build

      qm.first_name = "Leo"
      qm.last_name = "Pardo"
      qm.dob = Date.new(1991,1,10)
      qm.employee_relationship = "child_under_26"

      q.save

      qh = q.quote_households.build
      qh.family_id = "2"
      qh.quote_benefit_group_id = qbg1.id
      qm = qh.quote_members.build

      qm.first_name = "Dengo"
      qm.last_name = "Mengo"
      qm.dob = Date.new(1988,9,27)
      qm.employee_relationship = "employee"

      qm = qh.quote_members.build

      qm.first_name = "Alice"
      qm.last_name = "Wonder"
      qm.dob = Date.new(2014,1,13)
      qm.employee_relationship = "child_under_26"
      q.save


      q = Quote.new
      #q.claim_code = q.employer_claim_code

      q.broker_role_id = broker_id
      q.quote_name = "Yet another quote"
      q.plan_year = 2016
      q.start_on = Date.new(2016,8,2)


      qbg = q.quote_benefit_groups.build
      qbg.plan_option_kind = "single_carrier"
      qbg.title = "Essential Package"
      qbg.build_relationship_benefits

      #qbg.relationship_benefit_for("employee").premium_pct=(90)
      #qbg.relationship_benefit_for("spouse").premium_pct=(95)
      #qbg.relationship_benefit_for("child_under_26").premium_pct=(50)


      qh = q.quote_households.build
      qh.family_id = "1"
      qh.quote_benefit_group_id = qbg.id

      qm = qh.quote_members.build

      qm.first_name = "John"
      qm.last_name = "Doe"
      qm.dob = Date.new(1980,7,26)
      qm.employee_relationship = "employee"

      qh = q.quote_households.build
      qh.family_id = "2"
      qh.quote_benefit_group_id = qbg.id

      qm = qh.quote_members.build

      qm.first_name = "Hello"
      qm.last_name = "World"
      qm.dob = Date.new(1980,7,26)
      qm.employee_relationship = "employee"

      q.save

    end


    puts "::: Generating Broker Roles :::"
    bk0 = p0.build_broker_role(npn: npn0, provider_kind: "broker")
    bk0.save
    generate_approved_broker(bk0, wk_addr, wk_phone, wk_email, 'quote.demo@dc.gov')



    office0 = OfficeLocation.new(address: {kind: "work", address_1: "Quote St", city: "Washington", state: "DC", zip: "20001"}, phone: {kind: "work", area_code: "202", number: "555-1212"})
    org0 = Organization.new(legal_name: "Quote Agency", fein: "000777000", office_locations: [office0], dba: "Acme")
    org0.create_broker_agency_profile(primary_broker_role: bk0, broker_agency_contacts: [p0], market_kind: "both", entity_kind: "c_corporation")
    org0.save

    p0.broker_role.broker_agency_profile_id  = org0.broker_agency_profile.id

    p0.save


    gen_quote(bk0.id)

    puts "*"*80




  end
end
