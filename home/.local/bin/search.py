#!/usr/bin/env python

import sys
import json
import os
import subprocess
import urllib.request
from typing import Any

RESET = "\033[0m"
DIM = "\033[2m"
YELLOW = "\033[33m"
RED = "\033[31m"

MODEL = "Qwen3.5-2B-Q8_0"
API_URL = "http://localhost:8012/v1/chat/completions"
SYSTEM_PROMPT = """
You are a codebase search tool. Your only job is to find all locations matching the user's request and call `write_report`.

<rules>
  <rule>Start with ONE broad `grep_search` covering the most likely pattern (e.g. "alloc" for allocations).</rule>
  <rule>If results are incomplete, do at most ONE or TWO follow-up searches with different patterns.</rule>
  <rule>Never search for the same pattern twice.</rule>
  <rule>Do not read files unless grep results are ambiguous about the line content.</rule>
  <rule>Collect ALL matching lines including column numbers from grep output.</rule>
  <rule>Call `write_report` immediately once you have enough results. Do not explain or summarize.</rule>
  <rule>When you feel stuck, call `write_report` with what you have. Partial results are better than looping forever.</rule>
</rules>

The grep output format is: filepath:line:column:content
Parse this directly to fill `write_report` entries with accurate filepath, line, column, and the matched content as short_description.
"""
TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "read_file",
            "description": "Read a file by path, start line number and line count. Useful if you already know the line number of search from eg. grep_search, but want a bit more context.",
            "parameters": {
                "type": "object",
                "required": ["path", "offset", "limit"],
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path relative to project root, no leading slash.",
                    },
                    "offset": {
                        "type": "integer",
                        "description": "Start line number to read from.",
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Number of lines to read.",
                    },
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "grep_search",
            "description": "Search for a file or content with a grep pattern in the current project. This will give you all occurences of the pattern in the current project in all the file names and their content.",
            "parameters": {
                "type": "object",
                "required": ["pattern"],
                "properties": {
                    "pattern": {
                        "type": "string",
                        "description": "Pattern to search for in the current project and directory only.",
                    },
                    "path": {
                        "type": "string",
                        "description": "Optional. Restrict search to this file or directory path.",
                    },
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "write_report",
            "description": "Create a report with a list of all entries. Entries need to contain all of the locations you have found during your search.",
            "parameters": {
                "type": "object",
                "required": ["entries"],
                "properties": {
                    "entries": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "required": [
                                "filepath",
                                "line",
                                "short_description",
                            ],
                            "properties": {
                                "filepath": {
                                    "type": "string",
                                    "description": "this should be a valid path to a file",
                                },
                                "line": {"type": "integer"},
                                "short_description": {"type": "string"},
                            },
                        },
                    },
                },
            },
        },
    },
]
FD_ARGS = [
    "--type=f",
    "--type=l",
    "--hidden",
    "--follow",
    "--exclude=.git",
]
RG_ARGS = [
    "--line-number",
    "--no-heading",
    "--smart-case",
    "--hidden",
    "--glob=!.git",
]
RG_RESULT_LIMIT = 100


class ToolError(Exception):
    pass


def read_file(path: str, offset: int, limit: int) -> str:
    if len(path) == 0:
        raise ToolError("`path` argument cannot be empty")

    path = path.lstrip("/")

    if not os.path.exists(path):
        raise ToolError(f"File '{path}' does not exist.")

    awk_result = subprocess.run(
        [
            "awk",
            f'NR>={offset} && NR<={offset + limit} {{print NR": "$0}}',
            path,
        ],
        capture_output=True,
        text=True,
    )
    if awk_result.returncode != 0:
        raise ToolError(awk_result.stderr)

    return awk_result.stdout if awk_result.stdout else "No results found."


def grep_search(query: str, path: str = "") -> str:
    if not query:
        raise ToolError("`query` is required and cannot be empty")

    results = set()

    fd_result = subprocess.run(["fd", query, *FD_ARGS], capture_output=True, text=True)
    if fd_result.stdout:
        for line in fd_result.stdout.splitlines():
            results.add(line)

    rg_cmd = ["rg", query, *RG_ARGS]
    if path:
        rg_cmd.append(path.lstrip("/"))

    rg_result = subprocess.run(rg_cmd, capture_output=True, text=True)
    if rg_result.stdout:
        for line in rg_result.stdout.splitlines():
            results.add(line)

    final_list = sorted(list(results))
    truncated = len(final_list) > RG_RESULT_LIMIT

    output = "\n".join(final_list[:RG_RESULT_LIMIT])
    if truncated:
        output += "\n[Results truncated at 100 - narrow your pattern]"

    return output if output else f"No matches found for '{query}'."


def write_report(entries: list[dict]) -> str:
    if len(entries) == 0:
        raise ToolError(
            "`entries` argument cannot be empty. Provide all the locations you have found that are relevant to the initial request."
        )
    quickfix = []
    for entry in entries:
        filepath = entry.get("filepath")
        assert type(filepath) is str
        filepath = filepath.lstrip("/")
        if not filepath or not os.path.exists(filepath):
            raise ToolError(f"Filepath {filepath} does not exist")
        quickfix.append(
            f"{entry.get('filepath')}:{entry.get('line')}:0:{entry.get('short_description')}"
        )
    return "\n".join(quickfix)


