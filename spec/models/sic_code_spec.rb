require 'rails_helper'

RSpec.describe SicCode, type: :model do
  subject { SicCode.new }

  it "has a valid factory" do 
    expect(create(:sic_code)).to be_valid
  end  

  it { is_expected.to validate_presence_of :division_code }
  it { is_expected.to validate_presence_of :division_label }
  it { is_expected.to validate_presence_of :major_group_code }
  it { is_expected.to validate_presence_of :major_group_label }
  it { is_expected.to validate_presence_of :industry_group_code }
  it { is_expected.to validate_presence_of :industry_group_label }
  it { is_expected.to validate_presence_of :sic_code }
  it { is_expected.to validate_presence_of :sic_label }

end  
