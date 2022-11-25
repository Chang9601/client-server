/*****************************************************************************
 *
 *     This file is part of Purdue CS 422.
 *
 *     Purdue CS 422 is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Purdue CS 422 is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with Purdue CS 422. If not, see <https://www.gnu.org/licenses/>.
 *
 *****************************************************************************/

/*
 * client-c.c
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netdb.h>
#include <netinet/in.h>
#include <errno.h>

#define SEND_BUFFER_SIZE 2048


/* TODO: client()
 * Open socket and send message from stdin.
 * Return 0 on success, non-zero on failure
*/
int client(char *server_ip, char *server_port) {

	int sockfd;
	size_t num_read;
	struct addrinfo *serveraddr, hints, *result;
	char buffer[SEND_BUFFER_SIZE + 1];

	memset(&hints, 0, sizeof(hints));
	/* AF_UNSPEC: 모든 프로토콜 패밀리 (IPv4, IPv6, ...) */
	hints.ai_family = AF_UNSPEC;
	/* SOCK_STREAM: 스트림 소켓 (TCP) */
	hints.ai_socktype = SOCK_STREAM; 
		
	if (getaddrinfo(server_ip, server_port, &hints, &result) < 0) {
		fprintf(stderr, "client-c: getaddrinfo");
		exit(EXIT_FAILURE);
	}

	for (serveraddr = result; serveraddr != NULL; serveraddr = serveraddr -> ai_next) {
		if ((sockfd = socket(serveraddr -> ai_family, serveraddr -> ai_socktype, serveraddr -> ai_protocol)) < 0) {
			perror("client-c: socket");
			continue;
		}

		/* 매개변수인 소켓 주소 구조체는 반드시 서버의 IP 주소와 포트 번호 */
		if (connect(sockfd, serveraddr -> ai_addr, serveraddr -> ai_addrlen) < 0) {
			close(sockfd);
			perror("client-c: connect");
			continue;
		}

		break;
	}

	freeaddrinfo(result);

	if (serveraddr == NULL) {
		fprintf(stderr, "client-c: connect");
		exit(EXIT_FAILURE);
	}

	/* 텍스트 형태, 이진 형태 둘 다 받을 수 있어야 하기 때문에 fread 사용 */	
	while ((num_read = fread(buffer, sizeof(char), SEND_BUFFER_SIZE, stdin))) {
		if (send(sockfd, buffer, num_read, 0) < 0) 
			perror("client-c: send");
	}

	close(sockfd);

	return 0;
}

/*
 * main()
 * Parse command-line arguments and call client function
*/
int main(int argc, char **argv) {
	char *server_ip;
  	char *server_port;

  	if (argc != 3) {
    	fprintf(stderr, "Usage: ./client-c (server IP) (server port) < (message)\n");
    	exit(EXIT_FAILURE);
  	}

  	server_ip = argv[1];
  	server_port = argv[2];

  	return client(server_ip, server_port);
}
