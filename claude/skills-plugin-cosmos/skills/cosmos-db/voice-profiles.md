# Voice identity queries

A worker points at one `realtime_profiles` row (a pipeline plus a voice)
through `workers_settings.realtime_profile_id`. Until the legacy pair is
dropped, the resolver only uses a profile that agrees with
`tts_provider` + `voice_id`. Swap `service=local` for `service=beta`
freely.

Each worker: legacy pair next to its profile, and whether they agree.

```sh
psql service=local -c "
  select a.name as worker, w.tts_provider, w.voice_id,
         p.name as profile_pipeline,
         coalesce(v.provider_voice_id, '(pipeline voice)') as profile_voice,
         case when rp.worker_id is not null then 'own'
              when rp.org_id is not null then 'org'
              else 'shared' end as scope,
         (coalesce(nullif(btrim(w.tts_provider), ''), 'default'),
          w.voice_id)
           is not distinct from (p.name, v.provider_voice_id)
           as agrees
  from workers_settings w
  join accounts a on a.id = w.worker_id
  left join realtime_profiles rp on rp.id = w.realtime_profile_id
  left join realtime_pipelines p on p.id = rp.pipeline_id
  left join voices v on v.id = rp.voice_id
  order by agrees, worker;"
```

Live watch while changing voices in the UI.

```sh
while true; do clear; date +%T; psql service=local -c "
  select a.name, w.tts_provider, w.voice_id, p.name as pipeline,
         v.provider_voice_id as profile_voice,
         (coalesce(nullif(btrim(w.tts_provider), ''), 'default'),
          w.voice_id)
           is not distinct from (p.name, v.provider_voice_id) as agrees,
         w.updated_at
  from workers_settings w
  join accounts a on a.id = w.worker_id
  left join realtime_profiles rp on rp.id = w.realtime_profile_id
  left join realtime_pipelines p on p.id = rp.pipeline_id
  left join voices v on v.id = rp.voice_id
  order by w.updated_at desc nulls last;"; sleep 2; done
```

Links that disagree with the legacy pair (inline specs excluded).

```sh
psql service=beta -c "
  select w.worker_id, w.tts_provider, w.voice_id,
         p.name as pipeline, v.provider_voice_id as profile_voice
  from workers_settings w
  join realtime_profiles rp on rp.id = w.realtime_profile_id
  join realtime_pipelines p on p.id = rp.pipeline_id
  left join voices v on v.id = rp.voice_id
  where (coalesce(nullif(btrim(w.tts_provider), ''), 'default'),
         w.voice_id)
        is distinct from (p.name, v.provider_voice_id)
    and coalesce(w.tts_provider, '') not like '{%';"
```

Own profiles and recent profile changes.

```sh
psql service=local -c "
  select rp.id, p.name as pipeline, v.label, v.kind, rp.org_id,
         rp.worker_id, rp.label as test_label, rp.updated_at
  from realtime_profiles rp
  join realtime_pipelines p on p.id = rp.pipeline_id
  left join voices v on v.id = rp.voice_id
  where rp.updated_at > now() - interval '1 hour'
     or rp.worker_id is not null
  order by rp.updated_at desc;"
```

Workers per profile.

```sh
psql service=beta -c "
  select p.name as pipeline, v.label as voice, v.provider_voice_id,
         count(w.worker_id) as workers
  from realtime_profiles rp
  join realtime_pipelines p on p.id = rp.pipeline_id
  left join voices v on v.id = rp.voice_id
  left join workers_settings w on w.realtime_profile_id = rp.id
  group by 1, 2, 3
  having count(w.worker_id) > 0
  order by workers desc, 1, 2;"
```

Pipelines, one line each.

```sh
psql service=beta -c "
  select name, production, spec->'llm'->>'engine' as engine,
         spec->'llm'->>'model' as llm, spec->'stt'->>'provider' as stt,
         spec->'tts'->>'provider' as tts, spec->'tts'->>'model' as tts_model
  from realtime_pipelines order by production desc, name;"
```

Totals.

```sh
psql service=local -Atc "
  select 'profiles shared/own/org',
         count(*) filter (where org_id is null and worker_id is null),
         count(*) filter (where worker_id is not null),
         count(*) filter (where org_id is not null and worker_id is null)
  from realtime_profiles;
  select 'workers linked', count(*), count(realtime_profile_id), null
  from workers_settings;"
```

Backfill (dry run by default, `-v apply=1` commits; a write, so it needs
the user's go-ahead):

```sh
cd apps/web
psql service=beta -f scripts/backfill-realtime-profile-id.sql
```
