require "rails_helper"

require File.join(Rails.root, "app", "data_migrations", "products", "mapping_to_correct_hios_id")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
  
describe MappingToCorrectHiosId, dbclean: :after_each do

  let(:given_task_name) { "mapping_to_correct_hios_id" }
  subject { MappingToCorrectHiosId.new(given_task_name, double(:current_scope => nil)) }
  
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update employee role id on the enrollments", dbclean: :after_each do
    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'

    let(:start_on)  { TimeKeeper.date_of_record.beginning_of_month.prev_month }
    let!(:employer_profile) { abc_profile }
    let!(:benefit_application) { initial_application }
    let(:single_product_package) { benefit_sponsor_catalog.product_packages.where(package_kind: :single_product).first }
    let!(:product) { single_product_package.products.first}
    let(:product2) { single_product_package.products.last }
    let!(:benefit_package) { current_benefit_package }
    let(:benefit_group_assignment) {FactoryBot.build(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package)}
    let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: employer_profile, census_employee_id: census_employee.id) }
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
                         sponsored_benefit_id: benefit_package.health_sponsored_benefit.id,
                         aasm_state: 'coverage_selected'
      )
    end

    around do |example|
      current_benefit_market_catalog
      ClimateControl.modify feins: abc_organization.fein, hios_id: product2.hios_id do
        census_employee.update_attributes!(employee_role_id: employee_role.id)
        example.run
      end
    end

    it "Mapping reference_product_id with other product_id" do
      subject.migrate
      benefit_package.reload
      expect(benefit_package.health_sponsored_benefit.reference_product_id).to eq product2.id
    end

    it "Updating hbx_enrollment product_id with it's reference_product_id" do
      subject.migrate
      benefit_application.reload
      hbx_enrollment.reload
      expect(hbx_enrollment.product_id).to eq product2.id
    end
  end
end
