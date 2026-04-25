# Dialyzer ignore patterns for known false positives.
# Mix task modules depend on the Mix application which is only available at
# build time. The :mix app is added to the PLT, but some callback metadata
# (Mix.Task behaviour) is not always resolvable — suppress those here.
[
  ~r/lib\/mix\/tasks\/.+\.ex:\d+:callback_info_missing/
]
