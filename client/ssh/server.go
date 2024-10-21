package ssh

import (
	"context"
	"log"
	"net"
	"os"
	"os/signal"
	"sync"

	"github.com/gliderlabs/ssh"
	gssh "github.com/gliderlabs/ssh"
	"tailscale.com/tsnet"
)

type Server struct {
	sshSrv *gssh.Server
	ln     net.Listener
	ts     *tsnet.Server

	mu    sync.RWMutex
	auths []auth

	doneC chan struct{}
}

func NewServer(authKey, hostname string) *Server {
	s := &Server{
		ts: &tsnet.Server{
			AuthKey:   authKey,
			Hostname:  hostname,
			Ephemeral: true,
			UserLogf:  nullLogf,
		},
		sshSrv: &gssh.Server{
			Handler: handler,
		},

		auths: []auth{},

		doneC: make(chan struct{}, 1),
	}

	// s.sshSrv.PublicKeyHandler = s.handlePublicKeyAuth

	s.handleInterrupts()

	return s
}

func (s *Server) handlePublicKeyAuth(ctx ssh.Context, key ssh.PublicKey) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for _, a := range s.auths {
		if ssh.KeysEqual(a.key, key) {
			return true
		}
	}

	return false
}

func (s *Server) AddKey(key ssh.PublicKey) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.auths = append(s.auths, auth{key: key})
}

func (s *Server) RemoveKey(key ssh.PublicKey) {
	s.mu.Lock()
	defer s.mu.Unlock()

	for i, a := range s.auths {
		if ssh.KeysEqual(a.key, key) {
			s.auths = append(s.auths[:i], s.auths[i+1:]...)
		}
	}
}

func (s *Server) ClearAuth() {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.auths = []auth{}
}

func (s *Server) Start(ctx context.Context) error {
	_, err := s.ts.Up(ctx)
	if err != nil {
		return err
	}

	ln, err := s.ts.Listen("tcp", ":22")
	if err != nil {
		return err
	}

	go func() {
		if err := s.sshSrv.Serve(ln); err != nil {
			log.Printf("Failed to serve SSH: %s", err)
		}
	}()

	return nil
}

func (s *Server) handleInterrupts() {
	c := make(chan os.Signal, 1)
	go func(s *Server) {
		<-c
		s.Close()

		os.Exit(0)
	}(s)

	signal.Notify(c, os.Interrupt)
}

func (s *Server) Close() error {
	if s.ln != nil {
		s.ln.Close()
	}

	if s.ts != nil {
		s.ts.Close()
	}

	if s.sshSrv != nil {
		s.sshSrv.Close()
	}

	s.doneC <- struct{}{}

	return nil
}

func (s *Server) Done() <-chan struct{} {
	return s.doneC
}

func nullLogf(format string, args ...any) {}
