require 'dotenv/load'
require 'sinatra'
require 'mongo'
require 'json/ext'
require 'oj'

configure do
  db = Mongo::Client.new(ENV['MONGODB_URI'])
  set :mongo_db, db[:test]
end

before do
  content_type :json

  auth_token = params[:auth_token]

  if auth_token != ENV['AUTHENTICATION_TOKEN']
    halt(404, {}.to_json)
  end
end

get '/environments' do
  client = settings.mongo_db.client
  start_timestamp = params[:start_timestamp] || (Time.now - 24 * 60 * 60)
  start_timestamp = Time.at(start_timestamp.to_i)
  end_timestamp = params[:end_timestamp] || Time.now
  end_timestamp = Time.at(end_timestamp.to_i)

  result = client[:environments].find(
    {
      hour: {
        '$gte' => Time.parse(start_timestamp.strftime('%Y-%m-%dT%H:00:00%z')),
        '$lte' => Time.parse(end_timestamp.strftime('%Y-%m-%dT%H:00:00%z'))
      },
      zone_uid: params[:zone_uid],
      'environments.timestamp' => {
        '$gte' => start_timestamp.to_i,
        '$lte' => end_timestamp.to_i,
      }
    }
  ).projection({environments: 1}).to_a

  result.map {|r| r['environments']}.flatten.select do |environment|
    time = Time.at(environment['timestamp'])
    time >= start_timestamp && time <= end_timestamp
  end.to_json
end

post '/environments' do
  content_type :json

  body = Oj.load(request.body)
  body[:environments].map do |environment|
    timestamp = Time.at(environment[:timestamp])

    client = settings.mongo_db.client
    client[:environments].update_one(
      {
        zone_uid: body[:zone_uid],
        hour: Time.parse(timestamp.strftime('%Y-%m-%dT%H:00:00%z'))
      },
      {
        '$push' => {environments: environment}
      },
      {
        upsert: true
      }
    )

    {}.to_json
  end
end