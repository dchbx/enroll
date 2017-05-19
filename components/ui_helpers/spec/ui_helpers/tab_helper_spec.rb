require_relative '../spec_helper'
# p subject.native.inner_html #=>to output html

describe UIHelpers::TabHelper do
  subject { render(view).with UIHelpers::TabHelper }

  context 'when using pills' do
    let(:view) do
      <<-VIEW
        <%= tab_content do |t| %>
          <%= t.tab :first, active: true do %>
            <h1>First</h1>
          <% end %>
          <%= t.tab :second do %>
            <h1>Second</h1>
          <% end %>
        <% end %>
      VIEW
    end

    it 'has an outer div with a tab-content class' do
      expect(subject).to have_css('div.tab-content')
    end

    it 'sets the active tab to the first tab' do
      expect(subject).to have_css('div.tab-pane.active:first-child')
    end
  end

  describe UIHelpers::TabHelper::TabBuilder do
    subject { UIHelpers::TabHelper::TabBuilder.new construct_template(UIHelpers::TabHelper) }

    describe '#tab' do
      context 'with a block' do
        let(:output) do
          subject.tab :sub_1 do
            'hey'
          end
        end

        it 'works!' do
          expect(output).to eql('<div id="sub_1" role="tabpanel" class="tab-pane ">hey</div>')
        end
      end
    end
  end
end
