# Interaction rule

At the end of every assistant turn, call `ask_user` exactly once.

Requirements for `ask_user`:
- Provide 2-4 concrete options.
- Also allow free-text input.
- The question must be directly about the current task.
- Do not end the turn with plain text if `ask_user` is available.

If `ask_user` is unavailable, explicitly say: "ask_user unavailable in this session".
