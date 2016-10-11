#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda.h>
#include <sys/time.h>
#define MAX_THREADS_PER_BLOCK 512 

int no_of_nodes;
int edge_list_size;
FILE *fp;

//Structure to hold a node information
struct Node
{
	int starting;
	int no_of_edges;
};

__global__ void 
Kernel3(Node* g_graph_nodes, int* g_graph_edges,int* cd, bool* f1d, bool *f2d,int no_of_nodes,bool *md)
{
        int i = blockIdx.x*MAX_THREADS_PER_BLOCK + threadIdx.x;
	//int idx, idxi;
	//printf("\n Thread id:  %d",i);
	int  ci, cj; 	
	if(f1d[i]==true)
	{
		f1d[i]=false;
	
		ci=cd[i];
		bool cimod=false;
		int temp;
for(int j=g_graph_nodes[i].starting;j<(g_graph_nodes[i].starting + g_graph_nodes[i].no_of_edges); j++)
		{
			temp=g_graph_edges[j];
			cj = cd[temp];
			if ( ci < cj )
			{
				atomicMin(&cd[temp],ci);
				f2d[temp]=true;
				*md=true;				
			}
			else
			if (ci>cj)
			{
				ci=cj;
				cimod=true;
			}	
		}
		
		if(cimod==true)
		{
			atomicMin(&cd[i],ci);
			f2d[i]=true;
			*md=true;
		}
	
	}
	//	printf("\n End of kernel:  %d", cd[i]);
}


long long start_timer();
long long stop_timer(long long start_time, char *name);


void GPLGraph(int argc, char** argv);

////////////////////////////////////////////////////////////////////////////////
// Main Program
////////////////////////////////////////////////////////////////////////////////
int main( int argc, char** argv) 
{
	no_of_nodes=0;
	edge_list_size=0;
	GPLGraph( argc, argv);
}

