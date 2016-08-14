TOOLKIT=/home/denis/bin/connectiq-sdk-win-2.1.0/bin
MC=$(TOOLKIT)/monkeyc
SIM=$(TOOLKIT)/simulator.exe
SIM_LAUNCHER=$(TOOLKIT)/monkeydo

DEVICE=vivoactive_hr

ROOTPATH=/home/denis/Repositories/programming_projects/garmin_departure_board

OUTPUTDIR=bin
FILENAME=DEPARTUREBOARD.PRG

RESOURCES=-z $(ROOTPATH)/resources/drawables/drawables.xml -z $(ROOTPATH)/resources/layouts/layout.xml -z $(ROOTPATH)/resources/properties/properties.xml -z $(ROOTPATH)/resources/resources.xml -z $(ROOTPATH)/resources/settings/settings.xml -z $(ROOTPATH)/resources/strings/strings.xml
MANIFEST=manifest.xml
SOURCES=source/StopPicker.mc source/DepartureBoardView.mc source/DepartureBoardClass.mc source/DepartureBoardApp.mc
KEY=/home/denis/bin/connectiq-sdk-win-2.1.0/developer_key

all:
	$(MC) -y $(KEY) -m $(MANIFEST) -o $(OUTPUTDIR)/$(FILENAME) -w $(RESOURCES) $(SOURCES)
run:
	$(SIM_LAUNCHER) $(ROOTPATH)/$(OUTPUTDIR)/$(FILENAME) $(DEVICE)
deploy:
	cp $(OUTPUTDIR)/$(FILENAME) /media/denis/GARMIN/GARMIN/APPS/$(FILENAME)
clean:
	rm $(OUTPUTDIR)/*
