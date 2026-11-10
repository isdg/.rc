---
name: cosmos-logs
description: Use when checking logs, pods, fleets or metrics of a
  cosmos-saas deployment (local, beta/preprod, prod, us, ae, bouygues,
  Attendee meeting bots) — "check logs", "check loki", "why does the
  worker not speak", "check the phone pod", latency or error hunts.
---

# Cosmos logs, pods and metrics

History lives in Loki; `kubectl logs` only reaches back to the last
redeploy (many per day on beta, ~30 min of backend logs on prod). Start
with `logcli`, fall back to `kubectl`. All of it is read-only.

## Where each environment's logs are

| env      | Loki (`LOKI_ADDR`, needs WARP) | namespaces in Loki            | kube context |
| -------- | ------------------------------ | ----------------------------- | ------------ |
| local    | `http://127.0.0.1:3100`        | fleet log file via Alloy      | none |
| beta     | `http://172.16.4.25:3100`      | all (`cosmos`, `realtime`, …) | `admin@scw-eu-preprod` |
| prod     | `http://172.16.16.25:3100`     | `realtime`, `attendee`, `attendee-preprod` only | `admin@scw-eu-prod` |
| Attendee | prod Loki, above               | `attendee` (prod bots), `attendee-preprod` | `admin@recap-delos` |
| us / ae / bouygues | none: no log shipper | — | `admin@az-<name>-prod` |

- The shell default `LOKI_ADDR` is beta. Set it per command for
  anything else; never assume.
- **Prod backend (`cosmos` namespace) is not in Loki**: `kubectl logs`
  right away, before the pod rotates.
- In prod Loki, `service_name="realtime"` is Supabase Realtime. The
  fleets are `namespace="realtime"`.
- Prometheus sits on the same VMs at `:9090` (`promtool query instant
  http://<vm>:9090 '<promql>'`), series labelled
  `cluster="cosmos-preprod"` / `"cosmos-prod"`.

## logcli

```sh
export LOKI_ADDR=http://172.16.16.25:3100            # prod
logcli labels app --since 1h -q                      # what exists
logcli query --since 2h --limit 500 -q -o raw \
  '{namespace="realtime", app="phone-worker"} !~ "\"audio\": " |= "<id>"'
logcli query --from 2026-11-03T09:00:00Z --to 2026-11-03T09:30:00Z \
  --limit 2000 -q -o raw --forward \
  '{namespace="attendee", app="bot-proc"} | pod="bot-pod-…"'
```

- **Always add `!~ "\"audio\": "`** on realtime fleets: ElevenLabs
  debug lines carry base64 audio and make queries time out.
- **Drop the noise early:** `!= "ddtrace"` and `| json | level!="DEBUG"`;
  workers log JSON, the backend logs rich-wrapped multi-line text.
- **Filter a pod with a pipeline stage** (`| pod="…"`), not in the
  stream selector: on prod the selector form returns nothing.
- **Follow one session by id** (`session_id`, room name
  `phone-worker-_<session_id>`, bot id) across apps with
  `{namespace="realtime"} |= "<id>"`; `summary:` lines give the
  per-session totals.
- `app` values: fleets `live-worker`, `phone-worker`, `voice-worker`,
  `video-worker`, `external-video-worker`; jobs `realtime-session-proc`,
  `realtime-session-eval`, `room-observer`; Attendee `bot-proc`,
  `web-proc`, `worker-proc`; beta also `backend`, `frontend`, …
- Send large results to a scratchpad file and `rg` it; don't page
  thousands of lines through the conversation.

## kubectl

Always pass `--context`; the current context can be any cluster.

```sh
kubectl --context admin@scw-eu-prod -n realtime get pods -o wide
kubectl --context admin@scw-eu-prod -n cosmos logs deploy/backend \
  --since 30m | rg -n '<id>'
kubectl --context admin@scw-eu-prod -n realtime logs <pod> --previous
kubectl --context admin@recap-delos -n attendee top pod
```

- No `exec`, `delete`, `scale`, `rollout`, `apply` or `helm upgrade`
  without the user's go-ahead; hand those over as commands. The prod
  Scaleway identity is read-only anyway.
- Restarts and OOMs: `describe pod` (last state, events) before logs.

## Local

- Runtime is tmux `cosmos-main-runtime`: windows db, attendee, backend
  (:8000), fleet, web. Read a window with `tmux capture-pane -p -S
  -2000 -t cosmos-main-runtime:<window>`.
- Monitoring is tmux `cosmos-main-monitoring-runtime`: Loki :3100,
  Prometheus :9090, Grafana :3001. The fleet log is
  `~/cosmos-main-monitoring/logs/fleet.log`.
- Before restarting a fleet, check
  `lk_agents_active_job_count == 0`: a restart cuts live calls.

## Known answers, check these first

- **Meeting worker silent:** a voiced bot logs `room sync client`. No
  such line → it was created silent: the worker's meeting voice toggle,
  the `worker-meeting-voice` org flag, a missing event id, or no free
  room. Not a fleet problem.
- **Idle Gemini Live in a meeting lobby** drops with 1008 about every
  2.5 min of silence; the fourth drop closes the voice.
- **A session that never appears in `realtime` logs** was never
  dispatched: look at the backend (dispatch) or Attendee side first.

## Reporting

Give the environment, the time window in UTC, the exact query, then
the finding with two or three quoted lines. State what the logs could
not show (prod backend history, Azure regions) rather than guessing.
