require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_conversion_flag")

describe UpdateConversionFlag, :dbclean => :after_each do

  let(:given_task_name) { "update_conversion_flag" }
  subject { UpdateConversionFlag.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating conversion flag of employer" do
    let!(:employer_profile) { FactoryGirl.create(:employer_profile)}

    it "should update profile source to self_serve and should approve employer attestation" do
      ENV["fein"] = employer_profile.fein
      ENV["profile_source"] = "self_serve"
      subject.migrate
      employer_profile.reload
      expect(employer_profile.profile_source).to eq "self_serve"
      expect(employer_profile.employer_attestation.aasm_state).to eq "approved"
    end

    it "should update profile source to conversion and approve employer attestation" do
      ENV["fein"] = employer_profile.fein
      ENV["profile_source"] = "conversion"
      subject.migrate
      employer_profile.reload
      expect(employer_profile.profile_source).to eq "conversion"
      expect(employer_profile.employer_attestation.aasm_state).to eq "approved"
    end
  end

  describe "employer with denied employer attestation" do
    let!(:employer_profile) { FactoryGirl.create(:employer_profile)}
    let!(:employer_attestation) { FactoryGirl.create(:employer_attestation,aasm_state:'denied',employer_profile:employer_profile) }
    let(:document) { FactoryGirl.create(:employer_attestation_document, aasm_state: 'rejected', employer_attestation: employer_attestation) }
    let(:attestation) { document.employer_attestation }

    it "should approve employer attestation" do
      ENV["fein"] = employer_profile.fein
      ENV["profile_source"] = "self_serve"
      expect(attestation.aasm_state).to eq "denied"
      subject.migrate
      employer_profile.reload
      expect(employer_profile.profile_source).to eq "self_serve"
      expect(employer_profile.employer_attestation.aasm_state).to eq "approved"
    end
  end

  describe "employer with rejected employer attestation document" do
    let!(:employer_profile) { FactoryGirl.create(:employer_profile)}
    let!(:employer_attestation) { FactoryGirl.create(:employer_attestation,aasm_state:'denied',employer_profile:employer_profile) }
    let(:document) { FactoryGirl.create(:employer_attestation_document) }
    let(:attestation) { document.employer_attestation }

    it "should accept the employer attested document" do
      ENV["fein"] = employer_profile.fein
      expect(employer_attestation.aasm_state).to eq "denied"
      subject.migrate
      employer_profile.reload
      expect(document.aasm_state).to eq "submitted"
    end
  end


end
