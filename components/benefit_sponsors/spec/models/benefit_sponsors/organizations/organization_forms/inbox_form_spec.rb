require 'rails_helper'

module BenefitSponsors

  RSpec.describe Organizations::OrganizationForms::InboxForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Organizations::OrganizationForms::InboxForm }

    describe "model attributes" do

      let!(:params) {
        {
            access_key: '1234'
        }
      }

      it "should have all the attributes" do
        [:access_key, :messages].each do |key|
          expect(subject.new.attributes.has_key?(key)).to be_truthy
        end
      end

      it 'instantiates a new Inbox Form' do
        expect(subject.new).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::InboxForm)
      end

      it "new form should be valid" do
        new_form = subject.new params
        new_form.validate
        expect(new_form).to be_valid
      end
    end
  end
end