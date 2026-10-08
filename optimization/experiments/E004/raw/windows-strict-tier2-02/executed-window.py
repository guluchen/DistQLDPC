"""Temporary, unprivileged Windows benchmark affinity and CPU telemetry.

Microsoft API references:
https://learn.microsoft.com/en-us/windows/win32/api/winternl/nf-winternl-ntquerysysteminformation
https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getlogicalprocessorinformationex
No exclusive reservation, power-plan mutation, or changes to other processes.
"""
import ctypes as C
import json
import os
import struct
import time

k = C.WinDLL('kernel32', use_last_error=True)
nt = C.WinDLL('ntdll')
k.GetCurrentProcess.restype = C.c_void_p
k.SetProcessAffinityMask.argtypes = [C.c_void_p, C.c_size_t]
k.GetProcessAffinityMask.argtypes = [C.c_void_p, C.POINTER(C.c_size_t), C.POINTER(C.c_size_t)]
k.SetThreadExecutionState.argtypes = [C.c_ulong]
k.SetThreadExecutionState.restype = C.c_ulong
k.CreateJobObjectW.argtypes = [C.c_void_p, C.c_wchar_p]
k.CreateJobObjectW.restype = C.c_void_p
k.SetInformationJobObject.argtypes = [C.c_void_p, C.c_int, C.c_void_p, C.c_ulong]
k.AssignProcessToJobObject.argtypes = [C.c_void_p, C.c_void_p]
k.CloseHandle.argtypes = [C.c_void_p]
k.GetPriorityClass.argtypes = [C.c_void_p]
k.GetPriorityClass.restype = C.c_ulong
k.SetPriorityClass.argtypes = [C.c_void_p, C.c_ulong]


class JobLimits(C.Structure):
    _fields_ = [('process_time', C.c_int64), ('job_time', C.c_int64), ('flags', C.c_ulong),
                ('min_working', C.c_size_t), ('max_working', C.c_size_t), ('active', C.c_ulong),
                ('affinity', C.c_size_t), ('priority', C.c_ulong), ('scheduling', C.c_ulong)]


def affinity(handle=None):
    p, s = C.c_size_t(), C.c_size_t()
    if not k.GetProcessAffinityMask(handle or k.GetCurrentProcess(), C.byref(p), C.byref(s)):
        raise C.WinError(C.get_last_error())
    return p.value


class ProcessEntry(C.Structure):
    _fields_ = [('size', C.c_ulong), ('usage', C.c_ulong), ('pid', C.c_ulong),
                ('heap', C.c_size_t), ('module', C.c_ulong), ('threads', C.c_ulong),
                ('parent', C.c_ulong), ('priority', C.c_long), ('flags', C.c_ulong),
                ('exe', C.c_wchar*260)]


def descendant_affinities(root_pid):
    """Read only owned descendants; tolerate processes exiting during snapshot."""
    k.CreateToolhelp32Snapshot.restype = C.c_void_p
    k.Process32FirstW.argtypes = [C.c_void_p, C.POINTER(ProcessEntry)]
    k.Process32NextW.argtypes = [C.c_void_p, C.POINTER(ProcessEntry)]
    k.OpenProcess.argtypes = [C.c_ulong, C.c_int, C.c_ulong]
    k.OpenProcess.restype = C.c_void_p
    k.CloseHandle.argtypes = [C.c_void_p]
    snapshot = k.CreateToolhelp32Snapshot(2, 0)
    assert snapshot not in (None, C.c_void_p(-1).value)
    entries, entry = [], ProcessEntry()
    entry.size = C.sizeof(entry)
    try:
        ok = k.Process32FirstW(snapshot, C.byref(entry))
        while ok:
            entries.append((entry.pid, entry.parent))
            ok = k.Process32NextW(snapshot, C.byref(entry))
    finally:
        k.CloseHandle(snapshot)
    owned = {root_pid}
    while True:
        more = {pid for pid, parent in entries if parent in owned}
        if more <= owned:
            break
        owned |= more
    records = []
    for pid in sorted(owned):
        handle = k.OpenProcess(0x1000, False, pid)
        if handle:
            try:
                records.append(dict(pid=pid, mask=affinity(handle), priority_class=k.GetPriorityClass(handle)))
            except OSError:
                pass  # exit race; no claim about an unobserved process
            finally:
                k.CloseHandle(handle)
    return records


