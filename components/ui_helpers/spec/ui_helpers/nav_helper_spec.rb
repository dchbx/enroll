require_relative '../spec_helper'
# p subject.native.inner_html #=>to output html

describe UIHelpers::NavHelper do
  subject { render(view).with UIHelpers::NavHelper }

  context 'when using pills' do
    let(:view) do
      <<-VIEW
        <%= nav type: 'pills' do |n| %>
          <%= n.pill :first, 'First', active: true %>
          <%= n.pill :second, 'Second' %>
        <% end %>
      VIEW
    end

    it 'has an outer ul with a nav-pills class' do
      expect(subject).to have_css('ul.nav-pills')
    end

    it 'sets the active pill to the first li' do
      expect(subject).to have_css('li.active:first-child')
    end
  end

  context 'when using tabs' do
    let(:view) do
      <<-VIEW
        <%= nav type: :tabs do |n| %>
          <%= n.tab 'First', active: true %>
          <%= n.tab 'Second' %>
        <% end %>
      VIEW
    end

    it 'has an outer ul with a nav-tabs class' do
      expect(subject).to have_css('ul.nav-tabs')
    end

    it 'sets the active tab to the first li' do
      expect(subject).to have_css('li.active:first-child')
    end
  end

  describe UIHelpers::NavHelper::NavBuilder do
    subject { UIHelpers::NavHelper::NavBuilder.new construct_template(UIHelpers::NavHelper) }

    describe '#pill' do
      context 'with both ref and title' do
        it 'works!' do
          expect(subject.pill(:sub_1, 'Sub 1')).to eql('<li role="presentation" class=""><a aria-controls="sub_1" role="pill" data-toggle="pill" href="#sub_1">Sub 1</a></li>')
        end
      end

      context 'with just one string' do
        it 'works!' do
          expect(subject.pill('sub 1')).to eql('<li role="presentation" class=""><a aria-controls="sub_1" role="pill" data-toggle="pill" href="#sub_1">sub 1</a></li>')
        end
      end

      context 'with a block' do
        let(:output) do
          subject.pill :sub_1 do
            'hey'
          end
        end

        it 'works!' do
          expect(output).to eql('<li role="presentation" class=""><a aria-controls="sub_1" role="pill" data-toggle="pill" href="#sub_1">hey</a></li>')
        end
      end
    end

    describe '#tab' do
      context 'with a title' do
        it 'works!' do
          expect(subject.tab('Topic 1')).to eql('<li role="presentation" class=""><a href="#">Topic 1</a></li>')
        end
      end

      context 'with a block' do
        let(:output) do
          subject.tab do
            'Topic 1'
          end
        end

        it 'works!' do
          expect(output).to eql('<li role="presentation" class=""><a href="#">Topic 1</a></li>')
        end
      end
    end
  end
end
