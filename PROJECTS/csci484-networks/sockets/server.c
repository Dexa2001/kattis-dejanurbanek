#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <stdlib.h>
#include <string.h>
#include <netinet/in.h>

#define MAX_BUFFER_SIZE 1024

void receiveFile(int socket) {
    FILE *file = fopen("received_file.txt", "wb");
    if (!file) {
        perror("Error opening file for writing");
        return;
    }

    char buffer[MAX_BUFFER_SIZE];
    size_t bytesRead;

    while ((bytesRead = recv(socket, buffer, MAX_BUFFER_SIZE, 0)) > 0) {
        fwrite(buffer, 1, bytesRead, file);
    }

    fclose(file);
}

int main(int argc, char **argv) {
    int serverSocket;
    int setsockoptStatus;
    int bindStatus;
    int listenStatus;
    int newSocket;
    struct addrinfo hints, *res;
    struct sockaddr_storage address;
    int addrSize = sizeof(address);
    int yes = 1;

    char buffer[MAX_BUFFER_SIZE] = {0};

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    getaddrinfo(NULL, "1234", &hints, &res);

    serverSocket = socket(res->ai_family, res->ai_socktype, 0);

    setsockoptStatus = setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));

    bindStatus = bind(serverSocket, res->ai_addr, res->ai_addrlen);

    listenStatus = listen(serverSocket, 1);

    newSocket = accept(serverSocket, (struct sockaddr *)&address, (socklen_t *)&addrSize);

    // Receiving mode from the client
    recv(newSocket, buffer, MAX_BUFFER_SIZE, 0);
    printf("Received mode from client: %s\n", buffer);

    if (strcmp(buffer, "echo") == 0) {
        // Echo mode logic (unchanged from the previous version)
        while (1) {
            recv(newSocket, buffer, MAX_BUFFER_SIZE, 0);

            if (strncmp(buffer, "close", 5) == 0) {
                send(newSocket, "goodbye", strlen("goodbye"), 0);
                break;
            }

            send(newSocket, buffer, strlen(buffer), 0);
            memset(buffer, 0, sizeof(buffer));
        }
    } else if (strcmp(buffer, "transfer") == 0) {
        // File transfer mode logic
        receiveFile(newSocket);
    } else {
        fprintf(stderr, "Invalid mode received from the client.\n");
    }

    close(newSocket);
    close(serverSocket);

    return 0;
}
