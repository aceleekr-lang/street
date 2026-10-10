-- 백중미션 앱 — 다섯 자리 좌표 저장 (기존 백중연 Supabase 프로젝트에 추가, 재실행 안전)
-- 관리자 암호는 백중연 관리자와 같은 '00010101' (바꾸려면 아래 한 곳만)

create table if not exists public.baekjung_mission_spots (
  idx        int primary key check (idx between 1 and 5),
  lat        double precision not null,
  lng        double precision not null,
  updated_at timestamptz not null default now()
);
alter table public.baekjung_mission_spots enable row level security;
drop policy if exists "anon_read" on public.baekjung_mission_spots;
create policy "anon_read" on public.baekjung_mission_spots
  for select to anon, authenticated using (true);   -- 좌표는 공개 정보(앱이 읽음)
grant select on public.baekjung_mission_spots to anon, authenticated;

-- 관리자: 다섯 자리 좌표 한 번에 저장  p_spots = [{"idx":1,"lat":35.5,"lng":128.7}, ...]
create or replace function public.baekjung_mission_set_spots(p_pass text, p_spots jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare s jsonb;
begin
  if p_pass is distinct from '00010101' then perform pg_sleep(1.5); raise exception 'DENIED'; end if;
  for s in select * from jsonb_array_elements(p_spots) loop
    insert into public.baekjung_mission_spots (idx, lat, lng)
      values ((s->>'idx')::int, (s->>'lat')::double precision, (s->>'lng')::double precision)
    on conflict (idx) do update set lat = excluded.lat, lng = excluded.lng, updated_at = now();
  end loop;
end $$;
grant execute on function public.baekjung_mission_set_spots(text, jsonb) to anon, authenticated;
