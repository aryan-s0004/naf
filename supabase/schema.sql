create extension if not exists "uuid-ossp";

create table if not exists profiles (
  id uuid primary key default uuid_generate_v4(),
  email text unique not null,
  full_name text not null,
  role text not null check (role in ('employee', 'manager', 'admin')),
  manager_id uuid references profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists goals (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  description text,
  thrust_area text not null,
  uom text not null,
  target_value numeric not null,
  weightage numeric not null default 10,
  status text not null default 'draft' check (status in ('draft', 'submitted', 'approved', 'rejected')),
  locked boolean not null default false,
  manager_feedback text default '',
  created_at timestamptz not null default now()
);

create table if not exists shared_goals (
  id uuid primary key default uuid_generate_v4(),
  created_by uuid not null references profiles(id),
  title text not null,
  description text,
  thrust_area text not null,
  uom text not null,
  target_value numeric not null,
  assigned_to_emails text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists audit_logs (
  id uuid primary key default uuid_generate_v4(),
  goal_id uuid references goals(id) on delete set null,
  action text not null,
  changed_by uuid not null references profiles(id),
  notes text,
  created_at timestamptz not null default now()
);

insert into profiles (id, email, full_name, role, manager_id) values
  ('00000000-0000-0000-0000-000000000001', 'mike.manager@atomberg.com', 'Mike Manager', 'manager', null),
  ('00000000-0000-0000-0000-000000000002', 'john.employee@atomberg.com', 'John Employee', 'employee', '00000000-0000-0000-0000-000000000001'),
  ('00000000-0000-0000-0000-000000000003', 'jane.employee@atomberg.com', 'Jane Employee', 'employee', '00000000-0000-0000-0000-000000000001'),
  ('00000000-0000-0000-0000-000000000004', 'admin@atomberg.com', 'GoalForge Admin', 'admin', null)
on conflict (email) do nothing;
