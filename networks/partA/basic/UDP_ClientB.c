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

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);//DGRAM signifies we are using UDP protocol
    if (sockfd < 0) {
        perror("[-]socket error");
        exit(1);
    }

    memset(&server_addr, '\0', sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr(ip);
    bzero(buffer,1024);// to clear the garbage


    int play_again = 1;

    // while (play_again) {
        int choice;
        printf("Enter your choice (0: Rock, 1: Paper, 2: Scissors): ");
        scanf("%s", buffer);

        sendto(sockfd, &buffer, sizeof(buffer), 0, (const struct sockaddr*)&server_addr, sizeof(server_addr));
        printf("[+] Data send");

    //     int result;
    //     recvfrom(sockfd, &result, sizeof(int), 0, NULL, NULL);

    // addr_size = sizeof(client_addr);
    //     recvfrom(sockfd2, buffer2, 1024, 0, (struct sockaddr*)&client_addr, &addr_size);

    //     if (result == 0)
    //         printf("It's a draw!\n");
    //     else if (result == 1)
    //         printf("You win!\n");
    //     else
    //         printf("You lose!\n");

    //     printf("Do you want to play again? (1 for Yes, 0 for No): ");
    //     scanf("%d", &play_again);
    //     sendto(sockfd, &play_again, sizeof(int), 0, (const struct sockaddr*)&server_addr, sizeof(server_addr));
    // // }

    // close(sockfd);
    return 0;
}
