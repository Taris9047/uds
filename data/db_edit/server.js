/* Server js */

const path = require( 'path' );
const getPort = require( 'get-port' );
const open = require( 'open' );
const express = require( 'express' );

// Create express application
const app = express();

// Set view engine as ejs
app.set('view engine', 'ejs');

// public directory to store assets
app.use(express.static( path.join( __dirname+'/public' ) ) );

// routes for app
app.get('/', function(req, res) {
  res.render('pad');
});

// Find available port, if not 8000 Then listen to server, then
// open main browser!
getPort( {port:8000} ).then(pt => {
  console.log(pt);
  const port = pt;
  const host = `http://127.0.0.1:${ port }`;
  app.listen( port, async () => {
    console.log( 'Express server started!' );
    await open( `${ host }` );
  });
});


