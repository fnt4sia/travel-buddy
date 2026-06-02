create extension if not exists pgcrypto;

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    display_name text not null,
    avatar_url text,
    country text,
    age integer check (age is null or age >= 13),
    interests text[] not null default '{}',
    languages text[] not null default '{}',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.meetup_rooms (
    id uuid primary key default gen_random_uuid(),
    place_id text,
    place_name text not null,
    address text not null,
    meetup_date date not null,
    starts_at time,
    ends_at time,
    timezone text not null default 'Asia/Makassar',
    price_amount integer not null default 0 check (price_amount >= 0),
    price_currency text not null default 'IDR',
    max_capacity integer not null check (max_capacity between 2 and 20),
    created_by uuid not null references public.profiles(id) on delete cascade,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.room_members (
    room_id uuid not null references public.meetup_rooms(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    role text not null default 'member' check (role in ('host', 'member')),
    joined_at timestamptz not null default now(),
    primary key (room_id, user_id)
);

create table if not exists public.room_messages (
    id uuid primary key default gen_random_uuid(),
    room_id uuid not null references public.meetup_rooms(id) on delete cascade,
    sender_id uuid not null references public.profiles(id) on delete cascade,
    body text not null check (length(trim(body)) > 0 and length(body) <= 2000),
    created_at timestamptz not null default now()
);

create index if not exists meetup_rooms_date_idx
    on public.meetup_rooms (meetup_date, starts_at);

create index if not exists room_members_user_idx
    on public.room_members (user_id);

create index if not exists room_messages_room_created_idx
    on public.room_messages (room_id, created_at);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();

drop trigger if exists meetup_rooms_touch_updated_at on public.meetup_rooms;
create trigger meetup_rooms_touch_updated_at
before update on public.meetup_rooms
for each row execute function public.touch_updated_at();

create or replace function public.prevent_room_over_capacity()
returns trigger
language plpgsql
as $$
declare
    capacity integer;
    current_members integer;
begin
    select max_capacity
      into capacity
      from public.meetup_rooms
     where id = new.room_id
     for update;

    select count(*)
      into current_members
      from public.room_members
     where room_id = new.room_id;

    if current_members >= capacity then
        raise exception 'meetup room is full';
    end if;

    return new;
end;
$$;

drop trigger if exists room_members_capacity_guard on public.room_members;
create trigger room_members_capacity_guard
before insert on public.room_members
for each row execute function public.prevent_room_over_capacity();

create or replace function public.prevent_duplicate_same_day_place_membership()
returns trigger
language plpgsql
as $$
declare
    has_conflict boolean;
begin
    select exists (
        select 1
          from public.room_members existing_member
          join public.meetup_rooms existing_room
            on existing_room.id = existing_member.room_id
          join public.meetup_rooms candidate_room
            on candidate_room.id = new.room_id
         where existing_member.user_id = new.user_id
           and existing_member.room_id <> new.room_id
           and existing_room.meetup_date = candidate_room.meetup_date
           and (
                (
                    existing_room.place_id is not null
                    and candidate_room.place_id is not null
                    and existing_room.place_id = candidate_room.place_id
                )
                or (
                    lower(trim(existing_room.address))
                        = lower(trim(candidate_room.address))
                )
           )
    ) into has_conflict;

    if has_conflict then
        raise exception 'user is already joined to a meetup at this place on this date';
    end if;

    return new;
end;
$$;

drop trigger if exists room_members_same_day_place_guard on public.room_members;
create trigger room_members_same_day_place_guard
before insert on public.room_members
for each row execute function public.prevent_duplicate_same_day_place_membership();

create or replace function public.add_room_host_membership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.room_members (room_id, user_id, role)
    values (new.id, new.created_by, 'host')
    on conflict (room_id, user_id) do nothing;

    return new;
end;
$$;

drop trigger if exists meetup_rooms_add_host_membership on public.meetup_rooms;
create trigger meetup_rooms_add_host_membership
after insert on public.meetup_rooms
for each row execute function public.add_room_host_membership();

create or replace view public.available_meetup_rooms
with (security_invoker = true)
as
select
    rooms.id,
    rooms.place_id,
    rooms.place_name,
    rooms.address,
    rooms.meetup_date,
    rooms.starts_at,
    rooms.ends_at,
    rooms.timezone,
    rooms.price_amount,
    rooms.price_currency,
    rooms.max_capacity,
    rooms.created_by,
    rooms.created_at,
    count(members.user_id)::integer as member_count,
    (rooms.max_capacity - count(members.user_id))::integer as available_spots
from public.meetup_rooms rooms
left join public.room_members members on members.room_id = rooms.id
group by rooms.id;

alter table public.profiles enable row level security;
alter table public.meetup_rooms enable row level security;
alter table public.room_members enable row level security;
alter table public.room_messages enable row level security;

drop policy if exists "profiles are visible to signed in users" on public.profiles;
create policy "profiles are visible to signed in users"
on public.profiles for select
to authenticated
using (true);

drop policy if exists "users can insert their own profile" on public.profiles;
create policy "users can insert their own profile"
on public.profiles for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "users can update their own profile" on public.profiles;
create policy "users can update their own profile"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "signed in users can view meetup rooms" on public.meetup_rooms;
create policy "signed in users can view meetup rooms"
on public.meetup_rooms for select
to authenticated
using (true);

drop policy if exists "users can create meetup rooms" on public.meetup_rooms;
create policy "users can create meetup rooms"
on public.meetup_rooms for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists "hosts can update meetup rooms" on public.meetup_rooms;
create policy "hosts can update meetup rooms"
on public.meetup_rooms for update
to authenticated
using (created_by = auth.uid())
with check (created_by = auth.uid());

drop policy if exists "hosts can delete meetup rooms" on public.meetup_rooms;
create policy "hosts can delete meetup rooms"
on public.meetup_rooms for delete
to authenticated
using (created_by = auth.uid());

drop policy if exists "signed in users can view room members" on public.room_members;
create policy "signed in users can view room members"
on public.room_members for select
to authenticated
using (true);

drop policy if exists "users can join as themselves" on public.room_members;
create policy "users can join as themselves"
on public.room_members for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "users can leave rooms" on public.room_members;
create policy "users can leave rooms"
on public.room_members for delete
to authenticated
using (user_id = auth.uid());

drop policy if exists "members can read room messages" on public.room_messages;
create policy "members can read room messages"
on public.room_messages for select
to authenticated
using (
    exists (
        select 1
          from public.room_members members
         where members.room_id = room_messages.room_id
           and members.user_id = auth.uid()
    )
);

drop policy if exists "members can send room messages" on public.room_messages;
create policy "members can send room messages"
on public.room_messages for insert
to authenticated
with check (
    sender_id = auth.uid()
    and exists (
        select 1
          from public.room_members members
         where members.room_id = room_messages.room_id
           and members.user_id = auth.uid()
    )
);
