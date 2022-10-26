package prowJobs

import (
	"github.com/aws/eks-distro-build-tooling/golang/conformance-test-executor/pkg/constants"
	prowJobTypes "github.com/aws/eks-distro-prow-jobs/templater/jobs/types"
)

const defaultTimeout = "6h"
const defaultMemoryRequest = "8Gi"
const defaultCpuRequest = "2"

type GenerateConformanceTestsProwJobsOptions struct {
	TestRoleArn                 string
	ArtifactsBucket             string
	ControlPlaneInstanceProfile string
	NodeInstanceProfile         string
	KopsStateStore              string
	ImageRepo                   string
	DockerConfig                string
	RuntimeImage                string
	Timeout                     string
	CpuRequest                  string
	MemoryRequest               string
	RebuildAll                  bool
	PreExecuteCommands          []string
	PostExecuteCommands         []string
}

func (g GenerateConformanceTestsProwJobsOptions) setDefaults() {
	if g.TestRoleArn == "" {
		g.TestRoleArn = constants.TestRoleArn
	}

	if g.ArtifactsBucket == "" {
		g.ArtifactsBucket = constants.EksDPostSubmitArtifactsBucket
	}

	if g.ControlPlaneInstanceProfile == "" {
		g.ControlPlaneInstanceProfile = constants.ControlPlaneInstanceProfile
	}

	if g.NodeInstanceProfile == "" {
		g.NodeInstanceProfile = constants.KopsNodeInstanceProfile
	}

	if g.KopsStateStore == "" {
		g.KopsStateStore = constants.KopsStateStoreBucket
	}

	if g.ImageRepo == "" {
		g.ImageRepo = constants.ImageRepo
	}

	if g.DockerConfig == "" {
		g.DockerConfig = constants.DockerConfig
	}

	if g.Timeout == "" {
		g.Timeout = defaultTimeout
	}

	if g.MemoryRequest == "" {
		g.MemoryRequest = defaultMemoryRequest
	}

	if g.CpuRequest == "" {
		g.CpuRequest = defaultCpuRequest
	}

	if !g.RebuildAll {
		g.RebuildAll = true
	}
}

func GenerateConformanceTestProwJob(eksDistroVersion string, opts GenerateConformanceTestsProwJobsOptions) []byte {
	opts.setDefaults()

	job := prowJobTypes.JobConfig{}
	job.JobName = "eks-go-custom-conformance-test"
	job.Architecture = constants.AMD64Arch

	job.Resources.Requests.CPU = opts.CpuRequest
	job.Resources.Requests.Memory = opts.MemoryRequest

	job.Timeout = opts.Timeout

	job.ImageBuild = true

	if opts.RuntimeImage != "" {
		job.RuntimeImage = opts.RuntimeImage
	}

	job.Commands = []string{
		"cp -r \"${HOME}/.docker\" /home/prow/go/src/github.com/aws/eks-distro",
		"make -j2 postsubmit-conformance",
	}

	if opts.PreExecuteCommands != nil {
		job.Commands = append(opts.PreExecuteCommands, opts.PreExecuteCommands...)
	}

	if opts.PostExecuteCommands != nil {
		job.Commands = append(job.Commands, opts.PostExecuteCommands...)
	}

	job.EnvVars = []*prowJobTypes.EnvVar{
		{
			"TEST_ROLE_ARN",
			opts.TestRoleArn,
		},
		{
			"ARTIFACT_BUCKET",
			opts.ArtifactsBucket,
		},
		{
			"RELEASE_BRANCH",
			eksDistroVersion,
		},
		{
			"CONTROL_PLANE_INSTANCE_PROFILE",
			opts.ControlPlaneInstanceProfile,
		},
		{
			"NODE_INSTANCE_PROFILE",
			opts.NodeInstanceProfile,
		},
		{
			"KOPS_STATE_STORE",
			opts.KopsStateStore,
		},
		{
			"IMAGE_REPO",
			opts.ImageRepo,
		},
		{
			"DOCKER_CONFIG",
			opts.DockerConfig,
		},
	}
}