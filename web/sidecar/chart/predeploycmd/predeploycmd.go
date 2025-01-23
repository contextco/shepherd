package predeploycmd


type PreDeployCmd struct {
    command string
}

func New(command string) (*PreDeployCmd, error) {
    return &PreDeployCmd{command: command}, nil
}

func (p *PreDeployCmd) Generate() []string {
    return []string{"/bin/sh", "-c", p.command}
}
