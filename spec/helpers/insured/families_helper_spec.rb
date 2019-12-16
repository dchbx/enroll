require "rails_helper"

RSpec.describe Insured::FamiliesHelper, :type => :helper do

  describe "#plan_shopping_dependent_text" do
    let(:person) { FactoryBot.build_stubbed(:person)}
    let(:family) { FactoryBot.build_stubbed(:family, :with_primary_family_member, person: person) }
    let(:household) { FactoryBot.build_stubbed(:household, family: family) }
    let(:hbx_enrollment) { FactoryBot.build_stubbed(:hbx_enrollment, household: household, hbx_enrollment_members: [hbx_enrollment_member, hbx_enrollment_member_two]) }
    let(:hbx_enrollment_member) { FactoryBot.build_stubbed(:hbx_enrollment_member) }
    let(:hbx_enrollment_member_two) { FactoryBot.build_stubbed(:hbx_enrollment_member, is_subscriber: false) }

    it "it should return subscribers full name in span with dependent-text class" do
      allow(hbx_enrollment_member_two).to receive(:is_subscriber).and_return(true)
      allow(hbx_enrollment_member).to receive_message_chain("person.full_name").and_return("Bobby Boucher")
      expect(helper.plan_shopping_dependent_text(hbx_enrollment)).to eq "<span class='dependent-text'>Bobby Boucher</span>"
    end

    it "it should return subscribers and dependents modal" do
      allow(hbx_enrollment_member).to receive_message_chain("person.full_name").and_return("Bobby Boucher")
      allow(hbx_enrollment_member).to receive_message_chain("person.find_relationship_with").and_return("Spouse")
      allow(hbx_enrollment_member_two).to receive_message_chain("person.full_name").and_return("Danny Boucher")
      expect(helper.plan_shopping_dependent_text(hbx_enrollment)).to match '<h4 class="modal-title">Coverage For</h4>'
    end

  end

  describe "#generate_options_for_effective_on_kinds" do
    it "it should return blank array" do
      options = helper.generate_options_for_effective_on_kinds([], TimeKeeper.date_of_record)
      expect(options).to eq []
    end

    it "it should return options" do
      date = TimeKeeper.date_of_record
      options = helper.generate_options_for_effective_on_kinds(['date_of_event', 'fixed_first_of_next_month'], TimeKeeper.date_of_record)
      expect(options).to eq [[date.to_s, 'date_of_event'], [(date.end_of_month+1.day).to_s, 'fixed_first_of_next_month']]
    end
  end

  describe "#render_plan_type_details", dbclean: :after_each do
    let(:dental_plan_2015){FactoryBot.create(:plan_template,:shop_dental, active_year: 2015, metal_level: "dental")}
    let(:dental_plan_2016){FactoryBot.create(:plan_template,:shop_dental, active_year: 2016, metal_level: "dental", dental_level: "high")}
    let(:health_plan_2016){FactoryBot.create(:plan_template,:shop_health, active_year: 2016, metal_level: "silver")}

    it "should return dental plan with dental_level = high for 2016 plan" do
      expect(helper.render_plan_type_details(dental_plan_2016)).to eq "<span class=\"dental-icon\">High</span>"
    end

    it "should return dental plan with metal_level = dental for 2015 plan" do
      expect(helper.render_plan_type_details(dental_plan_2015)).to eq "<span class=\"dental-icon\">Dental</span>"
    end

    it "should return health plan with metal_level = bronze" do
      expect(helper.render_plan_type_details(health_plan_2016)).to eq "<span class=\"silver-icon\">Silver</span>"
    end
  end

  describe "#show_employer_panel", dbclean: :after_each do
    let(:person) {FactoryBot.build(:person)}
    let(:employee_role) {FactoryBot.build(:employee_role)}
    let(:census_employee) {FactoryBot.build(:census_employee)}
    let(:person_with_employee_role) {FactoryBot.create(:person, :with_employee_role)}

    it "should return false without employee_role" do
      expect(helper.newhire_enrollment_eligible?(nil)).to eq false
    end

    it "should return false with employee_role who has no census_employee" do
      allow(employee_role).to receive(:census_employee).and_return nil
      expect(helper.newhire_enrollment_eligible?(employee_role)).to eq false
    end

    context "with employee_role who has census_employee" do
      before :each do
        allow(employee_role).to receive(:census_employee).and_return census_employee
      end

      it "should return false when census_employee is not newhire_enrollment_eligible" do
        allow(census_employee).to receive(:newhire_enrollment_eligible?).and_return false
        expect(helper.newhire_enrollment_eligible?(employee_role)).to eq false
      end

      context "when census_employee is newhire_enrollment_eligible" do
        before do
          allow(census_employee).to receive(:newhire_enrollment_eligible?).and_return true
        end

        it "should return false when person can not select coverage" do
          allow(employee_role).to receive(:can_select_coverage?).and_return false
          expect(helper.newhire_enrollment_eligible?(employee_role)).to eq false
        end

        it "should return true when person can select coverage" do
          allow(employee_role).to receive(:can_select_coverage?).and_return true
          expect(helper.newhire_enrollment_eligible?(employee_role)).to eq true
        end
      end
    end
  end

  describe "has_writing_agent?" do
    let(:employee_role) { FactoryBot.build(:employee_role) }
    let(:person) { FactoryBot.build(:person) }

    it "should return false when employee_role is passwed with out writing_agent" do
      expect(helper.has_writing_agent?(employee_role)).to eq false
    end

    it "should return false when person is passwed with out writing_agent" do
      expect(helper.has_writing_agent?(person)).to eq false
    end

    it "should return true when employee_role is passed with out writing_agent" do
      allow(person).to receive_message_chain(:primary_family,:current_broker_agency,:writing_agent).and_return(true)
      expect(helper.has_writing_agent?(person)).to eq true
    end

  end

  describe "display_aasm_state?" do
    let(:person) { FactoryBot.build_stubbed(:person)}
    let(:family) { FactoryBot.build_stubbed(:family, :with_primary_family_member, person: person) }
    let(:household) { FactoryBot.build_stubbed(:household, family: family) }
    let(:hbx_enrollment) { FactoryBot.build_stubbed(:hbx_enrollment, household: household, hbx_enrollment_members: [hbx_enrollment_member]) }
    let(:hbx_enrollment_member) { FactoryBot.build_stubbed(:hbx_enrollment_member) }
    states = ["coverage_selected", "coverage_canceled", "coverage_terminated", "shopping", "inactive", "unverified", "coverage_enrolled", "auto_renewing", "any_state"]
    show_for_ivl = ["coverage_selected", "coverage_canceled", "coverage_terminated", "auto_renewing", "renewing_coverage_selected"]

    context "IVL market" do
      before :each do
        allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      end
      states.each do |status|
        it "returns #{show_for_ivl.include?(status)} for #{status}" do
          hbx_enrollment.aasm_state = status
          expect(helper.display_aasm_state?(hbx_enrollment)).to eq show_for_ivl.include?(status)
        end
      end
    end

    context "SHOP market" do
      before :each do
        allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      end
      states.each do |status|
        it "returns true for #{status}" do
          hbx_enrollment.aasm_state = status
          expect(helper.display_aasm_state?(hbx_enrollment)).to eq true
        end
      end
    end
  end

  describe "ShopForPlan using SEP", dbclean: :after_each do
    let(:qle_on) {Date.new(TimeKeeper.date_of_record.year, 04, 14)}
    let(:person) {FactoryBot.create(:person, :with_employee_role, :with_family)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:qle_first_of_month) { FactoryBot.create(:qualifying_life_event_kind, :effective_on_first_of_month ) }
    let(:qle_with_date_options_available) { FactoryBot.create(:qualifying_life_event_kind, :effective_on_first_of_month, date_options_available: true ) }
    let(:sep_without_date_options) {
      sep = family.special_enrollment_periods.new
      sep.effective_on_kind = 'first_of_month'
      sep.qualifying_life_event_kind= qle_first_of_month
      sep.qualifying_life_event_kind_id = qle_first_of_month.id
      sep.qle_on= Date.new(TimeKeeper.date_of_record.year, 04, 14)
      sep.admin_flag = true
      sep
    }

    let(:sep_with_date_options) {
      sep = family.special_enrollment_periods.new
      sep.effective_on_kind = 'first_of_month'
      sep.qualifying_life_event_kind= qle_first_of_month
      sep.qualifying_life_event_kind_id = qle_with_date_options_available.id
      sep.qle_on = qle_on
      sep.optional_effective_on = [qle_on+5.days, qle_on+6.days, qle_on+7.days]
      sep.admin_flag = true
      sep
    }
    context "when building ShopForPlan link" do
      it "should have class 'existing-sep-item' for a SEP with date options QLE and optional_effective_on populated " do
        expect(helper.build_link_for_sep_type(sep_with_date_options)).to include "class=\"existing-sep-item\""
      end

      it "should be a link to 'insured/family_members' for a QLE type without date options available" do
        expect(helper.build_link_for_sep_type(sep_without_date_options)).to include "href=\"/insured/family_members"
      end
    end

    context "#build_link_for_sep_type" do
      it "returns nil if sep nil" do
        expect(helper.build_link_for_sep_type(nil)).to be_nil
      end

      it "can find qle" do
        expect(QualifyingLifeEventKind).to receive(:find)
        helper.build_link_for_sep_type(sep_with_date_options)
      end
    end

    context "find QLE for SEP" do
      it "needs to return the right QLE for a given SEP" do
        expect(find_qle_for_sep(sep_with_date_options)).to eq qle_with_date_options_available
        expect(find_qle_for_sep(sep_without_date_options)).to eq qle_first_of_month
      end
    end
  end

  describe "#tax_info_url" do
    context "production environment" do
      it "should redirect from production environment" do
        ClimateControl.modify(AWS_ENV: 'prod') do
          expect(helper.tax_info_url).to eq "https://dchealthlink.com/individuals/tax-documents"
        end
      end
    end

    context "non-production environment" do
      it "should redirect from test environment" do
        ClimateControl.modify(AWS_ENV: 'preprod') do
          expect(helper.tax_info_url).to eq "https://staging.dchealthlink.com/individuals/tax-documents"
        end
      end
    end
  end

  context "build consumer role" do
    let(:person) { FactoryBot.create(:person)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}

    it "should build consumer role for a person" do
      helper.build_consumer_role(person,family)
      expect(person.consumer_role.present?). to eq true
    end
  end

  context "build resident role " do
    let(:person) { FactoryBot.create(:person)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}

    it "should build consumer role for a person" do
      helper.build_resident_role(person,family)
      expect(person.resident_role.present?). to eq true
    end
  end

  describe "show_download_tax_documents_button?" do
    let(:person) { FactoryBot.create(:person)}

    before do
      helper.instance_variable_set(:@person, person)
    end

    context "as consumer" do
      let(:consumer_role) {FactoryBot.build(:consumer_role)}
      context "had a SSN" do
        before do
          person.consumer_role = consumer_role
            person.ssn = '123456789'
        end
        it "should display the download tax documents button" do
         expect(helper.show_download_tax_documents_button?).to eq true
        end

        context "current user is hbx staff" do
          let(:current_user) { FactoryBot.build(:hbx_staff)}
          it "should display the download tax documents button" do
            expect(helper.show_download_tax_documents_button?).to eq true
          end
        end
      end

      context "had no SSN" do
        before do
          person.ssn = ''
        end

        it "should not display the download tax documents button" do
          expect(helper.show_download_tax_documents_button?).to eq false
        end
      end

    end

    context "as employee and has no consumer role", dbclean: :after_each do
      let(:person) { FactoryBot.create(:person)}
      let(:employee_role) {FactoryBot.build(:employee_role)}

      before do
        person.employee_roles = [employee_role]
      end

      context "had a SSN" do
        before do
          person.ssn = '123456789'
        end

        it "should not display the download tax documents button" do
          expect(helper.show_download_tax_documents_button?).to eq false
        end
      end
    end

    describe "#disable_make_changes_button?" do
      let(:hbx_enrollment) do
        instance_double(
          HbxEnrollment,
          census_employee: census_employee,
          is_shop?: is_shop,
          sponsored_benefit_package: sponsored_benefit_package,
          employee_role: employee_role,
          family: family
        )
      end

      let(:census_employee) do
        instance_double(CensusEmployee)
      end

      let(:is_shop) { true }

      let(:todays_date) { double }

      let(:sponsored_benefit_package) do
        instance_double(
          BenefitSponsors::BenefitPackages::BenefitPackage
        )
      end

      let(:employee_role) do
        instance_double(
          EmployeeRole,
          can_enroll_as_new_hire?: can_enroll_as_new_hire
        )
      end

      let(:family) do
        instance_double(
          Family,
          current_sep: current_sep,
          is_under_special_enrollment_period?: under_special_enrollment_period
        )
      end

      let(:current_sep) { double(effective_on: active_during_date) }

      let(:active_during_date) { double }

      let(:under_special_enrollment_period) { false }
      let(:open_enrollment_contains) { false }
      let(:can_enroll_as_new_hire) { false }
      let(:active_during) { false }

      before :each do
        allow(TimeKeeper).to receive(:date_of_record).and_return(todays_date)
        allow(sponsored_benefit_package).to receive(:open_enrollment_contains?).
          with(todays_date).and_return(open_enrollment_contains)
        allow(hbx_enrollment).to receive(:active_during?).
          with(active_during_date).and_return(active_during)
      end

      context "given a non-census employee enrollment" do
        let(:census_employee) { nil }

        it "does not disable the Make Changes button" do
          expect(helper.disable_make_changes_button?(hbx_enrollment)).to be_falsey
        end
      end
      context "given an enrollment which has a census employee, but is not shop" do
        let(:is_shop) { false }

        it "does not disable the Make Changes button" do
          expect(helper.disable_make_changes_button?(hbx_enrollment)).to be_falsey
        end
      end

      context "given:
      - a census employee enrollment
      - which is shop
      - when inside open enrollment for the same benefit package as this enrollment
      " do

        let(:open_enrollment_contains) { true }

        it "does not disable the Make Changes button" do
          expect(helper.disable_make_changes_button?(hbx_enrollment)).to be_falsey
        end
      end

      context "given:
      - a census employee enrollment
      - which is shop
      - but is not inside the open enrollment period
      - but the corresponding employee role can enroll as a new hire
      " do
        let(:can_enroll_as_new_hire) { true }

        it "does not disable the Make Changes button" do
          expect(helper.disable_make_changes_button?(hbx_enrollment)).to be_falsey
        end
      end

      context "given:
      - a census employee enrollment
      - which is shop
      - but is not inside the open enrollment period
      - and the corresponding employee role can not enroll as a new hire
      - but the family is under a special enrollment period which overlaps with when this enrollment is active
      " do
        let(:under_special_enrollment_period) { true }
        let(:active_during) { true }

        it "does not disable the Make Changes button" do
          expect(helper.disable_make_changes_button?(hbx_enrollment)).to be_falsey
        end
      end
      context "given:
      - a census employee enrollment
      - which is shop
      - but is not inside the open enrollment period
      - and the corresponding employee role can not enroll as a new hire
      - and the family is not under a special enrollment period
      " do

        it "disables the Make Changes button" do
          expect(helper.disable_make_changes_button?(hbx_enrollment)).to be_truthy
        end
      end
      context "given:
      - a census employee enrollment
      - which is shop
      - but is not inside the open enrollment period
      - and the corresponding employee role can not enroll as a new hire
      - and the family is under a special enrollment period, but the SEP doesn't overlap with this enrollment's active period
      " do
        let(:under_special_enrollment_period) { true }

        it "disables the Make Changes button" do
          expect(helper.disable_make_changes_button?(hbx_enrollment)).to be_truthy
        end
      end
    end

  end

  describe "#Enrollment coverage", dbclean: :after_each do
    let!(:person) { FactoryBot.build_stubbed(:person)}
    let!(:family) { FactoryBot.build_stubbed(:family, :with_primary_family_member, person: person) }
    let!(:household) { FactoryBot.build_stubbed(:household, family: family) }

    context "IVL enrollment", dbclean: :after_each do

      let!(:hbx_enrollment) { FactoryBot.build_stubbed(:hbx_enrollment, household: household, aasm_state: "coverage_expired", effective_on: TimeKeeper.date_of_record) }
      let!(:hbx_profile) { FactoryBot.create(:hbx_profile)}
      let!(:benefit_coverage_periods) { HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.by_date(hbx_enrollment.effective_on).first}

      it "should return benefit coverage period" do
        expect(benefit_coverage_periods.present?).to eq true
      end

      it "should return benefit coverage period end date" do
        expect(enrollment_coverage_end(hbx_enrollment)).to eq hbx_enrollment.effective_on.end_of_year
      end
    end

    context "shop enrollment", dbclean: :after_each do
      let(:site)                  { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:benefit_sponsor)        { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile_initial_application, site: site) }
      let(:benefit_sponsorship)    { benefit_sponsor.active_benefit_sponsorship }
      let(:employer_profile)      {  benefit_sponsorship.profile }
      let!(:benefit_package) { benefit_sponsorship.benefit_applications.first.benefit_packages.first}
      let(:census_employee)   { FactoryBot.create(:census_employee, employer_profile: employer_profile) }
      let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package, census_employee: census_employee)}
      let(:start_on)          { benefit_package.start_on }
      let(:terminated_on)          { benefit_package.start_on + 1.month }
      let!(:shop_hbx_enrollment) do
        FactoryBot.build_stubbed(:hbx_enrollment, kind: "employer_sponsored", household: household, benefit_group_assignment: benefit_group_assignment, aasm_state: "coverage_expired", effective_on: TimeKeeper.date_of_record)
      end
      let!(:termed_shop_hbx_enrollment) do
        FactoryBot.build_stubbed(:hbx_enrollment, terminated_on: terminated_on, kind: "employer_sponsored", household: household, benefit_group_assignment: benefit_group_assignment,
                                                  aasm_state: "coverage_terminated", effective_on: TimeKeeper.date_of_record)
      end


      it "should return benefit applictaion end date for expired enrollment" do
        expect(enrollment_coverage_end(shop_hbx_enrollment)).to eq benefit_package.end_on
      end

      it "should return terminated date for term enrollment" do
        expect(enrollment_coverage_end(termed_shop_hbx_enrollment)).to eq terminated_on
      end
    end
  end

  describe '#render_product_type_details', dbclean: :after_each do
    it 'should return gold icon with nationwide' do
      expect(helper.render_product_type_details(:gold, true)).to eq "<span class=\"gold-icon\">Gold</span>&nbsp<label class='separator'></label>NATIONWIDE NETWORK"
    end

    it 'should return gold icon without nationwide' do
      expect(helper.render_product_type_details(:gold, false)).to eq "<span class=\"gold-icon\">Gold</span>"
    end
  end
end
