using Toybox.System;
using Toybox.Graphics;
using Toybox.WatchUi as Ui;


class ErrorView extends Ui.View
{
	hidden var errorType;

	enum
	{
		ERROR_NO_CONNNECTION,
		ERROR_NO_POSITION,
		ERROR_NO_STOPS,
		ERROR_NO_PHONE
	}
	
	function initialize()
	{
		View.initialize();
	}

	function setErrorTypeNoConnection()
	{
		errorType = ERROR_NO_CONNNECTION;
	}

	function setErrorTypeNoStops()
	{
		errorType = ERROR_NO_STOPS;
	}

	function setErrorTypeNoPosition()
	{
		errorType = ERROR_NO_POSITION;
	}

	function setErrorTypeNoPhone()
	{
		errorType = ERROR_NO_PHONE;
	}

	function onLayout(dc)
	{
		System.println("Error view called");

		System.println("Error type: " + errorType);

		if(errorType == ERROR_NO_CONNNECTION)
		{
			System.println("Displaying no connection error");
			setLayout(Rez.Layouts.NoConnectionErrorLayout(dc));
		}
		else if(errorType == ERROR_NO_POSITION)
		{
			System.println("Displaying no position error");
			setLayout(Rez.Layouts.NoPositionErrorLayout(dc));
		}
		else if(errorType == ERROR_NO_STOPS)
		{
			System.println("Displaying no stops error");
			setLayout(Rez.Layouts.NoStopsErrorLayout(dc));
		}
		else if(errorType == ERROR_NO_PHONE)
		{
			System.println("Displaying no phone error");
			setLayout(Rez.Layouts.NoPhoneErrorLayout(dc));
		}
	}

	function onUpdate(dc)
	{
		errorShownFlag = true;
		View.onUpdate(dc);
	}
}

class ErrorViewDelegate extends Ui.BehaviorDelegate
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