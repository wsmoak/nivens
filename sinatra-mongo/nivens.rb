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
#db = Mongo::Connection.new.db("nivens")

# collections
rabbits = db["rabbits"]
litters = db["litters"]
txns    = db["transactions"]

get '/' do
  erb :index
end

get '/rabbit/create' do
  erb :rabbit_create
end

get '/rabbit/all' do
  response = '<h1>Rabbits</h1>'
  rabbits.find().each { |rabbit|
    response += '<pre>' + JSON.pretty_generate(rabbit) + '</pre>'
    response += "<a href='/rabbit/" + rabbit["id"] + "'>Display</a> | "
    response += "<a href='/rabbit/edit/" + rabbit["id"] + "'>Edit</a>"
  }
  response += "<p><a href='/'>Home</a></p>"
  response
end

get '/rabbit/:id' do
  response = '<h1>Rabbit</h1>'
  rabbit = rabbits.find_one( "id" => params[:id] )
  response += "<pre>" + JSON.pretty_generate(rabbit) + "</pre>"
  response += "<a href='/rabbit/edit/" + rabbit["id"] + "'>Edit</a> | "
  response += "<a href='/rabbit/all" + "'>List</a>"
  response += "<p><a href='/'>Home</a></p>"
  response
end

get '/rabbit/edit/:id' do
  response = '<h1>Rabbit</h1>'
  rabbit = rabbits.find_one( "id" => params[:id] )
  response += "<pre>" + JSON.pretty_generate(rabbit) + "</pre>"
  response += erb(:rabbit_update)
  response += "<a href='/rabbit/" + rabbit["id"] + "'>Display</a> | "
  response += "<a href='/rabbit/all" + "'>List</a>"
  response += "<p><a href='/'>Home</a></p>"
  response
end

# http://www.sinatrarb.com/faq.html#multiroute
["/rabbit", "/rabbits"].each do |path|
  get path do
    redirect '/rabbit/all'
  end
end

post '/rabbit' do
  doc = { 
    :id => params["id"],
    :name => params["name"],
    :sex => params["sex"], 
    :birth_date => Date.new(params["year"].to_i,params["month"].to_i,params["day"].to_i).to_time.utc
   }
  rabbits.insert(doc)
  redirect '/rabbit/'+params["id"]
end

post '/rabbit/name/update' do
  rabbits.update( {:id => params[:id]}, { "$set" => { :name => params[:name] } } )
  redirect '/rabbit/'+params[:id]
end

post '/rabbit/sex/update' do
  rabbits.update( {:id => params[:id]}, { "$set" => { :sex => params[:sex] } } )
  redirect '/rabbit/'+params[:id]
end

post '/rabbit/birthdate/update' do
  rabbits.update( {:id => params[:id]},
  { "$set" => { :birth_date => Date.new(params["year"].to_i,params["month"].to_i,params["day"].to_i).to_time.utc } } )
  redirect '/rabbit/'+params[:id]
end

post '/rabbit/mother/update' do
  rabbits.update( {:id => params[:id]}, { "$set" => { :parent_doe => params[:parent_doe] } } )
  redirect '/rabbit/'+params[:id]
end

post '/rabbit/father/update' do
  rabbits.update( {:id => params[:id]}, { "$set" => { :parent_buck => params[:parent_buck] } } )
  redirect '/rabbit/'+params[:id]
end

post '/exposure' do
  date = Date.new(params["year"].to_i,params["month"].to_i,params["day"].to_i).to_time.utc
  exposure = { :date => date, :notes => params["notes"] }
  litters.update( {:id => params["id"]}, { "$push" => {"exposures" =>  exposure } } )
  litters.update( {:id => params["id"]}, { "$set" => { "last_exposure" => date } } )
  litter = litters.find_one( "id" => params[:id] )
  if !litter["first_exposure"] then
    litters.update( {:id => params["id"]}, { "$set" => { :first_exposure => date } } )
  end
  redirect '/litter/edit/'+params["id"]
end

