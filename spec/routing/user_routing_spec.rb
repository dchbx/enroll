require 'rails_helper'

describe UsersController do

  describe 'routing' do

    it 'route to #confirm_lock' do
      expect(get('/users/1/confirm_lock')).to route_to('users#confirm_lock', id: '1')
    end

    it 'route to #lockable' do
      expect(get('/users/1/lockable')).to route_to('users#lockable', id: '1')
    end

    it 'routes to #reset_password' do
      expect(get('/users/2/reset_password')).to route_to('users#reset_password', id: '2')
    end

    it 'routes to #confirm_reset_password' do
      expect(put('/users/2/confirm_reset_password')).to route_to('users#confirm_reset_password', id: '2')
    end
    
  end

end