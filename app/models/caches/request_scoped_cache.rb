# frozen_string_literal: true

module Caches
  class RequestScopedCache

    def initialize
      @records = {}
    end

    def lookup(m_id, &def_block)
      return @records[m_id] if @records.key?(m_id)
      @records[m_id] = def_block.call
      @records[m_id]
    end

    def self.allocate(name)
      Thread.current[key_for(name)] = self.new
    end

    def self.release(name)
      Thread.current[key_for(name)] = nil
    end

    def self.lookup(name, cache_key, &def_block)
      repo = Thread.current[key_for(name)]
      return(def_block.call) if repo.nil?
      repo.lookup(cache_key, &def_block)
    end

    def self.key_for(name)
      "request_scoped_#{name}_cache_repository"
    end
  end
end
