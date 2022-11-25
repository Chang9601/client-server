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
 * server-c.c
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

#define QUEUE_LENGTH 10
#define RECV_BUFFER_SIZE 2048

void processMsg(int);

/* TODO: server()
 * Open socket and wait for client to connect
 * Print received message to stdout
 * Return 0 on success, non-zero on failure
*/
int server(char *server_port) {
	
	int serverfd, clientfd;
	struct addrinfo *serveraddr, hints, *result;
	/* sockaddr_storage: 모든 소켓 주소 구조체를 저장할 수 있음 */
	struct sockaddr_storage clientaddr;
	socklen_t addrlen;
	/* setsockopt() 옵션 활성화 */
	int optval = 1;
	
	memset(&hints, 0, sizeof(hints));
	/* 
	 * AI_PASSIVE
	 *   서버로 사용되는 소켓
	 *   일반적으로 호스트 이름 명시 X (즉, NULL)
	 *   소켓 주소 구조체는 INADDR_ANY (IPv4) 혹은 IN6ADDR_ANY_INIT (IPv6)
	 */
	hints.ai_flags = AI_PASSIVE; 
	/* AF_UNSPEC: 모든 프로토콜 패밀리 (IPv4, IPv6, ...) */
	hints.ai_family = AF_UNSPEC;
	/* SOCK_STREAM: 스트림 소켓 (TCP) */
	hints.ai_socktype = SOCK_STREAM; 
	
	if (getaddrinfo(NULL, server_port, &hints, &result) < 0) {
		fprintf(stderr, "server-c: getaddrinfo");
		exit(EXIT_FAILURE);
	}

	for (serveraddr = result; serveraddr != NULL; serveraddr = serveraddr -> ai_next) {
		/* 소켓 생성 */		
		if ((serverfd = socket(serveraddr -> ai_family, serveraddr -> ai_socktype, serveraddr -> ai_protocol)) < 0) {
			perror("server-c: socket");
			continue;
		}
	
		/* Address already in use 방지 */
		if (setsockopt(serverfd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)) < 0) {
			perror("server-c: setsockopt");
			exit(EXIT_FAILURE);
		}
		
		/* 소켓을 포트에 고정 */
		if (bind(serverfd, serveraddr -> ai_addr, serveraddr -> ai_addrlen) < 0) {
			/* bind 실패할 경우 소켓 기술자 닫기 */
			close(serverfd);	
			perror("server-c: bind");
			continue;
		}
		
		/* 서버 찾으면 반복문 종료 */	
		break;
	}
	
	/* getaddrinfo() 함수가 동적으로 할당한 메모리 해제 */
	freeaddrinfo(result);

	if (serveraddr == NULL) {
		fprintf(stderr, "server-c: bind");
		exit(EXIT_FAILURE);
	}

	/* 서버로 동작하는 소켓 */
	if (listen(serverfd, QUEUE_LENGTH) < 0) {
		fprintf(stderr, "server-c: listen");	
		exit(EXIT_FAILURE);
	}

	while (1) {
		/* addrlen은 accept 호출 전 소켓 주소 구조체의 크기로 설정 */
		addrlen = sizeof(clientaddr);
		/* 클라이언트 연결 */
		if ((clientfd = accept(serverfd, (struct sockaddr *)&clientaddr, &addrlen)) < 0) {
			perror("server-c: accept");
			continue;
		}
		
		/* 클라이언트의 메시지 처리 */	
		processMsg(clientfd);
	
		/* 클라이언트 소켓 사용 후 종료 */	
		close(clientfd);
	}

	close(serverfd);

    return 0;
}

void processMsg(int sockfd)
{
	char buffer[RECV_BUFFER_SIZE + 1];
	char ch;
	int num_read;

	while (num_read = recv(sockfd, buffer, RECV_BUFFER_SIZE, 0)) {
		if (num_read < 0) {
			perror("server-c: recv");
			exit(EXIT_FAILURE);
		}

		fwrite(buffer, num_read, 1, stdout);
		/* 터미널은 line buffered, 파일은 fully buffered, 따라서 flush 필요 */
		fflush(stdout);
	}
}

/*
 * main():
 * Parse command-line arguments and call server function
*/
int main(int argc, char **argv) {
	char *server_port;

  	if (argc != 2) {
    	fprintf(stderr, "Usage: ./server-c (server port)\n");
    	exit(EXIT_FAILURE);
  	}

	server_port = argv[1];

 	return server(server_port);
}
