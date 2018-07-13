module Config
  module S3Helper
    def s3_template_bucket_key
      Rails.env.production? ? ENV['S3_TEMPLATES_BUCKET_KEY'] : "bogus-key"
    end
  end
end
