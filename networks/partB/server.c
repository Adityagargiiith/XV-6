#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include <time.h>


#define CHUNK_SIZE 10 // Adjust the chunk size as needed
#define MAX_CHUNKS 100
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

    while (received_count < MAX_CHUNKS) {
        struct Chunk chunk;
        ssize_t bytes_received = recvfrom(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)&client_addr, &addr_size);

        if (bytes_received == -1) {
            perror("recvfrom");
            exit(1);
        }
        int ack_sequence_number = chunk.sequence_number;
        //  if (rand() % 3 != 0) {
            // sendto(sockfd, &ack_sequence_number, sizeof(ack_sequence_number), 0, (struct sockaddr *)&client_addr, addr_size);
        sendto(sockfd, &ack_sequence_number, sizeof(ack_sequence_number), 0, (struct sockaddr *)&client_addr, addr_size);
        // }
        printf("Acknowledged sent\n");

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
        // Set up timeout for the next chunk reception
        FD_ZERO(&read_fds);
        FD_SET(sockfd, &read_fds);
        timeout.tv_sec = TIMEOUT_SEC;
        timeout.tv_usec = TIMEOUT_USEC;

        select_result = select(sockfd + 1, &read_fds, NULL, NULL, &timeout);
        if (select_result == -1) {
            perror("select");
            exit(1);
        }
        else if (select_result == 0) {
            printf("Timeout occurred. Resending last ACK.\n");
            sendto(sockfd, &ack_sequence_number, sizeof(ack_sequence_number), 0, (struct sockaddr *)&client_addr, addr_size);
        }
    }

    close(sockfd);
    return 0;
}
