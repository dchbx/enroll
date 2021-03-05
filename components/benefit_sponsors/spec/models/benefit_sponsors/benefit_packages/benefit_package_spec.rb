require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe BenefitPackages::BenefitPackage, type: :model, :dbclean => :after_each do

    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:title)                 { "Generous BenefitPackage - 2018"}
    let(:probation_period_kind) { :first_of_month_after_30_days }

    let(:params) do
      {
        title: title,
        probation_period_kind: probation_period_kind,
      }
    end

    context "A new model instance" do
      it { is_expected.to be_mongoid_document }
      it { is_expected.to have_field(:title).of_type(String).with_default_value_of("")}
      it { is_expected.to have_field(:description).of_type(String).with_default_value_of("")}
      it { is_expected.to have_field(:probation_period_kind).of_type(Symbol)}
      it { is_expected.to have_field(:is_default).of_type(Mongoid::Boolean).with_default_value_of(false)}
      it { is_expected.to have_field(:is_active).of_type(Mongoid::Boolean).with_default_value_of(true)}
      it { is_expected.to have_field(:predecessor_id).of_type(BSON::ObjectId)}
      it { is_expected.to embed_many(:sponsored_benefits)}
      it { is_expected.to be_embedded_in(:benefit_application)}


      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no title" do
        subject { described_class.new(params.except(:title)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no probation_period_kind" do
        subject { described_class.new(params.except(:probation_period_kind)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with all required arguments" do
        subject { described_class.new(params) }


        context "and all arguments are valid" do
          it "should be valid" do
            subject.validate
            expect(subject).to be_valid
          end
        end
      end
    end

    describe '.census_employees_assigned_on' do
      let(:renewed_enrollment) { double("hbx_enrollment")}
      let(:ra) {initial_application.renew}
      let(:ia) {predecessor_application}
      let(:bs) { ra.predecessor.benefit_sponsorship}
      let(:cbp){ra.predecessor.benefit_packages.first}
      let(:rbp){ra.benefit_packages.first}
      let!(:rhsb) do
        sb = rbp.health_sponsored_benefit
        sb.product_package_kind = :single_product
        sb.save
        sb
      end
      let(:ibp){ia.benefit_packages.first}
      let(:roster_size) { 5 }
      let(:enrollment_kinds) { ['health'] }
      let!(:census_employees) { create_list(:census_employee, roster_size, :with_active_assignment, benefit_sponsorship: bs, employer_profile: bs.profile, benefit_group: cbp) }
      let!(:person) { FactoryBot.create(:person) }
      let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
      let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person)}
      let!(:census_employee) { census_employees.first }
      let(:hbx_enrollment) do
        FactoryBot.build(
          :hbx_enrollment,
          :shop,
          household: family.active_household,
          family: family,
          product: cbp.sponsored_benefits.first.reference_product,
          coverage_kind: :health,
          employee_role_id: census_employee.employee_role.id,
          sponsored_benefit_package_id: cbp.id,
          benefit_group_assignment_id: census_employee.benefit_group_assignments.last.id
        )
      end

      let(:renewal_product_package)    { renewal_benefit_market_catalog.product_packages.detect { |package| package.package_kind == package_kind } }
      let(:product) { renewal_product_package.products[0] }

      let!(:update_product) do
        reference_product = current_benefit_package.sponsored_benefits.first.reference_product
        reference_product.renewal_product = product
        reference_product.save!
      end

      let(:active_bga) {FactoryBot.build(:benefit_sponsors_benefit_group_assignment, benefit_group: ibp, census_employee: census_employee)}
      let(:renewal_bga) {FactoryBot.build(:benefit_sponsors_benefit_group_assignment, benefit_group: rbp, census_employee: census_employee)}

      let(:renewal_benefit_package) { ra.benefit_packages.last }

      before :each do
        ra.benefit_packages.build(title: "Fake Title", probation_period_kind: ::BenefitMarkets::PROBATION_PERIOD_KINDS.sample).save!
        new_benefit_package = ra.benefit_packages.last
        renewal_benefit_package.benefit_sponsorship.census_employees.each do |census_employee|
          census_employee.add_renew_benefit_group_assignment([new_benefit_package])
          census_employee.benefit_group_assignments.each do |bga|
            allow(bga).to receive(:start_on).and_return(ra.start_on)
          end
        end
      end

      it "should return census employees by the benefit_packages package and assignment date" do
        expect(renewal_benefit_package.census_employees_assigned_on(ra.start_on).last.class).to eq(CensusEmployee)
      end

      it "should return blank if no census employees in non term and pending state" do
        renewal_benefit_package.benefit_sponsorship.census_employees.update_all(aasm_state: 'employment_terminated')
        expect(renewal_benefit_package.census_employees_assigned_on(ra.start_on).length).to eq(0)
      end
    end

    describe ".renew" do
      context "when passed renewal benefit package to current benefit package for renewal" do

        let(:renewal_application)             { initial_application.renew }
        let(:renewal_benefit_sponsor_catalog) { renewal_application.benefit_sponsor_catalog }
        let!(:renewal_benefit_package)        { renewal_application.benefit_packages.build }

        before do
          current_benefit_package.renew(renewal_benefit_package)
        end

        it "should have valid applications" do
          initial_application.validate
          renewal_application.validate
          expect(initial_application).to be_valid
          expect(renewal_application).to be_valid
        end

        it "should renew benefit package" do
          expect(renewal_benefit_package).to be_present
          expect(renewal_benefit_package.title).to eq current_benefit_package.title + "(#{renewal_benefit_package.start_on.year})"
          expect(renewal_benefit_package.description).to eq current_benefit_package.description
          expect(renewal_benefit_package.probation_period_kind).to eq current_benefit_package.probation_period_kind
          expect(renewal_benefit_package.is_default).to eq  current_benefit_package.is_default
        end

        it "should renew sponsored benefits" do
          expect(renewal_benefit_package.sponsored_benefits.size).to eq current_benefit_package.sponsored_benefits.size
        end

        it "should reference to renewal product package" do
          renewal_benefit_package.sponsored_benefits.each_with_index do |sponsored_benefit, i|
            current_sponsored_benefit = current_benefit_package.sponsored_benefits[i]
            expect(sponsored_benefit.product_package).to eq renewal_benefit_sponsor_catalog.product_packages.by_package_kind(current_sponsored_benefit.product_package_kind).by_product_kind(current_sponsored_benefit.product_kind)[0]
          end
        end

        it "should attach renewal reference product" do
          renewal_benefit_package.sponsored_benefits.each_with_index do |sponsored_benefit, i|
            current_sponsored_benefit = current_benefit_package.sponsored_benefits[i]
            expect(sponsored_benefit.reference_product).to eq current_sponsored_benefit.reference_product.renewal_product
          end
        end

        it "should renew sponsor contributions" do
          renewal_benefit_package.sponsored_benefits.each_with_index do |sponsored_benefit, i|
            expect(sponsored_benefit.sponsor_contribution).to be_present

            current_sponsored_benefit = current_benefit_package.sponsored_benefits[i]
            current_sponsored_benefit.sponsor_contribution.contribution_levels.each_with_index do |current_contribution_level, i|
              new_contribution_level = sponsored_benefit.sponsor_contribution.contribution_levels[i]
              expect(new_contribution_level.is_offered).to eq current_contribution_level.is_offered
              expect(new_contribution_level.contribution_factor).to eq current_contribution_level.contribution_factor
            end
          end
        end

        it "should renew pricing determinations" do
        end
      end

      context "when employer offering both health and dental coverages" do
        let(:product_kinds)            { [:health, :dental] }
        let(:dental_sponsored_benefit) { true }

        let(:renewal_application)             { initial_application.renew }
        let(:renewal_benefit_sponsor_catalog) { renewal_application.benefit_sponsor_catalog }
        let(:renewal_bp)  { renewal_application.benefit_packages.build }

        let(:current_app) { benefit_sponsorship.benefit_applications[0] }
        let(:current_bp)  { current_app.benefit_packages[0] }

        subject do
          current_bp.renew(renewal_bp)
        end

        context "when renewal product available for both health and dental" do 

          let(:health_sb) { current_bp.sponsored_benefit_for(:health) }
          let(:dental_sb) { current_bp.sponsored_benefit_for(:dental) }
  
          it "does build valid renewal benefit package" do
            expect(subject.valid?).to be_truthy
          end

          it "does renew health sponsored benefit" do
            expect(subject.sponsored_benefit_for(:health)).to be_present 
          end

          it "does renew health reference product" do
            expect(subject.sponsored_benefit_for(:health).reference_product).to eq health_sb.reference_product.renewal_product
          end

          it "does renew health sponsor contributions" do
            sponsor_contribution = subject.sponsored_benefit_for(:health).sponsor_contribution
            expect(sponsor_contribution).to be_present
            expect(sponsor_contribution.contribution_levels.size).to eq health_sb.sponsor_contribution.contribution_levels.size
          end

          it "does renew dental sponsored benefit" do
            expect(subject.sponsored_benefit_for(:dental)).to be_present 
          end

          it "does renew dental reference product" do
            expect(subject.sponsored_benefit_for(:dental).reference_product).to eq dental_sb.reference_product.renewal_product
          end

          it "does renew dental sponsor contributions" do
            sponsor_contribution = subject.sponsored_benefit_for(:dental).sponsor_contribution
            expect(sponsor_contribution).to be_present
            expect(sponsor_contribution.contribution_levels.size).to eq dental_sb.sponsor_contribution.contribution_levels.size
          end
        end

        context "when renewal product available for health only" do
          before :each do
            BenefitMarkets::Products::Product.where({
              "application_period.min" => renewal_benefit_market_catalog.application_period.min,
              "_type" => /Dental/i
            }).delete_all
          end

          let(:health_sb) { current_bp.sponsored_benefit_for(:health) }
          let(:dental_sb) { current_bp.sponsored_benefit_for(:dental) }
  
          it "does build valid renewal benefit package" do
            expect(subject.valid?).to be_truthy
          end

          it "does renew health sponsored benefit" do
            expect(subject.sponsored_benefit_for(:health)).to be_present 
          end

          it "does renew health reference product" do
            expect(subject.sponsored_benefit_for(:health).reference_product).to eq health_sb.reference_product.renewal_product
          end

          it "does renew health sponsor contributions" do
            sponsor_contribution = subject.sponsored_benefit_for(:health).sponsor_contribution
            expect(sponsor_contribution).to be_present
            expect(sponsor_contribution.contribution_levels.size).to eq health_sb.sponsor_contribution.contribution_levels.size
          end

          it "does not renew dental sponsored benefit" do
            expect(subject.sponsored_benefit_for(:dental)).to be_blank 
          end
        end

        context "when renewal product available for dental only" do

          before :each do
            BenefitMarkets::Products::Product.where({
              "application_period.min" => renewal_benefit_market_catalog.application_period.min,
              "_type" => /Health/i
            }).delete_all
          end

          let(:health_sb) { current_bp.sponsored_benefit_for(:health) }
          let(:dental_sb) { current_bp.sponsored_benefit_for(:dental) }
  
          it "does build valid renewal benefit package" do
            expect(subject.valid?).to be_truthy
          end

          it "does not renew health sponsored benefit" do
            expect(subject.sponsored_benefit_for(:health)).to be_blank 
          end

          it "does renew dental sponsored benefit" do
            expect(subject.sponsored_benefit_for(:dental)).to be_present 
          end

          it "does renew dental reference product" do
            expect(subject.sponsored_benefit_for(:dental).reference_product).to eq dental_sb.reference_product.renewal_product
          end

          it "does renew dental sponsor contributions" do
            sponsor_contribution = subject.sponsored_benefit_for(:dental).sponsor_contribution
            expect(sponsor_contribution).to be_present
            expect(sponsor_contribution.contribution_levels.size).to eq dental_sb.sponsor_contribution.contribution_levels.size
          end
        end

        context "when renewal product not available for both health and dental" do 
          before :each do
            BenefitMarkets::Products::Product.where({
              "application_period.min" => renewal_benefit_market_catalog.application_period.min
            }).delete_all
          end

          let(:health_sb) { current_bp.sponsored_benefit_for(:health) }
          let(:dental_sb) { current_bp.sponsored_benefit_for(:dental) }
  
          it "does build valid renewal benefit package" do
            expect(subject.valid?).to be_truthy
          end

          it "does not renew health sponsored benefit" do
            expect(subject.sponsored_benefit_for(:health)).to be_blank 
          end

          it "does not renew dental sponsored benefit" do
            expect(subject.sponsored_benefit_for(:dental)).to be_blank 
          end
        end

        context "when employer has conversion dental sponsored benefit" do 

          let(:health_sb) { current_bp.sponsored_benefit_for(:health) }
          let(:dental_sb) { current_bp.sponsored_benefits.unscoped.detect{|sb| sb.product_kind == :dental } }

          before do
            dental_sb.update(source_kind: :conversion)
            current_bp.reload
          end

          it "does build valid renewal benefit package" do
            expect(subject.valid?).to be_truthy
          end

          it "does renew health sponsored benefit" do
            expect(subject.sponsored_benefit_for(:health)).to be_present 
          end

          it "does renew health reference product" do
            expect(subject.sponsored_benefit_for(:health).reference_product).to eq health_sb.reference_product.renewal_product
          end

          it "does renew health sponsor contributions" do
            sponsor_contribution = subject.sponsored_benefit_for(:health).sponsor_contribution
            expect(sponsor_contribution).to be_present
            expect(sponsor_contribution.contribution_levels.size).to eq health_sb.sponsor_contribution.contribution_levels.size
          end

          it "does renew dental sponsored benefit" do
            expect(dental_sb.source_kind).to eq :conversion
            expect(subject.sponsored_benefit_for(:dental)).to be_present
            expect(subject.sponsored_benefit_for(:dental).source_kind).to eq :benefit_sponsor_catalog 
          end

          it "does renew dental reference product" do
            expect(subject.sponsored_benefit_for(:dental).reference_product).to eq dental_sb.reference_product.renewal_product
          end

          it "does renew dental sponsor contributions" do
            sponsor_contribution = subject.sponsored_benefit_for(:dental).sponsor_contribution
            expect(sponsor_contribution).to be_present
            expect(sponsor_contribution.contribution_levels.size).to eq dental_sb.sponsor_contribution.contribution_levels.size
          end
        end

        context "when employer has multi_product dental sponsored benefit" do
          let(:catalog_dental_package_kinds)      { [:single_product, :multi_product, :single_issuer] }
          let(:dental_package_kind)       { :multi_product }

          let(:health_sb) { current_bp.sponsored_benefit_for(:health) }
          let(:dental_sb) { current_bp.sponsored_benefits.detect{|sb| sb.product_kind == :dental } }

          let(:renewed_dental_sb) { subject.sponsored_benefit_for(:dental) }
          let(:renewal_products) { dental_sb.elected_products.map{|p| p.renewal_product.id} }

          it 'should have multi_product current dental sponsored benefit' do
            expect(dental_sb.product_package_kind).to eq :multi_product
            expect(dental_sb.elected_product_choices.present?).to be_truthy
          end

          it "does build valid renewal benefit package" do
            expect(subject.valid?).to be_truthy
          end

          it "does renew health sponsored benefit" do
            expect(subject.sponsored_benefit_for(:health)).to be_present
          end

          it "does renew health reference product" do
            expect(subject.sponsored_benefit_for(:health).reference_product).to eq health_sb.reference_product.renewal_product
          end

          it "does renew health sponsor contributions" do
            sponsor_contribution = subject.sponsored_benefit_for(:health).sponsor_contribution
            expect(sponsor_contribution).to be_present
            expect(sponsor_contribution.contribution_levels.size).to eq health_sb.sponsor_contribution.contribution_levels.size
          end

          it "does renew dental sponsored benefit" do
            expect(renewed_dental_sb).to be_present
            expect(renewed_dental_sb.source_kind).to eq :benefit_sponsor_catalog
          end

          it "does renew dental reference product" do
            expect(renewed_dental_sb.reference_product).to eq dental_sb.reference_product.renewal_product
          end

          it "does renew elected_product_choices" do
            expect(renewed_dental_sb.product_package_kind).to eq dental_sb.product_package_kind
            expect(renewed_dental_sb.elected_product_choices).to eq renewal_products
          end

          it "does renew dental sponsor contributions" do
            sponsor_contribution = renewed_dental_sb.sponsor_contribution
            expect(sponsor_contribution).to be_present
            expect(sponsor_contribution.contribution_levels.size).to eq dental_sb.sponsor_contribution.contribution_levels.size
          end
        end
      end
    end

    describe '.renew_member_benefit' do
      include_context "setup renewal application"

      let(:renewed_enrollment) { double("hbx_enrollment")}
      let(:ra) {renewal_application}
      let(:ia) {predecessor_application}
      let(:bs) { ra.predecessor.benefit_sponsorship}
      let(:cbp){ra.predecessor.benefit_packages.first}
      let(:rbp){ra.benefit_packages.first}
      let!(:rhsb) do
        sb = rbp.health_sponsored_benefit
        sb.product_package_kind = :single_product
        sb.save
        sb
      end
      let(:ibp){ia.benefit_packages.first}
      let(:roster_size) { 5 }
      let(:enrollment_kinds) { ['health'] }
      let!(:census_employees) { create_list(:census_employee, roster_size, :with_active_assignment, benefit_sponsorship: bs, employer_profile: bs.profile, benefit_group: cbp) }
      let!(:person) { FactoryBot.create(:person) }
      let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
      let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person)}
      let!(:census_employee) { census_employees.first }
      let(:hbx_enrollment) do
        FactoryBot.build(
          :hbx_enrollment,
          :shop,
          household: family.active_household,
          family: family,
          product: cbp.sponsored_benefits.first.reference_product,
          coverage_kind: :health,
          employee_role_id: census_employee.employee_role.id,
          sponsored_benefit_package_id: cbp.id,
          benefit_group_assignment_id: census_employee.benefit_group_assignments.last.id
        )
      end

      let(:renewal_product_package)    { renewal_benefit_market_catalog.product_packages.detect { |package| package.package_kind == package_kind } }
      let(:product) { renewal_product_package.products[0] }

      let!(:update_product) do
        reference_product = current_benefit_package.sponsored_benefits.first.reference_product
        reference_product.renewal_product = product
        reference_product.save!
      end

      let(:active_bga) {FactoryBot.build(:benefit_sponsors_benefit_group_assignment, benefit_group: ibp, census_employee: census_employee)}
      let(:renewal_bga) {FactoryBot.build(:benefit_sponsors_benefit_group_assignment, benefit_group: rbp, census_employee: census_employee)}

      let!(:census_update) do
        census_employee.benefit_group_assignments = [active_bga, renewal_bga]
        census_employee.save!
      end

      let(:hbx_enrollment) do
        FactoryBot.create(
          :hbx_enrollment,
          :shop,
          family: family,
          household: family.active_household,
          product: cbp.sponsored_benefits.first.reference_product,
          coverage_kind: :health,
          effective_on: predecessor_application.start_on,
          employee_role_id: census_employee.employee_role.id,
          sponsored_benefit_package_id: cbp.id,
          benefit_sponsorship: bs,
          benefit_group_assignment: active_bga
        )
      end

      before do
        census_employee.update_attributes(employee_role_id: employee_role.id)
        census_employee.employee_role.primary_family.active_household.hbx_enrollments << hbx_enrollment
        census_employee.employee_role.primary_family.save
        predecessor_application.update_attributes({:aasm_state => "active"})
        ra.update_attributes({:aasm_state => "enrollment_eligible"})
        hbx_enrollment.benefit_group_assignment_id = census_employee.benefit_group_assignments[0].id
        allow(rbp).to receive(:is_renewal_benefit_available?).and_return(true)
        allow(rbp).to receive(:trigger_renewal_model_event).and_return nil
        allow(hbx_enrollment).to receive(:renew_benefit).with(rbp).and_return(renewed_enrollment)
      end

      it "should have renewing enrollment" do
        expect(family.active_household.hbx_enrollments.map(&:aasm_state)).to eq ["coverage_selected"]
        rbp.renew_member_benefit(census_employee)
        family.reload
        expect(family.active_household.hbx_enrollments.map(&:aasm_state).include?("auto_renewing")).to eq true
      end

      it "when enrollment in terminated for initial application, should not generate renewal" do
        hbx_enrollment.update_attributes(benefit_sponsorship: bs, aasm_state: 'coverage_terminated')
        hbx_enrollment.save

        expect(family.active_household.hbx_enrollments.map(&:aasm_state)).to eq ["coverage_terminated"]
        rbp.renew_member_benefit(census_employee)
        family.reload
        expect(family.active_household.hbx_enrollments.map(&:aasm_state).include?("auto_renewing")).to eq false
      end

      context 'renewing enrollment already present' do
        let!(:renewing_hbx_enrollment) do
          FactoryBot.create(
            :hbx_enrollment,
            :shop,
            family: family,
            household: family.active_household,
            product: rbp.sponsored_benefits.first.reference_product,
            coverage_kind: :health,
            effective_on: ra.start_on,
            employee_role_id: census_employee.employee_role.id,
            sponsored_benefit_package_id: rbp.id,
            benefit_sponsorship: bs,
            benefit_group_assignment: renewal_bga
          )
        end

        context 'auto renewing enrollment present' do
          it 'should not generate a duplicate auto renewing enrollment' do
            renewing_hbx_enrollment.update_attributes(aasm_state: 'auto_renewing')
            enrolled_enrollments = family.active_household.hbx_enrollments.enrolled_waived_and_renewing
                                         .by_benefit_sponsorship(bs).by_effective_period(ra.effective_period)
            expect(enrolled_enrollments.count).to eq 1
            rbp.renew_member_benefit(census_employee)
            family.reload
            expect(enrolled_enrollments.count).to eq 1
          end
        end

        context 'renewing_waived enrollment present' do
          it 'should not generate a duplicate renewing_waived enrollment' do
            hbx_enrollment.update_attributes(benefit_sponsorship: bs, aasm_state: 'inactive')
            renewing_hbx_enrollment.update_attributes(aasm_state: 'renewing_waived')
            enrolled_enrollments = family.active_household.hbx_enrollments.enrolled_waived_and_renewing
                                         .by_benefit_sponsorship(bs).by_effective_period(ra.effective_period)
            expect(enrolled_enrollments.count).to eq 1
            rbp.renew_member_benefit(census_employee)
            family.reload
            expect(enrolled_enrollments.count).to eq 1
          end
        end

        context 'actively selected renewal enrollment present' do
          it 'should not generate a duplicate coverage_selected enrollment' do
            renewing_hbx_enrollment.update_attributes(aasm_state: 'coverage_selected')
            enrolled_enrollments = family.active_household.hbx_enrollments.enrolled_waived_and_renewing
                                         .by_benefit_sponsorship(bs).by_effective_period(ra.effective_period)
            expect(enrolled_enrollments.count).to eq 1
            rbp.renew_member_benefit(census_employee)
            family.reload
            expect(enrolled_enrollments.count).to eq 1
          end
        end

        context 'coverage canceled renewal enrollment' do
          it 'should not generate a duplicate coverage_selected enrollment' do
            renewing_hbx_enrollment.update_attributes(aasm_state: 'coverage_canceled')
            enrolled_enrollments = family.active_household.hbx_enrollments.enrolled_waived_and_renewing
                                         .by_benefit_sponsorship(bs).by_effective_period(ra.effective_period)
            expect(enrolled_enrollments.count).to eq 0
            rbp.renew_member_benefit(census_employee)
            family.reload
            expect(enrolled_enrollments.count).to eq 1
          end
        end
      end
    end

    describe '.is_renewal_benefit_available?' do

      let(:renewal_product_package)    { renewal_benefit_market_catalog.product_packages.detect { |package| package.package_kind == package_kind } }
      let(:product) { renewal_product_package.products[0] }
      let(:reference_product) { current_benefit_package.sponsored_benefits[0].reference_product }
      let(:current_enrolled_product) { product_package.products[2] }

      let!(:update_product) do
        reference_product.renewal_product = product
        reference_product.save!
      end
      
      let(:renewal_benefit_sponsor_catalog) { benefit_sponsorship.benefit_sponsor_catalog_for(renewal_effective_date) }
      let(:renewal_application)             { initial_application.renew(renewal_benefit_sponsor_catalog) }
      let(:renewal_benefit_package)         { renewal_application.benefit_packages.build }

      context "when renewal product missing" do
        let(:hbx_enrollment) { double(product: current_enrolled_product, is_coverage_waived?: false, coverage_termination_pending?: false, coverage_kind: :health) }
        let(:renewal_sponsored_benefit) do
          renewal_benefit_package.sponsored_benefits.build(
            product_package_kind: :single_issuer
          )
        end
        let(:renewal_sponsored_benefit) do
          renewal_benefit_package.sponsored_benefits.build(
            product_package_kind: :single_issuer
          )
        end

        before do
          #removing hbx_enrollment.product.renewal_product from renewal_product_package
          allow(renewal_sponsored_benefit).to receive(:products).and_return(renewal_product_package.products.reject{ |prod| prod.id == hbx_enrollment.product.renewal_product.id })
          allow(current_enrolled_product).to receive(:renewal_product).and_return(nil)
          allow(renewal_benefit_package).to receive(:sponsored_benefit_for).and_return(renewal_sponsored_benefit)
        end

        it 'should return false' do
          expect(renewal_benefit_package.is_renewal_benefit_available?(hbx_enrollment)).to be_falsey
        end
      end

      context "when renewal product offered by employer" do
        let(:hbx_enrollment) { double(product: current_benefit_package.sponsored_benefits.first.reference_product, coverage_kind: :health, is_coverage_waived?: false, coverage_termination_pending?: false) }
        let(:sponsored_benefit) { renewal_benefit_package.sponsored_benefits.build(product_package_kind: :single_issuer) }

        before do
          allow(sponsored_benefit).to receive(:products).and_return(renewal_product_package.products)
          allow(renewal_benefit_package).to receive(:sponsored_benefit_for).and_return(sponsored_benefit) 
        end

        it 'should return true' do
          expect(renewal_benefit_package.is_renewal_benefit_available?(hbx_enrollment)).to be_truthy
        end
      end

      context "when renewal product not offered by employer" do
        let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile) }
        let(:hbx_enrollment) do
          double(
            product: current_benefit_package.sponsored_benefits.first.reference_product,
            family: double('Family'),
            coverage_kind: :health,
            is_coverage_waived?: false,
            coverage_termination_pending?: false
          )
        end
        let(:sponsored_benefit) { renewal_benefit_package.sponsored_benefits.build(product_package_kind: :single_issuer) }

        before do
          allow(sponsored_benefit).to receive(:products).and_return(renewal_product_package.products)
          allow(renewal_benefit_package).to receive(:sponsored_benefit_for).and_return(sponsored_benefit) 
        end

        it "should return false" do
          expect(renewal_benefit_package.is_renewal_benefit_available?(hbx_enrollment)).to be_falsey
        end
      end
    end

    describe '.sponsored_benefit_for' do
    end

    describe '.assigned_census_employees_on' do
    end

    describe '.renew_employee_benefits' do
      include_context "setup employees with benefits"

    end

    describe 'changing reference product' do
      context 'changing reference product' do
        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup initial benefit application"

        let(:sponsored_benefit) { initial_application.benefit_packages.first.sponsored_benefits.first }
        let(:new_reference_product) { product_package.products[2] }

        before do
          @benefit_application_id = sponsored_benefit.benefit_package.benefit_application.id
          sponsored_benefit.reference_product_id = new_reference_product._id
          sponsored_benefit.save!
        end

        it 'changes to the correct product' do
          bs = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.benefit_application_find([@benefit_application_id]).first
          benefit_application_from_db = bs.benefit_applications.detect { |ba| ba.id == @benefit_application_id }
          expect(sponsored_benefit.reference_product).to eq(new_reference_product)
          sponsored_benefit_from_db = benefit_application_from_db.benefit_packages.first.sponsored_benefits.first
          expect(sponsored_benefit_from_db.id).to eq(sponsored_benefit.id)
          expect(sponsored_benefit_from_db.reference_product).to eq(new_reference_product)
        end
      end
    end

    describe '.reinstate_canceled_member_benefits' do

      context 'when application got canceled due to ineligble state' do


        context 'given employee coverages got canceled after application cancellation' do 

          it 'should reinstate their canceled coverages' do 
          end
        end

        context 'given employee coverages got canceled before application cancellation' do

          it 'should not reinstate their canceled coverages' do 
          end 
        end
      end

      context 'when application not canceled due to ineligble state' do 

        it 'should not process any reinstatements on enrollments' do 
        end
      end
    end

    describe '.effectuate_member_benefits', :dbclean => :after_each do

      include_context "setup renewal application"

      let(:benefit_group_assignment) {FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_package)}
      let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: abc_profile.id) }
      let(:census_employee) { FactoryBot.create(:census_employee, employer_profile: benefit_sponsorship.profile, benefit_sponsorship: benefit_sponsorship, benefit_group_assignments: [benefit_group_assignment]) }
      let(:person)       { FactoryBot.create(:person, :with_family) }
      let!(:family)       { person.primary_family }
      let!(:hbx_enrollment) do
        hbx_enrollment =
          FactoryBot.create(
            :hbx_enrollment,
            :with_enrollment_members,
            :with_product,
            family: family,
            household: family.active_household,
            aasm_state: enr_state,
            effective_on: renewal_application.start_on,
            rating_area_id: renewal_application.recorded_rating_area_id,
            sponsored_benefit_id: renewal_application.benefit_packages.first.health_sponsored_benefit.id,
            sponsored_benefit_package_id: benefit_package.id,
            benefit_sponsorship_id: renewal_application.benefit_sponsorship.id,
            employee_role_id: employee_role.id
          )
        hbx_enrollment.benefit_sponsorship = benefit_sponsorship
        hbx_enrollment.save!
        hbx_enrollment
      end

      context "when enrollment is in auto renewing state" do
        let(:enr_state) {"auto_renewing"}

        it "should move auto renewing enrollment to coverage enrolled state" do
          expect(hbx_enrollment.aasm_state).to eq "auto_renewing"
          benefit_package.effectuate_member_benefits
          hbx_enrollment.reload
          expect(hbx_enrollment.aasm_state).to eq "coverage_enrolled"
        end
      end

      context "when enrollment is in coverage selected state state" do
        let(:enr_state) {"coverage_selected"}

        it "should move auto renewing enrollment to coverage enrolled state" do
          expect(hbx_enrollment.aasm_state).to eq "coverage_selected"
          benefit_package.effectuate_member_benefits
          hbx_enrollment.reload
          expect(hbx_enrollment.aasm_state).to eq "coverage_enrolled"
        end
      end
    end

    describe '.cancel_member_benefits', :dbclean => :after_each do

      include_context "setup renewal application"

      let(:benefit_group_assignment) {FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_package)}
      let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: abc_profile.id) }
      let(:census_employee) { FactoryBot.create(:census_employee, employer_profile: benefit_sponsorship.profile, benefit_sponsorship: benefit_sponsorship, benefit_group_assignments: [benefit_group_assignment]) }
      let(:person)       { FactoryBot.create(:person, :with_family) }
      let!(:family)       { person.primary_family }
      let!(:hbx_enrollment) do
        hbx_enrollment =
          FactoryBot.create(
            :hbx_enrollment,
            :with_enrollment_members,
            :with_product,
            family: family,
            household: family.active_household,
            aasm_state: enr_state,
            effective_on: renewal_application.start_on,
            rating_area_id: renewal_application.recorded_rating_area_id,
            sponsored_benefit_id: renewal_application.benefit_packages.first.health_sponsored_benefit.id,
            sponsored_benefit_package_id: benefit_package.id,
            benefit_sponsorship_id: renewal_application.benefit_sponsorship.id,
            employee_role_id: employee_role.id
          )
        hbx_enrollment.benefit_sponsorship = benefit_sponsorship
        hbx_enrollment.save!
        hbx_enrollment
      end

      context "when enrollment is in auto renewing state" do
        let(:enr_state) {"auto_renewing"}
        let(:renewal_state) { :canceled }

        it "should move auto renewing enrollment to coverage enrolled state" do
          expect(hbx_enrollment.aasm_state).to eq "auto_renewing"
          benefit_package.cancel_member_benefits
          expect(hbx_enrollment.reload.aasm_state).to eq "coverage_canceled"
        end

        it "should not persist retro cancel reason for canceled applications" do
          expect(hbx_enrollment.reload.terminate_reason).to eq nil
        end
      end

      context "when enrollment is in coverage selected state state" do
        let(:enr_state) {"coverage_selected"}
        let(:renewal_state) { :retroactive_canceled }

        it "should move auto renewing enrollment to coverage enrolled state" do
          expect(hbx_enrollment.aasm_state).to eq "coverage_selected"
          benefit_package.cancel_member_benefits
          expect(hbx_enrollment.reload.aasm_state).to eq "coverage_canceled"
        end

        it "should persist retro cancel reason for retroactive_canceled applications" do
          benefit_package.cancel_member_benefits
          expect(hbx_enrollment.reload.terminate_reason).to eq "retroactive_canceled"
        end
      end
    end

    describe '.terminate_member_benefits', :dbclean => :after_each do

      include_context "setup initial benefit application" do
        let(:current_effective_date) { (TimeKeeper.date_of_record - 2.months).beginning_of_month }
      end

      let(:benefit_package)  { initial_application.benefit_packages.first }
      let(:benefit_group_assignment) {FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_package)}
      let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: abc_profile.id) }
      let(:census_employee) do
        FactoryBot.create(
          :census_employee,
          employer_profile: benefit_sponsorship.profile,
          benefit_sponsorship: benefit_sponsorship,
          benefit_group_assignments: [benefit_group_assignment]
        )
      end
      let(:person)       { FactoryBot.create(:person, :with_family) }
      let!(:family)       { person.primary_family }
      let!(:hbx_enrollment) do
        hbx_enrollment =
          FactoryBot.create(
            :hbx_enrollment,
            :with_enrollment_members,
            :with_product,
            family: family,
            household: family.active_household,
            aasm_state: "coverage_selected",
            effective_on: initial_application.start_on,
            rating_area_id: initial_application.recorded_rating_area_id,
            sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
            sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
            benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
            employee_role_id: employee_role.id
          )
        hbx_enrollment.benefit_sponsorship = benefit_sponsorship
        hbx_enrollment.save!
        hbx_enrollment
      end

      let(:benefit_group_assignment_1) {FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_package)}
      let(:employee_role_1) { FactoryBot.create(:benefit_sponsors_employee_role, person: person_1, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee_1.id, benefit_sponsors_employer_profile_id: abc_profile.id) }
      let(:census_employee_1) do
        FactoryBot.create(
          :census_employee,
          employer_profile: benefit_sponsorship.profile,
          benefit_sponsorship: benefit_sponsorship,
          benefit_group_assignments: [benefit_group_assignment_1]
        )
      end
      let(:person_1)       { FactoryBot.create(:person, :with_family) }
      let!(:family_1)       { person_1.primary_family }
      let!(:hbx_enrollment_1) do
        hbx_enrollment =
          FactoryBot.create(
            :hbx_enrollment,
            :with_enrollment_members,
            :with_product,
            family: family_1,
            household: family_1.active_household,
            aasm_state: "coverage_selected",
            effective_on: TimeKeeper.date_of_record.next_month,
            rating_area_id: initial_application.recorded_rating_area_id,
            sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
            sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
            benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
            employee_role_id: employee_role_1.id
          )
        hbx_enrollment.benefit_sponsorship = benefit_sponsorship
        hbx_enrollment.save!
        hbx_enrollment
      end

      let(:end_on) { TimeKeeper.date_of_record.prev_month }

      context "when coverage_selected enrollments are present", :dbclean => :after_each do

        before do
          initial_application.update_attributes!(aasm_state: :terminated, effective_period: initial_application.start_on..end_on, terminated_on: TimeKeeper.date_of_record, termination_kind: "nonpayment", termination_reason: "")
          benefit_package.terminate_member_benefits
          hbx_enrollment.reload
          hbx_enrollment_1.reload
        end

        it 'should move valid enrollments to terminated state' do
          expect(hbx_enrollment.aasm_state).to eq "coverage_terminated"
        end

        it 'should update terminated_on field on hbx_enrollment' do
          expect(hbx_enrollment.terminated_on).to eq initial_application.end_on
        end

        it 'should move future enrollments to canceled state' do
          expect(hbx_enrollment_1.aasm_state).to eq "coverage_canceled"
        end

        context "benefit application with termination_kind and NO termination_reason" do
          it 'should persist terminate reason to enrollment' do
            expect(hbx_enrollment.terminate_reason).to eq "non_payment"
          end
        end
      end

      context "when an employee has coverage_termination_pending enrollment", :dbclean => :after_each do

        let(:hbx_enrollment_terminated_on) { end_on.prev_month }

        before do
          initial_application.update_attributes!(aasm_state: :terminated, effective_period: initial_application.start_on..end_on, terminated_on: TimeKeeper.date_of_record, termination_kind: "nonpayment", termination_reason: "nonpayment")
          hbx_enrollment.update_attributes!(effective_on: initial_application.start_on, aasm_state: "coverage_termination_pending", terminated_on: hbx_enrollment_terminated_on)
          hbx_enrollment_1.update_attributes!(effective_on: initial_application.start_on, aasm_state: "coverage_termination_pending", terminated_on: end_on + 2.months)
          benefit_package.terminate_member_benefits(enroll_term_reason: "nonpayment")
          hbx_enrollment.reload
          hbx_enrollment_1.reload
        end

        it "should not update hbx_enrollment terminated_on if terminated_on < benefit_application end on" do
          expect(hbx_enrollment.terminated_on).to eq hbx_enrollment_terminated_on
          expect(hbx_enrollment.terminated_on).not_to eq end_on
        end

        it "should update hbx_enrollment terminated_on if terminated_on > benefit_application end on" do
          expect(hbx_enrollment_1.terminated_on).to eq end_on
        end

        context "benefit application with termination_kind and termination_reason" do
          it 'should persist terminate reason to enrollment' do
            expect(hbx_enrollment_1.terminate_reason).to eq "nonpayment"
          end
        end
      end

      context "when an employee has coverage_terminated enrollment", :dbclean => :after_each do

        let(:hbx_enrollment_terminated_on) { end_on.prev_month }

        before do
          initial_application.update_attributes!(aasm_state: :terminated, effective_period: initial_application.start_on..end_on, terminated_on: TimeKeeper.date_of_record)
          hbx_enrollment.update_attributes!(effective_on: initial_application.start_on, aasm_state: "coverage_terminated", terminated_on: hbx_enrollment_terminated_on)
          hbx_enrollment_1.update_attributes!(effective_on: initial_application.start_on, aasm_state: "coverage_terminated", terminated_on: end_on + 2.months)
          benefit_package.terminate_member_benefits
          hbx_enrollment.reload
          hbx_enrollment_1.reload
        end

        it "should update terminated_on date on enrollment if terminated_on > benefit_application end_on" do
          expect(hbx_enrollment_1.terminated_on).to eq end_on
        end

        it "should NOT update terminated_on date on enrollment if terminated_on < benefit_application end_on" do
          expect(hbx_enrollment.terminated_on).to eq hbx_enrollment_terminated_on
        end

        context "terminate_benefit_group_assignments", :dbclean => :after_each do

          before :each do
            @bga = initial_application.benefit_sponsorship.census_employees.first.benefit_group_assignments.first
            @bga.update_attributes!(end_on: benefit_package.end_on)
          end

          it "should update benefit_group_assignment end_on if end_on < benefit_application end on" do
            benefit_package.terminate_benefit_group_assignments
            expect(benefit_package.end_on).to eq @bga.end_on
          end
        end
      end
    end

    describe '.reinstate_member_benefits' do
      include_context 'setup initial benefit application'

      let!(:effective_period_start_on) { TimeKeeper.date_of_record.beginning_of_year }
      let!(:effective_period_end_on)   { TimeKeeper.date_of_record.end_of_year }
      let!(:site) { BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market }
      let!(:benefit_market) { site.benefit_markets.first }
      let!(:effective_period) { (effective_period_start_on..effective_period_end_on) }
      let!(:current_benefit_market_catalog) do
        BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_catalog(site, benefit_market, effective_period)
        benefit_market.benefit_market_catalogs.where(:'application_period.min' => effective_period_start_on).first
      end

      let!(:service_areas) do
        ::BenefitMarkets::Locations::ServiceArea.where(:active_year => current_benefit_market_catalog.application_period.min.year).all.to_a
      end

      let!(:rating_area) do
        ::BenefitMarkets::Locations::RatingArea.where(:active_year => current_benefit_market_catalog.application_period.min.year).first
      end
      let(:current_effective_date) {TimeKeeper.date_of_record.beginning_of_year}

      let(:person) { FactoryBot.create(:person, :with_employee_role, :with_family) }
      let(:family) { person.primary_family }
      let!(:census_employee) do
        ce = FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package)
        ce.update_attributes!(employee_role_id: person.employee_roles.first.id)
        person.employee_roles.first.update_attributes(census_employee_id: ce.id)
        ce
      end
      let!(:enrollment) do
        FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                          household: family.latest_household,
                          coverage_kind: 'health',
                          family: family,
                          aasm_state: 'coverage_selected',
                          effective_on: current_effective_date,
                          kind: 'employer_sponsored',
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: current_benefit_package.id,
                          sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                          employee_role_id: census_employee.employee_role.id,
                          product: current_benefit_package.sponsored_benefits[0].reference_product,
                          rating_area_id: BSON::ObjectId.new,
                          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
      end

      context 'given employee coverages got terminated after application termination' do
        before do
          period = initial_application.effective_period.min..(initial_application.end_on - 6.months).end_of_month
          initial_application.update_attributes!(termination_reason: 'nonpayment', terminated_on: period.max, effective_period: period)
          initial_application.terminate_enrollment!
          effective_period = (initial_application.effective_period.max.next_day)..(initial_application.benefit_sponsor_catalog.effective_period.max)
          cloned_application = ::BenefitSponsors::Operations::BenefitApplications::Clone.new.call({benefit_application: initial_application, effective_period: effective_period}).success
          cloned_catalog = ::BenefitMarkets::Operations::BenefitSponsorCatalogs::Clone.new.call(benefit_sponsor_catalog: initial_application.benefit_sponsor_catalog).success

          cloned_catalog.benefit_application = cloned_application
          cloned_catalog.save!
          cloned_application.assign_attributes({aasm_state: :active, reinstated_id: initial_application.id, benefit_sponsor_catalog_id: cloned_catalog.id})
          cloned_application.save!

          @cloned_package = cloned_application.benefit_packages[0]
          @cloned_package.reinstate_member_benefits
          census_employee.reload
        end

        context 'on reinstate' do
          it 'should reinstate terminated benefit group assigment' do
            reinstated_bga = census_employee.benefit_group_assignments.where(benefit_package_id: @cloned_package.id).first
            expect(reinstated_bga.start_on).to eq @cloned_package.start_on
          end

          it 'should reinstate terminated coverages' do
            reinstated_hbx = HbxEnrollment.where(sponsored_benefit_package_id: @cloned_package.id).first
            expect(reinstated_hbx.effective_on).to eq @cloned_package.start_on
            if TimeKeeper.date_of_record >= reinstated_hbx.effective_on
              expect(reinstated_hbx.aasm_state).to eq "coverage_enrolled"
            else
              expect(reinstated_hbx.aasm_state).to eq "coverage_selected"
            end
            expect(reinstated_hbx.predecessor_enrollment_id).to eq enrollment.id
          end

          it 'should assign reinstated benefit group assigment on reinstated enrollment' do
            reinstated_hbx = HbxEnrollment.where(sponsored_benefit_package_id: @cloned_package.id).first
            reinstated_bga = census_employee.benefit_group_assignments.where(benefit_package_id: @cloned_package.id).first
            expect(reinstated_hbx.benefit_group_assignment_id).to eq reinstated_bga.id
          end

          it 'should update reinstated benefit group assigment with hbx enrollment id' do
            reinstated_bga = census_employee.benefit_group_assignments.where(benefit_package_id: @cloned_package.id).first
            reinstated_hbx = HbxEnrollment.where(sponsored_benefit_package_id: @cloned_package.id).first
            expect(reinstated_bga.hbx_enrollment_id).to eq reinstated_hbx.id
          end
        end
      end

      context 'given employee coverages moved to terminated pending after application terminated with future date' do
        before do
          initial_application.update_attributes(effective_period: (initial_application.start_on + 6.months..initial_application.end_on + 6.months))
          initial_application.benefit_sponsor_catalog.update_attributes(effective_date: initial_application.start_on + 6.months, effective_period: (initial_application.start_on + 6.months..initial_application.end_on + 6.months))
          enrollment.update_attributes(effective_on: initial_application.start_on)
          census_employee.benefit_group_assignments.first.update_attributes(start_on: initial_application.start_on)
          census_employee.reload
          period = (initial_application.effective_period.min..TimeKeeper.date_of_record.end_of_month)
          initial_application.update_attributes!(termination_reason: 'nonpayment', terminated_on: period.max, effective_period: period)
          initial_application.schedule_enrollment_termination!
          effective_period = (initial_application.effective_period.max.next_day)..(initial_application.benefit_sponsor_catalog.effective_period.max)
          cloned_application = ::BenefitSponsors::Operations::BenefitApplications::Clone.new.call({benefit_application: initial_application, effective_period: effective_period}).success
          cloned_catalog = ::BenefitMarkets::Operations::BenefitSponsorCatalogs::Clone.new.call(benefit_sponsor_catalog: initial_application.benefit_sponsor_catalog).success
          cloned_catalog.benefit_application = cloned_application
          cloned_catalog.save!
          cloned_application.assign_attributes({aasm_state: :active, reinstated_id: initial_application.id, benefit_sponsor_catalog_id: cloned_catalog.id})
          cloned_application.save!
          @cloned_package = cloned_application.benefit_packages[0]
          @cloned_package.reinstate_member_benefits
          census_employee.reload
        end

        context 'on reinstate' do

          it 'should reinstate terminated benefit group assigment' do
            reinstated_bga = census_employee.benefit_group_assignments.where(benefit_package_id: @cloned_package.id).first
            expect(reinstated_bga.start_on).to eq @cloned_package.start_on
          end

          it 'should reinstate terminated coverages' do
            reinstated_hbx = HbxEnrollment.where(sponsored_benefit_package_id: @cloned_package.id).first
            expect(reinstated_hbx.effective_on).to eq @cloned_package.start_on
            expect(reinstated_hbx.aasm_state).to eq "coverage_selected"
            expect(reinstated_hbx.predecessor_enrollment_id).to eq enrollment.id
          end

          it 'should assign reinstated benefit group assigment on reinstated enrollment' do
            reinstated_hbx = HbxEnrollment.where(sponsored_benefit_package_id: @cloned_package.id).first
            reinstated_bga = census_employee.benefit_group_assignments.where(benefit_package_id: @cloned_package.id).first
            expect(reinstated_hbx.benefit_group_assignment_id).to eq reinstated_bga.id
          end

          it 'should update reinstated benefit group assigment with hbx enrollment id' do
            reinstated_bga = census_employee.benefit_group_assignments.where(benefit_package_id: @cloned_package.id).first
            reinstated_hbx = HbxEnrollment.where(sponsored_benefit_package_id: @cloned_package.id).first
            expect(reinstated_bga.hbx_enrollment_id).to eq reinstated_hbx.id
          end
        end
      end

      context 'given employee coverages canceled after application canceled' do
        before do
          initial_application.cancel!
          effective_period = (initial_application.start_on..initial_application.end_on)
          cloned_application = ::BenefitSponsors::Operations::BenefitApplications::Clone.new.call({benefit_application: initial_application, effective_period: effective_period}).success
          cloned_catalog = ::BenefitMarkets::Operations::BenefitSponsorCatalogs::Clone.new.call(benefit_sponsor_catalog: initial_application.benefit_sponsor_catalog).success
          cloned_catalog.benefit_application = cloned_application
          cloned_catalog.save!
          cloned_application.assign_attributes({aasm_state: :active, reinstated_id: initial_application.id, benefit_sponsor_catalog_id: cloned_catalog.id})
          cloned_application.save!
          @cloned_package = cloned_application.benefit_packages[0]
          @cloned_package.reinstate_member_benefits
          census_employee.reload
        end

        context 'on reinstate' do

          it 'should reinstate terminated benefit group assigment' do
            reinstated_bga = census_employee.benefit_group_assignments.where(benefit_package_id: @cloned_package.id).first
            expect(reinstated_bga.start_on).to eq @cloned_package.start_on
          end

          it 'should reinstate terminated coverages' do
            reinstated_hbx = HbxEnrollment.where(sponsored_benefit_package_id: @cloned_package.id).first
            expect(reinstated_hbx.effective_on).to eq @cloned_package.start_on
            expect(reinstated_hbx.aasm_state).to eq "coverage_enrolled"
            expect(reinstated_hbx.predecessor_enrollment_id).to eq enrollment.id
          end

          it 'should assign reinstated benefit group assigment on reinstated enrollment' do
            reinstated_hbx = HbxEnrollment.where(sponsored_benefit_package_id: @cloned_package.id).first
            reinstated_bga = census_employee.benefit_group_assignments.where(benefit_package_id: @cloned_package.id).first
            expect(reinstated_hbx.benefit_group_assignment_id).to eq reinstated_bga.id
          end

          it 'should update reinstated benefit group assigment with hbx enrollment id' do
            reinstated_bga = census_employee.benefit_group_assignments.where(benefit_package_id: @cloned_package.id).first
            reinstated_hbx = HbxEnrollment.where(sponsored_benefit_package_id: @cloned_package.id).first
            expect(reinstated_bga.hbx_enrollment_id).to eq reinstated_hbx.id
          end
        end
      end

      context 'given employee coverages canceled after application canceled' do #legacy cancel
        before do
          initial_application.cancel!
          initial_application.update_attributes(aasm_state: :canceled)
          enrollment.update_attributes(terminate_reason: '')
          effective_period = (initial_application.start_on..initial_application.end_on)
          cloned_application = ::BenefitSponsors::Operations::BenefitApplications::Clone.new.call({benefit_application: initial_application, effective_period: effective_period}).success
          cloned_catalog = ::BenefitMarkets::Operations::BenefitSponsorCatalogs::Clone.new.call(benefit_sponsor_catalog: initial_application.benefit_sponsor_catalog).success
          cloned_catalog.benefit_application = cloned_application
          cloned_catalog.save!
          cloned_application.assign_attributes({aasm_state: :active, reinstated_id: initial_application.id, benefit_sponsor_catalog_id: cloned_catalog.id})
          cloned_application.save!
          @cloned_package = cloned_application.benefit_packages[0]
          @cloned_package.reinstate_member_benefits
          census_employee.reload
        end

        context 'on reinstate' do

          it 'should reinstate terminated benefit group assigment' do
            reinstated_bga = census_employee.benefit_group_assignments.where(benefit_package_id: @cloned_package.id).first
            expect(reinstated_bga.start_on).to eq @cloned_package.start_on
          end

          it 'should reinstate terminated coverages' do
            reinstated_hbx = HbxEnrollment.where(sponsored_benefit_package_id: @cloned_package.id).first
            expect(reinstated_hbx.effective_on).to eq @cloned_package.start_on
            expect(reinstated_hbx.aasm_state).to eq "coverage_enrolled"
            expect(reinstated_hbx.predecessor_enrollment_id).to eq enrollment.id
          end

          it 'should assign reinstated benefit group assigment on reinstated enrollment' do
            reinstated_hbx = HbxEnrollment.where(sponsored_benefit_package_id: @cloned_package.id).first
            reinstated_bga = census_employee.benefit_group_assignments.where(benefit_package_id: @cloned_package.id).first
            expect(reinstated_hbx.benefit_group_assignment_id).to eq reinstated_bga.id
          end

          it 'should update reinstated benefit group assigment with hbx enrollment id' do
            reinstated_bga = census_employee.benefit_group_assignments.where(benefit_package_id: @cloned_package.id).first
            reinstated_hbx = HbxEnrollment.where(sponsored_benefit_package_id: @cloned_package.id).first
            expect(reinstated_bga.hbx_enrollment_id).to eq reinstated_hbx.id
          end
        end
      end
    end

    describe '.termination_pending_member_benefits' do

      include_context "setup initial benefit application" do
        let(:current_effective_date) { (TimeKeeper.date_of_record - 2.months).beginning_of_month }
      end

      let(:benefit_package)  { initial_application.benefit_packages.first }
      let(:benefit_group_assignment) {FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_package)}
      let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: abc_profile.id) }
      let(:census_employee) do
        FactoryBot.create(
          :census_employee,
          employer_profile: benefit_sponsorship.profile,
          benefit_sponsorship: benefit_sponsorship,
          benefit_group_assignments: [benefit_group_assignment]
        )
      end
      let(:person)       { FactoryBot.create(:person, :with_family) }
      let!(:family)       { person.primary_family }
      let!(:hbx_enrollment) do
        hbx_enrollment =
          FactoryBot.create(
            :hbx_enrollment,
            :with_enrollment_members,
            :with_product,
            household: family.active_household,
            family:family,
            aasm_state: "coverage_selected",
            effective_on: initial_application.start_on,
            rating_area_id: initial_application.recorded_rating_area_id,
            sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
            sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
            benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
            employee_role_id: employee_role.id
          )
        hbx_enrollment.benefit_sponsorship = benefit_sponsorship
        hbx_enrollment.save!
        hbx_enrollment
      end

      let(:employee_role_1) { FactoryBot.create(:benefit_sponsors_employee_role, person: person_1, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee_1.id, benefit_sponsors_employer_profile_id: abc_profile.id) }
      let(:census_employee_1) do
        FactoryBot.create(
          :census_employee,
          employer_profile: benefit_sponsorship.profile,
          benefit_sponsorship: benefit_sponsorship,
          benefit_group_assignments: [benefit_group_assignment]
        )
      end
      let(:person_1)       { FactoryBot.create(:person, :with_family) }
      let!(:family_1)       { person_1.primary_family }
      let!(:hbx_enrollment_1) do
        hbx_enrollment =
          FactoryBot.create(
            :hbx_enrollment,
            :with_enrollment_members,
            :with_product,
            household: family_1.active_household,
            family: family_1,
            aasm_state: "coverage_selected",
            effective_on: initial_application.start_on,
            rating_area_id: initial_application.recorded_rating_area_id,
            sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
            sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
            benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
            employee_role_id: employee_role_1.id
          )
        hbx_enrollment.benefit_sponsorship = benefit_sponsorship
        hbx_enrollment.save!
        hbx_enrollment
      end

      let(:end_on) { TimeKeeper.date_of_record.next_month }

      before do
        initial_application.update_attributes!(aasm_state: :termination_pending, effective_period: initial_application.start_on..end_on, terminated_on: TimeKeeper.date_of_record, termination_kind: "nonpayment", termination_reason: "")
        benefit_package.termination_pending_member_benefits
        hbx_enrollment.reload
      end

      it 'should move valid enrollments to termination pending state' do
        expect(hbx_enrollment.aasm_state).to eq "coverage_termination_pending"
      end

      it 'should update terminated_on field on hbx_enrollment' do
        expect(hbx_enrollment.terminated_on).to eq initial_application.end_on
      end

      context "benefit application with termination_kind and NO termination_reason" do
        it 'should persist terminate reason to enrollment' do
          expect(hbx_enrollment.terminate_reason).to eq "non_payment"
        end
      end

      context "when an employee has coverage_termination_pending enrollment", :dbclean => :after_each do

        let(:hbx_enrollment_terminated_on) { end_on.prev_month }

        before do
          initial_application.update_attributes!(aasm_state: :termination_pending, effective_period: initial_application.start_on..end_on, terminated_on: TimeKeeper.date_of_record, termination_kind: "nonpayment", termination_reason: "nonpayment")
          hbx_enrollment.update_attributes!(effective_on: initial_application.start_on, aasm_state: "coverage_termination_pending", terminated_on: hbx_enrollment_terminated_on)
          hbx_enrollment_1.update_attributes!(effective_on: initial_application.start_on, aasm_state: "coverage_termination_pending", terminated_on: end_on + 2.months)
          benefit_package.termination_pending_member_benefits(enroll_term_reason: "nonpayment")
          hbx_enrollment.reload
          hbx_enrollment_1.reload
        end

        it "should not update hbx_enrollment terminated_on if terminated_on < benefit_application end on" do
          expect(hbx_enrollment.terminated_on).to eq hbx_enrollment_terminated_on
          expect(hbx_enrollment.terminated_on).not_to eq end_on
        end

        it "should update hbx_enrollment terminated_on if terminated_on > benefit_application end on" do
          expect(hbx_enrollment_1.terminated_on).to eq end_on
        end

        context "benefit application with termination_kind and termination_reason" do
          it 'should persist terminate reason to enrollment' do
            expect(hbx_enrollment_1.terminate_reason).to eq "nonpayment"
          end
        end

        context "pending terminate_benefit_group_assignments", :dbclean => :after_each do
          before :each do
            @bga = initial_application.benefit_sponsorship.census_employees.first.benefit_group_assignments.first
            @bga.update_attributes!(end_on: nil)
          end

          it "should update benefit_group_assignment end_on if end_on > benefit_application end on" do
            expect(@bga.end_on).to eq nil
            benefit_package.terminate_benefit_group_assignments
            expect(@bga.end_on).to eq benefit_package.end_on
          end
        end

      end

      context "when an employee has coverage_terminated enrollment", :dbclean => :after_each do

        let(:hbx_enrollment_terminated_on) { end_on.prev_month }

        before do
          initial_application.update_attributes!(aasm_state: :termination_pending, effective_period: initial_application.start_on..end_on, terminated_on: TimeKeeper.date_of_record)
          hbx_enrollment.update_attributes!(effective_on: initial_application.start_on, aasm_state: "coverage_terminated", terminated_on: hbx_enrollment_terminated_on)
          benefit_package.termination_pending_member_benefits
          hbx_enrollment.reload
        end

        it "should NOT update terminated_on date on enrollment if terminated_on < benefit_application end_on" do
          expect(hbx_enrollment.terminated_on).to eq hbx_enrollment_terminated_on
        end
      end
    end
  end
end
