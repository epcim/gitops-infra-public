#!/bin/python3
import subprocess
import sys

kubeseal = "kubeseal -o yaml".split()

secrets = sys.stdin.read()
for secret in secrets.split("\n---\n"):
    process = subprocess.Popen(kubeseal, stdin=subprocess.PIPE)
    process.stdin.write(secret.encode())
    process.communicate()

    if process.returncode == 0:
        print("---")
