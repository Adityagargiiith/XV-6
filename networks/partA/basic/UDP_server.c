#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <time.h> // Added for random number generation

int main(int argc, char **argv) {

    if (argc != 3) {
        printf("Usage: %s <port1> <port2>\n", argv[0]);
        exit(0);
    }

    char *ip = "127.0.0.1";
    int port1 = atoi(argv[1]);
    int port2 = atoi(argv[2]);

    int sockfd1, sockfd2;
    struct sockaddr_in server_addr1, server_addr2, client_addr;
    char buffer1[1024], buffer2[1024];

    socklen_t addr_size;
    int n;

    sockfd1 = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd1 < 0) {
        perror("[-]socket error for port 1");
        exit(1);
    }

    sockfd2 = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd2 < 0) {
        perror("[-]socket error for port 2");
        exit(1);
    }

    memset(&server_addr1, '\0', sizeof(server_addr1));
    server_addr1.sin_family = AF_INET;
    server_addr1.sin_port = htons(port1);
    server_addr1.sin_addr.s_addr = inet_addr(ip);

    memset(&server_addr2, '\0', sizeof(server_addr2));
    server_addr2.sin_family = AF_INET;
    server_addr2.sin_port = htons(port2);
    server_addr2.sin_addr.s_addr = inet_addr(ip);

    n = bind(sockfd1, (struct sockaddr*)&server_addr1, sizeof(server_addr1));
    if (n < 0) {
        perror("[-]bind error for port 1");
        exit(1);
    }

    n = bind(sockfd2, (struct sockaddr*)&server_addr2, sizeof(server_addr2));
    if (n < 0) {
        perror("[-]bind error for port 2");
        exit(1);
    }
    
    // while (1) {
           bzero(buffer1, 1024);
        addr_size = sizeof(client_addr);
        recvfrom(sockfd1, buffer1, 1024, 0, (struct sockaddr*)&client_addr, &addr_size);
        int choice1 = atoi(buffer1);
        printf("[Client 1] Choice: %d\n", choice1);

        // Receive choices from client 2
        bzero(buffer2, 1024);
        addr_size = sizeof(client_addr);
        recvfrom(sockfd2, buffer2, 1024, 0, (struct sockaddr*)&client_addr, &addr_size);
        int choice2 = atoi(buffer2);
        printf("[Client 2] Choice: %d\n", choice2);
    

        // Generate a random choice for the server (0: Rock, 1: Paper, 2: Scissors)
        // srand(time(NULL));
        // int server_choice = rand() % 3;
        char resultA[50];
        char resultB[50];

        if (choice1 == 0 && choice2 == 0 || choice1 == 1 && choice2 == 1 || choice1 == 2 && choice2 == 2){
            strcpy(resultA,"Draw");
            strcpy(resultB,"Draw");
            // printf("%s",resultA);

            sendto(sockfd1, resultA, sizeof(resultA), 0, (const struct sockaddr*)&client_addr, sizeof(client_addr));
            printf("Results send");
        }
        //  else if (choice1 == 0 && choice2 == 2 || choice1 == 1 && choice2 == 0 || choice1 == 2 && choice2 == 0){
        //     printf("Draw");
        // }
        //     server_choice == 1 && strcmp(buffer, "Paper") == 0 ||
        //     server_choice == 2 && strcmp(buffer, "Scissors") == 0) {
        //     strcpy(result, "Draw");
        // } else if (server_choice == 0 && strcmp(buffer, "Scissors") == 0 ||
        //            server_choice == 1 && strcmp(buffer, "Rock") == 0 ||
        //            server_choice == 2 && strcmp(buffer, "Paper") == 0) {
        //     strcpy(result, "Server wins");
        // } else {
        //     strcpy(result, "Client wins");
        // }

        // // Send the result to the client
        // sendto(sockfd, result, strlen(result), 0, (struct sockaddr*)&client_addr, sizeof(client_addr));
    // }

    return 0;
}
