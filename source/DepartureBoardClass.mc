using Toybox.Position as Position;
using Toybox.WatchUi as Ui;
using Toybox.Communications as Comm;
using Toybox.System as System;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian as Greg;

// Global variable for delegates
var selectedStop;

class DepatureBoard
{
	hidden var timer;
	hidden var stateTimeout;
	hidden var currentState;
	
	// Views
	hidden var progressBarView;

	// Stores the retrieved position
	hidden var myLat; 
	hidden var myLon;
	hidden var positionAcquiredFlag = false;

	// Stores the retrieved web data
	hidden var responseCode;
	hidden var responseData;
	
	// Stops related
	var favouriteStops;	//TODO: To be autofilled from settings
	hidden var stopsData;
	
	// Board related
	hidden var valuesToDisplay = 6;
	hidden var departureBoardData = new [valuesToDisplay];
		
	hidden var drawingContext;


	const LABEL_COLOR_BUS_NORMAL = Gfx.COLOR_YELLOW;
	const LABEL_COLOR_BUS_A = Gfx.COLOR_RED;
	const LABEL_COLOR_BUS_E = Gfx.COLOR_GREEN;
	const LABEL_COLOR_BUS_S = Gfx.COLOR_BLUE;	
	const LABEL_COLOR_LOCAL_TRAIN = 0x000055;
	const LABEL_COLOR_REG_TRAIN = 0x00AA00;
	const LABEL_COLOR_S_TRAIN_A = Gfx.COLOR_BLUE;
	const LABEL_COLOR_S_TRAIN_B = Gfx.COLOR_DK_GREEN;
	const LABEL_COLOR_S_TRAIN_BX = Gfx.COLOR_GREEN;
	const LABEL_COLOR_S_TRAIN_C = Gfx.COLOR_ORANGE;
	const LABEL_COLOR_S_TRAIN_E = Gfx.COLOR_PURPLE;
	const LABEL_COLOR_S_TRAIN_F = Gfx.COLOR_YELLOW;
	const LABEL_COLOR_S_TRAIN_H = Gfx.COLOR_RED;

	enum
	{
		SM_GET_POSITION,
		SM_WAITING_FOR_POSITION,
		SM_REQUEST_NEARBY_STOPS,
		SM_WAIT_STOPS_RESPONSE,
		SM_DETERMINE_STOP,
		SM_REQUEST_BOARD,
		SM_WAIT_BOARD_RESPONSE,
		SM_SHOW_BOARD,
		SM_DELAY_BEFORE_REQUEST,
		SM_ERROR,
		SM_DONE
	}

	function initialize(dc)
	{
		drawingContext = dc;
	
		currentState = SM_GET_POSITION;
		
		progressBarView = new Ui.ProgressBar(Ui.loadResource(Rez.Strings.StrWaitingForPosition),null);    	
		
		//timer = new Timer.Timer(); 
        //timer.start(method(:updateSM), 500, true);
        favouriteStops = splitString(Application.getApp().getProperty("favouriteStops"),',');
        
        for(var i=0;i<favouriteStops.size();i++)
        {
        	System.println("Returned: " + favouriteStops[i]);
        }


        System.exit();
	}

	// Callback function for position request
	function setCurrentLocation(info)
	{
		positionAcquiredFlag = true;
		myLat = (info.position.toDegrees()[0] * 1000000).toNumber();
		myLon = (info.position.toDegrees()[1] * 1000000).toNumber();
	}
	
	// Callback function for web request
	function webRequestCallback(rc, data)
	{
		responseCode = rc;
		responseData = data;		
	}
	
	function getSMState()
	{
		return currentState; 
	}
	
