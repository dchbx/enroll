require "rails_helper"
require File.join(Rails.root, "components", "benefit_sponsors", "app", "data_migrations", "modify_benefit_application")

describe ModifyBenefitApplication do

  let(:given_task_name) { "modify_benefit_application" }
  subject { ModifyBenefitApplication.new(given_task_name, double(:current_scope => nil)) }

  after :each do
    DatabaseCleaner.clean
  end

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "modifying benefit application" do

    let(:current_effective_date)  { TimeKeeper.date_of_record }
    let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                            benefit_market: benefit_market,
                                            title: "SHOP Benefits for #{current_effective_date.year}",
                                            application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
                                          }
    let(:benefit_market)      { site.benefit_markets.first }
    let!(:product_package) { benefit_market_catalog.product_packages.first }

    let!(:rating_area)   { FactoryGirl.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)  { FactoryGirl.create_default :benefit_markets_locations_service_area }
    let!(:security_question)  { FactoryGirl.create_default :security_question }

    let(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    let(:benefit_sponsorship) do
      FactoryGirl.create(
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
      application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, effective_period: effective_period, aasm_state: :active)
      application.benefit_sponsor_catalog.save!
      application
    }

    let!(:benefit_package) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }
    let(:benefit_group_assignment) {FactoryGirl.build(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package)}

    let(:employee_role) { FactoryGirl.create(:benefit_sponsors_employee_role, person: person, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee.id) }
    let(:census_employee) { FactoryGirl.create(:benefit_sponsors_census_employee,
      employer_profile: benefit_sponsorship.profile,
      benefit_sponsorship: benefit_sponsorship,
      benefit_group_assignments: [benefit_group_assignment]
    )}
    let(:person) { FactoryGirl.create(:person) }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}

    let!(:hbx_enrollment) do
      FactoryGirl.create(:hbx_enrollment,
                         household: family.active_household,
                         kind: "employer_sponsored",
                         effective_on: start_on,
                         employee_role_id: employee_role.id,
                         sponsored_benefit_package_id: benefit_package.id,
                         benefit_group_assignment_id: benefit_group_assignment.id,
                         aasm_state: 'coverage_selected'
      )
    end

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
    end

    context "terminate benefit application" do
      let(:termination_date) { start_on.next_month.next_day }
      let(:end_on)           { start_on.next_month.end_of_month }

      before do
        allow(ENV).to receive(:[]).with("termination_notice").and_return("true")
        allow(ENV).to receive(:[]).with("action").and_return("terminate")
        allow(ENV).to receive(:[]).with("termination_date").and_return(termination_date.to_s)
        allow(ENV).to receive(:[]).with("end_on").and_return(end_on.to_s)
        subject.migrate
        benefit_application.reload
        hbx_enrollment.reload
      end

      it "should terminate the benefit application" do
        expect(benefit_application.aasm_state).to eq :terminated
      end

      it "should update end on date on benefit application" do
        expect(benefit_application.end_on).to eq end_on
      end

      it "should update end on date on benefit application" do
        expect(benefit_application.terminated_on).to eq termination_date
      end

      it "should terminate any active employee enrollments" do
        expect(hbx_enrollment.aasm_state).to eq "coverage_terminated"
      end
    end

    context "should trigger termination notice", db_clean: :after_each do

      let(:termination_date) { start_on.next_month.next_day }
      let(:end_on)           { start_on.next_month.end_of_month }

      before do
        allow(ENV).to receive(:[]).with("termination_notice").and_return("true")
        allow(ENV).to receive(:[]).with("action").and_return("terminate")
        allow(ENV).to receive(:[]).with("termination_date").and_return(termination_date.to_s)
        allow(ENV).to receive(:[]).with("end_on").and_return(end_on.to_s)
      end

      let(:model_instance) { benefit_application }

      context "should trigger termination notice to employer and employees" do
        it "should trigger model event" do
          model_instance.class.observer_peers.keys.each do |observer|
            expect(observer).to receive(:notifications_send) do |instance, model_event|
              expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
              expect(model_event).to have_attributes(:event_key => :group_advance_termination_confirmation, :klass_instance => model_instance, :options => {})
            end
          end
          subject.migrate
        end
      end
    end
  end
end
