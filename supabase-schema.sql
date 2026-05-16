-- GOALFORGE - Complete Database Schema
-- Run this in Supabase SQL Editor.

create extension if not exists "pgcrypto";

create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  full_name text,
  role text check (role in ('employee', 'manager', 'admin')) default 'employee',
  manager_id uuid references profiles(id),
  created_at timestamp default now()
);

create table if not exists goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  title text not null,
  description text,
  thrust_area text not null,
  uom text check (uom in ('numeric', 'percent', 'timeline', 'zero')) not null,
  target_value decimal not null,
  weightage decimal check (weightage >= 0 and weightage <= 100),
  status text check (status in ('draft', 'submitted', 'approved', 'rejected')) default 'draft',
  locked boolean default false,
  manager_feedback text,
  created_at timestamp default now(),
  updated_at timestamp default now()
);

create table if not exists shared_goals (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references profiles(id),
  title text not null,
  description text,
  thrust_area text not null,
  uom text not null,
  target_value decimal not null,
  assigned_to_emails text[] default '{}',
  created_at timestamp default now()
);

create table if not exists goal_shares (
  id uuid primary key default gen_random_uuid(),
  shared_goal_id uuid references shared_goals(id),
  employee_id uuid references profiles(id),
  weightage decimal default 0,
  created_at timestamp default now()
);

create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid references goals(id),
  action text,
  changed_by uuid references profiles(id),
  old_data jsonb,
  new_data jsonb,
  notes text,
  created_at timestamp default now()
);

create table if not exists checkins (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid references goals(id),
  quarter text check (quarter in ('Q1', 'Q2', 'Q3', 'Q4')),
  actual_achievement decimal,
  status text check (status in ('Not Started', 'On Track', 'Completed')),
  manager_comment text,
  updated_at timestamp default now()
);

insert into profiles (email, full_name, role) values
  ('john.employee@atomberg.com', 'John Worker', 'employee'),
  ('jane.employee@atomberg.com', 'Jane Smith', 'employee'),
  ('mike.manager@atomberg.com', 'Mike Manager', 'manager'),
  ('admin@atomberg.com', 'Admin User', 'admin')
on conflict (email) do nothing;

update profiles
set manager_id = (select id from profiles where email = 'mike.manager@atomberg.com')
where role = 'employee' and manager_id is null;

alter table profiles enable row level security;
alter table goals enable row level security;
alter table shared_goals enable row level security;
alter table goal_shares enable row level security;
alter table audit_logs enable row level security;
alter table checkins enable row level security;

drop policy if exists "Profiles are readable" on profiles;
drop policy if exists "Goals are readable" on goals;
drop policy if exists "Goals are insertable" on goals;
drop policy if exists "Goals are updatable" on goals;
drop policy if exists "Shared goals are readable" on shared_goals;
drop policy if exists "Audit logs are readable" on audit_logs;

create policy "Profiles are readable" on profiles for select using (true);
create policy "Goals are readable" on goals for select using (true);
create policy "Goals are insertable" on goals for insert with check (true);
create policy "Goals are updatable" on goals for update using (true);
create policy "Shared goals are readable" on shared_goals for select using (true);
create policy "Audit logs are readable" on audit_logs for select using (true);
