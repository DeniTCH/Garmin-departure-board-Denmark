using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;

class StopChooser extends Ui.View
{
    function initialize(data)
    {
        System.println(data);
        selectedStop = data[0];
        //mData = data;
    }

    function onLayout(dc)
    {
        setLayout(Rez.Layouts.StopChooserLayout(dc));
    }

    function onUpdate(dc)
    {
        findDrawableById("selectedItemLabel").setText(selectedStop.get("name").substring(0,15));
        findDrawableById("distLabel").setText(Ui.loadResource(Rez.Strings.StrDistancePrefix) + " " + selectedStop.get("distance"));
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
    }

    function onNextButton()
    {
        if(mSelectedIndex < mData.size() - 1)
        {
            mSelectedIndex = mSelectedIndex + 1;
            selectedStop = mData[mSelectedIndex];
            Ui.requestUpdate();
        }
    }

    function onPreviousButton()
    {
        if(mSelectedIndex > 0)
        {
            mSelectedIndex = mSelectedIndex - 1;
            selectedStop = mData[mSelectedIndex];
            Ui.requestUpdate();  
        }
    }

    function onAcceptButton()
    {
        stopSelectedFlag = true;
        Ui.popView(Ui.SLIDE_IMMEDIATE);
    }

}