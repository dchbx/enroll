require 'rails_helper'

module BenefitSponsors

  RSpec.describe Organizations::OrganizationForms::OfficeLocationForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Organizations::OrganizationForms::OfficeLocationForm }

    describe "model attributes" do

      let!(:params) {
        {
          address:
           {
              address_1: "new address",
              kind: "primary",
              address_2:"",
              city: "ma_city",
              state:"MA",
              zip:"01001",
              county: "Hampden"
           }
        }
      }

      let(:phone) {
         {
           kind: "phone main",
           area_code:"222", number:"2221111",
           extension:""
         }
      }

      it "should have all the attributes" do
        [:id, :is_primary, :address, :phone].each do |key|
          expect(subject.new.attributes.has_key?(key)).to be_truthy
        end
      end

      it 'instantiates a new OfficeLocation Form' do
        expect(subject.new).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::OfficeLocationForm)
      end

      it "new form should be valid" do
        new_form = subject.new params.merge({:phone=>phone})
        new_form.validate
        expect(new_form).to be_valid
      end

      it "new form should not be valid" do
        params[:address][:address_1] = ''
        new_form = subject.new params.merge!({:phone=>phone})
        new_form.validate
        expect(new_form).to_not be_valid
      end

      it "should set is_primary form attribute to true when address is primary" do
        new_form = subject.new params.merge!({:phone=>phone})
        address = new_form.address
        new_form.set_is_primary_field(address)
        expect(new_form.is_primary).to eq true
      end

      it "should set is_primary form attribute to false when address is mailing" do
        params[:address][:kind] = 'mailing'
        new_form = subject.new params.merge!({:phone=>phone})
        address = new_form.address
        new_form.set_is_primary_field(address)
        expect(new_form.is_primary).to eq false
      end
    end
  end
end