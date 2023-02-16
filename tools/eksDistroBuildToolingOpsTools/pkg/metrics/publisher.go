package metrics

import (
	"fmt"

	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/cloudwatch"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
)

func New(cloudwatchClient cloudwatch.CloudWatch) *MetricPublisher {
	return &MetricPublisher{
		cloudwatchClient: cloudwatchClient,
	}
}

type MetricPublisher struct {
	cloudwatchClient cloudwatch.CloudWatch
}

func (m *MetricPublisher) publishMetric(metric *cloudwatch.PutMetricDataInput) (*cloudwatch.PutMetricDataOutput, error) {
	outputData, err := m.cloudwatchClient.PutMetricData(metric)
	logger.V(9).Info("put metric data", "inputData", metric.MetricData, "outputData", outputData)
	if err != nil {
		if awsErr, ok := err.(awserr.Error); ok {
			switch awsErr.Code() {
			case cloudwatch.ErrCodeInvalidParameterValueException:
				return nil, fmt.Errorf("invalid parameter value: %v code: %v", awsErr.Message(), awsErr.Code())
			case cloudwatch.ErrCodeMissingRequiredParameterException:
				return nil, fmt.Errorf("required parameter missing: %v code: %v", awsErr.Message(), awsErr.Code())
			case cloudwatch.ErrCodeInvalidParameterCombinationException:
				return nil, fmt.Errorf("invalid parameter combination: %v code: %v", awsErr.Message(), awsErr.Code())
			case cloudwatch.ErrCodeInternalServiceFault :
				return nil, fmt.Errorf("cloudwatch internal service fault: %v code: %v", awsErr.Message(), awsErr.Code())
			}
		}
		return nil, fmt.Errorf("putting metric data %v: %v", metric.MetricData, err)
	}
	return outputData, nil
}
