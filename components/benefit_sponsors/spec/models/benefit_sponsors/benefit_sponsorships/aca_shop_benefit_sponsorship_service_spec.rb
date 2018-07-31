require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitSponsorships::AcaShopBenefitSponsorshipService, dbclean: :after_each do

    let!(:previous_rating_area) { create_default(:benefit_markets_locations_rating_area, active_year: Date.current.year - 1) }
    let!(:previous_service_area) { create_default(:benefit_markets_locations_service_area, active_year: Date.current.year - 1) }
    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
    let!(:service_area) { create_default(:benefit_markets_locations_service_area) }

    let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:benefit_market)  { site.benefit_markets.first }

    let(:employer_organization)   { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)        { employer_organization.employer_profile }

    let!(:rating_area)                    { FactoryGirl.create(:benefit_markets_locations_rating_area)  }
    let!(:service_area)                    { FactoryGirl.create(:benefit_markets_locations_service_area)  }
    let(:this_year)                       { TimeKeeper.date_of_record.year }

    let(:april_effective_date)            { Date.new(this_year,4,1) }
    let(:april_open_enrollment_begin_on)  { april_effective_date - 1.month }
    let(:april_open_enrollment_end_on)    { april_open_enrollment_begin_on + 9.days }

    let(:initial_application_state)       { :active }
    let(:renewal_application_state)       { :enrollment_open }

    let(:sponsorship_state)               { :active }
    let(:renewal_sponsorship_state)       { :active }
    let(:renewal_current_application_state) { :active }

    let!(:april_sponsors)                 { create_list(:benefit_sponsors_benefit_sponsorship, 2, :with_organization_cca_profile,
      :with_initial_benefit_application, initial_application_state: initial_application_state,
      default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site, aasm_state: sponsorship_state)
    }

    let!(:april_renewal_sponsors)         { create_list(:benefit_sponsors_benefit_sponsorship, 2, :with_organization_cca_profile,
      :with_renewal_benefit_application, initial_application_state: renewal_current_application_state,
      renewal_application_state: renewal_application_state,
      default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site,
      aasm_state: renewal_sponsorship_state)
    }

    let(:current_date)                    { Date.today }

    before { TimeKeeper.set_date_of_record_unprotected!(current_date) }
    subject { BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService }

    describe '.mark_initial_ineligible' do 
      let(:sponsorship_state)               { :initial_enrollment_closed }
      let(:initial_application_state)       { :enrollment_closed }

      context  'when initial employer missed binder payment' do 

        it "should move applications into ineligible state" do 
          april_sponsors.each do |sponsor|

            sponsorship_service = subject.new(benefit_sponsorship: sponsor)
            sponsorship_service.mark_initial_ineligible

            sponsor.reload

            expect(sponsor.initial_enrollment_ineligible?).to be_truthy
            expect(sponsor.benefit_applications.first.enrollment_ineligible?).to be_truthy
          end
        end
      end
    end


    describe '.auto_cancel_ineligible' do 
      let(:sponsorship_state)               { :initial_enrollment_ineligible }
      let(:initial_application_state)       { :enrollment_ineligible }
      let(:renewal_application_state)       { :enrollment_ineligible }

      context  'when initial employer missed binder payment' do 

        it "should move applications into ineligible state" do 
          (april_sponsors + april_renewal_sponsors).each do |sponsor|
            benefit_application = sponsor.benefit_applications.detect{|application| application.is_renewing?}
            benefit_application = sponsor.benefit_applications.first if benefit_application.blank?

            expect(sponsor.initial_enrollment_ineligible?).to be_truthy if !benefit_application.is_renewing?
            expect(benefit_application.enrollment_ineligible?).to be_truthy

            sponsorship_service = subject.new(benefit_sponsorship: sponsor)
            sponsorship_service.auto_cancel_ineligible

            sponsor.reload
            benefit_application.reload

            expect(sponsor.applicant?).to be_truthy
            expect(benefit_application.canceled?).to be_truthy
          end
        end
      end
    end
  end
end