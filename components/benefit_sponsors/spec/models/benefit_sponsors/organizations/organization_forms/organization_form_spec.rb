require 'rails_helper'

module BenefitSponsors

  RSpec.describe Organizations::OrganizationForms::OrganizationForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Organizations::OrganizationForms::OrganizationForm }

    describe "model attributes" do

      let!(:params) {
        {
            entity_kind: 'tax_exempt_organization',
            fein: "111222333",
            legal_name: "legal_name",
        }
      }

      it "should have all the attributes" do
        [:fein, :legal_name, :dba, :entity_kind, :entity_kind_options, :profile_type, :profile].each do |key|
          expect(subject.new.attributes.has_key?(key)).to be_truthy
        end
      end

      it 'instantiates a new Organization Form' do
        expect(subject.new).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::OrganizationForm)
      end

      it "new form should be valid" do
        new_form = subject.new params
        new_form.validate
        expect(new_form).to be_valid
      end

      it "new form should not be valid" do
        new_form = subject.new params.except!(:legal_name)
        new_form.validate
        expect(new_form).to_not be_valid
      end

      it "new form with invalid fein" do
        params[:fein]='1112222'
        new_form = subject.new params
        new_form.validate
        expect(new_form).to_not be_valid
        expect(new_form.errors.messages.has_key?(:fein)).to eq true
      end
    end
  end
end