void Usage(int argc, char**argv){

fprintf(stderr,"Usage: %s <input_file>\n", argv[0]);

}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
void GPLGraph( int argc, char** argv) 
{

    char *input_f;
	if(argc!=2){
	Usage(argc, argv);
	exit(0);
	}
	
	input_f = argv[1];
	printf("Reading File\n");
	//Read in Graph from a file
	fp = fopen(input_f,"r");
	if(!fp)
	{
		printf("Error Reading graph file\n");
		return;
	}

	int source = 0;

	fscanf(fp,"%d",&no_of_nodes);

	int num_of_blocks = 1;
	int num_of_threads_per_block = no_of_nodes;

	//Make execution Parameters according to the number of nodes
	//Distribute threads across multiple Blocks if necessary
	if(no_of_nodes>MAX_THREADS_PER_BLOCK)
	{
		num_of_blocks = (int)ceil(no_of_nodes/(double)MAX_THREADS_PER_BLOCK); 
		num_of_threads_per_block = MAX_THREADS_PER_BLOCK; 
	}

	// allocate host memory
	Node* h_graph_nodes = (Node*) malloc(sizeof(Node)*no_of_nodes);

	int start, edgeno;   
	// initalize the memory
	for( unsigned int i = 0; i < no_of_nodes; i++) 
	{
		fscanf(fp,"%d %d",&start,&edgeno);
		h_graph_nodes[i].starting = start;
		h_graph_nodes[i].no_of_edges = edgeno;
	}

	//read the source node from the file
	fscanf(fp,"%d",&source);
	source=0;


	fscanf(fp,"%d",&edge_list_size);

	int id,cost;
	int* h_graph_edges = (int*) malloc(sizeof(int)*edge_list_size);
	for(unsigned int i=0; i < edge_list_size ; i++)
	{
		fscanf(fp,"%d",&id);
		fscanf(fp,"%d",&cost);
		h_graph_edges[i] = id;
	}

	  int* c = (int*) malloc(sizeof(int)*no_of_nodes);
	 bool* f1 = (bool*) malloc(sizeof(bool)*no_of_nodes);
 	bool* f2 = (bool*) malloc(sizeof(bool)*no_of_nodes);       
	bool* f3 = (bool*) malloc(sizeof(bool)*no_of_nodes);


 for(unsigned int i=0; i < no_of_nodes ; i++)
        {
        	c[i]=i;
                f1[i]=true;
                f2[i]=false;
        }
	
	if(fp)
		fclose(fp);    

	printf("Read File\n");

	//Copy the Node list to device memory
	Node* d_graph_nodes;
	cudaMalloc( (void**) &d_graph_nodes, sizeof(Node)*no_of_nodes) ;
	cudaMemcpy( d_graph_nodes, h_graph_nodes, sizeof(Node)*no_of_nodes, cudaMemcpyHostToDevice) ;

	//Copy the Edge List to device Memory
	int* d_graph_edges;
	cudaMalloc( (void**) &d_graph_edges, sizeof(int)*edge_list_size) ;
	cudaMemcpy( d_graph_edges, h_graph_edges, sizeof(int)*edge_list_size, cudaMemcpyHostToDevice) ;

	//Allocate Color Array in device Memory
	int* cd;
	cudaMalloc( (void**) &cd, sizeof(int)*no_of_nodes);
	cudaMemcpy( cd, c, sizeof(int)*no_of_nodes,cudaMemcpyHostToDevice);

	//Allocate Boolean Array in current Iteration
	bool* f1d;
	cudaMalloc( (void**) &f1d, sizeof(bool)*no_of_nodes);
	cudaMemcpy( f1d, f1, sizeof(bool)*no_of_nodes,cudaMemcpyHostToDevice);

	//Allocate Boolean Array for next Iteration
	bool* f2d;
	cudaMalloc( (void**) &f2d, sizeof(bool)*no_of_nodes);
	cudaMemcpy( f2d, f2, sizeof(bool)*no_of_nodes,cudaMemcpyHostToDevice);

 bool* f3d;
        cudaMalloc( (void**) &f3d, sizeof(bool)*no_of_nodes);
       
	
	bool m;
	bool *md;
	cudaMalloc( (void**) &md, sizeof(bool));


	printf("Copied Everything to Kernel");

	// setup execution parameters
	dim3  grid( num_of_blocks, 1, 1);
	dim3  threads( num_of_threads_per_block, 1, 1);
long long timer;
	timer = start_timer();
	int k=0;
	printf("Start traversing the tree\n");
	
	//Call the Kernel untill all the elements of Frontier are not false
	do
	{
		m=false;
		//if no thread changes this value then the loop stops
		cudaMemcpy( md, &m, sizeof(bool), cudaMemcpyHostToDevice) ;
		
Kernel3<<< grid, threads, 0 >>>( d_graph_nodes, d_graph_edges,cd,f1d,f2d, no_of_nodes,md);
		// check if kernel execution generated and error
		
	cudaMemcpy( f1, f1d, sizeof(bool)*no_of_nodes,cudaMemcpyDeviceToHost);
	cudaMemcpy( f2, f2d, sizeof(bool)*no_of_nodes,cudaMemcpyDeviceToHost);
	cudaMemcpy( f1d, f2, sizeof(bool)*no_of_nodes,cudaMemcpyHostToDevice);
 	cudaMemcpy( f2d, f1, sizeof(bool)*no_of_nodes,cudaMemcpyHostToDevice);
	k++;
	cudaMemcpy( &m,md , sizeof(bool), cudaMemcpyDeviceToHost) ;
//		printf("\n \n Return from kernel:   %d",m);
	}
	while(m);


	printf("Kernel Executed %d times\n",k);

	// copy result from device to host
	cudaMemcpy( c,cd, sizeof(int)*no_of_nodes, cudaMemcpyDeviceToHost) ;

	//Store the result into a file
	FILE *fpo = fopen("result.txt","w");
	for(unsigned int i=0;i<no_of_nodes;i++)
		fprintf(fpo,"%d) color:%d\n",i,c[i]);
	fclose(fpo);
	printf("Result stored in result.txt\n");


	// cleanup memory
	free( h_graph_nodes);
	free( h_graph_edges);
	cudaFree(d_graph_nodes);
	cudaFree(d_graph_edges);
	cudaFree(cd);
	cudaFree(f1d);
	cudaFree(f2d);
	//cudaFree(md);
stop_timer(timer, "Total Processing time");



}
long long start_timer() {
	struct timeval tv;
	gettimeofday(&tv, NULL);
	return tv.tv_sec * 1000000 + tv.tv_usec;
}

long long stop_timer(long long start_time, char *label) {
	struct timeval tv;
	gettimeofday(&tv, NULL);
	long long end_time = tv.tv_sec * 1000000 + tv.tv_usec;
	printf("%s: %.5f sec\n", label, ((float) (end_time - start_time)) / (1000 * 1000));
	return end_time - start_time;
}

