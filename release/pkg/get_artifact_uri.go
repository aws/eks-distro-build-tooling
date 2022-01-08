package pkg

import (
	"fmt"
	"strings"

	distrov1alpha1 "github.com/aws/eks-distro-build-tooling/release/api/v1alpha1"
)

func GetAssetUri(releaseManifestUrl, component, assetType, os, arch string) (string, error) {
	eksDRelease, err := getEksdRelease(releaseManifestUrl)
	if err != nil {
		return "", fmt.Errorf("error getting EKS Distro release from manifest URL: %v", err)
	}

	uri, err := parseReleaseForUri(eksDRelease, component, assetType, os, arch)
	if err != nil {
		return "", fmt.Errorf("error parsing EKS Distro release for component URI: %v", err)
	}

	return uri, nil
}

func parseReleaseForUri(release *distrov1alpha1.Release, componentName, assetType, osName, arch string) (string, error) {
	assets := []distrov1alpha1.Asset{}
	for _, component := range release.Status.Components {
		if component.Name == componentName {
			for _, asset := range component.Assets {
				if asset.OS == osName && strings.ToLower(asset.Type) == assetType && sliceContains(asset.Arch, arch) {
					assets = append(assets, asset)
				}
			}
		}
	}

	pos := 1
	if len(assets) > 0 {
		if len(assets) > 1 {
			fmt.Printf("Component %s has the following assets corresponding to %s type:\n", componentName, assetType)
			for i, asset := range assets {
				fmt.Printf("%d. %s\n", (i + 1), asset.Description)
			}
			fmt.Printf("\nPlease select the required asset from the above list: ")
			fmt.Scanf("%d\n", &pos)
		}
		switch assetType {
		case "image":
			return assets[(pos - 1)].Image.URI, nil
		case "archive":
			return assets[(pos - 1)].Archive.URI, nil
		}
	}

	return "", fmt.Errorf("no artifact found for requested combination")
}
