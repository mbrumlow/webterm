package main

// #cgo LDFLAGS: -lutil
// #include <unistd.h>
// #include <stdlib.h>
// #include <stdio.h>
// #include <pty.h>
// int start_session(int *pid, int *fd) {
//  *pid = forkpty(fd, NULL, NULL, NULL);
//  if( *pid == 0 ) {
//    execl("/bin/sh", "sh", NULL);
//    exit(0);
//  } else if( *pid > 0 )  {
//   return 1;
//  } else {
//   return 0;
//  }
// }
import "C"

import (
	"bytes"
	"fmt"
	"net/http"
	"syscall"
)

var sc chan string

type Message struct {
	Line string
}

func startSession() (int, int) {
	var fd C.int
	var pid C.int
	C.start_session(&pid, &fd)

	return int(fd), int(pid)
}

func runSession(sc chan string, fd int) {

	buf := make([]byte, 1)

	var p = 1
	for {

		count, _ := syscall.Read(fd, buf)

		s := string(buf[:count])

		sc <- s

		if p == 1 {
			syscall.Write(fd, []byte("top -d 0\n"))
			p = 0
		}
	}

}

func handler(w http.ResponseWriter, r *http.Request) {

	var buffer bytes.Buffer
	l := len(sc)

	if l > 0 {
		for i := 0; i < l; i++ {
			s := <-sc
			buffer.WriteString(s)
		}
	} else {
		s := <-sc
		buffer.WriteString(s)
	}

	w.Header().Set("Content-Type", "text/plain")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	fmt.Fprint(w, buffer.String())
}

func main() {

	fd, pid := startSession()

	fmt.Println(pid)
	fmt.Println(fd)
	fmt.Println("-------------------------")

	sc = make(chan string, 512)

	go runSession(sc, fd)

	http.HandleFunc("/line", handler)
	http.ListenAndServe(":8080", nil)

}
