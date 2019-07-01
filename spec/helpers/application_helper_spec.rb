require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ApplicationHelper, :type => :helper do

  describe "#can_employee_shop??" do
    it "should return false if date is empty" do
      expect(helper.can_employee_shop?(nil)).to eq false
    end

    it "should return true if date is present and rates are present" do
      allow(Plan).to receive(:has_rates_for_all_carriers?).and_return(false)
      expect(helper.can_employee_shop?("10/01/2018")).to eq true
    end
  end

  describe "#rates_available?" do
    let(:employer_profile){ double("EmployerProfile") }

    it "should return blocking when true" do
      allow(employer_profile).to receive(:applicant?).and_return(true)
      allow(Plan).to receive(:has_rates_for_all_carriers?).and_return(false)
      expect(helper.rates_available?(employer_profile)).to eq "blocking"
    end

    it "should return empty string when false" do
      allow(employer_profile).to receive(:applicant?).and_return(false)
      expect(helper.rates_available?(employer_profile)).to eq ""
    end
  end

  describe "#product_rates_available?", :dbclean => :after_each  do
    let!(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
    let(:benefit_sponsorship){ double("benefit_sponsorship") }

    context "when active_benefit_application is present" do
      it "should return false" do
        allow(benefit_sponsorship).to receive(:active_benefit_application).and_return(true)
        expect(helper.product_rates_available?(benefit_sponsorship)).to eq false
      end
    end

    context "when active_benefit_application is not present" do
      before(:each) do
        allow(benefit_sponsorship).to receive(:active_benefit_application).and_return(false)
        allow(benefit_sponsorship).to receive(:applicant?).and_return(true)
      end
      it "should return false if not in late rates" do
        expect(helper.product_rates_available?(benefit_sponsorship)).to eq false
      end

      it "should return true if during late rates" do
        expect(helper.product_rates_available?(benefit_sponsorship, TimeKeeper.date_of_record + 1.year)).to eq true
      end
    end
  end

  describe "#deductible_display" do
    let(:hbx_enrollment) {double(hbx_enrollment_members: [double, double])}
    let(:plan) { double("Plan", deductible: "$500", family_deductible: "$500 per person | $1000 per group",) }

    before :each do
      assign(:hbx_enrollment, hbx_enrollment)
    end

    it "should return family deductible if hbx_enrollment_members count > 1" do
      expect(helper.deductible_display(hbx_enrollment, plan)).to eq plan.family_deductible.split("|").last.squish
    end

    it "should return individual deductible if hbx_enrollment_members count <= 1" do
      allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return([double])
      expect(helper.deductible_display(hbx_enrollment, plan)).to eq plan.deductible
    end
  end

  describe "#dob_in_words" do
    it "returns date of birth in words for < 1 year" do
      expect(helper.dob_in_words(0, "20/06/2015".to_date)).to eq time_ago_in_words("20/06/2015".to_date)
      expect(helper.dob_in_words(0, "20/07/2015".to_date)).to eq time_ago_in_words("20/07/2015".to_date)
      expect(helper.dob_in_words(0, "20/07/2014".to_date)).to eq time_ago_in_words("20/07/2014".to_date)
    end
  end

  describe "#display_carrier_logo" do
    let(:carrier_profile){ FactoryBot.build(:carrier_profile, legal_name: "Kaiser")}
    let(:plan){ Maybe.new(FactoryBot.build(:plan, hios_id: "94506DC0350001-01", carrier_profile: carrier_profile)) }

    it "should return the named logo" do
      expect(helper.display_carrier_logo(plan)).to match %r{<img width=\"50\" src=\"/assets/logo/carrier/kaiser-.*\.jpg\" />}
    end

  end

  describe "#format_time_display" do
    let(:timestamp){ Time.now.utc }
    it "should display the time in proper format" do
      expect(helper.format_time_display(timestamp)).to eq timestamp.in_time_zone('Eastern Time (US & Canada)')
    end

    it "should return empty if no timestamp is present" do
      expect(helper.format_time_display(nil)).to eq ""
    end
  end

  describe "#group_xml_transmitted_message" do
    let(:employer_profile_1){ double("EmployerProfile", xml_transmitted_timestamp: Time.now.utc, legal_name: "example1 llc.") }
    let(:employer_profile_2){ double("EmployerProfile", xml_transmitted_timestamp: nil, legal_name: "example2 llc.") }

    it "should display re-submit message if xml is being transmitted again" do
      expect(helper.group_xml_transmitted_message(employer_profile_1)).to eq  "The group xml for employer #{employer_profile_1.legal_name} was transmitted on #{format_time_display(employer_profile_1.xml_transmitted_timestamp)}. Are you sure you want to transmit again?"
    end

    it "should display first time message if xml is being transmitted first time" do
      expect(helper.group_xml_transmitted_message(employer_profile_2)).to eq  "Are you sure you want to transmit the group xml for employer #{employer_profile_2.legal_name}?"
    end
  end

  describe "#display_dental_metal_level" do
    let(:dental_plan_2015){FactoryBot.create(:plan_template,:shop_dental, active_year: 2015)}
    let(:dental_plan_2016){FactoryBot.create(:plan_template,:shop_dental, active_year: 2016)}

    it "should display metal level if its a 2015 plan" do
      expect(display_dental_metal_level(dental_plan_2015)).to eq dental_plan_2015.metal_level.titleize
    end

    it "should display metal level if its a 2016 plan" do
      expect(display_dental_metal_level(dental_plan_2016)).to eq dental_plan_2016.dental_level.titleize
    end
  end

  describe '#network_type , #plans_count', :dbclean => :after_each do
    let!(:nationwide_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, nationwide: true, dc_in_network: false) }
    let!(:dcmetro_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, nationwide: false, dc_in_network: true) }
    let!(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, nationwide: false, dc_in_network: false) }
    let(:all_products) {[nationwide_product, dcmetro_product, product]}
    let(:no_products) {[]}

    it 'should display Nationwide if product is nationwide' do
      expect(network_type(nationwide_product)).to eq 'Nationwide'
    end

    it 'should display DC-Metro if product is DC-Metro' do
      expect(network_type(dcmetro_product)).to eq 'DC-Metro'
    end

    it 'should display empty if metal level if its a 2016 plan' do
      expect(network_type(product)).to eq nil
    end

    it 'should display Nationwide if product is nationwide' do
      expect(products_count(all_products)).to eq 3
    end

    it 'should display DC-Metro if product is DC-Metro' do
      expect(products_count(no_products)).to eq 0
    end
  end

  describe "#enrollment_progress_bar", :dbclean => :after_each  do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application" do
      let(:aasm_state) { :enrollment_open }
    end

    let!(:employer_profile)    { abc_profile }
    let!(:plan_year) { initial_application }

    it "display progress bar" do
      expect(helper.enrollment_progress_bar(plan_year, 1, minimum: false)).to include('<div class="progress-wrapper employer-dummy">')
    end

    context ">200 census employees" do
      let!(:census_employees) { create_list(:census_employee, 201, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package) }
      context "greater than 200 employees " do
        context "active employees count greater than 200" do
          it "does not display if active census employees > 200" do
            expect(helper.enrollment_progress_bar(plan_year, 1, minimum: false)).to eq nil
          end
        end

        context "active employees count greater than 200" do

          before do
            census_employees.take(5).each do |census_employee|
              census_employee.terminate_employee_role!
            end
          end

          it "should display progress bar if active census employees < 200" do
            expect(helper.enrollment_progress_bar(plan_year, 1, minimum: false)).to include('<div class="progress-wrapper employer-dummy">')
          end
        end
      end
    end

  end

  describe "#fein helper methods" do
    it "returns fein with masked fein" do
      expect(helper.number_to_obscured_fein("111098222")).to eq "**-***8222"
    end

    it "returns formatted fein" do
      expect(helper.number_to_fein("111098222")).to eq "11-1098222"
    end
  end

  describe "date_col_name_for_broker_roaster" do
    context "for applicants controller" do
      before do
        expect(helper).to receive(:controller_name).and_return("applicants")
      end
      it "should return accepted date" do
        assign(:status, "active")
        expect(helper.date_col_name_for_broker_roaster).to eq 'Accepted Date'
      end
      it "should return terminated date" do
        assign(:status, "broker_agency_terminated")
        expect(helper.date_col_name_for_broker_roaster).to eq 'Terminated Date'
      end
      it "should return declined_date" do
        assign(:status, "broker_agency_declined")
        expect(helper.date_col_name_for_broker_roaster).to eq 'Declined Date'
      end
    end
    context "for other than applicants controller" do
      before do
        expect(helper).to receive(:controller_name).and_return("test")
      end
      it "should return certified" do
        assign(:status, "certified")
        expect(helper.date_col_name_for_broker_roaster).to eq 'Certified Date'
      end
      it "should return decertified" do
        assign(:status, "decertified")
        expect(helper.date_col_name_for_broker_roaster).to eq 'Decertified Date'
      end
      it "should return denied" do
        assign(:status, "denied")
        expect(helper.date_col_name_for_broker_roaster).to eq 'Denied Date'
      end
    end
  end

  describe "relationship_options" do
    let(:dependent) { double("FamilyMember") }

    context "consumer_portal" do
      it "should return correct options for consumer portal" do
        expect(helper.relationship_options(dependent, "consumer_role_id")).to match(/Domestic Partner/mi)
        expect(helper.relationship_options(dependent, "consumer_role_id")).to match(/Spouse/mi)
        expect(helper.relationship_options(dependent, "consumer_role_id")).not_to match(/other tax dependent/mi)
      end
    end

    context "employee portal" do
      it "should not match options that are in consumer portal" do
        expect(helper.relationship_options(dependent, "")).to match(/Domestic Partner/mi)
        expect(helper.relationship_options(dependent, "")).not_to match(/other tax dependent/mi)
      end
    end

  end

  describe "#may_update_census_employee?" do
    let(:user) { double("User") }
    let(:census_employee) { double("CensusEmployee", new_record?: false, is_eligible?: false) }

    before do
      expect(helper).to receive(:current_user).and_return(user)
    end

    it "census_employee can edit if it is new record" do
      expect(user).to receive(:roles).and_return(["employee"])
      expect(helper.may_update_census_employee?(CensusEmployee.new)).to eq true # readonly -> false
    end

    it "census_employee cannot edit if linked to an employer" do
      expect(user).to receive(:roles).and_return(["employee"])
      expect(helper.may_update_census_employee?(census_employee)).to eq false # readonly -> true
    end

    it "hbx admin edit " do
      expect(user).to receive(:roles).and_return(["hbx_staff"])
      expect(helper.may_update_census_employee?(CensusEmployee.new)).to eq true # readonly -> false
    end
  end

  describe "#parse_ethnicity" do
    it "should return string of values" do
      expect(helper.parse_ethnicity(["test", "test1"])).to eq "test, test1"
    end
    it "should return empty value if ethnicity is not selected" do
      expect(helper.parse_ethnicity([""])).to eq ""
    end
  end

  describe "#calculate_participation_minimum" do
    let(:plan_year_1) { double("PlanYear", eligible_to_enroll_count: 5) }
    before do
      @current_plan_year = plan_year_1
    end
    it "should  return 0 when eligible_to_enroll_count is zero" do
      expect(@current_plan_year).to receive(:eligible_to_enroll_count).and_return(0)
      expect(helper.calculate_participation_minimum).to eq 0
    end

    it "should calculate eligible_to_enroll_count when not zero" do
      expect(helper.calculate_participation_minimum.ceil).to eq 4
    end
  end

  describe "get_key_and_bucket" do
    it "should return array with key and bucket" do
      uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{Settings.site.s3_prefix}-sbc#f21369fc-ae6c-4fa5-a299-370a555dc401"
      key, bucket = get_key_and_bucket(uri)
      expect(key).to eq("f21369fc-ae6c-4fa5-a299-370a555dc401")
      expect(bucket).to eq("#{Settings.site.s3_prefix}-sbc")
    end
  end
  describe "current_cost" do
    it "should return cost without session" do
      expect(helper.current_cost(100, 0.9)).to eq 100
    end

    context "with session" do
      before :each do
        session['elected_aptc'] = 100
        session['max_aptc'] = 200
      end

      it "when ehb_premium > aptc_amount" do
        expect(helper.current_cost(200, 0.9)).to eq (200 - 0.5*200)
      end

      it "when ehb_premium < aptc_amount" do
        expect(helper.current_cost(100, 0.9)).to eq (100 - 0.9*100)
      end

      it "should return 0" do
        session['elected_aptc'] = 160
        expect(helper.current_cost(100, 1.2)).to eq 0
      end

      it "when can_use_aptc is false" do
        expect(helper.current_cost(100, 1.2, nil, 'shopping', false)).to eq 100
      end

      it "when can_use_aptc is true" do
        expect(helper.current_cost(100, 1.2, nil, 'shopping', true)).to eq 0
      end
    end

    context "with hbx_enrollment" do
      let(:hbx_enrollment) {double(applied_aptc_amount: 10, total_premium: 100, coverage_kind: 'health')}
      it "should return cost from hbx_enrollment" do
        expect(helper.current_cost(100, 0.8, hbx_enrollment, 'account')).to eq 90
      end
    end
  end

  describe "env_bucket_name" do
    let(:aws_env) { ENV['AWS_ENV'] || "qa" }
    it "should return bucket name with system name prepended and environment name appended" do
      bucket_name = "sample-bucket"
      expect(env_bucket_name(bucket_name)).to eq("#{Settings.site.s3_prefix}-enroll-#{bucket_name}-#{aws_env}")
    end
  end

  describe "disable_purchase?" do
    it "should return true when disabled is true" do
      expect(helper.disable_purchase?(true, nil)).to eq true
    end

    context "when disable is false" do
      let(:hbx_enrollment) { HbxEnrollment.new }

      it "should return true when hbx_enrollment is not allow select_coverage" do
        allow(hbx_enrollment).to receive(:can_select_coverage?).and_return false
        expect(helper.disable_purchase?(false, hbx_enrollment)).to eq true
      end

      it "should return false when hbx_enrollment is allow select_coverage" do
        allow(hbx_enrollment).to receive(:can_select_coverage?).and_return true
        expect(helper.disable_purchase?(false, hbx_enrollment)).to eq false
      end
    end
  end

  describe "qualify_qle_notice" do
    it "should return notice" do
      expect(helper.qualify_qle_notice).to include("In order to purchase benefit coverage, you must be in either an Open Enrollment or Special Enrollment period. ")
    end
  end

  describe "show_default_ga?", dbclean: :after_each do
    let(:general_agency_profile) { FactoryBot.create(:general_agency_profile, :shop_agency) }
    let(:broker_agency_profile) { FactoryBot.create(:broker_agency_profile, :shop_agency) }

    it "should return false without broker_agency_profile" do
      expect(helper.show_default_ga?(general_agency_profile, nil)).to eq false
    end

    it "should return false without general_agency_profile" do
      expect(helper.show_default_ga?(nil, broker_agency_profile)).to eq false
    end

    it "should return true" do
      broker_agency_profile.default_general_agency_profile = general_agency_profile
      expect(helper.show_default_ga?(general_agency_profile, broker_agency_profile)).to eq true
    end

    it "should return false when the default_general_agency_profile of broker_agency_profile is not general_agency_profile" do
      expect(helper.show_default_ga?(general_agency_profile, broker_agency_profile)).to eq false
    end
  end
   describe "#show_oop_pdf_link" , dbclean: :after_each do
       context 'valid aasm_state' do
         it "should return true" do
           BenefitSponsors::BenefitApplications::BenefitApplication::SUBMITTED_STATES.each do |state|
             expect(helper.show_oop_pdf_link(state)).to be true
           end
         end
       end

        context 'invalid aasm_state' do
          it "should return false" do
            ["draft", "renewing_draft"].each do |state|
              expect(helper.show_oop_pdf_link(state)).to be false
            end
          end
        end
     end


  describe "find_plan_name", dbclean: :after_each do
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:shop_enrollment) { FactoryBot.create(:hbx_enrollment,
                                        household: family.active_household,
                                        family:family,
                                        kind: "employer_sponsored",
                                        submitted_at: TimeKeeper.datetime_of_record - 3.days,
                                        created_at: TimeKeeper.datetime_of_record - 3.days
                                )}
    let(:ivl_enrollment)    { FactoryBot.create(:hbx_enrollment,
                                        household: family.latest_household,
                                        family:family,
                                        coverage_kind: "health",
                                        effective_on: TimeKeeper.datetime_of_record - 10.days,
                                        enrollment_kind: "open_enrollment",
                                        kind: "individual",
                                        submitted_at: TimeKeeper.datetime_of_record - 20.days
                            )}
    let(:valid_shop_enrollment_id)  { shop_enrollment.id }
    let(:valid_ivl_enrollment_id)   { ivl_enrollment.id }
    let(:invalid_enrollment_id)     {  }

    it "should return the plan name given a valid SHOP enrollment ID" do
      expect(helper.find_plan_name(valid_shop_enrollment_id)).to eq shop_enrollment.plan.name
    end

    it "should return the plan name given a valid INDIVIDUAL enrollment ID" do
      expect(helper.find_plan_name(valid_ivl_enrollment_id)).to eq  ivl_enrollment.plan.name
    end

    it "should return nil given an invalid enrollment ID" do
      expect(helper.find_plan_name(invalid_enrollment_id)).to eq  nil
    end
  end
