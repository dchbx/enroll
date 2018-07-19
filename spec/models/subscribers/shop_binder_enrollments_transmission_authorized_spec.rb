require "rails_helper"

describe Subscribers::ShopBinderEnrollmentsTransmissionAuthorized, "with an event subscription" do

  subject { Subscribers::ShopBinderEnrollmentsTransmissionAuthorized }

  it "listens for the correct event" do
    expect(subject.subscription_details).to eq(["acapi.info.events.employer.binder_enrollments_transmission_authorized"])
  end
end

describe Subscribers::ShopBinderEnrollmentsTransmissionAuthorized, "given no effective date" do
  subject { Subscribers::ShopBinderEnrollmentsTransmissionAuthorized.new }

  it "broadcasts an error message" do
    expect(subject).to receive(:notify).with("acapi.error.events.employer.binder_enrollments_transmission_authorized.invalid_effective_on_date",
                                               {
    :fein => nil,
    :employer_id => nil,
    :effective_on => nil,
    :return_status => "422"
    })
    subject.call(nil, nil, nil, nil, {})
  end
end

describe Subscribers::ShopBinderEnrollmentsTransmissionAuthorized, "given an employer hbx id" do
  let(:employer_id) { double }
  let(:effective_on) { double }
  let(:effective_date) { double }
  subject { Subscribers::ShopBinderEnrollmentsTransmissionAuthorized.new }

  before :each do
    allow(Date).to receive(:strptime).with(effective_on, "%Y-%m-%d").and_return(effective_date)
    allow(::BenefitSponsors::Organizations::Organization).to receive(:employer_by_hbx_id).with(employer_id).and_return(found_organizations)
  end

  describe "which doesn't exist" do
    let(:found_organizations) { [] }
    it "broadcasts an error message" do
      expect(subject).to receive(:notify).with("acapi.error.events.employer.binder_enrollments_transmission_authorized.employer_not_found",
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
    let(:enrollment_ids) { [enrollment_id] }
    let(:employer_fein) { double }
    let(:employer_org) { instance_double(Organization, :fein => employer_fein) }
    let(:found_organizations) { [employer_org] }
    let(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

    before(:each) do
      allow(Queries::NamedEnrollmentQueries).to receive(:shop_initial_enrollments).with(employer_org, effective_date).and_return(enrollment_ids)
    end

    it "transmits the new enrollments for the employer" do
      expect(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.coverage_selected", {
        :hbx_enrollment_id => enrollment_id,
        :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#initial",
        :reply_to => glue_event_queue_name
      })
      subject.call(nil, nil, nil, nil, { :employer_id => employer_id, :effective_on => effective_on})
    end
  end
end

describe Subscribers::ShopBinderEnrollmentsTransmissionAuthorized, "given an employer fein" do
  let(:effective_on) { double }
  let(:employer_fein) { double }
  let(:effective_date) { double }
  subject { Subscribers::ShopBinderEnrollmentsTransmissionAuthorized.new }

  before :each do
    allow(Date).to receive(:strptime).with(effective_on, "%Y-%m-%d").and_return(effective_date)
    allow(::BenefitSponsors::Organizations::Organization).to receive(:employer_by_fein).with(employer_fein).and_return(found_organizations)
  end

  describe "which doesn't exist" do
    let(:found_organizations) { [] }

    it "broadcasts an error message" do
      expect(subject).to receive(:notify).with("acapi.error.events.employer.binder_enrollments_transmission_authorized.employer_not_found",
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
    let(:employer_org) { instance_double(Organization, :fein => employer_fein) }
    let(:found_organizations) { [employer_org] }
    let(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

    before(:each) do
      allow(Queries::NamedEnrollmentQueries).to receive(:shop_initial_enrollments).with(employer_org, effective_date).and_return(enrollment_ids)
    end

    it "transmits the new enrollments for the employer" do
      expect(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.coverage_selected", {
        :hbx_enrollment_id => enrollment_id,
        :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#initial",
        :reply_to => glue_event_queue_name
      })
      subject.call(nil, nil, nil, nil, { :fein => employer_fein, :effective_on => effective_on})
    end
  end

end
