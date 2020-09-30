# frozen_string_literal: true

require 'rails_helper'
<<<<<<< HEAD
require File.join(Rails.root, "components/benefit_sponsors/spec/support/benefit_sponsors_site_spec_helpers.rb")
=======
>>>>>>> e9f7af3894... Work in Progress.

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

<<<<<<< HEAD
    context 'of multiple ids' do
      let(:audience_ids) { nil }
      let(:audience_type) { 'employer' }
      let(:identifiers) { "1234\n1235\n1236" }
      let(:session) { {} }

      context 'all matches' do
        before do
          allow(BenefitSponsors::Organizations::Organization)
            .to receive(:where)
            .with(fein: "1234")
            .and_return(double(first: double(id: '1',
                                             legal_name: 'ACME Inc',
                                             fein: '123456789',
                                             hbx_id: '1234',
                                             profile_types: ['employer'])))
          allow(BenefitSponsors::Organizations::Organization)
            .to receive(:where)
            .with(fein: "1235")
            .and_return(double(first: double(id: '2',
                                             legal_name: 'Widget Co',
                                             fein: '123456788',
                                             hbx_id: '1235',
                                             profile_types: ['employer'])))
          allow(BenefitSponsors::Organizations::Organization)
            .to receive(:where)
            .with(fein: "1236")
            .and_return(double(first: double(id: '3',
                                             legal_name: 'Lux Corp',
                                             fein: '123456787',
                                             hbx_id: '1236',
                                             profile_types: ['employer'])))

          reflex.run(:new_identifier)
        end

        it 'will render a org badge for every match' do
          expect(reflex).to have_received(:morph) do |_selector, raw|
            html = Capybara::Node::Simple.new(raw)
            expect(html).to have_css('span.badge-alt-blue', count: 3)
          end
        end
      end
    end

    context 'of audience ids and identifiers' do
      let(:site) { ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market }
      let(:organization_one)         do
        profile = FactoryBot.create :benefit_sponsors_organizations_aca_shop_dc_employer_profile
        profile.organization
      end

      let(:organization_two)         do
        profile = FactoryBot.create :benefit_sponsors_organizations_aca_shop_dc_employer_profile
        profile.organization
      end

      let(:organization_three)         do
        profile = FactoryBot.create :benefit_sponsors_organizations_aca_shop_dc_employer_profile
        profile.organization
      end

      let(:audience_ids) { [organization_three.id.to_s] }
      let(:audience_type) { 'employer' }
      let(:identifiers) { "#{organization_one.fein}\n#{organization_two.fein}" }
      let(:session) { {} }

      context 'all matches' do
        before do
          reflex.run(:new_identifier)
        end

        it 'will render a org badge for every match' do
          expect(reflex).to have_received(:morph) do |_selector, raw|
            html = Capybara::Node::Simple.new(raw)
            expect(html).to have_css('span.badge-alt-blue', count: 3)
          end
        end
      end
    end

=======
>>>>>>> e9f7af3894... Work in Progress.
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
          expect(reflex).to have_received(:morph) do |_selector, raw|
            html = Capybara::Node::Simple.new(raw)
            expect(html).to have_css('span.badge-alt-blue', text: '1234')
          end
        end
      end

      context 'without a match' do
        before { reflex.run(:new_identifier) }

        it 'will render an error org badge' do
          expect(reflex).to have_received(:morph) do |_selector, raw|
            html = Capybara::Node::Simple.new(raw)
            expect(html).to have_css('span.badge-danger', text: '1234')
          end
        end
      end
    end
  end

  describe "#audience_select" do
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
      reflex.element.value = audience_type
    end

    context 'of selecting employee with general agency ids present' do
      let(:audience_ids) { ['1234', '1235'] }
      let(:audience_type) { 'employee' }
      let(:session) do
        {
          bulk_notice: {
            audience: { '1234' => { id: '1', fein: '1', hbx_id: '1234', types: ['general_agency'] },
                        '1235' => { id: '2', fein: '2', hbx_id: '1235', types: ['general_agency'] } }
          }
        }
      end

      before { reflex.run(:audience_select) }

      it 'will render two error badges' do
        expect(reflex).to have_received(:morph) do |_selector, raw|
          html = Capybara::Node::Simple.new(raw)
          expect(html).to have_css("span.badge-danger[title='Wrong audience type']", count: 2)
        end
      end
    end

    context 'of selecting employee with employer ids present' do
      let(:audience_ids) { ['1234', '1235'] }
      let(:audience_type) { 'employee' }
      let(:session) do
        {
          bulk_notice: {
            audience: { '1234' => { id: '1', fein: '1', hbx_id: '1234', types: ['employer'] },
                        '1235' => { id: '2', fein: '2', hbx_id: '1235', types: ['employer'] } }
          }
        }
      end

      before { reflex.run(:audience_select) }

      it 'will render two error badges' do
        expect(reflex).to have_received(:morph) do |_selector, raw|
          html = Capybara::Node::Simple.new(raw)
          expect(html).to have_css("span.badge-alt-blue", count: 2)
        end
      end
    end
  end
end