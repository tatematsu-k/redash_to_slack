require 'json'
require 'slack-notifier'
require 'faraday'

slack_webhook = ENV["SLACK_WEBHOOK_URL"]
redash_api_key = ENV["REDASH_API_KEY"]

def webhook(event:, context:)
  body = JSON.parse(event["body"])
  p body
  {
    statusCode: 200,
    body: {
      message: 'Go Serverless v1.0! Your function executed successfully!',
      input: body
    }.to_json
  }
end
