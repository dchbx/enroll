# FactoryGirl.define do
#   factory :person do
#     first_name 'John'
#     sequence(:last_name) {|n| "Smith#{n}" }
#     dob "1972-04-04".to_date
#     is_incarcerated false
#     is_active true
#     gender "male"
#
#     after(:create) do |p, evaluator|
#       # create_list(:address, 2, person: p)
#       # create_list(:phone, 2, person: p)
#       # create_list(:email, 2, person: p)
#       #create_list(:employee_role, 1, person: p)
#     end
#
#     trait :with_mailing_address do
#       addresses { [FactoryGirl.build(:address, :mailing_kind)]}
#     end
#
#     trait :with_ssn do
#       sequence(:ssn) { |n| 222222220 + n }
#     end
#
#     trait :with_work_email do
#       emails { [FactoryGirl.build(:email, kind: "work") ] }
#     end
#
#     trait :with_work_phone do
#       phones { [FactoryGirl.build(:phone, kind: "work") ] }
#     end
#
#     trait :without_first_name do
#       first_name ' '
#     end
#
#     trait :without_last_name do
#       last_name ' '
#     end
#
#     trait :male do
#       gender "male"
#     end
#
#     trait :female do
#       gender "female"
#     end
#
#     trait :with_employer_staff_role do
#       after(:create) do |p, evaluator|
#         create_list(:employer_staff_role, 1, person: p)
#       end
#     end
#
#     trait :with_general_agency_staff_role do
#       after(:create) do |p, evaluator|
#         create_list(:general_agency_staff_role, 1, person: p)
#       end
#     end
#
#     trait :with_hbx_staff_role do
#       after(:create) do |p, evaluator|
#         create_list(:hbx_staff_role, 1, person: p)
#       end
#     end
#
#     trait :with_broker_role do
#       after(:create) do |p, evaluator|
#         create_list(:broker_role, 1, person: p)
#       end
#     end
#
#     trait :with_assister_role do
#       after(:create) do |p, evaluator|
#         create_list(:assister_role, 1, person: p)
#       end
#     end
#
#     trait :with_csr_role do
#       after(:create) do |p, evaluator|
#         create_list(:csr_role, 1, person: p)
#       end
#     end
#   end
# end
