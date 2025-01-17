package ssh

import (
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"syscall"

	"github.com/creack/pty"

	gssh "github.com/gliderlabs/ssh"
)

func handler(session gssh.Session) {
	io.WriteString(session, "Welcome to the server\n")

	if err := configurePty(session); err != nil {
		io.WriteString(session, fmt.Sprintf("Error: %s\n", err))
		return
	}
}

func configurePty(session gssh.Session) error {
	cmd := exec.Command("sh") // TODO: Use embedded bash instead.

	ptmx, err := pty.Start(cmd)
	if err != nil {
		return err
	}
	defer ptmx.Close()

	ch := make(chan os.Signal, 1)
	signal.Notify(ch, syscall.SIGWINCH)
	go func() {
		for range ch {
			if err := pty.InheritSize(os.Stdin, ptmx); err != nil {
				log.Printf("error resizing pty: %s", err)
			}
		}
	}()
	ch <- syscall.SIGWINCH                        // Initial resize.
	defer func() { signal.Stop(ch); close(ch) }() // Cleanup signals when done.

	// Copy stdin to the pty and the pty to stdout.
	// NOTE: The goroutine will keep reading until the next keystroke before returning.
	go func() { _, _ = io.Copy(ptmx, session) }()
	_, _ = io.Copy(session, ptmx)

	return nil
}
