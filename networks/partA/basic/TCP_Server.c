#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main(int argc,char **argv){

    if (argc != 3) {
        printf("Usage: %s <port>\n", argv[0]);
        exit(0);
    }

  char *ip = "127.0.0.1";
  int port1=atoi(argv[1]);
  int port2=atoi(argv[2]);
//   scanf("%d",&port);

  int server_sock1, client_sock1,server_sock2,client_sock2;
  struct sockaddr_in server_addr1, client_addr1,server_addr2,client_addr2;
  socklen_t addr_size1,addr_size2;
  char buffer1[1024];
  char buffer2[1024];
  int n1,n2;

  server_sock1 = socket(AF_INET, SOCK_STREAM, 0);
  if (server_sock1 < 0){
    perror("[-]Socket error");
    exit(1);
  }
  printf("[+]TCP server socket 1 created.\n");
  server_sock2 = socket(AF_INET, SOCK_STREAM, 0);
  if (server_sock2 < 0){
    perror("[-]Socket error");
    exit(1);
  }
    printf("[+]TCP server socket 2 created.\n");


  memset(&server_addr1, '\0', sizeof(server_addr1));
  server_addr1.sin_family = AF_INET;
  server_addr1.sin_port = port1;
  server_addr1.sin_addr.s_addr = inet_addr(ip);


  memset(&server_addr2, '\0', sizeof(server_addr2));
  server_addr2.sin_family = AF_INET;
  server_addr2.sin_port = port2;
  server_addr2.sin_addr.s_addr = inet_addr(ip);

  n1 = bind(server_sock1, (struct sockaddr*)&server_addr1, sizeof(server_addr1));
  if (n1 < 0){
    perror("[-]Bind error");
    exit(1);
  }
  printf("[+]Bind to the port number: %d\n", port1);

  n2 = bind(server_sock2, (struct sockaddr*)&server_addr2, sizeof(server_addr2));
  if (n1 < 0){
    perror("[-]Bind error");
    exit(1);
  }

    printf("[+]Bind to the port number: %d\n", port2);


  listen(server_sock1, 5);
    listen(server_sock2, 5);

  printf("Listening...\n");

// /  while(1){
    addr_size1 = sizeof(client_addr1);
    client_sock1 = accept(server_sock1, (struct sockaddr*)&client_addr1, &addr_size1);
    printf("[+]ClientA connected.\n");
    addr_size2 = sizeof(client_addr2);
    client_sock2 = accept(server_sock2, (struct sockaddr*)&client_addr2, &addr_size2);
    printf("[+]ClientB connected.\n");

    while (1)
    {
        /* code */

    

    bzero(buffer1, 1024);
    recv(client_sock1, buffer1, sizeof(buffer1), 0);
    printf("ClientA choice: %s\n", buffer1);
    int choice1=atoi(buffer1);

    bzero(buffer2, 1024);
    recv(client_sock2, buffer2, sizeof(buffer2), 0);
    printf("ClientB choice: %s\n", buffer2);
    int choice2=atoi(buffer2);

      char resultA[50];
        char resultB[50];
        bzero(buffer1,1024);
        bzero(buffer2,1024);

        if (choice1 == 0 && choice2 == 0 || choice1 == 1 && choice2 == 1 || choice1 == 2 && choice2 == 2){
            strcpy(buffer1,"Draw");
            strcpy(buffer2,"Draw");
            // printf("%s",resultA);
        send(client_sock1, buffer1, strlen(buffer1), 0);
            send(client_sock2, buffer2, strlen(buffer2), 0);


            // sendto(sockfd1, buffer1, 1024, 0, (const struct sockaddr*)&client_addr1, sizeof(client_addr1));
            // sendto(sockfd2, buffer2, 1024, 0, (const struct sockaddr*)&client_addr2, sizeof(client_addr2));
            printf("Results send\n");
        }
         else if (choice1 == 0 && choice2 == 2 || choice1 == 1 && choice2 == 0 || choice1 == 2 && choice2 == 1){
            strcpy(buffer1,"Win");
            strcpy(buffer2,"Lose");
                send(client_sock1, buffer1, strlen(buffer1), 0);
    send(client_sock2, buffer2, strlen(buffer2), 0);

            // sendto(sockfd1, buffer1, 1024, 0, (const struct sockaddr*)&client_addr1, sizeof(client_addr1));
            // sendto(sockfd2, buffer2, 1024, 0, (const struct sockaddr*)&client_addr2, sizeof(client_addr2));
            printf("Results send\n");
            // printf("Draw");
        }
        else{
            strcpy(buffer1,"Lose");
            strcpy(buffer2,"Win");
                send(client_sock1, buffer1, strlen(buffer1), 0);
    send(client_sock2, buffer2, strlen(buffer2), 0);

            // sendto(sockfd1, buffer1, 1024, 0, (const struct sockaddr*)&client_addr1, sizeof(client_addr1));
            // sendto(sockfd2, buffer2, 1024, 0, (const struct sockaddr*)&client_addr2, sizeof(client_addr2));
            printf("Results send\n");
        }

        bzero(buffer1,1024);
        bzero(buffer2,1024);
            recv(client_sock1, buffer1, sizeof(buffer1), 0);


        // recvfrom(sockfd1, buffer1, sizeof(int), 0, (struct sockaddr*)&client_addr1, &addr_size1);
        int play1 = atoi(buffer1);
        // printf("[Client 1] Choice: %s\n", buffer1);
            recv(client_sock2, buffer2, sizeof(buffer2), 0);


        // recvfrom(sockfd2, buffer2, sizeof(int), 0, (struct sockaddr*)&client_addr2, &addr_size2);
        int play2 = atoi(buffer2);
        // printf("[Client 2] Choice: %s\n", buffer2);

if(play1==0 || play2==0){
      bzero(buffer1,1024);
    bzero(buffer2,1024);
     strcpy(buffer1,"1");
            strcpy(buffer2,"1");
                send(client_sock1, buffer1, strlen(buffer1), 0);
    send(client_sock2, buffer2, strlen(buffer2), 0);

            // sendto(sockfd1, buffer1, 1024, 0, (const struct sockaddr*)&client_addr1, sizeof(client_addr1));
            // sendto(sockfd2, buffer2, 1024, 0, (const struct sockaddr*)&client_addr2, sizeof(client_addr2));
            break;
}
else{
        bzero(buffer1,1024);
    bzero(buffer2,1024);
     strcpy(buffer1,"0");
            strcpy(buffer2,"0");
                send(client_sock1, buffer1, strlen(buffer1), 0);
    send(client_sock2, buffer2, strlen(buffer2), 0);

            // sendto(sockfd1, buffer1, 1024, 0, (const struct sockaddr*)&client_addr1, sizeof(client_addr1));
            // sendto(sockfd2, buffer2, 1024, 0, (const struct sockaddr*)&client_addr2, sizeof(client_addr2));
}


    // bzero(buffer1, 1024);
    // strcpy(buffer1, "HI, THIS IS SERVER. HAVE A NICE DAY!!!");
    // printf("Server: %s\n", buffer1);
    // send(client_sock1, buffer1, strlen(buffer1), 0);

    // bzero(buffer2, 1024);
    // strcpy(buffer2, "HI, THIS IS SERVER. HAVE A NICE DAY!!!");
    // printf("Server: %s\n", buffer2);
    // send(client_sock2, buffer2, strlen(buffer2), 0);
    }
    


    close(client_sock1);
     close(client_sock2);

    printf("[+]Client disconnected.\n\n");

//   }

  return 0;
}