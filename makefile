# --- makefile preliminary setup begins --- 
ifeq ($(shell test -L makefile ; echo $$? ),1)
all : 
	@echo "makefile should be a symbolic link to avoid accidentally building in the root directory ... attempting to create ./obj,./lib,./run, symlink makefile in ./obj, and recurse make into ./obj"
	-mkdir obj run lib
	-ln -sf ../makefile obj/makefile
	cd obj && $(MAKE)
else
# FIXME: make seems to somtimes like to run prebuild.py multiple times -- which is not great, but okay.
$(info py_prebuild_rm_okay: $(shell rm -f prebuild.okay ))
# run python build code: generates various code, object list file, and dependency list file
$(info py_prebuild_hook:  $(shell python ../pysrc/prebuild.py )) # creates an empty prebuild.okay file on success
ifeq ($(shell test -f prebuild.okay ; echo $$? ),1)
$(error "prebuild.okay file does not exist. assuming prebuild.py failed, aborting make")
endif
# --- makefile preliminary setup ends ---
# --- makefile header section begins --- # edit paths / project info / configuration here
TARGET := ../lib/boda
CPP := g++
CPPFLAGS := -Wall -O3 -g -std=c++0x -rdynamic -fPIC -I/usr/include/python2.7 -I/usr/include/octave-3.8.1 -I/usr/include/octave-3.8.1/octave -I/usr/include/SDL2 -I/usr/local/include/SDL2 -fopenmp -Wall 
LDFLAGS := -lboost_system -lboost_filesystem -lboost_iostreams -lboost_regex -lpython2.7 -loctave -loctinterp -fopenmp -lturbojpeg -lSDL2 -lSDL2_ttf
#for caffe/cuda
CAFFE_HOME := /home/moskewcz/git_work/caffe_dev
CPPFLAGS := $(CPPFLAGS) -I$(CAFFE_HOME)/include -I$(CAFFE_HOME)/build/src -I/usr/local/cuda/include
LDFLAGS := $(LDFLAGS) -L$(CAFFE_HOME)/build/lib -L/usr/local/cuda/lib64 -lcaffe -lcudart -lcublas -lcurand -lprotobuf
# --- makefile header section ends --- # generally, there is no need to alter the makefile below this line
VPATH := ../src ../src/gen ../src/ext
OBJS := $(shell cat ../src/obj_list | grep -v ^\#) $(shell cat ../src/gen/gen_objs | grep -v ^\#)
.SUFFIXES:
%.o : %.cc
	$(CPP) $(CPPFLAGS) -MMD -c $<
%.d : %.cc
	@touch $@
%.o : %.cpp
	$(CPP) $(CPPFLAGS) -MMD -c $<
%.d : %.cpp
	@touch $@
DEPENDENCIES = $(OBJS:.o=.d)
LIBTARGET=../lib/libboda.so
all : $(TARGET) # $(LIBTARGET)
$(TARGET): $(OBJS)
	$(CPP) $(CPPFLAGS) -o $(TARGET) $(OBJS) $(LDFLAGS)
$(LIBTARGET): $(OBJS)
	$(CPP) -shared $(CPPFLAGS) -o $(LIBTARGET) $(OBJS) $(LDFLAGS)
.PHONY : clean
clean:
	-rm -f $(TARGET) $(OBJS) $(DEPENDENCIES)
include $(DEPENDENCIES)
endif
