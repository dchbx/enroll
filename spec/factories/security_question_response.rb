FactoryGirl.define do
  factory :security_question_response do
    question_answer 'answer'
    security_question_id { create(:security_question).id }
  end
end
