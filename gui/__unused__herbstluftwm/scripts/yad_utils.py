from typing import List, Optional
import subprocess


def ask_text(
    text: Optional[str] = None,
    text_align: str = "center",
    input_label: Optional[str] = None,
    prefill_text: Optional[str] = None,
    extra_args: List[str] = [],
) -> str:
    cmd = [
        "yad",
        "--on-top",
        "--center",
        "--close-on-unfocus",
        "--entry",
    ]
    if text:
        cmd += ["--text-align", text_align, "--text", text]
    if input_label:
        cmd += ["--entry-label", input_label]
    if prefill_text:
        cmd += ["--entry-text", prefill_text]
    if extra_args:
        cmd += extra_args
    proc = subprocess.run(
        args=cmd,
        capture_output=True,
        encoding="utf-8",
    )
    return proc.stdout.strip("\n")
