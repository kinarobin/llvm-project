// RUN: mlir-rocm-runner %s \
// RUN:   --shared-libs=%rocm_wrapper_library_dir/librocm-runtime-wrappers%shlibext \
// RUN:   --entry-point-result=void \
// RUN: | FileCheck %s

func @other_func(%arg0 : f32, %arg1 : memref<?xf32>) {
  %c0 = constant 0 : index
  %c1 = constant 1 : index
  %block_dim = dim %arg1, %c0 : memref<?xf32>
  gpu.launch blocks(%bx, %by, %bz) in (%grid_x = %c1, %grid_y = %c1, %grid_z = %c1)
             threads(%tx, %ty, %tz) in (%block_x = %block_dim, %block_y = %c1, %block_z = %c1) {
    store %arg0, %arg1[%tx] : memref<?xf32>
    gpu.terminator
  }
  return
}

// CHECK: [1, 1, 1, 1, 1]
func @main() {
  %arg0 = alloc() : memref<5xf32>
  %21 = constant 5 : i32
  %22 = memref_cast %arg0 : memref<5xf32> to memref<?xf32>
  %cast = memref_cast %22 : memref<?xf32> to memref<*xf32>
  gpu.host_register %cast : memref<*xf32>
  %23 = memref_cast %22 : memref<?xf32> to memref<*xf32>
  call @print_memref_f32(%23) : (memref<*xf32>) -> ()
  %24 = constant 1.0 : f32
  %25 = call @mgpuMemGetDeviceMemRef1dFloat(%22) : (memref<?xf32>) -> (memref<?xf32>)
  call @other_func(%24, %25) : (f32, memref<?xf32>) -> ()
  call @print_memref_f32(%23) : (memref<*xf32>) -> ()
  return
}

func private @mgpuMemGetDeviceMemRef1dFloat(%ptr : memref<?xf32>) -> (memref<?xf32>)
func private @print_memref_f32(%ptr : memref<*xf32>)
