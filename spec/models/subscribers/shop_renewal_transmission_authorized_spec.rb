require "rails_helper"

describe Subscribers::ShopRenewalTransmissionAuthorized, "with an event subscription" do

  subject { Subscribers::ShopRenewalTransmissionAuthorized }

  it "listens for the correct event" do
    expect(subject.subscription_details).to eq(["acapi.info.events.employer.renewal_transmission_authorized"])
  end
end

describe Subscribers::ShopRenewalTransmissionAuthorized, "given no effective date" do
  subject { Subscribers::ShopRenewalTransmissionAuthorized.new }

  it "broadcasts an error message" do
    expect(subject).to receive(:notify).with("acapi.error.events.employer.renewal_transmission_authorized.invalid_effective_on_date",
                                               {
    :fein => nil,
    :employer_id => nil,
    :effective_on => nil,
    :return_status => "422"
    })
    subject.call(nil, nil, nil, nil, {})
  end
end

describe Subscribers::ShopRenewalTransmissionAuthorized, "given an employer hbx id" do
  let(:employer_id) { double }
  let(:effective_on) { double }
  let(:effective_date) { double }
  subject { Subscribers::ShopRenewalTransmissionAuthorized.new }

  before :each do
    allow(Date).to receive(:strptime).with(effective_on, "%Y-%m-%d").and_return(effective_date)
    allow(BenefitSponsors::Organizations::Organization).to receive(:employer_by_hbx_id).with(employer_id).and_return(found_organizations)
  end

  describe "which doesn't exist" do
    let(:found_organizations) { [] }
    it "broadcasts an error message" do
      expect(subject).to receive(:notify).with("acapi.error.events.employer.renewal_transmission_authorized.employer_not_found",
                                               {
        :fein => nil,
        :effective_on => effective_on,
        :employer_id => employer_id,
        :return_status => "422"
      })
      subject.call(nil, nil, nil, nil, { :employer_id => employer_id, :effective_on => effective_on })
    end
  end

  describe "for an existing employer" do
    let(:enrollment_id) { double }
    let(:terminated_enrollment_id) { double }
    let(:enrollment_ids) { [enrollment_id] }
    let(:terminated_enrollment_ids) { [terminated_enrollment_id] }
    let(:employer_fein) { double }
    let(:employer_org) { instance_double(BenefitSponsors::Organizations::Organization, :fein => employer_fein) }
    let(:found_organizations) { [employer_org] }
    let(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

    before(:each) do
      allow(Queries::NamedPolicyQueries).to receive(:shop_monthly_terminations).with([employer_fein], effective_date).and_return(terminated_enrollment_ids)
      allow(Queries::NamedEnrollmentQueries).to receive(:renewal_gate_lifted_enrollments).with(employer_org, effective_date).and_return(enrollment_ids)
      allow(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {
        :hbx_enrollment_id => terminated_enrollment_id,
        :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
        :reply_to => glue_event_queue_name
      })
      allow(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.coverage_selected", {
        :hbx_enrollment_id => enrollment_id,
        :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#initial",
        :reply_to => glue_event_queue_name
      })
    end

    it "transmits the renewed enrollments for the employer" do
      expect(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.coverage_selected", {
        :hbx_enrollment_id => enrollment_id,
        :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#initial",
        :reply_to => glue_event_queue_name
      })
      subject.call(nil, nil, nil, nil, { :employer_id => employer_id, :effective_on => effective_on})
    end
=begin
# TODO: Fix once we have renewal terminations
    it "transmits the terminated enrollments for the employer" do
      expect(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {
        :hbx_enrollment_id => terminated_enrollment_id,
        :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
        :reply_to => glue_event_queue_name
      })
      subject.call(nil, nil, nil, nil, { :employer_id => employer_id, :effective_on => effective_on})
    end
=end
  end
end

describe Subscribers::ShopRenewalTransmissionAuthorized, "given an employer fein" do
  let(:effective_on) { double }
  let(:employer_fein) { double }
  let(:effective_date) { double }
  subject { Subscribers::ShopRenewalTransmissionAuthorized.new }

  before :each do
    allow(Date).to receive(:strptime).with(effective_on, "%Y-%m-%d").and_return(effective_date)
    allow(BenefitSponsors::Organizations::Organization).to receive(:employer_by_fein).with(employer_fein).and_return(found_organizations)
  end

  describe "which doesn't exist" do
    let(:found_organizations) { [] }

    it "broadcasts an error message" do
      expect(subject).to receive(:notify).with("acapi.error.events.employer.renewal_transmission_authorized.employer_not_found",
                                               {
        :effective_on => effective_on,
        :fein => employer_fein,
        :employer_id => nil,
        :return_status => "422"
      })
      subject.call(nil, nil, nil, nil, { :fein => employer_fein, :effective_on => effective_on})
    end
  end

  describe "for an existing employer" do
    let(:enrollment_id) { double }
    let(:enrollment_ids) { [enrollment_id] }
    let(:terminated_enrollment_id) { double }
    let(:terminated_enrollment_ids) { [terminated_enrollment_id] }
    let(:employer_org) { instance_double(BenefitSponsors::Organizations::Organization, :fein => employer_fein) }
    let(:found_organizations) { [employer_org] }
    let(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

    before(:each) do
      allow(Queries::NamedPolicyQueries).to receive(:shop_monthly_terminations).with([employer_fein], effective_date).and_return(terminated_enrollment_ids)
      allow(Queries::NamedEnrollmentQueries).to receive(:renewal_gate_lifted_enrollments).with(employer_org, effective_date).and_return(enrollment_ids)
      allow(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {
        :hbx_enrollment_id => terminated_enrollment_id,
        :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
        :reply_to => glue_event_queue_name
      })
      allow(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.coverage_selected", {
        :hbx_enrollment_id => enrollment_id,
        :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#initial",
        :reply_to => glue_event_queue_name
      })
    end

    it "transmits the new enrollments for the employer" do
      expect(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.coverage_selected", {
        :hbx_enrollment_id => enrollment_id,
        :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#initial",
        :reply_to => glue_event_queue_name
      })
      subject.call(nil, nil, nil, nil, { :fein => employer_fein, :effective_on => effective_on})
    end

=begin
# TODO: Fix once we do termination query
    it "transmits the terminated enrollments for the employer" do
      expect(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {
        :hbx_enrollment_id => terminated_enrollment_id,
        :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
        :reply_to => glue_event_queue_name
      })
      subject.call(nil, nil, nil, nil, { :fein => employer_fein, :effective_on => effective_on})
    end
=end
  end

end
