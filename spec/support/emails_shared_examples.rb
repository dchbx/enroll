RSpec.shared_examples "email attr examples" do |class_name|

  let(:array_email1) { {"0"=>{:kind=>"home", :address=>"test@dc.gov"}}}
  let(:class_email1) { Email.new(kind: "home", address: "test@dc.gov")}
end
