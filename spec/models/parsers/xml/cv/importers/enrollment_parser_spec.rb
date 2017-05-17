require 'rails_helper'

describe Parsers::Xml::Cv::Importers::EnrollmentParser do
  let(:subject) { Parsers::Xml::Cv::Importers::EnrollmentParser.new(xml) }

  context "valid verified_policy" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "importer_payloads", "policy.xml")) }

    context "get_enrollment_object" do
      it 'should return the enrollment as an object' do
        expect(subject.get_enrollment_object.class).to eq HbxEnrollment
      end

      it "should be employer_sponsored" do
        expect(subject.get_enrollment_object.kind).to eq 'employer_sponsored'
      end

      it "should get plan" do
        plan = subject.get_enrollment_object.plan
        expect(plan.name).to eq "BluePreferred PPO $1,000 100%/80%"
        expect(plan.active_year).to eq 2016
        expect(plan.ehb).to eq 91.2
        expect(plan.metal_level).to eq 'gold'
        expect(plan.coverage_kind).to eq "health_and_dental"
      end

      it "should get base info of enrollment" do
        enrollment = subject.get_enrollment_object
        expect(enrollment.elected_aptc_pct).to eq 0
        expect(enrollment.applied_aptc_amount).to eq 0
        expect(enrollment.carrier_profile_id).to eq '116036'
        expect(enrollment.coverage_kind).to eq 'health_and_dental'
        expect(enrollment.household.class).to eq Household
        expect(enrollment.employee_role.class).to eq EmployeeRole
      end

      it "should get family_members" do
        household = subject.get_enrollment_object.household
        expect(household.family.family_members.class).to eq Array
        expect(household.family.family_members.first.person.class).to eq Person
        expect(household.family.family_members.first.person.hbx_id).to eq '19801010'
      end

      it "should get hbx_enrollment_members" do
        enrollment = subject.get_enrollment_object
        expect(enrollment.hbx_enrollment_members.class).to eq Array
        expect(enrollment.hbx_enrollment_members.first.class).to eq HbxEnrollmentMember
      end

      it "should get hbx_id by policy" do
        enrollment = subject.get_enrollment_object
        expect(enrollment.hbx_id).to eq '6011122'
      end

      it "should get fein and legal_name by employee_role" do
        employee_role = subject.get_enrollment_object.employee_role
        org = employee_role.employer_profile.organization
        expect(org.fein).to eq '555002222'
        expect(org.legal_name).to eq 'United States Senate'
      end

      it "should get effective_on and terminated_on by is_subscriber" do
        enrollment = subject.get_enrollment_object
        expect(enrollment.effective_on).to eq Date.new(2016,1,1)
        expect(enrollment.terminated_on).to eq Date.new(2016,12,31)
      end
    end

    context "get_broker_role_object" do
      it "should get broker_role" do
        broker_role = subject.get_broker_role_object
        expect(broker_role.class).to eq BrokerRole
      end

      it "should get broker_role info" do
        broker_role = subject.get_broker_role_object
        expect(broker_role.npn).to eq '1023'
        expect(broker_role.person.first_name).to eq 'Acme'
        expect(broker_role.person.last_name).to eq 'Broker'
      end
    end
  end

  context "valid individual policy" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "importer_payloads", "individual_policy.xml")) }

    it "should be individual" do
      expect(subject.get_enrollment_object.kind).to eq 'individual'
    end

    it "should get applied_aptc_amount" do
      enrollment = subject.get_enrollment_object
      expect(enrollment.applied_aptc_amount).to eq 194.65
    end
  end
end
