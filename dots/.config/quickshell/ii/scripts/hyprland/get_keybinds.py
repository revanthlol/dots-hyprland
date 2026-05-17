#!/usr/bin/env python3
import argparse
import ast
import json
import os
import re
import subprocess
import tempfile
from pathlib import Path


MOD_NORMALIZATION = {
    "SUPER": "Super",
    "CTRL": "Ctrl",
    "ALT": "Alt",
    "SHIFT": "Shift",
    "SUPER_L": "Super_L",
    "SUPER_R": "Super_R",
    "SPACE": "Space",
    "TAB": "Tab",
    "RETURN": "Return",
    "DELETE": "Delete",
    "BACKSPACE": "BackSpace",
    "ESCAPE": "Escape",
    "SEMICOLON": "Semicolon",
    "APOSTROPHE": "Apostrophe",
    "PERIOD": "Period",
    "SLASH": "Slash",
    "BACKSLASH": "Backslash",
    "HASH": "Hash",
    "MINUS": "Minus",
    "EQUAL": "Equal",
}


class KeyBinding(dict):
    def __init__(self, mods, key, comment) -> None:
        self["mods"] = mods
        self["key"] = key
        self["comment"] = comment


class Section(dict):
    def __init__(self, name="") -> None:
        self["children"] = []
        self["keybinds"] = []
        self["name"] = name


def read_content(path: str) -> str:
    resolved = os.path.expanduser(os.path.expandvars(path))
    if not os.access(resolved, os.R_OK):
        return "error"
    with open(resolved, "r", encoding="utf-8") as file:
        return file.read()


def normalize_token(token: str) -> str:
    token = token.strip()
    upper = token.upper()
    return MOD_NORMALIZATION.get(upper, token)


def split_combo(combo: str):
    parts = [part.strip() for part in combo.split("+") if part.strip()]
    if not parts:
        return [], ""
    if len(parts) == 1:
        return [], normalize_token(parts[0])
    mods = [normalize_token(part) for part in parts[:-1]]
    key = normalize_token(parts[-1])
    return mods, key


def extract_bind_block(lines, start_index):
    block_lines = [lines[start_index]]
    depth = balance_delta(lines[start_index])
    index = start_index
    while depth > 0 and index + 1 < len(lines):
        index += 1
        block_lines.append(lines[index])
        depth += balance_delta(lines[index])
    return "\n".join(block_lines), index


def balance_delta(text: str) -> int:
    depth = 0
    in_string = None
    escape = False
    i = 0
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == in_string:
                in_string = None
        else:
            if ch == "-" and nxt == "-":
                break
            if ch in ("'", '"'):
                in_string = ch
            elif ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
        i += 1
    return depth


def run_lua_capture(target_path: Path):
    base_dir = target_path.parent
    lua_script = f"""
local target = arg[1]
local base_dir = target:match("(.+)/[^/]+$") or "."
package.path = table.concat({{
  base_dir .. "/?.lua",
  base_dir .. "/?/init.lua",
  package.path,
}}, ";")
package.preload["hyprland.lib"] = function() return {{}} end
package.preload["hyprland/lib"] = function() return {{}} end

local bindings = {{}}

local function proxy()
  return setmetatable({{}}, {{
    __index = function()
      return function(...)
        return proxy()
      end
    end,
  }})
end

hl = {{}}
hl.dsp = setmetatable({{
  global = function(...) return proxy() end,
  exec_cmd = function(...) return proxy() end,
  layout = function(...) return proxy() end,
  focus = function(...) return proxy() end,
  monitor = function(...) return proxy() end,
  gesture = function(...) return proxy() end,
  cursor = proxy(),
  window = setmetatable({{}}, {{
    __index = function()
      return function(...) return proxy() end
    end,
  }}),
  workspace = setmetatable({{}}, {{
    __index = function()
      return function(...) return proxy() end
    end,
  }}),
}}, {{
  __index = function()
    return function(...) return proxy() end
  end,
}})

function hl.bind(combo, _action, opts)
  local description = ""
  if type(opts) == "table" and opts.description ~= nil then
    description = tostring(opts.description)
  end
  table.insert(bindings, {{ combo = tostring(combo), description = description }})
end

function hl.config(...) end
function hl.curve(...) end
function hl.animation(...) end
function hl.monitor(...) end
function hl.gesture(...) end
function hl.window_rule(...) end
function hl.layer_rule(...) end
function hl.workspace_rule(...) end
function hl.exec_cmd(...) end
function hl.dispatch(...) end
function hl.define_submap(_name, fn)
  if type(fn) == "function" then
    pcall(fn)
  end
end
function hl.env(...) end
function hl.get_config(...) return 0 end
function hl.get_current_submap() return "" end
function hl.get_active_workspace() return {{ id = 1 }} end
hl.notification = {{ create = function(...) end }}

HOME = os.getenv("HOME") or ""
function is_file_exists(_path) return false end
function create_if_not_exists(_path) return false end
function workspace_in_group(i) return i end

function hl.on(_event, fn)
  if type(fn) == "function" then
    pcall(fn)
  end
end

local ok, err = pcall(dofile, target)
if not ok then
  io.stderr:write(err .. "\\n")
  os.exit(1)
end

for _, item in ipairs(bindings) do
  print(string.format("%q\\t%q", item.combo or "", item.description or ""))
end
"""

    with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False) as lua_file:
        lua_file.write(lua_script)
        lua_path = lua_file.name

    try:
        proc = subprocess.run(
            ["lua5.4", lua_path, str(target_path)],
            check=True,
            capture_output=True,
            text=True,
        )
    finally:
        os.unlink(lua_path)

    bindings = []
    for line in proc.stdout.splitlines():
        if "\t" not in line:
            continue
        combo_q, desc_q = line.split("\t", 1)
        combo = ast.literal_eval(combo_q)
        description = ast.literal_eval(desc_q)
        bindings.append({"combo": combo, "description": description})
    return bindings


