# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe BenefitSponsors::Subscribers::ReinstateEmployeeEnrollmentSubscriber, :dbclean => :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context 'setup initial benefit application'

  let(:subscriber) do
    BenefitSponsors::Subscribers::ReinstateEmployeeEnrollmentSubscriber.new
  end
  let!(:effective_period_start_on) { TimeKeeper.date_of_record.beginning_of_year }
  let!(:effective_period_end_on)   { TimeKeeper.date_of_record.end_of_year }
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
  let(:correlation_id) { "a correlation id" }
  let(:person) { FactoryBot.create(:person, :with_employee_role, :with_family) }
  let(:family) { person.primary_family }
  let!(:census_employee) do
    ce = FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package)
    ce.update_attributes!(employee_role_id: person.employee_roles.first.id)
    person.employee_roles.first.update_attributes(census_employee_id: ce.id)
    ce
  end
  let!(:benefit_group_assignment) {census_employee.benefit_group_assignments.last}
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
    cloned_application.notify_application(true)
    @cloned_package = cloned_application.benefit_packages[0]
    benefit_group_assignment.reload
    @cloned_package.reinstate_benefit_group_assignment(benefit_group_assignment)
    census_employee.reload
    enrollment.reload
  end

  describe "that passes all validations" do
    before do
      allow(subscriber).to receive(:notify).with(
        "acapi.info.events.benefit_package.reinstate_employee_enrollment.reinstate_executed",
        {
          :return_status => "200",
          :benefit_package_id => @cloned_package.id,
          :hbx_enrollment_id => enrollment.id,
          :notify => @cloned_package.benefit_application.is_application_trading_partner_publishable?,
          :correlation_id => correlation_id
        }
      )
    end
    let(:headers) do
      {
        :benefit_package_id => @cloned_package.id,
        :hbx_enrollment_id => enrollment.id,
        :notify => @cloned_package.benefit_application.is_application_trading_partner_publishable?
      }
    end
    let(:payload) do
      double(
        :headers => headers,
        :correlation_id => correlation_id
      )
    end

    it "executed the reinstate" do
      expect(subscriber).to receive(
        :notify
      ).with(
        "acapi.info.events.benefit_package.reinstate_employee_enrollment.reinstate_executed",
        {
          :return_status => "200",
          :benefit_package_id => @cloned_package.id,
          :hbx_enrollment_id => enrollment.id,
          :notify => @cloned_package.benefit_application.is_application_trading_partner_publishable?,
          :correlation_id => correlation_id
        }
      )
      subscriber.work_with_params("", nil, payload)
    end

    it "acks" do
      result = subscriber.work_with_params("", nil, payload)
      expect(result).to eq :ack
    end
  end

  describe "that does not pass syntax validation" do
    let(:headers) do
      {
        :benefit_package_id => "",
        :hbx_enrollment_id => enrollment.id,
        :notify => @cloned_package.benefit_application.is_application_trading_partner_publishable?
      }
    end
    let(:payload) do
      double(
        :headers => headers,
        :correlation_id => correlation_id
      )
    end

    let(:validation_error) do
      double(
        :success? => false,
        :errors => {:benefit_package_id => ["must be provided"]}
      )
    end

    before :each do
      allow(subscriber).to receive(:run_validations).with(headers.stringify_keys).and_return(validation_error)
      allow(subscriber).to receive(
        :notify
      ).with(
        "acapi.error.events.benefit_package.reinstate_employee_enrollment.invalid_request",
        {
          :return_status => "422",
          :benefit_package_id => "",
          :hbx_enrollment_id => enrollment.id,
          :notify => @cloned_package.benefit_application.is_application_trading_partner_publishable?,
          :body => JSON.dump({:benefit_package_id => ["must be provided"]}),
          :correlation_id => correlation_id
        }
      )
    end

    it "notifies of an invalid request" do
      expect(subscriber).to receive(
        :notify
      ).with(
        "acapi.error.events.benefit_package.reinstate_employee_enrollment.invalid_request",
        {
          :return_status => "422",
          :benefit_package_id => "",
          :hbx_enrollment_id => enrollment.id,
          :notify => @cloned_package.benefit_application.is_application_trading_partner_publishable?,
          :body => JSON.dump({:benefit_package_id => ["must be provided"]}),
          :correlation_id => correlation_id
        }
      )
      subscriber.work_with_params("", nil, payload)
    end

    it "acks" do
      result = subscriber.work_with_params("", nil, payload)
      expect(result).to eq :ack
    end
  end

  describe "that does not pass domain validation" do
    let(:benefit_package_id) {BSON::ObjectId.new}
    let(:headers) do
      {
        :benefit_package_id => benefit_package_id,
        :hbx_enrollment_id => enrollment.id,
        :notify => @cloned_package.benefit_application.is_application_trading_partner_publishable?
      }
    end
    let(:payload) do
      double(
        :headers => headers,
        :correlation_id => correlation_id
      )
    end

    before :each do
      allow(subscriber).to receive(
        :notify
      ).with(
        "acapi.error.events.benefit_package.reinstate_employee_enrollment.invalid_request",
        {
          :return_status => "422",
          :benefit_package_id => benefit_package_id,
          :hbx_enrollment_id => enrollment.id,
          :notify => @cloned_package.benefit_application.is_application_trading_partner_publishable?,
          :body => JSON.dump({:benefit_package_id => ["was not found"]}),
          :correlation_id => correlation_id
        }
      )
    end

    it "notifies of an invalid request" do
      expect(subscriber).to receive(
        :notify
      ).with(
        "acapi.error.events.benefit_package.reinstate_employee_enrollment.invalid_request",
        {
          :return_status => "422",
          :benefit_package_id => benefit_package_id,
          :hbx_enrollment_id => enrollment.id,
          :notify => @cloned_package.benefit_application.is_application_trading_partner_publishable?,
          :body => JSON.dump({:benefit_package_id => ["was not found"]}),
          :correlation_id => correlation_id
        }
      )
      subscriber.work_with_params("", nil, payload)
    end

    it "acks" do
      result = subscriber.work_with_params("", nil, payload)
      expect(result).to eq :ack
    end
  end

  describe "that has an exception while reinstating the assignment" do
    before :each do
      allow(error).to receive(:backtrace).and_return([])
      allow_any_instance_of(BenefitSponsors::BenefitPackages::BenefitPackage).to receive(:reinstate_enrollment).with(enrollment, notify: true).and_raise(error)
      allow(subscriber).to receive(:notify).with(
        "acapi.error.events.benefit_package.reinstate_employee_enrollment.exception",
        {
          :return_status => "500",
          :benefit_package_id => @cloned_package.id,
          :hbx_enrollment_id => enrollment.id,
          :notify => @cloned_package.benefit_application.is_application_trading_partner_publishable?,
          :body => JSON.dump({
                               error: error.inspect,
                               message: error.message,
                               backtrace: []
                             }),
          :correlation_id => correlation_id
        }
      )

    end

    let(:headers) do
      {
        :benefit_package_id => @cloned_package.id,
        :hbx_enrollment_id => enrollment.id,
        :notify => @cloned_package.benefit_application.is_application_trading_partner_publishable?
      }
    end
    let(:payload) do
      double(
        :headers => headers,
        :correlation_id => correlation_id
      )
    end

    let(:error) do
      StandardError.new


    end

    it "notifies of an exception" do
      expect(subscriber).to receive(
        :notify
      ).with(
        "acapi.error.events.benefit_package.reinstate_employee_enrollment.exception",
        {
          :return_status => "500",
          :benefit_package_id => @cloned_package.id,
          :hbx_enrollment_id => enrollment.id,
          :notify => @cloned_package.benefit_application.is_application_trading_partner_publishable?,
          :body => JSON.dump({
                               error: error.inspect,
                               message: error.message,
                               backtrace: []
                             }),
          :correlation_id => correlation_id
        }
      )
      subscriber.work_with_params("", nil, payload)
    end

    it "rejects" do
      result = subscriber.work_with_params("", nil, payload)
      expect(result).to eq :reject
    end
  end
end