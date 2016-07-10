using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Communications as Comm;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian as Greg;

var dc1;

class DepartureBoardView extends Ui.View {


    function initialize() {
        View.initialize();
    }
	
	// Makes a request to the Journeyplanner API
    function makeRequest(stop_id, use_bus) {
        System.println("Making request");
        
        // Get the system time and date
        var now = System.getClockTime();
        var time=now.hour.toString() + "." + now.min.toString();        
        var dateinfo = Greg.info(Time.now(), Time.FORMAT_SHORT);
        var date=dateinfo.day.toString() + "." +  dateinfo.month.toString() + "." + dateinfo.year.toString();

		// Generate the URL
		var url = "http://xmlopen.rejseplanen.dk/bin/rest.exe/departureBoard?&format=json&id=" + stop_id + "&date="+ date + "&time=" + time; // + "&useBus=" + use_bus
        
        System.println(url);
        Comm.makeJsonRequest(url, null, null, method(:onReceive));
    }
    
    // Receive the data from the web request
    function onReceive(responseCode, data) {
     	
     	System.println("Checking response code");
     	// Check the response code
     	dc1.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT); 
		dc1.drawText(20,20, Gfx.FONT_TINY, "Resp code", Gfx.TEXT_JUSTIFY_CENTER);
        if (responseCode == 200) {     
        	System.println("Response received");
        	System.println(data.toString());
        	var values = data.get("DepartureBoard").get("Departure");
        	System.println(values.toString());
        	System.println("Values length is: " + values.size().toString());
        			
			if(values.size() < valuesToDisplay)
			{
				valuesToDisplay = values.size();		
			}
			
			for(var i=0; i < valuesToDisplay; i++)
			{
				departureBoardData[i] = values[i];
			}
	        if(receivedFlag == 0)
	        {
	        	receivedFlag = 1;
	        	Ui.requestUpdate();
	        } 
	        
        	
        } else {
        	//TODO: Show failed connection message
            System.println("Failed to load\nError: " + responseCode.toString());
            receivedFlag=0;
        }
    }
    	
	
    // Load your resources here
    function onLayout(dc) {
    	dc1 = dc;
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    	Ui.requestUpdate();
    }


	function drawDepartureTableLine(dc, layout_line_nr, line, destination, minutes) {
		var base_x_offset = 5;
		var base_y_offset = 5;
		var icon_width = 32;
		var icon_height = 15;
		
		var min_text = minutes.toString() + " m"; 
		
		// Draw the line icon
		if(line.find("Bus") != null)
		{
			if(line.find("A"))
			{
				dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
			}else if(line.find("E"))
			{
				dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
			}else if(line.find("S"))
			{
				dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
			}else
			{
				dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
			}
			dc.fillRoundedRectangle(base_x_offset,base_y_offset + ((icon_height + base_y_offset) * layout_line_nr),icon_width,icon_height,3);
			
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT); 
			dc.drawText(base_x_offset + icon_width/2, base_y_offset + ((icon_height + base_y_offset) * layout_line_nr - icon_height/2 + 3), Gfx.FONT_TINY, line.substring(4,line.length()), Gfx.TEXT_JUSTIFY_CENTER);
			dc.drawText(base_x_offset + icon_width + 5, base_y_offset + ((icon_height + base_y_offset) * layout_line_nr - icon_height/2 + 3), Gfx.FONT_TINY, min_text, Gfx.TEXT_JUSTIFY_LEFT);					
		}
		
	}

    // Update the view
    function onUpdate(dc) {
    	
    	System.println("onUpdate called");
    	if(receivedFlag == 0)
    	{
    		//makeRequest("292", "1");
    		makeRequest("466", "1");    		
    	}
       	
       	
       	if(departureBoardData[0] != null && receivedFlag == 1)
       	{
	       	for(var i=0;i<departureBoardData.size();i++)
	       	{
	       		var now = Time.now();
	       		var date_key = "date";
	       		var time_key = "time";
	       		
	       		System.println(departureBoardData[i]);
	       		
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
	       		
				System.println("NOW: " + now.value().toString());
	       		System.println("ARRIVAL: " + arrivalMoment.value().toString());
	       		System.println("DIFF: " + diff_min);
	       	
	       		drawDepartureTableLine(dc, i, departureBoardData[i].get("name"), departureBoardData[i].get("finalStop"), diff_min); 
	       	}
	        receivedFlag = 0;
       	}
        
    	
    
        // Call the parent onUpdate function to redraw the layout
        /*
        dc.setColor(Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK);
        dc.clear();
      
      	drawDepartureTableLine(dc, 0, "300S","Norreport", 5);
      	drawDepartureTableLine(dc, 1, "1E","Norreport", 10);
      	drawDepartureTableLine(dc, 2, "1A","Norreport", 3);
		*/
		//View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }
}
