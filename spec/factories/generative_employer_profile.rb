FactoryGirl.define do

  factory(:generative_office_location, {class:OfficeLocation}) do
    is_primary { Forgery('basic').boolean }
    address {
      if Forgery('basic').boolean
        FactoryGirl.build_stubbed :generative_address
      else
        nil
      end
    }
    phone {
      FactoryGirl.build_stubbed :generative_phone
    }
  end

  factory(:generative_organization, {class: Organization}) do
    legal_name  { Forgery('name').company_name + " " + Forgery('name').industry }
    dba { "A string" }
    fein { Forgery(:basic).number({:min => 0, :max => 999999999}).to_s.rjust(9, '0') }
    home_page { "http://" + Forgery(:internet).domain_name }
    updated_at { DateTime.new }
    created_at { DateTime.new }
    is_active { Forgery('basic').boolean }
    office_locations {
      example_count = Random.rand(4)
      (0..example_count).to_a.map do |e|
        FactoryGirl.build_stubbed :generative_office_location
      end
    }
  end

  factory(:generative_carrier_profile, {class: CarrierProfile}) do
    organization {
      FactoryGirl.build_stubbed :generative_organization
    }
  end

  factory(:generative_reference_plan, {class: Plan}) do
    active_year 2015
    hios_id "JDFLKJELKFJKLDJFIODFIE-01"
    coverage_kind {
      pick_list = Plan::COVERAGE_KINDS
      max = pick_list.length
      pick_list[Random.rand(max)]
    }
    metal_level {
      pick_list = Plan::METAL_LEVEL_KINDS
      max = pick_list.length
      pick_list[Random.rand(max)]
    }
    carrier_profile {
      FactoryGirl.build_stubbed :generative_carrier_profile
    }
  end

  factory(:generative_relationship_benefit, {class: RelationshipBenefit}) do
    transient do
      rel_kind ""
    end
    relationship { rel_kind }
    premium_pct { Random.rand * 100.00 }
    offered { Forgery('basic').boolean }
  end

  factory(:generative_benefit_group, {class: BenefitGroup}) do
    reference_plan { FactoryGirl.build_stubbed :generative_reference_plan }
    relationship_benefits {
        (BenefitGroup::PERSONAL_RELATIONSHIP_KINDS.map do |rk|
          FactoryGirl.build_stubbed(:generative_relationship_benefit, :rel_kind => rk)
        end)
    }
  end

  factory(:generative_plan_year, {class: PlanYear}) do
    open_enrollment_start_on Date.today
    open_enrollment_end_on Date.today
    start_on Date.today
    end_on Date.today
    benefit_groups {
      example_count = Random.rand(4)
      (0..example_count).to_a.map do |e|
        FactoryGirl.build_stubbed :generative_benefit_group
      end
    }
  end

  factory(:generative_person, {class: Person}) do
    first_name { Forgery(:name).first_name }
    last_name { Forgery(:name).first_name }
    hbx_id { "76f55832508f4e5087c5d5d944664b9f" }
  end

  factory(:generative_owner, {class: Person}) do
    first_name { Forgery(:name).first_name }
    last_name { Forgery(:name).first_name }
  end

  factory(:generative_broker_agency_profile, {class: BrokerAgencyProfile }) {
    ach_routing_number "123456789"
    ach_account_number "9999999999999999"
    organization { FactoryGirl.build_stubbed :generative_organization }
    corporate_npn "11234234"
  }

  factory(:generative_broker_role, {class: BrokerRole}) do
    person { FactoryGirl.build_stubbed :generative_person}
  end

  factory(:generative_broker_agency_account, {class: BrokerAgencyAccount}) {
    start_on { DateTime.now }
    end_on { DateTime.now }
    broker_agency_profile {
      FactoryGirl.build_stubbed :generative_broker_agency_profile
    }
    writing_agent { FactoryGirl.build_stubbed :generative_broker_role }
  }

  factory(:generative_employer_profile, {class: EmployerProfile}) do
    entity_kind {
      pick_list = Organization::ENTITY_KINDS
      max = pick_list.length
      pick_list[Random.rand(max)]
    }
    organization { FactoryGirl.build_stubbed :generative_organization }
    plan_years {
      example_count = Random.rand(6)
      (0..example_count).to_a.map do |e|
        FactoryGirl.build_stubbed :generative_plan_year
      end
    }
    broker_agency_accounts {
      example_count = Random.rand(2)
      (0..example_count).to_a.map do |e|
        FactoryGirl.build_stubbed :generative_broker_agency_account
      end
    }

    after(:stub) do |obj|
      extend RSpec::Mocks::ExampleMethods
      allow(obj).to receive(:staff_roles).and_return([(FactoryGirl.build_stubbed :generative_person)])
    end
  end
end
