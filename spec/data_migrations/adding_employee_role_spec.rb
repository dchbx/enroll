require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "adding_employee_role")

describe AddingEmployeeRole, dbclean: :after_each do
  let!(:site) { create(:benefit_sponsors_site,:with_benefit_market, :with_benefit_market_catalog_and_product_packages, :as_hbx_profile, :cca) }
  let!(:org) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let(:employer_profile) { org.employer_profile }
  let!(:rating_area) { FactoryBot.create_default :benefit_markets_locations_rating_area }
  let!(:service_area) { FactoryBot.create_default :benefit_markets_locations_service_area }
  let(:benefit_sponsorship) { employer_profile.add_benefit_sponsorship }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
  let(:benefit_market) { site.benefit_markets.first }
  let(:benefit_market_catalog) { benefit_market.benefit_market_catalogs.first }
  let!(:product_package) { benefit_market_catalog.product_packages.where(package_kind: :single_issuer).first }
  let!(:benefit_package) { FactoryBot.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }
  let!(:benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, aasm_state: :active) }
  let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, sponsored_benefit_package_id: benefit_package.id, household: family.active_household)}
  let(:benefit_group_assignment) {FactoryBot.build(:benefit_group_assignment, benefit_package: benefit_package, hbx_enrollment: hbx_enrollment, start_on: benefit_application.start_on) }
  let(:benefit_group_assignment2) {FactoryBot.build(:benefit_group_assignment, benefit_package: benefit_package, hbx_enrollment: hbx_enrollment, start_on: benefit_application.start_on) }
  let(:benefit_group_assignment3) {FactoryBot.build(:benefit_group_assignment, benefit_package: benefit_package, hbx_enrollment: hbx_enrollment, start_on: benefit_application.start_on) }
  let(:census_employee) { FactoryBot.create(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship) }
  let(:census_employee2) { FactoryBot.create(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship) }
  let(:census_employee3) { FactoryBot.create(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship) }

  let(:given_task_name) { "adding_employee_role" }
  subject { AddingEmployeeRole.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "creating new employee role", dbclean: :after_each do
    let(:person) { FactoryBot.create(:person, ssn: "009998887") }

    context 'When params are missing/invalid' do
      context 'when census_employee_id not provided then' do
        it 'should raise an error' do
          ClimateControl.modify action: 'Add' do
            expect(subject.migrate).to eq('Please provide census_employee_id.')
          end
        end
      end

      context 'when census employee id is invalid then' do
        it 'should raise an error' do
          ClimateControl.modify action: 'Add',census_employee_id: '123abc987pqr' do
           expect(subject.migrate).to eq('No Census Employee found by 123abc987pqr')
          end
        end
      end

      context 'when person_id not provided then' do
        it 'should raise an error' do
          ClimateControl.modify action: 'Add', census_employee_id: census_employee.id do
            expect(subject.migrate).to eq('Please provide person_id.')
          end
        end
      end

      context 'when census person_id is invalid then' do
        it 'should raise an error' do
          ClimateControl.modify action: 'Add',census_employee_id: census_employee.id,person_id: '123abc987pqr' do
          expect(subject.migrate).to eq('Person not found by 123abc987pqr')
          end
        end
      end
    end

    context 'employee without an employee role' do
      it 'should link employee role' do
        ClimateControl.modify action: 'Add',census_employee_id: census_employee.id,person_id: person.id do
          census_employee.update_attribute(:employer_profile_id, employer_profile.id)
          census_employee.benefit_group_assignments << benefit_group_assignment
          census_employee.save!
          benefit_group_assignment.save!

          expect(census_employee.employee_role).to eq nil
          subject.migrate
          census_employee.reload
          expect(census_employee.employee_role).not_to eq nil
        end
      end
    end
  end

  describe "census employee's not linked" do

    context 'When ENV params are invalid' do
      context 'when action is invalid then' do

        it 'should raise an error' do
          ClimateControl.modify action: 'Hello'do
            expect(subject.migrate).to eq('Invalid action Hello!')
          end
        end
      end

      context 'when ce ids not provided then' do
        it 'should raise an error' do
          ClimateControl.modify action: 'Link' do
            expect(subject.migrate).to eq('Please provide census_employee_ids.')
          end
        end
      end

      context 'when census employee id is invalid then' do
        it 'should raise an error' do
          ClimateControl.modify action: 'Link', census_employee_ids: '123abc987pqr' do
            expect(subject.migrate).to eq('No Census Employee found with 123abc987pqr')
          end
        end
      end
    end

    context 'when benefit application state is not published then' do
      let!(:benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, aasm_state: :draft) }
      before(:each) do
        census_employee.benefit_group_assignments << benefit_group_assignment
        census_employee.save!
        benefit_group_assignment.save!
      end

      it 'employee state should not be changed to employee_role_linked' do
        ClimateControl.modify action: 'Link', census_employee_ids: census_employee.id.to_s do
          expect(census_employee.aasm_state).to eq 'eligible'
          subject.migrate
          census_employee.reload
          expect(census_employee.aasm_state).to eq 'eligible'
        end
      end
    end

    context 'when census employee ids are valid' do
      it 'employees should have eligible state then employee role linked states' do
        ClimateControl.modify action: 'Link', census_employee_ids: "#{census_employee.id}, #{census_employee2.id}, #{census_employee3.id}" do
          census_employee.benefit_group_assignments << benefit_group_assignment
          census_employee.save!
          benefit_group_assignment.save!
          census_employee2.benefit_group_assignments << benefit_group_assignment2
          census_employee2.save!
          benefit_group_assignment2.save!
          census_employee3.benefit_group_assignments << benefit_group_assignment3
          census_employee3.save!
          benefit_group_assignment3.save!

          expect(census_employee.aasm_state).to eq 'eligible'
          expect(census_employee2.aasm_state).to eq 'eligible'
          expect(census_employee3.aasm_state).to eq 'eligible'
          subject.migrate
          census_employee.reload
          census_employee2.reload
          census_employee3.reload
          expect(census_employee.aasm_state).to eq 'employee_role_linked'
          expect(census_employee2.aasm_state).to eq 'employee_role_linked'
          expect(census_employee3.aasm_state).to eq 'employee_role_linked'
        end
      end
    end
  end
end
