require 'rails_helper'
require File.expand_path(
  File.join(
    File.dirname(__FILE__),
    "../../../",
    "support/benefit_sponsors_site_spec_helpers"
  )
)
require File.expand_path(
  File.join(
    File.dirname(__FILE__),
    "../../../",
    "support/benefit_sponsors_product_spec_helpers"
  )
)
require File.expand_path(
  File.join(
    File.dirname(__FILE__),
    "../../../",
    "support/benefit_sponsors_organization_spec_helpers"
  )
)

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::StaffRoleService, type: :model, :dbclean => :after_each do
    let!(:security_question)  { FactoryBot.create_default :security_question }

    let(:current_effective_date) { TimeKeeper.date_of_record }
    let(:site) do
      site = ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market
      benefit_market =  site.benefit_markets.first
      ::BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_and_previous_catalog(
        site,
        benefit_market,
        (current_effective_date.beginning_of_year..current_effective_date.end_of_year)
      )
      site
    end 
    let(:employer_organization)   do
      org_id = ::BenefitSponsors::OrganizationSpecHelpers.with_aca_shop_employer_profile(site)
      org = ::BenefitSponsors::Organizations::Organization.find(org_id)
    end
    let(:employer_profile)        { employer_organization.employer_profile }

    let(:broker_organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }

    let(:broker_agency_profile) { broker_organization.broker_agency_profile }
    let(:general_agency_organization) do 
      org_id = ::BenefitSponsors::OrganizationSpecHelpers.with_aca_shop_general_agency_profile(site)
      org = ::BenefitSponsors::Organizations::Organization.find(org_id)
    end
    let(:general_agency_profile) { general_agency_organization.general_agency_profile }
    let(:primary_general_agency_staff_role) {FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, is_primary: true, aasm_state: 'active')}

    # let!(:employer_profile) {benefit_sponsor.employer_profile}
    let(:active_employer_staff_role) {FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
    let(:person) { FactoryBot.create(:person, employer_staff_roles: [active_employer_staff_role]) }
    let(:broker_agency_staff_role) {FactoryBot.build(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id)}
    let(:active_employer_staff_role) {FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
    let(:broker_person) { FactoryBot.create(:person) }
    let(:user) { FactoryBot.create(:user, :person => person)}

    describe ".find_profile" do

      context "Employer profile" do
        let(:staff_role_form) do
          BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: employer_profile.id
          )
        end

        it 'should return employer profile' do
          expect(subject.find_profile(staff_role_form)).to eq employer_profile
        end
      end

      context "Broker Agency profile" do
        let(:staff_role_form) do
          BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(profile_id: broker_agency_profile.id,
                                                                               profile_type: "broker_agency_staff")
        end

        it 'should return employer profile' do
          expect(subject.find_profile(staff_role_form)).to eq broker_agency_profile
        end
      end
    end

    describe ".add_profile_representative!", dbclean: :after_each do

      context "adding staff role with non existing person" do

        let(:invalid_add_staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: employer_profile.id,
            first_name:'new_staff_first_name',
            last_name:'new_staff_first_name',
            dob:TimeKeeper.date_of_record)
        }

        it 'should not add staff role for profile' do
          expect(subject.add_profile_representative!(invalid_add_staff_role_form)).to eq [false,"Person does not exist on the HBX Exchange"]
        end
      end

      context "adding staff role with existing person" do

        let!(:new_person) { FactoryBot.create(:person) }
        let!(:add_staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: employer_profile.id,
            first_name:new_person.first_name,
            last_name:new_person.last_name,
            dob:Date.new(1972,04,04).to_s)
        }

        it 'should add staff role for profile' do
          expect(subject.add_profile_representative!(add_staff_role_form)).to eq [true, new_person]
        end
      end

      context "adding broker staff role for new person" do
        let!(:new_person) { FactoryBot.create(:person) }
        let(:staff_role_form) do
          BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(profile_id: broker_agency_profile.id,
                                                                               profile_type: "broker_agency_staff",
                                                                               first_name: new_person.first_name,
                                                                               last_name: new_person.last_name,
                                                                               dob: new_person.dob.to_s,
                                                                               email: "steve@gmail.com")
        end

        it 'should add broker staff role for broker agency profile' do
          expect(subject.add_profile_representative!(staff_role_form)).to eq [true, new_person]
        end
      end

      context "adding person to broker agency in which he is already a staff" do
        before do
          person.broker_agency_staff_roles << broker_agency_staff_role
        end
        let(:staff_role_form) do
          BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(profile_id: broker_agency_profile.id,
                                                                               profile_type: "broker_agency_staff",
                                                                               first_name: person.first_name,
                                                                               last_name: person.last_name,
                                                                               dob: person.dob.to_s,
                                                                               email: "steve@gmail.com")
        end


        it 'should not add broker staff role' do
          expect(subject.add_profile_representative!(staff_role_form)).to eq [false, "you are already associated with this Broker Agency"]
        end
      end

      context "adding general agency staff role for new person" do
        before do
          person.general_agency_staff_roles << primary_general_agency_staff_role
        end
        let!(:new_person) { FactoryBot.create(:person) }
        let(:staff_role_form) do
          BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(profile_id: general_agency_profile.id,
                                                                               profile_type: "general_agency_staff",
                                                                               first_name: new_person.first_name,
                                                                               last_name: new_person.last_name,
                                                                               dob: new_person.dob.to_s,
                                                                               email: "steve@gmail.com")
        end

        it 'should add ga staff role for general agency profile' do
          expect(subject.add_profile_representative!(staff_role_form)).to eq [true, new_person]
        end
      end

      context "adding person to general agency in which he is already a staff" do
        before do
          person.general_agency_staff_roles << primary_general_agency_staff_role
        end
        let(:staff_role_form) do
          BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(profile_id: general_agency_profile.id,
                                                                               profile_type: "general_agency_staff",
                                                                               first_name: person.first_name,
                                                                               last_name: person.last_name,
                                                                               dob: person.dob.to_s,
                                                                               email: "steve@gmail.com")
        end


        it 'should not add ga staff role' do
          expect(subject.add_profile_representative!(staff_role_form)).to eq [false, "you are already associated with this General Agency"]
        end
      end
    end

    describe ".deactivate_profile_representative!", dbclean: :after_each do

      context "employer profile with one staff role." do

        let!(:deactivate_staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: employer_profile.id,
            first_name:person.first_name,
            last_name:person.last_name,
            dob:person.dob.to_s,
            person_id:person.id)
        }

        it 'should not deactivate only staff role' do
          expect(subject.deactivate_profile_representative!(deactivate_staff_role_form)).to eq [false,"Please add another staff role before deleting this role"]
        end
      end

      context "employer profile more than one staff role." do
        before :each do
          user
        end

        let!(:another_person_active_employer_staff_role) {FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
        let!(:another_person) { FactoryBot.create(:person, employer_staff_roles:[another_person_active_employer_staff_role]) }
        let!(:deactivate_staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: employer_profile.id,
            first_name:another_person.first_name,
            last_name:another_person.last_name,
            dob:another_person.dob.to_s,
            person_id:another_person.id)
        }

        it 'should deactivate staff role' do
          expect(subject.deactivate_profile_representative!(deactivate_staff_role_form)).to eq [true,"Employee Staff Role is inactive"]
        end
      end
    end

    describe ".approve_profile_representative!", dbclean: :after_each do

      context "staff role with applicant status" do

        let!(:another_person_active_employer_staff_role) {FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_applicant', benefit_sponsor_employer_profile_id: employer_profile.id)}
        let!(:another_person) { FactoryBot.create(:person, employer_staff_roles:[another_person_active_employer_staff_role]) }
        let!(:approve_staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: employer_profile.id,
            first_name:another_person.first_name,
            last_name:another_person.last_name,
            dob:another_person.dob.to_s,
            person_id:another_person.id)
        }

        it 'should approve staff role' do
          expect(subject.approve_profile_representative!(approve_staff_role_form)).to eq [true,"Role is approved"]
          another_person_active_employer_staff_role.reload
          expect(another_person_active_employer_staff_role.aasm_state).to eq "is_active"
        end
      end

      context "staff role with is_closed status" do

        let!(:another_person_active_employer_staff_role) {FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_closed', benefit_sponsor_employer_profile_id: employer_profile.id)}
        let!(:another_person) { FactoryBot.create(:person, employer_staff_roles:[another_person_active_employer_staff_role]) }
        let!(:approve_staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: employer_profile.id,
            first_name:another_person.first_name,
            last_name:another_person.last_name,
            dob:another_person.dob.to_s,
            person_id:another_person.id)
        }

        it 'should not approve staff role' do
          expect(subject.approve_profile_representative!(approve_staff_role_form)).to eq [false, "Please contact HBX Admin to report this error"]
        end
      end

    end

    describe ".match_or_create_person", dbclean: :after_each do
      context 'when more than 1 person matched' do
        before :each do
          2.times { FactoryBot.create(:person, first_name: "steve", last_name: "smith", dob: "10/10/1974") }
        end

        let(:staff_role_form) do
          BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(profile_id: broker_agency_profile.id,
                                                                               profile_type: "broker_agency_staff",
                                                                               first_name: "steve",
                                                                               last_name: "smith",
                                                                               dob: "10/10/1974")
        end
        it "should raise an exception" do
          expect(subject.match_or_create_person(staff_role_form)).to eq [false, "too many people match the criteria provided for your identity.  Please contact HBX."]
        end
      end

      context 'when no person matched' do
        let(:staff_role_form) do
          BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(profile_id: broker_agency_profile.id,
                                                                               profile_type: "broker_agency_staff",
                                                                               first_name: "steve",
                                                                               last_name: "smith",
                                                                               dob: "10/10/1974",
                                                                               email: "steve@gmail.com")
        end
        it "should build a new person" do
          expect(subject.match_or_create_person(staff_role_form)).to eq true
          expect(subject.person.first_name).to eq "steve"
        end
      end

      context 'when only one person matched' do
        let(:staff_role_form) do
          BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(profile_id: broker_agency_profile.id,
                                                                               profile_type: "broker_agency_staff",
                                                                               first_name: person.first_name,
                                                                               last_name: person.last_name,
                                                                               dob: person.dob,
                                                                               email: "steve@gmail.com")
        end
        it "form should assign person to exisiting person" do
          expect(subject.match_or_create_person(staff_role_form)).to eq true
          expect(subject.person.first_name).to eq person.first_name
        end
      end
    end

    describe ".broker_agency_search!", dbclean: :after_each do

      before do
        Person.create_indexes
      end

      context 'when broker agency profile is in approved state' do

        let(:staff_role_form) do
          BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(filter_criteria: {"q" => broker_agency_profile.legal_name},
                                                                               is_broker_registration_page: "true")
        end
        # flaky test
        xit "should return result if broker profile is approved" do
          broker_agency_profile.update_attributes!(aasm_state: "is_approved")
          expect(subject.broker_agency_search!(staff_role_form)).to eq [broker_agency_profile]
        end
      end

      context 'when broker agency profile is not in approved state' do
        let(:staff_role_form) do
          BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(filter_criteria: {"q" => broker_agency_profile.legal_name},
                                                                               is_broker_registration_page: "true")
        end
        xit "should return empty result if broker profile is not approved" do
          expect(subject.broker_agency_search!(staff_role_form)).to eq []
        end
      end

    end

    describe ".general_agency_search!", dbclean: :after_each do

      before :each do
        Person.create_indexes
      end

      context 'when general agency profile is in approved state' do

        let(:staff_role_form) do
          BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(filter_criteria: {"q" => general_agency_profile.legal_name},
                                                                               is_general_agency_registration_page: "true")
        end
        # flaky test
        xit "should return result if general agency profile is approved" do
          general_agency_profile.update_attributes!(aasm_state: "is_approved")
          expect(subject.general_agency_search!(staff_role_form)).to eq [general_agency_profile]
        end
      end

      context 'when general agency profile is not in approved state' do
        let(:staff_role_form) do
          BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(filter_criteria: {"q" => general_agency_profile.legal_name},
                                                                               is_general_agency_registration_page: "true")
        end
        xit "should return empty result if general agency profile is not approved" do
          expect(subject.general_agency_search!(staff_role_form)).to eq []
        end
      end

    end

    describe ".add_broker_agency_staff_role", dbclean: :after_each  do

      let!(:broker_organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }

      let(:broker_agency_profile) { broker_organization.broker_agency_profile }
      let(:person_params) {{first_name: Forgery('name').first_name, last_name: Forgery('name').first_name, dob: '1990/05/01'}}
      let(:person1) {FactoryBot.create(:person, person_params)}

      context 'duplicate person PII' do
        before do
          FactoryBot.create(:person, person_params)
          @status, @result = subject.add_broker_agency_staff_role(person1.first_name, person1.last_name, person1.dob,'#default@email.com', broker_agency_profile)
        end
        it 'returns false' do
          expect(@status).to eq false
        end

        it 'returns msg' do
          expect(@result).to be_instance_of String
        end
      end

      context 'zero matching person PII' do
        before {@status, @result = subject.add_broker_agency_staff_role('sam', person1.last_name, person1.dob,'#default@email.com', broker_agency_profile)}

        it 'returns false' do
          expect(@status).to eq false
        end

        it 'returns msg' do
          expect(@result).to be_instance_of String
        end
      end

      context 'matching one person PII' do
        before {@status, @result = subject.add_broker_agency_staff_role(person1.first_name, person1.last_name, person1.dob,'#default@email.com', broker_agency_profile)}

        it 'returns true' do
          expect(@status).to eq true
        end

        it 'returns the person' do
          expect(@result).to eq person1
        end
      end

      context 'person already has broker role with this broker agency' do
        before do
          subject.add_broker_agency_staff_role(person1.first_name, person1.last_name, person1.dob,'#default@email.com', broker_agency_profile)
          @status, @result = subject.add_broker_agency_staff_role(person1.first_name, person1.last_name, person1.dob,'#default@email.com', broker_agency_profile)
        end

        it 'returns false' do
          expect(@status).to eq false
        end

        it 'returns the person' do
          expect(@result).to be_instance_of String
        end
      end
    end

    describe ".add_general_agency_staff_role", dbclean: :after_each  do
      let(:person_params) {{first_name: Forgery('name').first_name, last_name: Forgery('name').first_name, dob: '1990/05/01'}}
      let(:person1) {FactoryBot.create(:person, person_params)}

      context 'duplicate person PII' do
        before do
          FactoryBot.create(:person, person_params)
          @status, @result = subject.add_general_agency_staff_role(person1.first_name, person1.last_name, person1.dob,'#default@email.com', general_agency_profile)
        end
        it 'returns false' do
          expect(@status).to eq false
        end

        it 'returns msg' do
          expect(@result).to be_instance_of String
        end
      end

      context 'zero matching person PII' do
        before do
          broker_agency_staff_role 
          @status, @result = subject.add_general_agency_staff_role('sam', person1.last_name, person1.dob,'#default@email.com', general_agency_profile)
        end

        it 'returns false' do
          expect(@status).to eq false
        end

        it 'returns msg' do
          expect(@result).to be_instance_of String
        end
      end

      context 'matching one person PII' do
        before do
          primary_general_agency_staff_role
          @status, @result = subject.add_general_agency_staff_role(person1.first_name, person1.last_name, person1.dob,'#default@email.com', general_agency_profile)
        end

        it 'returns true' do
          expect(@status).to eq true
        end

        it 'returns the person' do
          expect(@result).to eq person1
        end
      end

      context 'person already has general agency staff role with this general agency' do
        before do
          primary_general_agency_staff_role
          subject.add_general_agency_staff_role(person1.first_name, person1.last_name, person1.dob,'#default@email.com', general_agency_profile)
          @status, @result = subject.add_general_agency_staff_role(person1.first_name, person1.last_name, person1.dob,'#default@email.com', general_agency_profile)
        end

        it 'returns false' do
          expect(@status).to eq false
        end

        it 'returns the person' do
          expect(@result).to be_instance_of String
        end
      end
    end

    describe ".deactivate_broker_agency_staff_role" do
      let(:person) {FactoryBot.create(:person)}
      let!(:broker_organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }

      let(:broker_agency_profile) { broker_organization.broker_agency_profile }
      let!(:broker_organization_second)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }

      let(:broker_agency_profile_second) { broker_organization_second.broker_agency_profile }
      before do
        FactoryBot.create(:broker_agency_staff_role, broker_agency_profile_id: broker_agency_profile.id, person: person, broker_agency_profile: broker_agency_profile, aasm_state: 'active')
      end

      context 'finds the person and deactivates the role' do
        before do
          @status, @result = subject.deactivate_broker_agency_staff_role(person.id, broker_agency_profile.id)
        end
        it 'returns true' do
          expect(@status).to be true
        end

        it 'returns msg' do
          expect(@result).to be_instance_of String
        end

        it 'should terminate broker agency staff role' do
          expect(person.reload.broker_agency_staff_roles.first.aasm_state).to eq "broker_agency_terminated"
        end
      end

      context 'person does not have broker agency staff role' do
        before do
          @status, @result = subject.deactivate_broker_agency_staff_role(person.id, broker_agency_profile_second.id)
        end
        it 'returns false' do
          expect(@status).to eq false
        end

        it 'returns msg' do
          expect(@result).to be_instance_of String
        end

        it 'should not terminate other broker agency staff role' do
          expect(person.reload.broker_agency_staff_roles.first.aasm_state).to eq "active"
        end
      end
    end

    describe ".deactivate_general_agency_staff_role" do
      let(:person) {FactoryBot.create(:person)}
      let!(:ga_organization)  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
      let(:general_agency_profile) { ga_organization.general_agency_profile }
      let!(:ga_organization_second) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
      let(:general_agency_profile_second) { ga_organization_second.general_agency_profile }
      before do
        FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, person: person, general_agency_profile: general_agency_profile, aasm_state: 'active')
      end

      context 'finds the person and deactivates the role' do
        before do
          @status, @result = subject.deactivate_general_agency_staff_role(person.id, general_agency_profile.id)
        end
        it 'returns true' do
          expect(@status).to be true
        end

        it 'returns msg' do
          expect(@result).to be_instance_of String
        end

        it 'should terminate general agency staff role' do
          expect(person.reload.general_agency_staff_roles.first.aasm_state).to eq "general_agency_terminated"
        end
      end

      context 'person does not have general agency staff role' do
        before do
          @status, @result = subject.deactivate_general_agency_staff_role(person.id, general_agency_profile_second.id)
        end
        it 'returns false' do
          expect(@status).to eq false
        end

        it 'returns msg' do
          expect(@result).to be_instance_of String
        end

        it 'should not terminate other broker agency staff role' do
          expect(person.reload.general_agency_staff_roles.first.aasm_state).to eq "active"
        end
      end
    end
  end
end
