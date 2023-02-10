//go:build rpm_crashtraceback
// +build rpm_crashtraceback

package SOURCES

func init() {
	setTraceback("crash")
}
