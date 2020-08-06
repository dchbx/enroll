# frozen_string_literal: true

require 'rails_helper'

module BenefitSponsors
  RSpec.describe Organizations::OrganizationForms::OrganizationForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Organizations::OrganizationForms::OrganizationForm }

    describe "model attributes", dbclean: :after_each do

      let!(:params) do
        {
          entity_kind: 'tax_exempt_organization',
          fein: "111222333",
          legal_name: "legal_name"
        }
      end

      it "should have all the attributes" do
        [:fein, :legal_name, :dba, :entity_kind, :entity_kind_options, :profile_type, :profile].each do |key|
          expect(subject.new.attributes.key?(key)).to be_truthy
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

      it "new form with invalid legal_name" do
        params[:legal_name] = nil
        new_form = subject.new params
        new_form.validate
        expect(new_form).to_not be_valid
        expect(new_form.errors.messages.key?(:legal_name)).to eq true
      end

      context "for fein" do
        it "new form should not be valid when fein is nil for benefit_sponsor" do
          params[:fein] = nil
          new_form = subject.new params.merge({profile: {profile_type: 'benefit_sponsor'} })
          new_form.validate
          expect(new_form).to_not be_valid
          expect(new_form.errors.messages.key?(:fein)).to eq true
        end

        it "new form should be valid when fein is nil for broker_agency" do
          params[:fein] = nil
          new_form = subject.new params.merge({profile: {profile_type: 'broker_agency'} })
          new_form.validate
          expect(new_form).to be_valid
          expect(new_form.errors.messages.key?(:fein)).to eq false
        end
      end
    end
  end
end
