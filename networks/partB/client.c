#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define CHUNK_SIZE 10
#define MAX_CHUNKS 1000
struct Chunk
{
    int sequence_number;
    char data[CHUNK_SIZE];
};

int main(int argc, char **argv)
{
    // int main(int argc, char **argv){

    if (argc != 2)
    {
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
    if (fgets(buffer, sizeof(buffer), stdin) != NULL)
    {
        int length = strlen(buffer);
        if (length > 0 && buffer[length - 1] == '\n')
        {
            buffer[length - 1] = '\0';
        }
    }
    int text_len = strlen(buffer);
    int total_chunks = ((text_len) / CHUNK_SIZE) + 1;
    // printf("%d",total_chunks);
    int array[MAX_CHUNKS];
    int chunks=total_chunks;
    sendto(sockfd, &chunks, sizeof(chunks), 0, (struct sockaddr *)&addr, sizeof(addr));

    for (int i = 0; i < MAX_CHUNKS; i++)
    {
        array[i] = 0;
    }



    for (int i = 0; i < total_chunks; i=i+2)
    {
        struct Chunk chunk;
        chunk.sequence_number = i;
        array[i] = 1;
        // Copy a chunk of data
        int data_len;
        if (i == total_chunks - 1)
        {
            data_len = (text_len % CHUNK_SIZE) + 1;
        }
        else
        {
            data_len = CHUNK_SIZE;
        }
        strncpy(chunk.data, buffer + i * CHUNK_SIZE, data_len);
        sendto(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)&addr, sizeof(addr));
        // array[i]=1;
        int ack_sequence_number;
        if (recvfrom(sockfd, &ack_sequence_number, sizeof(ack_sequence_number), 0, NULL, NULL) == -1)
        {
            perror("recvfrom");
            exit(1);
        }
        printf("Acknowledged recieved with number %d\n", ack_sequence_number);

        // if (ack_sequence_number != i) {
        //     printf("Received incorrect ACK for sequence number %d\n", i);
        // }
    }
    // printf("hello");
    struct Chunk chunk;

    chunk.sequence_number = -1;
    strcpy(chunk.data, "..");
    // chunk.data='wreq';
    sendto(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)&addr, sizeof(addr));
    struct Chunk chunk5;

    // chunk5.sequence_number=-3;
    // strcpy(chunk5.data,"..");
    // // chunk.data='wreq';
    // sendto(sockfd, &chunk5, sizeof(chunk5), 0, (struct sockaddr *)&addr, sizeof(addr));
    for (int i = 0; i < total_chunks; i++)
    {
        if (array[i] == 0)
        {
            printf("Sending retransmission for chunk \n");

            struct Chunk request_packet;
            request_packet.sequence_number = i;
            int data_len;
            if (i == total_chunks - 1)
            {
                data_len = (text_len % CHUNK_SIZE) + 1;
            }
            else
            {
                data_len = CHUNK_SIZE;
            }
            strncpy(request_packet.data, buffer + i * CHUNK_SIZE, data_len); // You can use any message for retransmission request
            // printf("%s",request_packet.data);
            sendto(sockfd, &request_packet, sizeof(request_packet), 0, (struct sockaddr *)&addr, sizeof(addr));
            // printf("%s",request_packet.data);
            int ack_sequence_number;
        if (recvfrom(sockfd, &ack_sequence_number, sizeof(ack_sequence_number), 0, NULL, NULL) == -1)
        {
            perror("recvfrom");
            exit(1);
        }
        printf("Acknowledged recieved with number %d\n", ack_sequence_number);
        }
    }

    struct Chunk chunk2;

    chunk2.sequence_number = -2;
    strcpy(chunk.data, "..");
    // chunk.data='wreq';
    sendto(sockfd, &chunk2, sizeof(chunk2), 0, (struct sockaddr *)&addr, sizeof(addr));

    for(int i=0;i<total_chunks;i++){
        int ack_sequence_number;
        if (recvfrom(sockfd, &ack_sequence_number, sizeof(ack_sequence_number), 0, NULL, NULL) == -1)
        {
            perror("recvfrom");
            exit(1);
        }
        if(ack_sequence_number==-2){
            break;
        }
        printf("Acknowledged recieved with number %d\n", ack_sequence_number);

    }

    close(sockfd);
    return 0;
}
