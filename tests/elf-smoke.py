# Purpose: Prove the packaged REA command performs an ELF layout inspection.
import json
import os
import pathlib
import subprocess
import sys
import tempfile

rea, source = sys.argv[1:]
with tempfile.TemporaryDirectory() as directory:
    binary = pathlib.Path(directory) / "fixture"
    subprocess.run(["cc", source, "-o", binary], check=True)
    result = subprocess.run(
        [f"{rea}/bin/rea", "inspect-binary-layout", str(binary)],
        capture_output=True,
        text=True,
        env=os.environ.copy(),
    )
    if result.returncode != 0:
        raise RuntimeError(f"stdout: {result.stdout}\nstderr: {result.stderr}")
    assert "provider:" in result.stdout, result.stdout
    assert "id: pwntools-elf" in result.stdout, result.stdout
    assert "format: elf" in result.stdout, result.stdout

    import selectors

    with tempfile.TemporaryFile(mode="w+") as errors:
        process = subprocess.Popen(
            [f"{rea}/bin/rea", "mcp"], stdin=subprocess.PIPE,
            stdout=subprocess.PIPE, stderr=errors, text=True,
        )
        try:
            def request(identifier, method, params):
                process.stdin.write(json.dumps({"jsonrpc": "2.0", "id": identifier,
                                               "method": method, "params": params}) + "\n")
                process.stdin.flush()
                with selectors.DefaultSelector() as selector:
                    selector.register(process.stdout, selectors.EVENT_READ)
                    if not selector.select(45):
                        raise RuntimeError(f"MCP timeout: {method}")
                reply = json.loads(process.stdout.readline())
                assert reply.get("id") == identifier and "error" not in reply, reply
                return reply["result"]

            request(1, "initialize", {"protocolVersion": "2024-11-05", "capabilities": {},
                                     "clientInfo": {"name": "rea-nix-smoke", "version": "1"}})
            process.stdin.write('{"jsonrpc":"2.0","method":"notifications/initialized"}\n')
            process.stdin.flush()
            response = request(2, "tools/call", {
                "name": "inspect_binary_layout", "arguments": {"path": str(binary)}})
            assert not response.get("isError"), response
            evidence = json.dumps(response)
            assert "pwntools-elf" in evidence and "x86_64" in evidence, response
        finally:
            process.terminate()
            process.wait(timeout=10)
