/*
Copyright 2023 The Kubernetes Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package test

import (
	"bytes"
	"context"
	"os/exec"
	"path/filepath"
	"regexp"
	"testing"

	"github.com/kubernetes-sigs/iptables-wrappers/internal/commands"
	"github.com/kubernetes-sigs/iptables-wrappers/internal/iptables"
)

// iptablesVersion denotes the IP version for a iptables command, V4 or V6
type iptablesIPVersion string

const (
	v4 iptablesIPVersion = "iptables"
	v6 iptablesIPVersion = "ip6tables"
)

// iptablesMode represents a iptables mode.
type iptablesMode struct {
	original, wrongMode iptables.Mode
	// expectedIPTablesVStr is the subtring expected in betwen brakets when
	// running `iptables -V` for this particular mode
	// ex. for nft -> `iptables v1.8.7 (nf_tables)`
	expectedIPTablesVStr string
}

var legacy = iptablesMode{
	original:             iptables.Legacy,
	wrongMode:            iptables.NFT,
	expectedIPTablesVStr: "legacy",
}

var nft = iptablesMode{
	original:             iptables.NFT,
	wrongMode:            iptables.Legacy,
	expectedIPTablesVStr: "nf_tables",
}

func TestIPTablesWrapperLegacy(t *testing.T) {
	tt := newIPTablesWrapperTest(t, v4, legacy)
	runTest(t, tt)
}

func TestIPTablesWrapperNFT(t *testing.T) {
	tt := newIPTablesWrapperTest(t, v4, nft)
	runTest(t, tt)
}

func TestIP6TablesWrapperLegacy(t *testing.T) {
	tt := newIPTablesWrapperTest(t, v6, legacy)
	runTest(t, tt)
}

func TestIP6TablesWrapperNFT(t *testing.T) {
	tt := newIPTablesWrapperTest(t, v6, nft)
	runTest(t, tt)
}

func runTest(tb testing.TB, test iptablesWrapperTest) {
	ctx := context.Background()
	test.assertIPTablesUndecided(tb)

	tb.Log("Inserting chains")
	// Initialize the chosen iptables mode with just a hint chain
	test.iptables.runAndAssertSuccess(ctx, tb, "-t", "mangle", "-N", "KUBE-IPTABLES-HINT")

	// Put some junk in the other iptables system
	test.wrongModeIPTables.runAndAssertSuccess(ctx, tb, "-t", "filter", "-N", "BAD-1")
	test.wrongModeIPTables.runAndAssertSuccess(ctx, tb, "-t", "filter", "-A", "BAD-1", "-j", "ACCEPT")
	test.wrongModeIPTables.runAndAssertSuccess(ctx, tb, "-t", "filter", "-N", "BAD-2")
	test.wrongModeIPTables.runAndAssertSuccess(ctx, tb, "-t", "filter", "-A", "BAD-2", "-j", "DROP")

	test.assertIPTablesUndecided(tb)

	// This should run the iptables-wrapper
	tb.Log("Running `iptables -L` command")
	c := exec.CommandContext(ctx, "iptables", "-L")
	assertSuccess(tb, commands.RunAndReadError(c))

	test.assertIPTablesResolved(ctx, tb)
}

type iptablesWrapperTest struct {
	mode                        iptablesMode
	iptables, wrongModeIPTables ipTablesRunner
	sbinPath                    string
	wrapperPath                 string
	iptablesPath, ip6tablesPath string
}

// newIPTablesWrapperTest creates a new test setup for a particular IP version of iptables (iptables or ip6tables)
// and a particular mode (legacy or nft)
func newIPTablesWrapperTest(tb testing.TB, ipV iptablesIPVersion, mode iptablesMode) iptablesWrapperTest {
	sbinPath, err := iptables.DetectBinaryDir()
	assertSuccess(tb, err)

	return iptablesWrapperTest{
		mode:              mode,
		iptables:          newIPTablesRunner(ipV, mode.original),
		wrongModeIPTables: newIPTablesRunner(ipV, mode.wrongMode),
		sbinPath:          sbinPath,
		wrapperPath:       filepath.Join(sbinPath, "iptables-wrapper"),
		iptablesPath:      filepath.Join(sbinPath, "iptables"),
		ip6tablesPath:     filepath.Join(sbinPath, "ip6tables"),
	}
}

func (tt iptablesWrapperTest) assertIPTablesUndecided(tb testing.TB) {
	tb.Log("Checking the iptables mode hasn't been decided yet")
	iptablesRealPath := tt.iptablesRealPath(tb)
	if !tt.isIPTablesWrapper(iptablesRealPath) {
		tb.Fatalf("iptables link was resolved prematurely, got [%s]", iptablesRealPath)
	}
	tb.Logf("iptables points to %s", iptablesRealPath)

	ip6tablesRealPath := tt.ip6tablesRealPath(tb)
	if !tt.isIPTablesWrapper(ip6tablesRealPath) {
		tb.Fatalf("ip6tables link was resolved prematurely, got [%s]", ip6tablesRealPath)
	}
	tb.Logf("ip6tables points to %s", ip6tablesRealPath)
}

func (tt iptablesWrapperTest) assertIPTablesResolved(ctx context.Context, tb testing.TB) {
	tb.Logf("Checking the iptables mode has been resolved to %s", tt.mode.original)
	iptablesRealPath := tt.iptablesRealPath(tb)
	if tt.isIPTablesWrapper(iptablesRealPath) {
		tb.Fatal("iptables link is not yet resolved")
	}

	ip6tablesRealPath := tt.iptablesRealPath(tb)
	if tt.isIPTablesWrapper(ip6tablesRealPath) {
		tb.Fatal("ip6tables link is not yet resolved")
	}

	mode := readIPTablesMode(ctx, tb, "iptables")
	if mode != tt.mode.expectedIPTablesVStr {
		tb.Fatalf("iptables link resolved incorrectly: expected %s, got %s", tt.mode.expectedIPTablesVStr, mode)
	}

	mode = readIPTablesMode(ctx, tb, "ip6tables")
	if mode != tt.mode.expectedIPTablesVStr {
		tb.Fatalf("ip6tables link resolved incorrectly: expected %s, got %s", tt.mode.expectedIPTablesVStr, mode)
	}
}

func (tt iptablesWrapperTest) isIPTablesWrapper(binaryRealPath string) bool {
	return binaryRealPath == tt.wrapperPath
}

func (tt iptablesWrapperTest) iptablesRealPath(tb testing.TB) string {
	return binaryRealPath(tb, tt.iptablesPath)
}

func (tt iptablesWrapperTest) ip6tablesRealPath(tb testing.TB) string {
	return binaryRealPath(tb, tt.ip6tablesPath)
}

func binaryRealPath(tb testing.TB, binary string) string {
	realPath, err := filepath.EvalSymlinks(binary)
	assertSuccess(tb, err)

	return realPath
}

func newIPTablesRunner(ipV iptablesIPVersion, mode iptables.Mode) ipTablesRunner {
	return ipTablesRunner{
		binary: string(ipV) + "-" + string(mode),
	}
}

type ipTablesRunner struct {
	binary string
}

func (r ipTablesRunner) runAndAssertSuccess(ctx context.Context, tb testing.TB, args ...string) {
	tb.Helper()
	assertSuccess(tb, r.run(ctx, args...))
}

func (r ipTablesRunner) run(ctx context.Context, args ...string) error {
	c := exec.CommandContext(ctx, r.binary, args...)
	return commands.RunAndReadError(c)
}

var iptablesModeRegex = regexp.MustCompile(`^ip6?tables.*\((.+)\).*`)

func readIPTablesMode(ctx context.Context, tb testing.TB, iptables string) string {
	tb.Helper()
	var out bytes.Buffer
	c := exec.CommandContext(ctx, iptables, "-V")
	c.Stdout = &out
	assertSuccess(tb, commands.RunAndReadError(c))

	outIPTablesVersion := out.String()
	matches := iptablesModeRegex.FindStringSubmatch(outIPTablesVersion)
	if len(matches) != 2 {
		tb.Fatalf("Can't read `%s -V` output format: %s", iptables, outIPTablesVersion)
	}

	tb.Logf("Output of `%s -V`: %s", iptables, outIPTablesVersion)

	mode := matches[1]
	return mode
}

func assertSuccess(tb testing.TB, err error) {
	tb.Helper()
	if err != nil {
		tb.Fatal(err.Error())
	}
}
