module Mongo
  class Collection
    def raw_aggregate(pipeline, options={})
      aggregate(pipeline, options)
    end
  end
end
