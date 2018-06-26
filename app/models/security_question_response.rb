require 'bcrypt'

class SecurityQuestionResponse
  include Mongoid::Document
  include Mongoid::Timestamps

  field :question_answer, type: String
  field :security_question_id, type: String

  embedded_in :user
  validates_presence_of :question_answer
  before_save :crypt_question_answer

  def matching_response? response_string
    BCrypt::Password.new(self.question_answer) == response_string
  end

  def original_question
    security_question.title
  end

  def success_token
    BCrypt::Password.create(question_answer + original_question)
  end

  private

  def security_question
    @security_question ||= SecurityQuestion.find(security_question_id)
  end

  def crypt_question_answer
    self.question_answer = BCrypt::Password.create(self.question_answer)
  end
end
