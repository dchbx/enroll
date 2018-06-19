require 'rails_helper'

RSpec.describe Organization, dbclean: :after_each do
  it { should validate_presence_of :legal_name }
  it { should validate_presence_of :fein }
  it { should validate_presence_of :office_locations }

  let(:legal_name) {"Acme Brokers, Inc"}
  let(:fein) {"065872626"}
  let(:bad_fein) {"123123"}
  let(:office_locations) {FactoryGirl.build(:office_locations)}
  let(:invoice) { FactoryGirl.create(:document) }
  let(:org) { FactoryGirl.create(:organization) }
  let(:file_path){ "test/hbxid_01012001_invoice_R.pdf"}
  let(:valid_file_names){ ["hbxid_01012001_invoice_R.pdf","hbxid_04012014_invoice_R.pdf","hbxid_10102001_invoice_R.pdf"] }

  let(:fein_error_message) {"#{bad_fein} is not a valid FEIN"}

  let(:valid_office_location_attributes) do
    {
      address: FactoryGirl.build(:address, kind: "work"),
      phone: FactoryGirl.build(:phone, kind: "work")
    }
  end

  let(:valid_params) do
    {
      legal_name: legal_name,
      fein: fein,
      office_locations: [valid_office_location_attributes]
    }
  end

  describe ".create" do
    context "with valid arguments" do
      let(:params) {valid_params}
      let(:organization) {Organization.create(**params)}
      before do
        organization.valid?
      end

      it "should have assigned an hbx_id" do
        expect(organization.hbx_id).not_to eq nil
      end

      context "and a second organization is created with the same fein" do
        let(:organization2) {Organization.create(**params)}
        before do
          organization2.valid?
        end

        context "the second organization" do
          it "should not be valid" do
             expect(organization2.valid?).to be false
          end

          it "should have an error on fein" do
            expect(organization2.errors[:fein].any?).to be true
          end

          it "should not have the same id as the first organization" do
            expect(organization2.id).not_to eq organization.id
          end
        end
      end
    end
  end


  describe ".new" do

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(Organization.new(**params).save).to be_falsey
      end
    end

    context "with all valid arguments" do
      let(:params) {valid_params}

      it "should save" do
        expect(Organization.new(**params).save).to be_truthy
      end
    end

    context "with no legal_name" do
      let(:params) {valid_params.except(:legal_name)}

      it "should fail validation" do
        expect(Organization.create(**params).errors[:legal_name].any?).to be_truthy
      end
    end

    context "with no fein" do
      let(:params) {valid_params.except(:fein)}

      it "should fail validation" do
        expect(Organization.create(**params).errors[:fein].any?).to be_truthy
      end
    end

    context "with no office_locations" do
      let(:params) {valid_params.except(:office_locations)}

      it "should fail validation" do
        expect(Organization.create(**params).errors[:office_locations].any?).to be_truthy
      end
    end

   context "with invalid fein" do
      let(:params) {valid_params.deep_merge({fein: bad_fein})}

      it "should fail validation" do
        expect(Organization.create(**params).errors[:fein]).to eq [fein_error_message]
      end
    end
  end

  describe "class method", dbclean: :after_each do
    let(:organization1) {FactoryGirl.create(:organization, legal_name: "Acme Inc")}
    let!(:carrier_profile_1) {FactoryGirl.create(:carrier_profile, with_service_areas: 0, organization: organization1, issuer_hios_ids: ['11111'])}
    let(:organization2) {FactoryGirl.create(:organization, legal_name: "Turner Inc")}
    let!(:carrier_profile_2) {FactoryGirl.create(:carrier_profile, with_service_areas: 0, organization: organization2, issuer_hios_ids: ['22222'])}
    let(:single_choice_organization) {FactoryGirl.create(:organization, legal_name: "Restricted Options")}
    let!(:sole_source_participater) { create(:carrier_profile, with_service_areas: 0, organization: single_choice_organization, offers_sole_source: true) }

    let!(:carrier_one_service_area) { create(:carrier_service_area, service_area_zipcode: '10001', issuer_hios_id: carrier_profile_1.issuer_hios_ids.first) }
    let(:address) { double(zip: '10001', county: 'County', state: Settings.aca.state_abbreviation) }
    let(:office_location) { double(address: address)}
    let(:carrier_plan) { instance_double(Plan, active_year: '2017', is_sole_source: true, is_vertical: false, is_horizontal: false) }

    before :each do
      Rails.cache.clear
    end

    context "carrier_names" do
      before :each do
        allow(Plan).to receive(:valid_shop_health_plans).and_return([carrier_plan])
      end

      context "base case" do
        it "valid_carrier_names" do
          carrier_names = {}
          carrier_names[carrier_profile_1.id.to_s] = carrier_profile_1.legal_name
          carrier_names[carrier_profile_2.id.to_s] = carrier_profile_2.legal_name
          carrier_names[sole_source_participater.id.to_s] = sole_source_participater.legal_name
          expect(Organization.valid_carrier_names).to match_array carrier_names
        end

        it "valid_carrier_names_for_options" do
          carriers = [[carrier_profile_1.legal_name, carrier_profile_1.id.to_s], [carrier_profile_2.legal_name, carrier_profile_2.id.to_s],[sole_source_participater.legal_name, sole_source_participater.id.to_s]]
          expect(Organization.valid_carrier_names_for_options).to match_array carriers
        end

        it "valid_carrier_names_for_options passes arguments and filters to sole source only" do
          carriers = [[sole_source_participater.legal_name, sole_source_participater.id.to_s]]
          expect(Organization.valid_carrier_names_for_options(sole_source_only: true)).to match_array carriers
        end

        it "can filter out by service area" do
          carrier_names = {}
          carrier_names[carrier_profile_1.id.to_s] = carrier_profile_1.legal_name
          carrier_names[sole_source_participater.id.to_s] = sole_source_participater.legal_name

          expect(Organization.valid_carrier_names(primary_office_location: office_location)).to match_array carrier_names
        end
      end

      context "when limiting carriers to service area and coverage selection level and active year" do
        before do
          allow(CarrierServiceArea).to receive(:valid_for_carrier_on).and_return([])
          allow(CarrierServiceArea).to receive(:valid_for_carrier_on).with(address: address, carrier_profile: carrier_profile_1, year: 2017).and_return([carrier_one_service_area])
          allow(CarrierServiceArea).to receive(:valid_for_carrier_on).with(address: address, carrier_profile: carrier_profile_1, year: 2018).and_return([carrier_one_service_area])
          allow(CarrierServiceArea).to receive(:valid_for_carrier_on).with(address: address, carrier_profile: sole_source_participater, year: 2018).and_return([carrier_one_service_area])
          allow(Plan).to receive(:valid_shop_health_plans).with("carrier", carrier_profile_2.id, 2017).and_return([])
          allow(Plan).to receive(:valid_shop_health_plans).with("carrier", sole_source_participater.id, 2017).and_return([])
          allow(Plan).to receive(:valid_shop_health_plans).with("carrier", sole_source_participater.id, 2018).and_return([carrier_plan])
          allow(Plan).to receive(:valid_shop_health_plans).with("carrier", carrier_profile_1.id, 2017).and_return([carrier_plan])
          allow(Plan).to receive(:valid_shop_health_plans).with("carrier", carrier_profile_1.id, 2018).and_return([carrier_plan])
        end

        it "returns carriers if they are available in the service area and offer plans for that coverage level" do
          carrier_names = {}
          multiple_carriers = {}
          carrier_names[carrier_profile_1.id.to_s] = carrier_profile_1.legal_name
          multiple_carriers[carrier_profile_1.id.to_s] = carrier_profile_1.legal_name
          multiple_carriers[sole_source_participater.id.to_s] = sole_source_participater.legal_name
          expect(Organization.valid_carrier_names(primary_office_location: office_location, active_year: 2017, selected_carrier_level: 'sole_source')).to match_array carrier_names
          expect(Organization.valid_carrier_names(primary_office_location: office_location, active_year: 2018, selected_carrier_level: 'sole_source')).to match_array multiple_carriers
        end

        it "returns no carriers if there are no matches" do
          expect(Organization.valid_carrier_names(primary_office_location: office_location, active_year: 2017, selected_carrier_level: 'metal_level')).to match_array []
          expect(Organization.valid_carrier_names(primary_office_location: office_location, active_year: 2017, selected_carrier_level: 'single_plan')).to match_array []
        end
      end
    end

    context "binder_paid" do
      let(:address)  { Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County") }
      let(:phone  )  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
      let(:office_location) { OfficeLocation.new(
          is_primary: true,
          address: address,
          phone: phone
        )
      }
      let(:organization) { Organization.create(
        legal_name: "Sail Adventures, Inc",
        dba: "Sail Away",
        fein: "001223833",
        office_locations: [office_location]
        )
      }
      let(:valid_params) do
        {
          organization: organization,
          entity_kind: "partnership",
          sic_code: '1111'
        }
      end
      let(:renewing_plan_year)    { FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.next_month.beginning_of_month - 1.year, end_on: TimeKeeper.date_of_record.end_of_month, aasm_state: 'renewing_enrolling') }
      let(:new_plan_year)    { FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.next_month.beginning_of_month , end_on: TimeKeeper.date_of_record.end_of_month + 1.year, aasm_state: 'enrolling') }
      let(:new_employer)     { EmployerProfile.new(**valid_params, plan_years: [new_plan_year]) }
      let(:renewing_employer)     { EmployerProfile.new(**valid_params, plan_years: [renewing_plan_year]) }

      before do
        renewing_employer.save!
        new_employer.save!
      end

      it "should return correct number of records" do
       expect(Organization.retrieve_employers_eligible_for_binder_paid.size).to eq 1
     end
    end
  end

  describe "Broker Agency Search" do
    let(:agency_1) { FactoryGirl.create(:broker_agency, :shop_only, legal_name: "Health Brokers Inc") }
    let(:agency_2) { FactoryGirl.create(:broker_agency, :shop_only, legal_name: "DC Health Inc") }

    context ".scopes" do
      context 'approved_broker_agencies' do

        before do
          agency_1.broker_agency_profile.approve!
        end

        it 'should return apporved broker agencies' do
          expect(Organization.approved_broker_agencies.count).to eq(1)
          expect(Organization.approved_broker_agencies[0]).to eq(agency_1)
        end
      end

      context 'broker_agencies_by_market_kind' do
        context "when individual market is enabled" do
          let(:agency_1) { FactoryGirl.create(:broker_agency, :ivl_only, legal_name: "IVL Health Brokers Inc") }
          let(:agency_2) { FactoryGirl.create(:broker_agency, :both_ivl_and_shop, legal_name: "IVL Health Brokers Inc") }

          before do
            stub_const("BrokerAgencyProfile::MARKET_KINDS", %W[individual shop both])
            agency_1.reload
            agency_2.reload
          end
          it 'should return individual market agencies' do
            expect(Organization.broker_agencies_by_market_kind(['individual', 'both']).count).to eq(2)
          end
        end
        context "when individual market is disabled" do
          let(:agency_1) { FactoryGirl.create(:broker_agency, :shop_only, legal_name: "SHOP Health Brokers Inc") }
          let(:agency_2) { FactoryGirl.create(:broker_agency, :shop_only, legal_name: "SHOP Health Brokers Inc 2") }

          before do
            stub_const("BrokerAgencyProfile::MARKET_KINDS", %W[shop])
            agency_1.reload
            agency_2.reload
          end
          it 'should return shop market agencies' do
            expect(Organization.broker_agencies_by_market_kind(['shop', 'both']).count).to eq(2)
          end
        end
      end

      context 'by_broker_agency_profile', dbclean: :after_each do
        let(:organization6)  {FactoryGirl.create(:organization, fein: "024897585", legal_name: "organization 6")}
        let(:broker_role6) { FactoryGirl.create(:broker_role)}
        let!(:broker_agency_profile)  {FactoryGirl.create(:broker_agency_profile, organization: organization6, primary_broker_role_id: broker_role6.id)}
        let!(:organization7)  {FactoryGirl.create(:organization, fein: "724897585", legal_name: "organization 7")}
        let!(:broker_agency_profile7)  {FactoryGirl.create(:broker_agency_profile, organization: organization7, primary_broker_role_id: broker_role7.id)}
        let(:broker_role7) { FactoryGirl.create(:broker_role)}
        let(:organization3)  {FactoryGirl.create(:organization, fein: "034267123")}

        it 'should match employers with active broker agency_profile' do
          organization3.create_employer_profile(entity_kind: "partnership", broker_agency_profile: broker_agency_profile, sic_code: '1111');
          employers = Organization.by_broker_agency_profile(broker_agency_profile.id)
          expect(employers.size).to eq(1)
        end

        it 'broker agency_profile match does not count unless active account' do
          employer = organization3.create_employer_profile(entity_kind: "partnership", broker_agency_profile: broker_agency_profile, sic_code: '1111');
          employers = Organization.by_broker_agency_profile(broker_agency_profile.id)
          expect(employers.size).to eq(1)
          employer = Organization.find(employer.organization.id).employer_profile
          employer.hire_broker_agency(broker_agency_profile7)
          employer.save
          employer = Organization.find(employer.organization.id).employer_profile
          employers = Organization.by_broker_agency_profile(broker_agency_profile.id)
          expect(employers.size).to eq(0)
        end
      end
    end

    context 'with advanced options' do

      before do
        agency_1.broker_agency_profile.approve!
        agency_2.broker_agency_profile.approve!
        agency_1.broker_agency_profile.primary_broker_role.update_attributes(broker_agency_profile_id: agency_1.broker_agency_profile.id)
        agency_1.broker_agency_profile.update_attributes(languages_spoken: ['en', 'fr', 'de'])
        agency_1.broker_agency_profile.primary_broker_role.approve!
        @agent1 = agency_1.broker_agency_profile.primary_broker_role.person

        agency_2.broker_agency_profile.primary_broker_role.update_attributes(broker_agency_profile_id: agency_2.broker_agency_profile.id)
        agency_2.broker_agency_profile.update_attributes({languages_spoken: ['bn', 'hi'], working_hours: true})
        agency_2.broker_agency_profile.primary_broker_role.approve!
        @agent2 = agency_2.broker_agency_profile.primary_broker_role.person
      end

      context ".search_agencies_by_criteria" do
        context 'when searched with legal name' do
          it 'should return matching agency' do
            agencies = Organization.search_agencies_by_criteria({q: 'DC'})
            expect(agencies.count).to eq(1)
            expect(agencies.first.legal_name).to eq(agency_2.legal_name)
          end
        end

        context 'when searched with multiple languages' do
          it 'should return matching agency' do
            agencies = Organization.search_agencies_by_criteria({languages: ['de', 'en']})
            expect(agencies.count).to eq(1)
            expect(agencies.first.legal_name).to eq(agency_1.legal_name)

            agencies = Organization.search_agencies_by_criteria({languages: ['bn', 'de']})
            expect(agencies.count).to eq(2)
            expect(agencies.map(&:legal_name)).to eq([agency_2.legal_name, agency_1.legal_name])
          end
        end

        context 'when searched with weekend hours' do
          it 'should return matching agency' do
            agencies = Organization.search_agencies_by_criteria({working_hours: 'true'})
            expect(agencies.count).to eq(1)
            expect(agencies.first.legal_name).to eq(agency_2.legal_name)
          end
        end

        context 'when searched by name, languages, weekend hours' do
          it 'should return matching agency' do
            agencies = Organization.search_agencies_by_criteria({ q: 'Brokers', working_hours: 'true' })
            expect(agencies.count).to eq(0)

            agencies = Organization.search_agencies_by_criteria({ q: 'Brokers', working_hours: 'false' })
            expect(agencies.count).to eq(1)
            expect(agencies.first.legal_name).to eq(agency_1.legal_name)

            agencies = Organization.search_agencies_by_criteria({ q: 'Health', languages: ['bn'], working_hours: 'true' })
            expect(agencies.count).to eq(1)
            expect(agencies.first.legal_name).to eq(agency_2.legal_name)

            agencies = Organization.search_agencies_by_criteria({ q: 'Health', languages: ['bn', 'en'] })
            expect(agencies.count).to eq(2)
            expect(agencies.map(&:legal_name)).to eq([agency_2.legal_name, agency_1.legal_name])

            agencies = Organization.search_agencies_by_criteria({ q: 'Health', languages: ['bn', 'en'], working_hours: 'false' })
            expect(agencies.count).to eq(1)
            expect(agencies.first.legal_name).to eq(agency_1.legal_name)

            agencies = Organization.search_agencies_by_criteria({ languages: ['bn', 'en'], working_hours: 'false' })
            expect(agencies.count).to eq(1)
            expect(agencies.first.legal_name).to eq(agency_1.legal_name)
          end
        end
      end

      context ".broker_agencies_with_matching_agency_or_broker" do
        context 'when searching by broker name and npn' do
          it 'should return matching broker instead of agency' do
            agencies = Organization.broker_agencies_with_matching_agency_or_broker({q: @agent2.last_name})
            expect(agencies.count).to eq(1)
            expect(agencies.first).to eq(@agent2)

            agencies = Organization.broker_agencies_with_matching_agency_or_broker({q: @agent1.broker_role.npn})
            expect(agencies.count).to eq(1)
            expect(agencies.first).to eq(@agent1)
          end
        end

        context 'when searching by broker name and agency languages' do
          it 'should return matching broker with matching agency criteria' do
            agencies = Organization.broker_agencies_with_matching_agency_or_broker({q: @agent1.first_name})
            expect(agencies.count).to eq(2)

            agencies = Organization.broker_agencies_with_matching_agency_or_broker({q: @agent1.first_name, languages: ['bn'], working_hours: 'true'})
            expect(agencies.count).to eq(1)
            expect(agencies.first).to eq(@agent2)

            agencies = Organization.broker_agencies_with_matching_agency_or_broker({q: @agent1.first_name, working_hours: 'false'})
            expect(agencies.count).to eq(1)
            expect(agencies.first).to eq(@agent1)

            agencies = Organization.broker_agencies_with_matching_agency_or_broker({q: @agent1.first_name, languages: ['bn', 'en']})
            expect(agencies.count).to eq(2)
            expect(agencies).to include(@agent1)
            expect(agencies).to include(@agent2)
          end
        end

        context 'when searching by broker agency name, languages, hours' do
          it 'should return matching agencies' do
            agencies = Organization.broker_agencies_with_matching_agency_or_broker({ q: 'Brokers', working_hours: 'false' })
            expect(agencies.count).to eq(1)
            expect(agencies.first.legal_name).to eq(agency_1.legal_name)

            agencies = Organization.broker_agencies_with_matching_agency_or_broker({ q: 'Health', languages: ['bn'], working_hours: 'true' })
            expect(agencies.count).to eq(1)
            expect(agencies.first.legal_name).to eq(agency_2.legal_name)

            agencies = Organization.broker_agencies_with_matching_agency_or_broker({ q: 'Health', languages: ['bn', 'en'] })
            expect(agencies.count).to eq(2)
            expect(agencies.map(&:legal_name)).to eq([agency_2.legal_name, agency_1.legal_name])

            agencies = Organization.broker_agencies_with_matching_agency_or_broker({ q: 'Health', languages: ['bn', 'en'], working_hours: 'false' })
            expect(agencies.count).to eq(1)
            expect(agencies.first.legal_name).to eq(agency_1.legal_name)

            agencies = Organization.broker_agencies_with_matching_agency_or_broker({ languages: ['bn', 'en'], working_hours: 'false' })
            expect(agencies.count).to eq(1)
            expect(agencies.first.legal_name).to eq(agency_1.legal_name)
          end
        end
      end
    end
  end

  context "primary_office_location" do
    let(:organization) {FactoryGirl.build(:organization)}
    let(:office_location) {FactoryGirl.build(:office_location, :primary)}
    let(:office_location2) {FactoryGirl.build(:office_location, :primary)}

    it 'should save fail with more than one primary office_location' do
      organization.office_locations = [office_location, office_location2]
      expect(organization.save).to eq false
    end

    it "should save success with one primary office_location" do
      organization.office_locations = [office_location]
      expect(organization.save).to eq true
    end
  end

  context "primary_mailing_address" do
    let!(:organization) {FactoryGirl.build(:organization)}
    let!(:office_location) {FactoryGirl.build(:office_location, :with_mailing_address)}

    before :each do
      organization.office_locations = [office_location]
      organization.primary_mailing_address
    end

    it 'should return a valid primary_mailing_address for organization' do
      expect(organization.primary_mailing_address).to eq office_location.address
      expect(organization.primary_mailing_address.kind).to eq "mailing"
    end

    it "should not return an invalid address" do
      expect(organization.primary_mailing_address.kind).not_to eq "branch"
    end
  end

  context "Invoice Upload" do
    let(:organization) {FactoryGirl.build(:organization, :hbx_id => 'hbxid')}
    before do
      allow(Aws::S3Storage).to receive(:save).and_return("urn:openhbx:terms:v1:file_storage:s3:bucket:invoices:asdds123123")
      allow(Organization).to receive(:by_invoice_filename).and_return(organization)
    end

    context "with valid arguments" do
      before do
        Organization.upload_invoice(file_path,valid_file_names.first)
      end
       it "should upload invoice to the organization" do
        expect(organization.documents.size).to eq 1
      end
    end
    context "with duplicate files" do

       it "should upload invoice to the organization only once" do
        Organization.upload_invoice(file_path,valid_file_names.first)
        Organization.upload_invoice(file_path,valid_file_names.first)
        expect(organization.documents.size).to eq 1
      end
    end

    context "without date in file name" do
      before do
        Organization.upload_invoice("test/hbxid_invoice_R.pdf",'dummyfile.pdf')
      end
       it "should Not Upload invoice" do
        expect(organization.documents.size).to eq 0
      end
    end
  end

  context "invoice_date" do
    context "with valid date in the file name" do
      it "should parse the date" do
        valid_file_names.each do | file_name |
          expect(Organization.invoice_date(file_name)).to be_an_instance_of(Date)
        end
      end
    end
  end

  describe "notify_legal_name_or_fein_change" do

    context "notify update" do
      let(:employer_profile) { FactoryGirl.build(:employer_profile) }
      let(:organization) {FactoryGirl.create(:organization, employer_profile:employer_profile)}
      let(:changed_fields) { ["legal_name", "version", "updated_at"] }
      let(:changed_fields1) { ["fein", "version", "updated_at"] }

      it "notify legal name updated" do
        organization.instance_variable_set(:@changed_fields, changed_fields)
        expect(organization).to receive(:notify).exactly(1).times
        organization.notify_legal_name_or_fein_change
      end

      it "notify fein updated" do
        organization.instance_variable_set(:@changed_fields, changed_fields1)
        expect(organization).to receive(:notify).exactly(1).times
        organization.notify_legal_name_or_fein_change
      end
    end
  end

  describe "legal_name_or_fein_change_attributes" do

    context "changed_attributes" do
      let(:employer_profile) { FactoryGirl.build(:employer_profile) }
      let(:organization) {FactoryGirl.create(:organization, employer_profile:employer_profile)}

      it "legal_name changed_attributes " do
        organization.legal_name = "test1"
        organization.save!
        expect(organization.instance_variable_get(:@changed_fields)).to eq ["legal_name", "version", "updated_at"]
      end

      it "fein changed_attributes" do
        organization.fein ="000000001"
        organization.save
        expect(organization.instance_variable_get(:@changed_fields)).to eq ["fein", "version", "updated_at"]
      end
    end
  end

  describe "check_legal_name_or_fein_changed?" do

    context "legal and fein change" do
      let(:employer_profile) { FactoryGirl.build(:employer_profile) }
      let(:organization) {FactoryGirl.create(:organization, employer_profile:employer_profile)}

      it "return true for legal name update" do
        expect(organization.legal_name_changed?).to eq false #before update
        organization.legal_name = "test1"
        expect(organization.legal_name_changed?).to eq true #after update
        organization.save!
      end

      it "return true for fein update" do
        expect(organization.fein_changed?).to eq false
        organization.fein ="000000001"
        expect(organization.fein_changed?).to eq true
        organization.save
      end
    end
  end

  describe "check employer_attestations scopes" do
    context "employer attestation documents scope" do
      it "should return exact scope match records" do
        ["submitted","approved","pending","denied"].each do |state|
          FactoryGirl.create(:organization,
                             employer_profile: FactoryGirl.build(:employer_profile,
                                                                 employer_attestation:  FactoryGirl.build(:employer_attestation,{aasm_state: state})))
        end
        expect(Organization.employer_attestations_submitted[0].employer_profile.employer_attestation.aasm_state).to eq "submitted"
        expect(Organization.employer_attestations_pending[0].employer_profile.employer_attestation.aasm_state).to eq "pending"
        expect(Organization.employer_attestations_approved[0].employer_profile.employer_attestation.aasm_state).to eq "approved"
        expect(Organization.employer_attestations_denied[0].employer_profile.employer_attestation.aasm_state).to eq "denied"
      end
    end
  end

end
