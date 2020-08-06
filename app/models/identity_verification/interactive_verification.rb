# frozen_string_literal: true

module IdentityVerification
  class InteractiveVerification
    class Response
      extend ActiveModel::Naming
      include ActiveModel::Model
      attr_accessor :response_text, :response_id
    end

    class Question
      extend ActiveModel::Naming
      include ActiveModel::Model
      include ActiveModel::Validations
      attr_accessor :question_id, :question_text
      attr_accessor :response_id

      attr_writer :responses

      validates_presence_of :response_id, :message => "You must select a response."

      def answer
        @responses.detect { |r| r.response_id == response_id }
      end

      def unanswered?
        @response_id.blank?
      end

      def responses
        @responses ||= []
      end

      def responses_attributes=(vals)
        @responses = []
        vals.each_pair do |_k, v|
          @responses << ::IdentityVerification::InteractiveVerification::Response.new(v)
        end
      end
    end

    extend ActiveModel::Naming
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :questions, :session_id, :transaction_id

    validate :questions_have_responses

    def questions_have_responses
      errors.add(:base, "You must answer all questions") if questions.any?(&:unanswered?)
    end

    def questions
      @questions ||= []
    end

    def questions_attributes=(vals)
      @questions = []
      vals.each_pair do |_k, v|
        @questions << ::IdentityVerification::InteractiveVerification::Question.new(v)
      end
    end
  end
end
