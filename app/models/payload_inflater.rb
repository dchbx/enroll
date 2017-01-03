class PayloadInflater
  def self.inflate(is_deflated, payload)
    return payload unless is_deflated
    raw_data = Base64.decode64(payload)
    gz = Zlib::GzipReader.new(StringIO.new(raw_data))
    data = gz.read
    gz.close
    data
  end
end
