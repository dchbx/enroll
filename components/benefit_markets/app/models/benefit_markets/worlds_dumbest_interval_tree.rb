module BenefitMarkets
  # An interval tree used for searching dates (for example for Actuarial Factors)
  # This is needed since we now use date ranges instead of directly hashable
  # year values.
  #
  # For speed and ease of implementation, this makes a couple assumptions
  # specific to our usage of this tree:
  # - Intervals will not overlap
  # - Insertion and deletion performance doesn't matter
  # - Deletion isn't even supported
  # - Querying must be at least O(log n)
  class WorldsDumbestIntervalTree
    class DumbNode
      attr_reader :interval
      attr_accessor :left, :right

      def initialize(interval)
        @interval = interval
        @left = nil
        @right = nil
      end

      def search(point)
        return nil unless self.interval.include?(point)
        return self.interval if @left.nil?
        @left.search(point) || @right.search(point)
      end

      def each(&blk)
        if @left.nil?
          yield self.interval
        else
          @left.each(&blk)
          @right.each(&blk)
        end
      end
    end

    include Enumerable

    def initialize
      @root = nil
      @size = 0
      @nodes_data = {}
    end

    def add_node(interval, data = nil)
      @nodes_data[interval] = data
      @size = @size + 1
      if @size == 1
        @root = DumbNode.new(interval)
      else
        build_tree
      end
    end

    def search(point)
      @root.search(point)
    end

    def search_data(point)
      interval = @root.search(point)
      interval ? @nodes_data[interval] : nil
    end

    def each(&blk)
      @root.each(&blk)
    end

    private

    def build_tree
      ranges = @nodes_data.keys.sort_by(&:min)
      min = ranges.first.min
      max = ranges.last.max
      lefts, rights = pivot(ranges)
      @root = DumbNode.new(min..max)
      build_nodes(@root, lefts, rights)
    end

    def build_nodes(parent, lefts, rights)
      if lefts.any?
        if lefts.length == 1
          parent.left = DumbNode.new(lefts.first)
        else
          new_lefts, new_rights = pivot(lefts)
          new_child = DumbNode.new(lefts.first.min..lefts.last.max)
          parent.left = new_child
          build_nodes(new_child, new_lefts, new_rights)
        end
      end
      if rights.any?
        if rights.length == 1
          parent.right = DumbNode.new(rights.first)
        else
          new_lefts, new_rights = pivot(rights)
          new_child = DumbNode.new(rights.first.min..rights.last.max)
          build_nodes(new_child, new_lefts, new_rights)
          parent.right = new_child
        end
      end
    end

    def pivot(ranges)
      n, r = ranges.length.divmod 2
      rightmost_left_element_index = (r == 0) ? (n - 1) : n
      pivot_value = ranges[rightmost_left_element_index].max
      ranges.partition { |k| k.min <= pivot_value}
    end
  end
end
