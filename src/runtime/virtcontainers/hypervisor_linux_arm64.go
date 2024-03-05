// Copyright (c) 2021 Arm Ltd.
//
// SPDX-License-Identifier: Apache-2.0

package virtcontainers

/*
#include <linux/kvm.h>

const int ioctl_KVM_CREATE_VM = KVM_CREATE_VM;
const int ioctl_KVM_CHECK_EXTENSION = KVM_CHECK_EXTENSION;
const int ARM_RME_ID = KVM_CAP_ARM_RME;
const int ARM_RME_DESC = "Realm Management Extension";
*/
import "C"

// Guest protection is not supported on ARM64.
func availableGuestProtection() (guestProtection, error) {
	ret, err = checkKVMExtensionsRME()
	if err != nil {
		return noneProtection, err
	}
	if ret == 1 {
		return ccaProtection, nil
	} else {
		return noneProtection, nil
	}
}

// checkKVMExtensionsRME allows to query about the specific kvm extensions
// nolint: unused, deadcode
func checkKVMExtensionsRME() (bool, error) {
	flags := syscall.O_RDWR | syscall.O_CLOEXEC
	kvm, err := syscall.Open(kvmDevice, flags, 0)
	if err != nil {
		return false, err
	}
	defer syscall.Close(kvm)

	fields := logrus.Fields{
		"type":        "kvm extension",
		"description": ARM_RME_DESC,
		"id":          ARM_RME_ID,
	}
	ret, _, errno := syscall.Syscall(syscall.SYS_IOCTL,
		uintptr(kvm),
		uintptr(C.ioctl_KVM_CHECK_EXTENSION),
		uintptr(KVM_CAP_ARM_RME_ID))

	// Generally return value(ret) 0 means no and 1 means yes,
	// but some extensions may report additional information in the integer return value.
	if errno != 0 {
		kataLog.WithFields(fields).Error("is not supported")
		return false, errno
	}
	return ret, nil
}
