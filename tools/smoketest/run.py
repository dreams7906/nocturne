"""Run Example.lua through its HTTP/loadstring entry point, then exercise the UI.

Usage: python tools/smoketest/run.py path/to/luau.exe
"""

import pathlib
import hashlib
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent


def read(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8").replace("\r\n", "\n")


def main() -> int:
    luau = sys.argv[1] if len(sys.argv) > 1 else "luau"
    mock = read(HERE / "mock.luau")
    bundle = read(ROOT / "Nocturne.lua").replace("--!nocheck", "", 1)
    example = read(ROOT / "Example.lua")
    fuzz = read(HERE / "fuzz.luau")
    digest = hashlib.sha256((ROOT / "Nocturne.lua").read_bytes()).hexdigest()[:12]
    source = f"""
local Mock = (function()
{mock}
end)()
local nativeLoadstring = loadstring
local environment = getfenv()
loadstring = function(source)
    local chunk, message = nativeLoadstring(source)
    if chunk then setfenv(chunk, environment) end
    return chunk, message
end
local downloads = 0
game._props.HttpGet = function(_, url)
    downloads += 1
    if url == "https://raw.githubusercontent.com/dreams7906/nocturne/main/Example.lua" then
        return [====[{example}]====]
    end
    assert(url == "https://raw.githubusercontent.com/dreams7906/nocturne/main/Nocturne.lua?v={digest}", "Unexpected or stale library URL: " .. url)
    return [====[{bundle}]====]
end
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/dreams7906/nocturne/main/Example.lua"))()
assert(downloads == 2, "Example must download the library exactly once")
assert(Library and Library.CreateWindow, "Example did not return its loaded library")
local ok, err = pcall(function(...)
{fuzz}
end, Mock, Library)
if not ok then table.insert(Mock.errors, tostring(err)) end
for _, message in ipairs(Mock.errors) do print(message) end
print(("\\n%d error(s)"):format(#Mock.errors))
"""
    out = HERE / "_combined.luau"
    out.write_text(source, encoding="utf-8", newline="\n")
    result = subprocess.run([luau, str(out)], capture_output=True, text=True)
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    return 0 if result.returncode == 0 and "\n0 error(s)" in result.stdout else 1


if __name__ == "__main__":
    sys.exit(main())
