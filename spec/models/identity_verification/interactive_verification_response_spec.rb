require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
describe IdentityVerification::InteractiveVerificationResponse do
  let(:response_data) { File.read(file_path) }
  subject {
    IdentityVerification::InteractiveVerificationResponse.parse(response_data, :single => true)
  }

  describe "given a successful response" do
    let(:file_path) { File.join(Rails.root, "spec", "test_data", "ridp_payloads", "successful_question_response.xml") }
    let(:expected_response_text) { "You knew the right answers."}
    let(:expected_transaction_id) { "WhateverRefNumberHere" }

    it "should be considered successful" do
      expect(subject.successful?).to eq true
    end

    it "should not be considered failed" do
      expect(subject.failed?).to eq false
    end

    it "should have the correct response text" do
      expect(subject.response_text).to eq expected_response_text
    end

    it "should have the correct transaction_id" do
      expect(subject.transaction_id).to eq expected_transaction_id
    end

    it "should not continue the session" do
      expect(subject.continue_session?).to eq false
    end
  end

  describe "given a failed response" do
    let(:file_path) { File.join(Rails.root, "spec", "test_data", "ridp_payloads", "failed_start_response.xml") }
    let(:expected_response_text) { "Failed response - please see ref below."}
    let(:expected_transaction_id) { "WhateverRefNumberHere" }

    it "should be considered failed" do
      expect(subject.failed?).to eq true
    end

    it "should have the correct response text" do
      expect(subject.response_text).to eq expected_response_text
    end

    it "should have the correct transaction_id" do
      expect(subject.transaction_id).to eq expected_transaction_id
    end

    it "should not continue the session" do
      expect(subject.continue_session?).to eq false
    end
  end

  describe "given a response which asks for responses to questions" do
    let(:file_path) { File.join(Rails.root, "spec", "test_data", "ridp_payloads", "successful_start_response.xml") }
    let(:expected_transaction_id) { "transaction id for reference" }
    let(:expected_session_id) { "session id for reference" }

    it "should not be considered failed" do
      expect(subject.failed?).to eq false
    end

    it "should have the correct session_id" do
      expect(subject.session_id).to eq expected_session_id
    end

    it "should have the correct transaction_id" do
      expect(subject.transaction_id).to eq expected_transaction_id
    end

    it "should continue the session" do
      expect(subject.continue_session?).to eq true
    end

    it "should have 2 questions" do
      expect(subject.questions.length).to eq 2
    end

    describe "with question 1" do
      let(:expected_question_id) { "First Question" }
      let(:expected_question_text) { "If you had to answer a question" }
      let(:question) { subject.questions.first }

      it "should have the correct question id" do
        expect(question.question_id).to eq expected_question_id
      end

      it "should have the correct question text" do
        expect(question.question_text).to eq expected_question_text
      end

      describe "with responses" do
        it "should have 2 response options" do
          expect(question.response_options.length).to eq 2
        end

        describe "with response option 1" do
          let(:expected_response_id) { "A" }
          let(:expected_response_text) { "pick answer A" }
          let(:response_option) { question.response_options.first }

          it "should have the correct response_id" do
            expect(response_option.response_id).to eq expected_response_id
          end

          it "should have the correct response_text" do
            expect(response_option.response_text).to eq expected_response_text
          end
        end

        describe "with response option 2" do
          let(:expected_response_id) { "B" }
          let(:expected_response_text) { "pick answer B" }
          let(:response_option) { question.response_options.last }

          it "should have the correct response_id" do
            expect(response_option.response_id).to eq expected_response_id
          end

          it "should have the correct response_text" do
            expect(response_option.response_text).to eq expected_response_text
          end
        end
      end

      describe "with question 2" do
        let(:expected_question_id) { "Second Question" }
        let(:expected_question_text) { "If somehow there was another question" }
        let(:question) { subject.questions.last }

        it "should have the correct question id" do
          expect(question.question_id).to eq expected_question_id
        end

        it "should have the correct question text" do
          expect(question.question_text).to eq expected_question_text
        end

        describe "with responses" do
          it "should have 2 response options" do
            expect(question.response_options.length).to eq 2
          end

          describe "with response option 1" do
            let(:expected_response_id) { "C" }
            let(:expected_response_text) { "pick answer C" }
            let(:response_option) { question.response_options.first }

            it "should have the correct response_id" do
              expect(response_option.response_id).to eq expected_response_id
            end

            it "should have the correct response_text" do
              expect(response_option.response_text).to eq expected_response_text
            end
          end

          describe "with response option 2" do
            let(:expected_response_id) { "D" }
            let(:expected_response_text) { "pick answer D" }
            let(:response_option) { question.response_options.last }

            it "should have the correct response_id" do
              expect(response_option.response_id).to eq expected_response_id
            end

            it "should have the correct response_text" do
              expect(response_option.response_text).to eq expected_response_text
            end
          end
        end
      end

      describe "which can be converted to a form model" do
        let(:model) { subject.to_model  }

        it "should have 2 questions" do
          expect(model.questions.length).to eq 2
        end

        describe "the first question" do
          let(:expected_question_id) { "First Question" }
          let(:expected_question_text) { "If you had to answer a question" }
          let(:question) { model.questions.first }

          it "should have the correct question id" do
            expect(question.question_id).to eq expected_question_id
          end

          it "should have the correct question text" do
            expect(question.question_text).to eq expected_question_text
          end

          describe "with responses" do
            it "should have 2 response options" do
              expect(question.responses.length).to eq 2
            end

            describe "with response option 1" do
              let(:expected_response_id) { "A" }
              let(:expected_response_text) { "pick answer A" }
              let(:response_option) { question.responses.first }

              it "should have the correct response_id" do
                expect(response_option.response_id).to eq expected_response_id
              end

              it "should have the correct response_text" do
                expect(response_option.response_text).to eq expected_response_text
              end
            end

          end
        end
      end
    end
  end
end
end
