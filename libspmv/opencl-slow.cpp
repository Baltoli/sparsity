#define CL_HPP_ENABLE_EXCEPTION
#define CL_HPP_MINIMUM_OPENCL_VERSION BUILD_CLVERSION
#define CL_HPP_TARGET_OPENCL_VERSION BUILD_CLVERSION

#include <CL/cl.hpp>
#include <clSPARSE.h>
#include <clSPARSE-error.h>

#include <algorithm>
#include <csignal>
#include <iostream>
#include <unistd.h>
#include <vector>
#include <sys/mman.h>

namespace {
  cl_int cl_status;
  clsparseStatus status;

  std::vector<cl::Device> devices{};
  std::vector<cl::Platform> platforms{};

  cl::Device* device;
  cl::Platform* platform;

  cl::Context context;
  cl::CommandQueue queue;
  clsparseControl control;

  clsparseScalar alpha;
  clsparseScalar beta;

  cldenseVector x;
  cldenseVector y;
  clsparseCsrMatrix A;
}

std::pair<int, int> get_pd_pair();

void set_platform_device(int p, int d)
{
  cl_status = cl::Platform::get(&platforms);
  if(cl_status != CL_SUCCESS) {
    std::cout << "Problem getting OpenCL platforms"
              << " [" << cl_status << "]" << '\n';
    std::exit(2);
  }

  platform = &platforms[p];

  cl_status = platform->getDevices(CL_DEVICE_TYPE_ALL, &devices);
  if(cl_status != CL_SUCCESS) {
    std::cout << "Problem getting devices from platform"
              << platform->getInfo<CL_PLATFORM_NAME>()
              << " error: [" << cl_status << "]" << '\n';
  }

  device = &devices[d];
  
  /* std::cout << platform->getInfo<CL_PLATFORM_NAME>() << "\n" */
  /*           << device->getInfo<CL_DEVICE_NAME>() << "\n"; */
}

void init_alpha_beta()
{
  clsparseInitScalar(&alpha);
  alpha.value = clCreateBuffer(context(), CL_MEM_READ_ONLY, 
                               sizeof(double), nullptr, 
                               &cl_status);

  clsparseInitScalar(&beta);
  beta.value = clCreateBuffer(context(), CL_MEM_READ_ONLY, 
                              sizeof(double), nullptr, 
                              &cl_status);

  auto halpha = static_cast<double *>(clEnqueueMapBuffer(
      queue(), alpha.value, CL_TRUE, CL_MAP_WRITE,
      0, sizeof(double), 0, nullptr, nullptr, &cl_status));
  *halpha = 1.0f;
  cl_status = clEnqueueUnmapMemObject(queue(), alpha.value, halpha,
                                      0, nullptr, nullptr);

  auto hbeta = static_cast<double *>(clEnqueueMapBuffer(
        queue(), beta.value, CL_TRUE, CL_MAP_WRITE,
        0, sizeof(double), 0, nullptr, nullptr, &cl_status));
  *hbeta = 0.0f;
  cl_status = clEnqueueUnmapMemObject(queue(), beta.value, hbeta,
                                      0, nullptr, nullptr);
}

void f_init_alpha_beta()
{
  clsparseInitScalar(&alpha);
  alpha.value = clCreateBuffer(context(), CL_MEM_READ_ONLY, 
                               sizeof(float), nullptr, 
                               &cl_status);

  clsparseInitScalar(&beta);
  beta.value = clCreateBuffer(context(), CL_MEM_READ_ONLY, 
                              sizeof(float), nullptr, 
                              &cl_status);

  auto halpha = static_cast<float *>(clEnqueueMapBuffer(
      queue(), alpha.value, CL_TRUE, CL_MAP_WRITE,
      0, sizeof(float), 0, nullptr, nullptr, &cl_status));
  *halpha = 1.0f;
  cl_status = clEnqueueUnmapMemObject(queue(), alpha.value, halpha,
                                      0, nullptr, nullptr);

  auto hbeta = static_cast<float *>(clEnqueueMapBuffer(
        queue(), beta.value, CL_TRUE, CL_MAP_WRITE,
        0, sizeof(float), 0, nullptr, nullptr, &cl_status));
  *hbeta = 0.0f;
  cl_status = clEnqueueUnmapMemObject(queue(), beta.value, hbeta,
                                      0, nullptr, nullptr);
}

