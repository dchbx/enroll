require 'rails_helper'

module BenefitSponsors

  RSpec.describe Organizations::OrganizationForms::MessageForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Organizations::OrganizationForms::MessageForm }

    describe "model attributes" do

      let!(:params) {
        {
            sender_id: '123'
        }
      }

      it "should have all the attributes" do
        [:sender_id].each do |key|
          expect(subject.new.attributes.has_key?(key)).to be_truthy
        end
      end

      it 'instantiates a new Message Form' do
        expect(subject.new).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::MessageForm)
      end

      it "new form should be valid" do
        new_form = subject.new params
        new_form.validate
        expect(new_form).to be_valid
      end
    end
  end
end