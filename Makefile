############################################################################
##
##     This file is part of Purdue CS 422.
##
##     Purdue CS 422 is free software: you can redistribute it and/or modify
##     it under the terms of the GNU General Public License as published by
##     the Free Software Foundation, either version 3 of the License, or
##     (at your option) any later version.
##
##     Purdue CS 422 is distributed in the hope that it will be useful,
##     but WITHOUT ANY WARRANTY; without even the implied warranty of
##     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##     GNU General Public License for more details.
##
##     You should have received a copy of the GNU General Public License
##     along with Purdue CS 422. If not, see <https://www.gnu.org/licenses/>.
##
#############################################################################

default: c

####################################################################
############### Set up Mininet and Controller ######################
####################################################################

SCRIPTS = ./scripts

.PHONY: mininet controller cli netcfg host-h1 host-h2

mininet:
	$(SCRIPTS)/mn-stratum --topo linear,2

controller:
	ONOS_APPS=gui,proxyarp,drivers.bmv2,lldpprovider,hostprovider \
	$(SCRIPTS)/onos

cli:
	$(SCRIPTS)/onos-cli

netcfg:
	$(SCRIPTS)/onos-netcfg cfg/netcfg.json

host-h1:
	$(SCRIPTS)/utils/mn-stratum/exec h1

host-h2:
	$(SCRIPTS)/utils/mn-stratum/exec h2


####################################################################
###################### Compile C programs ##########################
####################################################################

GCC = gcc:4.9
SRCS = srcs

c: client-c server-c

client-c:
	docker run --rm -v "$(PWD)":/workdir -w /workdir $(GCC) \
		gcc -o $(SRCS)/client-c $(SRCS)/client-c.c

server-c:
	docker run --rm -v "$(PWD)":/workdir -w /workdir $(GCC) \
		gcc -o $(SRCS)/server-c $(SRCS)/server-c.c

####################################################################
###3###################### Run tests ###############################
####################################################################

test:
	$(SCRIPTS)/utils/mn-stratum/exec-script h1 "./tests/client-server.sh python 11111"


clean:
	rm -f $(SRCS)/server-c $(SRCS)/client-c
	rm -rf .workspace
