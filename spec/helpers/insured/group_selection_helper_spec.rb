require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Insured::GroupSelectionHelper, :type => :helper, dbclean: :after_each do
  after :all do
    DatabaseCleaner.clean
  end

  let(:subject)  { Class.new { extend Insured::GroupSelectionHelper } }

  describe "#can shop individual" do
    let(:person) { FactoryBot.create(:person) }

    before(:each) do
      allow(person).to receive(:is_consumer_role_active?).and_return(false)
    end


    it "should not have an active consumer role" do
      expect(subject.can_shop_individual?(person)).not_to be_truthy
    end

    context "with active consumer role" do
      let(:person) { FactoryBot.create(:person, :with_consumer_role) }
      let(:person) { FactoryBot.create(:person, :with_consumer_role) }

      before(:each) do
        allow(person).to receive(:is_consumer_role_active?).and_return(true)
      end
      it "should have active consumer role" do
        expect(subject.can_shop_individual?(person)).to be_truthy
      end

    end
  end

  describe "#can shop shop" do
    let(:person) { FactoryBot.create(:person) }

    it "should not have an active employee role" do
        expect(subject.can_shop_shop?(person)).not_to be_truthy
    end
    context "with active employee role" do
      let(:person) { FactoryBot.create(:person) }
      before do
        allow(person).to receive(:has_active_employee_role?).and_return(true)
      end

      it "should have active employee role but no benefit group" do
        expect(subject.can_shop_shop?(person)).not_to be_truthy
      end

    end

    context "with active employee role and benefit group" do
      let(:person) { FactoryBot.create(:person) }
      before do
        allow(person).to receive(:has_active_employee_role?).and_return(true)
        allow(person).to receive(:has_employer_benefits?).and_return(true)
      end

      it "should have active employee role and benefit group" do
        expect(subject.can_shop_shop?(person)).to be_truthy
      end
    end

  end

  describe "#can shop both" do
    let(:person) { FactoryBot.create(:person) }
    context "with active consumer role" do
      let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_employee_role) }
      before do
        allow(person).to receive(:has_active_employee_role?).and_return(true)
        allow(person).to receive(:is_consumer_role_active?).and_return(true)
      end
      it "should have both active consumer and employee role" do
        expect(subject.can_shop_both_markets?(person)).not_to be_truthy
      end
    end

    context "with active consumer role" do
      let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_employee_role) }
      before do
        allow(person).to receive(:has_active_employee_role?).and_return(true)
        allow(person).to receive(:has_employer_benefits?).and_return(true)
        allow(person).to receive(:is_consumer_role_active?).and_return(true)

      end
      it "should have both active consumer and employee role" do
        expect(subject.can_shop_both_markets?(person)).to be_truthy
      end
    end

  end

  context "relationship_benefits" do

    let(:renewal_benefit_group) { FactoryBot.create(:benefit_group) }
    let(:active_benefit_group) { FactoryBot.create(:benefit_group)}

    context "#health_relationship_benefits" do

      let(:initial_health__relationship_benefits) do
        [
            RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
            RelationshipBenefit.new(offered: true, relationship: :spouse, premium_pct: 75),
            RelationshipBenefit.new(offered: true, relationship: :child_under_26, premium_pct: 50)
        ]
      end

      let(:renewal_health_relationship_benefits) do
        [
            RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
            RelationshipBenefit.new(offered: true, relationship: :spouse, premium_pct: 75)
        ]
      end

      context "active/renewal health benefit group offered relationships" do

        it "should return offered relationships of active health benefit group" do
          allow(active_benefit_group).to receive_message_chain(:relationship_benefits).and_return(initial_health__relationship_benefits)
          expect(helper.health_relationship_benefits(active_benefit_group)).to eq ["employee", "spouse", "child_under_26"]
        end

        it "should return offered relationships of renewal health benefit group" do
          allow(renewal_benefit_group).to receive_message_chain(:relationship_benefits).and_return(renewal_health_relationship_benefits)
          expect(helper.health_relationship_benefits(renewal_benefit_group)).to eq ["employee", "spouse"]
        end
      end
    end

    context "#dental_relationship_benefits" do

      let(:initial_dental_relationship_benefits) do
        [
            RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
            RelationshipBenefit.new(offered: true, relationship: :child_under_26, premium_pct: 50)
        ]
      end

      let(:renewal_dental_relationship_benefits) do
        [
            RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
        ]
      end

      context "active/renewal dental benefit group offered relationships" do

        it "should return offered relationships of active dental benefit group" do
          allow(active_benefit_group).to receive_message_chain(:dental_relationship_benefits).and_return(initial_dental_relationship_benefits)
          expect(helper.dental_relationship_benefits(active_benefit_group)).to eq ["employee", "child_under_26"]
        end

        it "should return offered relationships of renewal dental benefit group" do
          allow(renewal_benefit_group).to receive_message_chain(:dental_relationship_benefits).and_return(renewal_dental_relationship_benefits)
          expect(helper.dental_relationship_benefits(renewal_benefit_group)).to eq ["employee"]
        end
      end
    end
  end

  describe "#select_benefit_group" do
    let(:benefit_group) { double("BenefitGroup")}
    let(:employee_role) { double("EmployeeRole")}

    it "should return nil if market kind is not shop" do
      helper.instance_variable_set("@market_kind", "individual")
      expect(helper.select_benefit_group(false, employee_role)).to eq nil
    end

    it "should return benefit group on employee role if shop" do
      helper.instance_variable_set("@market_kind", "shop")
      helper.instance_variable_set("@employee_role", employee_role)
      allow(employee_role).to receive(:benefit_group).with(qle: false).and_return benefit_group
      expect(helper.select_benefit_group(false, employee_role)).to eq benefit_group
    end
  end

  describe "#view_market_places" do
    let(:person) { FactoryBot.create(:person) }

    it 'returns shop, individual and coverall if all 3 are true' do
      allow(person).to receive(:is_consumer_role_active?).and_return(true)
      allow(person).to receive(:has_employer_benefits?).and_return(true)
      allow(person).to receive(:is_resident_role_active?).and_return(true)

      expect(helper.view_market_places(person)).to eq(['shop', 'individual', 'coverall'])
    end

    it "should return shop & individual if can_shop_both_markets? return true" do
      allow(person).to receive(:is_consumer_role_active?).and_return(true)
      allow(person).to receive(:has_employer_benefits?).and_return(true)
      expect(helper.view_market_places(person)).to eq BenefitMarkets::Products::Product::MARKET_KINDS
      expect(helper.view_market_places(person)).to eq ["shop", "individual"]
    end

    it "should return individual & coverall if can_shop_individual? return true" do
      allow(person).to receive(:is_consumer_role_active?).and_return(true)
      expect(helper.view_market_places(person)).to eq ["individual"]
    end

    it "should return coverall if can_shop_resident? return true" do
      allow(person).to receive(:is_resident_role_active?).and_return(true)
      expect(helper.view_market_places(person)).to eq ["coverall"]
    end

    it "should return individual & coverall if can_shop_individual_or_resident? return true" do
      allow(person).to receive(:is_consumer_role_active?).and_return(true)
      allow(person).to receive(:has_active_resident_member?).and_return(true)
      expect(helper.view_market_places(person)).to eq ["individual", "coverall"]
    end

    it "should return individual if can_shop_individual_or_resident? return false" do
      allow(person).to receive(:is_consumer_role_active?).and_return(true)
      allow(person).to receive(:has_active_resident_member?).and_return(false)
      expect(helper.view_market_places(person)).to eq ["individual"]
    end

    it "should return coverall if can_shop_individual_or_resident? return false" do
      allow(person).to receive(:is_consumer_role_active?).and_return(false)
      allow(person).to receive(:is_resident_role_active?).and_return(true)
      allow(person).to receive(:has_active_resident_member?).and_return(false)
      expect(helper.view_market_places(person)).to eq ["coverall"]
    end
  end

  describe "#get_ivl_market_kind" do

    let(:person) {FactoryBot.create(:person)}
    context "family has primary person with consumer role active" do
      it 'should return individual market if person has active consumer role' do
        allow(person).to receive(:is_consumer_role_active?).and_return(true)
        allow(person).to receive(:is_resident_role_active?).and_return(false)
        expect(helper.get_ivl_market_kind(person)).to eq "individual"
      end
    end

    context "family has primary person with resident role active" do
      it 'should return coverall market if person has active resident role' do
        allow(person).to receive(:is_consumer_role_active?).and_return(false)
        allow(person).to receive(:is_resident_role_active?).and_return(true)
        expect(helper.get_ivl_market_kind(person)).to eq "coverall"
      end
    end

    context "family has primary person with resident role active and dependent with consumer role active" do
      it 'should return individual market for the family' do
        allow(person).to receive(:is_resident_role_active?).and_return(true)
        allow(person).to receive(:has_active_consumer_member?).and_return(true)
        expect(helper.get_ivl_market_kind(person)).to eq "individual"
      end
    end

    context "family has primary person with consumer role active and dependent with resident role active" do
      it 'should return individual market for the family' do
        allow(person).to receive(:is_consumer_role_active?).and_return(true)
        allow(person).to receive(:has_active_resident_member?).and_return(true)
        expect(helper.get_ivl_market_kind(person)).to eq "individual"
      end
    end

  end

  describe "#selected_enrollment" do

    context "selelcting the enrollment" do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup renewal application"

      let(:person)       { FactoryBot.create(:person, :with_family) }
      let(:family)       { person.primary_family }
      let!(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, active_benefit_group_assignment: current_benefit_package.id) }
      let(:employee_role)     { FactoryBot.create(:benefit_sponsors_employee_role, employer_profile: abc_profile, person: person, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: abc_profile.id) }
      let(:qle_kind) { FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date) }
      let(:sep){
        sep = family.special_enrollment_periods.new
        sep.effective_on_kind = 'date_of_event'
        sep.qualifying_life_event_kind= qle_kind
        sep.qle_on= TimeKeeper.date_of_record - 7.days
        sep.save
        sep
      }

      let!(:active_enrollment) do
        FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                          household: family.active_household,
                          family: family,
                          aasm_state: "coverage_selected",
                          kind: "employer_sponsored",
                          effective_on: predecessor_application.start_on,
                          rating_area_id: predecessor_application.recorded_rating_area_id,
                          sponsored_benefit_id: predecessor_application.benefit_packages.first.health_sponsored_benefit.id,
                          sponsored_benefit_package_id: predecessor_application.benefit_packages.first.id,
                          benefit_sponsorship_id: predecessor_application.benefit_sponsorship.id,
                          employee_role_id: employee_role.id)
      end

      let!(:renewal_enrollment) do
        FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                          household: family.active_household,
                          family: family,
                          aasm_state: "renewing_coverage_selected",
                          kind: "employer_sponsored",
                          effective_on: renewal_application.start_on,
                          rating_area_id: renewal_application.recorded_rating_area_id,
                          sponsored_benefit_id: renewal_application.benefit_packages.first.health_sponsored_benefit.id,
                          sponsored_benefit_package_id: renewal_application.benefit_packages.first.id,
                          benefit_sponsorship_id: renewal_application.benefit_sponsorship.id,
                          employee_role_id: employee_role.id)
      end

      before do
        allow(family).to receive(:current_sep).and_return sep
        active_enrollment.update_attribute(:sponsored_benefit_package_id, current_benefit_package.id)
        renewal_enrollment.update_attribute(:sponsored_benefit_package_id, benefit_package.id)
      end

      it "should return active enrollment if the coverage effective on covers active plan year" do
        allow(employee_role.census_employee).to receive(:active_benefit_package).and_return(current_benefit_package)
        expect(subject.selected_enrollment(family, employee_role, active_enrollment.coverage_kind)).to eq active_enrollment
      end

      it "should return renewal enrollment if the coverage effective on covers renewal plan year" do
        allow(employee_role.census_employee).to receive(:renewal_published_benefit_package).and_return(benefit_package)
        sep.update_attribute(:effective_on, renewal_application.start_on + 2.days)
        expect(subject.selected_enrollment(family, employee_role, active_enrollment.coverage_kind)).to eq renewal_enrollment
      end

      it 'should return nil if employee role is not present' do
        expect(subject.selected_enrollment(family, nil, active_enrollment.coverage_kind)).to eq nil
      end

      context 'it should not return any enrollment' do

        before do
          allow(employee_role.census_employee).to receive(:active_benefit_package).and_return nil
          allow(employee_role.census_employee).to receive(:renewal_published_benefit_package).and_return nil
        end

        it "should not return active enrollment although if the coverage effective on covers active plan year & if not belongs to the assigned benefit group" do
          expect(subject.selected_enrollment(family, employee_role, 'health')).to eq nil
        end

        it "should not return renewal enrollment although if the coverage effective on covers renewal plan year & if not belongs to the assigned benefit group" do
          sep.update_attribute(:effective_on, renewal_application.start_on + 2.days)
          expect(subject.selected_enrollment(family, employee_role, 'health')).to eq nil
        end
      end

      context 'it should return terminated or expired enrollment if effective on falls under expired or terminated PY' do
        let(:person)       { FactoryBot.create(:person, :with_family) }
        let(:family)       { person.primary_family }
        let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile_expired_application, site: site) }        # let(:profile)      { binding.pry organization.employer_profile}
        let(:expired_application) { organization.employer_profile.benefit_applications.expired.first }
        let(:profile) { organization.employer_profile }
        let(:expired_benefit_package) { expired_application.benefit_packages.first }
        let!(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: profile, active_benefit_group_assignment: expired_benefit_package.id) }
        let(:employee_role)     { FactoryBot.create(:benefit_sponsors_employee_role, employer_profile: profile, person: person, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: profile.id) }

        let(:qle_kind) { FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date) }

        let(:sep) do
          sep = family.special_enrollment_periods.new
          sep.effective_on_kind = 'date_of_event'
          sep.qualifying_life_event_kind = qle_kind
          sep.qle_on = TimeKeeper.date_of_record - 7.days
          sep.save
          sep
        end

        let!(:expired_enrollment) do
          FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                            household: family.active_household,
                            family: family,
                            aasm_state: "coverage_expired",
                            kind: "employer_sponsored",
                            effective_on: expired_application.start_on,
                            rating_area_id: expired_application.recorded_rating_area_id,
                            sponsored_benefit_id: expired_application.benefit_packages.first.health_sponsored_benefit.id,
                            sponsored_benefit_package_id: expired_application.benefit_packages.first.id,
                            benefit_sponsorship_id: expired_application.benefit_sponsorship.id,
                            employee_role_id: employee_role.id)
        end

        before do
          allow(employee_role).to receive(:census_employee).and_return census_employee
        end

        it "should return benefit group assignment belongs to expired py when benefit_group belongs to expired plan year" do
          expect(subject.selected_enrollment(family, employee_role, 'health')).to eq expired_enrollment
        end
      end
    end
  end

  describe "#benefit_group_assignment_by_plan_year", dbclean: :after_each do
    let(:organization) { FactoryBot.create(:organization, :with_active_and_renewal_plan_years)}
    let(:census_employee) { FactoryBot.create(:census_employee, employer_profile: organization.employer_profile)}
    let(:employee_role) { FactoryBot.create(:employee_role, employer_profile: organization.employer_profile)}

    before do
      allow(employee_role).to receive(:census_employee).and_return census_employee
    end

    it "should return active benefit group assignment when the benefit group belongs to active plan year" do
      benefit_group = organization.employer_profile.active_plan_year.benefit_groups.first
      expect(subject.benefit_group_assignment_by_plan_year(employee_role, benefit_group, nil, nil)).to eq census_employee.active_benefit_group_assignment
    end

    it "should return renewal benefit group assignment when benefit_group belongs to renewing plan year" do
      benefit_group = organization.employer_profile.show_plan_year.benefit_groups.first
      expect(subject.benefit_group_assignment_by_plan_year(employee_role, benefit_group, nil, nil)).to eq census_employee.renewal_benefit_group_assignment
    end

    # EE should have the ability to buy coverage from expired plan year if had an eligible SEP which falls in that period

    context "when EE has an eligible SEP which falls in expired plan year period" do

      let(:organization) { FactoryBot.create(:organization, :with_expired_and_active_plan_years)}

      it "should return benefit group assignment belongs to expired py when benefit_group belongs to expired plan year" do
        benefit_group = organization.employer_profile.plan_years.where(aasm_state: "expired").first.benefit_groups.first
        expired_bga = census_employee.benefit_group_assignments.where(benefit_group_id: benefit_group.id).first
        expect(subject.benefit_group_assignment_by_plan_year(employee_role, benefit_group, nil, "sep")).to eq expired_bga
      end
    end
  end

  describe "disabling & checking market kinds, coverage kinds & kinds when user gets to plan shopping" do
    let(:primary) { FactoryBot.create(:person)}

    context "#is_market_kind_disabled?" do

      context "when user clicked on 'make changes' on the enrollment in open enrollment" do
        context "when user clicked on IVL enrollment" do
          describe "family with IVL and resident roles" do
            before do
              helper.instance_variable_set("@mc_market_kind", "individual")
              allow(helper).to receive(:can_shop_individual_or_resident?).and_return true
            end

            it "should disable the shop market kind if user clicked on 'make changes' for IVL enrollment" do
              expect(helper.is_market_kind_disabled?("shop", primary)).to eq nil
            end

            it "should not disable the IVL market kind if user clicked on 'make changes' for IVL enrollment" do
              expect(helper.is_market_kind_disabled?("individual", primary)).to eq nil
            end

          end

          before do
            helper.instance_variable_set("@mc_market_kind", "individual")
          end

          it "should disable the shop market kind if user clicked on 'make changes' for IVL enrollment" do
            expect(helper.is_market_kind_disabled?("shop", primary)).to eq true
          end

          it "should not disable the IVL market kind if user clicked on 'make changes' for IVL enrollment" do
            expect(helper.is_market_kind_disabled?("individual", primary)).to eq false
          end
        end

        context "when user clicked on shop enrollment" do

          before do
            helper.instance_variable_set("@mc_market_kind", "shop")
          end

          it "should disable the IVL market kind if user clicked on 'make changes' for shop enrollment" do
            expect(helper.is_market_kind_disabled?("individual", primary)).to eq true
          end

          it "should not disable the shop market kind if user clicked on 'make changes' for shop enrollment" do
            expect(helper.is_market_kind_disabled?("shop", primary)).to eq false
          end
        end
      end

      context "when user selected a QLE" do
        let(:primary) { FactoryBot.create(:person)}

        context "when user selected shop QLE" do

          before do
            helper.instance_variable_set("@disable_market_kind", "individual")
          end

          it "should disable the IVL market if user selected shop based QLE" do
            expect(helper.is_market_kind_disabled?("individual", primary)).to eq true
          end

          it "should not disable the shop market if user selected shop based QLE" do
            expect(helper.is_market_kind_disabled?("shop", primary)).to eq false
          end
        end

        context "when user selected IVL QLE" do

          before do
            helper.instance_variable_set("@disable_market_kind", "shop")
          end

          it "should disable the shop market if user selected IVL based QLE" do
            expect(helper.is_market_kind_disabled?("shop", primary)).to eq true
          end

          it "should not disable the shop market if user selected shop based QLE" do
            expect(helper.is_market_kind_disabled?("individual", primary)).to eq false
          end
        end
      end
    end

    context "#is_market_kind_checked?" do

      context "when user clicked on 'make changes' on the enrollment in open enrollment" do
        context "when user clicked on IVL enrollment" do

          before do
            helper.instance_variable_set("@mc_market_kind", "individual")
          end

          it "should not check the shop market kind if user clicked on 'make changes' for IVL enrollment" do
            expect(helper.is_market_kind_checked?("shop", nil)).to eq false
          end

          it "should check the IVL market kind if user clicked on 'make changes' for IVL enrollment" do
            expect(helper.is_market_kind_checked?("individual", nil)).to eq true
          end
        end

        context "when user clicked on shop enrollment" do

          before do
            helper.instance_variable_set("@mc_market_kind", "shop")
          end

          it "should not check the IVL market kind if user clicked on 'make changes' for shop enrollment" do
            expect(helper.is_market_kind_checked?("individual", nil)).to eq false
          end

          it "should check the shop market kind if user clicked on 'make changes' for shop enrollment" do
            expect(helper.is_market_kind_checked?("shop", nil)).to eq true
          end
        end
      end
    end

    context "#is_employer_disabled?" do
      let(:site) { FactoryBot.create(:benefit_sponsors_site,  :with_benefit_market, :dc, :as_hbx_profile) }

      let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization,
        :with_aca_shop_dc_employer_profile_initial_application,
        site: site
       )}

      let(:employer_profile) { organization.employer_profile }

      let(:employee_role_one) { FactoryBot.create(:employee_role, employer_profile: employer_profile)}
      let(:employee_role_two) { FactoryBot.create(:employee_role, employer_profile: employer_profile)}
      let!(:hbx_enrollment) { double("HbxEnrollment", employee_role: employee_role_one)}

      context "when user clicked on 'make changes' on the enrollment in open enrollment" do
        context "when user clicked on IVL enrollment" do

          before do
            helper.instance_variable_set("@mc_market_kind", "individual")
          end

          it "should disable all the employers if user clicked on 'make changes' for IVL enrollment" do
            expect(helper.is_employer_disabled?(employee_role_one)).to eq true
            expect(helper.is_employer_disabled?(employee_role_two)).to eq true
          end
        end

        context "when user clicked on shop enrollment" do

          before do
            helper.instance_variable_set("@mc_market_kind", "shop")
            helper.instance_variable_set("@hbx_enrollment", hbx_enrollment)
          end

          it "should not disable the current employer if user clicked on 'make changes' for shop enrollment" do
            expect(helper.is_employer_disabled?(employee_role_one)).to eq false
          end

          it "should disable all the other employers other than the one user clicked shop enrollment ER" do
            expect(helper.is_employer_disabled?(employee_role_two)).to eq true
          end
        end
      end

      context "when user clicked on shop for plans" do
        before do
          helper.instance_variable_set("@mc_market_kind", nil)
        end

        it "should not disable all the employers if user clicked on 'make changes' for IVL enrollment" do
          expect(helper.is_employer_disabled?(employee_role_one)).to eq false
          expect(helper.is_employer_disabled?(employee_role_two)).to eq false
        end
      end
    end

    context "#is_employer_checked?" do
      let(:site) { FactoryBot.create(:benefit_sponsors_site,  :with_benefit_market, :dc, :as_hbx_profile) }

      let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization,
        :with_aca_shop_dc_employer_profile_initial_application,
        site: site
       )}

      let(:employer_profile) { organization.employer_profile }

      let(:employee_role_one) { FactoryBot.create(:employee_role, employer_profile: employer_profile)}
      let(:employee_role_two) { FactoryBot.create(:employee_role, employer_profile: employer_profile)}
      let!(:hbx_enrollment) { double("HbxEnrollment", employee_role: employee_role_one)}

      context "when user clicked on 'make changes' on the enrollment in open enrollment" do
        context "when user clicked on IVL enrollment" do

          before do
            helper.instance_variable_set("@mc_market_kind", "individual")
          end

          it "should not check any of the employers when user clicked on 'make changes' for IVL enrollment" do
            expect(helper.is_employer_checked?(employee_role_one)).to eq false
            expect(helper.is_employer_checked?(employee_role_two)).to eq false
          end
        end

        context "when user clicked on shop enrollment" do

          before do
            helper.instance_variable_set("@mc_market_kind", "shop")
            helper.instance_variable_set("@hbx_enrollment", hbx_enrollment)
          end

          it "should check the current employer if user clicked on 'make changes' for shop enrollment" do
            expect(helper.is_employer_checked?(employee_role_one)).to eq true
          end

          it "should not check all the other employers other than the one user clicked shop enrollment ER" do
            expect(helper.is_employer_checked?(employee_role_two)).to eq false
          end
        end
      end

      context "when user clicked on shop for plans" do
        before do
          helper.instance_variable_set("@mc_market_kind", nil)
          helper.instance_variable_set("@employee_role", employee_role_one)
        end

        it "should check the first employee role by default" do
          expect(helper.is_employer_checked?(employee_role_one)).to eq true
        end

        it "should not check the other employee roles" do
          expect(helper.is_employer_checked?(employee_role_two)).to eq false
        end
      end
    end

    context "#is_coverage_kind_disabled?" do

      context "when user clicked on 'make changes' on the enrollment in open enrollment" do
        context "when user clicked on health enrollment" do

          before do
            helper.instance_variable_set("@mc_coverage_kind", "health")
          end

          it "should disable the dental coverage kind" do
            expect(helper.is_coverage_kind_disabled?("dental")).to eq true
          end

          it "should not disable the health coverage kind" do
            expect(helper.is_coverage_kind_disabled?("health")).to eq false
          end
        end

        context "when user clicked on dental enrollment" do

          before do
            helper.instance_variable_set("@mc_coverage_kind", "dental")
          end

          it "should not disable the dental coverage kind" do
            expect(helper.is_coverage_kind_disabled?("dental")).to eq false
          end

          it "should disable the health coverage kind" do
            expect(helper.is_coverage_kind_disabled?("health")).to eq true
          end
        end
      end

      context "when user clicked on shop for plans" do

        before do
          helper.instance_variable_set("@mc_market_kind", nil)
        end

        it "should not disable the health coverage kind" do
          expect(helper.is_coverage_kind_disabled?("health")).to eq false
        end

        it "should not disable the dental coverage kind" do
          expect(helper.is_coverage_kind_disabled?("dental")).to eq false
        end
      end
    end

    context "#is_coverage_kind_checked?" do

      context "when user clicked on 'make changes' on the enrollment in open enrollment" do
        context "when user clicked on health enrollment" do

          before do
            helper.instance_variable_set("@mc_coverage_kind", "health")
          end

          it "should not check the dental coverage kind" do
            expect(helper.is_coverage_kind_checked?("dental")).to eq false
          end

          it "should check the health coverage kind" do
            expect(helper.is_coverage_kind_checked?("health")).to eq true
          end
        end

        context "when user clicked on dental enrollment" do

          before do
            helper.instance_variable_set("@mc_coverage_kind", "dental")
          end

          it "should check the dental coverage kind" do
            expect(helper.is_coverage_kind_checked?("dental")).to eq true
          end

          it "should not check the health coverage kind" do
            expect(helper.is_coverage_kind_checked?("health")).to eq false
          end
        end
      end

      context "when user clicked on shop for plans" do

        before do
          helper.instance_variable_set("@mc_market_kind", nil)
        end

        it "should check the health coverage kind by default" do
          expect(helper.is_coverage_kind_checked?("health")).to eq true
        end

        it "should not check the dental coverage kind" do
          expect(helper.is_coverage_kind_checked?("dental")).to eq false
        end
      end
    end
  end

  describe "#is_eligible_for_dental?" do
    let(:site) { FactoryBot.create(:benefit_sponsors_site,  :with_benefit_market, :dc, :as_hbx_profile) }

    let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization,
        :with_aca_shop_dc_employer_profile_initial_application,
        site: site
       )}

    let(:employer_profile) { organization.employer_profile }


    let(:active_bg) { double("ActiveBenefitGroup", plan_year: double("ActivePlanYear")) }
    let(:renewal_bg) { double("RenewalBenefitGroup", plan_year: double("RenewingPlanYear")) }
    let(:employee_role) { FactoryBot.create(:employee_role, employer_profile: employer_profile)}
    let(:census_employee) { double("CensusEmployee", active_benefit_group: active_bg, employer_profile: employer_profile)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: employee_role.person)}
    let!(:sep) { FactoryBot.create(:special_enrollment_period, family: family, effective_on: TimeKeeper.date_of_record)}

    before do
      allow(employee_role).to receive(:census_employee).and_return census_employee
      allow(employee_role).to receive(:can_enroll_as_new_hire?).and_return false
    end

    context "when ER is an initial ER" do

      before do
        allow(census_employee).to receive(:renewal_published_benefit_group).and_return nil
      end

      it "should return true if active benefit group offers dental" do
        allow(active_bg).to receive(:is_offering_dental?).and_return true
        expect(helper.is_eligible_for_dental?(employee_role, nil, nil)).to eq true
      end

      it "should return false if active benefit group not offers dental" do
        allow(active_bg).to receive(:is_offering_dental?).and_return false
        expect(helper.is_eligible_for_dental?(employee_role, nil, nil)).to eq false
      end
    end

    context "when ER is in renewing period" do

      before do
        allow(census_employee).to receive(:renewal_published_benefit_group).and_return renewal_bg
      end

      context "when EE is in renewal open enrollment & clicked on shop for plans" do

        it "should return true if renewal benefit group offers dental" do
          allow(renewal_bg).to receive(:is_offering_dental?).and_return true
          expect(helper.is_eligible_for_dental?(employee_role, nil, nil)).to eq true
        end

        it "should return false if renewal benefit group not offers dental" do
          allow(renewal_bg).to receive(:is_offering_dental?).and_return false
          expect(helper.is_eligible_for_dental?(employee_role, nil, nil)).to eq false
        end
      end

      context "when EE selects SEP & effective_on does not covers under renewal plan year period", dbclean: :after_each do

        before do
          allow(renewal_bg).to receive(:is_offering_dental?).and_return true
          allow(sep).to receive(:is_eligible?).and_return true
          allow(helper).to receive(:is_covered_plan_year?).with(renewal_bg.plan_year, sep.effective_on).and_return false
          sep.update_attributes!(start_on: TimeKeeper.date_of_record - 10.days, end_on: TimeKeeper.date_of_record + 10.days) unless sep.is_active?
        end

        it "should return true if active benefit group offers dental" do
          allow(active_bg).to receive(:is_offering_dental?).and_return true
          expect(helper.is_eligible_for_dental?(employee_role, "change_by_qle", nil)).to eq true
        end

        it "should return false if active benefit group not offers dental" do
          allow(active_bg).to receive(:is_offering_dental?).and_return false
          expect(helper.is_eligible_for_dental?(employee_role, "change_by_qle", nil)).to eq false
        end
      end

      context "when EE selects SEP & effective_on covers under renewal plan year period", dbclean: :after_each do

        before do
          allow(active_bg).to receive(:is_offering_dental?).and_return true
          allow(sep).to receive(:is_eligible?).and_return true
          allow(helper).to receive(:is_covered_plan_year?).with(renewal_bg.plan_year, sep.effective_on).and_return true
          sep.update_attributes!(start_on: TimeKeeper.date_of_record - 10.days, end_on: TimeKeeper.date_of_record + 10.days) unless sep.is_active?
        end

        it "should return true if renewal benefit group offers dental" do
          allow(renewal_bg).to receive(:is_offering_dental?).and_return true
          expect(helper.is_eligible_for_dental?(employee_role, "change_by_qle", nil)).to eq true
        end

        it "should return false if renewal benefit group not offers dental" do
          allow(renewal_bg).to receive(:is_offering_dental?).and_return false
          expect(helper.is_eligible_for_dental?(employee_role, "change_by_qle", nil)).to eq false
        end
      end

      context "when EE is in new hire enrollment period" do
        before do
          allow(employee_role).to receive(:can_enroll_as_new_hire?).and_return true
        end
        it "should return true if active benefit group offers dental" do
          allow(active_bg).to receive(:is_offering_dental?).and_return true
          expect(helper.is_eligible_for_dental?(employee_role, nil, nil)).to eq true
        end

        it "should return false if active benefit group not offers dental" do
          allow(active_bg).to receive(:is_offering_dental?).and_return false
          expect(helper.is_eligible_for_dental?(employee_role, nil, nil)).to eq false
        end
      end

      context "when EE clicked on make changes button of a shop enrollment" do
        let(:enrollment) { double("HbxEnrollment", benefit_group: renewal_bg, is_shop?: true)}

        it "should return true if benefit group on enrollment offers dental" do
          allow(renewal_bg).to receive(:is_offering_dental?).and_return true
          expect(helper.is_eligible_for_dental?(employee_role, "change_plan", enrollment)).to eq true
        end

        it "should return false if benefit group on enrollment does not offers dental" do
          allow(renewal_bg).to receive(:is_offering_dental?).and_return false
          expect(helper.is_eligible_for_dental?(employee_role, "change_plan", enrollment)).to eq false
        end
      end

      context "when EE clicked on make changes button of an ivl enrollment" do
        let(:enrollment) { double("HbxEnrollment", benefit_group: renewal_bg, is_shop?: false)}
        before do
          allow(employee_role).to receive(:can_enroll_as_new_hire?).and_return true
        end
        it "should not depend on enrollment benefit group" do
          allow(active_bg).to receive(:is_offering_dental?).and_return false
          allow(renewal_bg).to receive(:is_offering_dental?).and_return true
          expect(helper.is_eligible_for_dental?(employee_role, "change_plan", enrollment)).to eq false
        end
      end
    end
  end

  describe "#class_for_ineligible_row" do
    let(:site) { FactoryBot.create(:benefit_sponsors_site,  :with_benefit_market, :dc, :as_hbx_profile) }

    let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization,
        :with_aca_shop_dc_employer_profile_initial_application,
        site: site
       )}

    let(:employer_profile) { organization.employer_profile }
    let(:person) { FactoryBot.create(:person, :with_family)}
    let(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: employer_profile)}
    # let(:employee_role_2) { FactoryBot.create(:employee_role, person: employee_role_1.person)}

    before do
      assign(:"person", person)
      allow(person).to receive(:active_employee_roles).and_return [employee_role]
      @member = person.primary_family.primary_applicant
    end

    it "should return a string" do
      allow(helper).to receive(:shop_health_and_dental_attributes).and_return([nil, nil])
      expect(helper.class_for_ineligible_row(@member, nil).class).to eq String
    end

    it "should have 'ineligible_health_employee_role_id' class if not eligible for ER sponsored health benefits" do
      allow(helper).to receive(:shop_health_and_dental_attributes).with(@member, employee_role).and_return([false, nil])
      expect(helper.class_for_ineligible_row(@member, nil).include?("ineligible_health_row_#{employee_role.id}")).to eq true
    end

    it "should have 'ineligible_dental_employee_role_id' class if not eligible for ER sponsored dental benefits" do
      allow(helper).to receive(:shop_health_and_dental_attributes).with(@member, employee_role).and_return([nil, false])
      expect(helper.class_for_ineligible_row(@member, nil).include?("ineligible_dental_row_#{employee_role.id}")).to eq true
    end

    it "should have both 'ineligible_dental' & 'ineligible_health' classes if not eligible for both types of ER sponsored benefits" do
      allow(helper).to receive(:shop_health_and_dental_attributes).with(@member, employee_role).and_return([false, false])
      expect(helper.class_for_ineligible_row(@member, nil).include?("ineligible_health_row_#{employee_role.id}")).to eq true
      expect(helper.class_for_ineligible_row(@member, nil).include?("ineligible_dental_row_#{employee_role.id}")).to eq true
    end

    it "should have 'ineligible_ivl_row' class if not eligible for IVL benefits" do
      allow(helper).to receive(:shop_health_and_dental_attributes).with(@member, employee_role).and_return([nil, nil])
      expect(helper.class_for_ineligible_row(@member, false).include?("ineligible_ivl_row")).to eq true
    end

    it "should not have 'ineligible_health_employee_role_id' class if eligible for ER sponsored health benefits" do
      allow(helper).to receive(:shop_health_and_dental_attributes).with(@member, employee_role).and_return([true, nil])
      expect(helper.class_for_ineligible_row(@member, nil).include?("ineligible_health_row_#{employee_role.id}")).to eq false
    end

    it "should not have 'ineligible_dental_employee_role_id' class if eligible for ER sponsored dental benefits" do
      allow(helper).to receive(:shop_health_and_dental_attributes).with(@member, employee_role).and_return([nil, true])
      expect(helper.class_for_ineligible_row(@member, nil).include?("ineligible_dental_row_#{employee_role.id}")).to eq false
    end

    it "should not have 'ineligible_ivl_row' class if eligible for IVL benefits" do
      allow(helper).to receive(:shop_health_and_dental_attributes).with(@member, employee_role).and_return([nil, nil])
      expect(helper.class_for_ineligible_row(@member, true).include?("ineligible_ivl_row")).to eq false
    end

    it "should have 'is_primary' class for primary person" do
      allow(helper).to receive(:shop_health_and_dental_attributes).with(@member, employee_role).and_return([nil, nil])
      expect(helper.class_for_ineligible_row(@member, true).include?("is_primary")).to eq true
    end
  end
end
