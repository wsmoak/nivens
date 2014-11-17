# Copyright 2014 Wendy Smoak
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'sinatra'
require 'mongo'
require 'json/ext'
require 'thin'
require 'uri'

# see https://devcenter.heroku.com/articles/mongohq#adding-a-compose-database
def get_connection
  return @db_connection if @db_connection
  db = URI.parse(ENV['MONGOHQ_URL'])
  db_name = db.path.gsub(/^\//, '')
  @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.password.nil?)
  @db_connection
end

db = get_connection

# collections
rabbits = db["rabbits"]

get '/' do
  erb :index
end

get '/api/rabbit' do
  content_type 'application/json'
  rabbits.find().to_a.to_json
end

post '/api/rabbit' do
  content_type 'application/json'
  puts "api/rabbit called with post and " + params.inspect
  new_id = rabbits.insert params
  rabbits.find_one( :_id => new_id ).to_json
end