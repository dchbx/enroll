require 'rails_helper'

describe PayloadInflater, "given a payload which is not deflated" do
  let(:payload) { "some string or whatever" }

  subject { PayloadInflater.inflate(false, payload) }

  it { is_expected.to eql payload }
end

describe PayloadInflater, "given a payload which is deflated" do
  let(:original_payload) { "some string or whatever" }
  let(:deflated_payload) do 
    buffer = StringIO.new
    gzw = Zlib::GzipWriter.new(buffer, Zlib::BEST_COMPRESSION)
    gzw.write(original_payload)
    gzw.close
    buffer.rewind
    Base64.encode64(buffer.string)
  end

  subject { PayloadInflater.inflate(true, deflated_payload) }

  it { is_expected.to eql original_payload }
end
