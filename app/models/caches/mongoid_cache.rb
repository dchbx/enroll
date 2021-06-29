# frozen_string_literal: true

module Caches
  class MongoidCache

    def initialize(kls)
      @records = kls.all.inject({}) do |accum, c|
        accum[c.id] = c
        accum
      end
    end

    def lookup(m_id)
      @records[m_id]
    end

    def self.allocate(klass)
      Thread.current[key_for(klass)] = self.new(klass) if Thread.current[key_for(klass)].blank?
    end

    def self.release(klass)
      Thread.current[key_for(klass)] = nil
    end

    def self.lookup(klass, id_val, &def_block)
      repo = Thread.current[key_for(klass)]
      return(def_block.call) if repo.nil?
      repo.lookup(id_val)
    end

    def self.key_for(klass)
      "#{klass.name.tableize}_cache_repository"
    end

    def self.with_cache_for(*args)
      args.each do |kls|
        self.allocate(kls)
      end
      yield
      args.each do |kls|
        self.release(kls)
      end
    end
  end
end
