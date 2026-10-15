"""
Headless smoke test: runs Nocturne.lua + Example.lua inside a Roblox mock
with luau.exe, then fuzzes the UI (tools/smoketest/fuzz.luau).

Usage:  python tools/smoketest/run.py path/to/luau(.exe)
        python tools/smoketest/run.py path/to/luau(.exe) --remote
Get luau from https://github.com/luau-lang/luau/releases
"""

import pathlib
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

    source = f"""
local Mock = (function()
{mock}
end)()

local Library = (function()
{bundle}
end)()

local libraryStub = Mock.instance("ModuleScript", {{ Name = "Nocturne" }})
libraryStub.Parent = game:GetService("ReplicatedStorage")
local nativeRequire = require
require = function(target)
	if target == libraryStub then
		return Library
	end
	return nativeRequire(target)
end

local exampleOk, exampleErr = pcall(function()
{example}
end)
if not exampleOk then
	table.insert(Mock.errors, "Example.lua: " .. tostring(exampleErr))
end

local fuzzOk, fuzzErr = pcall(function(...)
{fuzz}
end, Mock, Library)
if not fuzzOk then
	table.insert(Mock.errors, "fuzz: " .. tostring(fuzzErr))
end

print(("\\n%d error(s)"):format(#Mock.errors))
local seen = {{}}
for _, err in ipairs(Mock.errors) do
	local key = string.sub(err, 1, 300)
	if not seen[key] then
		seen[key] = true
		print("- " .. err)
	end
end
"""
    if "--remote" in sys.argv[2:]:
        remote = read(ROOT / "RemoteExample.lua")
        # Exercise the real loadstring path without a ReplicatedStorage module.
        source = f"""
local Mock = (function()
{mock}
end)()
local nativeLoadstring = loadstring
local environment = getfenv()
loadstring = function(source)
    local chunk, message = nativeLoadstring(source)
    if chunk then
        -- Loaded chunks need the mock's typeof/Enum overrides too.
        setfenv(chunk, environment)
    end
    return chunk, message
end
game._props.HttpGet = function(_, url)
    assert(string.match(url, "^https://raw%.githubusercontent%.com/dreams7906/nocturne/main/Nocturne%.lua%?v=%x+$"), "Unexpected URL: " .. url)
    return [====[{bundle}]====]
end
local Library = (function()
{remote}
return Library
end)()
assert(Library and Library.CreateWindow, "Remote loader did not return the library")
local ok, err = pcall(function(...)
{fuzz}
end, Mock, Library)
if not ok then
    table.insert(Mock.errors, tostring(err))
end
for _, message in ipairs(Mock.errors) do
    print(message)
end
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
