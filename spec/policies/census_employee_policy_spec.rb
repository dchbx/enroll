require "rails_helper"
require "spec_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"


describe CensusEmployeePolicy, dbclean: :after_each do
  subject { described_class }
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"
  let(:employer_profile){abc_profile}
  let(:person) { FactoryBot.create(:person) }
  let!(:benefit_group) { current_benefit_package }
  let!(:employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, benefit_group: benefit_group) }
  let!(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: abc_profile, census_employee_id: employee.id) }
  let!(:benefit_group_assignment) { FactoryBot.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: employee)}
  let(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
  let(:broker_person) { FactoryBot.create(:person, :with_broker_role) }
  let(:employer_staff_person) { FactoryBot.create(:person,:with_employer_staff_role) }
  let(:general_agency_person) { FactoryBot.create(:person,:with_general_agency_staff_role) }

  before do
    allow_any_instance_of(CensusEmployee).to receive(:generate_and_deliver_checkbook_url).and_return(true)
  end

  permissions :delink? do
    context "already linked" do
      let(:employee_state) { "employee_role_linked"}

      context "with perosn with appropriate roles" do
        it "grants access when hbx_staff" do
          employee.link_employee_role
          expect(subject).to permit(FactoryBot.create(:user, :hbx_staff, person: admin_person), employee)
        end

        it "grants access when broker" do
          employee.link_employee_role
          expect(subject).to permit(FactoryBot.create(:user, :broker, person: broker_person), employee)
        end

        it "grants access when broker_agency_staff" do
          employee.link_employee_role
          expect(subject).to permit(FactoryBot.create(:user, :broker_agency_staff, person: broker_person), employee)
        end
      end

      it "denies access when normal user" do
        expect(subject).not_to permit(FactoryBot.create(:user), employee)
      end
    end

    context "not linked" do
      let(:employee_state) { "eligible"}

      it "denies access when hbx_staff" do
        expect(subject).not_to permit(FactoryBot.create(:user, :hbx_staff, person: admin_person), employee)
      end

      it "denies access when broker" do
        expect(subject).not_to permit(FactoryBot.create(:user, :broker, person: broker_person), employee)
      end

      it "denies access when broker_agency_staff" do
        expect(subject).not_to permit(FactoryBot.create(:user, :broker_agency_staff, person: broker_person), employee)
      end

      it "denies access when normal user" do
        expect(subject).not_to permit(FactoryBot.create(:user, person: person), employee)
      end
    end
  end

  permissions :update? do
    let(:employee_state) { "eligible"}
    context "when is hbx_staff user" do
      let(:user) { FactoryBot.create(:user, :hbx_staff, person: admin_person) }

      it "grants access when change dob" do
        employee.dob = TimeKeeper.date_of_record
        expect(subject).to permit(user, employee)
      end

      it "grants access when change ssn" do
        employee.ssn = "123321456"
        expect(subject).to permit(user, employee)
      end
    end

    context "when is normal user" do
      let(:user) { FactoryBot.create(:user) }

      it "denies access when change dob" do
        employee.dob = TimeKeeper.date_of_record
        expect(subject).not_to permit(user, employee)
      end

      it "denies access when change ssn" do
        employee.ssn = "123321456"
        expect(subject).not_to permit(user, employee)
      end
    end

    context "when is broker user" do
      let(:user) { FactoryBot.create(:user, :broker, person: person) }

      context "current user is broker of employer_profile" do
        before :each do
          allow(employer_profile).to receive(:active_broker).and_return person
          allow(employee).to receive(:employer_profile).and_return employer_profile
        end

        it "grants access when change dob" do
          employee.dob = TimeKeeper.date_of_record
          expect(subject).to permit(user, employee)
        end

        it "grants access when change ssn" do
          employee.ssn = "123321456"
          expect(subject).to permit(user, employee)
        end
      end

      context "current user is not broker of employer_profile" do
        before :each do
          allow(employer_profile).to receive(:active_broker).and_return FactoryBot.build(:person)
          allow(employee).to receive(:employer_profile).and_return employer_profile
        end

        it "denies access when change dob" do
          employee.dob = TimeKeeper.date_of_record
          expect(subject).not_to permit(user, employee)
        end

        it "denies access when change ssn" do
          employee.ssn = "123321456"
          expect(subject).not_to permit(user, employee)
        end
      end
    end

    context "when is employer_staff user" do
      let(:user) { FactoryBot.create(:user, :employer_staff) }

      context "not linked" do
        before do
          allow(employee).to receive(:eligible?).and_return(true)
        end

        context "when employee is staff of current user" do
          let(:employer_staff_role) {double(benefit_sponsor_employer_profile_id: employee.benefit_sponsors_employer_profile_id)}
          let(:employer_staff_roles) { [employer_staff_role] }
          before :each do
            allow(person).to receive(:employer_staff_roles).and_return employer_staff_roles
            allow(user).to receive(:person).and_return person
            allow(employee).to receive(:employer_profile_id).and_return employer_profile.id
          end

          it "grants access when change dob" do
            employee.dob = TimeKeeper.date_of_record
            expect(subject).to permit(user, employee)
          end

          it "grants access when change ssn" do
            employee.ssn = "123321456"
            expect(subject).to permit(user, employee)
          end
        end

        context "when employee is not staff of current user" do
          let(:employer_staff_role) {double(benefit_sponsor_employer_profile_id: EmployerProfile.new.id)}
          let(:employer_staff_roles) { [employer_staff_role] }
          before :each do
            allow(person).to receive(:employer_staff_roles).and_return employer_staff_roles
            allow(user).to receive(:person).and_return person
            allow(employee).to receive(:employer_profile_id).and_return employer_profile.id
          end

          it "denies access when change dob" do
            employee.dob = TimeKeeper.date_of_record
            expect(subject).not_to permit(user, employee)
          end

          it "denies access when change ssn" do
            employee.ssn = "123321456"
            expect(subject).not_to permit(user, employee)
          end
        end
      end

      context "has linked" do
        before do
          allow(employee).to receive(:eligible?).and_return(false)
        end

        context "when employee is staff of current user" do
          let(:employer_staff_role) {double(benefit_sponsor_employer_profile_id: employee.benefit_sponsors_employer_profile_id)}
          let(:employer_staff_roles) { [employer_staff_role] }
          before :each do
            allow(person).to receive(:employer_staff_roles).and_return employer_staff_roles
            allow(user).to receive(:person).and_return person
            allow(employee).to receive(:employer_profile_id).and_return employer_profile.id
          end

          it "grants access when change dob" do
            employee.dob = TimeKeeper.date_of_record
            expect(subject).to permit(user, employee)
          end

          it "grants access when change ssn" do
            employee.ssn = "123321456"
            expect(subject).to permit(user, employee)
          end
        end

        context "when employee is not staff of current user" do
          let(:employer_staff_role) {double(benefit_sponsor_employer_profile_id: EmployerProfile.new.id)}
          let(:employer_staff_roles) { [employer_staff_role] }
          before :each do
            allow(person).to receive(:employer_staff_roles).and_return employer_staff_roles
            allow(user).to receive(:person).and_return person
            allow(employee).to receive(:employer_profile_id).and_return employer_profile.id
          end

          it "denies access when change dob" do
            employee.dob = TimeKeeper.date_of_record
            expect(subject).not_to permit(user, employee)
          end

          it "denies access when change ssn" do
            employee.ssn = "123321456"
            expect(subject).not_to permit(user, employee)
          end
        end
      end
    end
    context "when is general agency user", dbclean: :after_each do
      let(:user) { FactoryBot.create(:user, :general_agency_staff, person: person) }
      context "current user is broker of employer_profile" do

        let!(:employee) { FactoryBot.create(:census_employee, benefit_sponsors_employer_profile_id: bs_employer_profile.id, aasm_state: "eligible", employer_profile_id: '', benefit_sponsorship: benefit_sponsorship) }
        let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
        let(:start_on) { TimeKeeper.date_of_record }
        let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
        let!(:bs_employer_profile)    { organization.employer_profile }
        let!(:benefit_sponsorship) do
          bs = bs_employer_profile.add_benefit_sponsorship
          bs.save
          bs
        end

        let(:broker_agency) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site)}
        let(:broker_agency_profile)  { broker_agency.broker_agency_profile }

        let(:general_agency) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site) }
        let(:general_agency_profile) { general_agency.profiles.first }

        let!(:plan_design_organization) { FactoryBot.create(:sponsored_benefits_plan_design_organization, has_active_broker_relationship: true, sponsor_profile_id: bs_employer_profile.id) }
        let!(:general_agency_account) { plan_design_organization.general_agency_accounts.create(general_agency_profile: general_agency_profile, start_on: start_on, broker_role_id: broker_agency_profile.primary_broker_role.id) }

        let(:person) { FactoryBot.create(:person) }
        let!(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, person: person) }

        before :each do
          allow(EmployerProfile).to receive(:find_by_general_agency_profile).with(
            user.person.general_agency_staff_roles.first.general_agency_profile
          ).and_return([CensusEmployee.first.employer_profile])
        end

        it "grants access when change dob" do
          employee.dob = TimeKeeper.date_of_record
          expect(subject).to permit(user, employee)
        end

        it "grants access when change ssn" do
          employee.ssn = "879876"
          expect(subject).to permit(user, employee)
        end
      end
    end
  end

  permissions :show? do
    let(:employee_state) { "eligible"}

    context "hbx_staff user" do
      let(:user) { FactoryBot.create(:user, :hbx_staff, person: admin_person) }

      it "grants access" do
        expect(subject).to permit(user, employee)
      end
    end

    context "wnormal user" do
      let(:user) { FactoryBot.create(:user) }
      it "denies access" do
        expect(subject).not_to permit(user, employee)
      end
    end

    context "broker user" do
      let(:user) { FactoryBot.create(:user, :broker, person: person) }

      context "current user is broker of employer_profile" do
        before :each do
          allow(employer_profile).to receive(:active_broker).and_return person
          allow(employee).to receive(:employer_profile).and_return employer_profile
        end
        it "grants access" do
          expect(subject).to permit(user, employee)
        end
      end

      context "current user is not broker of employer_profile" do
        before :each do
          allow(employer_profile).to receive(:active_broker).and_return FactoryBot.build(:person)
          allow(employee).to receive(:employer_profile).and_return employer_profile
        end
        it "denies access" do
          expect(subject).not_to permit(user, employee)
        end
      end
    end

    context "employer_staff user" do
      let(:user) { FactoryBot.create(:user, :employer_staff) }

      context "not linked" do
        before do
          allow(employee).to receive(:eligible?).and_return(true)
        end

        context "employee is staff of current user" do
          let(:employer_staff_role) {double(benefit_sponsor_employer_profile_id: employee.benefit_sponsors_employer_profile_id)}
          let(:employer_staff_roles) { [employer_staff_role] }
          before :each do
            allow(person).to receive(:employer_staff_roles).and_return employer_staff_roles
            allow(user).to receive(:person).and_return person
            allow(employee).to receive(:employer_profile).and_return employer_profile
          end

          it "grants access" do
            expect(subject).to permit(user, employee)
          end
        end

        context "employee is not staff of current user" do
          let(:employer_staff_role) {double(benefit_sponsor_employer_profile_id: EmployerProfile.new.id)}
          let(:employer_staff_roles) { [employer_staff_role] }
          before :each do
            allow(person).to receive(:employer_staff_roles).and_return employer_staff_roles
            allow(user).to receive(:person).and_return person
            allow(employee).to receive(:employer_profile).and_return employer_profile
          end
          it "denies access" do
            expect(subject).not_to permit(user, employee)
          end
        end
      end

      context "has linked" do
        before do
          allow(employee).to receive(:eligible?).and_return(false)
        end

        context "employee is staff of current user" do
          let(:employer_staff_role) {double(benefit_sponsor_employer_profile_id: employee.benefit_sponsors_employer_profile_id)}
          let(:employer_staff_roles) { [employer_staff_role] }
          before :each do
            allow(person).to receive(:employer_staff_roles).and_return employer_staff_roles
            allow(user).to receive(:person).and_return person
            allow(employee).to receive(:employer_profile).and_return employer_profile
          end

          it "grants access" do
            expect(subject).to permit(user, employee)
          end
        end

        context "employee is not staff of current user" do

          let(:employer_staff_role) {double(benefit_sponsor_employer_profile_id: EmployerProfile.new.id)}
          let(:employer_staff_roles) { [employer_staff_role] }
          before :each do
            allow(person).to receive(:employer_staff_roles).and_return employer_staff_roles
            allow(user).to receive(:person).and_return person
            allow(employer_staff_role).to receive(:active).and_return true
          end
          it "denies access" do
            expect(subject).not_to permit(user, employee)
          end
        end
      end
    end

    context "general agency user not linked to the employer", dbclean: :after_each do
      let(:user) { FactoryBot.create(:user, :general_agency_staff, person: person) }
      let(:general_agency_profile_double) { double('GeneralAgencyProfile', id: 1) }
      let(:organizations_scope_double) { [instance_double('SponsoredBenefits::Organizations::PlanDesignOrganization', general_agency_profile: general_agency_profile_double, id: 1)] }
      context "current user is broker of employer_profile" do
        let(:person) { FactoryBot.create(:person, :with_general_agency_staff_role) }
        # This is to stub
        # return true if a.general_agency_profile.id == ga_id
        # in #show? of census_employee_policy
        before do
          allow(user).to receive(:has_general_agency_staff_role?).and_return true
          allow(EmployerProfile).to receive(:find_by_general_agency_profile).and_return [employee.employer_profile]
          allow(user.person.general_agency_staff_roles.last).to receive(:general_agency_profile).and_return(general_agency_profile_double)
          allow(SponsoredBenefits::Organizations::PlanDesignOrganization).to receive(:find_by_sponsor).with(CensusEmployee.first.employer_profile.id).and_return(organizations_scope_double)
        end

        # in the original PR on this, the 'it' says "grant access" but expects not to permit.
        # https://github.com/dchbx/enroll/pull/2782/files
        # According to the original developer, both of these should be "denies access."
        it "grants access" do
          expect(subject).to permit(user, employee)
        end
      end

      context "current user is not broker of general agency role" do
        let(:user) { FactoryBot.create(:user, person: person) }
        it "denies access" do
          expect(subject).not_to permit(user, employee)
        end
      end
    end
  end
end
