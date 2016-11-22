#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <time.h>



__global__ void vAdd(float* A, int num_elements, int factor_hilos, float* s){

	//__local__ float a = 0.0;
	//__shared__ float a;

	//if(threadIdx.x == 0) a = 0.0;
		//__syncthreads();

	//Posicion del thread
	int i = (blockIdx.x * blockDim.x + threadIdx.x);


	//printf("Hola desde el hilo %d, en el bloque %d y el hilo %d\n", i, blockIdx.x, threadIdx.x);

	if(i < factor_hilos*num_elements){


		atomicAdd(s, A[i%num_elements]);

		//atomicAdd(&a, 2);
		//A[i%num_elements] = A[i%num_elements] + 1;

	}

	//A[i%num_elements] = a;

	//s = a;

	//printf("%d", s[0]);


}



void fError(cudaError_t err, int i){
	if(err != cudaSuccess){
		printf("%d Ha ocurrido un error con codigo: %s\n", i, cudaGetErrorString(err));
	}
}


int main(){

	//cudaSetDevice(1);

	int num_elements = 1024;
	int factor_hilos = 1;

	//Reservar espacio en memoria HOST


	float * h_A = (float*)malloc(num_elements * sizeof(float));


	if(h_A == NULL ){
		printf("Error al reservar memoria para los vectores HOST");
		exit(1);
	}


	float * h_sum = (float*)malloc(sizeof(float));
	h_sum[0] = 0;


	//Inicializar elementos de los vectores
	for(int i=0; i<num_elements; i++){
		h_A[i] = (float)i;

	}

	cudaError_t err;

	float size = num_elements * sizeof(float);

	float * d_A = NULL;
	err = cudaMalloc((void **)&d_A, size);
	fError(err,1);

	float * d_sum = NULL;
	err = cudaMalloc((void **)&d_sum, sizeof(float));
	fError(err, 3);








	//Copiamos a GPU DEVICE
	err = cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_sum, h_sum, sizeof(float), cudaMemcpyHostToDevice);



	int HilosPorBloque = 256;
	int BloquesPorGrid = (factor_hilos*num_elements + HilosPorBloque -1) / HilosPorBloque;


	cudaError_t Err;

	//Lanzamos el kernel y medimos tiempos
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaEventRecord(start, 0);

	vAdd<<<BloquesPorGrid, HilosPorBloque>>>(d_A, num_elements, factor_hilos, d_sum);
	Err = cudaGetLastError();
	fError(Err,2);

	cudaEventRecord(stop,0);
	cudaEventSynchronize(stop);
	float tiempo_reserva_host;
	cudaEventElapsedTime(&tiempo_reserva_host, start, stop);


	printf("Tiempo de suma vectores DEVICE: %f\n", tiempo_reserva_host);

	cudaEventDestroy(start);
	cudaEventDestroy(stop);


	//Copiamos a CPU el vector C
	err = cudaMemcpy(h_A, d_A, size, cudaMemcpyDeviceToHost);


	cudaMemcpy(h_sum, d_sum, sizeof(float), cudaMemcpyDeviceToHost);




	/*for(int i=0; i<20; i++){
		printf("%f ", h_A[i]);
		//printf("\n");
	}*/

	printf("La suma es: %f", h_sum[0]);

}







