require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "correct_curam_vlp_status")

describe CorrectCuramVlpStatus do
  let(:threshold_date) {
    Time.mktime(2016, 7, 5, 6, 0, 0)
  }

  let(:qualifying_ssa_response) {
    EventResponse.new({
      :received_at => threshold_date + 1.hour
    })
  }

  describe "given a task name" do
    let(:given_task_name) { "migrate_my_curam_vlp_status" }
    subject { CorrectCuramVlpStatus.new(given_task_name, double(:current_scope => nil)) }

    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "given a person who has a vlp authority of 'curam', in the 'pending' status" do
    subject { CorrectCuramVlpStatus.new("fix me task", double(:current_scope => nil)) }

    context "people with SSN, and NO qualifying ssa response" do
      let(:curam_user) { FactoryGirl.create(:person, :with_consumer_role)}
      before :each do
        curam_user.consumer_role.lawful_presence_determination.vlp_authority = "curam"
        curam_user.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
        curam_user.consumer_role.aasm_state = "verification_outstanding"
        curam_user.save!
        subject.migrate
        curam_user.reload
      end
      it "does not change the consumer state"do
        expect(curam_user.consumer_role.aasm_state).to eq "verification_outstanding"
      end

      it "does not change lpd status" do
        expect(curam_user.consumer_role.lawful_presence_determination.aasm_state).to eq "verification_pending"
      end

      it "does not change vlp authority" do
        expect(curam_user.consumer_role.lawful_presence_determination.vlp_authority).to eq "curam"
      end

    end

    context "people with SSN, and a qualifying ssa response" do
      let(:curam_user) { FactoryGirl.create(:person, :with_consumer_role)}
      before :each do
        curam_user.consumer_role.lawful_presence_determination.vlp_authority = "curam"
        curam_user.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
        curam_user.consumer_role.aasm_state = "verification_outstanding"
        curam_user.consumer_role.lawful_presence_determination.ssa_responses << qualifying_ssa_response
        curam_user.save!
        subject.migrate
        curam_user.reload
      end
      it "moves the person consumer_role to 'fully verified'" do
        expect(curam_user.consumer_role.aasm_state).to eq "fully_verified"
      end

      it "moves SSN to 'valid' state" do
        expect(curam_user.consumer_role.ssn_validation).to eq 'valid'
      end

      it "saves ssn_update_reason as 'user in curam'" do
        expect(curam_user.consumer_role.ssn_update_reason).to eq 'user in curam'
      end

      it "keeps vlp authority as curam" do
        expect(curam_user.consumer_role.lawful_presence_determination.vlp_authority).to eq "curam"
      end

      it "moves lpd state to 'verification_successful'" do
        expect(curam_user.consumer_role.lawful_presence_determination.aasm_state).to eq "verification_successful"
      end

      it "saves 'lawful_presence_update_reason' as Hash with update_reason and update_comment" do
        expect(curam_user.consumer_role.lawful_presence_update_reason[:update_reason]).to eq "user in curam"
        expect(curam_user.consumer_role.lawful_presence_update_reason[:update_comment]).to eq "fix data migration"
      end
    end

    context "people with NO SSN, and a qualifying ssa response" do
      let(:curam_user) {
        person = FactoryGirl.create(:person, :with_consumer_role)
        person.ssn = nil
        person.unset(:encrypted_ssn)
        person.save!
        person
      }

      before :each do
        curam_user.consumer_role.lawful_presence_determination.vlp_authority = "curam"
        curam_user.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
        curam_user.consumer_role.aasm_state = "verification_outstanding"
        curam_user.consumer_role.lawful_presence_determination.ssa_responses << qualifying_ssa_response
        curam_user.save!
        subject.migrate
        curam_user.reload
      end

      it "moves SSN to 'na' state" do
        expect(curam_user.consumer_role.ssn_validation).to eq 'na'
      end

      it "does not save ssn_update_reason" do
        expect(curam_user.consumer_role.ssn_update_reason).to eq nil
      end

      it "keeps vlp authority as curam" do
        expect(curam_user.consumer_role.lawful_presence_determination.vlp_authority).to eq "curam"
      end

      it "moves lpd state to 'verification_successful'" do
        expect(curam_user.consumer_role.lawful_presence_determination.aasm_state).to eq "verification_successful"
      end

      it "saves 'lawful_presence_update_reason' with update_reason and update_comment" do
        expect(curam_user.consumer_role.lawful_presence_update_reason[:update_reason]).to eq "user in curam"
        expect(curam_user.consumer_role.lawful_presence_update_reason[:update_comment]).to eq "fix data migration"
      end
    end
  end


  describe "given a person who has a vlp authority of 'ssa', in the 'pending' status" do
    subject { CorrectCuramVlpStatus.new("fix me task", double(:current_scope => nil)) }
    let(:user) { FactoryGirl.create(:person, :with_consumer_role)}

    before :each do
      user.consumer_role.lawful_presence_determination.vlp_authority = "ssa"
      user.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
      user.consumer_role.aasm_state = "verification_outstanding"
      user.save!
      subject.migrate
      user.reload
    end
    it "does not change the consumer state"do
      expect(user.consumer_role.aasm_state).to eq "verification_outstanding"
    end

    it "does not change lpd status" do
      expect(user.consumer_role.lawful_presence_determination.aasm_state).to eq "verification_pending"
    end

    it "does not change vlp authority" do
      expect(user.consumer_role.lawful_presence_determination.vlp_authority).to eq "ssa"
    end
  end
end
