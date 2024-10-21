package control

import (
	"context"
	"net/http"

	"onprem/control/components/home"
)

type Server struct {
}

func (s *Server) Start(ctx context.Context) error {
	srv := http.NewServeMux()

	srv.HandleFunc("/static/", func(w http.ResponseWriter, r *http.Request) {
		r.URL.Path = r.URL.Path[len("/static/"):]
		http.FileServer(http.Dir("./build")).ServeHTTP(w, r)
	})

	srv.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		home.Index().Render(ctx, w)
	})

	return http.ListenAndServe(":8080", srv)
}
