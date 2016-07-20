using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Graphics as Gfx;

class ListFactory extends Ui.PickerFactory
{
		
	function initialize()
	{		
	}
	
	
	function getSize()
	{
		return stopsData.size();
	}
	
	function getValue(index)
	{
		return stopsData[index].get("id");
	}
	
	function getDrawable(index, selected)
	{
		return new Ui.Text({:text=>stopsData[index].get("name"), :color=>Gfx.COLOR_WHITE, :font=>Gfx.FONT_SMALL, :locX=>Ui.LAYOUT_HALIGN_CENTER, :locY=>Ui.LAYOUT_VALIGN_CENTER});	
	}
}


class StopPicker extends Ui.Picker
{	
	function initialize()
	{	
		var title = new Ui.Text({:text=>"Choose a stop", :locX =>Ui.LAYOUT_HALIGN_CENTER, :locY=>Ui.LAYOUT_VALIGN_BOTTOM, :color=>Gfx.COLOR_WHITE});		
		var factory = new ListFactory(stopsData);
		Picker.initialize({:title=>title, :pattern=>[factory],:defaults=>null});
	}
	
	function onUpdate(dc)
	{
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
	}
}

class StopPickerDelegate extends Ui.PickerDelegate
{	
	function onCancel()
	{
		Ui.popView(Ui.SLIDE_IMMEDIATE);
	}
	
	function onAccept(values)
	{
		selectedStop = values[0];
		System.println("Selected: " + selectedStop);
		Ui.popView(Ui.SLIDE_IMMEDIATE);
		
		// Free the memory
    	stopsData = {};
	}
}