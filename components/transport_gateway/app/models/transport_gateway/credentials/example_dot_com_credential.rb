module TransportGateway
  class Credentials::ExampleDotComCredential

    def basic_credential
      username = "john.doe@example.com"
      password = "B1g$3cr3t"
      return username, password
    end

    def key_credential
      key_file = File.join(File.expand_path("../../..spec/support", __FILE__), "test_files", "key.pem")
      pass_phrase = "it doesn't matter"
      return key_file, pass_phrase
    end

  end
end
