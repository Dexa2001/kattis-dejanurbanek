#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <string.h>
#include <arpa/inet.h>
#include <unistd.h>

#define MAX_BUFFER_SIZE 1024

void sendFile(int socket) {
    FILE *file = fopen("sockets.txt", "rb");
    if (!file) {
        perror("Error opening file for reading");
        return;
    }

    char buffer[MAX_BUFFER_SIZE];
    size_t bytesRead;

    while ((bytesRead = fread(buffer, 1, MAX_BUFFER_SIZE, file)) > 0) {
        send(socket, buffer, bytesRead, 0);
    }

    fclose(file);
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <server_ip> <mode>\n", argv[0]);
        return 1;
    }

    int clientSocket;
    int connectStatus;
    struct sockaddr_in remoteAddr;

    memset(&remoteAddr, 0, sizeof(remoteAddr));
    remoteAddr.sin_family = AF_INET;
    inet_pton(AF_INET, argv[1], &(remoteAddr.sin_addr));
    remoteAddr.sin_port = htons(1234);

    clientSocket = socket(AF_INET, SOCK_STREAM, 0);

    connectStatus = connect(clientSocket, (struct sockaddr *)&remoteAddr, sizeof(remoteAddr));

    char buffer[MAX_BUFFER_SIZE] = {0};

    if (connectStatus == -1) {
        perror("Connection failed");
        return 1;
    }

    // Sending mode to the server
    send(clientSocket, argv[2], strlen(argv[2]), 0);

    if (strcmp(argv[2], "echo") == 0) {
        // Echo mode logic (unchanged from the previous version)
        while (1) {
            printf("Enter a string to echo (type 'close' to quit): ");
            fgets(buffer, MAX_BUFFER_SIZE, stdin);
            send(clientSocket, buffer, strlen(buffer), 0);

            if (strncmp(buffer, "close", 5) == 0) {
                break;
            }

            recv(clientSocket, buffer, MAX_BUFFER_SIZE, 0);
            printf("Received from server: %s\n", buffer);

            memset(buffer, 0, sizeof(buffer));
        }
    } else if (strcmp(argv[2], "transfer") == 0) {
        // File transfer mode logic
        sendFile(clientSocket);
    } else {
        fprintf(stderr, "Invalid mode. Use 'echo' or 'transfer'.\n");
    }

    close(clientSocket);

    return 0;
}
