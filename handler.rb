require 'json'
require 'slack-notifier'
require 'faraday'

def webhook(event:, context:)
  body = JSON.parse(event["body"])
  p body

  if body.dig("alert", "state") == "triggered"
    conn = faraday_client(url: body["url_base"])

    results = get_query_results(url: body["url_base"], id: body.dig("alert", "query_id"))
    message = <<~EOF
      #{body.dig("alert", "name")}
      #{body["url_base"]}/queries/#{body.dig("alert", "query_id")}
    EOF
    notify(message, parse_slack_attachments(results, color: "danger"))
  end

  {
    statusCode: 200,
    body: {
      message: 'Go Serverless v1.0! Your function executed successfully!',
      input: body
    }.to_json
  }
end

def notify(text, attachments = [])
  slack_client.post(
    text: text,
    attachments: attachments,
  )
end

def parse_slack_attachments(results = [], color: good)
  results.map do |result|
    {
      color: color,
      fields: result.map do |key, value|
        {
          title: key,
          value: value,
          short: is_short?(value),
        }
      end
    }
  end
end

def is_short?(value)
  case value
  when Integer
    true
  else
    false
  end
end

def slack_client
  @notifier ||= Slack::Notifier.new(ENV["SLACK_WEBHOOK_URL"])
end

def get_query_results(url:, id:)
  api_key = get_query_api_key(url: url, id: id)

  conn = faraday_client(url: url)

  response = conn.get do |req|
    req.url "/api/queries/#{id}/results.json"
    req.headers['Content-Type'] = 'application/json'
    req.headers['Authorization'] = "Key #{api_key}"
  end

  JSON.parse(response.body).dig("query_result", "data", "rows")
end

def get_query_api_key(url:, id:)
  get_redash_query(url: url, id: id)["api_key"]
end

def get_redash_query(url:, id:)
  conn = faraday_client(url: url)

  response = conn.get do |req|
    req.url "/api/queries/#{id}"
    req.headers['Content-Type'] = 'application/json'
    req.headers['Authorization'] = "Key #{ENV["REDASH_API_KEY"]}"
  end

  JSON.parse(response.body)
end

def faraday_client(url:)
  @clients ||= {}
  return @clients[url] if @clients.has_key?(url)

  conn = Faraday::Connection.new(url: url) do |builder|
    builder.use Faraday::Request::UrlEncoded
    builder.use Faraday::Response::Logger
  end

  @clients[url] = conn

  conn
end
