using Toybox.Position as Position;
using Toybox.WatchUi as Ui;
using Toybox.Communications as Comm;
using Toybox.System as System;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian as Greg;

// Global variable for delegates
var selectedStop;
var stopSelectedFlag = false;

//var dummyStops = {distance=>16, x=>12504705, y=>55739628, id=>7202, name=>Vandt├Ñrnsvej (S├╕borg Hovedgade)}, {distance=>51, x=>12505739, y=>55739530, id=>320, name=>S├╕borg Hovedgade (Hagavej)}, {distance=>112, x=>12506090, y=>55740303, id=>291, name=>Christianeh├╕j (Hagavej)}, {distance=>119, x=>12504831, y=>55738469, id=>4705, name=>S├╕borg Hovedgade (Vandt├Ñrnsvej)}, {distance=>246, x=>12501874, y=>55740950, id=>7203, name=>Buddinge Skole (S├╕borg Hovedgade)}, {distance=>311, x=>12508445, y=>55737570, id=>319, name=>S├╕borg Torv (S├╕borg Hovedgade)};
//var dummyBoard = {};
module DepartureBoard
{
	class DepatureBoardClass
	{
		hidden var timer;
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
		var favouriteStops;
		hidden var stopsData;
		
		// Board related
		hidden var valuesToDisplay = 6;
		hidden var departureBoardData = new [valuesToDisplay];
		
		// Colors for transport labels
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

		// Timer related
		const TIMER_TRIGGER = 500;
		hidden var timeoutCounter = 0;
		hidden var timeoutEnabled = false;

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
			SM_ERROR_NO_CONNECTION,
			SM_ERROR_NO_POSITION,
			SM_ERROR_NO_STOPS,
			SM_ERROR_NO_PHONE,
			SM_DONE
		}

