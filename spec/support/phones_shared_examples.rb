RSpec.shared_examples "phone numbers" do |class_name|

  let!(:array_phone1) {{"0"=>{:kind=>"home", :full_phone_number=> "(202) 555-9999"},
                                  "1"=>{:kind=>"mobile", :full_phone_number=> ""},
                                  "2"=>{:kind=>"work", :full_phone_number=>""},
                                  "3"=>{:kind=>"fax", :full_phone_number=>""}}}

  let!(:array_phone2) {{"0"=>{:kind=>"home", :full_phone_number=>"20211111133"}}}

  let!(:array_phone3) {{"0"=>{"kind"=>"home", "full_phone_number"=> "(202) 555-9999"},
                        "1"=>{"kind"=>"mobile", "full_phone_number"=> ""},
                        "2"=>{"kind"=>"work", "full_phone_number"=>""},
                        "3"=>{"kind"=>"fax", "full_phone_number"=>""}}}

  let!(:array_phone4) {{"0"=>{"kind"=>"home", "full_phone_number"=>"20211111133"}}}

  let!(:class_phone2) {Phone.new(kind: "home", area_code: "123", number: "456-7890", full_phone_number:"(123) 456-7890") }
  let!(:class_phone1) {Phone.new(kind: "home", area_code: "202", number: "555-9999", full_phone_number:"(202) 555-9999") }
end
