require 'rails_helper'

module BenefitSponsors

  RSpec.describe Organizations::OrganizationForms::StaffRoleForm, type: :model, dbclean: :after_each do

    let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_sponsor) { create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_profile) { benefit_sponsor.employer_profile }
    let!(:active_employer_staff_role) {FactoryGirl.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
    let!(:person) { FactoryGirl.create(:person, employer_staff_roles:[active_employer_staff_role]) }
    let(:user) { FactoryGirl.create(:user, :person => person)}

    subject { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm }

    describe "model attributes" do
      it {
        [:npn, :first_name, :last_name, :email, :phone, :status, :dob, :person_id, :area_code, :number, :extension, :profile_id, :profile_type].each do |key|
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
      end
    end

    describe '#for_new' do
      it 'instantiates a new Staff Role Form' do
        expect(subject.new).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm)
      end
    end

    describe '#for_create' do

      let!(:person) { FactoryGirl.create(:person) }
      let!(:params) {
        {
            profile_id: employer_profile.id.to_s,
            first_name: person.first_name,
            last_name: person.last_name,
            dob: person.dob.to_s
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

      let!(:active_employer_staff_role) {FactoryGirl.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_applicant', benefit_sponsor_employer_profile_id: employer_profile.id)}
      let!(:person) { FactoryGirl.create(:person, employer_staff_roles:[active_employer_staff_role]) }
      let!(:params) {
        {
            profile_id: employer_profile.id.to_s,
            first_name: person.first_name,
            last_name: person.last_name,
            dob: person.dob.to_s,
            person_id:person.id
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

      let!(:active_employer_staff_role) {FactoryGirl.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
      let!(:person2) { FactoryGirl.create(:person, first_name:'y',employer_staff_roles:[active_employer_staff_role]) }
      let!(:params) {
        {
            profile_id: employer_profile.id.to_s,
            first_name: person2.first_name,
            last_name: person2.last_name,
            dob: person2.dob.to_s,
            person_id:person2.id
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
  end
end
