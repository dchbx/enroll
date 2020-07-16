# frozen_string_literal: true

require 'rails_helper'
require 'factory_bot_rails'

RSpec.describe ::Exchanges::ManageSepTypesController do
  render_views
  before :all do
    DatabaseCleaner.clean
  end

  let(:current_user){FactoryBot.create(:user)}
  let(:q1){FactoryBot.create(:qualifying_life_event_kind, is_active: true)}
  let(:q2){FactoryBot.create(:qualifying_life_event_kind, is_active: true)}

  context 'for create' do
    let(:post_params) do
      { :forms_qualifying_life_event_kind_form => { start_on: '2020-07-01',
                                                    end_on: '2020-07-31',
                                                    title: 'test title',
                                                    tool_tip: 'jhsdjhs',
                                                    pre_event_sep_in_days: '10',
                                                    is_self_attested: 'true',
                                                    reason: 'lost_access_to_mec',
                                                    post_event_sep_in_days: '88',
                                                    market_kind: 'individual',
                                                    effective_on_kinds: ['date_of_event'] }}
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

  context 'for sorting_sep_types' do

    before do
      sign_in(current_user)
      get :sorting_sep_types
    end

    it 'should return http redirect' do
      expect(response).to have_http_status(:ok)
    end

    it 'should have response body' do
      expect(response.body).to match /Individual/i
      expect(response.body).to match /Shop/i
      expect(response.body).to match /Congress/i
    end
  end

  context 'for sort' do
    let(:params) do
      { 'market_kind' => 'shop', 'sort_data' => [{'id' => q1.id, 'position' => 3}, 'id' => q2.id, 'position' => 4]}
    end

    before do
      sign_in(current_user)
      patch :sort, params: params
    end

    it 'should return http redirect' do
      expect(response).to have_http_status(:ok)
    end

    it 'should update the position' do
      expect(QualifyingLifeEventKind.find(q1.id).ordinal_position).to equal 3
      expect(QualifyingLifeEventKind.find(q2.id).ordinal_position).to equal 4
    end
  end
end
