#include <cuda_runtime.h>
#include <cublas_v2.h>
#include <cusparse.h>

#include <assert.h>
#include <stdbool.h>

static cublasHandle_t cublasH = NULL;
static cusparseHandle_t cusparseH = NULL;
static cudaStream_t stream = NULL;
static cusparseMatDescr_t descrA = NULL;

static cublasStatus_t cublasStat = CUBLAS_STATUS_SUCCESS;
static cusparseStatus_t cusparseStat = CUSPARSE_STATUS_SUCCESS;

static cudaError_t cudaStat1 = cudaSuccess;
static cudaError_t cudaStat2 = cudaSuccess;
static cudaError_t cudaStat3 = cudaSuccess;
static cudaError_t cudaStat4 = cudaSuccess;
static cudaError_t cudaStat5 = cudaSuccess;

static int *d_csrRowPtrA = NULL;
static int *d_csrColIndA = NULL;
static double *d_csrValA = NULL;
static double *d_x = NULL;
static double *d_y = NULL;

static double h_one = 1.0;
static double h_zero = 0.0;

static int last_n = -1;
static int last_nnzA = -1;

void setup(int n, int nnzA)
{
  static bool ready = false;
  if(!ready) {
    // Set up CUDA libraries
    cudaStat1 = cudaStreamCreateWithFlags(&stream, cudaStreamNonBlocking);
    assert(cudaSuccess == cudaStat1);

    cublasStat = cublasCreate(&cublasH);
    assert(CUBLAS_STATUS_SUCCESS == cublasStat);

    cublasStat = cublasSetStream(cublasH, stream);
    assert(CUBLAS_STATUS_SUCCESS == cublasStat);

    cusparseStat = cusparseCreate(&cusparseH);
    assert(CUSPARSE_STATUS_SUCCESS == cusparseStat);

    cusparseStat = cusparseSetStream(cusparseH, stream);
    assert(CUSPARSE_STATUS_SUCCESS == cusparseStat);

    // Set up matrix
    cusparseStat = cusparseCreateMatDescr(&descrA);
    assert(CUSPARSE_STATUS_SUCCESS == cusparseStat);

    cusparseSetMatIndexBase(descrA,CUSPARSE_INDEX_BASE_ONE);
    cusparseSetMatType(descrA, CUSPARSE_MATRIX_TYPE_GENERAL );

    ready = true;
  }

  if(n != last_n || nnzA != last_nnzA) {
    cudaStat1 = cudaMalloc ((void**)&d_csrRowPtrA, sizeof(int) * (n+1) );
    cudaStat2 = cudaMalloc ((void**)&d_csrColIndA, sizeof(int) * nnzA );
    cudaStat3 = cudaMalloc ((void**)&d_csrValA   , sizeof(double) * nnzA );
    cudaStat4 = cudaMalloc ((void**)&d_x         , sizeof(double) * n );
    cudaStat5 = cudaMalloc ((void**)&d_y         , sizeof(double) * n );

    assert(cudaSuccess == cudaStat1);
    assert(cudaSuccess == cudaStat2);
    assert(cudaSuccess == cudaStat3);
    assert(cudaSuccess == cudaStat4);
    assert(cudaSuccess == cudaStat5);

    last_n = n;
    last_nnzA = nnzA;
  }
}

void* spmv_harness_(double* ov, double* a, double* iv, int* rowstr, int* colidx, int* rows)
{
  int n = *rows + 1;
  int nnzA = rowstr[n] - rowstr[0];

  setup(n, nnzA);

  // Do device copy
  cudaStat1 = cudaMemcpy(d_csrRowPtrA, rowstr, sizeof(int) * (n+1)   , cudaMemcpyHostToDevice);
  cudaStat2 = cudaMemcpy(d_csrColIndA, colidx, sizeof(int) * nnzA    , cudaMemcpyHostToDevice);
  cudaStat3 = cudaMemcpy(d_csrValA   , a   , sizeof(double) * nnzA , cudaMemcpyHostToDevice);
  assert(cudaSuccess == cudaStat1);
  assert(cudaSuccess == cudaStat2);
  assert(cudaSuccess == cudaStat3);
  
  cudaStat1 = cudaMemcpy(d_x, iv, sizeof(double) * n, cudaMemcpyHostToDevice);
  assert(cudaSuccess == cudaStat1);

  // Do the SPMV
  cusparseStat = cusparseDcsrmv_mp(cusparseH,
                                   CUSPARSE_OPERATION_NON_TRANSPOSE,
                                   n,
                                   n,
                                   nnzA,
                                   &h_one,
                                   descrA,
                                   d_csrValA,
                                   d_csrRowPtrA,
                                   d_csrColIndA,
                                   d_x,
                                   &h_zero,
                                   d_y);
  assert(CUSPARSE_STATUS_SUCCESS == cusparseStat);

  cudaStat1 = cudaMemcpy(ov, d_y, sizeof(double) * n, cudaMemcpyDeviceToHost);
  assert(cudaSuccess == cudaStat1);

  return NULL;
}
