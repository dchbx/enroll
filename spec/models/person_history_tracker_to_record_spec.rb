require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe "Person with history tracks and a list of addresses", :dbclean => :after_each do
  let(:person) do
    Person.create!({
      first_name: "Example",
      last_name: "Person",
      addresses: [
        Address.new({
          kind: "home",
          address_1: "1234 Some Street",
          city: "Washington",
          state: "DC",
          zip: "20000"
        }),
        Address.new({
          kind: "work",
          address_1: "1234 Some Other Street",
          city: "Washington",
          state: "DC",
          zip: "20000"
        })
      ]
    })
  end

  describe "when we add a mailing and delete work" do
    before :each do
      person
      sleep(1.5)
      mailing_address = Address.new({
          kind: "mailing",
          address_1: "1234 Some Third Street",
          city: "Washington",
          state: "DC",
          zip: "20000"
        })
      person.addresses.detect do |address|
        address.kind == "work"
      end.destroy
      person.save
      person.addresses << mailing_address
      person.reload
    end

    it "has a mailing address, but no work address" do
      expect(person.addresses.map(&:kind)).to include("mailing")
      expect(person.addresses.map(&:kind)).not_to include("work")
    end

    it "reverts to the original state" do
      reverted_person = person.history_tracker_to_record(person.created_at)
      expect(reverted_person.addresses.map(&:kind)).not_to include("mailing")
      expect(reverted_person.addresses.map(&:kind)).to include("work")
    end
  end

end


describe "Person with history tracks and a consumer role", :dbclean => :after_each do

  let(:non_curam_ivl_person) do
    FactoryBot.create(:person, :with_family, gender: 'male', first_name: "Tom", last_name: "Cruise")
  end
  let!(:consumer_role) do
    ConsumerRole.create!(
      person: non_curam_ivl_person,
      is_state_resident: true,
      citizen_status: 'us_citizen',
      vlp_documents: [FactoryBot.build(:vlp_document)],
      ridp_documents: [FactoryBot.build(:ridp_document)],
      is_applicant: true
    )
  end

  describe "history_track_to_person" do
    describe "creating records" do
      before do
      end
    end

    describe "destroying records" do
      context "embeds many addresses" do
        let(:address_1) { FactoryBot.create(:address, person: non_curam_ivl_person) }
        let(:address_2) { FactoryBot.create(:address, person: non_curam_ivl_person) }
        let(:address_3) { FactoryBot.create(:address, person: non_curam_ivl_person) }
        before do
          address_1
          address_2
          non_curam_ivl_person.addresses.first.destroy
          address_3
        end

        it "undoes the destroyed records" do
        end
      end
    end

    describe "editing records" do
      context "embeds_one consumer role" do
        before do
          non_curam_ivl_person
          sleep(1.5)
          non_curam_ivl_person.consumer_role.update_attributes!(is_state_resident: false, citizen_status: 'undocumented_immigrant')
          sleep(1.5)
          non_curam_ivl_person.consumer_role.update_attributes!(is_state_resident: true, citizen_status: 'us_citizen')
        end

        it "undoes changes to a person when a HistoryTrack instance passed as arguement" do
          target_history_track =  non_curam_ivl_person.history_tracks.where(modified: {"is_state_resident" => false}).last
          past_person = non_curam_ivl_person.history_tracker_to_record(target_history_track.created_at)
          expect(past_person.consumer_role.is_state_resident).to eq(false)
          target_history_track =  non_curam_ivl_person.history_tracks.where(modified: {"is_state_resident" => true}).last
          past_person = non_curam_ivl_person.history_tracker_to_record(target_history_track.created_at)
          expect(past_person.consumer_role.is_state_resident).to eq(true)
        end
      end

      context "embeds_many address updated" do
        before do
          non_curam_ivl_person
          sleep(1.5)
          non_curam_ivl_person.update_attributes!(addresses_attributes: { "0" => { id: non_curam_ivl_person.addresses.first.id, address_1: '1600 PA Ave' } })
          sleep(1.5)
          non_curam_ivl_person.update_attributes!(addresses_attributes: { "0" => { id: non_curam_ivl_person.addresses.first.id, address_1: '111 1 St NE' } })
          sleep(1.5)
          non_curam_ivl_person.update_attributes!(addresses_attributes: { "0" => { id: non_curam_ivl_person.addresses.first.id, address_1: '1150 Connecticut Ave' } })
        end

        it "successfully returns the addresses" do
          expect(non_curam_ivl_person.addresses.first.address_1).to eq('1150 Connecticut Ave')
          target_history_track =  non_curam_ivl_person.history_tracks.where(modified: {"address_1"=>'1600 PA Ave'}).last
          past_person = non_curam_ivl_person.history_tracker_to_record(target_history_track.created_at)
          expect(past_person.addresses.first.address_1).to eq('1600 PA Ave')
        end
      end

      context "embeds_many address missing creation" do
        let(:address_1) { FactoryBot.create(:address, person: non_curam_ivl_person) }
        let(:address_2) { FactoryBot.create(:address, person: non_curam_ivl_person) }
        let(:address_3) { FactoryBot.create(:address, person: non_curam_ivl_person) }

        # update address
        let(:history_track_1) do
          HistoryTracker.new version: 1,
            created_at: 1.days.ago,
            action: 'update',
            association_chain: [{ "name" => "Person", "id" => non_curam_ivl_person.id }, { "name" => "addresses", "id" => address_1.id }],
            modified: address_1.attributes.slice(:address_1, :address_2),
            original: { "address_1": "Yo St" }
        end
        before do
          address_1
          address_2
          non_curam_ivl_person.addresses.first.destroy
          address_3
          non_curam_ivl_person.addresses.find(address_1.id).destroy
          allow(non_curam_ivl_person).to receive(:created_at).and_return(10.days.ago)
          allow(non_curam_ivl_person).to receive(:history_tracks).and_return([history_track_1])
        end

        it "can restore to last updated address" do
          puts address_1.address_1.inspect
          puts address_2.address_2.inspect
          puts address_3.address_3.inspect
          puts non_curam_ivl_person.addresses.map(&:address_1).inspect
          past_person = non_curam_ivl_person.history_tracker_to_record(2.days.ago)
          puts past_person.addresses.map(&:address_1).inspect
          expect(past_person.addresses.first.address_1).to eql(address_1.address_1)
        end
      end

      context "just person record itself" do
        before do
          non_curam_ivl_person
          non_curam_ivl_person.update_attributes!(gender: 'female')
          sleep 1.5
          non_curam_ivl_person.update_attributes!(gender: 'male')
          sleep 1.5
          non_curam_ivl_person.update_attributes!(dob: Date.today - 22.years)
          sleep 1.5
          non_curam_ivl_person.update_attributes!(gender: 'female')
        end

        it "undoes changes to a person when a HistoryTrack instance passed as arguement" do
          history_tracks = non_curam_ivl_person.history_tracks.to_a.sort_by(&:created_at).reverse
          expect(non_curam_ivl_person.history_tracker_to_record(history_tracks[1].created_at).gender).to eq('male')
          expect(non_curam_ivl_person.history_tracker_to_record(history_tracks.third.created_at).dob).to_not eq(Date.today - 22.years)
          expect(non_curam_ivl_person.history_tracker_to_record(history_tracks.second.created_at).gender).to eq('male')
        end
      end
    end
  end
end
