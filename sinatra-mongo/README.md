Nivens
======

Nivens keeps track of all the data from breeding and raising rabbits.

This is the initial incarnation -- a Ruby + Sinatra + mongoDB app -- where the data model and API emerged.

To run locally, start mongoDB on the default port and execute

$ ruby nivens.rb

Then visit:

http://localhost:4000/rabbit/create

To see a list of your rabbits, visit:

http://localhost:4000/rabbit/all

Once you have added a pair of rabbits, visit:

http://localhost:4000/litter/create

After you have created a litter, you can record when the doe was exposed to the buck.

Once you have done this, visit:

http://localhost:4567/schedule

The schedule tells you when you should add a nestbox to the cage, and when to expect the doe to kindle.

Possible Features

- rabbit status page showing id, name, age, average weight of kits at X days (by doe for the buck), whether a doe is pregnant, etc.
- print out cage cards
- predict kindling date based on the doe's history
