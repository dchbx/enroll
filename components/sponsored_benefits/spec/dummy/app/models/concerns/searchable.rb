module Searchable
  extend ActiveSupport::Concern

  module ClassMethods
    def search_by(search_params)
      results = self.scoped
      search_params.each do |key, value|
        results = results.public_send(key, value) if value.present?
      end
      results
    end
  end
end
