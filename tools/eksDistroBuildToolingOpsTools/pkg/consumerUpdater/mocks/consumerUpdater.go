// Code generated by MockGen. DO NOT EDIT.
// Source: github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/consumerUpdater (interfaces: Consumer,Updater,Notifier)

// Package mocks is a generated GoMock package.
package mocks

import (
	reflect "reflect"

	consumerUpdater "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/consumerUpdater"
	gomock "github.com/golang/mock/gomock"
)

// MockConsumer is a mock of Consumer interface.
type MockConsumer struct {
	ctrl     *gomock.Controller
	recorder *MockConsumerMockRecorder
}

// MockConsumerMockRecorder is the mock recorder for MockConsumer.
type MockConsumerMockRecorder struct {
	mock *MockConsumer
}

// NewMockConsumer creates a new mock instance.
func NewMockConsumer(ctrl *gomock.Controller) *MockConsumer {
	mock := &MockConsumer{ctrl: ctrl}
	mock.recorder = &MockConsumerMockRecorder{mock}
	return mock
}

// EXPECT returns an object that allows the caller to indicate expected use.
func (m *MockConsumer) EXPECT() *MockConsumerMockRecorder {
	return m.recorder
}

// Info mocks base method.
func (m *MockConsumer) Info() consumerUpdater.ConsumerInfo {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "Info")
	ret0, _ := ret[0].(consumerUpdater.ConsumerInfo)
	return ret0
}

// Info indicates an expected call of Info.
func (mr *MockConsumerMockRecorder) Info() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "Info", reflect.TypeOf((*MockConsumer)(nil).Info))
}

// Notifiers mocks base method.
func (m *MockConsumer) Notifiers() []consumerUpdater.Notifier {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "Notifiers")
	ret0, _ := ret[0].([]consumerUpdater.Notifier)
	return ret0
}

// Notifiers indicates an expected call of Notifiers.
func (mr *MockConsumerMockRecorder) Notifiers() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "Notifiers", reflect.TypeOf((*MockConsumer)(nil).Notifiers))
}

// NotifyAll mocks base method.
func (m *MockConsumer) NotifyAll() error {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "NotifyAll")
	ret0, _ := ret[0].(error)
	return ret0
}

// NotifyAll indicates an expected call of NotifyAll.
func (mr *MockConsumerMockRecorder) NotifyAll() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "NotifyAll", reflect.TypeOf((*MockConsumer)(nil).NotifyAll))
}

// UpdateAll mocks base method.
func (m *MockConsumer) UpdateAll() error {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "UpdateAll")
	ret0, _ := ret[0].(error)
	return ret0
}

// UpdateAll indicates an expected call of UpdateAll.
func (mr *MockConsumerMockRecorder) UpdateAll() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "UpdateAll", reflect.TypeOf((*MockConsumer)(nil).UpdateAll))
}

// Updaters mocks base method.
func (m *MockConsumer) Updaters() []consumerUpdater.Updater {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "Updaters")
	ret0, _ := ret[0].([]consumerUpdater.Updater)
	return ret0
}

// Updaters indicates an expected call of Updaters.
func (mr *MockConsumerMockRecorder) Updaters() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "Updaters", reflect.TypeOf((*MockConsumer)(nil).Updaters))
}

// MockUpdater is a mock of Updater interface.
type MockUpdater struct {
	ctrl     *gomock.Controller
	recorder *MockUpdaterMockRecorder
}

// MockUpdaterMockRecorder is the mock recorder for MockUpdater.
type MockUpdaterMockRecorder struct {
	mock *MockUpdater
}

// NewMockUpdater creates a new mock instance.
func NewMockUpdater(ctrl *gomock.Controller) *MockUpdater {
	mock := &MockUpdater{ctrl: ctrl}
	mock.recorder = &MockUpdaterMockRecorder{mock}
	return mock
}

// EXPECT returns an object that allows the caller to indicate expected use.
func (m *MockUpdater) EXPECT() *MockUpdaterMockRecorder {
	return m.recorder
}

// Update mocks base method.
func (m *MockUpdater) Update() error {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "Update")
	ret0, _ := ret[0].(error)
	return ret0
}

// Update indicates an expected call of Update.
func (mr *MockUpdaterMockRecorder) Update() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "Update", reflect.TypeOf((*MockUpdater)(nil).Update))
}

// MockNotifier is a mock of Notifier interface.
type MockNotifier struct {
	ctrl     *gomock.Controller
	recorder *MockNotifierMockRecorder
}

// MockNotifierMockRecorder is the mock recorder for MockNotifier.
type MockNotifierMockRecorder struct {
	mock *MockNotifier
}

// NewMockNotifier creates a new mock instance.
func NewMockNotifier(ctrl *gomock.Controller) *MockNotifier {
	mock := &MockNotifier{ctrl: ctrl}
	mock.recorder = &MockNotifierMockRecorder{mock}
	return mock
}

// EXPECT returns an object that allows the caller to indicate expected use.
func (m *MockNotifier) EXPECT() *MockNotifierMockRecorder {
	return m.recorder
}

// Notify mocks base method.
func (m *MockNotifier) Notify() error {
	m.ctrl.T.Helper()
	ret := m.ctrl.Call(m, "Notify")
	ret0, _ := ret[0].(error)
	return ret0
}

// Notify indicates an expected call of Notify.
func (mr *MockNotifierMockRecorder) Notify() *gomock.Call {
	mr.mock.ctrl.T.Helper()
	return mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "Notify", reflect.TypeOf((*MockNotifier)(nil).Notify))
}
