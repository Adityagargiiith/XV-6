#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <time.h>

#define SERVER_IP "127.0.0.1"
#define SERVER_PORT 12345
#define CHUNK_SIZE 32
#define MAX_SEQ_NUM 100

// Custom packet structure
typedef struct {
    int seq_num;
    char data[CHUNK_SIZE];
} Packet;

int main() {
    int sockfd;
    struct sockaddr_in server_addr;
    socklen_t server_len = sizeof(server_addr);

    // Create a UDP socket
    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        perror("socket");
        exit(1);
    }

    // Initialize server address structure
    memset(&server_addr, 0, server_len);
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(SERVER_PORT);
    inet_pton(AF_INET, SERVER_IP, &server_addr.sin_addr);

    srand(time(NULL));

    int next_seq_num = 0;
    int expected_seq_num = 0;

    while (1) {
        // Simulate sending data
        char data[CHUNK_SIZE];
        snprintf(data, CHUNK_SIZE, "Chunk %d", next_seq_num);

        Packet packet;
        packet.seq_num = next_seq_num;
        strncpy(packet.data, data, CHUNK_SIZE);

        // Send the packet
        sendto(sockfd, &packet, sizeof(packet), 0, (struct sockaddr *)&server_addr, server_len);

        printf("Sent: SeqNum=%d Data=%s\n", next_seq_num, data);

        // Simulate random ACK generation (50% probability)
        if (rand() % 2 == 0) {
            printf("Received ACK for SeqNum=%d\n", expected_seq_num);
            expected_seq_num++;
        }

        // Simulate retransmission if needed
        if (next_seq_num < expected_seq_num + 3) {
            next_seq_num++;
        }

        sleep(1); // Simulate transmission delay
    }

    close(sockfd);
    return 0;
}
