insert into categories (name, sort) values ('สกินแคร์', 1), ('อาหารเสริม', 2), ('น้ำหอม', 3), ('เครื่องสำอาง', 4);

insert into products (name, category_id, retail_price, vip_price) values
  ('ครีมซองกานิเย่ชมพู', 1, 29, 25),
  ('เซรั่มวิตซี 30ml', 1, 420, 340),
  ('น้ำหอมแจนยัวร์ 30ML', 3, 390, null);

insert into price_tiers (product_id, min_qty, unit_price, for_role) values
  (1, 5, 26, 'all'), (1, 10, 24, 'all'), (1, 10, 22, 'vip'),
  (2, 1, 370, 'all'), (2, 10, 350, 'all'), (2, 10, 330, 'vip'),
  (3, 5, 300, 'all'), (3, 10, 280, 'all');
