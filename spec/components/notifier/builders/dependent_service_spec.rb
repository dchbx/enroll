# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Components::Notifier::Builders::DependentService', :dbclean => :after_each do

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

    let!(:person) {
      FactoryBot.create(:person, :with_consumer_role, hbx_id: "3117597607a14ef085f9220f4d189356", first_name: "Samules", last_name: "Park")
    }

    let!(:family){ FactoryBot.create(:family, :with_primary_family_member, person: person) }

    let(:member) do
      payload['notice_params']['dependents'].select{ |m| m['member_id'] == person.hbx_id}.first
    end

    let(:member) {
      payload['notice_params']['dependents'].select{ |m|
        m['member_id'] == person.hbx_id
      }.first
    }

    let(:aqhp_dependent) {
      ::Notifier::Services::DependentService.new(false, member)
    }

    context "Model attributes" do
      it "should have first name from payload" do
        expect(aqhp_dependent.first_name).to eq(member["first_name"])
      end

      it "should have last name from payload" do
        expect(aqhp_dependent.last_name).to eq(member["last_name"])
      end

      it "should have member age from payload" do
        # 2019 matches the year in the file name
        member_dob = Date.strptime(member['dob'], '%m/%d/%Y')
        expect(aqhp_dependent.age).to eq(((TimeKeeper.date_of_record - member_dob) / 365.25).floor)
      end
    end
  end
end
