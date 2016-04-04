require "rails_helper"

describe ValueParsers::SsnParser do
  TEST_VALUES = {
    nil => nil,
    "" => nil,
    "000000000" => nil,
    "0123" => "000000123",
    123 => "000000123",
    123.546 => "000000123",
    "123.546" => "000000123",
    ".546" => nil,
    0.546 => nil,
    "\t 123.546" => "000000123",
    "\tD\s 123.546    " => "000000123",
    123000000.005 => "123000000",
    "12300  0000 \t.000" => "123000000"
  }
 
  TEST_VALUES.each_pair do |k, v| 
    it "parses a value of #{k.to_s} of type #{k.class.inspect} to the #{v.inspect}" do
      expect(ValueParsers::SsnParser.parse(k)).to eq v
    end
  end

end
