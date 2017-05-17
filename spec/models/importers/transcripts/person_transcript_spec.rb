require 'rails_helper'

RSpec.describe Importers::Transcripts::PersonTranscript, type: :model do

  let(:person_template)             { Person.new.attributes.except("_id", "version") }
  let(:consumer_role_template)      { person_template.buiild.attributes.except("_id", "version") }
  let(:family_transcript_template)  { }

  describe "instance methods" do

    let!(:source_record) {
      Person.create({ 
        "hbx_id"=>"117966",
        "first_name"=>"Bruce",
        "last_name"=>"Jackson",
        # "dob"=> Date.new(1975, 8, 1),
        "gender"=>"male",
        "middle_name"=>"",
        "ssn"=>"671126612",
        "no_dc_address"=>false,
        "addresses"=>[{
          "kind"=>"home",
          "address_1"=>"3312 H St NW",
          "city"=>"Washington",
          "state"=>"DC",
          "zip"=>"20002"
        },
          {
            "kind"=>"work",
            "address_1"=>"609 L St NW",
            "city"=>"Washington",
            "state"=>"DC",
            "zip"=>"20002",
            "created_at" => TimeKeeper.date_of_record - 10.days,
            "updated_at" => TimeKeeper.date_of_record -  5.days
        }],
        "phones"=>[{
          "area_code"=>"202",
          "kind"=>"mobile",
          "full_phone_number"=>"2029867777",
          "number"=>"9867777",
        }],
        "emails"=>[{
          "kind"=>"home", "address"=>"bruce@gmail.com"
        }]
      })
    }

    let(:other_record) {
      Person.new({"hbx_id"=>"117966",
        "first_name"=>"Bruce",
        "last_name"=>"Jackson",
        "dob"=> Date.new(1975, 6, 1),
        "gender"=>"male",
        "middle_name"=>"",
        "ssn"=>"671126610",
        "no_dc_address"=>false,
        "addresses"=>[{
          "kind"=>"home",
          "address_1"=>"3312 Gosnell Rd",
          "city"=>"Vienna",
          "state"=>"VA",
          "zip"=>"22180"
          }],
        "phones"=>[{
          "area_code"=>"202",
          "kind"=>"home",
          "full_phone_number"=>"2029866677",
          "number"=>"9866677"
          }],
        "emails"=>[{
          "kind"=>"home", "address"=>"bruce@gmail.com"
        }]
      })
    }

    context "#execute" do

      it 'should return differences' do 
        builder = Transcripts::PersonTranscript.new
        builder.find_or_build(other_record)
        person_transcript = builder.transcript

        expect(source_record.dob).to be_nil
        expect(source_record.ssn).to eq "671126612"
        expect(source_record.home_phone).to be_nil
        expect(source_record.home_address.address_1).to eq "3312 H St NW"

        person_importer = Importers::Transcripts::PersonTranscript.new
        person_importer.transcript = person_transcript
        person_importer.process

        source_record.reload

        expect(source_record.dob).to eq Date.new(1975, 6, 1)
        expect(source_record.ssn).to eq "671126610"
        expect(source_record.home_phone).to be_present
        expect(source_record.home_address.address_1).to eq "3312 gosnell rd"
      end
    end
  end
end
