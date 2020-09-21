# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Components::Notifier::Builders::ConsumerRole', :dbclean => :after_each do

  describe "A new model instance" do
    let(:payload) do
      file = Rails.root.join("spec", "test_data", "notices", "proj_elig_report_aqhp_test_data.csv")
      csv = CSV.open(file, "r", :headers => true)
      data = csv.to_a

      {"consumer_role_id" => "5c61bf485f326d4e4f00000c",
       "event_object_kind" => "ConsumerRole",
       "event_object_id" => "5bcdec94eab5e76691000cec",
       "notice_params" => {"dependents" => data.select{ |m| m["dependent"].casecmp('YES').zero? }.map(&:to_hash),
                           "primary_member" => data.detect{ |m| m["dependent"].casecmp('NO').zero? }.to_hash}}
    end

    let!(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: "a16f4029916445fcab3dbc44bb7aadd0", first_name: "Test", last_name: "Data", middle_name: "M", name_sfx: "Jr") }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    subject do
      consumer = Notifier::Builders::ConsumerRole.new
      consumer.payload = payload
      consumer.consumer_role = person.consumer_role
      consumer
    end

    context "Model attributes" do

      context 'first name' do
        it 'should get first name from person object for projected uqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(true)
          expect(subject.first_name).to eq(person.first_name)
        end

        it 'should get first name from payload for projected aqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(false)
          expect(subject.first_name).to eq(payload["notice_params"]["primary_member"]["first_name"])
        end
      end

      context 'last name' do
        it 'should get last name from person object for projected uqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(true)
          expect(subject.last_name).to eq(person.last_name)
        end

        it 'should get last name from payload for projected aqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(false)
          expect(subject.last_name).to eq(payload["notice_params"]["primary_member"]["last_name"])
        end
      end

      it "should have full name from person object" do
        expect(subject.primary_fullname).to eq(person.full_name)
      end

      it "should have aptc from payload" do
        expect(subject.aptc).to eq(ActionController::Base.helpers.number_to_currency(payload["notice_params"]["primary_member"]["aptc"]))
      end

      it "should have incarcerated from payload" do
        expect(subject.incarcerated).to eq("No")
      end

      context 'age' do
        it 'should get age from person object for projected uqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(true)
          expect(subject.age).to eq(person.age_on(TimeKeeper.date_of_record))
        end

        it 'should get age from payload for projected aqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(false)
          expect(subject.age).to eq(subject.age_of_aqhp_person(TimeKeeper.date_of_record, Date.strptime(payload['notice_params']['primary_member']['dob'],"%m/%d/%Y")))
        end
      end

      context 'irs_consent' do
        it 'should return false for projected uqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(true)
          expect(subject.irs_consent).to eq(false)
        end

        it 'should get age from payload for projected aqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(false)
          expect(subject.irs_consent).to eq(payload['notice_params']['primary_member']['irs_consent'].casecmp('YES').zero?)
        end
      end
    end

    context "Model dependent attributes" do
      it "should have dependent filer type attributes" do
        expect(subject.dependents.first['filer_type']).to eq('Filers')
        expect(subject.dependents.last['filer_type']).to eq('Married Filing Separately')
        expect(subject.dependents.count).to eq(2)
      end

      it "should have dependent citizen_status attributes" do
        expect(subject.citizen_status("US")).to eq('US Citizen')
        expect(subject.dependents.count).to eq(2)
      end

      it "should have magi_medicaid_members_present" do
        expect(subject.magi_medicaid_members_present).to eq(false)
      end

      it "should have aqhp_or_non_magi_medicaid_members_present" do
        expect(subject.aqhp_or_non_magi_medicaid_members_present).to eq(true)
      end

      it "should have uqhp_or_non_magi_medicaid_members_present" do
        expect(subject.uqhp_or_non_magi_medicaid_members_present).to eq(false)
      end
    end

    context "Conditional attributes" do
      it "should be aqhp_eligible?" do
        expect(subject.aqhp_eligible?).to eq(true)
      end

      it "should be totally_ineligible?" do
        expect(subject.totally_ineligible?).to eq(false)
      end

      it "should be uqhp_eligible?" do
        expect(subject.uqhp_eligible?).to eq(false)
      end

      it "should have irs_consent?" do
        expect(subject.irs_consent?).to eq(false)
      end

      it "should have magi_medicaid?" do
        expect(subject.magi_medicaid?).to eq(false)
      end

      it "should have non_magi_medicaid?" do
        expect(subject.non_magi_medicaid?).to eq(false)
      end

      it "should have csr?" do
        expect(subject.csr?).to eq(true)
      end

      it "should have aptc_amount_available?" do
        expect(subject.aptc_amount_available?).to eq(true)
      end

      it "should have csr_is_73?" do
        expect(subject.csr_is_73?).to eq(true)
      end

      it "should have csr_is_100?" do
        expect(subject.csr_is_100?).to eq(false)
      end

      it "should return false if APTC amount is greater than 0" do
        expect(subject.aptc_is_zero?).to eq(false)
      end

      it "should return true if APTC amount is $0" do
        allow(subject).to receive(:aptc).and_return "$0"
        expect(subject.aptc_is_zero?).to eq(true)
      end

      context 'aqhp_event_and_irs_consent_no?' do
        it 'should always return false for projected uqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(true)
          expect(subject.aqhp_event_and_irs_consent_no?).to eq(false)
        end

        it 'should return  for projected uqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(false)
          expect(subject.aqhp_event_and_irs_consent_no?).to eq(false)
        end
      end
    end

    context "Model Open enrollment start and end date attributes" do
      it "should have open enrollment start date" do
        expect(subject.ivl_oe_start_date). to eq(Settings.aca
                                                .individual_market
                                                .upcoming_open_enrollment
                                                .start_on.strftime('%B %d, %Y'))
      end

      it "should have open enrollment end date" do
        expect(subject.ivl_oe_end_date). to eq(Settings.aca
                                              .individual_market
                                              .upcoming_open_enrollment
                                              .end_on.strftime('%B %d, %Y'))
      end
    end

    describe 'consumer_role and address' do
      let(:consumer) {subject.consumer_role.person}
      let(:address) {consumer.mailing_address}

      context "Model address attributes" do
        it "should have address " do
          expect(address.address_1.present?)
        end
      end
    end
  end

  describe "A uqhp_eligible in aqhp event" do
    let(:payload2) {
      file = Rails.root.join("spec", "test_data", "notices", "proj_elig_report_aqhp_test_data.csv")
      csv = CSV.open(file, "r", :headers => true)
      data = csv.to_a

      {
        "consumer_role_id" => "5c61bf485f326d4e4f0000c",
        "event_object_kind" =>  "ConsumerRole",
        "event_object_id" => "5bcdec94eab5e76691000cec",
        "notice_params" => {
          "primary_member" => data.select{ |m| m["dependent"].casecmp('NO').zero? && m["uqhp_eligible"].casecmp('YES').zero?}.first.to_hash
        }
      }
    }

    let!(:person2) { FactoryBot.create(:person, :with_consumer_role, hbx_id: "a16f4029916445fcab3dbc44bb7aadd1", first_name: "Test2", last_name: "Data2") }
    let!(:family2) { FactoryBot.create(:family, :with_primary_family_member, person: person2) }

    let(:subject2) {
      consumer = Notifier::Builders::ConsumerRole.new
      consumer.payload = payload2
      consumer.consumer_role = person2.consumer_role
      consumer
    }

    context "uqhp_eligible in aqhp_event" do
      it "should be uqhp_eligible in aqhp event" do
        allow(subject2).to receive(:uqhp_notice?).and_return(false)
        expect(subject2.uqhp_eligible).to eq(true)
      end
    end
  end
end
