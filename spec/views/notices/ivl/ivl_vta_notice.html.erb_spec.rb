# frozen_string_literal: true

require 'rails_helper'
include ActionView::Context

RSpec.describe 'notices/ivl/ivl_vta_notice.html.erb' do

  let(:true_or_false) { true }
  let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_mailing_address) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:application_event) do
    double('ApplicationEventKind', { name: '1095A VTA Void Cover Letter Notice',
                                     notice_template: 'notices/ivl/ivl_vta_notice',
                                     notice_builder: 'IvlNotices::IvlVtaNotice',
                                     event_name: 'ivl_vta_void_cover_letter_notice',
                                     options: { is_a_void_active_cover_letter: true},
                                     mpi_indicator: 'IVL_VTA',
                                     title: 'Your 1095-A Health Coverage Tax Form' })
  end

  let(:valid_params) do
    { subject: application_event.title,
      mpi_indicator: application_event.mpi_indicator,
      event_name: application_event.event_name,
      options: { is_a_void_active_cover_letter: true_or_false},
      template: application_event.notice_template }
  end

  let!(:notice) { catastrophic_plan_notice.notice }
  let!(:catastrophic_plan_notice) { IvlNotices::IvlVtaNotice.new(person.consumer_role, valid_params) }

  before :each do
    catastrophic_plan_notice.append_hbe
    catastrophic_plan_notice.build
    render file: 'notices/ivl/ivl_vta_notice', locals: {notice: notice}
  end

  context "for template's text" do
    it { expect(rendered).to have_selector('h3', text: 'NOTICE - VOID FORM 1095-A TAX FORM') }
    it { expect(rendered).not_to match(/Dear #{person.full_name}:/) }
    it { expect(rendered).to match(/You previously received a Form 1095-A from #{Settings.site.short_name} with information about your #{previous_year} health insurance coverage./) }
    it { expect(rendered).to match(/If you believe your Form 1095-A was voided by mistake please call/) }
    it { expect(rendered).to match(/The #{Settings.site.short_name} Team/) }
  end

  context 'text display for void active' do
    it 'should display the text if has AQHP enrollments' do
      expect(rendered).to match(/Our records show that the plans with the Marketplace-assigned policy numbers listed below were active in #{previous_year}./)
    end
  end

  context 'text display for void inactive' do
    let(:true_or_false) { false }

    it 'should display the text if has UQHP enrollments' do
      expect(rendered).to match("Since you did not have other health coverage in #{previous_year}, you will not receive a new Form 1095-A for this tax year.")
    end
  end

  context 'for partials' do
    it { render partial: 'notices/shared/cover_page', locals: {notice: notice} }
    it { render partial: 'notices/shared/logo_and_address_shop', locals: {notice: notice} }
    it { render partial: 'notices/shared/date', locals: {notice: notice} }
    it { render partial: 'notices/shared/address', locals: {notice: notice} }
    it { render partial: 'notices/shared/paragraph', locals: {content: "The #{Settings.site.short_name} Team"} }
  end
end