void setup(int rows, int cols, int nnz)
{
  static bool ready = false;
  if(!ready) {
    auto pair = get_pd_pair();
    set_platform_device(pair.first, pair.second);

    context = cl::Context(*device);
    queue = cl::CommandQueue(context, *device);
    
    // Setup clsparse
    status = clsparseSetup();
    if(status != clsparseSuccess) {
      std::cout << "Problem setting up clSPARSE\n";
      std::exit(3);
    }

    auto createResult = clsparseCreateControl(queue());
    CLSPARSE_V(createResult.status, "Failed to create status control");
    control = createResult.control;

    init_alpha_beta();

    clsparseInitVector(&x);
    clsparseInitVector(&y);
    clsparseInitCsrMatrix(&A);

    // Setup GPU buffers
    ready = true;
  }

  static int last_rows = -1;
  static int last_cols = -1;
  static int last_nnzA = -1;
  if(cols != last_cols || rows != last_rows || nnz != last_nnzA) {
    A.num_rows = rows;
    A.num_cols = cols;
    A.num_nonzeros = nnz;

    x.num_values = A.num_cols;
    y.num_values = A.num_rows;

    if(A.values) { clReleaseMemObject(A.values); }
    if(A.col_indices) { clReleaseMemObject(A.col_indices); }
    if(A.row_pointer) { clReleaseMemObject(A.row_pointer); }
    if(x.values) { clReleaseMemObject(x.values); }
    if(y.values) { clReleaseMemObject(y.values); }

    A.values = clCreateBuffer(context(), CL_MEM_READ_ONLY, 
                              sizeof(double) * A.num_nonzeros, 
                              nullptr, &cl_status);

    A.col_indices = clCreateBuffer(context(), CL_MEM_READ_ONLY, 
                                   sizeof(int) * A.num_nonzeros, 
                                   nullptr, &cl_status);

    A.row_pointer = clCreateBuffer(context(), CL_MEM_READ_ONLY, 
                                   sizeof(int) * (A.num_rows + 1), 
                                   nullptr, &cl_status);

    x.values = clCreateBuffer(context(), CL_MEM_READ_ONLY, 
                              x.num_values * sizeof(double),
                              nullptr, &cl_status);

    y.values = clCreateBuffer(context(), CL_MEM_READ_ONLY, 
                              y.num_values * sizeof(double),
                              nullptr, &cl_status);

    last_cols = cols;
    last_rows = rows;
    last_nnzA = nnz;
  }
}

void f_setup(int rows, int cols, int nnz)
{
  static bool ready = false;
  if(!ready) {
    auto pair = get_pd_pair();
    set_platform_device(pair.first, pair.second);

    context = cl::Context(*device);
    queue = cl::CommandQueue(context, *device);
    
    // Setup clsparse
    status = clsparseSetup();
    if(status != clsparseSuccess) {
      std::cout << "Problem setting up clSPARSE\n";
      std::exit(3);
    }

    auto createResult = clsparseCreateControl(queue());
    CLSPARSE_V(createResult.status, "Failed to create status control");
    control = createResult.control;

    f_init_alpha_beta();

    clsparseInitVector(&x);
    clsparseInitVector(&y);
    clsparseInitCsrMatrix(&A);

    // Setup GPU buffers
    ready = true;
  }

  static int last_rows = -1;
  static int last_cols = -1;
  static int last_nnzA = -1;
  if(cols != last_cols || rows != last_rows || nnz != last_nnzA) {
    A.num_rows = rows;
    A.num_cols = cols;
    A.num_nonzeros = nnz;

    x.num_values = A.num_cols;
    y.num_values = A.num_rows;

    if(A.values) { clReleaseMemObject(A.values); }
    if(A.col_indices) { clReleaseMemObject(A.col_indices); }
    if(A.row_pointer) { clReleaseMemObject(A.row_pointer); }
    if(x.values) { clReleaseMemObject(x.values); }
    if(y.values) { clReleaseMemObject(y.values); }

    A.values = clCreateBuffer(context(), CL_MEM_READ_ONLY, 
                              sizeof(float) * A.num_nonzeros, 
                              nullptr, &cl_status);

    A.col_indices = clCreateBuffer(context(), CL_MEM_READ_ONLY, 
                                   sizeof(int) * A.num_nonzeros, 
                                   nullptr, &cl_status);

    A.row_pointer = clCreateBuffer(context(), CL_MEM_READ_ONLY, 
                                   sizeof(int) * (A.num_rows + 1), 
                                   nullptr, &cl_status);

    x.values = clCreateBuffer(context(), CL_MEM_READ_ONLY, 
                              x.num_values * sizeof(float),
                              nullptr, &cl_status);

    y.values = clCreateBuffer(context(), CL_MEM_READ_ONLY, 
                              y.num_values * sizeof(float),
                              nullptr, &cl_status);

    last_cols = cols;
    last_rows = rows;
    last_nnzA = nnz;
  }
}

