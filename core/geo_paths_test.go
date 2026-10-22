package core

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/metacubex/mihomo/component/geodata"
	_ "github.com/metacubex/mihomo/component/geodata/memconservative"
	"github.com/metacubex/mihomo/component/geodata/router"
	_ "github.com/metacubex/mihomo/component/geodata/standard"
	"github.com/metacubex/mihomo/component/updater"
	C "github.com/metacubex/mihomo/constant"
	"google.golang.org/protobuf/proto"
)

func TestGeoIPLoadsAfterMMDBLookupAndUpdate(t *testing.T) {
	previousHome, previousName, previousURL := C.Path.HomeDir(), C.GeoipName, geodata.MmdbUrl()
	t.Cleanup(func() {
		C.SetHomeDir(previousHome)
		C.GeoipName = previousName
		geodata.SetMmdbUrl(previousURL)
	})
	geoIP, err := proto.Marshal(&router.GeoIPList{Entry: []*router.GeoIP{
		{CountryCode: "RU", Cidr: []*router.CIDR{{Ip: []byte{1, 2, 3, 0}, Prefix: 24}}},
	}})
	if err != nil {
		t.Fatal(err)
	}
	mmdb, err := os.ReadFile(filepath.Join("..", "assets", "data", "GEOIP.metadb"))
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write(mmdb)
	}))
	defer server.Close()
	geodata.SetMmdbUrl(server.URL)

	for _, alias := range []string{"Country.mmdb", "geoip.db", "geoip.metadb", "GEOIP.metadb"} {
		t.Run(alias, func(t *testing.T) {
			home := t.TempDir()
			for name, data := range map[string][]byte{"GEOIP.dat": geoIP, alias: mmdb} {
				if err := os.WriteFile(filepath.Join(home, name), data, 0o600); err != nil {
					t.Fatal(err)
				}
			}
			C.SetHomeDir(home)
			checkLoaders := func(t *testing.T) {
				t.Helper()
				for _, name := range []string{"standard", "memconservative"} {
					loader, err := geodata.GetGeoDataLoader(name)
					if err != nil {
						t.Fatal(err)
					}
					cidrs, err := loader.LoadGeoIP("RU")
					if err != nil || len(cidrs) != 1 || cidrs[0].Prefix != 24 {
						t.Errorf("%s: GeoIP stopped loading: cidrs=%v, err=%v", name, cidrs, err)
					}
				}
			}
			t.Run("lookup", func(t *testing.T) {
				C.Path.GeoIP()
				checkLoaders(t)
				if got := filepath.Clean(C.Path.MMDB()); got != filepath.Join(home, alias) {
					t.Fatalf("MMDB path = %q", got)
				}
				checkLoaders(t)
			})
			t.Run("update", func(t *testing.T) {
				C.Path.GeoIP()
				if err := updater.UpdateMMDB(); err != nil {
					t.Fatal(err)
				}
				checkLoaders(t)
			})
		})
	}
}
