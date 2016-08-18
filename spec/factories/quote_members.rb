FactoryGirl.define do
  factory :quote_member do
		first_name "John"
		middle_name "M"
		last_name "Taylor"
		gender "male"
		dob 30.years.ago
  end

end
