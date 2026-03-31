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
You are a fast, highly efficient codebase explorer and search expert. Use your tools to investigate the codebase based on the user's request. 

<rules>
  <rule>Be extremely fast. Minimize tool usage by choosing the most direct path to the answer.</rule>
  <rule>Unless the user specifies a particular file, start with a broad `grep_search` (including README, package.json, pyproject.toml, etc.) to understand project structure.</rule>
  <rule>If a search returns too many results, refine your query rather than reading through massive logs.</rule>
  <rule>Prefer `grep_search` for navigation. Only read full files when you have narrowed down the exact location(s).</rule>
  <rule>Never search for the exact same term twice. Always adjust your strategy and move forward.</rule>
  <rule>Be precise with line numbers—they must match the actual code exactly.</rule>
  <rule>If you cannot find exactly what was asked, identify the closest relevant locations with clear descriptions and immediately finish.</rule>
  <rule>Do not summarize, explain, or chat. Execute your searches silently.</rule>
</rules>

<output>
  CRITICAL: When your exploration is complete, you must trigger the `write_report` tool immediately. 

  DO NOT output any conversational text. 
  DO NOT summarize your findings in the chat. 
  DO NOT explain how the code works. 

  If your final response contains standard text instead of a direct tool call, you have failed the instructions. Respond ONLY with the `write_report` tool containing ALL discovered locations.
</output>
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
                "required": ["pattern", "limit"],
                "properties": {
                    "pattern": {
                        "type": "string",
                        "description": "Pattern to search for in the current project and directory only.",
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Controls how many results to show.",
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


def grep_search(query: str, limit: int = 10) -> str:
    if len(query) == 0:
        raise ToolError("`query` is required and cannot be empty")

    results = set()

    fd_result = subprocess.run(["fd", query, *FD_ARGS], capture_output=True, text=True)
    if fd_result.stdout:
        for line in fd_result.stdout.splitlines():
            results.add(line)

    rg_result = subprocess.run(["rg", query, *RG_ARGS], capture_output=True, text=True)
    if rg_result.stdout:
        for line in rg_result.stdout.splitlines():
            results.add(line)

    final_list = sorted(list(results))[:limit]

    if not final_list:
        return f"No matches found for '{query}' in paths or content."

    return "\n".join(final_list)


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
            return grep_search(args["pattern"], args["limit"])
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
        temperature=1.0,
        top_p=0.95,
        top_k=20,
        min_p=0.0,
        presence_penalty=1.5,
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
    messages: list[dict[str, Any]] = [
        dict(role="system", content=SYSTEM_PROMPT),
        dict(role="user", content=user_prompt),
    ]

    while True:
        choice = stream_complete(messages)
        message = choice["message"]
        messages.append(message)

        tool_calls = message.get("tool_calls", [])

        if choice["finish_reason"] == "stop" and len(tool_calls) == 0:
            reminder = "You did not call `write_report` tool. Provide all the locations that you know of, that are relevant to the initial request."
            print(f"{RED}{reminder}{RESET}", flush=True)
            messages.append(dict(role="user", content=reminder))
        else:
            for tool_call in tool_calls:
                name = tool_call["function"]["name"]
                args = json.loads(tool_call["function"]["arguments"])

                print(f"{YELLOW}{name}({args}){RESET}", flush=True)

                try:
                    result = handle_tool_call(name, args)
                except ToolError as e:
                    print(f"{RED}{e}{RESET}", flush=True)
                    messages.append(
                        dict(
                            role="tool",
                            tool_call_id=tool_call["id"],
                            content=str(e),
                        )
                    )
                else:
                    if name == "write_report":
                        with open("/tmp/qf.txt", "w") as f:
                            f.write(result)
                        print(f"{YELLOW}Wrote quickfix list to /tmp/qf.txt{RESET}")
                        return result

                    messages.append(
                        dict(role="tool", tool_call_id=tool_call["id"], content=result)
                    )


if __name__ == "__main__":
    prompt = " ".join(sys.argv[1:])
    run(prompt)
