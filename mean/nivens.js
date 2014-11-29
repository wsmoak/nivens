
// see http://mongodb.github.io/node-mongodb-native/api-articles/nodekoarticle1.html
var MongoClient = require('mongodb').MongoClient;
var rabbits;
MongoClient.connect("mongodb://localhost:27017/nivens", function(err,db) {
  if(!err) {
    console.log("Connected to nivens db!");
    rabbits = db.collection('rabbits');
  } else {
    console.log("Error: " + err);
  }
});

var express = require('express');

var app = express();

app.set('port', process.env.EXPRESS_PORT || 3000);

app.use(express.static(__dirname + '/public'));

https://github.com/expressjs/body-parser
//app.use(require('body-parser').json());
var bodyParser = require('body-parser');
var jsonParser = bodyParser.json();

app.get('/api/rabbit', function(req,res) {
  res.type('application/json');
  rabbits.find().toArray(function(err, items) {
    res.send(items);  
  });
});

app.post('/api/rabbit', jsonParser, function(req,res) {
  res.type('application/json');
  console.log("adding rabbit" + req.body);
  rabbits.insert(req.body, 
      function() { 
        console.log("rabbit insert callback")
        res.send({"ok":true});
        });
});

  app.listen(app.get('port'), function(){
console.log( 'Express started on http://localhost:' +
        app.get('port') + '; press Ctrl-C to terminate.' );
    });