def handle_tool_call(name: str, args: dict[str, Any]) -> str:
    match name:
        case "read_file":
            return read_file(args["path"], args["offset"], args["limit"])
        case "grep_search":
            return grep_search(args["pattern"], args.get("path", ""))
        case "write_report":
            return write_report(args["entries"])
        case _:
            assert False


def stream_complete(messages: list[dict[str, Any]]) -> dict[str, Any]:
    payload = dict(
        model=MODEL,
        messages=messages,
        tools=TOOLS,
        stream=True,
        temperature=0.8,
        top_p=1.0,
        top_k=10,
        min_p=0.0,
        presence_penalty=1.0,
    )
    req = urllib.request.Request(
        API_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    reasoning = ""
    content = ""
    tool_calls: dict[int, dict[str, Any]] = {}
    finish_reason = None
    in_reasoning = False
    in_content = False

    with urllib.request.urlopen(req) as resp:
        assert resp.status == 200

        for raw_line in resp:
            assert raw_line
            line = raw_line.decode("utf-8").rstrip("\r\n")
            if not line:
                continue

            prefix = "data: "
            if not line.startswith(prefix):
                continue

            payload = line[len(prefix) :]
            if payload == "[DONE]":
                break

            chunk = json.loads(payload)
            choice = chunk.get("choices", [{}])[0]
            delta = choice.get("delta", {})
            finish_reason = choice.get("finish_reason", finish_reason)

            if reasoning_delta := delta.get("reasoning_content", ""):
                if not in_reasoning:
                    in_reasoning = True
                print(f"{DIM}{reasoning_delta}{RESET}", end="", flush=True)
                reasoning += reasoning_delta

            if content_delta := delta.get("content"):
                if not in_content:
                    if in_reasoning and len(content_delta) > 0:
                        print("", flush=True)
                    in_content = True
                if not content.endswith(content_delta):
                    print(content_delta, end="", flush=True)
                    content += content_delta

            for tc_delta in delta.get("tool_calls", []):
                idx = tc_delta["index"]
                if idx not in tool_calls:
                    tool_calls[idx] = dict(
                        id=tc_delta.get("id", ""),
                        type="function",
                        function=dict(name="", arguments=""),
                    )
                fun = tc_delta.get("function", {})
                tool_calls[idx]["function"]["name"] += fun.get("name", "")
                tool_calls[idx]["function"]["arguments"] += fun.get("arguments", "")

    if in_reasoning or in_content:
        print()

    message: dict[str, Any] = dict(role="assistant")
    if content:
        message["content"] = content
    if reasoning:
        message["reasoning_content"] = reasoning
    if tool_calls:
        message["tool_calls"] = list(tool_calls.values())

    return dict(message=message, finish_reason=finish_reason)


def run(user_prompt: str) -> str:
    messages = [
        dict(role="system", content=SYSTEM_PROMPT),
        dict(role="user", content=user_prompt),
    ]

    seen_calls: set[str] = set()
    repeat_count: dict[str, int] = {}

    while True:
        choice = stream_complete(messages)
        message = choice["message"]
        messages.append(message)

        tool_calls = message.get("tool_calls", [])

        if choice["finish_reason"] == "stop" and not tool_calls:
            reminder = (
                "You did not call `write_report`. Call it now with all locations found."
            )
            print(f"{RED}{reminder}{RESET}", flush=True)
            messages.append(dict(role="user", content=reminder))
            continue

        for tool_call in tool_calls:
            name = tool_call["function"]["name"]
            args = json.loads(tool_call["function"]["arguments"])
            hash = f"{name}:{json.dumps(args, sort_keys=True)}"

            if hash in seen_calls:
                repeat_count[hash] = repeat_count.get(hash, 1) + 1
                warning = f"You already called {name}({args}) and got results. Do not repeat it. Move on or call `write_report`."
                print(f"{RED}[REPEAT BLOCKED] {name}({args}){RESET}", flush=True)
                messages.append(
                    dict(
                        role="tool",
                        tool_call_id=tool_call["id"],
                        content=warning,
                    )
                )
                continue

            seen_calls.add(hash)
            print(f"{YELLOW}{name}({args}){RESET}", flush=True)

            try:
                result = handle_tool_call(name, args)
            except ToolError as e:
                print(f"{RED}{e}{RESET}", flush=True)
                messages.append(
                    dict(role="tool", tool_call_id=tool_call["id"], content=str(e))
                )
            else:
                if name == "write_report":
                    return result
                messages.append(
                    dict(role="tool", tool_call_id=tool_call["id"], content=result)
                )


if __name__ == "__main__":
    prompt = " ".join(sys.argv[1:])
    result = run(prompt)

    with open("/tmp/qf.txt", "w") as f:
        f.write(result)
        print(f"{YELLOW}Wrote quickfix list to /tmp/qf.txt{RESET}")
