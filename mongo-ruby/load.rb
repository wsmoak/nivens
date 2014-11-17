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

# Clears and re-loads the collections in the nivens database with sample data

require 'mongo'
require 'date'

def to_utc(year,month,day)
  Date.new(year,month,day).to_time.utc
end

db = Mongo::Connection.new.db("nivens")

puts "Loading rabbits..."
rabbits = db["rabbits"]
rabbits.remove 

rabbits.insert ( {:id=>"C4", :sex=>"M", :birth_date => to_utc(2011,12,01),
  :notes => "Acquired April 1 2012 from Ms. Schumaker, Inverness FL"} )
rabbits.insert ( {:id=>"C16", :sex=>"M", :birth_date => to_utc(2012,12,01),
  :notes => "Acquired Feb 2013 from Ms. Schumaker, Inverness FL"} )
rabbits.insert ( {:id=>"C3", :sex=>"F", :birth_date =>  to_utc(2011,12,01),
  :notes => "Acquired April 1 2012 from Ms. Schumaker, Inverness FL"} )
rabbits.insert ( {:id=>"NZW8", :sex=>"F", :birth_date => to_utc(2012,6,29),
  :notes => "Acquired from Crossroads Rabbitry in AL"} )
rabbits.insert ( {:id=>"3BL", :sex=>"F", :birth_date => to_utc(2014,03,04),
  "parent_buck" => "C4", "parent_doe" => "C3"} )
rabbits.insert ( {:id=>"3BR", :sex=>"F", :birth_date => to_utc(2014,03,04),
  "parent_buck" => "C4", "parent_doe" => "C3"} )

puts "Loading litters..."
litters = db["litters"]
litters.remove 
  
litters.insert(
  {:id => "43", :doe => "3BL", :buck => "C16", :birth_date => to_utc(2014,10,24),
    :kindled => 2, :survived => 2,
    :weights => [
      { :date => to_utc(2014,11,10),
        :data => [
          { :weight => 1.14, :count => 1, :id => "", :notes => "" },
          { :weight => 1.10, :count => 1, :id => "", :notes => "" }
        ]
      }
    ]
  }
)
  
litters.insert( {:id => "44", :doe => "3BR", :buck => "C16", :birth_date => to_utc(2014,10,24), "kindled" => 3, "survived" => 0 } )

litters.insert ( {:id => "45", :doe=>"C3", "buck"=>"C4",
  "first_exposure"=>to_utc(2014,11,7), "last_exposure"=>to_utc(2014,11,9),
  "exposures" => [
    {:date => to_utc(2014,11,7), :notes=>"not interested"},
    {:date => to_utc(2014,11,8), :notes=>"success"},
    {:date => to_utc(2014,11,9), :notes=>"not interested"}
    ] }
  )

litters.insert({ :id => "46", :doe=>"NZW8", :buck=>"C4",
  "first_exposure"=>to_utc(2014,11,7), "last_exposure"=>to_utc(2014,11,8),
    "exposures" => [
      {"date" => to_utc(2014,11,7), :notes=>"success"},
      {"date" =>to_utc(2014,11,8), :notes=>"very upset!"}
    ] }
  )

puts "Loading transactions..."
txns = db["transactions"]
txns.remove

# Store transactions as type=income or expense. Normally expense is negative, income is positive.  
# Refunds are negative income.  returns are negative expenses.
txns.insert( { :date => to_utc(2014,11,11), :amount => -53.25, :type => "expense", :tags => ["feed"], :description => "3 x 50lbs" } )
