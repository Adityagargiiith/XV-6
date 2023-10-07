#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include <time.h>


#define CHUNK_SIZE 10 // Adjust the chunk size as needed
#define MAX_CHUNKS 10000
#define TIMEOUT_SEC 0 // Timeout in seconds (0 for non-blocking)
#define TIMEOUT_USEC 100000 
struct Chunk {
    int sequence_number;
    char data[CHUNK_SIZE];
};

int main(int argc, char** argv) {
     if (argc != 2){
    printf("Usage: %s <port>\n", argv[0]);
    exit(0);
  }


  char *ip = "127.0.0.1";
  int port = atoi(argv[1]);
int sockfd;
  struct sockaddr_in server_addr, client_addr;
  char buffer[1024];
  socklen_t addr_size;
  int n;

  sockfd = socket(AF_INET, SOCK_DGRAM, 0);
  if (sockfd < 0){
    perror("[-]socket error");
    exit(1);
  }

  memset(&server_addr, '\0', sizeof(server_addr));
  server_addr.sin_family = AF_INET;
  server_addr.sin_port = htons(port);
  server_addr.sin_addr.s_addr = inet_addr(ip);

  n = bind(sockfd, (struct sockaddr*)&server_addr, sizeof(server_addr));
  if (n < 0) {
    perror("[-]bind error");
    exit(1);
  }
  addr_size = sizeof(client_addr);
    struct Chunk received_chunks[MAX_CHUNKS];
    int received_count = 0;
      fd_set read_fds;
    struct timeval timeout;
    int select_result;
    // int array[1000;
    // for(int i=0;i<1000;i++)
    int chunksize;
    ssize_t bytes_received=recvfrom(sockfd, &chunksize, sizeof(chunksize), 0, (struct sockaddr *)&client_addr, &addr_size);
int sizeofchunk=chunksize;
int *array=malloc(sizeof(int)*(sizeofchunk+5));
    memset(array, 0, sizeof(array));
// printf("%d",sizeofchunk);
    while (received_count < MAX_CHUNKS) {
        struct Chunk chunk;
        // printf("%d",received_count);
        ssize_t bytes_received = recvfrom(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)&client_addr, &addr_size);
        if (bytes_received == -1) {
            printf("recieved error");
            exit(1);
        }
        // printf("%d",chunk.sequence_number);

        int ack_sequence_number = chunk.sequence_number;
array[ack_sequence_number]=1;
        // array[chunk.sequence_number]=1;
        // array[chunk.sequence_number]=0;
        //  if (rand() % 3 != 0) {
            // sendto(sockfd, &ack_sequence_number, sizeof(ack_sequence_number), 0, (struct sockaddr *)&client_addr, addr_size);
        // }


        received_count++;

        // Check if we have received all chunks
        if (chunk.sequence_number == -1) {
            break;
        }
        sendto(sockfd, &ack_sequence_number, sizeof(ack_sequence_number), 0, (struct sockaddr *)&client_addr, addr_size);
        printf("Acknowledged sent \n");
        received_chunks[chunk.sequence_number] = chunk;
        
    }
    for (int i = 0; i < MAX_CHUNKS; i++) {
    
            // printf("Requesting retransmission for chunk %d\n", i);
            struct Chunk chunk3;
ssize_t bytes_received=recvfrom(sockfd, &chunk3, sizeof(chunk3), 0, (struct sockaddr *)&client_addr, &addr_size);
        if (bytes_received == -1) {
            printf("recieved error");
            exit(1);
        }
        
int ack_sequence_number = chunk3.sequence_number;
array[ack_sequence_number]=1;
        // array[chunk.sequence_number]=1;
        // array[chunk.sequence_number]=0;
        //  if (rand() % 3 != 0) {
            // sendto(sockfd, &ack_sequence_number, sizeof(ack_sequence_number), 0, (struct sockaddr *)&client_addr, addr_size);
                        printf("Sending acknowledgment for chunk \n");

        sendto(sockfd, &ack_sequence_number, sizeof(ack_sequence_number), 0, (struct sockaddr *)&client_addr, addr_size);


// printf("%d",chunk3.sequence_number);
        received_count++;
        if(chunk3.sequence_number==-2){
            break;
        }

received_chunks[chunk3.sequence_number] = chunk3;
      
        
    }
    for (int i = 0; i < sizeofchunk; i++)
    {
        if (array[i] == 0)
        {
            printf("Sending acknowledgment for chunk \n");

int ack_sequence_number=i;
            sendto(sockfd, &ack_sequence_number, sizeof(ack_sequence_number), 0, (struct sockaddr *)&client_addr, addr_size);

            // printf("%s",request_packet.data);
            // int ack_sequence_number;
        // printf("Acknowledged recieved with number %d\n", ack_sequence_number);
        }
    }

int ack_sequence_number=-2;
            sendto(sockfd, &ack_sequence_number, sizeof(ack_sequence_number), 0, (struct sockaddr *)&client_addr, addr_size);

    printf("Received Data: ");
            for (int i = 0; i < received_count-1; i++) {
                printf("%s", received_chunks[i].data);
            }
            printf("\n");


    close(sockfd);
    return 0;
}
