# frozen_string_literal: true

module TransportProfiles
  class Steps::CreateFile < Steps::Step

    def initialize(path, contents, gateway)
      super("Create file: #{path}", gateway)
      @path = path
      @contents = contents
    end

    def execute(_process_context)
      File.write(@path, @contents)
    end


  end
end
