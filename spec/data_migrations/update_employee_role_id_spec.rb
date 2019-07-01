require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'update_employee_role_id')
describe UpdateEmployeeRoleId, dbclean: :after_each do
  let(:given_task_name) { 'update_employee_role_id' }
  subject { UpdateEmployeeRoleId.new(given_task_name, double(:current_scope => nil)) }
  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end
  
  describe 'update employee role id on the enrollments/census_employee', dbclean: :after_each do
    let(:current_effective_date)  { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                            benefit_market: benefit_market,
                                            title: 'SHOP Benefits for #{current_effective_date.year}',
                                            application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
                                          }
    let(:benefit_market)      { site.benefit_markets.first }
    let!(:product_package) { benefit_market_catalog.product_packages.first }

    let!(:rating_area)   { FactoryBot.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)  { FactoryBot.create_default :benefit_markets_locations_service_area }
    let!(:security_question)  { FactoryBot.create_default :security_question }

    let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: 'approved') }
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

    let(:start_on)  { current_effective_date.prev_month }
    let(:effective_period)  { start_on..start_on.next_year.prev_day }
    let!(:benefit_application) {
      application = FactoryBot.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, effective_period: effective_period, aasm_state: :active)
      application.benefit_sponsor_catalog.save!
      application
    }

    let!(:benefit_package) { FactoryBot.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }
    let(:benefit_group_assignment) {FactoryBot.build(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package)}

    let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee.id) }
    let(:census_employee) { FactoryBot.create(:benefit_sponsors_census_employee,
      employer_profile: benefit_sponsorship.profile,
      benefit_sponsorship: benefit_sponsorship,
      benefit_group_assignments: [benefit_group_assignment]    )}
    let(:person) { FactoryBot.create(:person) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}

    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                         household: family.active_household,
                         family: family,
                         kind: 'employer_sponsored',
                         effective_on: start_on,
                         employee_role_id: '111111111',
                         sponsored_benefit_package_id: benefit_package.id,
                         benefit_group_assignment_id: benefit_group_assignment.id,
                         aasm_state: 'coverage_selected'
      )
    end

    context 'update employee role id on the enrollments', dbclean: :after_each  do
      before :each do
        employee_role.person.save!
      end

      around do |example|
        ClimateControl.modify hbx_id: person.hbx_id, action: 'update_employee_role_id_to_enrollment' do
          example.run
        end
      end

      it 'should update the ee_role_id on hbx_enrollment with the correct one' do
        expect(person.active_employee_roles.first.id).not_to eq hbx_enrollment.employee_role_id
        subject.migrate
        hbx_enrollment.reload
        expect(person.active_employee_roles.first.id).to eq hbx_enrollment.employee_role_id
      end

      it 'should not change the ee_role_id of hbx_enrollment if the EE Role id matches with the correct one' do
        hbx_enrollment.update_attributes(:employee_role_id => employee_role.id)
        expect(person.active_employee_roles.first.id).to eq hbx_enrollment.employee_role_id
        subject.migrate
        hbx_enrollment.reload
        expect(person.active_employee_roles.first.id).to eq hbx_enrollment.employee_role_id
      end
    end

    context 'update employee role id on the census_employee', dbclean: :after_each  do
      before :each do
        employee_role.person.save!
        person.active_employee_roles.first.census_employee.update_attributes!(employee_role_id: employee_role.id )
      end

      around do |example|
        ClimateControl.modify hbx_id: person.hbx_id, action: 'update_employee_role_id_to_ce' do
          example.run
        end
      end

      it 'should update the ee_role_id on census_employee if the id on EE role is not similar' do
        person.active_employee_roles.first.census_employee.update_attributes!(employee_role_id: '111111111111111111111111')
        expect(person.active_employee_roles.first.id).not_to eq person.active_employee_roles.first.census_employee.employee_role_id
        subject.migrate
        person.active_employee_roles.first.census_employee.reload
        expect(person.active_employee_roles.first.id).to eq person.active_employee_roles.first.census_employee.employee_role_id
      end

      it 'should not change the ee_role_id of census_employee if the id on EE role is similar' do
        expect(person.active_employee_roles.first.id).to eq person.active_employee_roles.first.census_employee.employee_role_id
        subject.migrate
        person.active_employee_roles.first.census_employee.reload
        expect(person.active_employee_roles.first.id).to eq person.active_employee_roles.first.census_employee.employee_role_id
      end
    end
  end
end
