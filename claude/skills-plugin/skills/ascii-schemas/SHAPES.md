# Shapes

One small example per shape. Real ones carry real names: functions,
`file:line`, routes, keys, pods.

## Containment: where does it run

Nest boxes by machine, cluster, namespace, pod, process. Label the edge
with the protocol and say what works today.

```
┌─ PREPROD CLUSTER ──────────────────────────────────────┐
│  ns realtime              ns monitoring                │
│  ┌──────────────┐ scrape  ┌─────────────────────────┐  │
│  │ live-worker  │◄────────┤ prometheus-0            │  │
│  │ /metrics     │         │ configured by: helm     │  │
│  └──────────────┘         └────────────┬────────────┘  │
└────────────────────────────────────────┼───────────────┘
                                         │ remote write
                                         │ today: FAIL (refused)
┌─ MONITORING VM 172.16.4.25 ────────────▼───────────────┐
│  Prometheus :9090   refuses pushes until a flag is     │
│                     set in /etc/default/prometheus     │
│  Grafana  reads Prometheus + Loki                      │
└────────────────────────────────────────────────────────┘
```

## Call path: one request through the code

Start where the user would: the tool call, route or cron. Number the
steps; say where control returns.

```
LLM calls manage_meeting(action="join")       tools/meeting.py:59
▼
join_meeting_as_worker                        worker_join.py:179
│ 1. find_worker_bot: already present? → stop
│ 2. INSERT app_recap_events → event_id
│ 3. bot_join_meeting ─────────────────┐
│                                      ▼
│                   bot_join_meeting   create_bot.py:240
│                   │ 4. pick transport          (R1)
│                   │ 5. POST /bots → 201 bot_id
│                   ◄─ (bot_id, state)
│ 6. INSERT app_recap_bot                        (R3)
│ 7. tool returns: nobody has joined yet
▼
```

## Swimlanes: order across processes

One column per process, time flows down, every arrow labelled.

```
 worker job              API pod                  Attendee bot
 ──────────              ───────                  ────────────
 POST /bots ───────────► create bot
                         ◄── 201 bot_id
                                                  boots, joins
                         ◄══ WS /meeting_audio ═══ (per-participant
                         verify token               audio)
 TTS audio ════════════► bot_output ════════════► plays into mic
```

Legend under it when arrow styles differ: `──►` call, `══►` stream.

## Decision: what decides

First match wins, top to bottom.

```
 condition                              outcome
 ─────────────────────────────────────  ─────────────────────
 run in flight                       →  inject at next tool
 waiting / queued, claim won         →  run_worker(message)
 waiting / queued, claim lost        →  re-read, then inject
 terminal / awaiting_input / paused  →  skip
```

## Before / after: what a change does

Same layout twice so the eye diffs it. Mark `[new]`, `[gone]`,
`◄ still heavy`.

```
BEFORE                                  AFTER #13734
job                                     job
└─ context_session                      └─ context_session
   ├─ unified.context  +300 MB             ├─ realtime_state  [new]  light
   │   └─ every module's tools             ├─ realtime_prompt [new]  light
   └─ unified.factory                      └─ unified.factory  ◄ still heavy
```

## Frames: how state evolves

Repeat one layout per step; only the changed cells move.

```
step 2   thread: MAIN paused → back in the loop
         QUEUE:  [ CHILD ]
         ┌─ CHILD ───────────────────┐
         │ future: async { 42 }      │
         │ result: (empty)           │
         │ waiter: MAIN  ◄ new       │
         └───────────────────────────┘
```

## Stack: layering

Top is closest to the user, bottom is hardware.

```
┌──────────────────────────────────────────┐
│ docker CLI → context picks the socket    │
├──────────────────────────────────────────┤
│ Colima Linux VM: dockerd → containerd    │
├──────────────────────────────────────────┤
│ Virtualization.framework                 │
├──────────────────────────────────────────┤
│ macOS kernel (XNU), Apple Silicon        │
└──────────────────────────────────────────┘
```

## Timeline: where the time goes

```
t=0.0  request ends
t=1.4  lead-in finishes      (waits by design)
t=3.1  streamer page loaded  (driver.get, 1.7 s)
t=4.9  Meet reports share    (Present click, 1.75 s)
```
