module Edgar

  # Provides a small wrapper for Amazon S3 services.
  #
  #   AWSClient.new(name, file).upload
  #
  class AWSClient
    def initialize(name, file)
      @name = name
      @file = file

      client = Fog::Storage.new({
        provider: 'AWS',
        aws_access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
        region: ENV["S3_REGION"]
      })

      @bucket = client.directories.get(ENV["S3_BUCKET"])
    end

    def upload
      @bucket.files.create({
        key: "reports/#{@name}.csv",
        body: @file,
        public: false
      })
    end
  end
end