post '/weight' do
  date = Date.new(params[:year].to_i,params[:month].to_i,params[:day].to_i).to_time.utc
  rabbit_id = params[:rabbit]
  count = rabbit_id.empty? ? params[:count].to_i : 1
  data = { :weight => params[:weight].to_f, :count => count, :id => rabbit_id, :notes => params[:notes] }
  if litters.find_one({:id => params[:id], "weights.date" => date  } ) then
    # see http://docs.mongodb.org/manual/reference/operator/update/positional/#update-documents-in-an-array
    litters.update( {:id => params[:id], "weights.date" => date  }, { "$push" =>  { "weights.$.data" => data } } )
  else
    litters.update( {:id => params[:id] }, { "$push" => { :weights => { :date => date, :data => [ data ] } } } )
  end
  redirect '/litter/edit/'+params[:id]
end

get '/litter/create' do
  erb :litter_create
end

post '/litter' do
  litters.insert( {
         :id => params[:id],
         :doe => params[:doe], 
         :buck => params[:buck]
        }
    )
  redirect '/litter/edit/'+params["id"]
end

post '/litter/doe/update' do
  litters.update( {:id => params[:id]}, { "$set" => { :doe => params[:doe] } } )
  redirect '/litter/edit/'+params[:id]
end

post '/litter/buck/update' do
  litters.update( {:id => params[:id]}, { "$set" => { :buck => params[:buck] } } )
  redirect '/litter/edit/'+params[:id]
end

post '/litter/kindled/update' do
  litters.update( {:id => params[:id]}, { "$set" => { :kindled => params[:kindled].to_i } } )
  redirect '/litter/edit/'+params[:id]
end

post '/litter/survived/update' do
  litters.update( {:id => params[:id]}, { "$set" => { :survived => params[:survived].to_i } } )
  redirect '/litter/edit/'+params[:id]
end

get '/litter/all' do
  response = '<h1>Litters</h1>'
  litters.find().each { |litter|
    response += "<pre>" + JSON.pretty_generate(litter) + "</pre>"
    response += "<a href='/litter/" + litter["id"] + "'>Display</a> | "
    response += "<a href='/litter/edit/" + litter["id"] + "'>Edit</a>"
  }
  response += "<p><a href='/'>Home</a></p>"
  response
end

get '/litter/edit/:id' do
  response = "<h1>Litter</h1>"
  litter = litters.find_one( "id" => params[:id] )
  response += "<pre>" + JSON.pretty_generate(litter) + "</pre>"
  response += erb(:litter_update)
  response += erb(:exposure)
  response += erb(:weight)
  response += "<a href='/litter/" + litter["id"] + "'>Display</a> | "
  response += "<a href='/litter/all" + "'>List</a>"
  response += "<p><a href='/'>Home</a></p>"
end

get '/litter/:id' do
  response = "<h1>Litter</h1>"
  litter = litters.find_one( "id" => params[:id] )
  response += "<pre>" + JSON.pretty_generate(litter) + "</pre>"
  response += "<a href='/litter/edit/" + litter["id"] + "'>Edit</a> | "
  response += "<a href='/litter/all" + "'>List</a>"
  response += "<p><a href='/'>Home</a></p>"
end

# http://www.sinatrarb.com/faq.html#multiroute
["/litter", "/litters"].each do |path|
  get path do
    redirect '/litter/all'
  end
end

def add_nestbox(the_date)
  the_date + 60*60*24*27
end

def kits_due(the_date)
  the_date + 60*60*24*31
end

def remove_nestbox(the_date)
  the_date + 60*60*24*35
end

get '/transaction/create' do
  erb :txn_create
end

post '/transaction' do
  txns.insert( {
         :date => Date.new(params["year"].to_i,params["month"].to_i,params["day"].to_i).to_time.utc,
         :amount => params[:amount].to_f,
         :type => params[:type],
         :description => params[:description]
        }
    )
  redirect '/transaction/all'
end

post '/transaction/delete' do
  txns.remove( { "_id" => BSON::ObjectId( params[:_id] ) } )
  redirect '/transaction/all'
end

