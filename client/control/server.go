package control

import (
	"context"
	"net/http"
	"sync"

	"onprem/control/components/home"
	"onprem/process"
	"onprem/ssh"

	"github.com/a-h/templ"
	"github.com/google/uuid"
)

type Server struct {
	sshMu   sync.RWMutex
	SshSrv  *ssh.Server
	Process *process.Process
}

func (s *Server) Start(ctx context.Context) error {
	srv := http.NewServeMux()

	srv.HandleFunc("GET /static/", func(w http.ResponseWriter, r *http.Request) {
		r.URL.Path = r.URL.Path[len("/static/"):]
		http.FileServer(http.Dir("./build")).ServeHTTP(w, r)
	})

	srv.HandleFunc("PATCH /ssh", s.toggleSsh)
	srv.HandleFunc("GET /", s.index)

	return http.ListenAndServe(":8080", srv)
}

func (s *Server) Close() error {
	return s.SshSrv.Close()
}

func (s *Server) index(w http.ResponseWriter, r *http.Request) {
	renderComponent(home.Index(home.IndexProps{
		SSHRunning: s.SshSrv.Running(),
		Process:    s.Process,
	}))(w, r)
}

func (s *Server) toggleSsh(w http.ResponseWriter, r *http.Request) {
	s.sshMu.Lock()
	defer s.sshMu.Unlock()

	if s.SshSrv == nil {
		http.Error(w, "SSH server not initialized", http.StatusInternalServerError)
		return
	}

	if s.SshSrv.Running() {
		if err := s.SshSrv.Close(); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}

	if err := s.SshSrv.Start(r.Context()); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func renderComponent(component templ.Component) func(w http.ResponseWriter, r *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html")
		component.Render(r.Context(), w)
	}
}

func New(authKey string, p *process.Process) (*Server, error) {
	id, err := uuid.NewV7()
	if err != nil {
		return nil, err
	}

	return &Server{
		SshSrv:  ssh.NewServer(authKey, id.String()),
		Process: p,
	}, nil
}
