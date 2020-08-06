# frozen_string_literal: true

require 'rails_helper'

module BenefitSponsors
  RSpec.describe Forms::SponsoredBenefitForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Forms::SponsoredBenefitForm.new }
    let(:site)                  { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:benefit_sponsor)        { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile_initial_application, site: site) }
    let(:benefit_sponsorship)    { benefit_sponsor.active_benefit_sponsorship }
    let(:benefit_application)    { benefit_sponsorship.benefit_applications.first }
    let(:benefit_package)    { benefit_application.benefit_packages.first }
    let(:sponsored_benefits_id)   { benefit_package.sponsored_benefits.first.id}
    describe "model attributes" do
      it {
        [:benefit_package_id, :benefit_sponsorship_id, :sponsored_benefit_id, :kind].each do |key|
          expect(subject.attributes.key?(key)).to be_truthy
        end
      }
    end

    describe "#for_new" do
      let(:benefit_form) { FactoryBot.build(:benefit_sponsors_forms_benefit_form)}

      it "should assign benefit sponsorship" do
        form = BenefitSponsors::Forms::SponsoredBenefitForm.for_new_benefit({benefit_sponsorship_id: benefit_sponsorship.id, benefit_package_id: benefit_package.id, kind: "dental", benefit_application_id: benefit_application.id})
        expect(form.service).to be_instance_of(BenefitSponsors::Services::SponsoredBenefitService)
        expect(form.benefit_sponsorship_id).to eq benefit_sponsorship.id.to_s
      end
    end

    describe "#for_create" do
      let(:params) do
        {
          :benefit_application_id => benefit_application.id,
          :benefit_package_id => benefit_package.id,
          :benefit_sponsorship_id => benefit_sponsorship.id,
          :kind => 'dental'
        }
      end

      it "should create the form assign the params for forms" do
        form = BenefitSponsors::Forms::SponsoredBenefitForm.for_create(params)
        expect(form.benefit_package_id).to eq params[:benefit_package_id].to_s
        expect(form.benefit_sponsorship_id).to eq params[:benefit_sponsorship_id].to_s
        expect(form.kind).not_to be 'dental'
      end
    end

    describe "#fetch" do
      let(:params) do
        {
          :benefit_application_id => benefit_application.id,
          :benefit_package_id => benefit_package.id,
          :benefit_sponsorship_id => benefit_sponsorship.id,
          :kind => 'dental'
        }

      end

      it "should create the form assign the params for forms" do
        form = BenefitSponsors::Forms::SponsoredBenefitForm.for_create(params)
        fetch_form = BenefitSponsors::Forms::SponsoredBenefitForm.fetch(:id => form.id,
                                                                        :benefit_application_id => benefit_application.id,
                                                                        :benefit_package_id => benefit_package.id,
                                                                        :benefit_sponsorship_id => benefit_sponsorship.id,
                                                                        :kind => 'dental')
        expect(fetch_form.benefit_application_id).to eq params[:benefit_application_id].to_s
        expect(fetch_form.benefit_package_id).to eq params[:benefit_package_id].to_s
        expect(fetch_form.benefit_sponsorship_id).to eq params[:benefit_sponsorship_id].to_s
        expect(fetch_form.kind).to eq 'dental'
        expect(fetch_form.id).to be form.id
      end
    end

    describe "#for_destroy" do
      let(:params) do
        {
          :kind => 'dental',
          :benefit_application_id => benefit_application.id,
          :benefit_package_id => benefit_package.id,
          :benefit_sponsorship_id => benefit_sponsorship.id,
          :id => sponsored_benefits_id
        }
      end

      it "should destroy the form assign the params for forms" do
        form = BenefitSponsors::Forms::SponsoredBenefitForm.for_destroy(params)
        expect(form.benefit_application_id).to eq params[:benefit_application_id].to_s
        expect(form.benefit_package_id).to eq params[:benefit_package_id].to_s
        expect(form.benefit_sponsorship_id).to eq params[:benefit_sponsorship_id].to_s
        expect(form.kind).to eq 'dental'
      end
    end
  end
end
