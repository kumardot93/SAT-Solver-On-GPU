#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <stdbool.h>
#include <time.h>

#define K 3 // K is from K-SAT, currently we are working on 3-SAT
#define THREAD_PER_BLOCK_log2 10

// current Var Limit is 32;


void preProcessing(){

    // removes comment      
    while(getchar() == 'c'){
        while(getchar()!='\n');
    }
     
    getchar();
    char format[100];
    scanf("%s", format);
    if(strcmp(format, "cnf") != 0){    // format assertion
        printf("Format Error, expected cnf but %s was provided\n", format);
        exit(1);
    }    
    printf("Preprocessing Successfull\n");

}

int cpuSolve(int varCount, int clauseCount, int* clauseStore){
    int limit = pow(2, varCount);
    int satCount = 0;    

    for(int perIndex=0; perIndex<limit; perIndex++){
        bool result = true;
        
        for(int i=0; i<clauseCount; i++){
            bool clauseResult = false;
            for(int j=0; j<K; j++){
                int var = clauseStore[K*i + j];
                int absVar = abs(var);
                bool varValue;
                if(var < 0)
                    varValue = !((perIndex >> (absVar-1))&1);
                else 
                    varValue = (perIndex >> (absVar-1))&1;
                clauseResult = clauseResult || varValue;
            }
            result = result  && clauseResult;
        }
        if(result)
            satCount++;

//        if(perIndex%10000 == 0)
//            printf("completed  = %d\n", perIndex);
    } 
    
    return satCount;
}

__global__ void gpuSolver(int varCount, int clauseCount, int limit, int* clauseStore, int *gpu_sat_count){
    bool result = true;
    int perIndex = (blockIdx.x << THREAD_PER_BLOCK_log2) + threadIdx.x;
    
    if(perIndex >= limit)
        return;

    for(int i=0; i<clauseCount; i++){
    bool clauseResult = false;
        for(int j=0; j<K; j++){
            int var = clauseStore[K*i + j];
            int absVar = abs(var);
            bool varValue;
            if(var < 0)
                varValue = !((perIndex >> (absVar-1))&1);
            else
                varValue = (perIndex >> (absVar-1))&1;
            clauseResult = clauseResult || varValue;
        }
        result = result  && clauseResult;
    }
    if(result)
        atomicAdd(gpu_sat_count, 1);
}

int main(int argc, char* argv[]){
    if(argc<2){
        printf("Invalid Options: One options is required to indetity type of execution\n");
        return 1;
    }

    preProcessing();

    int varCount, clauseCount;
    scanf("%d%d", &varCount, &clauseCount);
   
    printf("\nNo. of Variables = %d | No. of clauses = %d\n", varCount, clauseCount); 

	
    // clauses Input
    int *clauseStore = (int*)malloc(sizeof(int)*clauseCount*K);
    
    for(int i=0; i<clauseCount; i++){

        for(int j=0; j<K; j++){ // one clause with K variables
            scanf("%d", clauseStore + (K * i) + j);
        }

        int tmp;
        scanf("%d\n", &tmp);
    }

    clock_t start, end;

    /* for(int i=0; i<clauseCount; i++){
        for(int j=0; j<K; j++){
            printf("%d ", clauseStore[K*i + j]);
        }
        printf("\n");
    } */

    if(strcmp(argv[1], "cpu")==0){  // cpu implementations
        start = clock();
        int satCount =  cpuSolve(varCount, clauseCount, clauseStore);
        end = clock();
        printf("\n\nSAT Count = %d\n", satCount);
    }
    else if(strcmp(argv[1], "gpu") ==0){        // gpu implementations
        int *gpuClauseStore;
        cudaMalloc(&gpuClauseStore, sizeof(int)*clauseCount*K);
        cudaMemcpy(gpuClauseStore, clauseStore, sizeof(int)*clauseCount*K, cudaMemcpyHostToDevice);    
    
        int *gpu_sat_count;
        cudaMalloc(&gpu_sat_count, sizeof(int));
        cudaMemset(gpu_sat_count, 0, sizeof(int));
        cudaDeviceSynchronize();
        int limit = pow(2, varCount);
        int threadPerBlock = pow(2, THREAD_PER_BLOCK_log2);
        int noOfBlock = ceil((float)limit / threadPerBlock);
        
        start = clock();
        gpuSolver<<<noOfBlock, threadPerBlock>>>(varCount, clauseCount, limit, gpuClauseStore, gpu_sat_count);
        cudaDeviceSynchronize();
        end = clock();

        int *satCount= (int*)malloc(sizeof(int));
        cudaMemcpy(satCount, gpu_sat_count,  sizeof(int), cudaMemcpyDeviceToHost);
        printf("\n\nSAT Count = %d\n", *satCount);
    }
    else{
        printf("Invalid Option");
        return 0;
    }

    double executionTime = (double)(end-start)/CLOCKS_PER_SEC;
    printf("execution Time = %lf\n", executionTime);

    return 0;
}
