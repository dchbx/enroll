require 'rails_helper'

module BenefitSponsors

  RSpec.describe Organizations::OrganizationForms::StaffRoleForm, type: :model, dbclean: :after_each do

    let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_sponsor) { create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_profile) { benefit_sponsor.employer_profile }
    let!(:broker_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let(:broker_agency_profile) { broker_organization.broker_agency_profile }
    let!(:broker_agency_staff_role) {FactoryBot.build(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id)}
    let!(:active_employer_staff_role) {FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
    let!(:person) { FactoryBot.create(:person, employer_staff_roles: [active_employer_staff_role]) }

    let!(:general_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
    let(:general_agency_profile) { general_agency_organization.general_agency_profile }
    let!(:general_agency_staff_role) {FactoryBot.build(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, is_primary: true)}

    let(:user) { FactoryBot.create(:user, :person => person)}

    subject { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm }

    describe "model attributes", dbclean: :after_each do
      it {
        [:npn, :first_name, :last_name, :email, :phone, :status, :dob, :person_id, :area_code, :number, :extension, :profile_id, :profile_type, :filter_criteria, :is_broker_registration_page, :is_general_agency_registration_page].each do |key|
          expect(subject.new.attributes.has_key?(key)).to be_truthy
        end
      }
    end

    describe "form object with profile_type" do

      context "#is_broker_profile? " do

        let!(:params) {
          {
              profile_type: 'broker_agency',
              first_name: person.first_name,
              last_name: person.last_name,
              dob: person.dob.to_s
          }
        }

        it "should return true" do
          expect(subject.new(params).is_broker_profile?).to eq true
        end

        it "should return false" do
          expect(subject.new(params).is_employer_profile?).to eq false
        end

        it "should return false" do
          expect(subject.new(params).is_broker_agency_staff_profile?).to eq false
        end

        it "should return false" do
          expect(subject.new(params).is_general_agency_staff_profile?).to eq false
        end
      end

      context "#is_employer_profile?? " do

        let!(:params) {
          {
              profile_type: 'benefit_sponsor',
              first_name: person.first_name,
              last_name: person.last_name,
              dob: person.dob.to_s
          }
        }

        it "should return true" do
          expect(subject.new(params).is_employer_profile?).to eq true
        end

        it "should return false" do
          expect(subject.new(params).is_broker_profile?).to eq false
        end

        it "should return false" do
          expect(subject.new(params).is_broker_agency_staff_profile?).to eq false
        end
      end

      context "#is_broker_agency_staff_profile?" do

        let!(:params) do
          {
            profile_type: 'broker_agency_staff',
            first_name: person.first_name,
            last_name: person.last_name,
            dob: person.dob.to_s
          }
        end

        it "should return true" do
          expect(subject.new(params).is_broker_agency_staff_profile?).to eq true
        end

        it "should return false" do
          expect(subject.new(params).is_broker_profile?).to eq false
        end

        it "should return false" do
          expect(subject.new(params).is_employer_profile?).to eq false
        end
      end

      context "#is_general_agency_staff_profile?" do

        let!(:params) do
          {
            profile_type: 'general_agency_staff',
            first_name: person.first_name,
            last_name: person.last_name,
            dob: person.dob.to_s
          }
        end

        it "should return true" do
          expect(subject.new(params).is_general_agency_staff_profile?).to eq true
        end

        it "should return false" do
          expect(subject.new(params).is_general_agency_profile?).to eq false
        end

        it "should return false" do
          expect(subject.new(params).is_general_agency_profile?).to eq false
        end
      end
    end

    describe '#for_new' do
      it 'instantiates a new Staff Role Form' do
        expect(subject.new).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm)
      end
    end

    describe '#for_create' do

      let!(:person) { FactoryBot.create(:person, :with_ssn) }
      let!(:params) {
        {
          profile_id: employer_profile.id.to_s,
          first_name: person.first_name,
          last_name: person.last_name,
          dob: Date.new(1972,0o4,0o4).to_s
        }
      }

      context "with valid form attributes " do

        let!(:create_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_create params }

        it "create_form should be valid" do
          create_form.validate
          expect(create_form).to be_valid
        end

        it "should assign the params for create forms" do
          expect(create_form.profile_id).to eq params[:profile_id]
          expect(create_form.first_name).to eq params[:first_name]
          expect(create_form.last_name).to eq params[:last_name]
          expect(create_form.dob).to eq params[:dob].to_date
          expect(create_form.profile_type).to eq nil
        end

        context '#save' do

          it 'should instantiates a new Staff Role Service' do
            expect(create_form.send(:service)).to be_an_instance_of(Services::StaffRoleService)
          end

          it "should add staff role for profile when persist!" do
            expect(person.employer_staff_roles).to eq []
            expect(create_form.save).to eq [true, person]
            person.reload
            expect(person.employer_staff_roles.count).to eq 1
          end
        end
      end

      context "with invalid form attributes " do

        let!(:create_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_create params.except!(:dob) }

        it "should not be valid" do
          create_form.validate
          expect(create_form).to_not be_valid
        end

        context '#save' do
          it "should return false when persist" do
            expect(create_form.save).to eq false
          end
        end
      end
    end

    describe '#for_approve' do

      let!(:active_employer_staff_role) {FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_applicant', benefit_sponsor_employer_profile_id: employer_profile.id)}
      let!(:person) { FactoryBot.create(:person, employer_staff_roles:[active_employer_staff_role]) }
      let!(:params) {
        {
          profile_id: employer_profile.id.to_s,
          first_name: person.first_name,
          last_name: person.last_name,
          dob: person.dob.to_s,
          person_id: person.id
        }
      }

      context "with valid form attributes " do

        let!(:approve_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_approve params }

        it "approve_form should be valid" do
          approve_form.validate
          expect(approve_form).to be_valid
        end

        context '#approve' do

          it "should approve staff role for profile" do
            expect(person.employer_staff_roles.map(&:aasm_state)).to eq ["is_applicant"]
            expect(approve_form.approve).to eq [true, "Role is approved"]
            person.reload
            expect(person.employer_staff_roles.map(&:aasm_state)).to eq ["is_active"]
          end
        end
      end

      context "with invalid form attributes " do

        let!(:approve_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_approve params.except!(:profile_id) }

        context '#approve' do
          it "should return error when approving staff role" do
            expect(approve_form.approve).to eq [false, "Please contact HBX Admin to report this error"]
          end
        end
      end
    end

    describe '#for_destroy' do

      let!(:active_employer_staff_role) {FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
      let!(:person2) { FactoryBot.create(:person, first_name:'y',employer_staff_roles:[active_employer_staff_role]) }
      let!(:params) {
        {
          profile_id: employer_profile.id.to_s,
          first_name: person2.first_name,
          last_name: person2.last_name,
          dob: person2.dob.to_s,
          person_id: person2.id
        }
      }

      context "with valid form attributes " do

        let!(:destroy_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_destroy params }

        it "approve_form should be valid" do
          destroy_form.validate
          expect(destroy_form).to be_valid
        end

        context '#destroy' do

          it "should deactivate staff role for profile" do
            expect(person2.employer_staff_roles.map(&:aasm_state)).to eq ["is_active"]
            expect(destroy_form.destroy).to eq [true, "Employee Staff Role is inactive"]
            person2.reload
            expect(person2.employer_staff_roles.map(&:aasm_state)).to eq ["is_closed"]
          end
        end
      end

      context "with invalid form attributes " do

        let!(:approve_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_destroy params.except!(:person_id) }

        context '#destroy' do
          it "should return error" do
            expect(approve_form.destroy).to eq [false, "Person not found"]
          end
        end
      end
    end

    describe '#for_broker_agency_search' do

      let!(:person) { FactoryBot.create(:person) }
      let!(:params) do
        {
          filter_criteria: {"q" => broker_agency_profile.legal_name},
          is_broker_registration_page: "true"
        }
      end

      context "with valid form attributes " do

        let!(:broker_search_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_broker_agency_search params }


        it "should assign the params for broker_search_form" do
          expect(broker_search_form.filter_criteria.class).to eq Hash
          expect(broker_search_form.is_broker_registration_page).to eq true
        end

        context '#broker_agency_search!' do

          it 'should instantiates a new Staff Role Service' do
            expect(broker_search_form.send(:service)).to be_an_instance_of(Services::StaffRoleService)
          end

          it "should search for broker agencies and return result if broker profile is approved" do
            broker_agency_profile.update_attributes!(aasm_state: "is_approved")
            expect(broker_search_form.broker_agency_search).to eq [broker_agency_profile]
          end

          it "should return empty result if broker profile is not approved" do
            expect(broker_search_form.broker_agency_search).to eq []
          end
        end
      end
    end

    describe '#for_general_agency_search' do

      let!(:person) { FactoryBot.create(:person) }
      let!(:params) do
        {
          filter_criteria: {"q" => general_agency_profile.legal_name},
          is_general_agency_registration_page: "true"
        }
      end

      context "with valid form attributes " do

        let!(:general_agency_search_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_general_agency_search params }


        it "should assign the params for general_agency_search_form" do
          expect(general_agency_search_form.filter_criteria.class).to eq Hash
          expect(general_agency_search_form.is_general_agency_registration_page).to eq true
        end

        context '#general_agency_search!' do

          it 'should instantiates a new Staff Role Service' do
            expect(general_agency_search_form.send(:service)).to be_an_instance_of(Services::StaffRoleService)
          end

          it "should search for general agencies and return result if ga profile is approved" do
            general_agency_profile.update_attributes!(aasm_state: "is_approved")
            expect(general_agency_search_form.general_agency_search).to eq [general_agency_profile]
          end

          it "should return empty result if general agency profile is not approved" do
            expect(general_agency_search_form.general_agency_search).to eq []
          end
        end
      end
    end
  end
end
