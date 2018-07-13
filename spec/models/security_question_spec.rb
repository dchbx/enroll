require 'rails_helper'

RSpec.describe SecurityQuestion, type: :model, dbclean: :after_each do
  subject { SecurityQuestion.new }

  it "has a valid factory" do
    expect(create(:security_question)).to be_valid
  end

  it { is_expected.to validate_presence_of :title }

  describe "::visible" do
    subject { SecurityQuestion }

    let!(:visible_question) { create(:security_question, title: "Visible") }
    let!(:hidden_question) { create(:security_question, title: "Hidden", visible: false) }

    it "should only include visible questions" do
      expect(subject.visible.to_a).to match_array([visible_question])
    end
  end

  describe ".safe_to_edit_or_delete?" do
    context "with a new question that has never been responded to" do
      let!(:security_question) { create(:security_question, title: 'Unanswered Question') }

      it "should be safe to delete or edit" do
        expect(security_question.safe_to_edit_or_delete?).to be_truthy
      end
    end

    context "with a question that has been responded to already" do
      let!(:security_question) { create(:security_question, title: 'Answered Question') }
      let!(:security_question_response) { build(:security_question_response, security_question_id: security_question.id) }
      let!(:user) { create(:user, with_security_questions: false, security_question_responses: [security_question_response]) }

      it "should not be safe to delete or edit" do
        expect(security_question.safe_to_edit_or_delete?).to be_falsey
      end
    end
  end

end
