// +build rpm_crashtraceback

package runtime

func init() {
	setTraceback("crash")
}
