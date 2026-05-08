# Task Spec: Current Menu Bar Action Parity

- Why now: the primary Current Menu Bar Icon panel is the first place users see pinned-icon recovery, but it had hand-rolled recovery and default buttons while the icon/settings strips already use shared helpers.
- Scope: update `apps/skillbar/SkillBarApp/Sources/Views/MenuBarView.swift` only; keep install/update wiring, catalog parsing, and pack behavior unchanged.
- Product rule: keep the direct Browse Icons action visible, make stale pinned-icon recovery use the same prominent/default/help behavior everywhere, and avoid adding another hidden gesture or modal.
- Verification: run SkillBar typecheck plus catalog/audit checks after the UI cleanup.
