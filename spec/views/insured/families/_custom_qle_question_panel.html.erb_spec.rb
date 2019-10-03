require 'rails_helper'

describe "insured/families/_custom_qle_question_panel.html.erb" do
  let(:qle_kind) { FactoryBot.create(:qualifying_life_event_kind) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
  let(:qle_question) do
    double(
      'CustomQleQuestion',
      qle_kind: qle_kind,
      _id: 1,
      content: "What is your name?",
      custom_qle_responses: [custom_qle_response]
    )
  end
  let(:custom_qle_response) do
    double('CustomQleResponse', content: "I dunno.")
  end

  context "Page Content" do
    before :each do
      assign :family, family
      assign :qle_kind, qle_kind
      assign :qle_question, qle_question
    end

    context "event kind label presence" do
      it "shows the date label if present" do
        label = "Date that feds order that coverage starts"
        allow(qle_kind).to receive(:event_kind_label).and_return(label)
        render partial: "insured/families/custom_qle_question_panel.html.erb"
        expect(rendered).to include(label)
      end

      it 'shows Date of Event: if not present' do
        allow(qle_kind).to receive(:event_kind_label).and_return(nil)
        render partial: "insured/families/custom_qle_question_panel.html.erb"
        expect(rendered).to include("Date of Event:" )
      end
    end

    context "second qle question" do
      let(:second_qle_question_message) do
        "Based on your response to the first question, " \
        "we need to ask you another question to clarify your eligibility."
      end
      it "shows custom qle question if custom qle params present" do
        allow(qle_kind).to receive(:event_kind_label).and_return(nil)
        render(
          partial: "insured/families/custom_qle_question_panel.html.erb",
          locals: { params: { only_display_question_two: true } }
        )
        expect(rendered).to include(second_qle_question_message)
      end

      it "does not show second qle message if second qle question present" do
        allow(qle_kind).to receive(:event_kind_label).and_return(nil)
        render(
          partial: "insured/families/custom_qle_question_panel.html.erb",
          locals: { params: { only_display_question_two: nil } }
        )
        expect(rendered).not_to include(second_qle_question_message)
      end
    end
  end
end
