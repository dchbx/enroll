# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Exchanges::ManageSepTypesController do
  before :all do
    DatabaseCleaner.clean
  end

  let(:current_user){FactoryBot.create(:user)}

  context 'for create' do
    let(:post_params) do
      { 'forms_qualifying_life_event_kind_form' => { 'settings' => { 'start_on' => '2020-07-01',
                                                                     'end_on' => '2020-07-31',
                                                                     'title' => 'test title',
                                                                     'tool_tip' => 'jhsdjhs',
                                                                     'pre_event_sep_in_days' => '10',
                                                                     'is_self_attested' => 'true',
                                                                     'reason' => 'lost_access_to_mec',
                                                                     'post_event_sep_in_days' => '88',
                                                                     'market_kind' => 'Individual'},
                                                                     'effective_on_kinds' => ['date_of_event'] }}
    end

    before do
      sign_in(current_user)
      post :create, params: post_params
    end

    it 'should return http redirect' do
      expect(response).to have_http_status(:redirect)
    end

    it 'should have success flash message' do
      expect(flash[:success]).to eq 'A new SEP Type was successfully created.'
    end

    it 'should redirect to sep types dt action' do
      expect(response).to redirect_to(sep_types_dt_exchanges_manage_sep_types_path)
    end
  end
end
