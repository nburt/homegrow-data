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

  puts auth_token
  puts ENV['AUTHENTICATION_TOKEN']
  if auth_token != ENV['AUTHENTICATION_TOKEN']
    halt(404, {}.to_json)
  end
end

get '/environments' do
  client = settings.mongo_db.client
  client[:environments].find({zone_uid: params[:zone_uid]}).to_a.to_json
end

post '/environments' do
  body = Oj.load(request.body)
  body[:environments].map do |environment|
    timestamp = Time.at(environment[:timestamp])

    client = settings.mongo_db.client
    client[:environments].update_one(
      {
        zone_uid: body[:zone_uid],
        hour: timestamp.hour
      },
      {
        '$push' => {environments: environment}
      },
      {
        upsert: true
      }
    )
  end
end