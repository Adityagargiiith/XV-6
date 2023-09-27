#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <time.h> // Added for random number generation

int main(int argc, char **argv) {

    if (argc != 2) {
        printf("Usage: %s <port1> <port2>\n", argv[0]);
        exit(0);
    }

    char *ip = "127.0.0.1";
    int port1 = atoi(argv[1]);
    // int port2 = atoi(argv[2]);

    int sockfd1, sockfd2;
    struct sockaddr_in server_addr1, client_addr;
    char buffer1[1024];

    socklen_t addr_size;
    int n;

    sockfd1 = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd1 < 0) {
        perror("[-]socket error for port 1");
        exit(1);
    }


    memset(&server_addr1, '\0', sizeof(server_addr1));
    server_addr1.sin_family = AF_INET;
    server_addr1.sin_port = htons(port1);
    server_addr1.sin_addr.s_addr = inet_addr(ip);


    n = bind(sockfd1, (struct sockaddr*)&server_addr1, sizeof(server_addr1));
    if (n < 0) {
        perror("[-]bind error for port 1");
        exit(1);
    }

    
    // while (1) {
           bzero(buffer1, 1024);
        addr_size = sizeof(client_addr);
        recvfrom(sockfd1, buffer1, 1024, 0, (struct sockaddr*)&client_addr, &addr_size);
        int choice1 = atoi(buffer1);
        printf("[Client 1] Choice: %d\n", choice1);

        // Receive choices from client 2
    
        
        bzero(buffer1,1024);

        // if (choice1 == 0 && choice2 == 0 || choice1 == 1 && choice2 == 1 || choice1 == 2 && choice2 == 2){
        //     strcpy(buffer1,"Draw");
            strcpy(buffer1,"Draw");
            // printf("%s",resultA);

            sendto(sockfd1, buffer1, 1024, 0, (const struct sockaddr*)&client_addr, sizeof(client_addr));
            printf("Results send");
        // }

    return 0;
}
