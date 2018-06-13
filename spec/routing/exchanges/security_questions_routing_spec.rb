require 'rails_helper'

describe Exchanges::SecurityQuestionsController do

  describe 'routing' do

    it 'route to SecurityQuestions#index' do
      expect(get('/exchanges/security_questions')).to route_to('exchanges/security_questions#index')
    end

    it 'route to SecurityQuestions#new' do
      expect(get('/exchanges/security_questions/new')).to route_to('exchanges/security_questions#new')
    end

    it 'route to SecurityQuestions#create' do
      expect(post('/exchanges/security_questions')).to route_to('exchanges/security_questions#create')
    end

    it 'route to SecurityQuestions#edit' do
      expect(get('/exchanges/security_questions/1/edit')).to route_to('exchanges/security_questions#edit', id: '1')
    end

    it 'route to SecurityQuestions#update' do
      expect(put('/exchanges/security_questions/1')).to route_to('exchanges/security_questions#update', id: '1')
    end

    it 'route to SecurityQuestions#destroy' do
      expect(delete('/exchanges/security_questions/1')).to route_to('exchanges/security_questions#destroy', id: '1')
    end
  end

end
