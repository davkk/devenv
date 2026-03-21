#!/usr/bin/env python

import json
import os
import subprocess
import sys
import urllib.request
from typing import Any

RESET = "\033[0m"
DIM = "\033[2m"
YELLOW = "\033[33m"
RED = "\033[31m"

MODEL = "Qwen3.5-2B-Q8_0"
API_URL = "http://localhost:8012/v1/chat/completions"
SYSTEM_PROMPT = """
You are a quick working expert codebase explorer and search expert without any bullshit.

<Rule>Use your tools to investigate the code based on the user's request.
<Rule>Always generate multiple tool calls at once, never only one.
<Rule>Be quick with your actions, try to search for exact thing the user wants to find.
<Rule>Preferably, navigate around codebase with grep_search tools first, before reading or listing files for more narrow approach.
<Rule>Be precise when writing line numbers as they need to match the actual line the code is at.
<Rule>Always finish your reporting with the report_findings tool, with ALL the locations of what you have found in your analysis as entries.
<Rule>Do not write any summaries, just go straight to executing report_findings tool once you are done searching.
"""
TOOLS = [
    # {
    #     "type": "function",
    #     "function": {
    #         "name": "list_files",
    #         "description": "List all files in a directory",
    #         "parameters": {
    #             "type": "object",
    #             "properties": {
    #                 "path": {
    #                     "type": "string",
    #                     "description": "Relative path to directory. Defaults to project root if not provided.",
    #                 }
    #             },
    #         },
    #     },
    # },
    {
        "type": "function",
        "function": {
            "name": "read_file",
            "description": "Read a file by path, start line number and line count. Useful if you already know the line number of search from eg. grep_search, but want a bit more context.",
            "parameters": {
                "type": "object",
                "required": ["path", "start_line_number", "line_count"],
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path relative to project root, no leading slash.",
                    },
                    "start_line_number": {
                        "type": "integer",
                        "description": "Start line number to read from.",
                    },
                    "line_count": {
                        "type": "integer",
                        "description": "Number of lines to read.",
                    },
                },
            },
        },
    },
    # {
    #     "type": "function",
    #     "function": {
    #         "name": "find_file",
    #         "description": "Find a files by pattern",
    #         "parameters": {
    #             "type": "object",
    #             "required": ["path"],
    #             "properties": {
    #                 "pattern": {
    #                     "type": "string",
    #                     "description": "Pattern to search for in file names in the entire project.",
    #                 },
    #             },
    #         },
    #     },
    # },
    {
        "type": "function",
        "function": {
            "name": "grep_search",
            "description": "Search for a pattern in current project. This will give you all occurences of the pattern in the current project in all the file names and their content.",
            "parameters": {
                "type": "object",
                "required": ["pattern"],
                "properties": {
                    "pattern": {
                        "type": "string",
                        "description": "Pattern to search for.",
                    }
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "report_findings",
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


class ToolError(Exception):
    pass


def list_files(path: str = ".") -> str:
    try:
        clean_path = path.lstrip("/").replace("./", "")
        return str(os.listdir(clean_path))
    except FileNotFoundError:
        raise ToolError(f"Error: Directory '{path}' not found")
    except NotADirectoryError:
        raise ToolError(f"Error: '{path}' is not a directory")


def find_file(pattern: str) -> str:
    proc = subprocess.Popen(
        [
            "fd",
            pattern,
            "--hidden",
            "--follow",
            "--exclude",
            ".git",
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    stdout, stderr = proc.communicate()
    if proc.returncode and proc.returncode > 0:
        raise ToolError(stderr.decode("utf-8"))
    return stdout.decode("utf-8") if stdout else "find_file: No results"


def read_file(path: str, start_line_number: int, line_count: int) -> str:
    proc = subprocess.Popen(
        [
            "awk",
            f'NR>={start_line_number} && NR<={start_line_number + line_count} {{print NR": "$0}}',
            path.replace("^/", ""),
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    stdout, stderr = proc.communicate()
    if proc.returncode and proc.returncode > 0:
        raise ToolError(stderr.decode("utf-8"))
    return stdout.decode("utf-8") if stdout else "No results found."


def grep_search(query: str, limit: int = 10) -> str:
    results = set()

    try:
        fd_cmd = [
            "fd",
            query,
            "--type=f",
            "--hidden",
            "--exclude=.git",
        ]
        fd_proc = subprocess.run(fd_cmd, capture_output=True, text=True)
        if fd_proc.stdout:
            for line in fd_proc.stdout.splitlines():
                results.add(f"{line}:1:0:")

    except FileNotFoundError:
        pass

    rg_cmd = [
        "rg",
        query,
        "--vimgrep",
        "--line-number",
        "--column",
        "--no-heading",
        "--smart-case",
        "--hidden",
        "--glob=!.git",
    ]

    rg_proc = subprocess.run(rg_cmd, capture_output=True, text=True)
    if rg_proc.stdout:
        for line in rg_proc.stdout.splitlines():
            results.add(line)

    final_list = sorted(list(results))[:limit]

    if not final_list:
        return f"No matches found for '{query}' in paths or content."

    return "\n".join(final_list)


def report_findings(entries: list[dict]) -> str:
    quickfix = []
    for entry in entries:
        filepath = entry.get("filepath")
        if not filepath or not os.path.exists(filepath):
            raise ToolError(f"Filepath {filepath} does not exist")
        quickfix.append(
            f"{entry.get('filepath')}:{entry.get('line')}:0:{entry.get('short_description')}"
        )
    return "\n".join(quickfix)


def handle_tool_call(name: str, args: dict[str, Any]) -> str:
    match name:
        case "list_files":
            return list_files(args.get("path", "."))
        case "find_file":
            return find_file(args["pattern"])
        case "read_file":
            return read_file(
                args["path"],
                args["start_line_number"],
                args["line_count"],
            )
        case "grep_search":
            return grep_search(args["pattern"])
        case "report_findings":
            return report_findings(args["entries"])
        case _:
            return f"Unknown tool: {name}"


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
                    tool_calls[idx] = {
                        "id": tc_delta.get("id", ""),
                        "type": "function",
                        "function": {"name": "", "arguments": ""},
                    }
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

        if choice["finish_reason"] == "stop":
            messages.append(
                {
                    "role": "user",
                    "content": "You did not call report_findings. Use your tools and provide a report with results of your whole analysis.",
                }
            )
            continue

        for tool_call in message.get("tool_calls", []):
            name = tool_call["function"]["name"]
            args = json.loads(tool_call["function"]["arguments"])

            print(f"{YELLOW}{name}({args}){RESET}", flush=True)

            try:
                result = handle_tool_call(name, args)
            except ToolError as e:
                print(f"{RED}{e}{RESET}", flush=True)
                messages.append(
                    {
                        "role": "tool",
                        "tool_call_id": tool_call["id"],
                        "content": str(e),
                    }
                )
            else:
                if name == "report_findings":
                    with open("/tmp/qf.txt", "w") as f:
                        f.write(result)
                    print(f"{YELLOW}Wrote quickfix list to /tmp/qf.txt{RESET}")
                    return result

                messages.append(
                    {
                        "role": "tool",
                        "tool_call_id": tool_call["id"],
                        "content": result,
                    }
                )


if __name__ == "__main__":
    prompt = " ".join(sys.argv[1:])
    run(prompt)
