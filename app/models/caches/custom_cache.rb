# frozen_string_literal: true

module Caches
  class CustomCache

    def initialize(recs)
      @records = recs
    end

    def lookup(m_id)
      @records[m_id]
    end

    def self.allocate(klass, name, lookup_table)
      Thread.current[key_for(klass, name)] = self.new(lookup_table)
    end

    def self.release(klass, name)
      Thread.current[key_for(klass, name)] = nil
    end

    def self.lookup(klass, name, id_val, &def_block)
      repo = Thread.current[key_for(klass, name)]
      return(def_block.call) if repo.nil?
      repo.lookup(id_val)
    end

    def self.key_for(klass,name)
      klass.name.tableize.to_s + "_#{name}_cache_repository"
    end

    def self.with_custom_cache(kls, name, lt)
      self.allocate(kls, name, lt)
      yield
      self.release(kls, name)
    end
  end
end