def topology():
    assert C.sizeof(C.c_void_p) == 8 and os.cpu_count() <= 64, 'Single group x64 host required'
    size = C.c_ulong()
    k.GetLogicalProcessorInformationEx(0, None, C.byref(size))
    buf = C.create_string_buffer(size.value)
    if not k.GetLogicalProcessorInformationEx(0, buf, C.byref(size)):
        raise C.WinError(C.get_last_error())
    cores, offset = [], 0
    while offset < size.value:
        relation, length = struct.unpack_from('<II', buf, offset)
        assert relation == 0 and length >= 48
        assert struct.unpack_from('<H', buf, offset+30)[0] == 1
        mask, group = struct.unpack_from('<QH', buf, offset+32)
        assert group == 0
        cores.append([i for i in range(os.cpu_count()) if mask & (1 << i)])
        offset += length
    assert sorted(i for c in cores for i in c) == list(range(os.cpu_count()))
    return cores


class Perf(C.Structure):
    _fields_ = [('idle', C.c_int64), ('kernel', C.c_int64), ('user', C.c_int64),
                ('reserved', C.c_int64*2), ('count', C.c_ulong)]


def ticks():
    data = (Perf * os.cpu_count())()
    returned = C.c_ulong()
    status = nt.NtQuerySystemInformation(8, data, C.sizeof(data), C.byref(returned))
    assert status == 0 and returned.value == C.sizeof(data), (status, returned.value)
    return [(r.idle, r.kernel+r.user) for r in data]


def percentages(a, b):
    return [100*(y[0]-x[0])/(y[1]-x[1]) if y[1] > x[1] else None for x, y in zip(a, b)]


