using Toybox.Application as App;
using Toybox.Position as Position;

// Globals

var db;

var maxNumberOfStops = 5;
var noStopsNearby = null;
var selectedStop = null;
var stopsData = {};

var valuesToDisplay = 6;
var departureBoardData = new [valuesToDisplay];

var favouriteStops = ["292","471"];

class DepartureBoardApp extends App.AppBase {

	var waitingForDataView;
	var departureBoardView;

    function initialize() {
        AppBase.initialize();
        
    }

    // onStart() is called on application start up
    function onStart(state) {
    	db = new DepartureBoard();
    }

    // onStop() is called when your application is exiting
    function onStop(state) 
    {
    	Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    // Return the initial view of your application here
    function getInitialView()
    {
    	//departureBoardView = new DepartureBoardView();
        //return [ departureBoardView ];
        waitingForDataView = new WaitingForDataView();
        return [waitingForDataView];
    }

}