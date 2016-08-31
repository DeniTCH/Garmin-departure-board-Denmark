TOOLKIT=/home/denis/bin/connectiq-sdk-win-2.1.2/bin
#MC=$(TOOLKIT)/monkeyc
MC=java -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true -jar $(TOOLKIT)/monkeybrains.jar
SIM=$(TOOLKIT)/simulator.exe
SIM_LAUNCHER=$(TOOLKIT)/monkeydo
KEY=/home/denis/bin/connectiq-sdk-win-2.1.2/developer_key

DEVICE=vivoactive_hr

ROOTPATH=/home/denis/Repositories/programming_projects/garmin_departure_board

OUTPUTDIR=bin
FILENAME=DEPARBRD.PRG
PACKAGE_NAME=DepartureBoard.iq

RESOURCES=-z resources/bitmaps.xml -z resources/layouts.xml -z resources/properties.xml -z resources/settings.xml -z resources/strings.xml -z resources/fonts.xml -z resources-dan/strings.xml
MANIFEST=manifest.xml
SOURCES=source/DepartureBoardView.mc source/DepartureBoardClass.mc source/DepartureBoardApp.mc source/NewPicker.mc


all: clean
	$(MC) -y $(KEY) -m $(MANIFEST) -w $(RESOURCES) -o $(OUTPUTDIR)/$(FILENAME) $(SOURCES) -d $(DEVICE)
run: all
	$(SIM_LAUNCHER) $(ROOTPATH)/$(OUTPUTDIR)/$(FILENAME) $(DEVICE)
deploy: all
	cp $(OUTPUTDIR)/$(FILENAME) /media/denis/GARMIN/GARMIN/APPS/$(FILENAME)
publish: clean
	$(MC) -r -e -y $(KEY) -m $(MANIFEST) -w $(RESOURCES) -o $(OUTPUTDIR)/$(PACKAGE_NAME) $(SOURCES)
clean:
	rm -rf $(OUTPUTDIR)/*