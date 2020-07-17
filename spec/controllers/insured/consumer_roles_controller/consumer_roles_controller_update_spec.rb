require "rails_helper"

RSpec.describe Insured::ConsumerRolesController do
  describe "PUT update, for an IVL market person with a consumer role" do
    let(:person_id) { "SOME PERSON ID" }
    let(:consumer_role_id) { "SOME CONSUMER ROLE ID" }
    let(:user) do
      instance_double(
        User,
        person: person,
        has_hbx_staff_role?: false
      )
    end
    let(:family) { instance_double(Family, id: family_id) }
    let(:family_id) { "SOME FAMILY ID" }
    let(:family_member) do
      instance_double(
        FamilyMember,
        person: dependent_person,
        family: family
      )
    end
    let(:person) do
      instance_double(
        Person,
        is_resident_role_active?: false,
        no_dc_address: false,
        has_multiple_roles?: false,
        id: person_id,
        agent?: false
      )
    end
    let(:consumer_role) do
      double(
        person: person,
        policy_class: ConsumerRolePolicy,
        residency_determined_at: nil,
        local_residency_validation: nil
      )
    end

    let(:person_controller_parameters) do
      ActionController::Parameters.new(person_update_properties).permit!
    end

    before(:each) do
      sign_in(user)
      allow(ConsumerRole).to receive(:find).with(consumer_role_id).and_return(consumer_role)
      allow(consumer_role).to receive(:update_by_person).with(person_controller_parameters).and_return(true)
    end

    describe "when the value for 'is_applying_coverage' is provided" do
      let(:is_applying_coverage_value) { "false" }
      let(:person_update_properties) do
        {
          "first_name" => "Person First Name",
          "is_applying_coverage" => is_applying_coverage_value
        }
      end

      it "updates the 'is_applying_coverage' value for the dependent" do
        expect(consumer_role).to receive(:update_attribute).with(:is_applying_coverage, is_applying_coverage_value).and_return(true)
        put :update, params: {id: consumer_role_id, person: person_update_properties, exit_after_method: true}
      end
    end

    describe "when the value for 'is_applying_coverage' is NOT provided" do
      let(:person_update_properties) do
        { "first_name" => "Person First Name" }
      end

      it "does not change the 'is_applying_coverage' value for the dependent" do
        expect(consumer_role).not_to receive(:update_attribute)
        put :update, params: {id: consumer_role_id, person: person_update_properties, exit_after_method: true}
      end
    end
  end
end