#This assumes you have stored the parameters in environment variables

akid=ENV['AWS_ACCESS_KEY_ID']
secret=ENV['AWS_SECRET_ACCESS_KEY']

#ENV['AWS_ACCESS_KEY_ID']=akid
#ENV['AWS_SECRET_ACCESS_KEY']=secret
#ENV['AWS_REGION']=region

if Rails.env.production?
Aws.config.update({region: 'us-east-1',
                   credentials: Aws::Credentials.new(akid, secret)})
end