using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;

class StopChooser extends Ui.View
{
    function initialize(data)
    {
        $.selectedStop = data[0];
        View.initialize();
    }

    function onLayout(dc)
    {
        setLayout(Rez.Layouts.StopChooserLayout(dc));
    }

    function onUpdate(dc)
    {
        findDrawableById("selectedItemLabel").setText(DepartureBoard.truncateStopName($.selectedStop.get("name")));
        findDrawableById("distLabel").setText(Ui.loadResource(Rez.Strings.StrDistancePrefix) + " " + $.selectedStop.get("distance") + "m");
        View.onUpdate(dc);   
    }
}

class StopChooserDelegate extends Ui.BehaviorDelegate
{
    var mData;
    var mSelectedIndex = 0;

    function initialize(data)
    {
        mData = data;
        BehaviorDelegate.initialize();
    }

    function onNextButton()
    {
        if(mSelectedIndex < mData.size() - 1)
        {
            mSelectedIndex = mSelectedIndex + 1;
            $.selectedStop = mData[mSelectedIndex];
            Ui.requestUpdate();
        }
    }

    function onPreviousButton()
    {
        if(mSelectedIndex > 0)
        {
            mSelectedIndex = mSelectedIndex - 1;
            $.selectedStop = mData[mSelectedIndex];
            Ui.requestUpdate();  
        }
    }

    function onAcceptButton()
    {
        System.println("Accept pressed");
        $.stopSelectedFlag = true;
        Ui.popView(Ui.SLIDE_IMMEDIATE);
    }
}