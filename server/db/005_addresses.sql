create table if not exists addresses (
  id bigint generated always as identity primary key,
  user_id bigint not null references users (id) on delete cascade,
  label text not null default '',
  recipient_name text not null,
  phone text not null default '',
  address_line text not null,
  subdistrict text not null default '',
  district text not null default '',
  province text not null,
  postal_code text not null default '',
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists addresses_user on addresses (user_id);

alter table orders add column if not exists ship_recipient text not null default '';
alter table orders add column if not exists ship_phone text not null default '';
alter table orders add column if not exists ship_line text not null default '';
alter table orders add column if not exists ship_subdistrict text not null default '';
alter table orders add column if not exists ship_district text not null default '';
alter table orders add column if not exists ship_province text not null default '';
alter table orders add column if not exists ship_postal text not null default '';