get '/transaction/all' do
  response = '<h1>Transactions</h1>'
  txns.find().each { |txn|
    response += "<pre>" + JSON.pretty_generate(txn) + "</pre>"

    response += "<a href='/transaction/" + txn['_id'].to_s + "'>Display</a> | "
    response += "<a href='/transaction/edit/" + txn['_id'].to_s + "'>Edit</a>"
  }
  response += "<p><a href='/'>Home</a></p>"
  response
end

get '/transaction/edit/:_id' do
  response = "<h1>Transaction</h1>"
  txn = txns.find_one( "_id" => BSON::ObjectId( params[:_id] ) )
  response += "<pre>" + JSON.pretty_generate(txn) + "</pre>"
  response += "<form action='/transaction/delete' method='post'>"
  response += "<input type='hidden' name='_id' value='" + txn['_id'].to_s + "'/>"
  response += "<button type='submit'>Delete</button></form>"
  response += "<a href='/transaction/" + txn['_id'].to_s + "'>Display</a> | "
  response += "<a href='/transaction/all'>List</a>"
  response += "<p><a href='/'>Home</a></p>"
  response
end

get '/transaction/:_id' do
  response = "<h1>Transaction</h1>"
  txn = txns.find_one( "_id" => BSON::ObjectId( params[:_id] ) )
  response += "<pre>" + JSON.pretty_generate(txn) + "</pre>"
  response += "<a href='/transaction/edit/" + txn['_id'].to_s + "'>Edit</a> | "
  response += "<a href='/transaction/all'>List</a>"
  response += "<p><a href='/'>Home</a></p>"
end

get '/schedule' do
  response = '<h1>Schedule</h1>'
  # db.coll.find({"exposures": {"$slice": -1}}) 
  litters.find(  "first_exposure" => {"$exists"=>"true"} ).each { |litter|
    first_exposure = litter["first_exposure"]
    last_exposure = litter["last_exposure"]
    response += "<p>Doe " + litter["doe"] + " bred (to " + litter["buck"] + ") " +
      first_exposure.strftime("%m/%d" ) +" to " + last_exposure.strftime("%m/%d") +
      ". Add nestbox on " + add_nestbox(first_exposure).strftime("%a %m/%d" ) +
      ". Kits due " + kits_due(first_exposure).strftime("%a %m/%d" ) +
      " to " + kits_due(last_exposure).strftime("%a %m/%d") +
      ". Remove nestbox on " + remove_nestbox(last_exposure).strftime("%a %m/%d") + ".</p>"
  }
  response += "<p><a href='/'>Home</a></p>"
  response
end

__END__

@@ layout
  <!DOCTYPE html>
  <html>
  <head></head>
  <body>
    <%= yield %>
  </body>
  </html>

@@ index
  <h1>Nivens</h1>
  <p><a href='/rabbit/create'>New Rabbit</a></p>
  <p><a href='/litter/create'>New Litter</a></p>
  <p><a href='/transaction/create'>New Transaction</a>
  <p><a href='/rabbit/all'>List Rabbits</a></p>
  <p><a href='/litter/all'>List Litters</a></p>
  <p><a href='/transaction/all'>List Transactions</a></p>
  <p><a href='/schedule'>View Schedule</a></p>

@@ rabbit_create
  <h1>New Rabbit</h1>
  <form action="/rabbit" method="post">
    ID: <input type="text" name="id"/><br/>
    Name: <input type="text" name="name"/><br/>
    Sex: <input type="text" name="sex"/><br/>
    Birth Year: <input type="text" name="year"/><br/>
    Birth Month: <input type="text" name="month"/><br/>
    Birth Day: <input type="text" name="day"/><br/>
    Parent Doe: <input type="text" name="parent_doe"><br/>
    Parent Buck: <input type="text" name="parent_buck"><br/>
    <button type="submit" name="Submit">Submit</button>
    <p><a href='/'>Home</a>
  </form>