def source_files_for(target_path: Path):
    if target_path.name == "hyprland.lua":
        base_dir = target_path.parent
        files = [base_dir / "hyprland" / "keybinds.lua"]
        custom_file = base_dir / "custom" / "keybinds.lua"
        if custom_file.exists():
            files.append(custom_file)
        return files
    return [target_path]


def add_bind_to_section(section, binding):
    mods, key = split_combo(binding["combo"])
    comment = binding["description"] if binding["description"] else binding["combo"]
    section["keybinds"].append(KeyBinding(mods, key, comment))


def parse_bind_sources(source_paths, bindings):
    root = Section("")
    bind_index = 0

    def next_binding():
        nonlocal bind_index
        if bind_index >= len(bindings):
            return None
        item = bindings[bind_index]
        bind_index += 1
        return item

    for source_path in source_paths:
        content = read_content(str(source_path))
        if content == "error":
            continue

        lines = content.splitlines()
        if source_path.name == "keybinds.lua" and source_path.parent.name == "hyprland":
            current_root = Section("Shell")
            root["children"].append(current_root)
            stack = [(0, root), (1, current_root)]
        else:
            current_root = Section("Custom")
            root["children"].append(current_root)
            stack = [(0, root), (1, current_root)]

        i = 0
        while i < len(lines):
            line = lines[i]
            stripped = line.strip()

            heading = re.match(r"^\s*--\s*(#+)!+\s*(.*)$", line)
            if heading:
                level = max(len(heading.group(1)) - 1, 1)
                name = heading.group(2).strip()
                if not name:
                    i += 1
                    continue
                while len(stack) > 1 and stack[-1][0] >= level:
                    stack.pop()
                parent = stack[-1][1]
                section = Section(name)
                parent["children"].append(section)
                stack.append((level, section))
                i += 1
                continue

            subsection = re.match(r"^\s*--\s*#\s+(?!/)(.*\S)\s*$", line)
            if subsection:
                name = subsection.group(1).strip()
                if not name:
                    i += 1
                    continue
                while len(stack) > 1 and stack[-1][0] >= 2:
                    stack.pop()
                parent = stack[-1][1]
                section = Section(name)
                parent["children"].append(section)
                stack.append((2, section))
                i += 1
                continue

            if stripped.startswith("hl.bind("):
                _, end_index = extract_bind_block(lines, i)
                binding = next_binding()
                if binding is not None:
                    add_bind_to_section(stack[-1][1], binding)
                i = end_index + 1
                continue

            i += 1

    return root


def parse_file(path: str):
    target_path = Path(os.path.expanduser(os.path.expandvars(path))).resolve()
    if not target_path.exists():
        return {"children": []}

    bindings = run_lua_capture(target_path)
    source_paths = source_files_for(target_path)
    return parse_bind_sources(source_paths, bindings)


def main():
    parser = argparse.ArgumentParser(description="Parse Hyprland Lua keybind files.")
    parser.add_argument("--path", type=str, required=True, help="Path to a Lua Hyprland config entrypoint.")
    args = parser.parse_args()
    print(json.dumps(parse_file(args.path)))


if __name__ == "__main__":
    main()
