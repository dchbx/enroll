require 'rails_helper'

RSpec.describe 'Notifier::Builders::ConsumerRole', :dbclean => :after_each do

  describe "A new model instance" do
    let(:payload) {
      file = Rails.root.join("spec", "test_data", "notices", "proj_elig_report_aqhp_2019_test_data.csv")
      csv = CSV.open(file, "r", :headers => true)
      data = csv.to_a

      {
        "consumer_role_id" => "5c61bf485f326d4e4f00000c",
        "event_object_kind" =>  "ConsumerRole",
        "event_object_id" => "5bcdec94eab5e76691000cec",
        "notice_params" => {
          "dependents" => data.select{ |m| m["dependent"].casecmp('YES').zero? }.map(&:to_hash),
          "primary_member" => data.detect{ |m| m["dependent"].casecmp('NO').zero? }.to_hash
        }
      }
    }

    let!(:person) { FactoryGirl.create(:person, :with_consumer_role, hbx_id: "a16f4029916445fcab3dbc44bb7aadd0", first_name: "Test", last_name: "Data") }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }

    subject do
      consumer = Notifier::Builders::ConsumerRole.new
      consumer.payload = payload
      consumer.consumer_role = person.consumer_role
      consumer
    end

    context "Model attributes" do
      it "should have first name from payload" do
        expect(subject.first_name).to eq(payload["notice_params"]["primary_member"]["first_name"])
      end

      it "should have last name from payload" do
        expect(subject.last_name).to eq(payload["notice_params"]["primary_member"]["last_name"])
      end

      it "should have aptc from payload" do
        expect(subject.aptc).to eq(payload["notice_params"]["primary_member"]["aptc"])
      end

      it "should have incarcerated from payload" do
        expect(subject.incarcerated).to eq("No")
      end
    end

    context "Model dependent attributes" do
      it "should have dependent filer type attributes" do
        expect(subject.dependents.first['filer_type']).to eq('Filers')
        expect(subject.dependents.count).to eq(2)
      end
      it "should have dependent citizen_status attributes" do
        expect(subject.citizen_status("US")).to eq('US Citizen')
        expect(subject.dependents.count).to eq(2)
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
end
