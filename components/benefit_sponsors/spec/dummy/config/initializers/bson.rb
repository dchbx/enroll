# Solved the canonical query issue. Credit to https://github.com/plataformatec/devise/issues/2949#issuecomment-44520300

module BSON
  class ObjectId
    def as_json(*args)
      to_s
    end
  end
end