# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module QualifyingLifeEventKind
    class Sort
      include Dry::Monads[:result, :do]

      def call(params)
        persist_data(params)
      end

      private

      def persist_data(params)
        sort_data = params['sort_data']
        sort_data.each do |sort|
          qleks = ::QualifyingLifeEventKind.active.where(market_kind: params['market_kind'], id: sort['id'])
          qleks.update(ordinal_position: sort['position'])
        end

        Success('Successfully sorted Qualifying Life Event Kind objects')
      end
    end
  end
end
