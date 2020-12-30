require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_predecessor_id_on_bp")
describe UpdateEmployeeRoleId, dbclean: :after_each do
  let(:given_task_name) { "update_predecessor_id_on_bp" }
  subject { UpdatePredecessorIdOnBp.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "update predecessor id on the enrollments", dbclean: :after_each do
    let(:current_effective_date)  { TimeKeeper.date_of_record }
    let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:issuer_profile)  { FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
    let!(:old_benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                            benefit_market: benefit_market,
                                            issuer_profile: issuer_profile,
                                            title: "SHOP Benefits for #{current_effective_date.year - 1.year}",
                                            application_period: (current_effective_date.next_month.beginning_of_month - 1.year ..current_effective_date.end_of_month))
                                          }

    let!(:renewing_benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                            benefit_market: benefit_market,
                                            issuer_profile: issuer_profile,
                                            title: "SHOP Benefits for #{current_effective_date.year}",
                                            application_period: (current_effective_date.next_month.beginning_of_month..current_effective_date.end_of_month + 1.year ))
                                          }

    let(:benefit_market)      { site.benefit_markets.first }
    let!(:product_package_1) { old_benefit_market_catalog.product_packages.first }
    let!(:product_package_2) { renewing_benefit_market_catalog.product_packages.first }

    let!(:rating_area)   { FactoryBot.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)  { FactoryBot.create_default :benefit_markets_locations_service_area }
    let!(:security_question)  { FactoryBot.create_default :security_question }

    let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    let(:benefit_sponsorship) do
      FactoryBot.create(
        :benefit_sponsors_benefit_sponsorship,
        :with_rating_area,
        :with_service_areas,
        supplied_rating_area: rating_area,
        service_area_list: [service_area],
        organization: organization,
        profile_id: organization.profiles.first.id,
        benefit_market: site.benefit_markets[0],
        employer_attestation: employer_attestation)
    end

    let(:start_on)  { TimeKeeper.date_of_record}
    let(:old_effective_period)  { start_on.next_month.beginning_of_month - 1.year ..start_on.end_of_month }
    let!(:old_benefit_application) {
      application = FactoryBot.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, effective_period: old_effective_period, aasm_state: :active)
      application.benefit_sponsor_catalog.save!
      application
    }

    let(:renewing_effective_period)  { start_on.next_month.beginning_of_month..start_on.end_of_month + 1.year }
    let!(:renewing_benefit_application) {
      application = FactoryBot.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, effective_period: renewing_effective_period, aasm_state: :renewing_enrolling, predecessor_id: old_benefit_application.id)
      application.benefit_sponsor_catalog.save!
      application
    }

    let!(:old_benefit_package) { FactoryBot.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: old_benefit_application, product_package: product_package_1) }
    let!(:renewing_benefit_package) { FactoryBot.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: renewing_benefit_application, product_package: product_package_1) }

    it "should update the predecessor_id on benefit_package with the correct one" do
      expect(organization.employer_profile.benefit_applications.second.benefit_packages.first.predecessor_id).to eq nil
      ClimateControl.modify old_benefit_package_id: organization.employer_profile.benefit_applications.first.benefit_packages.first.id,
                            renewing_benefit_package_id: organization.employer_profile.benefit_applications.second.benefit_packages.first.id do
        subject.migrate
      end
      organization.employer_profile.benefit_applications.second.benefit_packages.first.reload
      expect(organization.employer_profile.benefit_applications.second.benefit_packages.first.predecessor_id).to_not eq nil
      expect(organization.employer_profile.benefit_applications.second.benefit_packages.first.predecessor_id).to eq (organization.employer_profile.benefit_applications.first.benefit_packages.first.id)
    end

    it "should not change the ee_role_id of hbx_enrollment if the EE Role id matches with the correct one" do
      organization.employer_profile.benefit_applications.second.update_attributes!(predecessor_id: nil)
      ClimateControl.modify old_benefit_package_id: organization.employer_profile.benefit_applications.first.benefit_packages.first.id,
                            renewing_benefit_package_id: organization.employer_profile.benefit_applications.second.benefit_packages.first.id do
        subject.migrate
      end
      organization.employer_profile.benefit_applications.second.benefit_packages.first.reload
      expect(organization.employer_profile.benefit_applications.second.benefit_packages.first.predecessor_id).to eq nil
    end
  end
end
