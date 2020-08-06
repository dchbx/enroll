# frozen_string_literal: true

Rails.application.routes.draw do

  mount TransportGateway::Engine => "/transport_gateway"
end
