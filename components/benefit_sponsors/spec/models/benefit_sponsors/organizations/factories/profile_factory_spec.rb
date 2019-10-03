# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
# require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require File.join(File.dirname(__FILE__), "..", "..", "..", "..", "support/benefit_sponsors_site_spec_helpers")

module BenefitSponsors
  RSpec.describe Organizations::Factories::ProfileFactory, type: :model, dbclean: :after_each do
    let(:site) { ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market }


    let(:current_user) { FactoryBot.create :user }
    let(:fein) { "878998789" }
    let(:dob) { TimeKeeper.date_of_record - 60.years }
    let(:state) { Settings.aca.state_abbreviation }
    let(:city)                    { 'Washington' }
    let(:phone_number)            { '0987987' }
    let(:new_organization_name)   { 'New Organization LLC' }
    let(:valid_employer_params) do
      site
      {
        :current_user_id => current_user.id,
        :profile_type => "benefit_sponsor",
        :profile_id => nil,
        :staff_roles_attributes =>
        {
          0 =>
          {
            :npn => nil,
            :first_name => "Dany",
            :last_name => "Targ",
            :email => "dany@targ.com",
            :phone => nil,
            :status => nil,
            :dob => dob,
            :person_id => "",
            :area_code => "988",
            :number => "9879879",
            :extension => nil,
            :profile_id => nil,
            :profile_type => nil
          }
        },
        :organization =>
        {
          :entity_kind => :tax_exempt_organization,
          :fein => fein,
          :dba => "",
          :legal_name => "Mother of Drag",
          :profiles_attributes =>
          {
            0 =>
            {
              :contact_method => "electronic_only",
              :office_locations_attributes =>
              {
                0 =>
                {
                  :is_primary => true,
                  :_destroy => nil,
                  :phone_attributes =>
                  {
                    :kind => "phone main",
                    :area_code => "687",
                    :number => "7868776",
                    :extension => ""
                  },
                  :address_attributes =>
                  {
                    :address_1 => "87897",
                    :address_2 => "78897",
                    :city => "Wash",
                    :kind => "primary",
                    :state => state,
                    :zip => "20024",
                    :county => nil
                  }
                }
              }
            }
          }
        }
      }
    end
    let(:valid_broker_params) do
      site
      {
        :current_user_id => current_user.id,
        :profile_type => "broker_agency",
        :profile_id => nil,
        :staff_roles_attributes =>
        {
          0 =>
          {
            :npn => "3458947593",
            :first_name => "Tyrion",
            :last_name => "Lannister",
            :email => "tyrion@lannister.com",
            :phone => nil,
            :status => nil,
            :dob => dob,
            :person_id => nil,
            :area_code => nil,
            :number => nil,
            :extension => nil,
            :profile_id => nil,
            :profile_type => nil
          }
        },
        :organization =>
        {
          :entity_kind => :s_corporation,
          :fein => fein,
          :dba => "Doing Business As",
          :legal_name => "Lannister Army",
          :profiles_attributes =>
          {
            0 =>
            {
              :market_kind => :shop,
              :home_page => nil,
              :accept_new_clients => "0",
              :languages_spoken => ["", "en"],
              :working_hours => "0",
              :ach_routing_number => nil,
              :ach_account_number => nil,
              :office_locations_attributes =>
              {
                0 =>
                {
                  :is_primary => true,
                  :_destroy => nil,
                  :phone_attributes =>
                  {
                    :kind => "phone main",
                    :area_code => "879",
                    :number => "0987987",
                    :extension => ""
                  },
                  :address_attributes =>
                  {
                    :address_1 => "H ",
                    :address_2 => "Wash",
                    :city => "Wash",
                    :kind => "primary",
                    :state => state,
                    :zip => "20024",
                    :county => nil
                  }
                }
              }
            }
          }
        }
      }
    end
    let(:profile_factory_class) { BenefitSponsors::Organizations::Factories::ProfileFactory }

    context '.persist' do
      context 'when type is benefit sponsor' do
        let(:profile_factory) do
          profile_factory_class.call(valid_employer_params)
        end

        it 'should create general organization with given fein' do
          expect(profile_factory.organization.class).to eq BenefitSponsors::Organizations::GeneralOrganization
          expect(profile_factory.organization.fein).to eq fein
        end

        it 'should create benefit sponsor profile' do
          expect(profile_factory.profile.class).to eq "BenefitSponsors::Organizations::AcaShop#{Settings.site.key.capitalize}EmployerProfile".constantize
        end

        it 'should create person with given data' do
          expect(profile_factory.person.full_name).to eq "Dany Targ"
        end

        it 'should return redirection url' do
          expect(profile_factory.redirection_url(profile_factory.pending, true)).to eq "sponsor_home_registration_url@#{profile_factory.profile.id}"
        end
      end

      context 'when type is broker agency' do
        let(:profile_factory) { profile_factory_class.call(valid_broker_params) }

        it 'should create general organization' do
          expect(profile_factory.organization.class).to eq BenefitSponsors::Organizations::ExemptOrganization
        end

        it 'should create broker agency profile' do
          expect(profile_factory.profile.class).to eq BenefitSponsors::Organizations::BrokerAgencyProfile
        end

        it 'should create person with given data' do
          expect(profile_factory.person.full_name).to eq "Tyrion Lannister"
        end

        it 'should return redirection url' do
          expect(profile_factory.redirection_url(profile_factory.pending, true)).to eq :broker_new_registration_url
        end

        context 'when broker npn already exists' do
          let!(:broker_organization)      { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
          let(:person)                    { FactoryBot.create(:person) }
          let!(:broker_role)              { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_organization.broker_agency_profile.id, person: person) }
          let(:invalid_staff_role_params) do
            {
              0 =>
              {
                :npn => broker_role.npn,
                :first_name => "Tyrion",
                :last_name => "Lannister",
                :email => "tyrion@lannister.com",
                :phone => nil,
                :status => nil,
                :dob => dob,
                :person_id => nil,
                :area_code => nil,
                :number => nil,
                :extension => nil,
                :profile_id => nil,
                :profile_type => nil
              }
            }
          end
          let(:invalid_broker_params)     { valid_broker_params.merge({ staff_roles_attributes: invalid_staff_role_params }) }
          let(:profile_factory)           { profile_factory_class.call(invalid_broker_params) }

          it 'should throw an error' do
            expect(profile_factory.errors.messages[:organization]).to eq ["NPN has already been claimed by another broker. Please contact HBX-Customer Service - Call (855) 532-5465."]
          end
        end
      end

      context 'when type is general agency' do
        let(:valid_ga_params) do
          ga_params = valid_broker_params.merge({ :profile_type => "general_agency" })
          ga_params[:organization][:profiles_attributes][0].delete(:ach_account_number)
          ga_params[:organization][:profiles_attributes][0].delete(:ach_routing_number)
          ga_params
        end

        let(:profile_factory) { profile_factory_class.call(valid_ga_params) }

        it 'should create general organization' do
          expect(profile_factory.organization.class).to eq BenefitSponsors::Organizations::GeneralOrganization
        end

        it 'should create general agency profile' do
          expect(profile_factory.profile.class).to eq BenefitSponsors::Organizations::GeneralAgencyProfile
        end

        it 'should create person with given data' do
          expect(profile_factory.person.full_name).to eq "Tyrion Lannister"
        end

        it 'should create general agency staff role with is_primary true' do
          expect(profile_factory.person.general_agency_staff_roles.first.is_primary).to be_truthy
        end

        it 'should return redirection url' do
          expect(profile_factory.redirection_url(profile_factory.pending, true)).to eq :general_agency_new_registration_url
        end
      end
    end

    context '.update' do
      context 'when type is benefit sponsor' do
        let!(:abc_organization) do
          FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site)
        end
        let!(:benefit_sponsorship) do
          benefit_sponsorship = employer_profile.add_benefit_sponsorship
          benefit_sponsorship.aasm_state = :applicant
          benefit_sponsorship.save
          benefit_sponsorship
        end
        let(:employer_profile) { abc_organization.employer_profile }
        let(:new_organization_name) { "Texas Tech Agency" }
        let(:office_location) { abc_organization.employer_profile.primary_office_location }

        let(:valid_employer_params_update) do
          {
            :current_user_id => current_user.id,
            :profile_type => "benefit_sponsor",
            :profile_id => employer_profile.id,
            :staff_roles_attributes => {},
            :organization =>
            {
              :entity_kind => :tax_exempt_organization,
              :fein => abc_organization.fein,
              :dba => "",
              :legal_name => new_organization_name,
              :profiles_attributes =>
              {
                0 =>
                {
                  :contact_method => "electronic_only",
                  :id => employer_profile.id,
                  :office_locations_attributes =>
                  {
                    0 =>
                    {
                      :is_primary => true,
                      :id => office_location.id,
                      :_destroy => "false",
                      :phone_attributes =>
                      {
                        :kind => "phone main",
                        :area_code => "878",
                        :number => phone_number,
                        :extension => "",
                        :id => office_location.phone.id
                      },
                      :address_attributes =>
                      {
                        :address_1 => "H",
                        :address_2 => "Wash",
                        :city => city,
                        :kind => "primary",
                        :state => "DC",
                        :zip => "20024",
                        :county => nil,
                        :id => office_location.address.id
                      }
                    }
                  }
                }
              }
            }
          }
        end
        let!(:profile_factory) { profile_factory_class.call(valid_employer_params_update) }

        before { abc_organization.reload }

        it 'should update general organization legal_name' do
          expect(abc_organization.legal_name).to eq new_organization_name
        end

        it 'should update address' do
          expect(abc_organization.employer_profile.primary_office_location.address.city).to eq city
        end

        it 'should update phone' do
          expect(abc_organization.employer_profile.primary_office_location.phone.number).to eq phone_number
        end
      end

      context 'when type is broker agency' do
        let(:valid_broker_params_update) do
          {
            :current_user_id => current_user.id,
            :profile_type => "broker_agency",
            :profile_id => broker_agency_profile.id,
            :staff_roles_attributes =>
            {
              0 =>
              {
                :npn => broker_role.npn,
                :first_name => "Broker 12",
                :last_name => "Gov",
                :email => "gov@gov.com",
                :phone => nil,
                :status => nil,
                :dob => dob,
                :person_id => person.id,
                :area_code => nil,
                :number => nil,
                :extension => nil,
                :profile_id => nil,
                :profile_type => nil
              }
            },
            :organization =>
            {
              :entity_kind => :s_corporation,
              :fein => broker_organization.fein,
              :dba => "",
              :legal_name => new_organization_name,
              :profiles_attributes =>
              {
                0 =>
                {
                  :id => broker_agency_profile.id,
                  :market_kind => broker_agency_profile.market_kind,
                  :home_page => "",
                  :accept_new_clients => "0",
                  :languages_spoken => [""],
                  :working_hours => "0",
                  :ach_routing_number => nil,
                  :ach_account_number => nil,
                  :office_locations_attributes =>
                  {
                    0 =>
                    {
                      :is_primary => true,
                      :id => office_location.id,
                      :_destroy => "false",
                      :phone_attributes =>
                      {
                        :kind => "phone main",
                        :area_code => "879",
                        :number => phone_number,
                        :extension => "",
                        :id => office_location.phone.id
                      },
                      :address_attributes =>
                      {
                        :address_1 => "H",
                        :address_2 => "Wash",
                        :city => city,
                        :kind => "primary",
                        :state => "DC",
                        :zip => "20024",
                        :county => nil,
                        :id => office_location.address.id
                      }
                    }
                  }
                }
              }
            }
          }
        end

        let(:office_location)         { broker_agency_profile.primary_office_location }
        let!(:broker_organization)    { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
        let(:person)                  { FactoryBot.create(:person) }
        let!(:broker_role)            { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person) }
        let(:broker_agency_profile)   { broker_organization.broker_agency_profile }

        let!(:profile_factory)        { profile_factory_class.call(valid_broker_params_update) }

        before { broker_organization.reload }

        it 'should update broker organization legal name' do
          expect(broker_organization.legal_name).to eq new_organization_name
        end

        it 'should update phone number' do
          expect(broker_organization.broker_agency_profile.primary_office_location.phone.number).to eq phone_number
        end

        it 'should update address' do
          expect(broker_organization.broker_agency_profile.primary_office_location.address.city).to eq city
        end
      end

      context 'when type is general agency' do
        let(:office_location) { general_agency_profile.primary_office_location }
        let(:person) { FactoryBot.create :person }
        let!(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, person: person)}
        let(:general_agency_profile) { general_agency.general_agency_profile }
        let(:general_agency) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site) }
        let(:valid_ga_params_update) do
          {
            :current_user_id => current_user.id,
            :profile_type => "general_agency",
            :profile_id => general_agency_profile.id,
            :staff_roles_attributes =>
            {
              0 =>
              {
                :npn => general_agency_staff_role.npn,
                :first_name => "War 1",
                :last_name => "Art 1",
                :email => "warart@gmail.com",
                :phone => nil,
                :status => nil,
                :dob => dob,
                :person_id => person.id,
                :area_code => nil,
                :number => nil,
                :extension => nil,
                :profile_id => nil,
                :profile_type => nil
              }
            },
            :organization =>
            {
              :entity_kind => :s_corporation,
              :fein => general_agency.fein,
              :dba => "87987",
              :legal_name => new_organization_name,
              :profiles_attributes =>
              {
                0 =>
                {
                  :id => general_agency_profile.id,
                  :market_kind => :shop,
                  :home_page => "",
                  :accept_new_clients => "0",
                  :languages_spoken => ["", "en"],
                  :office_locations_attributes =>
                  {
                    0 =>
                    {
                      :is_primary => true,
                      :id => office_location.id,
                      :_destroy => "false",
                      :phone_attributes =>
                      {
                        :kind => "phone main",
                        :area_code => "786",
                        :number => phone_number,
                        :extension => "",
                        :id => office_location.phone.id
                      },
                      :address_attributes =>
                      {
                        :address_1 => "H",
                        :address_2 => "Wash",
                        :city => city,
                        :kind => "primary",
                        :state => "DC",
                        :zip => "20024",
                        :county => nil,
                        :id => office_location.address.id
                      }
                    }
                  }
                }
              }
            }
          }
        end

        let!(:profile_factory) { profile_factory_class.call(valid_ga_params_update) }

        before { general_agency.reload }

        it 'should update broker organization legal name' do
          expect(general_agency.legal_name).to eq new_organization_name
        end

        it 'should update phone number' do
          expect(general_agency.general_agency_profile.primary_office_location.phone.number).to eq phone_number
        end

        it 'should update address' do
          expect(general_agency.general_agency_profile.primary_office_location.address.city).to eq city
        end
      end
    end
  end
end
