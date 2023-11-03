F90=gfortran
F90FLAGS=-I. -g

CLOUD_PREFIX=..
CLOUD_LIBS= -L $(FZMQ_ROOT)/lib -lfzmq -L /opt/homebrew/lib -lzmq -lstdc++  # -lc -lpthread -lgnutls
CLOUD_INCFLAGS=-I$(FZMQ_ROOT)/include -I /opt/homebrew/include  -fstack-protector-all # -fsanitize=address
CLOUD_OBJ=cloud_0mq.o
LDFLAGS += -fstack-protector-all
### include cloud.inc

LIBS=$(CLOUD_INCFLAGS) $(CLOUD_LIBS)
LIBOBJ=$(CLOUD_OBJ)

all: test_proxy producer worker test test_recv

%.o: %.F90
	$(F90) -c -o $@ $< $(F90FLAGS) $(LIBS)

test_proxy: test_proxy.f90 $(LIBOBJ)
	$(F90) -o $@ $^ $(F90FLAGS) $(LIBS)

test: test.f90 $(LIBOBJ)
	$(F90) -o $@ $^ $(F90FLAGS) $(LIBS)

test_recv: test_recv.f90 $(LIBOBJ)
	$(F90) -o $@ $^ $(F90FLAGS) $(LIBS)

producer: producer.f90 $(LIBOBJ)
	$(F90) -o $@ $^ $(F90FLAGS) $(LIBS)

worker: worker.f90 $(LIBOBJ)
	$(F90) -o $@ $^ $(F90FLAGS) $(LIBS)

.PHONY: clean

clean:
	rm -f *.o *.mod producer worker test_proxy
