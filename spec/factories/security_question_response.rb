FactoryGirl.define do
  factory :security_question_response do
    question_answer 'answer'
    association :security_question
  end
end