@@ rabbit_update
  <form action="/rabbit/name/update" method="post">
    <input type="hidden" name="id" value="<%= params[:id] %>"/>
    Name: <input type="text" name="name"/>
    <button type="submit" name="Submit">Update</button>
  </form>
  <form action="/rabbit/sex/update" method="post">
    <input type="hidden" name="id" value="<%= params[:id] %>"/>
    Sex: <input type="text" name="sex"/>
    <button type="submit" name="Submit">Update</button>
  </form>
  <form action="/rabbit/birthdate/update" method="post">
    <input type="hidden" name="id" value="<%= params[:id] %>"/>
    Birth Year: <input type="text" size="5" name="year"/>
    Birth Month: <input type="text" size="3" name="month"/>
    Birth Day: <input type="text" size="3" name="day"/>
    <button type="submit" name="Submit">Update</button>
  </form>
  <form action="/rabbit/mother/update" method="post">
    <input type="hidden" name="id" value="<%= params[:id] %>"/>
    Parent Doe: <input type="text" name="parent_doe"/>
    <button type="submit" name="Submit">Update</button>
  </form>
  <form action="/rabbit/father/update" method="post">
    <input type="hidden" name="id" value="<%= params[:id] %>"/>
    Parent Buck: <input type="text" name="parent_buck"/>
    <button type="submit" name="Submit">Update</button>
  </form>
  
@@ litter_update
  <form action="/litter/doe/update" method="post">
    <input type="hidden" name="id" value="<%= params[:id] %>"/>
    Doe: <input type="text" size="5" name="doe"/>
    <button type="submit" name="Submit">Update</button>
  </form>
  <form action="/litter/buck/update" method="post">
    <input type="hidden" name="id" value="<%= params[:id] %>"/>
    Buck: <input type="text" size="5" name="buck"/>
    <button type="submit" name="Submit">Update</button>
  </form>
  <form action="/litter/kindled/update" method="post">
    <input type="hidden" name="id" value="<%= params[:id] %>"/>
    Number Kindled: <input size="5" type="text" name="kindled"/>
    <button type="submit" name="Submit">Update</button>
  </form>
  <form action="/litter/survived/update" method="post">
    <input type="hidden" name="id" value="<%= params[:id] %>"/>
    Number Survived: <input type="text" size="5" name="survived"/>
    <button type="submit" name="Submit">Update</button>
  </form>

@@ exposure
    <form action="/exposure" method="post">
      <input type="hidden" name="id" value="<%= params['id'] %>"/>
      Exposure Year: <input type="text" size="4" name="year"/>
      Month: <input type="text" size="2" name="month"/>
      Day: <input type="text" size="2" name="day"/>
      Notes: <input type="text" size="15" name="notes">
      <button type="submit" name="Submit">Add Exposure</button>
    </form>

@@ litter_create
    <h1>New Litter</h1>
    <form action="/litter" method="post">
      Doe's Ear ID: <input type="text" name="doe"/><br/>
      Buck's Ear ID: <input type="text" name="buck"><br/>
      Litter Number: <input type="text" name="id"/><br/>
      <button type="submit" name="Submit">Submit</button>
    </form>
    <p><a href='/'>Home</a>

@@ weight
    <form action="/weight" method="post">
      <input type="hidden" name="id" value="<%= params['id'] %>"/>
      Weight Year: <input type="text" size="4" name="year"/>
      Month: <input type="text" size="2" name="month"/>
      Day: <input type="text" size="2" name="day"/>
      Weight: <input type="text" size="5" name="weight"/>
      (Count: <input type="text" size="5" name="count"/> or
      ID: <input type="text" size="5" name="rabbit"/>)
      Notes: <input type="text" size="15" name="notes">
      <button type="submit" name="Submit">Add Weight</button>
    </form>

@@txn_create
    <h1>New Transaction</h1>
    <form action="/transaction" method="post">
      Year: <input type="text" size="4" name="year"/>
      Month: <input type="text" size="2" name="month"/>
      Day: <input type="text" size="2" name="day"/><br/>
      Amount: <input type="text" name="amount"><br/>
      Type: <input type="text" name="type"/><br/>
      Description: <input type="text" name="description"/><br/>
      <button type="submit" name="Submit">Submit</button>
    </form>
    <p><a href='/'>Home</a>