	function updateSM()
	{
		if(currentState == SM_GET_POSITION)
		{
			//Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:setCurrentLocation));		
			
			Ui.pushView(progressBarView, new ProgressBarViewInputDelegate(),Ui.SLIDE_IMMEDIATE);
			stateTimeout = 20;
			currentState = SM_WAITING_FOR_POSITION;
			System.println("Getting position");
			
			// DEBUG
			positionAcquiredFlag = true;
			
		// Await GPS position
		}else if(currentState == SM_WAITING_FOR_POSITION)
		{
			// If position has been acquired, request nearby stops
			if(positionAcquiredFlag)
			{
				System.println("Position acquired");
				progressBarView.setDisplayString(Ui.loadResource(Rez.Strings.StrWaitingForStops));
							
        		System.println("Requesting stops");
        		Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/stopsNearby?&format=json&coordX=" + "12504913" + "&coordY=" + "55739537" + "&maxRadius=1000&maxNumber=6", null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));
        		//Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/stopsNearby?&format=json&coordX=" + myLat.toString() + "&coordY=" + myLon.toString() + "&maxRadius=1000&maxNumber=6", null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));
        		currentState = SM_WAIT_STOPS_RESPONSE;
			}
			
			if(stateTimeout == 0)
			{
				currentState = SM_ERROR;
			}
			
		
		}
		// Await web request response
		else if(currentState == SM_WAIT_STOPS_RESPONSE)
		{
			if(responseCode == 200)
			{
				// Test if we have stops nearby
				if(responseData.get("LocationList").hasKey("StopLocation"))
				{
					System.println("Stops data received");
					currentState = SM_DETERMINE_STOP;													
				}else
				{
					//TODO: push view
					System.println("No stops to show");
					
					var errorView = new ErrorView();
					errorView.setErrorTypeNoStops();
					Ui.pushView(errorView, new ErrorViewDelegate(), Ui.SLIDE_IMMEDIATE);					
					currentState = SM_ERROR; 
				}				
			}else if(responseCode != null)
			{
	        	//TODO: Show failed connection message
	            System.println("Failed to get stops. Response code: " + responseCode);
	            
				var errorView = new ErrorView();
				errorView.setErrorTypeNoConnection();
				Ui.pushView(errorView, new ErrorViewDelegate(), Ui.SLIDE_IMMEDIATE);

	            currentState = SM_ERROR;		
			}						
		}
		
		// Determine the stop to show the departure board for
		else if(currentState == SM_DETERMINE_STOP)
		{
			stopsData = responseData.get("LocationList").get("StopLocation");
			for(var i=0; i < stopsData.size();i++)
	    	{
	    		for(var j=0; j < favouriteStops.size(); j++)
	    		{
	    			if(stopsData[i].get("id").equals(favouriteStops[j]))
	    			{
	    				System.println("Found one of the favourites: " + favouriteStops[j]);
	    				selectedStop = stopsData[i].get("id");
	    				currentState = SM_REQUEST_BOARD; 
	    			}
	    		}
	    	}
	    	
	    	if (selectedStop == null)
	    	{
	    		System.println("Pushing picker");
				Ui.pushView(new StopPicker(stopsData), new StopPickerDelegate(), Ui.SLIDE_IMMEDIATE);
				currentState = SM_REQUEST_BOARD;				
	    	}
		}
		else if(currentState == SM_REQUEST_BOARD)
		{
			if(selectedStop != null)
			{
				System.println("Stop selected: " + selectedStop);
				var now = System.getClockTime();
		        var time = now.hour.toString() + "." + now.min.toString();        
		        var dateinfo = Greg.info(Time.now(), Time.FORMAT_SHORT);
		        var date = dateinfo.day.toString() + "." +  dateinfo.month.toString() + "." + dateinfo.year.toString();
		
				// Generate the URL
				//var url = "http://xmlopen.rejseplanen.dk/bin/rest.exe/departureBoard?&format=json&id=" + stop_id + "&date="+ date + "&time=" + time; // + "&useBus=" + use_bus

				System.println("Requesting board");		        		        
		        responseCode = null;
		        Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/departureBoard?&format=json&id=" + selectedStop + "&date="+ date + "&time=" + time, null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));
		        
		        progressBarView.setDisplayString(Ui.loadResource(Rez.Strings.StrWaitingForBoard));
		        currentState = SM_WAIT_BOARD_RESPONSE;	
			}
		}
		else if(currentState == SM_WAIT_BOARD_RESPONSE)
		{
	     	// Check the response code
	        if (responseCode == 200) {     
				System.println("Board received");
	        	var values = responseData.get("DepartureBoard").get("Departure");        			
				if(values.size() < valuesToDisplay)
				{
					valuesToDisplay = values.size();		
				}
				
				for(var i=0; i < valuesToDisplay; i++)
				{
					departureBoardData[i] = values[i];
				}
								
				
				currentState = SM_SHOW_BOARD;
	        } else if(responseCode != null) {	        	
	            System.println("Failed to retrive board. Response code: " + responseCode);

				var errorView = new ErrorView();
				errorView.setErrorTypeNoConnection();
				Ui.pushView(errorView, new ErrorViewDelegate(), Ui.SLIDE_IMMEDIATE);

	            currentState = SM_ERROR;
	        }			
		}
		else if(currentState == SM_SHOW_BOARD)
		{
			Ui.popView(Ui.SLIDE_IMMEDIATE);
			//Ui.requestUpdate();
			currentState = SM_DONE;			
		}
		else if(currentState == SM_DONE)
		{
			//Ui.requestUpdate();
		}
		else if(currentState == SM_ERROR)
		{}
	}
	
