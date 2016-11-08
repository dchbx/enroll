require 'rails_helper'

describe Phone, type: :model do

  context "area_code" do
    it "invalid with blank" do
      expect(Phone.create(area_code: "").errors[:area_code].any?).to eq true
    end

    it "invalid with improper characters" do
      expect(Phone.create(area_code: "a7d8d9d8h").errors[:area_code].any?).to eq true
    end

    it "invalid when length <> 3" do
      expect(Phone.create(area_code: "20").errors[:area_code].any?).to eq true
      expect(Phone.create(area_code: "2020").errors[:area_code].any?).to eq true
    end

    it "valid with correct numeric-only value" do
      expect(Phone.create(area_code: "202").errors[:area_code].any?).to eq false
    end

    it "valid with strips non-numeric characters" do
      expect(Phone.create(area_code: "(202)").errors[:area_code].any?).to eq false
    end
  end

  context "number" do
    it "invalid when length <> 7" do
      expect(Phone.create(number: "20").errors[:number].any?).to eq true
      expect(Phone.create(number: "202578987420").errors[:number].any?).to eq true
    end

    it "invalid with blank" do
      expect(Phone.create(number: "").errors[:number].any?).to eq true
    end

    it "invalid with improper characters" do
      expect(Phone.create(number: "a7d8d9d8h").errors[:number].any?).to eq true
    end

    it "strips non-numeric characters in valid number" do
      expect(Phone.create(number: "741-9874").errors[:number].any?).to eq false
    end
  end

  context "set_full_phone_number" do
    let(:params) {{kind: "home", number: "111-3333", area_code: "123", person: person}}
    let(:phone) {Phone.create(**params)}

    it "should return full phone number" do
      expect(phone.set_full_phone_number).to eq "(123) 111-3333"
    end

    it "return full phone number with extension when extension present" do
      phone.extension = "876"
      expect(phone.set_full_phone_number).to eq "(123) 111-3333 x 876"
    end
  end

  context "kind" do
    it "invalid with null value" do
      expect(Phone.create(kind: "").errors[:kind].any?).to eq true
    end

    it "invalid with improper value" do
      expect(Phone.create(kind: "banana").errors[:kind].any?).to eq true
    end

    it "valid with proper value" do
      expect(Phone.create(kind: "work").errors[:kind].any?).to eq false
    end
  end

  let(:person) {FactoryGirl.create(:person)}
  let(:params) {{kind: "home", full_phone_number: "(222)-111-3333", person: person}}

  it "strips valid area code and number from full phone number" do
    phone = Phone.new(**params)
    expect(phone.area_code).to eq "222"
    expect(phone.number).to eq "1113333"
    expect(phone.to_s).to eq "(222) 111-3333"
    phone.extension = "876"
    expect(phone.to_s).to eq "(222) 111-3333 x 876"
    expect(phone.save).to eq true
  end

  context "phone components" do
    let(:person) {FactoryGirl.create(:person)}
    let(:params) {{kind: "home", full_phone_number: "(222)-111-3333", person: person}}
    let(:phone) {Phone.create(**params)}

    it "when the length of phone number is 11" do
      phone.full_phone_number = "+1-222-333-0123"
      phone.save
      expect(phone.country_code).to eq "1"
      expect(phone.area_code).to eq "222"
      expect(phone.number).to eq "3330123"
    end

    it "when the length of phone number is 10" do
      phone.full_phone_number = "111-333-0123"
      phone.save
      expect(phone.area_code).to eq "111"
      expect(phone.number).to eq "3330123"
    end
  end

  context "to_s" do
    let(:params) {{kind: "home", full_phone_number: "(222)-111-3333", person: person}}
    let(:phone) {Phone.create(**params)}

    it "when extension present" do
      phone.extension = "876" 
      expect(phone.to_s).to eq "(222) 111-3333 x 876"
    end

    it "when extension doesn't present" do
      expect(phone.to_s).to eq "(222) 111-3333" 
    end 
  end
end
