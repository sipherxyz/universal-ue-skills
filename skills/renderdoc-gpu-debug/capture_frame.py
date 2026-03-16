"""Capture a single GPU frame using the RenderDoc Python API.

Customize the variables below or drive them with environment variables before use.
"""

import os
import shutil
import sys
import time


RENDERDOC_PYTHON_PATH = os.environ.get("RENDERDOC_PYTHON_PATH", "")
if RENDERDOC_PYTHON_PATH:
    sys.path.insert(0, RENDERDOC_PYTHON_PATH)

import renderdoc as rd

cap_path = os.environ.get("RDC_CAPTURE_PATH", "./captures/frame.rdc")
exe = os.environ.get("RDC_CAPTURE_EXE", "/path/to/your/app")
args = os.environ.get("RDC_CAPTURE_ARGS", "")
workdir = os.environ.get("RDC_CAPTURE_CWD", os.getcwd())

opts = rd.CaptureOptions()
opts.apiValidation = False
opts.captureCallstacks = False
opts.refAllResources = False

env = []

if exe == "/path/to/your/app":
    print("Set RDC_CAPTURE_EXE to your application path before running this script.")
    sys.exit(1)

print("Executing and injecting...")
result = rd.ExecuteAndInject(exe, workdir, args, env, cap_path, opts, False)
print(f"Ident: {result.ident}")

if result.ident == 0:
    print("Failed to inject")
    sys.exit(1)

print("Connecting to target...")
target = rd.CreateTargetControl("", result.ident, "renderdoc-skill", True)

if target is None or not target.Connected():
    print("Failed to connect")
    sys.exit(1)

print("Connected. Brief init pump (3s)...")
for _ in range(30):
    target.ReceiveMessage(None)
    time.sleep(0.1)

print("Triggering capture...")
target.TriggerCapture(1)

print("Waiting for capture...")
cap_received = False
for i in range(100):  # 10 seconds max
    msg = target.ReceiveMessage(None)
    t = msg.type

    if t == rd.TargetControlMessageType.NewCapture:
        cap = msg.newCapture
        print(f"  Capture received: path={cap.path}")
        if cap.local and cap.path and cap.path != cap_path:
            os.makedirs(os.path.dirname(cap_path), exist_ok=True)
            shutil.copy2(cap.path, cap_path)
        elif not cap.local:
            target.CopyCapture(cap.captureId, cap_path)
        cap_received = True
        break
    elif t == rd.TargetControlMessageType.CaptureProgress:
        print(f"  Progress: {msg.capProgress:.0%}")

    time.sleep(0.1)

if not cap_received:
    print("No capture after 10s")

target.Shutdown()

if os.path.exists(cap_path):
    print(f"OK: {cap_path} ({os.path.getsize(cap_path):,} bytes)")
else:
    print("FAILED: no capture file")