end

  describe "Enabled/Disabled IVL market" do
    shared_examples_for "IVL market status" do |value|
       if value == true
        it "should return true if IVL market is enabled" do
          expect(helper.individual_market_is_enabled?).to eq  true
        end
       else
        it "should return false if IVL market is disabled" do
          expect(helper.individual_market_is_enabled?).to eq  false
        end
       end
    it_behaves_like "IVL market status", Settings.aca.market_kinds.include?("individual")
  end

  describe "#is_new_paper_application?" do
    let(:person_id) { double }
    let(:admin_user) { FactoryBot.create(:user, :hbx_staff)}
    let(:user) { FactoryBot.create(:user)}
    let(:person) { FactoryBot.create(:person, user: user)}
    before do
      allow(admin_user).to receive(:person_id).and_return person_id
    end

    it "should return true when current user is admin & doing new paper application" do
      expect(helper.is_new_paper_application?(admin_user, "paper")).to eq true
    end

    it "should return false when the current user is not an admin & working on new paper application" do
      expect(helper.is_new_paper_application?(user, "paper")).to eq nil
    end

    it "should return false when the current user is an admin & not working on new paper application" do
      expect(helper.is_new_paper_application?(admin_user, "")).to eq false
    end
  end

  describe "#previous_year" do
    it "should return past year" do
      expect(helper.previous_year).to eq (TimeKeeper.date_of_record.year - 1)
    end

    it "should not return current year" do
      expect(helper.previous_year).not_to eq (TimeKeeper.date_of_record.year)
    end

    it "should not return next year" do
      expect(helper.previous_year).not_to eq (TimeKeeper.date_of_record.year + 1)
    end
  end

  describe "convert_to_bool" do
    let(:val1) {true }
    let(:val2) {false }
    let(:val3) {"true" }
    let(:val4) {"false" }
    let(:val5) {0 }
    let(:val6) {1 }
    let(:val7) {"0" }
    let(:val8) {"1" }
    let(:val9) {"khsdbfkjs" }


    it "should be true when true is passed" do
      expect(helper.convert_to_bool(val1)).to eq true
    end

    it "should be false when false is passed" do
      expect(helper.convert_to_bool(val2)).to eq false
    end

    it "should be true when string 'true' is passed" do
      expect(helper.convert_to_bool(val3)).to eq true
    end

    it "should be false when string 'false' is passed" do
      expect(helper.convert_to_bool(val4)).to eq false
    end

    it "should be false when int 0 is passed" do
      expect(helper.convert_to_bool(val5)).to eq false
    end

    it "should be true when int 1 is passed" do
      expect(helper.convert_to_bool(val6)).to eq true
    end

    it "should be false when string '0' is passed" do
      expect(helper.convert_to_bool(val7)).to eq false
    end

    it "should be true when string '1' is passed" do
      expect(helper.convert_to_bool(val8)).to eq true
    end

    it "should raise error when non boolean values are passed" do
      expect{helper.convert_to_bool(val9)}.to raise_error(ArgumentError)
    end
  end
end
