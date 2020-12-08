require 'rails_helper'

# Date.today converted to TimeKeeper.date_of_record

module BenefitSponsors
  RSpec.describe Subscribers::BenefitPackageRenewalGroupAssignmentSubscriber do

    let(:subscriber) do
      Subscribers::BenefitPackageRenewalGroupAssignmentSubscriber.new
    end
    let(:correlation_id) { "a correlation id" }
    let(:benefit_package_id) { "a benefit package id" }
    let(:census_employee_id) { "a census employee id" }
    let(:effective_on_date) { TimeKeeper.date_of_record }
    let(:effective_on_date_string) { effective_on_date.strftime("%Y-%m-%d") }
    let(:syntax_validator) { double }
    let(:domain_validator) { double }

    let(:validation_errors_hash) { double }
    let(:validation_errors) do
      double(
        :to_h => validation_errors_hash
      )
    end

    let(:headers) do
      {
        benefit_package_id: benefit_package_id,
        census_employee_id: census_employee_id,
        effective_on_date: effective_on_date_string
      }
    end

    let(:payload) do
      double(
        :headers => headers,
        :correlation_id => correlation_id
      )
    end

    let(:benefit_package) do
      instance_double(
       BenefitSponsors::BenefitPackages::BenefitPackage
      )
   end

   let(:census_employee) do
     instance_double(
       CensusEmployee
     )
   end

    before :each do
      allow(
        BenefitSponsors::BenefitPackages::RenewalGroupAssignments::ParameterValidator
      ).to receive(
        :new  
      ).and_return(syntax_validator)
      allow(syntax_validator).to receive(
        :call
      ).with(
        headers.stringify_keys
      ).and_return(syntax_validation_result)
    end

    describe "that does not pass syntax validation" do
      let(:syntax_validation_result) do
        double(
          :errors => validation_errors,
          :success? => false
        )
      end

      before :each do
        allow(subscriber).to receive(
          :notify
        ).with(
          "acapi.error.events.benefit_package.renew_employee_assignment.invalid_request",
          {
            :return_status => "422",
            :benefit_package_id => benefit_package_id.to_s,
            :census_employee_id => census_employee_id.to_s,
            :effective_on_date => effective_on_date_string,
            :body => JSON.dump(validation_errors_hash),
            :correlation_id => correlation_id
          }
        )
      end

      it "notifies of an invalid request" do
        expect(subscriber).to receive(
          :notify
        ).with(
          "acapi.error.events.benefit_package.renew_employee_assignment.invalid_request",
          {
            :return_status => "422",
            :benefit_package_id => benefit_package_id.to_s,
            :census_employee_id => census_employee_id.to_s,
            :effective_on_date => effective_on_date_string,
            :body => JSON.dump(validation_errors_hash),
            :correlation_id => correlation_id
          }
        )
        subscriber. work_with_params("", nil, payload)
      end

      it "acks" do
        result = subscriber. work_with_params("", nil, payload)
        expect(result).to eq :ack
      end
    end

    describe "that does not pass domain validation" do
      let(:syntax_validation_output) { double }
      let(:syntax_validation_result) do
        double(
          :success? => true,
          :output => syntax_validation_output
        )
      end
      let(:domain_validation_result) do
        double(
          :success? => false,
          :errors => validation_errors
        )
      end

      before :each do
        allow(
          BenefitSponsors::BenefitPackages::RenewalGroupAssignments::DomainValidator
        ).to receive(
          :new
        ).and_return(domain_validator)
        allow(domain_validator).to receive(
          :call
        ).with(
          syntax_validation_output
        ).and_return(domain_validation_result)
        allow(subscriber).to receive(
          :notify
        ).with(
          "acapi.error.events.benefit_package.renew_employee_assignment.invalid_request",
          {
            :return_status => "422",
            :benefit_package_id => benefit_package_id.to_s,
            :census_employee_id => census_employee_id.to_s,
            :effective_on_date => effective_on_date_string,
            :body => JSON.dump(validation_errors_hash),
            :correlation_id => correlation_id
          }
        )
      end

      it "notifies of an invalid request" do
        expect(subscriber).to receive(
          :notify
        ).with(
          "acapi.error.events.benefit_package.renew_employee_assignment.invalid_request",
          {
            :return_status => "422",
            :benefit_package_id => benefit_package_id.to_s,
            :census_employee_id => census_employee_id.to_s,
            :effective_on_date => effective_on_date_string,
            :body => JSON.dump(validation_errors_hash),
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

    describe "that passes all validations" do
      let(:syntax_validation_output) do
        {
          :benefit_package_id => benefit_package_id,
          :census_employee_id => census_employee_id,
          :effective_on_date => effective_on_date
        }
      end
      let(:syntax_validation_result) do
        double(
          :success? => true,
          :output => syntax_validation_output
        )
      end
      let(:domain_validation_result) do
        double(
          :success? => true
        )
      end

      before :each do
        allow(
          BenefitSponsors::BenefitPackages::RenewalGroupAssignments::DomainValidator
        ).to receive(
          :new  
        ).and_return(domain_validator)
        allow(domain_validator).to receive(
          :call
        ).with(
          syntax_validation_output
        ).and_return(domain_validation_result)
        allow(subscriber).to receive(
          :notify
        ).with(
          "acapi.info.events.benefit_package.renew_employee_assignment.renewal_executed",
          {
            :return_status => "200",
            :benefit_package_id => benefit_package_id.to_s,
            :census_employee_id => census_employee_id.to_s,
            :effective_on_date => effective_on_date_string,
            :correlation_id => correlation_id
          }
        )
        allow(benefit_package).to receive(
          :renew_employee_assignment
        ).with(census_employee, effective_on_date)
        allow(
          BenefitSponsors::BenefitPackages::BenefitPackage
        ).to receive(
          :find
        ).with(benefit_package_id).and_return(benefit_package)
        allow(
          CensusEmployee
        ).to receive(
          :find
        ).with(census_employee_id).and_return(census_employee)
      end

      it "notifies of successful request" do
        expect(subscriber).to receive(
          :notify
        ).with(
          "acapi.info.events.benefit_package.renew_employee_assignment.renewal_executed",
          {
            :return_status => "200",
            :benefit_package_id => benefit_package_id.to_s,
            :census_employee_id => census_employee_id.to_s,
            :effective_on_date => effective_on_date_string,
            :correlation_id => correlation_id
          }
        )
        subscriber.work_with_params("", nil, payload)
      end

      it "executed the renewal" do
        allow(benefit_package).to receive(
          :renew_employee_assignment
        ).with(census_employee, effective_on_date)
        subscriber.work_with_params("", nil, payload)
      end

      it "acks" do
        result = subscriber.work_with_params("", nil, payload)
        expect(result).to eq :ack
      end
    end

    describe "that has an exception while renewing the census employee" do
      let(:syntax_validation_output) do
        {
          :benefit_package_id => benefit_package_id,
          :census_employee_id => census_employee_id,
          :effective_on_date => effective_on_date
        }
      end
      let(:syntax_validation_result) do
        double(
          :success? => true,
          :output => syntax_validation_output
        )
      end
      let(:domain_validation_result) do
        double(
          :success? => true
        )
      end
      let(:error) do
        Exception.new(

        )
      end

      before :each do
        allow(error).to receive(:backtrace).and_return([])
        allow(
          BenefitSponsors::BenefitPackages::RenewalGroupAssignments::DomainValidator
        ).to receive(
          :new  
        ).and_return(domain_validator)
        allow(domain_validator).to receive(
          :call
        ).with(
          syntax_validation_output
        ).and_return(domain_validation_result)
        allow(subscriber).to receive(
          :notify
        ).with(
          "acapi.error.events.benefit_package.renew_employee_assignment.exception",
          {
            :return_status => "500",
            :benefit_package_id => benefit_package_id.to_s,
            :census_employee_id => census_employee_id.to_s,
            :effective_on_date => effective_on_date_string,
            :body => JSON.dump({
              error: error.inspect,
              message: error.message,
              backtrace: []
            }),
            :correlation_id => correlation_id
          }
        )
        allow(
          BenefitSponsors::BenefitPackages::BenefitPackage
        ).to receive(
          :find
        ).with(benefit_package_id).and_return(benefit_package)
        allow(
          CensusEmployee
        ).to receive(
          :find
        ).with(census_employee_id).and_return(census_employee)
        allow(benefit_package).to receive(
          :renew_employee_assignment
        ).with(census_employee, effective_on_date).and_raise(error)
      end

      it "notifies of an exception" do
        expect(subscriber).to receive(
          :notify
        ).with(
          "acapi.error.events.benefit_package.renew_employee_assignment.exception",
          {
            :return_status => "500",
            :benefit_package_id => benefit_package_id.to_s,
            :census_employee_id => census_employee_id.to_s,
            :effective_on_date => effective_on_date_string,
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
end