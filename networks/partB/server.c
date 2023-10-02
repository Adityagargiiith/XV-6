#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define CHUNK_SIZE 10 // Adjust the chunk size as needed
#define MAX_CHUNKS 100
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

    while (received_count < MAX_CHUNKS) {
        struct Chunk chunk;
        ssize_t bytes_received = recvfrom(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)&client_addr, &addr_size);

        if (bytes_received == -1) {
            perror("recvfrom");
            exit(1);
        }

        received_chunks[chunk.sequence_number] = chunk;
        received_count++;

        // Check if we have received all chunks
        if (chunk.sequence_number == -1) {
            printf("Received Data: ");
            for (int i = 0; i < received_count-1; i++) {
                printf("%s", received_chunks[i].data);
            }
            printf("\n");
            break;
        }
    }

    close(sockfd);
    return 0;
}
