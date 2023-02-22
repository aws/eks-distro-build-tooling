package consumerUpdater

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"regexp"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/eksDistroRelease"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
)

const (
	bottlerocketName    = "Bottlerocket"
)

var (
	linebreak = []byte("\n")
)

func NewBottleRocketUpdater(releases []*eksDistroRelease.Release) Consumer {
	return &BottlerocketUpdater{
		updaters:         bottlerocketUpdaters(releases),
		notifiers:        bottlerocketNotifiers(),
		bottlerocketInfo: bottlerocketConsumerInfo(),
	}
}

type BottlerocketUpdater struct {
	updaters         []Updater
	notifiers        []Notifier
	bottlerocketInfo ConsumerInfo
}

func (b BottlerocketUpdater) Updaters() []Updater {
	return b.updaters
}

func (b BottlerocketUpdater) UpdateAll() error {
	for _, u := range b.Updaters() {
		err := u.Update()
		if err != nil {
			return err
		}
	}
	return nil
}

func (b BottlerocketUpdater) Notifiers() []Notifier {
	return b.notifiers
}

func (b BottlerocketUpdater) NotifyAll() error {
	for _, u := range b.Notifiers() {
		err := u.Notify()
		if err != nil {
			return err
		}
	}
	return nil
}

func (b BottlerocketUpdater) Info() ConsumerInfo {
	return b.bottlerocketInfo
}

func bottlerocketConsumerInfo() ConsumerInfo {
	return ConsumerInfo{
		Name: bottlerocketName,
	}
}

func bottlerocketUpdaters(releases []*eksDistroRelease.Release) []Updater {
	var updaters []Updater
	updaters = append(updaters, bottlerocketGithubUpdaters(releases)...)
	return updaters
}

func bottlerocketGithubUpdaters(releases []*eksDistroRelease.Release) []Updater {
	var updaters []Updater
	for _, r := range releases {
		updaters = append(updaters, &bottlerocketGithubUpdater {
			eksDistroRelease: r,
		})
	}
	return updaters
}

func bottlerocketNotifiers() []Notifier {
	return []Notifier{}
}

type bottlerocketGithubUpdater struct {
	eksDistroRelease *eksDistroRelease.Release
}

func (g *bottlerocketGithubUpdater) Update() error {
	//implement updater here
	fmt.Printf("Bottlerocket update invoked for EKS D release \n Major: %d\n Minor: %d\n Patch: %d\n Release: %d\n",
		g.eksDistroRelease.KubernetesMajorVersion(),
		g.eksDistroRelease.KubernetesMinorVersion(),
		g.eksDistroRelease.KubernetesPatchVersion(),
		g.eksDistroRelease.ReleaseNumber())

	brRootDir, err := bottlerocketHomeDir()
	if err != nil {
		return fmt.Errorf("getting BR home dir: %v", err)
	}

	brReleaseDir := filepath.Join(brRootDir, "packages", fmt.Sprintf("kubernetes-%d.%d", g.eksDistroRelease.Major, g.eksDistroRelease.Minor))

	specPath := filepath.Join(brReleaseDir, fmt.Sprintf("kubernetes-%d.%d.spec", g.eksDistroRelease.Major, g.eksDistroRelease.Minor))
	if err = updateSpec(specPath, *g.eksDistroRelease); err != nil {
		return fmt.Errorf("updating spec file: %w", err)
	}

	cargoPath := filepath.Join(brReleaseDir, "Cargo.toml")
	if err = updateCargo(cargoPath, *g.eksDistroRelease); err != nil {
		return fmt.Errorf("updating cargo file: %w", err)
	}
	return nil
}

// updateCargo updates the file at provided path cargoPath
func updateCargo(cargoPath string, eksD eksDistroRelease.Release) error {
	logger.Info("updating Bottlerockt cargo.toml", "cargo.toml path", cargoPath, "eks distro release", eksD.EksDistroReleaseFullVersion())
	data, err := os.ReadFile(cargoPath)
	if err != nil {
		return fmt.Errorf("reading cargo file: %w", err)
	}

	splitData := bytes.Split(data, linebreak)
	urlLinePrefix := []byte("url = ")
	shaLinePrefix := []byte("sha512 = ")
	urlFound := false
	for i := 0; i < len(splitData); i++ {
		if bytes.HasPrefix(splitData[i], urlLinePrefix) {
			// Example —> url = "https://distro.eks.amazonaws.com/kubernetes-1-23/releases/6/artifacts/kubernetes/v1.23.12/kubernetes-src.tar.gz"
			splitData[i] = append(urlLinePrefix, fmt.Sprintf("%q", eksD.KubernetesSourceArchive().Archive.URI)...)
			urlFound = true
			for j := i + 1; j < len(splitData); j++ {
				if bytes.HasPrefix(splitData[j], shaLinePrefix) {
					// Example —> sha512 = "3033c434d02e6e0296a6659e36e64ce65f7d5408a5d6338dae04bd03225abc7b3a6691e6cce788ac624ba556602a0638b228c64af09e2c8ae19188286a21b5b5"
					splitData[j] = append(shaLinePrefix, fmt.Sprintf("%q", eksD.KubernetesSourceArchive().Archive.SHA512)...)
					logger.Info("updated cargo.toml file", "cargo.toml", cargoPath)
					return os.WriteFile(cargoPath, bytes.Join(splitData, linebreak), constants.OwnerWriteallReadOctal)
				}
			}
		}
	}
	var missingPrefix []byte
	if !urlFound {
		missingPrefix = urlLinePrefix
	} else {
		missingPrefix = shaLinePrefix
	}
	return fmt.Errorf("finding line with prefix %s in %s", missingPrefix, cargoPath)
}

// updateSpec updates the file at provided path specPath
func updateSpec(specPath string, eksD eksDistroRelease.Release) error {
	logger.Info("updating Bottlerockt spec file", "spec path", specPath, "eks distro release", eksD.EksDistroReleaseFullVersion())
	data, err := os.ReadFile(specPath)
	if err != nil {
		return fmt.Errorf("reading spec file: %w", err)
	}

	splitData := bytes.Split(data, linebreak)
	goverLinePrefix := []byte("%global gover ")
	sourceLinePrefix := []byte("Source0: ")
	goverFound := false

	for i := 0; i < len(splitData); i++ {
		if bytes.HasPrefix(splitData[i], goverLinePrefix) {
			// Example —> %global gover 1.23.12
			splitData[i] = append(goverLinePrefix, eksD.KubernetesFullVersion()...)
			goverFound = true
			for j := i + 1; j < len(splitData); j++ {
				if bytes.HasPrefix(splitData[j], sourceLinePrefix) {
					re := regexp.MustCompile(constants.SemverRegex)
					// Example —> Source0: https://distro.eks.amazonaws.com/kubernetes-1-23/releases/6/artifacts/kubernetes/v%{gover}/kubernetes-src.tar.gz
					splitData[j] = append(sourceLinePrefix, re.ReplaceAll([]byte(eksD.KubernetesSourceArchive().Archive.URI), []byte("%{gover}"))...)
					logger.Info("updated spec file", "spec", specPath)
					return os.WriteFile(specPath, bytes.Join(splitData, linebreak), constants.OwnerWriteallReadOctal)
				}
			}
		}
	}

	var missingPrefix []byte
	if !goverFound {
		missingPrefix = goverLinePrefix
	} else {
		missingPrefix = sourceLinePrefix
	}
	return fmt.Errorf("finding line with prefix %s in %s", missingPrefix, specPath)
}

func bottlerocketHomeDir()(string, error){
	dir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "workspace", "bottlerocket"), nil
}
