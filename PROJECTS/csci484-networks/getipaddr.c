#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>

// Define a structure to represent each node in the linked list
struct Node {
    char ipstr[INET6_ADDRSTRLEN];
    char ipver[5]; // "IPv4" or "IPv6"
    struct Node* next;
};


int main(int argc, char *argv[]) {
    struct addrinfo hints, *res, *p;
    int status;

    if (argc != 2) {
        fprintf(stderr, "usage: showip hostname\n");
        return 1;
    }

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC; // AF_INET or AF_INET6 to force version
    hints.ai_socktype = SOCK_STREAM;

    if ((status = getaddrinfo(argv[1], NULL, &hints, &res)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(status));
        return 2;
    }

    printf("IP addresses for %s:\n\n", argv[1]);

    // Initialize a linked list
    struct Node* head = NULL;

    for (p = res; p != NULL; p = p->ai_next) {
        void *addr;
        struct Node* newNode = (struct Node*)malloc(sizeof(struct Node));

        // get the pointer to the address itself,
        // different fields in IPv4 and IPv6:
        if (p->ai_family == AF_INET) { // IPv4
            struct sockaddr_in *ipv4 = (struct sockaddr_in *)p->ai_addr;
            addr = &(ipv4->sin_addr);
            strcpy(newNode->ipver, "IPv4");
        } else { // IPv6
            struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)p->ai_addr;
            addr = &(ipv6->sin6_addr);
            strcpy(newNode->ipver, "IPv6");
        }

        // convert the IP to a string and store it in the linked list:
        inet_ntop(p->ai_family, addr, newNode->ipstr, sizeof newNode->ipstr);

        // Insert the new node at the beginning of the linked list
        newNode->next = head;
        head = newNode;
    }

    // Print the IP addresses from the linked list
    struct Node* current = head;
    while (current != NULL) {
        printf("  %s: %s\n", current->ipver, current->ipstr);

        // Move to the next node
        current = current->next;
    }

    // Free the linked list
    while (head != NULL) {
        struct Node* temp = head;
        head = head->next;
        free(temp);
    }

    freeaddrinfo(res); // free the linked list from getaddrinfo

    return 0;
}
