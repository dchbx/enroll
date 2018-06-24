require "rails_helper"

describe Subscribers::PolicyTerminationsSubscriber do
  let(:existing_enrollment) { instance_double(HbxEnrollment, :hbx_id => 1) }
  let(:enrollment_id) { "urn:some:id#123456" }
  let(:termination_event_name) { "acapi.info.events.policy.terminated" }
  let(:cancelation_event_name) { "acapi.info.events.policy.canceled" }

  before :each do
    allow(HbxEnrollment).to receive(:by_hbx_id).with("123456").and_return([existing_enrollment])
  end

  describe "given a termination event" do
    let(:termination_date) { Date.new(2017, 5, 30) }

    let(:termination_payload) do
      {
        :resource_instance_uri => "urn:some_thing:policy#policy_id",
        :event_effective_date => termination_date.strftime("%Y%m%d"),
        :hbx_enrollment_ids => JSON.dump([enrollment_id])
      }
    end

    before :each do
      allow(existing_enrollment).to receive(:may_terminate_for_non_payment?).and_return(true)
      allow(existing_enrollment).to receive(:may_terminate_coverage?).and_return(true)
    end

    it "terminates the enrollment" do
      expect(existing_enrollment).to receive(:terminate_coverage!).with(termination_date)
      subject.call(termination_event_name, nil, nil, nil, termination_payload)
    end
  end

  describe "given a termination event with qualify reason non_payment" do
    let(:termination_date) { Date.new(2017, 5, 30) }

    let(:termination_payload) do
      {
        :resource_instance_uri => "urn:some_thing:policy#policy_id",
        :event_effective_date => termination_date.strftime("%Y%m%d"),
        :hbx_enrollment_ids => JSON.dump([enrollment_id]),
        :qualifying_reason => "non_payment"
      }
    end

    before :each do
      allow(existing_enrollment).to receive(:may_terminate_coverage?).and_return(true)
      allow(existing_enrollment).to receive(:may_terminate_for_non_payment?).and_return(true)
    end

    it "terminates the enrollment" do
      expect(existing_enrollment).to receive(:terminate_for_non_payment!).with(termination_date)
      subject.call(termination_event_name, nil, nil, nil, termination_payload)
    end
  end

  describe "given a cancel event" do
    let(:termination_payload) do
      {
        :resource_instance_uri => "urn:some_thing:policy#policy_id",
        :hbx_enrollment_ids => JSON.dump([enrollment_id])
      }
    end

    before :each do
      allow(existing_enrollment).to receive(:may_cancel_coverage?).and_return(true)
      allow(existing_enrollment).to receive(:may_cancel_for_non_payment?).and_return(true)
    end

    it "cancels the enrollment" do
      expect(existing_enrollment).to receive(:cancel_coverage!)
      subject.call(cancelation_event_name, nil, nil, nil, termination_payload)
    end
  end

  describe "given a cancel event with qualify reason non_payment" do
    let(:termination_payload) do
      {
        :resource_instance_uri => "urn:some_thing:policy#policy_id",
        :hbx_enrollment_ids => JSON.dump([enrollment_id]),
        :qualifying_reason => "non_payment"
      }
    end

    before :each do
      allow(existing_enrollment).to receive(:may_cancel_coverage?).and_return(true)
      allow(existing_enrollment).to receive(:may_cancel_for_non_payment?).and_return(true)
    end

    it "cancels the enrollment" do
      expect(existing_enrollment).to receive(:cancel_for_non_payment!)
      subject.call(cancelation_event_name, nil, nil, nil, termination_payload)
    end
  end
end
