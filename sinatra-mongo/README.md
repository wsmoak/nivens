Nivens
======

Nivens keeps track of all the data from breeding and raising rabbits.

This is the initial incarnation -- a Ruby + Sinatra + mongoDB app -- where the data model and API emerged.

To run locally

- start mongoDB locally on the default port,
- add to ~/bash_profile:  export MONGOHQ_URL=mongodb://localhost:27017/nivens
- (be sure to open a new terminal window or otherwise re-load ~/.bash_profile)
- run bundle install
- and execute

$ ruby nivens.rb

Then visit:

http://localhost:4567/

Use the "New Rabbit" link to add a rabbit (twice), then return to the Home page and add a "New Litter".

After you have created a litter, you can record when the doe was exposed to the buck.

Once you have done this, click "View Schedule" from the Home page.

The schedule tells you when you should add a nestbox to the cage, and when to expect the doe to kindle.

Possible Features

- rabbit status page showing id, name, age, average weight of kits at X days (by doe for the buck), whether a doe is pregnant, etc.
- print out cage cards
- predict kindling date based on the doe's history
