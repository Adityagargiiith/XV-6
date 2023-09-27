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
    struct sockaddr_in server_addr1, server_addr2, client_addr1,client_addr2;
    char buffer1[1024], buffer2[1024];

    socklen_t addr_size1,addr_size2;
    int n1,n2;

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

    n1 = bind(sockfd1, (struct sockaddr*)&server_addr1, sizeof(server_addr1));
    if (n1 < 0) {
        perror("[-]bind error for port 1");
        exit(1);
    }

    n2 = bind(sockfd2, (struct sockaddr*)&server_addr2, sizeof(server_addr2));
    if (n2 < 0) {
        perror("[-]bind error for port 2");
        exit(1);
    }
    
    while (1) {
           bzero(buffer1, 1024);
        addr_size1 = sizeof(client_addr1);
        recvfrom(sockfd1, buffer1, 1024, 0, (struct sockaddr*)&client_addr1, &addr_size1);
        int choice1 = atoi(buffer1);
        printf("[Client 1] Choice: %d\n", choice1);

        // Receive choices from client 2
        bzero(buffer2, 1024);
        addr_size2 = sizeof(client_addr2);
        recvfrom(sockfd2, buffer2, 1024, 0, (struct sockaddr*)&client_addr2, &addr_size2);
        int choice2 = atoi(buffer2);
        printf("[Client 2] Choice: %d\n", choice2);
    

        // Generate a random choice for the server (0: Rock, 1: Paper, 2: Scissors)
        // srand(time(NULL));
        // int server_choice = rand() % 3;
        char resultA[50];
        char resultB[50];
        bzero(buffer1,1024);
        bzero(buffer2,1024);

        if (choice1 == 0 && choice2 == 0 || choice1 == 1 && choice2 == 1 || choice1 == 2 && choice2 == 2){
            strcpy(buffer1,"Draw");
            strcpy(buffer2,"Draw");
            // printf("%s",resultA);

            sendto(sockfd1, buffer1, 1024, 0, (const struct sockaddr*)&client_addr1, sizeof(client_addr1));
            sendto(sockfd2, buffer2, 1024, 0, (const struct sockaddr*)&client_addr2, sizeof(client_addr2));
            printf("Results send\n");
        }
         else if (choice1 == 0 && choice2 == 2 || choice1 == 1 && choice2 == 0 || choice1 == 2 && choice2 == 1){
            strcpy(buffer1,"Win");
            strcpy(buffer2,"Lose");
            sendto(sockfd1, buffer1, 1024, 0, (const struct sockaddr*)&client_addr1, sizeof(client_addr1));
            sendto(sockfd2, buffer2, 1024, 0, (const struct sockaddr*)&client_addr2, sizeof(client_addr2));
            printf("Results send\n");
            // printf("Draw");
        }
        else{
            strcpy(buffer1,"Lose");
            strcpy(buffer2,"Win");
            sendto(sockfd1, buffer1, 1024, 0, (const struct sockaddr*)&client_addr1, sizeof(client_addr1));
            sendto(sockfd2, buffer2, 1024, 0, (const struct sockaddr*)&client_addr2, sizeof(client_addr2));
            printf("Results send\n");
        }
                bzero(buffer1,1024);
        bzero(buffer2,1024);

        recvfrom(sockfd1, buffer1, sizeof(int), 0, (struct sockaddr*)&client_addr1, &addr_size1);
        int play1 = atoi(buffer1);
        // printf("[Client 1] Choice: %s\n", buffer1);

        recvfrom(sockfd2, buffer2, sizeof(int), 0, (struct sockaddr*)&client_addr2, &addr_size2);
        int play2 = atoi(buffer2);
        // printf("[Client 2] Choice: %s\n", buffer2);

if(play1==0 || play2==0){
      bzero(buffer1,1024);
    bzero(buffer2,1024);
     strcpy(buffer1,"1");
            strcpy(buffer2,"1");
            sendto(sockfd1, buffer1, 1024, 0, (const struct sockaddr*)&client_addr1, sizeof(client_addr1));
            sendto(sockfd2, buffer2, 1024, 0, (const struct sockaddr*)&client_addr2, sizeof(client_addr2));
            break;
}
else{
        bzero(buffer1,1024);
    bzero(buffer2,1024);
     strcpy(buffer1,"0");
            strcpy(buffer2,"0");
            sendto(sockfd1, buffer1, 1024, 0, (const struct sockaddr*)&client_addr1, sizeof(client_addr1));
            sendto(sockfd2, buffer2, 1024, 0, (const struct sockaddr*)&client_addr2, sizeof(client_addr2));
}

    }
    return 0;
}
