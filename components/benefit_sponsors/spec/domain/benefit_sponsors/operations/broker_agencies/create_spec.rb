# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::BrokerAgencies::Create, dbclean: :after_each do

  describe 'Create' do

    let!(:site)  { FactoryBot.create(:benefit_sponsors_site, :with_owner_exempt_organization, :dc, :with_benefit_market) }
    let(:registration_params) do
      {
        :profile_type => "broker_agency",
        :staff_roles_attributes => {
          :"0" => {
            :first_name => "test",
            :last_name => "test",
            :dob => "11/11/1990",
            :email => "test@tst.com",
            :npn => "2983479237",
            :profile_type => "broker_agency"
          }
        },
        :organization => {
          :entity_kind => "s_corporation",
          :legal_name => "SOME BROKER",
          :dba => "broker",
          :profile => {
            :market_kind => "both",
            :languages_spoken => ["", "en"],
            :working_hours => "1",
            :accept_new_clients => "1",
            :office_locations_attributes => {
              :"0" => {
                :address => {
                  :address_1 => "test",
                  :kind => "primary",
                  :address_2 => "test",
                  :city => "test",
                  :state => "DC",
                  :zip => "23948"
                },
                :phone => {
                  :kind => "work",
                  :area_code => "234",
                  :number => "9284729"
                }
              }
            },
            :profile_type => "broker_agency"
          },
          :profile_type => "broker_agency"
        }
      }
    end


    subject do
      described_class.new.call(params)
    end

    context 'Failure' do
      context 'no params passed' do
        let(:params)  { {} }
        it 'should raise error if  no params are passed' do
          expect(subject).to be_failure
          expect(subject.failure).to eq({:text => "Invalid params", :error => {:profile_type => ["is missing"], :staff_roles_attributes => ["is missing"], :organization => ["is missing"]}})
        end
      end

      context 'params with invalid profile type passed' do
        let(:params)  { registration_params.merge(profile_type: 'test') }
        it 'should raise error if profile type is not passed' do
          expect(subject).to be_failure
          expect(subject.failure[:error][:profile_type]).to eq(["Invalid profile type"])
        end
      end
    end


    context 'success' do
      let(:person) {FactoryBot.create(:person)}

      context 'should create new organization' do
        let(:params)  { registration_params }

        it 'should create new broker agency profile and organization' do
          expect(subject).to be_success
          expect(BenefitSponsors::Organizations::Organization.all.count).to eq 2
          expect(BenefitSponsors::Organizations::Organization.broker_agency_profiles.all.count).to eq 1
        end
      end

      context 'should create new broker agency staff role for person' do
        let(:staff_roles_attributes) do
          {
            :"0" => {
              :first_name => "test",
              :last_name => "test",
              :dob => "11/11/1990",
              :email => "test@tst.com",
              :npn => "2983479237",
              :profile_type => "broker_agency"
            }
          }
        end
        let(:params)  { registration_params.merge(person_id: person.id.to_s, staff_roles_attributes: staff_roles_attributes) }

        it 'should create new open struct object with keys' do
          expect(subject).to be_success
          expect(BenefitSponsors::Organizations::Organization.broker_agency_profiles.all.count).to eq 1
          person.reload
          # expect(person.broker_agency_staff_roles.size).to eq 1
        end
      end
    end
  end
end