	function drawDepartureBoard(dc)
	{
		System.println("Drawing departure board");
	   	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
   		dc.clear();
   	
       	for(var i=0;i<departureBoardData.size();i++)
       	{
       		var now = Time.now();
       		var dateKey = "date";
       		var timeKey = "time";
       		
       		//System.println(departureBoardData[i]);
       		
       		// Calculate time to transport
       		if(departureBoardData[i].hasKey("rtTime"))
       		{
				timeKey = "rtTime"; 
			}
			
			if(departureBoardData[i].hasKey("rtDate"))
       		{
				dateKey = "rtDate";
			}

       		// Parse time and date from response
       		var dateArray = splitString(departureBoardData[i].get(dateKey),'.');
			var timeArray = splitString(departureBoardData[i].get(timeKey),'.');
       		
       		var arrivalMoment = Greg.moment({:year => dateArray[2].toNumber()+2000,
       		:month => dateArray[1].toNumber(),
       		:day => dateArray[0].toNumber(),
       		:hour => timeArray[0].toNumber(),
       		:minute => timeArray[1].toNumber(),
       		:second => 0});

       		/*
       		System.println("year: " + departureBoardData[i].get(dateKey).substring(6,8).toNumber()+2000);
       		System.println("month: " + departureBoardData[i].get(dateKey).substring(3,5).toNumber());
       		System.println("day: " + departureBoardData[i].get(dateKey).substring(0,2).toNumber());
       		System.println("hour: " + departureBoardData[i].get(timeKey).substring(0,2).toNumber());
       		System.println("minute: " + departureBoardData[i].get(timeKey).substring(3,5).toNumber());
       		
   			var arrivalMoment = Greg.moment({:year => departureBoardData[i].get(dateKey).substring(6,8).toNumber()+2000,
       		:month => departureBoardData[i].get(dateKey).substring(3,5).toNumber(),
       		:day => departureBoardData[i].get(dateKey).substring(0,2).toNumber(),
       		:hour => departureBoardData[i].get(timeKey).substring(0,2).toNumber(),
       		:minute => departureBoardData[i].get(timeKey).substring(3,5).toNumber(),
       		:second => 0});
       		*/
       		
       		/* Fake data
       		var arrivalMoment = Greg.moment({:year => 2016,
       		:month => 8,
       		:day => 8,
       		:hour => 10,
       		:minute => 0,
       		:second => 0});
       		*/

       		var diff_min = (arrivalMoment.subtract(now).value().toNumber() - System.getClockTime().timeZoneOffset)/60;
       		
			//System.println("NOW: " + now.value().toString());
       		//System.println("ARRIVAL: " + arrivalMoment.value().toString());
       		//System.println("DIFF: " + diff_min);
       	
       		drawDepartureTableLine(dc, i, departureBoardData[i].get("name"), departureBoardData[i].get("finalStop"), diff_min); 
       	}	       	
	}
	
