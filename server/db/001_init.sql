create type user_role as enum ('customer', 'vip', 'admin');
create type order_status as enum ('pending', 'confirmed', 'shipped', 'cancelled');
create type tier_role as enum ('all', 'vip');

create table users (
  id bigint generated always as identity primary key,
  username text not null,
  password_hash text not null,
  name text not null default '',
  phone text,
  role user_role not null default 'customer',
  created_at timestamptz not null default now()
);
create unique index users_username_lower on users (lower(username));

create table categories (
  id bigint generated always as identity primary key,
  name text not null unique,
  sort int not null default 0
);

create table products (
  id bigint generated always as identity primary key,
  name text not null,
  category_id bigint references categories on delete set null,
  image_url text,
  retail_price numeric(10,2) not null check (retail_price > 0),
  vip_price numeric(10,2) check (vip_price > 0),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table price_tiers (
  id bigint generated always as identity primary key,
  product_id bigint not null references products on delete cascade,
  min_qty int not null check (min_qty >= 1),
  unit_price numeric(10,2) not null check (unit_price > 0),
  for_role tier_role not null default 'all',
  unique (product_id, min_qty, for_role)
);

create table orders (
  id bigint generated always as identity primary key,
  user_id bigint not null references users on delete cascade,
  status order_status not null default 'pending',
  total numeric(12,2) not null default 0,
  note text,
  tracking_no text,
  created_at timestamptz not null default now()
);

create table order_items (
  id bigint generated always as identity primary key,
  order_id bigint not null references orders on delete cascade,
  product_id bigint references products on delete set null,
  product_name text not null,
  qty int not null check (qty >= 1),
  unit_price_snapshot numeric(10,2) not null
);

create index on price_tiers (product_id);
create index on orders (user_id, created_at desc);
create index on orders (status, created_at desc);
create index on order_items (order_id);

-- Lowest applicable unit price for qty. Must match price_app/lib/core/pricing.dart.
create function unit_price(p_product bigint, p_qty int, p_role user_role)
returns numeric language sql stable as $$
  select min(price) from (
    select retail_price as price from products where id = p_product
    union all
    select vip_price from products
      where id = p_product and vip_price is not null and p_role in ('vip', 'admin')
    union all
    select unit_price from price_tiers
      where product_id = p_product and min_qty <= p_qty
        and (for_role = 'all' or p_role in ('vip', 'admin'))
  ) t;
$$;

-- items: [{"product_id": 1, "qty": 10}, ...]; prices are computed here, never trusted from the client.
create function create_order(p_user bigint, items jsonb, p_note text default null)
returns bigint language plpgsql as $$
declare
  v_role user_role;
  v_order bigint;
  v_item jsonb;
  v_product products;
  v_qty int;
  v_price numeric;
  v_total numeric := 0;
begin
  select role into v_role from users where id = p_user;
  if v_role is null then raise exception 'user not found'; end if;
  if jsonb_array_length(coalesce(items, '[]')) = 0 then raise exception 'cart is empty'; end if;

  insert into orders (user_id, note) values (p_user, p_note) returning id into v_order;

  for v_item in select * from jsonb_array_elements(items) loop
    v_qty := (v_item->>'qty')::int;
    select * into v_product from products where id = (v_item->>'product_id')::bigint and active;
    if v_product.id is null or v_qty is null or v_qty < 1 then
      raise exception 'invalid item %', v_item;
    end if;
    v_price := unit_price(v_product.id, v_qty, v_role);
    insert into order_items (order_id, product_id, product_name, qty, unit_price_snapshot)
      values (v_order, v_product.id, v_product.name, v_qty, v_price);
    v_total := v_total + v_price * v_qty;
  end loop;

  update orders set total = v_total where id = v_order;
  return v_order;
end $$;
