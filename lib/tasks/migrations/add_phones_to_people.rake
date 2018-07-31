# This rake task used to update phone records on person. check ticket #19754
# RAILS_ENV=production bundle exec rake migrations:add_phones_to_people

namespace "migrations" do
  desc "Adding phone records to people"

  task :add_phones_to_people => :environment do

    phones.each do |k, hash_val|
      begin
        people = Person.where(hbx_id: hash_val["hbx_id"])
        if people.size != 1
          puts "Found more than 1 or No person record"
          next
        end
        person = people.first

        person.phones << Phone.new(hash_val["phone"])
        person.save!
      rescue Exception => e
        puts "Exception #{hash_val["hbx_id"]} : #{e}"
      end
    end
  end
end

def phones
  {
    "record_1" => {
      "hbx_id" => "19772536",
      "phone" => {
        "country_code" => "",
        "area_code" => "801",
        "number" => "4288410",
        "extension" => nil,
        "full_phone_number" => "8014288410",
        "kind" => "phone main"
      }
    },

    "record_2" => {
      "hbx_id" => "19884077",
      "phone" => {
        "country_code" => "",
        "area_code" => "202",
        "number" => "3879162",
        "extension" => nil,
        "full_phone_number" => "2023879162",
        "kind" => "phone main"
      }
    },

    "record_3" => {
      "hbx_id" => "19930287",
      "phone" => {
        "country_code" => "",
        "area_code" => "323",
        "number" => "2847705",
        "extension" => nil,
        "full_phone_number" => "3232847705",
        "kind" => "phone main"
      }
    },

    "record_4" => {
      "hbx_id" => "19936572",
      "phone" => {
        "country_code" => "",
        "area_code" => "877",
        "number" => "2666850",
        "extension" => nil,
        "full_phone_number" => "8772666850",
        "kind" => "phone main"
      }
    },

    "record_5" => {
      "hbx_id" => "19962781",
      "phone" => {
        "country_code" => "",
        "area_code" => "603",
        "number" => "6224600",
        "extension" => nil,
        "full_phone_number" => "6036224600",
        "kind" => "phone main"
      }
    },

    "record_6" => {
      "hbx_id" => "19963213",
      "phone" => {
        "country_code" => "",
        "area_code" => "301",
        "number" => "2146718",
        "extension" => nil,
        "full_phone_number" => "3012146718",
        "kind" => "phone main"
      }
    }
  }
end
