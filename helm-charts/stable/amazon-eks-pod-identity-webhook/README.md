## Helm chart for custom amazon-eks-pod-identity-webhook installation

This deploys [amazon-eks-pod-identity-webhook](https://github.com/aws/amazon-eks-pod-identity-webhook)
and the related job resources to automate the `cluster-up` target in the upstream repository.

Make sure to specify the image name with deploying this Helm chart.

All the resources are defined in `templates/` except for the `MutatingWebhookConfiguration`,
which gets applied as part of the `Job` during `post-install,post-upgrade`. The resources in
`template/` related to the job have a `job-` prefix. There is also a `CronJob` that executes
the same script as the `Job` to also be able to detect for newer `CertificateSigningRequests`
in case the webhook detects that the certifcate in the secret is about to expire.
