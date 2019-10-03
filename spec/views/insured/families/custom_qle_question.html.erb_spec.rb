require 'rails_helper'

describe "insured/families/_custom_qle_question_panel.html.erb" do
  let(:qle_kind) {FactoryBot.create(:qualifying_life_event_kind)}

  context "Page Content" do
    context "event kind label presence" do
      before :each do
        assign :qle, qle_kind
      end

      it "shows the date label if present" do
        label = "Date that feds order that coverage starts"
        allow(qle_kind).to receive(:event_label).and_return(label)
        render file: "insured/families/custom_qle_question.html.erb"
        expect(rendered).to include(label)
      end

      it 'shows Date of Event: if not present' do
        render file: "insured/families/custom_qle_question.html.erb"
        expect(rendered).to include("Date of Event:" )
      end
    end
  end
end
