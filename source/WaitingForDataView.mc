using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class WaitingForDataView extends Ui.View {
	
    function initialize() 
    {
        View.initialize();
    }
		
    // Load your resources here
    function onLayout(dc) 
    {        
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() 
    {
    	//Ui.requestUpdate();
    }


    // Update the view
    function onUpdate(dc) 
    {
    	if(noStopsNearby ==  true)
    	{
		   	dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_BLACK );
	    	dc.clear();
	    	dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
	        dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2), Gfx.FONT_SMALL, "No stops!", Gfx.TEXT_JUSTIFY_CENTER );
    	}else
    	{
   	    	dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_BLACK );
	    	dc.clear();
	    	dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
	        dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2), Gfx.FONT_SMALL, "Waiting for data", Gfx.TEXT_JUSTIFY_CENTER );
    	}
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }
}