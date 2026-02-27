create extension if not exists pgcrypto;

-- Enums de dominio
do $$
begin
  if not exists (select 1 from pg_type where typname = 'session_phase') then
    create type session_phase as enum ('waiting', 'private', 'collaborative', 'finished');
  end if;

  if not exists (select 1 from pg_type where typname = 'postit_category') then
    create type postit_category as enum ('keep', 'improve', 'ideas', 'stop');
  end if;
end;
$$;

-- Sesiones
create table if not exists retro_sessions (
  id uuid primary key default gen_random_uuid(),
  code varchar(6) not null unique,
  moderator_id uuid not null references auth.users (id) on delete restrict,
  phase session_phase not null default 'waiting',
  created_at timestamptz not null default now()
);

-- Participantes
create table if not exists session_users (
  id uuid not null references auth.users (id) on delete cascade,
  session_id uuid not null references retro_sessions (id) on delete cascade,
  user_name text not null check (char_length(trim(user_name)) > 0),
  is_completed boolean not null default false,
  is_moderator boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (id, session_id)
);

-- Post-its
create table if not exists postits (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references retro_sessions (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  user_name text not null check (char_length(trim(user_name)) > 0),
  category postit_category not null,
  text text not null check (char_length(trim(text)) > 0),
  position_x integer not null default 0,
  position_y integer not null default 0,
  group_id uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Índices mínimos para consultas por sesión
create index if not exists idx_session_users_session_id on session_users (session_id);
create index if not exists idx_postits_session_id on postits (session_id);
create index if not exists idx_postits_user_id on postits (user_id);
create index if not exists idx_retro_sessions_code on retro_sessions (code);

-- Trigger updated_at para postits
create or replace function set_postits_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_postits_set_updated_at on postits;
create trigger trg_postits_set_updated_at
before update on postits
for each row
execute function set_postits_updated_at();

-- Helpers para políticas RLS
create or replace function is_session_participant(target_session_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from session_users su
    where su.session_id = target_session_id
      and su.id = auth.uid()
  );
$$;

create or replace function is_session_moderator(target_session_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from retro_sessions rs
    where rs.id = target_session_id
      and rs.moderator_id = auth.uid()
  );
$$;

-- RLS
alter table retro_sessions enable row level security;
alter table session_users enable row level security;
alter table postits enable row level security;

-- Retro sessions: visibles para participantes, administrables por moderador
drop policy if exists "retro_sessions_select_participants" on retro_sessions;
create policy "retro_sessions_select_participants"
on retro_sessions
for select
using (is_session_participant(id));

drop policy if exists "retro_sessions_insert_moderator" on retro_sessions;
create policy "retro_sessions_insert_moderator"
on retro_sessions
for insert
to authenticated
with check (moderator_id = auth.uid());

drop policy if exists "retro_sessions_update_moderator" on retro_sessions;
create policy "retro_sessions_update_moderator"
on retro_sessions
for update
to authenticated
using (moderator_id = auth.uid())
with check (moderator_id = auth.uid());

-- Session users: visibles para miembros de la sesión.
drop policy if exists "session_users_select_by_session_participants" on session_users;
create policy "session_users_select_by_session_participants"
on session_users
for select
using (is_session_participant(session_id));

drop policy if exists "session_users_insert_self_or_moderator" on session_users;
create policy "session_users_insert_self_or_moderator"
on session_users
for insert
to authenticated
with check (
  id = auth.uid()
  or is_session_moderator(session_id)
);

drop policy if exists "session_users_update_self_or_moderator" on session_users;
create policy "session_users_update_self_or_moderator"
on session_users
for update
to authenticated
using (id = auth.uid() or is_session_moderator(session_id))
with check (id = auth.uid() or is_session_moderator(session_id));

-- Post-its:
-- - En private: solo el creador puede leerlos.
-- - En collaborative: cualquier participante de la sesión puede leerlos.
drop policy if exists "postits_select_private_or_collaborative" on postits;
create policy "postits_select_private_or_collaborative"
on postits
for select
using (
  is_session_participant(session_id)
  and (
    user_id = auth.uid()
    or exists (
      select 1
      from retro_sessions rs
      where rs.id = postits.session_id
        and rs.phase = 'collaborative'
    )
  )
);

drop policy if exists "postits_insert_owner_participant" on postits;
create policy "postits_insert_owner_participant"
on postits
for insert
to authenticated
with check (
  user_id = auth.uid()
  and is_session_participant(session_id)
);

drop policy if exists "postits_update_owner_or_moderator" on postits;
create policy "postits_update_owner_or_moderator"
on postits
for update
to authenticated
using (user_id = auth.uid() or is_session_moderator(session_id))
with check (user_id = auth.uid() or is_session_moderator(session_id));

drop policy if exists "postits_delete_owner_or_moderator" on postits;
create policy "postits_delete_owner_or_moderator"
on postits
for delete
to authenticated
using (user_id = auth.uid() or is_session_moderator(session_id));

-- Realtime: publicar tablas necesarias
-- Nota: supabase_realtime suele existir por defecto en proyectos Supabase.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'retro_sessions'
  ) then
    execute 'alter publication supabase_realtime add table public.retro_sessions';
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'session_users'
  ) then
    execute 'alter publication supabase_realtime add table public.session_users';
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'postits'
  ) then
    execute 'alter publication supabase_realtime add table public.postits';
  end if;
end;
$$;