	// Function used to draw a specific departure board line	
	function drawDepartureTableLine(dc, layout_line_nr, line, destination, minutes) 
	{
		var base_x_offset = 5;
		var base_y_offset = 6;
		var icon_distance = 6;
		var icon_width = 45;
		var icon_height = 27;
		
		var time_text = generateReadableMinutes(minutes); 
		
		// Draw the line icon
		if(line.find("Bus") != null)
		{
			if(line.find("A"))
			{
				dc.setColor(LABEL_COLOR_BUS_A, Gfx.COLOR_TRANSPARENT);
			}else if(line.find("E"))
			{
				dc.setColor(LABEL_COLOR_BUS_E, Gfx.COLOR_TRANSPARENT);
			}else if(line.find("S"))
			{
				dc.setColor(LABEL_COLOR_BUS_S, Gfx.COLOR_TRANSPARENT);
			}else
			{
				dc.setColor(LABEL_COLOR_BUS_NORMAL, Gfx.COLOR_TRANSPARENT);
			}
			dc.fillRoundedRectangle(base_x_offset,base_y_offset + ((icon_height + base_y_offset) * layout_line_nr),icon_width,icon_height,3);
			
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT); 
			dc.drawText(base_x_offset + icon_width/2, base_y_offset + ((icon_height + icon_distance) * layout_line_nr - 1), Gfx.FONT_MEDIUM, line.substring(4,line.length()), Gfx.TEXT_JUSTIFY_CENTER);
		}else if(line.find("Lokalbane") != null)
		{
			dc.setColor(LABEL_COLOR_LOCAL_TRAIN, Gfx.COLOR_TRANSPARENT);
			dc.fillRoundedRectangle(base_x_offset,base_y_offset + ((icon_height + base_y_offset) * layout_line_nr),icon_width,icon_height,3);
			
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT); 
			dc.drawText(base_x_offset + icon_width/2, base_y_offset + ((icon_height + icon_distance) * layout_line_nr - 1), Gfx.FONT_MEDIUM, "L", Gfx.TEXT_JUSTIFY_CENTER);
		}else if(line.find("RE") != null)
		{
			dc.setColor(LABEL_COLOR_REG_TRAIN, Gfx.COLOR_TRANSPARENT);
			dc.fillRoundedRectangle(base_x_offset,base_y_offset + ((icon_height + base_y_offset) * layout_line_nr),icon_width,icon_height,3);
			
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT); 
			dc.drawText(base_x_offset + icon_width/2, base_y_offset + ((icon_height + icon_distance) * layout_line_nr - 1), Gfx.FONT_MEDIUM, "RE", Gfx.TEXT_JUSTIFY_CENTER);			
		}else
		{
			if(line.find("A") != null)
			{
				dc.setColor(LABEL_COLOR_S_TRAIN_A, Gfx.COLOR_TRANSPARENT);
			}else if(line.find("B") != null)
			{
				dc.setColor(LABEL_COLOR_S_TRAIN_B, Gfx.COLOR_TRANSPARENT);
			}else if(line.find("Bx") != null)
			{
				dc.setColor(LABEL_COLOR_S_TRAIN_BX, Gfx.COLOR_TRANSPARENT);
			}else if(line.find("C") != null)
			{
				dc.setColor(LABEL_COLOR_S_TRAIN_C, Gfx.COLOR_TRANSPARENT);
			}else if(line.find("E") != null)
			{
				dc.setColor(LABEL_COLOR_S_TRAIN_E, Gfx.COLOR_TRANSPARENT);
			}else if(line.find("F") != null)
			{
				dc.setColor(LABEL_COLOR_S_TRAIN_F, Gfx.COLOR_TRANSPARENT);
			}else if(line.find("H") != null)
			{
				dc.setColor(LABEL_COLOR_S_TRAIN_H, Gfx.COLOR_TRANSPARENT);
			}
			dc.fillRoundedRectangle(base_x_offset,base_y_offset + ((icon_height + base_y_offset) * layout_line_nr),icon_width,icon_height,3);
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT); 
			dc.drawText(base_x_offset + icon_width/2, base_y_offset + ((icon_height + icon_distance) * layout_line_nr - 1), Gfx.FONT_MEDIUM, line, Gfx.TEXT_JUSTIFY_CENTER);		
		}
		
		// Draw strings common for bus and train
		dc.drawText(base_x_offset + icon_width + 5, base_y_offset + ((icon_height + icon_distance) * layout_line_nr - 4), Gfx.FONT_TINY, time_text, Gfx.TEXT_JUSTIFY_LEFT);	
		// Check if string is too long for screen size
		if(destination.length() > 15)
		{
			dc.drawText(base_x_offset + icon_width + 5, base_y_offset + ((icon_height + icon_distance) * layout_line_nr) + icon_height/2-3, Gfx.FONT_TINY, destination.substring(0,15), Gfx.TEXT_JUSTIFY_LEFT);
		}else
		{
			dc.drawText(base_x_offset + icon_width + 5, base_y_offset + ((icon_height + icon_distance) * layout_line_nr) + icon_height/2-3, Gfx.FONT_TINY, destination, Gfx.TEXT_JUSTIFY_LEFT);
		}
		
	}
	
	function splitString(string, separator)
	{
		var items = [];
		var str = string.toCharArray();
		var lastSep = 0;

		for(var i=0; i<str.size(); i++)
		{
			if(str[i] == separator || i == str.size() - 1)
			{			
				if(i == str.size() - 1)
				{
					items.add(string.substring(lastSep,i+1));	
				}else
				{
					items.add(string.substring(lastSep,i));	
					lastSep = i+1;
				}				
			}
		}

		return items;
	}

	// Returns a string in a readable hr min format
	function generateReadableMinutes(minutes)
	{
		if(minutes > 59)
		{
			var hours = minutes / 60;
			var rem_minutes  = minutes % 60;
			return hours.toNumber().toString() + Ui.loadResource(Rez.Strings.StrHrId) + " " + rem_minutes.toString() + Ui.loadResource(Rez.Strings.StrMinId);	
		}else
		{
			return minutes + Ui.loadResource(Rez.Strings.StrMinId);
		}
	}
}

class ProgressBarViewInputDelegate extends Ui.BehaviorDelegate
{
	function initialize()
	{
		BehaviorDelegate.initialize();
	}

	function onBack()
	{
		System.exit();
	}
}