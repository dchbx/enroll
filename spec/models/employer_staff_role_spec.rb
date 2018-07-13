require 'rails_helper'
require_relative '../../components/benefit_sponsors/spec/concerns/observable_spec.rb'

describe EmployerStaffRole, dbclean: :after_each do

  it_behaves_like 'observable'

  let(:person) { FactoryGirl.create(:person) }
  let(:employer_profile) { double(id: "valid_id") }

  describe ".new" do
    let(:valid_params) do
      {
        person: person,
        employer_profile_id: employer_profile.id
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(EmployerStaffRole.new(**params).save).to be_falsey
      end
    end

     context "with valid params" do
      let(:params) { valid_params}

      it "should be valid" do
        expect(EmployerStaffRole.new(**params).valid?).to be_truthy
      end
     end

  end
end
