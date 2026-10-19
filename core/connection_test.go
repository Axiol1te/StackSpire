package core

import (
	"io"
	"net"
	"testing"
	"time"

	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/adapter/outbound"
	"github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/tunnel"
	"github.com/metacubex/mihomo/tunnel/statistic"
)

func TestStopListenerClosesActiveTCPAndUDP(t *testing.T) {
	direct := outbound.NewDirectWithOption(outbound.DirectOption{Name: "stop-check"})
	local, remote := net.Pipe()
	t.Cleanup(func() { local.Close(); remote.Close() })
	statistic.NewTCPTracker(outbound.NewConn(local, direct), statistic.DefaultManager,
		&constant.Metadata{}, nil, 0, 0, true)
	packet, err := net.ListenPacket("udp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { packet.Close() })
	statistic.NewUDPTracker(outbound.NewPacketConn(packet, direct), statistic.DefaultManager,
		&constant.Metadata{}, nil, 0, 0, true)
	wasRunning := isRunning.Load()
	t.Cleanup(func() { isRunning.Store(wasRunning) })
	isRunning.Store(true)
	if got := handleGetConnectionCount(); got != 2 {
		t.Fatalf("active connections = %d, want 2", got)
	}
	handleStopListener()
	if got := handleGetConnectionCount(); got != 0 {
		t.Fatalf("stop left %d active connections", got)
	}
	remote.SetReadDeadline(time.Now().Add(time.Second))
	if _, err := remote.Read(make([]byte, 1)); err != io.EOF {
		t.Fatalf("TCP peer did not observe close: %v", err)
	}
	if _, err := packet.WriteTo([]byte("closed"), packet.LocalAddr()); err == nil {
		t.Fatal("UDP socket remained usable after stop")
	}
	handleStopListener()
}

func TestProxyOnlyTrafficLeavesOutADirectProxyOfAnyName(t *testing.T) {
	direct := outbound.NewDirectWithOption(outbound.DirectOption{Name: "直连"})
	reject := outbound.NewRejectWithOption(outbound.RejectOption{Name: "HK"})
	tunnel.UpdateProxies(map[string]constant.Proxy{
		"直连": adapter.NewProxy(direct),
		"HK": adapter.NewProxy(reject),
	}, nil)
	t.Cleanup(func() { tunnel.UpdateProxies(nil, nil) })

	for _, test := range []struct {
		outbound constant.ProxyAdapter
		proxied  int64
	}{
		{direct, 0},
		{reject, 5},
	} {
		statistic.DefaultManager.ResetStatistic()
		local, remote := net.Pipe()
		go func() { _, _ = io.Copy(io.Discard, remote) }()
		tracker := statistic.NewTCPTracker(
			outbound.NewConn(local, test.outbound),
			statistic.DefaultManager,
			&constant.Metadata{},
			nil,
			0,
			0,
			true,
		)

		if _, err := tracker.Write([]byte("hello")); err != nil {
			t.Fatalf("write through %s: %v", test.outbound.Name(), err)
		}
		_ = tracker.Close()
		_ = remote.Close()

		all, _ := statistic.DefaultManager.TotalTraffic(false)
		proxied, _ := statistic.DefaultManager.TotalTraffic(true)
		if all != 5 || proxied != test.proxied {
			t.Errorf("%s: total %d, proxied %d; want 5 and %d", test.outbound.Name(), all, proxied, test.proxied)
		}
	}
	statistic.DefaultManager.ResetStatistic()
}
