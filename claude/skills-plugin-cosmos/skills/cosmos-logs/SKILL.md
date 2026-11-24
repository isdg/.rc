---
name: cosmos-logs
description: Use when checking logs, pods, fleets or metrics of a
  cosmos-saas deployment (local, beta/preprod, prod, us, ae, bouygues,
  Attendee meeting bots) — "check logs", "check loki", "why does the
  worker not speak", "check the phone pod", latency or error hunts.
---

# Cosmos logs, pods and metrics

History lives in Loki, Attendee's in Google Cloud Logging; `kubectl
logs` only reaches back to the last redeploy or log rotation (many per
day on beta, minutes to ~30 min of backend logs on prod). Start with
`logcli` or `gcloud logging read`, fall back to `kubectl`. All of it is
read-only.

## Where each environment's logs are

| env      | Loki (`LOKI_ADDR`, needs WARP) | namespaces in Loki            | kube context |
| -------- | ------------------------------ | ----------------------------- | ------------ |
| local    | `http://127.0.0.1:3100`        | fleet log file via Alloy      | none |
| beta     | `http://172.16.4.25:3100`      | all (`cosmos`, `realtime`, …) | `admin@scw-eu-preprod` |
| prod     | `http://172.16.16.25:3100`     | `realtime` only               | `admin@scw-eu-prod` |
| Attendee | none: Cloud Logging, project `delos-recap` | `attendee`, `attendee-preprod` | `viewer@gcp-eu-attendee` |
| us / ae / bouygues | none: no log shipper | — | `admin@az-<name>-prod` |

- Attendee moved to GKE (`recap`, europe-west9) on 2026-11-24; prod
  Loki keeps its `attendee*` history only until 02:00 UTC that day.

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
  '{namespace="realtime", app="external-video-worker"} | pod="…"'
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
  `realtime-session-eval`, `room-observer`; beta also `backend`,
  `frontend`, …
- Send large results to a scratchpad file and `rg` it; don't page
  thousands of lines through the conversation.

## Attendee: Cloud Logging

```sh
gcloud logging read --project delos-recap --order asc --limit 3000 \
  --format='value(timestamp,textPayload)' \
  'resource.type="k8s_container"
   resource.labels.namespace_name="attendee"
   resource.labels.pod_name:"bot-<bot id, lowercased>"
   timestamp>="2026-11-24T13:29:00Z" timestamp<="2026-11-24T13:40:00Z"'
```

- A bot's pod is `bot-pod-<n>-bot-<bot id lowercased>`, so the bot id
  finds it; `web`, `worker` and `worker-webhooks` are the Django side.
- Messages are in `textPayload`; filter by `timestamp` or
  `--freshness 2h`. History is ~30 days.
- Needs `roles/logging.viewer` on `delos-recap` (`container.viewer`
  for kubectl); a `PERMISSION_DENIED` means the grant is missing.
- The lifecycle reads in order: `Trying to join meeting`, `Google is
  blocking us` (meeting not started, pod restarts),
  `BOT_PUT_IN_WAITING_ROOM`, `Successfully joined meeting`, `Received
  message that meeting ended`.

## kubectl

Always pass `--context`; the current context can be any cluster.

```sh
kubectl --context admin@scw-eu-prod -n realtime get pods -o wide
kubectl --context admin@scw-eu-prod -n cosmos logs deploy/backend \
  --since 30m | rg -n '<id>'
kubectl --context admin@scw-eu-prod -n realtime logs <pod> --previous
kubectl --context viewer@gcp-eu-attendee -n attendee top pod
```

- No `exec`, `delete`, `scale`, `rollout`, `apply` or `helm upgrade`
  without the user's go-ahead; hand those over as commands. The prod
  Scaleway and GKE identities are read-only anyway.
- `viewer@gcp-eu-attendee` authenticates through
  `gke-gcloud-auth-plugin`, put on PATH by the Google Cloud SDK's
  `path.zsh.inc` (`~/.zshrc.local`).
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
  such line → it was created silent: the worker's meeting voice toggle
  (`workers_settings.meeting_voice_enabled`), a missing event id, or no
  free room. Not a fleet problem.
- **Voiced bot, no voice in the room:** the bot logs `Timed out waiting
  for LiveKit tracks: audio. Present: none` → no `external-video-worker`
  job joined. Check the bot's `worker_realtime_sessions` row (kind
  `meeting`, `recap_bot_id`): `failed` within a second of `started_at`
  means the backend's dispatch was refused.
- **Idle Gemini Live in a meeting lobby** drops with 1008 about every
  2.5 min of silence; the fourth drop closes the voice.
- **A session that never appears in `realtime` logs** was never
  dispatched: look at the backend (dispatch) or Attendee side first.

## Reporting

Give the environment, the time window in UTC, the exact query, then
the finding with two or three quoted lines. State what the logs could
not show (prod backend history, Azure regions) rather than guessing.
