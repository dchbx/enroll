require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_product_package_rates")
describe UpdateEmployeeRoleId, dbclean: :after_each do
  let(:given_task_name) { "update_product_package_rates" }
  subject { UpdateProductPackageRates.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update product package rates", dbclean: :after_each do
    let(:current_effective_date)  { TimeKeeper.date_of_record }
    let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:benefit_market)      { site.benefit_markets.first }
    let!(:rating_area)   { FactoryBot.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)  { FactoryBot.create_default :benefit_markets_locations_service_area }
    let!(:security_question)  { FactoryBot.create_default :security_question }
    let(:start_on)  { current_effective_date.prev_month }
    let(:effective_period)  { start_on..start_on.next_year.prev_day }
    let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site, fein: "123456789") }
    let(:benefit_sponsorship) { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(profile: employer_organization.employer_profile) }
    let!(:employer_profile) {benefit_sponsorship.profile}
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    let!(:benefit_sponsorship) do
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
    let!(:benefit_sponsor_catalog) { FactoryBot.create(:benefit_markets_benefit_sponsor_catalog, service_areas: [service_area]) }
    let!(:benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application, benefit_sponsor_catalog: benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, effective_period: effective_period, aasm_state: :active)
    }
    let!(:benefit_application_id) { benefit_application.id.to_s }
    let!(:issuer_profile)  { FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
    let!(:product_package_kind) { :single_issuer }
    let!(:update_product_package) { benefit_sponsor_catalog.product_packages.where(package_kind: product_package_kind).first.update_attributes(package_kind: :single_product) }

    let!(:product_package) { benefit_sponsor_catalog.product_packages.where(package_kind: :single_product).first}
    let!(:products){product_package.products.update_all(product_package_kinds: [:single_product])}
    let!(:product) { product_package.products.first}
    let!(:product2) {product_package.products.last}

    let!(:benefit_package) { FactoryBot.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }
    let(:benefit_group_assignment) {FactoryBot.build(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package)}

    let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: employer_profile, census_employee_id: census_employee.id) }
    let!(:benefit_group_assignment) {FactoryBot.build(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package)}
    let!(:census_employee) { FactoryBot.create(:census_employee,
      employer_profile_id: nil,
      benefit_sponsors_employer_profile_id: employer_profile.id,
      benefit_sponsorship: benefit_sponsorship,
      benefit_group_assignments: [benefit_group_assignment]
    )}
    let(:person) { FactoryBot.create(:person) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}

    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                         family: family,
                         household: family.active_household,
                         kind: "employer_sponsored",
                         effective_on: start_on,
                         product: product,
                         employee_role_id: employee_role.id,
                         sponsored_benefit_package_id: benefit_package.id,
                         benefit_group_assignment_id: benefit_group_assignment.id,
                         sponsored_benefit_id: benefit_application.benefit_packages.first.health_sponsored_benefit.id,
                         aasm_state: 'coverage_selected'
      )
    end

    it "should update the premium tables on the product" do
      ClimateControl.modify feins: '123456789' do
        organization.employer_profile.benefit_applications.first.benefit_sponsor_catalog.product_packages.first.products.first.premium_tables = []
        subject.migrate
        expect(organization.employer_profile.benefit_applications.first.benefit_sponsor_catalog.product_packages.first.products.first.premium_tables).not_to eq nil
      end
    end
  end
end
