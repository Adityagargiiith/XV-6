#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main(int argc,char** argv){

    if (argc != 2) {
        printf("Usage: %s <port>\n", argv[0]);
        exit(0);
    }

  char *ip = "127.0.0.1";

  int port=atoi(argv[1]);
//   scanf("%d",&por

  int sock;
  struct sockaddr_in addr;
  socklen_t addr_size;
  char buffer[1024];
  int n;

  sock = socket(AF_INET, SOCK_STREAM, 0);
  if (sock < 0){
    perror("[-]Socket error");
    exit(1);
  }
  printf("[+]TCP server socket created.\n");

  memset(&addr, '\0', sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_port = port;
  addr.sin_addr.s_addr = inet_addr(ip);

  connect(sock, (struct sockaddr*)&addr, sizeof(addr));
  printf("Connected to the server.\n");
  while(1){


  bzero(buffer, 1024);
    printf("Enter your choice (0: Rock, 1: Paper, 2: Scissors): ");
  scanf("%s",buffer);
//   strcpy(buffer, "HELLO, THIS IS CLIENT.");
  send(sock, buffer, strlen(buffer), 0);
    printf("[+] Data send\n");
            bzero(buffer,1024);
        // addr_size = sizeof(server_addr);
          recv(sock, buffer, sizeof(buffer), 0);

        // recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr*)&server_addr, &addr_size);
        printf("%s\n",buffer);



        printf("Do you want to play again? (1 for Yes, 0 for No): ");
        bzero(buffer,1024);// to clear the garbage
        scanf("%s", buffer);
        // scanf("%d", &play_again);
          send(sock, buffer, strlen(buffer), 0);

        // sendto(sockfd, &buffer, sizeof(int), 0, (const struct sockaddr*)&server_addr, sizeof(server_addr));
        bzero(buffer,1024);// to clear the garbage
          recv(sock, buffer, sizeof(buffer), 0);

        // recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr*)&server_addr, &addr_size);
        if(strcmp(buffer,"1")==0){
            // printf("yes");
            break;
        }




  // bzero(buffer, 1024);
  // recv(sock, buffer, sizeof(buffer), 0);
  // printf("Server: %s\n", buffer);

  }
  close(sock);
  printf("Disconnected from the server.\n");

  return 0;

}