using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Graphics as Gfx;

var errorShownFlag;

class DepartureBoardView extends Ui.View {
	
	var db;
    hidden var icon;

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) 
    {
        if(db == null)
        {
            db = new DepatureBoard();    
        }
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() 
    {
    }

    // Update the view
    function onUpdate(dc) {
        
        if(db.getSMState() == db.SM_SHOW_BOARD || db.getSMState() == db.SM_DONE)
        {
	        System.println("Updating view");
	        db.drawDepartureBoard(dc);	                
        }else if(db.getSMState() == db.SM_ERROR && errorShownFlag == true)
        {
            //Ui.popView(Ui.SLIDE_IMMEDIATE);
            //System.exit();
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}
