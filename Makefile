TOOLKIT=/home/denis/bin/connectiq-sdk-win-2.1.0/bin
#MC=$(TOOLKIT)/monkeyc
MC=java -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true -jar $(TOOLKIT)/monkeybrains.jar
SIM=$(TOOLKIT)/simulator.exe
SIM_LAUNCHER=$(TOOLKIT)/monkeydo

DEVICE=vivoactive_hr

ROOTPATH=/home/denis/Repositories/programming_projects/garmin_departure_board

OUTPUTDIR=bin
FILENAME=DEPARTUREBOARD.PRG

RESOURCES=-z resources/bitmaps.xml -z resources/layouts.xml -z resources/properties.xml -z resources/settings.xml -z resources/strings.xml
MANIFEST=manifest.xml
SOURCES=source/StopPicker.mc source/DepartureBoardView.mc source/DepartureBoardClass.mc source/DepartureBoardApp.mc source/ErrorView.mc
KEY=/home/denis/bin/connectiq-sdk-win-2.1.0/developer_key

all: clean
	$(MC) -y $(KEY) -m $(MANIFEST) -w $(RESOURCES) -o $(OUTPUTDIR)/$(FILENAME) $(SOURCES) -d $(DEVICE)
run: all
	$(SIM_LAUNCHER) $(ROOTPATH)/$(OUTPUTDIR)/$(FILENAME) $(DEVICE)
deploy: all
	cp $(OUTPUTDIR)/$(FILENAME) /media/denis/GARMIN/GARMIN/APPS/$(FILENAME)
clean:
	rm -rf $(OUTPUTDIR)/*