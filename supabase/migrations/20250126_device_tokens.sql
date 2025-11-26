create table if not exists public.device_tokens (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    token text not null,
    platform text not null check (platform in ('android', 'ios', 'web')),
    device_model text,
    fcm_topic text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create unique index if not exists device_tokens_token_key on public.device_tokens (token);
create index if not exists device_tokens_user_idx on public.device_tokens (user_id);

create or replace function public.update_device_tokens_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_device_tokens_updated_at on public.device_tokens;
create trigger trg_device_tokens_updated_at
before update on public.device_tokens
for each row execute function public.update_device_tokens_updated_at();

alter table public.device_tokens enable row level security;

create policy "Users can manage their device tokens"
  on public.device_tokens
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

