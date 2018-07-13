require 'rails_helper'

module BenefitSponsors

  RSpec.describe Organizations::OrganizationForms::AddressForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Organizations::OrganizationForms::AddressForm }

    describe "model attributes" do

      let!(:params) {
        {
            address_1: 'address1',
            city: "ma city",
            state: "MA",
            zip: "01001"
        }
      }

      it "should have all the attributes" do
        [:id, :address_1, :address_2, :city, :state, :zip, :kind, :county, :office_kind_options, :state_options].each do |key|
          expect(subject.new.attributes.has_key?(key)).to be_truthy
        end
      end

      it 'instantiates a new Address Form' do
        expect(subject.new).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::AddressForm)
      end

      it "new form should be valid" do
        new_form = subject.new params
        new_form.validate
        expect(new_form).to be_valid
      end

      it "new form should not be valid" do
        new_form = subject.new params.except!(:address_1)
        new_form.validate
        expect(new_form).to_not be_valid
      end
    end
  end
end