RSpec.shared_examples "addresses attr examples" do |class_name|

  let(:class_address1){ Address.new(kind: 'home', address_1: "1 street ct", address_2: "apt test2", city: "was", state: "DC", zip: "22211")}
  let(:class_address2){ Address.new(kind: 'home', address_1: "1111 spalding ct", address_2: "apt 444", city: "was", state: "DC", zip: "22211")}
  let(:array_address1) { {"0"=>{"kind"=>"home", "address_1"=>"1 street ct", "address_2"=>"apt test2", "city"=>"was", "state"=>"DC", "zip"=>"22211"}}}
end
