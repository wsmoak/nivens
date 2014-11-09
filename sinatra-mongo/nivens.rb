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

get '/rabbit/:ear_id' do
  response = '<h1>Rabbit</h1>'
  rabbits.find_one("ear_id" => params[:ear_id]).each{ |item| 
    response += "<p>" + item.inspect + "</p>" 
  }
  response
end

get '/rabbit/all' do
  response = '<h1>Rabbits</h1>'
  rabbits.find().each { |rabbit|
    response += '<p>' + rabbit.inspect + '</p>'
  }
  response
end

get '/rabbit/new' do
  erb :rabbit
end

post '/rabbit' do
  doc = { 
    :ear_id => params["ear_id"], 
    :sex => params["sex"], 
    :birth_date => Date.new(params["year"].to_i,params["month"].to_i,params["day"].to_i).to_time.utc }
  rabbits.insert(doc)
  redirect '/rabbit/'+params["ear_id"]
end

get '/breeding/new' do
  erb :breeding
end

post '/breeding' do
  date = Date.new(params["year"].to_i,params["month"].to_i,params["day"].to_i).to_time.utc
  doc = {
         :doe => params["doe"], 
         :buck => params["buck"], 
         :first => date ,
         :last => date ,
         :exposures => [ {:date => date, :notes => params["notes"] } ]
    }
  breedings.insert(doc)
  redirect '/breeding/all'
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
  redirect '/breeding/all'
end

#store latest breeding on the rabbit?
get '/breeding/all' do
  response = ''
  breedings.find().each { |breeding| 
    response += '<p>' + breeding.inspect + 
    "<form action='/breeding/edit/"+ breeding["doe"] + "'><button type='submit'>Add Exposure</button></form></p>"
  }
  response
end

get '/litter/all' do
  response = ''
  litters.find().each { |litter|
    response += "<p>" + litter.inspect + "</p>"
  }
  response
end

def add_nestbox(the_date)
  the_date + 60*60*24*27
end

def remove_nestbox(the_date)
  the_date + 60*60*24*35
end

get '/schedule' do
  response = '<h1>Schedule</h1>'
  # db.coll.find({"exposures": {"$slice": -1}}) 
  breedings.find().each { |breeding|
    first_exposure = breeding["first"]
    last_exposure = breeding["last"]
    response = response + "<p>Doe "+breeding["doe"]+" bred " + first_exposure.strftime("%m/%d" ) +
      " to " + last_exposure.strftime("%m/%d") +
      ". Add nestbox on " + add_nestbox(first_exposure).strftime("%a %m/%d" ) +
      ". Remove nestbox on " + remove_nestbox(last_exposure).strftime("%a %m/%d") + ".</p>"
  }
  response
end

get '/litter/new' do
  erb :litter
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
  
@@ breeding
    <form action="/breeding" method="post">
      Doe's Ear ID: <input type="text" name="doe"/><br/>
      Buck's Ear ID: <input type="text" name="buck"/><br/>
      Year: <input type="text" name="year"/><br/>
      Month: <input type="text" name="month"/><br/>
      Day: <input type="text" name="day"/><br/>
      Notes: <input type="text" name="notes"><br/>
      <button type="submit" name="Submit">Submit</button>
    </form>

@@ litter
    <form action="/litter" method="post">
      Doe's Ear ID: <input type="text" name="doe"/><br/>
      Litter Number: <input type="text" name="litter_id"/><br/>
      Number of kits born: <input type="text" name="size"/><br/>
      Birth Year: <input type="text" name="year"/><br/>
      Birth Month: <input type="text" name="month"/><br/>
      Birth Day: <input type="text" name="day"/><br/>
      Notes: <input type="text" name="notes"><br/>
      <button type="submit" name="Submit">Submit</button>
    </form>
