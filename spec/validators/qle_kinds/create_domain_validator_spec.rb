require "rails_helper"

describe QleKinds::CreateDomainValidator do
  let(:user) { instance_double(User) }
  let(:post_event_sep_eligibility) {Date.new(2016,3,3)}
  let(:request) { instance_double(Admin::QleKinds::CreateRequest, title: request_title, reason: "good reason",post_event_sep_eligibility:post_event_sep_eligibility) }
  let(:service) { instance_double(Admin::QleKinds::CreateService) }
  let(:request_title) { "A REQUEST TITLE" }
  let(:post_event_sep_eligibility) {Date.new(2016,3,3)}

  subject { QleKinds::CreateDomainValidator.new }

  describe "given valid objects" do
    before :each do
      allow(service).to receive(:title_is_unique?).with(request_title).and_return(true)
      allow(service).to receive(:reason_is_valid?).and_return(true)
      allow(service).to receive(:post_sep_eligiblity_date_is_valid?).and_return(true)
    end

    it "is valid" do
      expect(subject.call(user: user, request: request, service: service).success?).to be_truthy
    end
  end

  describe "given a qle create request with a duplicate title" do

    before :each do
      allow(service).to receive(:title_is_unique?).with(request_title).and_return(false)
      allow(service).to receive(:reason_is_valid?).and_return(false)
      allow(service).to receive(:post_sep_eligiblity_date_is_valid?).and_return(false)
    end

    it "is invalid" do
      validation_result = subject.call(user: user, request: request, service: service)
      expect(validation_result.errors.to_h).to have_key(:duplicate_title)
      expect(validation_result.errors.to_h).to have_key(:reason_is_invalid)
    end
  end

  describe "given a qle create request with a pre event sep eleigibliy after the post event sep eilgibility " do

    before :each do
      allow(service).to receive(:title_is_unique?).with(request_title).and_return(false)
      allow(service).to receive(:post_sep_eligiblity_date_is_valid?).and_return(false)
      allow(service).to receive(:reason_is_valid?).and_return(true)    
    end

    it "is invalid" do
      validation_result = subject.call(user: user, request: request, service: service)
      expect(validation_result.errors.to_h).to have_key(:duplicate_title)
    end
  end

  describe "given a qle create request with a pre event sep eleigibliy after the post event sep eilgibility " do

    before :each do
      allow(service).to receive(:title_is_unique?).with(request_title).and_return(false)
      allow(service).to receive(:reason_is_valid?).and_return(true)

      allow(service).to receive(:post_sep_eligiblity_date_is_valid?).and_return(false)
    end

    it "is invalid" do
      validation_result = subject.call(user: user, request: request, service: service)
      expect(validation_result.errors.to_h).to have_key(:duplicate_title)
    end
  end

  describe "given a qle create request with a pre event sep eleigibliy after the post event sep eilgibility " do

    before :each do
      allow(service).to receive(:title_is_unique?).with(request_title).and_return(false)
      allow(service).to receive(:reason_is_valid?).and_return(true)
      allow(service).to receive(:post_sep_eligiblity_date_is_valid?).with(post_event_sep_eligibility).and_return(false)
    end

    it "is invalid" do
      validation_result = subject.call(user: user, request: request, service: service)
      expect(validation_result.errors.to_h).to have_key(:duplicate_title)
    end
  end
end
