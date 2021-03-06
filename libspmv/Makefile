CFLAGS=-std=c99 -D_GNU_SOURCE -O3
CXXFLAGS=-I${CL_ROOT}/include -L${CL_ROOT}/lib -L${CL_ROOT}/lib64 -std=c++11 -O3
LDFLAGS=-ldl -lpthread

SPARSEX_LLVM_LIBDIR=$(shell $(LLVM_CONFIG) --libdir)
SPARSEX_CFLAGS=$(shell $(SPARSEX_CONFIG) --cppflags)
SPARSEX_LDFLAGS=$(shell $(SPARSEX_CONFIG) --ldflags)
F_SPARSEX_CFLAGS=$(shell $(F_SPARSEX_CONFIG) --cppflags)
F_SPARSEX_LDFLAGS=$(shell $(F_SPARSEX_CONFIG) --ldflags)

all: test

native.so: native.c native-impl.c
	${CC} ${CFLAGS} -fPIC -shared $^ -o $@

mkl.so:	mkl.c mkl-model.c native-impl.c
	${CC} ${CFLAGS} -m64 -I${MKLROOT}/include -L${MKLROOT}/lib/intel64 -Wl,--no-as-needed -lmkl_rt -lpthread -lm -ldl -fPIC -shared $^ -o $@

mkl-slow.so: mkl-slow.c
	${CC} ${CFLAGS} -m64 -I${MKLROOT}/include -L${MKLROOT}/lib/intel64 -Wl,--no-as-needed -lmkl_rt -lpthread -lm -ldl -fPIC -shared $^ -o $@

gpu.so:	gpu.c
	${CC} ${CFLAGS} -L${CUDA_ROOT}/lib64 -I${CUDA_ROOT}/include -fPIC -shared $< -o $@ -lcublas -lcusparse -lcudart

gpu-slow.so: gpu-slow.c
	${CC} ${CFLAGS} -L${CUDA_ROOT}/lib64 -I${CUDA_ROOT}/include -fPIC -shared $< -o $@ -lcublas -lcusparse -lcudart

unsafe.so: gpu-unsafe.c
	${CC} ${CFLAGS} -L${CUDA_ROOT}/lib64 -I${CUDA_ROOT}/include -fPIC -shared $< -o $@ -lcublas -lcusparse -lcudart

cl-probe: cl-probe.cpp
	$(CXX) $(CXXFLAGS) $< -lOpenCL -o $@

opencl%.so: opencl.cpp cl_%.cpp
	$(CXX) $(CXXFLAGS) -fPIC -shared $^ -lclSPARSE -lOpenCL -lclsparseTimer -o $@

opencl%-slow.so: opencl-slow.cpp cl_%.cpp
	$(CXX) $(CXXFLAGS) -fPIC -shared $^ -lclSPARSE -lOpenCL -lclsparseTimer -o $@

sparsex.so: sparsex.c
	$(CC) $(CFLAGS) -fPIC -shared $(SPARSEX_CFLAGS) $^ -o $@ $(SPARSEX_LDFLAGS) -L$(SPARSEX_LLVM_LIBDIR)

sparsex-slow.so: sparsex-slow.c
	$(CC) $(CFLAGS) -fPIC -shared $(SPARSEX_CFLAGS) $^ -o $@ $(SPARSEX_LDFLAGS) -L$(SPARSEX_LLVM_LIBDIR)

fsparsex.so: fsparsex.c
	$(CC) $(CFLAGS) -fPIC -shared $(F_SPARSEX_CFLAGS) $^ -o $@ $(F_SPARSEX_LDFLAGS) -L$(SPARSEX_LLVM_LIBDIR)

fsparsex-slow.so: fsparsex-slow.c
	$(CC) $(CFLAGS) -fPIC -shared $(F_SPARSEX_CFLAGS) $^ -o $@ $(F_SPARSEX_LDFLAGS) -L$(SPARSEX_LLVM_LIBDIR)

test: test.cpp
	${CXX} ${CXXFLAGS} $< -o $@ ${LDFLAGS}

install: $(platform).so
	mkdir -p $(SPMV_ROOT)/lib
	cp $< ${SPMV_ROOT}/lib/lib$(platform)-spmv.so

clean:
	rm -f *.so
	rm -f test
	rm -f cl-probe
