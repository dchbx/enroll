# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkNoticeReflex, type: :reflex do
  describe "#new_identifier" do
    let(:reflex) do
      build_reflex url: new_exchanges_bulk_notice_path,
                   params: {
                     admin_bulk_notice: {
                       audience_ids: audience_ids,
                       audience_type: audience_type
                     }
                   }
    end

    before do
      allow(reflex).to receive(:session).and_return(session)
      allow(reflex).to receive(:morph).and_call_original
      reflex.element.value = identifiers
    end

    context 'of one id' do
      let(:audience_ids) { nil }
      let(:audience_type) { 'employer' }
      let(:identifiers) { '1234' }
      let(:session) { {} }

      context 'with a match' do
        before do
          allow(BenefitSponsors::Organizations::Organization)
            .to receive(:where)
            .with(any_args)
            .and_return(double(first: double(id: '1',
                                             legal_name: 'ACME Inc',
                                             fein: '123456789',
                                             hbx_id: '1234',
                                             profile_types: ['employer'])))

          reflex.run(:new_identifier)
        end

        it 'will render a org badge for ACME Inc' do
          expect(reflex).to have_received(:morph) do |selector, raw|
            html = Capybara::Node::Simple.new(raw)
            expect(html).to have_css('span.badge-secondary', text: 'ACME Inc')
          end
        end
      end

      context 'without a match' do
        before { reflex.run(:new_identifier) }

        it 'will render an error org badge' do
          expect(reflex).to have_received(:morph) do |selector, raw|
            html = Capybara::Node::Simple.new(raw)
            expect(html).to have_css('span.badge-danger', text: '1234')
          end
        end
      end
    end
  end
end