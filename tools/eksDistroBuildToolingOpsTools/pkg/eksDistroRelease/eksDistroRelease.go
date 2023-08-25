package eksDistroRelease

import (
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"

	"sigs.k8s.io/yaml"

	"github.com/aws/eks-distro-build-tooling/release/api/v1alpha1"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
)

const (
	expectedStatusCode                  = 200
	eksDistroReleaseManifestUriTemplate = "https://distro.eks.amazonaws.com/kubernetes-%s/kubernetes-%s-eks-%d.yaml"
	kubernetesComponentName             = "kubernetes"
	kubernetesSourceArchiveAsset        = "kubernetes-src.tar.gz"
)

func NewEksDistroReleaseObject(versionString string) (*Release, error) {
	splitVersion := strings.Split(versionString, ".")
	patchAndRelease := strings.Split(splitVersion[2], "-")
	major, err := strconv.Atoi(splitVersion[0])
	if err != nil {
		return nil, err
	}

	minor, err := strconv.Atoi(splitVersion[1])
	if err != nil {
		return nil, err
	}

	patch, err := strconv.Atoi(patchAndRelease[0])
	if err != nil {
		return nil, err
	}

	release, err := strconv.Atoi(patchAndRelease[1])
	if err != nil {
		return nil, err
	}

	releaseBranch := fmt.Sprintf("%d-%d", major, minor)
	manifest, err := getReleaseManifestBody(releaseBranch, release)
	if err != nil {
		return nil, fmt.Errorf("getting release manifest body: %v", err)
	}

	return &Release{
		Major:      major,
		Manifest:   manifest,
		Minor:      minor,
		Patch:      patch,
		Release:    release,
		components: map[string]v1alpha1.Component{},
		assets:     map[string]v1alpha1.Asset{},
	}, nil
}

type Release struct {
	Major      int
	Minor      int
	Patch      int
	Release    int
	Manifest   *v1alpha1.Release
	components map[string]v1alpha1.Component
	assets     map[string]v1alpha1.Asset
}

func (r Release) KubernetesReleaseBranch() string {
	return fmt.Sprintf("%d-%d", r.Major, r.Minor)
}

func (r Release) KubernetesMajorVersion() int {
	return r.Major
}

func (r Release) KubernetesMinorVersion() int {
	return r.Minor
}

func (r Release) KubernetesPatchVersion() int {
	return r.Patch
}

func (r Release) ReleaseNumber() int {
	return r.Release
}

func (r Release) ReleaseManifest() v1alpha1.Release {
	return *r.Manifest
}

func (r Release) EksDistroReleaseFullVersion() string {
	return fmt.Sprintf("v%d.%d.%d-%d", r.Major, r.Minor, r.Patch, r.Release)
}

func (r Release) KubernetesFullVersion() string {
	return fmt.Sprintf("%d.%d.%d", r.Major, r.Minor, r.Patch)
}

func (r Release) KubernetesSemver() string {
	return fmt.Sprintf("v%d.%d.%d", r.Major, r.Minor, r.Patch)
}

func (r Release) KubernetesComponent() *v1alpha1.Component {
	component, ok := r.components[kubernetesComponentName]
	if ok {
		return &component
	}

	for _, c := range r.ReleaseManifest().Status.Components {
		if c.Name == kubernetesComponentName {
			r.components[kubernetesComponentName] = c
			return &c
		}
	}
	return nil
}

func (r Release) KubernetesSourceArchive() *v1alpha1.Asset {
	asset, ok := r.assets[kubernetesSourceArchiveAsset]
	if ok {
		return &asset
	}
	for _, a := range r.KubernetesComponent().Assets {
		if a.Name == kubernetesSourceArchiveAsset {
			r.assets[kubernetesSourceArchiveAsset] = a
			return &a
		}
	}
	return nil
}

func (r Release) Equals(release Release) bool {
	if r.Major != release.KubernetesMajorVersion() {
		logger.V(4).Info("Major version not equal", "self Major", r.Major, "compare Major", release.KubernetesMajorVersion())
		return false
	}
	if r.Minor != release.KubernetesMinorVersion() {
		logger.V(4).Info("Minor version not equal", "self Minor", r.Minor, "compare Minor", release.KubernetesMinorVersion())
		return false
	}
	if r.Patch != release.KubernetesPatchVersion() {
		logger.V(4).Info("Patch version not equal", "self Patch", r.Patch, "compare Patch", release.KubernetesPatchVersion())
		return false
	}
	if r.Release != release.ReleaseNumber() {
		logger.V(4).Info("Release version not equal", "self Release", r.Release, "compare Release", release.ReleaseNumber())
		return false
	}
	return true
}

func getReleaseManifestBody(releaseBranch string, release int) (*v1alpha1.Release, error) {
	releaseManifestURL := fmt.Sprintf(eksDistroReleaseManifestUriTemplate, releaseBranch, releaseBranch, release)
	logger.Info("release manifest url", "ur", releaseManifestURL)
	fmt.Println(releaseManifestURL)
	resp, err := http.Get(releaseManifestURL)
	if err != nil {
		return nil, fmt.Errorf("getting Release Manifest: %w\n", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode != expectedStatusCode {
		return nil, fmt.Errorf("got status code %v when getting Release Manifest (expected %d)",
			resp.StatusCode, expectedStatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("reading Release Manifest: %w", err)
	}

	releaseObject := &v1alpha1.Release{}
	err = yaml.Unmarshal(body, releaseObject)

	return releaseObject, err
}
