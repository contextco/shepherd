package circular

import (
	"bytes"
	"io"
	"strings"
	"time"
)

type Buffer struct {
	buffer []Line
	size   int
	head   int
	full   bool
	buf    bytes.Buffer
}

type Line struct {
	Text string
	Time time.Time
}

func NewBuffer(limit int) *Buffer {
	return &Buffer{
		buffer: make([]Line, limit),
		size:   limit,
		head:   0,
		full:   false,
	}
}

func (b *Buffer) Write(p []byte) (int, error) {
	// Append to an internal buffer to handle incomplete lines
	n, err := b.buf.Write(p)
	if err != nil {
		return n, err
	}

	// Extract lines from the buffer
	for {
		line, err := b.buf.ReadString('\n')
		if err == io.EOF {
			// If there's no complete line yet, put the remaining part back in the buffer
			b.buf.WriteString(line)
			break
		}
		// Trim newline characters and add the line to the ring buffer
		b.Add(strings.TrimSuffix(line, "\n"))
	}
	return n, nil
}

func (b *Buffer) Add(line string) {
	b.buffer[b.head] = NewLine(line)
	b.head = (b.head + 1) % b.size

	// Mark the buffer as full once we've looped over all positions
	if b.head == 0 {
		b.full = true
	}
}

func (b *Buffer) Lines(n int) []Line {
	if !b.full {
		// If the buffer isn't full, return the lines up to the current head
		return b.buffer[:min(b.head, n)]
	}

	// If the buffer is full, return the lines starting from head to the end,
	// followed by lines from the start to head
	return append(b.buffer[b.head:], b.buffer[:b.head]...)[:n]
}

func NewLine(text string) Line {
	return Line{
		Text: text,
		Time: time.Now(),
	}
}
