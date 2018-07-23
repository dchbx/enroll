require 'rails_helper'

module BenefitSponsors

  RSpec.describe Organizations::OrganizationForms::PhoneForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Organizations::OrganizationForms::PhoneForm }

    describe "model attributes" do

      let!(:params) {
        {
            kind: 'work',
            area_code: "222",
            number: "1112222"
        }
      }

      it "should have all the attributes" do
        [:id, :kind, :area_code, :number,:extension,:office_kind_options].each do |key|
          expect(subject.new.attributes.has_key?(key)).to be_truthy
        end
      end

      it 'instantiates a new Address Form' do
        expect(subject.new).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::PhoneForm)
      end

      it "new form should be valid" do
        new_form = subject.new params
        new_form.validate
        expect(new_form).to be_valid
      end

      it "new form should not be valid" do
        new_form = subject.new params.except!(:kind)
        new_form.validate
        expect(new_form).to_not be_valid
      end
    end
  end
end