		// Constructor
		function initialize()
		{
		
			progressBarView = new Ui.ProgressBar(Ui.loadResource(Rez.Strings.StrWaitingForPosition),null);
			
			// Parse favourite stops from settings
	        favouriteStops = splitString(Application.getApp().getProperty("favouriteStops"),',');
		    timer = new Timer.Timer();

	        if(System.getDeviceSettings().phoneConnected == false)
	        {
	        	System.println("Phone not connected!");
				currentState = SM_ERROR_NO_PHONE;
	        }else
	        {
		        currentState = SM_GET_POSITION;
	        }

	        timer.start(method(:updateSM), TIMER_TRIGGER, true);
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

		// Sets the timeout for a number of timer ticks
		function setTimeout(timer_ticks)
		{
			timeoutEnabled = true;
			timeoutCounter = timer_ticks;
		}

		// Clears the timeout
		function clearTimeout()
		{
			timeoutEnabled = false;
			timeoutCounter = 0;
		}

		// Checks if timed out
		function checkTimeout()
		{
			if(timeoutEnabled && timeoutCounter == 0)
			{
				return true;
			}else
			{
				return false;
			}
		}
		
		function updateSM()
		{
			// Handle timeout countdown, if set
			if(timeoutEnabled && timeoutCounter != 0)
			{
				timeoutCounter = timeoutCounter  - 1;
			}

			if(currentState == SM_GET_POSITION)
			{
				if(Position.getInfo().accuracy == Position.QUALITY_NOT_AVAILABLE)
				{
					currentState = SM_ERROR_NO_POSITION;
					Ui.requestUpdate(); // Request update as we still are in the default view, theprogress bar hasn't been pushed yet				
				}else
				{
					Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:setCurrentLocation));			
					Ui.pushView(progressBarView, new ProgressBarViewInputDelegate(),Ui.SLIDE_IMMEDIATE);				
					currentState = SM_WAITING_FOR_POSITION;
					System.println("Getting position");

					// Enable timeout for getting position
					setTimeout(40); // Equals 20 seconds
				}
				
			// Await GPS position
			}else if(currentState == SM_WAITING_FOR_POSITION)
			{
				// If position has been acquired, request nearby stops
				if(positionAcquiredFlag)
				{
					clearTimeout();	// Reset the timeout
					System.println("Position acquired");
					progressBarView.setDisplayString(Ui.loadResource(Rez.Strings.StrWaitingForStops));
								
	        		System.println("Requesting stops");
	        		Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/stopsNearby?&format=json&coordX=" + "12504913" + "&coordY=" + "55739537" + "&maxRadius=1000&maxNumber=6", null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));
	        		//Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/stopsNearby?&format=json&coordX=" + myLat.toString() + "&coordY=" + myLon.toString() + "&maxRadius=1000&maxNumber=6", null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));
	        		currentState = SM_WAIT_STOPS_RESPONSE;
				}
				
				if(checkTimeout())
				{ 
					// Get rid of the progress bar view
					Ui.popView(Ui.SLIDE_IMMEDIATE);
					currentState = SM_ERROR_NO_POSITION;
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
						System.println("No stops to show");
						
						// Get rid of the progress bar view
						Ui.popView(Ui.SLIDE_IMMEDIATE);
						currentState = SM_ERROR_NO_STOPS; 
					}				
				}else if(responseCode != null)
				{
		            System.println("Failed to get stops. Response code: " + responseCode);
		            
		            // Get rid of the progress bar view
					Ui.popView(Ui.SLIDE_IMMEDIATE);
		            currentState = SM_ERROR_NO_CONNECTION;		
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
		    				selectedStop = stopsData[i];
		    				currentState = SM_REQUEST_BOARD; 
		    			}
		    		}
		    	}
		    	
		    	if (selectedStop == null)
		    	{
		    		System.println("Pushing picker");
					Ui.pushView(new StopChooser(stopsData), new StopChooserDelegate(stopsData), Ui.SLIDE_IMMEDIATE);
					currentState = SM_REQUEST_BOARD;				
		    	}
			}
			else if(currentState == SM_REQUEST_BOARD)
			{
				if($.stopSelectedFlag)
				{
					System.println("Stop selected: " + $.selectedStop.get("name"));
					var now = System.getClockTime();
			        var time = now.hour.toString() + "." + now.min.toString();        
			        var dateinfo = Greg.info(Time.now(), Time.FORMAT_SHORT);
			        var date = dateinfo.day.toString() + "." +  dateinfo.month.toString() + "." + dateinfo.year.toString();
			
					// Generate the URL
					//var url = "http://xmlopen.rejseplanen.dk/bin/rest.exe/departureBoard?&format=json&id=" + stop_id + "&date="+ date + "&time=" + time; // + "&useBus=" + use_bus

					System.println("Requesting board");		        		        
			        responseCode = null;
			        Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/departureBoard?&format=json&id=" + $.selectedStop.get("id") + "&date="+ date + "&time=" + time, null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));
			        
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

		            // Get rid of the progress bar view
					Ui.popView(Ui.SLIDE_IMMEDIATE);
		            currentState = SM_ERROR_NO_CONNECTION;
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
			else
			{
				// Stop the SM update and request update to display the error
				timer.stop();
			}
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
				var timeArray = splitString(departureBoardData[i].get(timeKey),':');
	       		
	       		var arrivalMoment = Greg.moment({:year => dateArray[2].toNumber()+2000,
	       		:month => dateArray[1].toNumber(),
	       		:day => dateArray[0].toNumber(),
	       		:hour => timeArray[0].toNumber(),
	       		:minute => timeArray[1].toNumber(),
	       		:second => 0});

	       		var diff_min = (arrivalMoment.subtract(now).value().toNumber() - System.getClockTime().timeZoneOffset)/60;
	       		       	
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
				dc.drawText(base_x_offset + icon_width + 5, base_y_offset + ((icon_height + icon_distance) * layout_line_nr) + icon_height/2-3, Gfx.FONT_TINY, truncateStopName(destination), Gfx.TEXT_JUSTIFY_LEFT);
			}else
			{
				dc.drawText(base_x_offset + icon_width + 5, base_y_offset + ((icon_height + icon_distance) * layout_line_nr) + icon_height/2-3, Gfx.FONT_TINY, destination, Gfx.TEXT_JUSTIFY_LEFT);
			}
			
		}
		
		// Returns an array containing the substrings of the provided string, separated by separator
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

	// Intelligently truncates stop names
	function truncateStopName(name)
	{
		var bracketIndex = name.find("(");
		if(bracketIndex != null && bracketIndex < 15)
		{
			return name.substring(0,bracketIndex-1);
		}else
		{
			return name.substring(0,15);
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
			Ui.popView(Ui.SLIDE_IMMEDIATE);
		}
	}	
}