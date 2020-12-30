require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_product_on_fehb_enrollment")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"

describe UpdateProductOnFehbEnrollment, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:given_task_name) { "update_product_on_fehb_enrollment" }
  subject { UpdateProductOnFehbEnrollment.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update product on fehb enrollment", dbclean: :after_each do
    let!(:person){ FactoryBot.create(:person, :with_family)}
    let!(:family) {person.primary_family}
    let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, benefit_sponsors_employer_profile_id: abc_profile.id)}
    let!(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, employee_role_id: employee_role.id) }
    let!(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
    let!(:fehb_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, hios_base_id: product.hios_id, benefit_market_kind: :fehb ) }
    let!(:hbx_enrollment) do
      hbx_enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                          product_id: product.id,
                          household: family.active_household,
                          family: family,
                          aasm_state: "coverage_selected",
                          effective_on: initial_application.start_on,
                          kind: "employer_sponsored",
                          rating_area_id: initial_application.recorded_rating_area_id,
                          sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
                          sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
                          benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
                          employee_role_id: employee_role.id)
      hbx_enrollment.benefit_sponsorship = benefit_sponsorship
      hbx_enrollment.save!
      hbx_enrollment
    end

    it "should update the premium tables on the product" do
      ClimateControl.modify feins: abc_organization.fein do
        allow(hbx_enrollment).to receive(:fehb_profile).and_return(abc_profile)
        allow(subject).to receive(:enrollments_effective_on).and_return([hbx_enrollment])
        expect(hbx_enrollment.product.benefit_market_kind).to eq(:aca_shop)
        subject.migrate
        hbx_enrollment.remove_instance_variable(:@product)
        hbx_enrollment.reload
        expect(hbx_enrollment.product.benefit_market_kind).to eq(:fehb)
      end
    end
  end
end
