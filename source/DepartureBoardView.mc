using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Graphics as Gfx;

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
            db = new DepartureBoard.DepatureBoardClass();    
        }
        //setLayout(Rez.Layouts.StopChooserLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() 
    {
    }

    // Update the view
    function onUpdate(dc) {
        
        var smState = db.getSMState();

        if(smState == db.SM_SHOW_BOARD || smState == db.SM_DONE)
        {
	        System.println("Updating view");
	        db.drawDepartureBoard(dc);	                
        }
        else if(smState == db.SM_ERROR_NO_CONNECTION)
        {
            System.println("Displaying no connection error");
            setLayout(Rez.Layouts.NoConnectionErrorLayout(dc));
            View.onUpdate(dc);
        }
        else if(smState == db.SM_ERROR_NO_POSITION)
        {
            System.println("Displaying no position error");
            setLayout(Rez.Layouts.NoPositionErrorLayout(dc));
            View.onUpdate(dc);
        }
        else if(smState == db.SM_ERROR_NO_STOPS)
        {
            System.println("Displaying no stops error");
            setLayout(Rez.Layouts.NoStopsErrorLayout(dc));
            View.onUpdate(dc);
        }
        else if(smState == db.SM_ERROR_NO_PHONE)
        {
            System.println("Displaying no phone error");
            setLayout(Rez.Layouts.NoPhoneErrorLayout(dc));
            View.onUpdate(dc);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}
