require 'rails_helper'

module BenefitSponsors

  RSpec.describe Organizations::OrganizationForms::RegistrationForm, type: :model, dbclean: :after_each do
    let!(:site)  { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, :cca) }
    let!(:benefit_market)  { benefit_market = site.benefit_markets.first
                              benefit_market.save }
    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
    let!(:service_area)                 { FactoryGirl.create_default :benefit_markets_locations_service_area }

    subject { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm }

    describe '#for_new' do

      context "profile_type = benefit_sponsor" do

        it 'instantiates a new registration form for employer profile' do
          form = subject.for_new(profile_type:"benefit_sponsor")
          expect(form.profile_type).to eq 'benefit_sponsor'
          expect(form.profile_id).to eq nil
          expect(form.organization).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::OrganizationForm)
          expect( form.organization.profile.parent).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::OrganizationForm)
          expect(form.organization.profile).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::ProfileForm)
          expect(form.organization.profile.inbox).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::InboxForm)
          expect(form.organization.profile.office_locations.first).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::OfficeLocationForm)
          expect(form.staff_roles.first).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm)
        end
      end

      context "profile_type = broker_agency" do

        it 'instantiates a new registration form for broker agency profile' do
          form = subject.for_new(profile_type:"broker_agency")
          expect(form.profile_type).to eq 'broker_agency'
          expect(form.profile_id).to eq nil
          expect(form.organization).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::OrganizationForm)
          expect(form.organization.profile.parent).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::OrganizationForm)
          expect(form.organization.profile).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::ProfileForm)
          expect(form.organization.profile.inbox).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::InboxForm)
          expect(form.organization.profile.office_locations.first).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::OfficeLocationForm)
          expect(form.staff_roles.first).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm)
          expect(form.organization.profile.language_options.first).to be_an_instance_of(LanguageList::LanguageInfo)
        end
      end
    end

    shared_examples_for "should validate create_form and save profile" do |profile_type|
      let!(:security_question)  { FactoryGirl.create_default :security_question }

      let(:params) do
        {"profile_type"=>"#{profile_type}",
         "staff_roles_attributes"=>{
          "0"=>{
              "first_name"=>"first_name",
              "last_name"=>"last_name",
              "dob"=>"05/03/2000",
              "email"=>"email@gmail.com",
              "npn"=>"444411112",
              "area_code" => "123",
              "number" => "2341231"
            }
          },
         "organization"=>
             {"legal_name"=>"#{profile_type}",
              "dba"=>"",
              "fein"=>"123412341",
              "profile_attributes"=>
                  {"entity_kind"=>"s_corporation",
                   "sic_code"=>"0111",
                   "market_kind"=>"shop",
                   "languages_spoken"=>["", "en"],
                   "working_hours"=>"1",
                   "accept_new_clients"=>"1",
                   "office_locations_attributes"=>
                       {"0"=>
                            {"address_attributes"=>{"address_1"=>"new address", "kind"=>"primary", "address_2"=>"", "city"=>"ma_city", "state"=>"MA","zip"=>"01026", "county"=>"Berkshire"},
                             "phone_attributes"=>{"kind"=>"phone main", "area_code"=>"222", "number"=>"2221111", "extension"=>""}}},
                  "contact_method"=>"paper_and_electronic"}},
         "profile_id"=>nil,
         "current_user_id"=> profile_type == "benefit_sponsor" ? FactoryGirl.create(:user).id: nil}
      end

      before :each do
        params["organization"]["profile_attributes"].merge!(
            {
              "ach_account_number" => "1234567890",
              "ach_routing_number" => "011000015",
              "ach_routing_number_confirmation" => "011000015"
            }
        ) if profile_type == 'broker_agency'
      end

      let!(:create_form) { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_create params }

      it "create_form should be valid" do
        create_form.validate
        expect(create_form).to be_valid
      end

      it 'instantiates a create Form with the correct variables' do
        if profile_type == "benefit_sponsor"
          expect(create_form.profile_type).to eql('benefit_sponsor')
        else
          expect(create_form.profile_type).to eql('broker_agency')
        end
      end

      it 'has the primary office' do
        expect(create_form.organization.profile.office_locations.first.is_primary?).to be_truthy
      end

      it 'creates a new BenefitSponsors::Organizations::GeneralOrganization when saved' do
        if profile_type == "benefit_sponsor"
          expect { create_form.save }.to change { BenefitSponsors::Organizations::Organization.employer_profiles.count }.by(1)
          expect(BenefitSponsors::Organizations::Organization.employer_profiles.first.legal_name).to eq params["organization"]["legal_name"]
        else
          expect { create_form.save }.to change { BenefitSponsors::Organizations::Organization.broker_agency_profiles.count }.by(1)
          expect(BenefitSponsors::Organizations::Organization.broker_agency_profiles.first.legal_name).to eq params["organization"]["legal_name"]
        end
      end
    end

    describe '##for_create' do

      it_behaves_like "should validate create_form and save profile", "benefit_sponsor"
      it_behaves_like "should validate create_form and save profile", "broker_agency"

    end

    describe '##for_edit' do
      let!(:security_question)  { FactoryGirl.create_default :security_question }

      let!(:general_org) {FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)}
      let!(:employer_profile) {general_org.employer_profile}
      let!(:primary_office_location_address){employer_profile.primary_office_location.address }
      let!(:active_employer_staff_role) {FactoryGirl.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
      let(:broker_agency) {FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site)}
      let!(:broker_agency_profile) {broker_agency.broker_agency_profile}
      let!(:person) { FactoryGirl.create(:person, emails:[FactoryGirl.build(:email, kind:'work')],employer_staff_roles:[active_employer_staff_role]) }
      let(:user) { FactoryGirl.create(:user, :person => person)}

      before :each do
        primary_office_location_address.update_attributes!(kind: 'primary')
        broker_agency_profile.update_attributes!(ach_account_number: "1234567890", ach_routing_number: "011000015")
      end

      context "profile_type = benefit_sponsor" do

        let(:edit_form) { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_edit profile_id: employer_profile.id.to_s }

        it "update_form should be valid" do
          edit_form.validate
          expect(edit_form).to be_valid
        end

        it 'loads the employer profile in to the Registartion Form' do
          expect(edit_form.profile_type).to eql("benefit_sponsor")
          expect(edit_form.organization.legal_name).to eql(general_org.legal_name)
          expect(edit_form.staff_roles.first.first_name).to eql(person.first_name)
        end
      end

      context "profile_type = broker_agency" do

        let(:edit_form) { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_edit profile_id: broker_agency_profile.id.to_s }

        before do
          person.broker_role = BrokerRole.new(benefit_sponsors_broker_agency_profile_id:broker_agency_profile.id,provider_kind: "broker", npn:'12345678')
          person.save!
        end

        it 'loads the broker agency in to the Registartion Form' do
          expect(edit_form.profile_type).to eql("broker_agency")
          expect(edit_form.organization.legal_name).to eql(broker_agency.legal_name)
          expect(edit_form.profile_id).to eql(broker_agency_profile.id.to_s)
        end
      end
    end

    describe '##for_update' do
      let!(:security_question)  { FactoryGirl.create_default :security_question }
      let!(:general_org) {FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)}
      let!(:employer_profile) {general_org.employer_profile}
      let!(:active_employer_staff_role) {FactoryGirl.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
      let(:broker_agency) {FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site)}
      let!(:broker_agency_profile) {broker_agency.broker_agency_profile}
      let!(:person) { FactoryGirl.create(:person, emails:[FactoryGirl.build(:email, kind:'work')],employer_staff_roles:[active_employer_staff_role]) }
      let(:user) { FactoryGirl.create(:user, :person => person)}

      context "profile_type = benefit_sponsor" do

        let(:params) do
          {"organization"=>
               {"legal_name"=>"new_legal_name",
                "dba"=>"",
                "fein"=>"987654312",
                "profile_attributes"=>
                    {"id"=>employer_profile.id.to_s,
                     "sic_code"=>"0111",
                     "entity_kind"=>"c_corporation",
                     "office_locations_attributes"=>
                         {"0"=>
                              {"address_attributes"=>
                                   {"kind"=>"primary", "address_1"=>"new_address", "address_2"=>"", "city"=>"ma_city", "state"=>"MA", "zip"=>"01001"},
                               "phone_attributes"=>{"kind"=>"phone main", "area_code"=>"333", "number"=>"111-2222", "extension"=>"111"}}},
                     "contact_method"=>"paper_and_electronic"}},
           "profile_id"=>employer_profile.id.to_s,
           "current_user_id"=>BSON::ObjectId("#{user.id}")}
        end

        let!(:update_form) { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_update params }

        it "update_form should be valid" do
          update_form.validate
          expect(update_form).to be_valid
        end

        it "should assign the update params to Registartion forms" do
          expect(update_form.organization.legal_name).to eq params["organization"]["legal_name"]
          expect(update_form.organization.fein).to eq params["organization"]["fein"]
          expect(update_form.profile_id).to eq params["profile_id"]
        end

        it 'should update employer profile organization legal name' do
          update_form.update
          general_org.reload
          expect(general_org.legal_name).to eq params["organization"]["legal_name"]
        end
      end

      context "profile_type = broker_agency" do
        let(:params) do
          {"organization"=>
               {"legal_name"=>"new_legal_name",
                "dba"=>"",
                "fein"=>"123412341",
                "profile_attributes"=>
                    {"id"=>broker_agency_profile.id.to_s,
                     "entity_kind"=>"s_corporation",
                     "sic_code"=>"0111",
                     "ach_account_number"=>"1234567890",
                     "ach_routing_number"=>"011000015",
                     "ach_routing_number_confirmation"=>"011000015",
                     "market_kind"=>"shop",
                     "languages_spoken"=>["", "en"],
                     "working_hours"=>"1",
                     "accept_new_clients"=>"1",
                     "office_locations_attributes"=>
                         {"0"=>
                              {"address_attributes"=>{"address_1"=>"new address", "kind"=>"primary", "address_2"=>"", "city"=>"ma_city", "state"=>"MA", "zip"=>"01001", "county"=>"Hampden"},
                               "phone_attributes"=>{"kind"=>"phone main", "area_code"=>"222", "number"=>"2221111", "extension"=>""}}},
                     "contact_method"=>"paper_and_electronic"}},
           "profile_id"=>broker_agency_profile.id.to_s,
           "current_user_id"=> BSON::ObjectId("#{user.id}")}
        end

        let(:update_form) { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_update params }

        before do
          person.broker_role = BrokerRole.new(benefit_sponsors_broker_agency_profile_id:broker_agency_profile.id,provider_kind: "broker", npn:'12345678')
          person.save!
        end
        it "update_form should be valid" do
          update_form.validate
          expect(update_form).to be_valid
        end

        it "should assign the update params to Registartion forms" do
          expect(update_form.organization.legal_name).to eq params["organization"]["legal_name"]
          expect(update_form.organization.fein).to eq params["organization"]["fein"]
          expect(update_form.profile_id).to eq params["profile_id"]
        end

        it 'should update broker_agency organization legal name' do
          update_form.update
          broker_agency.reload
          expect(broker_agency.legal_name).to eq params["organization"]["legal_name"]
        end
      end
    end
  end
end
