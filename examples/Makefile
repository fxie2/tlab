# BINS_PATH contains the executables to be tested; needs to be passed externally
#
PRJS=\
     Case01 \
     Case02 \
     Case03 \
     Case04 \
     Case05 \
     Case06 \
     Case07 \
     Case08 \
     Case09 \
     Case10 \
     Case13 \
     Case14 \
     Case15 \
     Case16 \
     Case17 \
     Case18 \
     Case19 \
     Case20 \
     Case21 \
     Case22 \
     Case25 \
     Case26 \
     Case27 \
     Case28 \
     Case31 \
     Case32 \
     Case33 \
     Case34 \
     Case35 \
     Case36 \
     Case40

     # Case11 \
     # Case12 \

FILES=avg* grid* flow* scal* dns.out dns.log dns.err dns.war dns.def dns.ini.bak tower* particle* trajectories* residence*

##########################################################################
#   Directives
##########################################################################
SHELL := /bin/bash

check:
	@echo -e "Running selected cases in examples directory."
	@echo -e "Reference incompressible values obtained with FFTW/ESTIMATE mode."
	@(for prj in $(PRJS); do (echo -n "[`date +%T`] Checking $$prj... "; cd $$prj; ../check_run.sh ../../$(BINS_PATH) ) done )

##########################################################################
clean: 
	@(for prj in $(PRJS); do (cd $$prj; rm -f $(FILES) ) done )

proper:
	-/bin/rm -rf *~
	@(for prj in $(PRJS); do (cd $$prj; rm -f $(FILES) ) done )

