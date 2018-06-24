puts "*"*80
puts "::: Creating Security Questions:::"

created_count = 0

DEFAULT_QUESTIONS = [
  "Who is your favorite actor, musician, or artist?",
  "What is the name of your favorite pet?",
  "What was your first phone number?",
  "In what city were you born?",
  "What was the first street you lived on?",
  "What was the name of your favorite teacher?",
  "What high school did you attend?",
  "What is the name of your first school?",
  "What is your favorite movie?",
  "What street did you grow up on?",
  "What was the make of your first car?",
  "What was your high school mascot?",
  "What is your father’s middle name?",
]

DEFAULT_QUESTIONS.each do |question|
  security_question = SecurityQuestion.find_or_initialize_by(title: question)
  security_question.visible = true
  if security_question.save!
    created_count = created_count + 1
  end
end

puts "Created or updated #{created_count} security questions"
