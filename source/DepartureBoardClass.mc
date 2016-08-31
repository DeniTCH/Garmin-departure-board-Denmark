using Toybox.Position as Position;
using Toybox.WatchUi as Ui;
using Toybox.Communications as Comm;
using Toybox.System as System;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian as Greg;

// Global variable for delegates
var selectedStop;
var stopSelectedFlag = false;

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
		const LABEL_COLOR_BUS_NORMAL = 0xFDAE00;
		const LABEL_COLOR_BUS_A = 0xB8211C;
		const LABEL_COLOR_BUS_E = 0x00B26B;
		const LABEL_COLOR_BUS_S = 0x0065AA;	
		const LABEL_COLOR_BUS_X = 0x0000AA;	
		const LABEL_COLOR_BUS_NB = 0xAAAAAA;
		const LABEL_COLOR_HAVNEBUS = 0x1A4F6C;
		const LABEL_COLOR_BUS_TOGBUS= Gfx.COLOR_WHITE;
		const LABEL_COLOR_LOCAL_TRAIN = 0x50B748;
		const LABEL_COLOR_REG_TRAIN = 0x00AA00;
		const LABEL_COLOR_IC_TRAIN = 0xEF4130;
		const LABEL_COLOR_S_TRAIN_A = 0x00B2EF;
		const LABEL_COLOR_S_TRAIN_B = 0x50B848;
		const LABEL_COLOR_S_TRAIN_BX = 0xA6CE39;
		const LABEL_COLOR_S_TRAIN_C = 0xF58A1F;
		const LABEL_COLOR_S_TRAIN_E = 0x7670B2;
		const LABEL_COLOR_S_TRAIN_F = 0xFFC20E;
		const LABEL_COLOR_S_TRAIN_H = 0xEF4130;
		//TODO: Replace METRO with M1 and M2 + circle
		//TODO: Add EC, ICL IR and ØR colors
		const LABEL_COLOR_METRO_M1 = 0x008265;
		const LABEL_COLOR_METRO_M2 = 0xFFC425;

		const LABEL_COLOR_METRO = 0xAA0000;
		const LABEL_COLOR_FERRY = 0x000055;

		// Font
		hidden var customFont = null;

		// Timer related
		const TIMER_TRIGGER = 500;
		hidden var timeoutCounter = 0;
		hidden var timeoutEnabled = false;

		const TIMEOUT_10_SECONDS = 20;

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
	        	//System.println("Phone not connected!");
				currentState = SM_ERROR_NO_PHONE;
	        }else
	        {
		        currentState = SM_GET_POSITION;
	        }

	        customFont = Ui.loadResource(Rez.Fonts.atb);

	        timer.start(method(:updateSM), TIMER_TRIGGER, true);
		}

		// Callback function for position request
		function setCurrentLocation(info)
		{
			//System.println("GPS Accuracy:" + info.accuracy);
			if(info.accuracy > 1)
			{
				Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:setCurrentLocation));			
				positionAcquiredFlag = true;
				myLat = (info.position.toDegrees()[0] * 1000000).toNumber();
				myLon = (info.position.toDegrees()[1] * 1000000).toNumber();
			}
		}
		
		// Callback function for web request
		function webRequestCallback(rc, data)
		{
			responseCode = rc;
			responseData = data;		
		}
		
		// Returns current SM state
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
		
		// The main state machine handler
		function updateSM()
		{
			// Handle timeout countdown, if set
			if(timeoutEnabled && timeoutCounter != 0)
			{
				timeoutCounter = timeoutCounter  - 1;
			}

			if(currentState == SM_GET_POSITION)
			{
				Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:setCurrentLocation));			
				Ui.pushView(progressBarView, new ProgressBarViewInputDelegate(),Ui.SLIDE_IMMEDIATE);				
				currentState = SM_WAITING_FOR_POSITION;
				//System.println("Getting position");

				// Enable timeout for getting position
				setTimeout(TIMEOUT_10_SECONDS); // Equals 10 seconds
				
			// Await GPS position
			}else if(currentState == SM_WAITING_FOR_POSITION)
			{
				// If position has been acquired, request nearby stops
				if(positionAcquiredFlag)
				{
					clearTimeout();	// Reset the timeout
					//System.println("Position acquired");
					progressBarView.setDisplayString(Ui.loadResource(Rez.Strings.StrWaitingForStops));
								
	        		//System.println("Requesting stops");
	        		
	        		// Tolstojs Alle
	        		//Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/stopsNearby?&format=json&coordX=" + "12509917" + "&coordY=" + "55739763" + "&maxRadius=1000" + Application.getApp().getProperty("useTrain") + "&maxNumber=6", null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));	        		
	        		
	        		// Rønne havn
	        		//Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/stopsNearby?&format=json&coordX=" + "14691660" + "&coordY=" + "55100244" + "&maxRadius=1000" + Application.getApp().getProperty("useTrain") + "&maxNumber=6", null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));

	        		// Rødby havn	        		
	        		//Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/stopsNearby?&format=json&coordX=" + "11353111" + "&coordY=" + "54657359" + "&maxRadius=1000" + Application.getApp().getProperty("useTrain") + "&maxNumber=6", null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));

					// Lyngby st.
					//Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/stopsNearby?&format=json&coordX=" + "12502923" + "&coordY=" + "55768319" + "&maxRadius=1000" + Application.getApp().getProperty("useTrain") + "&maxNumber=6", null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));

					// Svanemøllen st.
					//Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/stopsNearby?&format=json&coordX=" + "12576676" + "&coordY=" + "55715771" + "&maxRadius=1000" + Application.getApp().getProperty("useTrain") + "&maxNumber=6", null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));					

	        		// Normal
			        Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/stopsNearby?&format=json&coordX=" + myLat.toString() + "&coordY=" + myLon.toString() + "&maxRadius=" + Application.getApp().getProperty("searchRadius") + "&maxNumber=6", null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));					


	        		currentState = SM_WAIT_STOPS_RESPONSE;
				}

				// If timed out either use the last known position, if such is not available, then show error
				if(checkTimeout())
				{ 
					// Disable GPS
					Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:setCurrentLocation));
					if(Position.getInfo().accuracy == Position.QUALITY_LAST_KNOWN)
					{
						positionAcquiredFlag = 1;
						myLat = (Position.getInfo().position.toDegrees()[0] * 1000000).toNumber();
						myLon = (Position.getInfo().position.toDegrees()[1] * 1000000).toNumber();
						//System.println(myLat + " " + myLon);
					}else if(Position.getInfo().accuracy == Position.QUALITY_NOT_AVAILABLE)
					{
						// Show error
						Ui.popView(Ui.SLIDE_IMMEDIATE);
						currentState = SM_ERROR_NO_POSITION;
					}
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
						//System.println("Stops data received");
						currentState = SM_DETERMINE_STOP;													
					}else
					{
						//System.println("No stops to show");
						
						// Get rid of the progress bar view
						Ui.popView(Ui.SLIDE_IMMEDIATE);
						currentState = SM_ERROR_NO_STOPS; 
					}				
				}else if(responseCode != null)
				{
		            //System.println("Failed to get stops. Response code: " + responseCode);
		            
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
		    			if(stopsData[i].get("id").toString().equals(favouriteStops[j].toString()))
		    			{
		    				System.println("Match: " + stopsData[i].get("id").toString() + "=" + favouriteStops[j].toString());
		    				selectedStop = stopsData[i];
		    				currentState = SM_REQUEST_BOARD; 
		    				$.stopSelectedFlag = true;
		    				break;
		    			}
		    		}
		    	}
		    	
		    	if (selectedStop == null)
		    	{
		    		//System.println("Pushing picker");
					Ui.pushView(new StopChooser(stopsData), new StopChooserDelegate(stopsData), Ui.SLIDE_IMMEDIATE);
					currentState = SM_REQUEST_BOARD;				
		    	}
			}
			else if(currentState == SM_REQUEST_BOARD)
			{
				if($.stopSelectedFlag)
				{
					//System.println("Stop selected: " + $.selectedStop.get("name"));
					var now = System.getClockTime();
			        var time = now.hour.toString() + "." + now.min.toString();        
			        var dateinfo = Greg.info(Time.now(), Time.FORMAT_SHORT);
			        var date = dateinfo.day.toString() + "." +  dateinfo.month.toString() + "." + dateinfo.year.toString();
			
					// Generate the URL
					//var url = "http://xmlopen.rejseplanen.dk/bin/rest.exe/departureBoard?&format=json&id=" + stop_id + "&date="+ date + "&time=" + time; // + "&useBus=" + use_bus

					//System.println("Requesting board");		        		        
			        responseCode = null;
			        ////System.println("http://xmlopen.rejseplanen.dk/bin/rest.exe/departureBoard?&format=json&id=" + $.selectedStop.get("id") + "&date="+ date + "&time=" + time);
			        Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/departureBoard?&format=json&id=" + $.selectedStop.get("id") + "&date="+ date + "&time=" + time + generateTransportShowSettings(), null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));
			     	// For debug:
			     	//Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/departureBoard?&format=json&id=008600432" + "&date="+ date + "&time=" + time + generateTransportShowSettings(), null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));
			    	//Comm.makeWebRequest("http://xmlopen.rejseplanen.dk/bin/rest.exe/departureBoard?&format=json&id=008600840" + "&date=22.08.2016&time=05:35" + generateTransportShowSettings(), null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:webRequestCallback));
			        
			        progressBarView.setDisplayString(Ui.loadResource(Rez.Strings.StrWaitingForBoard));
			        currentState = SM_WAIT_BOARD_RESPONSE;	
				}
			}
			else if(currentState == SM_WAIT_BOARD_RESPONSE)
			{
		     	// Check the response code
		        if (responseCode == 200) {     
					//System.println("Board received");
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
		            //System.println("Failed to retrive board. Response code: " + responseCode);

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
			//System.println("Drawing departure board");
		   	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
	   		dc.clear();

	   		//System.println(departureBoardData);

	       	for(var i=0;i<departureBoardData.size();i++)
	       	{
	       		if(departureBoardData[i] != null)
	       		{
		       		var now = Time.now();
		       		var dateKey = "date";
		       		var timeKey = "time";
		       		
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
		       		       	
		       		drawDepartureTableLine(dc, i,departureBoardData[i].get("type"), departureBoardData[i].get("name"), departureBoardData[i].get("finalStop"), diff_min); 
		       	}
	       	}	       	
		}
		
		// Function used to draw a specific departure board line	
		function drawDepartureTableLine(dc, layoutLineNr,type, line, destination, minutes) 
		{
			var baseXOffset = 5;
			var baseYOffset = 6;
			var iconDistance = 6;
			var iconWidth = 45;
			var iconHeight = 27;
			
			var time_text = generateReadableMinutes(minutes); 

			var labelColor = Gfx.COLOR_WHITE;
			var labelTextColor = Gfx.COLOR_WHITE;
			var labelText = "";
			
			if(type.equals("IC"))
			{
				labelColor = LABEL_COLOR_IC_TRAIN; 
				labelText = "IC";
			}
			else if(type.equals("LYN"))
			{
				labelColor = LABEL_COLOR_IC_TRAIN; 
				labelText = "ICL";
			}
			else if(type.equals("REG"))
			{
				labelColor = LABEL_COLOR_REG_TRAIN; 
				labelText = "RE";
			}
			else if(type.equals("S"))
			{
				if(line.find("A") != null)
				{
					labelColor = LABEL_COLOR_S_TRAIN_A; 
				}
				else if(line.find("B") != null)
				{
					labelColor = LABEL_COLOR_S_TRAIN_B; 
				}
				else if(line.find("Bx") != null)
				{
					labelColor = LABEL_COLOR_S_TRAIN_BX; 
				}
				else if(line.find("C") != null)
				{
					labelColor = LABEL_COLOR_S_TRAIN_C; 
				}
				else if(line.find("E") != null)
				{
					labelColor = LABEL_COLOR_S_TRAIN_E; 
				}
				else if(line.find("F") != null)
				{
					labelColor = LABEL_COLOR_S_TRAIN_F; 
				}
				else if(line.find("H") != null)
				{
					labelColor = LABEL_COLOR_S_TRAIN_H; 
				}
				
				labelText = line;				
			}
			else if(type.equals("TOG"))
			{
				if(line.find("RE") != null)
				{
					labelColor = LABEL_COLOR_REG_TRAIN; 
					labelText = "Ø";
				}
				else if(line.find("EC") != null)
				{
					labelColor = LABEL_COLOR_REG_TRAIN; 
					labelText = "EC";
				}
				else if(line.find("Togbus") != null) //FIXME: Special case
				{
					labelColor = LABEL_COLOR_BUS_TOGBUS; 
					labelText = "TB";
				}
				else
				{
					labelColor = LABEL_COLOR_LOCAL_TRAIN; 
					labelText = "L";
				}
			}
			else if(type.equals("BUS"))
			{
				if(line.find("A"))
				{
					labelColor = LABEL_COLOR_BUS_A; 
				}
				else if(line.find("E"))
				{
					labelColor = LABEL_COLOR_BUS_E; 
				}
				else
				{
					labelColor = LABEL_COLOR_BUS_NORMAL; 
				}
				labelText = line.substring(4,line.length());
			}
			else if(type.equals("EXB"))
			{
				if(line.find("X Bus") != null)
				{
					labelColor = LABEL_COLOR_BUS_X; 
					labelText = line.substring(6,line.length());
				}
				else if(line.find("S"))
				{
					labelColor = LABEL_COLOR_BUS_S; 
					labelText = line.substring(4,line.length());
				}
				else if(line.find("Bus") != null)
				{
					labelColor = LABEL_COLOR_BUS_NORMAL; 
					labelText = line.substring(4,line.length());

				}
			}
			else if(type.equals("NB"))
			{
				labelColor = LABEL_COLOR_BUS_NB; 
				labelText = line.substring(7,line.length());
			}
			else if(type.equals("TB"))
			{
				if(line.find("Havnebus") != null)
				{
					labelColor = LABEL_COLOR_BUS_NORMAL; 
					labelText = line.substring(9,line.length());
				}
				else if(line.find("Bybus") != null)
				{
					if(line.find("A"))
					{
						labelColor = LABEL_COLOR_BUS_A; 
					}
					else
					{
						labelColor = LABEL_COLOR_BUS_NORMAL; 
					}
					
					labelText = line.substring(6,line.length());
				}
			}
			else if(type.equals("F"))
			{
				labelColor = LABEL_COLOR_FERRY; 			
			}
			else if(type.equals("M"))
			{
				labelColor = LABEL_COLOR_METRO; 
				labelText = line.substring(6,line.length());
			}

			// Draw label and label text except for when it is a ferry or a train bus, then draw bitmap
			dc.setColor(labelColor, Gfx.COLOR_TRANSPARENT);
			dc.fillRoundedRectangle(baseXOffset,baseYOffset + ((iconHeight + baseYOffset) * layoutLineNr),iconWidth,iconHeight,3);			

			if(type.equals("F") == false)
			{
				dc.setColor(labelTextColor, Gfx.COLOR_TRANSPARENT);
				dc.drawText(baseXOffset + iconWidth/2, baseYOffset + ((iconHeight + iconDistance) * layoutLineNr - 1), customFont, labelText, Gfx.TEXT_JUSTIFY_CENTER);
			}
			else if(line.find("Togbus") != null)
			{
				dc.drawRoundedRectangle(baseXOffset,baseYOffset + ((iconHeight + baseYOffset) * layoutLineNr),iconWidth,iconHeight,3);
				dc.drawText(baseXOffset + iconWidth/2, baseYOffset + ((iconHeight + iconDistance) * layoutLineNr - 1), customFont, labelText, Gfx.TEXT_JUSTIFY_CENTER);
			}
			else
			{
				var ferryIcon = new Ui.Bitmap({:rezId=>Rez.Drawables.ferryIcon_bitmap});
				ferryIcon.setLocation(baseXOffset,baseYOffset + ((iconHeight + baseYOffset) * layoutLineNr));
				ferryIcon.draw(dc);
			}


			// Draw board information			
			dc.drawText(baseXOffset + iconWidth + 5, baseYOffset + ((iconHeight + iconDistance) * layoutLineNr - 4), Gfx.FONT_TINY, time_text, Gfx.TEXT_JUSTIFY_LEFT);	
			
			// Check if string is too long for screen size
			if(destination.length() > 15)
			{
				dc.drawText(baseXOffset + iconWidth + 5, baseYOffset + ((iconHeight + iconDistance) * layoutLineNr) + iconHeight/2-3, Gfx.FONT_TINY, truncateStopName(destination), Gfx.TEXT_JUSTIFY_LEFT);
			}else
			{
				dc.drawText(baseXOffset + iconWidth + 5, baseYOffset + ((iconHeight + iconDistance) * layoutLineNr) + iconHeight/2-3, Gfx.FONT_TINY, destination, Gfx.TEXT_JUSTIFY_LEFT);
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

		// Returns a string, which appends bus and train show settings to the request URL
		function generateTransportShowSettings()
		{
			var settings = "";
			//System.println("UseBus: " + Application.getApp().getProperty("useBus"));
			if(Application.getApp().getProperty("useTrain") == false)
			{
				settings = settings + "&useTog=0";
			}
			if(Application.getApp().getProperty("useBuss") == false)
			{
				settings = settings + "&useBus=0";
			}
			if(Application.getApp().getProperty("useMetro") == false)
			{
				settings = settings + "&useMetro=0";
			}
			//System.println("Request settings: " + settings);
			return settings;
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

	// Handles progress bar input
	class ProgressBarViewInputDelegate extends Ui.BehaviorDelegate
	{
		function initialize()
		{
			BehaviorDelegate.initialize();
		}

		function onBack()
		{
			//Ui.popView(Ui.SLIDE_IMMEDIATE);
		}
	}	
}