extern "C" {

void* spmv_harness_(double* ov, double* a, double* iv, int* rowstr, int* colidx, int* rows)
{
  int n_rows = *rows;
  int n_cols = 0;
  for(int i = rowstr[0] - 1; i < rowstr[n_rows] - 1; i++)
      if(colidx[i] >= n_cols) n_cols = colidx[i];
  int nnzA = rowstr[n_rows] - rowstr[0];

  setup(n_rows, n_cols, nnzA);

  cl_status = clEnqueueWriteBuffer(queue(), A.values, true, 0, 
                                   sizeof(double) * A.num_nonzeros, a, 
                                   0, nullptr, nullptr);

  auto one_based = new int[A.num_nonzeros + A.num_rows + 1];
  const auto sub_one = [](int v) { return v - 1; };

  auto it = std::transform(colidx, colidx + A.num_nonzeros, one_based, sub_one);
  std::transform(rowstr, rowstr + A.num_rows + 1, it, sub_one);

  cl_status = clEnqueueWriteBuffer(queue(), A.col_indices, true, 0,
                                   sizeof(int) * A.num_nonzeros, one_based,
                                   0, nullptr, nullptr);

  cl_status = clEnqueueWriteBuffer(queue(), A.row_pointer, true, 0,
                                   sizeof(int) * (A.num_rows + 1), 
                                   one_based + A.num_nonzeros,
                                   0, nullptr, nullptr);

  //clsparseCsrMetaCreate(&A, control);

  delete[] one_based;

  cl_status = clEnqueueWriteBuffer(queue(), y.values, true, 0,
                                   sizeof(double) * y.num_values, ov,
                                   0, nullptr, nullptr);

  cl_status = clEnqueueWriteBuffer(queue(), x.values, true, 0,
                                 sizeof(double) * x.num_values, iv,
                                 0, nullptr, nullptr);

  status = clsparseDcsrmv(&alpha, &A, &x, &beta, &y, control);
  if(status != clsparseSuccess) {
    std::cout << "Problem performing SPMV!\n";
  }

  cl_status = clEnqueueReadBuffer(queue(), y.values, true, 0, sizeof(double) * y.num_values, ov, 0, nullptr, nullptr);
}

void* f_spmv_harness_(float* ov, float* a, float* iv, int* rowstr, int* colidx, int* rows)
{
  int n_rows = *rows;
  int n_cols = 0;
  for(int i = rowstr[0] - 1; i < rowstr[n_rows] - 1; i++)
      if(colidx[i] >= n_cols) n_cols = colidx[i];
  int nnzA = rowstr[n_rows] - rowstr[0];

  f_setup(n_rows, n_cols, nnzA);

  cl_status = clEnqueueWriteBuffer(queue(), A.values, true, 0, 
                                   sizeof(float) * A.num_nonzeros, a, 
                                   0, nullptr, nullptr);

  auto one_based = new int[A.num_nonzeros + A.num_rows + 1];
  const auto sub_one = [](int v) { return v - 1; };

  auto it = std::transform(colidx, colidx + A.num_nonzeros, one_based, sub_one);
  std::transform(rowstr, rowstr + A.num_rows + 1, it, sub_one);

  cl_status = clEnqueueWriteBuffer(queue(), A.col_indices, true, 0,
                                   sizeof(int) * A.num_nonzeros, one_based,
                                   0, nullptr, nullptr);

  cl_status = clEnqueueWriteBuffer(queue(), A.row_pointer, true, 0,
                                   sizeof(int) * (A.num_rows + 1), 
                                   one_based + A.num_nonzeros,
                                   0, nullptr, nullptr);

  //clsparseCsrMetaCreate(&A, control);

  delete[] one_based;

  cl_status = clEnqueueWriteBuffer(queue(), y.values, true, 0,
                                   sizeof(float) * y.num_values, ov,
                                   0, nullptr, nullptr);

  cl_status = clEnqueueWriteBuffer(queue(), x.values, true, 0,
                                   sizeof(float) * x.num_values, iv,
                                   0, nullptr, nullptr);


  status = clsparseScsrmv(&alpha, &A, &x, &beta, &y, control);
  if(status != clsparseSuccess) {
    std::cout << "Problem performing SPMV!\n";
  }

  cl_status = clEnqueueReadBuffer(queue(), y.values, true, 0, sizeof(float) * y.num_values, ov, 0, nullptr, nullptr);
}

}
