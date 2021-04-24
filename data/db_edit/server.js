/* Server js */

var express = require('express');
var app = express();

// Set view engine as ejs
app.set('view engine', 'ejs');

// public directory to store assets
app.use(express.static(__dirname+'/public'));

// routes for app
app.get('/', function(req, res) {
  res.render('pad');
})

// Listen to port 8000
var port = process.env.PORT || 8000;
app.listen(port);