class Window:
    def __init__(self, allow_contention=False, priority_class=None):
        self.allow_contention = allow_contention
        self.priority_class = priority_class
        self.original_priority = k.GetPriorityClass(k.GetCurrentProcess())
        assert priority_class in (None, 0x20, 0x8000), 'Only Normal/AboveNormal benchmark priority supported'
        self.original_mask = affinity()
        self.cores = topology()
        before = ticks()
        time.sleep(5)
        after = ticks()
        idle = percentages(before, after)
        eligible = [core for core in self.cores if len(core) == 2
                    and all(self.original_mask & (1 << i) and idle[i] is not None and idle[i] >= 95 for i in core)]
        if not eligible and allow_contention:
            eligible = [core for core in self.cores if len(core) == 2
                        and all(self.original_mask & (1 << i) and idle[i] is not None for i in core)]
        assert eligible, 'No sufficiently idle physical core/SMT pair; no workload started'
        self.pair = max(eligible, key=lambda core: (min(idle[i] for i in core), min(core)))
        self.cpu, self.sibling = self.pair
        self.mask = 1 << self.cpu
        assert C.sizeof(JobLimits) == 64
        self.job = k.CreateJobObjectW(None, None)
        if not self.job:
            raise C.WinError(C.get_last_error())
        limits = JobLimits()
        limits.flags, limits.affinity = 0x10, self.mask
        if priority_class is not None:
            limits.flags |= 0x20  # JOB_OBJECT_LIMIT_PRIORITY_CLASS, applies to all owned descendants.
            limits.priority = priority_class
        if not k.SetInformationJobObject(self.job, 2, C.byref(limits), C.sizeof(limits)):
            k.CloseHandle(self.job)
            raise C.WinError(C.get_last_error())
        if not k.AssignProcessToJobObject(self.job, k.GetCurrentProcess()):
            k.CloseHandle(self.job)
            raise C.WinError(C.get_last_error())
        if not k.SetProcessAffinityMask(k.GetCurrentProcess(), self.mask):
            assert affinity() == self.mask  # Direct modification can be denied by fixed job affinity.
        assert affinity() == self.mask
        self.sleep_previous = k.SetThreadExecutionState(0x80000001)
        if not self.sleep_previous:
            empty = JobLimits()
            k.SetInformationJobObject(self.job, 2, C.byref(empty), C.sizeof(empty))
            k.CloseHandle(self.job)
            k.SetProcessAffinityMask(k.GetCurrentProcess(), self.original_mask)
            if priority_class is not None:
                k.SetPriorityClass(k.GetCurrentProcess(), self.original_priority)
            raise RuntimeError('Could not temporarily inhibit system sleep')
        self.selection = dict(topology=self.cores, selected_cpu=self.cpu, sibling=self.sibling,
                              original_affinity=self.original_mask, mask=self.mask,
                              idle_by_cpu=idle, sampling_sec=5, exclusive_reservation=False,
                              power_policy_changed=False, sleep_inhibition='temporary system requirement')
        self.selection['allow_contention'] = allow_contention
        self.selection['affinity_enforcement'] = 'Unnamed Windows Job Object JOB_OBJECT_LIMIT_AFFINITY; no breakaway flags'
        if priority_class is not None:
            if k.GetPriorityClass(k.GetCurrentProcess()) != priority_class:
                self.close()
                raise RuntimeError('Job priority class setup mismatch')
            self.selection['priority_class'] = priority_class
            self.selection['original_priority_class'] = self.original_priority
            self.selection['priority_enforcement'] = 'JOB_OBJECT_LIMIT_PRIORITY_CLASS on owned process tree'
        self.previous = ticks()

    def observe(self, label):
        current = ticks()
        idle = percentages(self.previous, current)
        a, b = self.previous, current
        total = sum(y[1]-x[1] for x, y in zip(a, b))
        global_idle = 100*sum(y[0]-x[0] for x, y in zip(a, b))/total if total else 0
        self.previous = current
        row = dict(label=label, time=time.time(), idle_percent=global_idle,
                   half_spare_logical_cpus=os.cpu_count()*global_idle/200,
                   selected_cpu_idle=idle[self.cpu], sibling_idle=idle[self.sibling],
                   affinity=affinity(), idle_by_cpu=idle)
        resource_ok = global_idle > 50 and row['half_spare_logical_cpus'] >= 1
        core_ok = row['sibling_idle'] is not None and row['sibling_idle'] >= 95
        if label.endswith('-preflight'):
            core_ok &= row['selected_cpu_idle'] is not None and row['selected_cpu_idle'] >= 95
        row['core_contention_detected'] = not core_ok
        row['eligible'] = resource_ok and (core_ok or self.allow_contention) and row['affinity'] == self.mask
        return row

    def close(self):
        empty = JobLimits()
        released = bool(k.SetInformationJobObject(self.job, 2, C.byref(empty), C.sizeof(empty)))
        k.CloseHandle(self.job)
        restored = bool(k.SetProcessAffinityMask(k.GetCurrentProcess(), self.original_mask))
        sleep_restored = bool(k.SetThreadExecutionState(self.sleep_previous))
        result = dict(job_limit_released=released, affinity_restored=restored, sleep_requirement_restored=sleep_restored,
                      final_mask=affinity())
        if self.priority_class is not None:
            result['priority_restored'] = bool(k.SetPriorityClass(k.GetCurrentProcess(), self.original_priority))
            result['final_priority_class'] = k.GetPriorityClass(k.GetCurrentProcess())
        return result


if __name__ == '__main__':
    window = Window()
    try:
        print(json.dumps(window.selection, indent=2))
    finally:
        print(json.dumps(window.close()))
