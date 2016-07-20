using Toybox.Position as Position;
using Toybox.Communications as Comm;
using Toybox.System;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.Time.Gregorian as Greg;
using Toybox.Graphics as Gfx;
using Toybox.Attention as Attention;
using Toybox.Application as App;



class DepartureBoard
{	
	hidden var responseReceivedFlag = false;
	hidden var uiUpdatedFlag = false;	
	
	hidden var timer;
	hidden var smState;
	hidden var updateCountdown;
	
	hidden var positionInfo;

    hidden var vibrateData = [ new Attention.VibeProfile(  25, 100 ),
                        new Attention.VibeProfile(  50, 100 ),
                        new Attention.VibeProfile(  75, 100 ),
                        new Attention.VibeProfile( 100, 100 ),
                        new Attention.VibeProfile(  75, 100 ),
                        new Attention.VibeProfile(  50, 100 ),
                        new Attention.VibeProfile(  25, 100 ) ];

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
		SM_REQUEST_NEARBY_STOPS,
		SM_WAIT_STOPS_RESPONSE,
		SM_DETERMINE_STOP,
		SM_NO_STOPS_TO_SHOW,
		SM_REQUEST_BOARD,
		SM_WAIT_BOARD_RESPONSE,
		SM_UPDATE_UI,
		SM_WAIT_FOR_UI_UPDATE,
		SM_DELAY_BEFORE_REQUEST
	}
	
	function initialize()
	{
		smState = SM_REQUEST_NEARBY_STOPS;
		timer = new Timer.Timer();
        timer.start(method(:updateSM), 500, true);
	}
	
	// Callback function for location request.	
	function getNearbyStops(info)
	{
		positionInfo = info;
		var lat = (positionInfo.position.toDegrees()[0] * 1000000).toNumber();
		var lon = (positionInfo.position.toDegrees()[1] * 1000000).toNumber();
				
		//var url = "http://xmlopen.rejseplanen.dk/bin/rest.exe/stopsNearby?&format=json&coordX=" + lat.toString() + "&coordY=" + lon.toString() + "&maxRadius=1000&maxNumber=" + maxNumberOfStops.toString();		
		var url = "http://xmlopen.rejseplanen.dk/bin/rest.exe/stopsNearby?&format=json&coordX=" + "12504913" + "&coordY=" + "55739537" + "&maxRadius=1000&maxNumber=" + maxNumberOfStops.toString();
		//System.println(url);
        Comm.makeJsonRequest(url, null, null, method(:onStopsReceive));
        //Comm.makeWebRequest(url, null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:onStopsReceive));
	}
	
	// Callback for API request for stops
	function onStopsReceive(responseCode, data)
	{
		if (responseCode == 200)
		{
			// Test if we have stops nearby
			if(data.get("LocationList").hasKey("StopLocation"))
			{
				stopsData = data.get("LocationList").get("StopLocation");
							
			}else
			{
				noStopsNearby = true;
			}
			responseReceivedFlag = true;
		}else
		{
        	//TODO: Show failed connection message
            System.println("Failed to get stops\nError: " + responseCode.toString());
            responseReceivedFlag = false;		
		}
	}
	
	
	// Makes a request to the Journeyplanner API
    function makeBoardRequest(stop_id, use_bus) 
    {               
        // Get the system time and date
        var now = System.getClockTime();
        var time=now.hour.toString() + "." + now.min.toString();        
        var dateinfo = Greg.info(Time.now(), Time.FORMAT_SHORT);
        var date=dateinfo.day.toString() + "." +  dateinfo.month.toString() + "." + dateinfo.year.toString();

		// Generate the URL
		var url = "http://xmlopen.rejseplanen.dk/bin/rest.exe/departureBoard?&format=json&id=" + stop_id + "&date="+ date + "&time=" + time; // + "&useBus=" + use_bus
        
        System.println(url);
        Comm.makeJsonRequest(url, null, null, method(:onBoardReceive));
        //Comm.makeWebRequest(url, null, {:method=>Comm.HTTP_REQUEST_METHOD_GET,:responseType=>Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:onBoardReceive));
    }
    
    // Callback function for the web request
    function onBoardReceive(responseCode, data) 
    {	
     	// Check the response code
        if (responseCode == 200) {     

        	var values = data.get("DepartureBoard").get("Departure");        			
			if(values.size() < valuesToDisplay)
			{
				valuesToDisplay = values.size();		
			}
			
			for(var i=0; i < valuesToDisplay; i++)
			{
				departureBoardData[i] = values[i];
			}
			
			values = null;
			responseReceivedFlag = true;
        } else {
        	//TODO: Show failed connection message
            System.println("Failed to load\nError: " + responseCode.toString());
            responseReceivedFlag = false;
        }
    }
    
    function getStopID()
    {
    	for(var i=0; i < stopsData.size();i++)
    	{
    		for(var j=0; j < favouriteStops.size(); j++)
    		{
    			if(stopsData[i].get("id").equals(favouriteStops[j]))
    			{
    				selectedStop = stopsData[i].get("id"); 
    			}
    		}
    	}
    	
    	if (selectedStop == null)
    	{
			if(App.getApp().getProperty("vibrate"))
			{
				Attention.vibrate(vibrateData);
			}
    		Ui.pushView(new StopPicker(), new StopPickerDelegate(), Ui.SLIDE_IMMEDIATE);
    	}
    }
	
	// Updates the state machine (called as a timer callback)
	function updateSM()
	{
		if(smState == SM_REQUEST_NEARBY_STOPS)
		{
			Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:getNearbyStops));			
			smState = SM_WAIT_STOPS_RESPONSE;
		}else if(smState == SM_WAIT_STOPS_RESPONSE)
		{
			if(responseReceivedFlag)
			{
				if(noStopsNearby == true)
				{
					Ui.requestUpdate();
					smState = SM_NO_STOPS_TO_SHOW;					
				}else
				{
					smState = SM_DETERMINE_STOP;
					responseReceivedFlag = false;						
					getStopID();
				}
			}
						
		}else if(smState == SM_DETERMINE_STOP)
		{
			if(selectedStop != null)
			{
				smState = SM_REQUEST_BOARD;
			}
			
		}else if(smState == SM_NO_STOPS_TO_SHOW)
		{
	
		}else if(smState == SM_REQUEST_BOARD)
		{
			makeBoardRequest(selectedStop, "1");
			smState = SM_WAIT_BOARD_RESPONSE;
		}else if(smState == SM_WAIT_BOARD_RESPONSE)
		{
			if(responseReceivedFlag)
			{
				smState = SM_UPDATE_UI;
				responseReceivedFlag = false;
				if(App.getApp().getProperty("vibrate"))
				{
					Attention.vibrate(vibrateData);
				}
				Ui.switchToView(new DepartureBoardView(), null, Ui.SLIDE_IMMEDIATE);
			}
		}else if(smState == SM_UPDATE_UI)
		{							
			Ui.requestUpdate();
			smState = SM_WAIT_FOR_UI_UPDATE;
		}else if(smState == SM_WAIT_FOR_UI_UPDATE)
		{
			if(uiUpdatedFlag)
			{
				updateCountdown = 30000;
				smState = SM_DELAY_BEFORE_REQUEST;
				uiUpdatedFlag = false;	
			}		
		}else if(smState == SM_DELAY_BEFORE_REQUEST)
		{
			if(updateCountdown == 0)
			{
				smState = SM_REQUEST_BOARD;
			}else
			{
				updateCountdown = updateCountdown - 500;
			}
		}
	}
	
	function drawDepartureBoard(dc)
	{
		if(smState == SM_WAIT_FOR_UI_UPDATE)
		{
		   	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
	   		dc.clear();
	   	
	       	for(var i=0;i<departureBoardData.size();i++)
	       	{
	       		var now = Time.now();
	       		var date_key = "date";
	       		var time_key = "time";
	       		
	       		//System.println(departureBoardData[i]);
	       		
	       		// Calculate time to transport
	       		if(departureBoardData[i].hasKey("rtTime"))
	       		{
					time_key = "rtTime"; 
				}
				
				if(departureBoardData[i].hasKey("rtDate"))
	       		{
					date_key = "rtDate";
				}
	       		// Parse time and date from response
	   			var arrivalMoment = Greg.moment({:year => departureBoardData[i].get(date_key).substring(6,8).toNumber()+2000,
	       		:month => departureBoardData[i].get(date_key).substring(3,5).toNumber(),
	       		:day => departureBoardData[i].get(date_key).substring(0,2).toNumber(),
	       		:hour => departureBoardData[i].get(time_key).substring(0,2).toNumber(),
	       		:minute => departureBoardData[i].get(time_key).substring(3,5).toNumber(),
	       		:second => 0});
	       		
	       		var diff_min = (arrivalMoment.subtract(now).value().toNumber() - System.getClockTime().timeZoneOffset)/60;
	       		
				//System.println("NOW: " + now.value().toString());
	       		//System.println("ARRIVAL: " + arrivalMoment.value().toString());
	       		//System.println("DIFF: " + diff_min);
	       	
	       		drawDepartureTableLine(dc, i, departureBoardData[i].get("name"), departureBoardData[i].get("finalStop"), diff_min); 
	       	}	       	
	       	uiUpdatedFlag = true;
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
		
		var min_text = minutes.toString() + " m"; 
		
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
		dc.drawText(base_x_offset + icon_width + 5, base_y_offset + ((icon_height + icon_distance) * layout_line_nr - 4), Gfx.FONT_TINY, min_text, Gfx.TEXT_JUSTIFY_LEFT);	
		// Check if string is too long for screen size
		if(destination.length() > 15)
		{
			dc.drawText(base_x_offset + icon_width + 5, base_y_offset + ((icon_height + icon_distance) * layout_line_nr) + icon_height/2-3, Gfx.FONT_TINY, destination.substring(0,15), Gfx.TEXT_JUSTIFY_LEFT);
		}else
		{
			dc.drawText(base_x_offset + icon_width + 5, base_y_offset + ((icon_height + icon_distance) * layout_line_nr) + icon_height/2-3, Gfx.FONT_TINY, destination, Gfx.TEXT_JUSTIFY_LEFT);
		}
		
	}	
}