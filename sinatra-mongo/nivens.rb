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

db = Mongo::Connection.new.db("nivens")

# collections
rabbits = db["rabbits"]
litters = db["litters"]
breedings = db["breedings"]

get '/rabbit/new' do
  erb :rabbit
end

get '/rabbit/all' do
  response = '<h1>Rabbits</h1>'
  rabbits.find().each { |rabbit|
    response += '<pre>' + JSON.pretty_generate(rabbit) + '</pre>'
  }
  response
end

get '/rabbit/:ear_id' do
  response = '<h1>Rabbit</h1>'
  rabbit = rabbits.find_one( "ear_id" => params[:ear_id] )
  response += "<pre>" + JSON.pretty_generate(rabbit) + "</pre>"
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
    :ear_id => params["ear_id"],
    :name => params["name"],
    :sex => params["sex"], 
    :birth_date => Date.new(params["year"].to_i,params["month"].to_i,params["day"].to_i).to_time.utc
   }
  rabbits.insert(doc)
  redirect '/rabbit/'+params["ear_id"]
end

post '/exposure' do
  date = Date.new(params["year"].to_i,params["month"].to_i,params["day"].to_i).to_time.utc
  exposure = { :date => date, :notes => params["notes"] }
  puts date
  puts exposure
  puts "updating..." + params["litter_id"]
  litters.update( {:litter_id => params["litter_id"]}, { "$push" => {"exposures" =>  exposure } } )
  litters.update( {:litter_id => params["litter_id"]}, { "$set" => { "last_exposure" => date } } )
  redirect '/litter/'+params["litter_id"]
end

get '/litter/new' do
  erb :litter
end

post '/litter' do
  doc = {
         :doe => params["doe"], 
         :buck => params["buck"], 
         :litter_id => params["litter_id"],
         :date => Date.new(params["year"].to_i,params["month"].to_i,params["day"].to_i).to_time.utc ,
         :kindled_count => params["size"],
         :notes => params["notes"] }
  litters.insert(doc)
  redirect '/litter/'+params["litter_id"]
end

get '/litter/all' do
  response = '<h1>Litters</h1>'
  litters.find().each { |litter|
    response += "<pre>" + JSON.pretty_generate(litter) + "</pre>"
    response += "<a href='/litter/" + litter["litter_id"] + "'>Edit</a>"
  }
  response
end

get '/litter/:litter_id' do
  response = "<h1>Litter</h1>"
  litter = litters.find_one( "litter_id" => params[:litter_id] )
  response += "<pre>" + JSON.pretty_generate(litter) + "</pre>"
  response += erb(:exposure)
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
  
@@ rabbit
  <form action="/rabbit" method="post">
    Ear ID: <input type="text" name="ear_id"/><br/>
    Sex: <input type="text" name="sex"/><br/>
    Birth Year: <input type="text" name="year"/><br/>
    Birth Month: <input type="text" name="month"/><br/>
    Birth Day: <input type="text" name="day"/><br/>
    Parent Doe: <input type="text" name="parent_doe"><br/>
    Parent Buck: <input type="text" name="parent_buck"><br/>
    <button type="submit" name="Submit">Submit</button>
  </form>
  
@@ exposure
    <form action="/exposure" method="post">
      <input type="hidden" name="litter_id" value="<%= params['litter_id'] %>"/>
      Year: <input type="text" size="4" name="year"/>
      Month: <input type="text" size="2" name="month"/>
      Day: <input type="text" size="2" name="day"/>
      Notes: <input type="text" size="15" name="notes">
      <button type="submit" name="Submit">Add Exposure</button>
    </form>

@@ litter
    <form action="/litter" method="post">
      Doe's Ear ID: <input type="text" name="doe"/><br/>
      Buck's Ear ID: <input type="text" name="buck"><br/>
      Litter Number: <input type="text" name="litter_id"/><br/>
      <button type="submit" name="Submit">Submit</button>
    </form>
