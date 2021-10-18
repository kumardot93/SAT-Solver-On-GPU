#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <stdbool.h>
#include <time.h>

#define K 3 // K is from K-SAT, currently we are working on 3-SAT

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

int main(){

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

    start = clock();
    int satCount =  cpuSolve(varCount, clauseCount, clauseStore);
    end = clock();
    printf("\n\nSAT Count = %d\n", satCount);

    double executionTime = (double)(end-start)/CLOCKS_PER_SEC;
    printf("execution Time = %lf\n", executionTime);

    return 0;
}
