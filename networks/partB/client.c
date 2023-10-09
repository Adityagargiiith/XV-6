#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define CHUNK_SIZE 10

struct Chunk {
    int sequence_number;
    char data[CHUNK_SIZE];
};

int main(int argc, char **argv) {
    // int main(int argc, char **argv){

  if (argc != 2) {
    printf("Usage: %s <port>\n", argv[0]);
    exit(0);
  }

  char *ip = "127.0.0.1";
  int port = atoi(argv[1]);

   int sockfd;
  struct sockaddr_in addr;
  char buffer[1024];
  socklen_t addr_size;

  sockfd = socket(AF_INET, SOCK_DGRAM, 0);
  memset(&addr, '\0', sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_port = htons(port);
  addr.sin_addr.s_addr = inet_addr(ip);
    // Example text to send
      bzero(buffer, 1024);
      printf("Enter the text\n");
       if (fgets(buffer, sizeof(buffer), stdin) != NULL) {
        int length = strlen(buffer);
        if (length > 0 && buffer[length - 1] == '\n') {
            buffer[length - 1] = '\0'; 
        }
       }
    int text_len = strlen(buffer);
    int total_chunks = ((text_len) / CHUNK_SIZE)+1; 
    // printf("%d",total_chunks);   

    for (int i = 0; i < total_chunks; i++) {
        struct Chunk chunk;
        chunk.sequence_number = i;

        // Copy a chunk of data
        int data_len;
        if(i == total_chunks - 1)
        {
         data_len =(text_len % CHUNK_SIZE)+1 ;

        }
        else{
            data_len=CHUNK_SIZE;
        }
        strncpy(chunk.data, buffer + i * CHUNK_SIZE, data_len);
        // printf("%s %d\n",chunk.data,data_len);

        // Send the chunk with its sequence number
        sendto(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)&addr, sizeof(addr));
        int ack_sequence_number;
        if (recvfrom(sockfd, &ack_sequence_number, sizeof(ack_sequence_number), 0, NULL, NULL) == -1) {
            perror("recvfrom");
            exit(1);
        }
        printf("Acknowledged recieved with number %d\n",ack_sequence_number);

        // Check if the ACK matches the sequence number
        if (ack_sequence_number != i) {
            printf("Received incorrect ACK for sequence number %d\n", i);
            // You can implement a retry mechanism here if needed
        }
        
    }
    struct Chunk chunk;
    chunk.sequence_number=-1;
    strcpy(chunk.data,"..");
    // chunk.data='wreq';
    sendto(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)&addr, sizeof(addr));

    close(sockfd);
    return 0;
}
