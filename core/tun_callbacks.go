package core

import "sync"

type TunCallbacks interface {
	Protect(fd int) bool
	ResolveUid(protocol int, source, target string) int
	ResolvePackage(uid int) string
}

type tunCallbackState struct {
	callbacks TunCallbacks
	mu        sync.RWMutex
}

func (state *tunCallbackState) handleProtect(fd int) {
	state.mu.RLock()
	defer state.mu.RUnlock()
	if state.callbacks != nil {
		state.callbacks.Protect(fd)
	}
}
