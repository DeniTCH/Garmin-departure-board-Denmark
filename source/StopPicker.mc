using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Graphics as Gfx;

class ListFactory extends Ui.PickerFactory
{

	hidden var stopsData;
		
	function initialize(data)
	{		
		PickerFactory.initialize();
		stopsData = data;
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
		return new Ui.Text({:text=>stopsData[index].get("name"), :color=>Gfx.COLOR_RED, :font=>Gfx.FONT_SMALL, :locX=>Ui.LAYOUT_HALIGN_CENTER, :locY=>Ui.LAYOUT_VALIGN_TOP});	
	}
}


class StopPicker extends Ui.Picker
{	
	function initialize(data)
	{	
		var title = new Ui.Text({:text=>Rez.Strings.StrChooseStop, :locX =>Ui.LAYOUT_HALIGN_CENTER, :locY=>Ui.LAYOUT_VALIGN_BOTTOM, :color=>Gfx.COLOR_WHITE});		
		var nextArrow = new Ui.Bitmap({:rezId=>Rez.Drawables.arrowDown, :locX=>Ui.LAYOUT_HALIGN_RIGHT, :LocY=>Ui.LAYOUT_VALIGN_BOTTOM});
		var previousArrow = new Ui.Bitmap({:rezId=>Rez.Drawables.arrowUp, :locX=>Ui.LAYOUT_HALIGN_LEFT, :LocY=>Ui.LAYOUT_VALIGN_BOTTOM});		
		var factory = new ListFactory(data);
		
		System.println("Picker data:" + data);
		
		Picker.initialize({:title=>title, :pattern=>[factory], :defaults=>null, :nextArrow=>nextArrow, :previousArrow=>previousArrow});
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
	function initialize()
	{
		PickerDelegate.initialize();
	}

	function onCancel()
	{
		System.exit();
	}
	
	function onAccept(values)
	{
		selectedStop = values[0];
		System.println("Picker onAccept: " + selectedStop);
		System.println("Popping picker");
		Ui.popView(Ui.SLIDE_IMMEDIATE);		
	}
}