require 'csv'
require 'base64'
require 'json'
require 'rest_client'

currency = ARGV[0]
account_id = ARGV[1]

if currency == nil || currency.empty? || account_id == nil || account_id.empty?
  puts "Usage: main.rb currency account_id"
  exit
end

def get_env(key)
  value = ENV[key]
  if value == nil || value.empty?
    puts "#{key} environment variable is required"
    exit
  end
  value
end

def transferwise_api_url; get_env("TRANSFERWISE_API_URL"); end
def transferwise_api_key; get_env("TRANSFERWISE_API_KEY"); end
def transferwise_account_id; get_env("TRANSFERWISE_ACCOUNT_ID"); end
def freeagent_api_url; get_env("FREEAGENT_API_URL"); end
def freeagent_client_id; get_env("FREEAGENT_API_CLIENT_ID"); end
def freeagent_client_secret; get_env("FREEAGENT_API_CLIENT_SECRET"); end
def freeagent_refresh_token; get_env("FREEAGENT_API_REFRESH_TOKEN"); end

def freeagent_refresh_access_token
  url = File.join(freeagent_api_url, "token_endpoint")
  body = {
    grant_type: "refresh_token",
    refresh_token: freeagent_refresh_token,
  }

  encoded_username_password = Base64.encode64("#{freeagent_client_id}:#{freeagent_client_secret}")
  raw = RestClient.post(url, URI.encode_www_form(body), { Authorization: "Basic #{encoded_username_password}" })
  response = JSON.parse(raw)

  response["access_token"]
end

def freeagent_access_token
  @freeagent_access_token ||= freeagent_refresh_access_token
end

def freeagent_account_url(account_id)
  File.join(freeagent_api_url, "bank_accounts", account_id)
end

def freeagent_transactions(account_id)
  params = { bank_account: freeagent_account_url(account_id) }
  url = File.join(freeagent_api_url, "bank_transactions?#{URI.encode_www_form(params)}")
  raw = RestClient.get(url, { Authorization: "Bearer #{freeagent_access_token}" })
  response = JSON.parse(raw)
  response["bank_transactions"].sort { |a, b| a["dated_on"] <=> b["dated_on"] }
end

def transferwise_statement(currency, since)
  end_date = (Date.today + 2).to_time - 0.0000000001
  iso8601 = "%FT%T.%NZ"
  params = { currency: currency, intervalStart: since.strftime(iso8601), intervalEnd: end_date.strftime(iso8601) }
  url = File.join(
    transferwise_api_url,
    "borderless-accounts",
    transferwise_account_id,
    "statement.json?#{URI.encode_www_form(params)}",
  )

  begin
    raw = RestClient.get(url, { Authorization: "Bearer #{transferwise_api_key}" }) 
    response = JSON.parse(raw)
  rescue RestClient::Exception => error
    puts error.response
    raise error
  end

  response["transactions"].sort { |a, b| a["date"] <=> b["date"] }
end

def upload_freeagent_statement(content, account_id)
  params = { bank_account: freeagent_account_url(account_id) }
  url = File.join(
    freeagent_api_url,
    "bank_transactions",
    "statement?#{URI.encode_www_form(params)}"
  )
  body = { statement: content }

  raw = RestClient.post(url, body.to_json, { Authorization: "Bearer #{freeagent_access_token}", Content_Type: "application/json" })

  raw
end

transactions = freeagent_transactions(account_id)
last_known = Date.parse(transactions.last["dated_on"]).to_time

statement = transferwise_statement(currency, last_known)

if statement.length == 0
  return
end

csv = CSV.generate do |csv|
  statement.each do |transaction|
    date = DateTime.parse(transaction["date"]).to_time.strftime("%d/%m/%Y")
    description = transaction["details"]["description"]

    if transaction["totalFees"]["value"] > 0
      csv << [date, -transaction["totalFees"]["value"], "#{description} (fee)"]
    end

    is_debit = transaction["type"] == "DEBIT"
    amount = transaction["amount"]["value"] - (transaction["totalFees"]["value"] * (is_debit ? -1 : 1))

    csv << [date, amount, description]
  end
end

p "Uploading #{statement.length} transactions"
upload_freeagent_statement(csv, account_id)
