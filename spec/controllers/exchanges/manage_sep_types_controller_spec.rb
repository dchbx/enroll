# frozen_string_literal: true

require 'rails_helper'
require 'factory_bot_rails'

if EnrollRegistry.feature_enabled?(:sep_types)
  RSpec.describe ::Exchanges::ManageSepTypesController do
    render_views
    before :all do
      DatabaseCleaner.clean
    end

    after :all do
      DatabaseCleaner.clean
      invoke_dry_types_script
    end

    let!(:person) do
      per = FactoryBot.create(:person, :with_hbx_staff_role)
      permission = FactoryBot.create(:permission, can_manage_qles: true)
      per.hbx_staff_role.update_attributes!(permission_id: permission.id)
      per
    end

    let!(:current_user){FactoryBot.create(:user, person: person)}
    let(:q1){FactoryBot.create(:qualifying_life_event_kind, is_active: true)}
    let(:q2){FactoryBot.create(:qualifying_life_event_kind, is_active: true)}

    context 'for new' do
      before do
        q1.update_attributes!(market_kind: 'individual', is_self_attested: true, aasm_state: :draft)
        q1.publish!
        sign_in(current_user)
        get :new
      end

      it 'should be a success' do
        expect(response).to have_http_status(:success)
      end

      it 'should render the new template' do
        expect(response).to render_template('new')
      end

      it 'should assign instance variable' do
        expect(assigns(:qle)).to be_a(Forms::QualifyingLifeEventKindForm)
      end

      it 'should load ivl_reasons on to the form object' do
        expect(assigns(:qle).ivl_reasons).to include(['Marriage', 'marriage'])
      end
    end

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
                                                      effective_on_kinds: ['date_of_event'],
                                                      coverage_effective_on: '2020-07-01',
                                                      coverage_end_on: '2020-07-31',
                                                      event_kind_label: 'event kind label',
                                                      is_visible: true,
                                                      date_options_available: true }}

      end

      context 'success case' do
        context 'individual' do
          before do
            sign_in(current_user)
            post :create, params: post_params
          end

          it 'should return http redirect' do
            expect(response).to have_http_status(:redirect)
          end

          it 'should have success flash message' do
            expect(flash[:success]).to eq 'New SEP Type Created Successfully.'
          end

          it 'should redirect to sep types dt action' do
            expect(response).to redirect_to(sep_types_dt_exchanges_manage_sep_types_path)
          end
        end

        context 'shop' do
          before do
            post_params[:forms_qualifying_life_event_kind_form].merge!({termination_on_kinds: ['date_of_event']})
            sign_in(current_user)
            post :create, params: post_params
          end

          it 'should return http redirect' do
            expect(response).to have_http_status(:redirect)
          end

          it 'should have success flash message' do
            expect(flash[:success]).to eq 'New SEP Type Created Successfully.'
          end

          it 'should redirect to sep types dt action' do
            expect(response).to redirect_to(sep_types_dt_exchanges_manage_sep_types_path)
          end
        end
      end

      context 'failure case' do
        before :each do
          post_params[:forms_qualifying_life_event_kind_form].merge!({end_on: '2019-07-01'})
          sign_in(current_user)
          post :create, params: post_params
        end

        it 'should return http redirect' do
          expect(response).to have_http_status(:success)
        end

        it 'should render the new template' do
          expect(response).to render_template('new')
        end

        it 'should have error message' do
          expect(response.body).to have_content(("End on must be after start on date"))
        end
      end
    end

    context 'for edit' do
      before do
        q1.update_attributes!(market_kind: 'individual', is_self_attested: true, aasm_state: :draft)
        q1.publish!
        sign_in(current_user)
        get :edit, params: {id: q1.id}
      end

      it 'should be a success' do
        expect(response).to have_http_status(:success)
      end

      it 'should render the edit template' do
        expect(response).to render_template('edit')
      end

      it 'should assign instance variable' do
        expect(assigns(:qle)).to be_a(Forms::QualifyingLifeEventKindForm)
      end

      it 'should load ivl_reasons on to the form object' do
        expect(assigns(:qle).ivl_reasons).to include(['Marriage', 'marriage'])
      end

      it 'should load qlek id data on to the form object' do
        expect(assigns(:qle)._id.to_s).to eq(q1.id.to_s)
      end

      it 'should load qlek title data on to the form object' do
        expect(assigns(:qle).title).to eq(q1.title)
      end

      it 'should load qlek tool_tip data on to the form object' do
        expect(assigns(:qle).tool_tip).to eq(q1.tool_tip)
      end

      it 'should load qlek effective_on_kinds data on to the form object' do
        expect(assigns(:qle).effective_on_kinds).to eq(q1.effective_on_kinds)
      end
    end

    context 'for update' do
      let(:post_params) do
        { id: q1.id.to_s,
          :forms_qualifying_life_event_kind_form => { start_on: '2020-07-01',
                                                      end_on: '2020-07-31',
                                                      title: 'test title',
                                                      tool_tip: 'jhsdjhs',
                                                      pre_event_sep_in_days: '10',
                                                      is_self_attested: 'true',
                                                      reason: 'birth',
                                                      post_event_sep_in_days: '88',
                                                      market_kind: 'individual',
                                                      effective_on_kinds: ['date_of_event'],
                                                      coverage_effective_on: '2020-07-01',
                                                      coverage_end_on: '2020-07-31',
                                                      event_kind_label: 'event kind label',
                                                      is_visible: true,
                                                      date_options_available: true }}
      end

      context 'success case' do
        before do
          sign_in(current_user)
        end

        it 'should return http redirect' do
          post :update, params: post_params
          expect(response).to have_http_status(:redirect)
        end

        it 'should have success flash message' do
          post_params[:forms_qualifying_life_event_kind_form].merge!({reason: 'test birth'})
          post :update, params: post_params
          expect(flash[:success]).to eq 'SEP Type Updated Successfully.'
        end

        it 'should redirect to sep types dt action' do
          post_params[:forms_qualifying_life_event_kind_form].merge!({reason: 'test had a baby'})
          post :update, params: post_params
          expect(response).to redirect_to(sep_types_dt_exchanges_manage_sep_types_path)
        end
      end

      context 'failure case' do
        before :each do
          post_params[:forms_qualifying_life_event_kind_form].merge!({end_on: '2019-07-01'})
          sign_in(current_user)
          post :update, params: post_params
        end

        it 'should return http redirect' do
          expect(response).to have_http_status(:success)
        end

        it 'should render the edit template' do
          expect(response).to render_template('edit')
        end

        it 'should have error message' do
          expect(response.body).to have_content(("End on must be after start on date"))
        end
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

      it 'should render sorting_sep_types template' do
        expect(response).to render_template('exchanges/manage_sep_types/sorting_sep_types.html.erb')
      end

      it 'should have response body' do
        expect(response.body).to match(/Individual/i)
        expect(response.body).to match(/Shop/i)
        expect(response.body).to match(/Congress/i)
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

      context 'success case' do

        it 'should return http redirect' do
          expect(response).to have_http_status(:ok)
        end

        it 'should update the position' do
          expect(QualifyingLifeEventKind.find(q1.id).ordinal_position).to equal 3
          expect(QualifyingLifeEventKind.find(q2.id).ordinal_position).to equal 4
        end
      end

      context 'failure case' do
        let(:params) do
          { 'market_kind' => 'shop', 'sort_data' => nil}
        end

        it 'should return http redirect' do
          expect(response).to have_http_status(:internal_server_error)
        end
      end
    end

    context 'for sep_types_dt' do

      before do
        person.hbx_staff_role.permission.update_attributes!(can_complete_resident_application: true)
        sign_in(current_user)
        get :sep_types_dt
      end

      it 'should return http ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'should render sep_type_datatable template' do
        expect(response).to render_template('exchanges/manage_sep_types/sep_type_datatable.html.erb')
      end

      it 'should update the position' do
        expect(response.body).to match(/Sorting Sep Types/i)
      end
    end

    def invoke_dry_types_script
      consts = ['IndividualQleReasons', 'ShopQleReasons',
                'FehbQleReasons', 'IndividualEffectiveOnKinds',
                'ShopEffectiveOnKinds', 'FehbEffectiveOnKinds']
      types_module_constants = Types.constants(false)
      consts.each {|const| Types.send(:remove_const, const.to_sym) if types_module_constants.include?(const.to_sym)}
      load File.join(Rails.root, 'app/domain/types.rb')
    end
  end
end
