package core

import (
	"sync/atomic"
	"testing"
)

type testTunCallbacks struct {
	protect func(int) bool
}

func (callbacks testTunCallbacks) Protect(fd int) bool      { return callbacks.protect(fd) }
func (testTunCallbacks) ResolveUid(int, string, string) int { return -1 }
func (testTunCallbacks) ResolvePackage(int) string          { return "" }

func TestTunSocketProtectionWorksBeforeListenerIsReady(t *testing.T) {
	var protected int
	state := tunCallbackState{callbacks: testTunCallbacks{protect: func(fd int) bool {
		protected = fd
		return true
	}}}
	state.handleProtect(42)
	if protected != 42 {
		t.Fatalf("socket opened during TUN construction was not protected: fd=%d", protected)
	}
}

func TestTunSocketProtectionStopsWithCallbacks(t *testing.T) {
	var calls atomic.Int32
	state := tunCallbackState{callbacks: testTunCallbacks{protect: func(int) bool {
		calls.Add(1)
		return true
	}}}
	state.handleProtect(1)
	state.mu.Lock()
	state.callbacks = nil
	state.mu.Unlock()
	state.handleProtect(2)
	if calls.Load() != 1 {
		t.Fatal("socket protection outlived the Android callbacks")
	}
}
