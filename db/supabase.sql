-- ════════════════════════════════════════════════════════════════════
-- Bitácora Territorial — esquema Supabase (PostgreSQL)
-- Ejecutar en el SQL Editor del proyecto. Idempotente.
-- ════════════════════════════════════════════════════════════════════

create extension if not exists "pgcrypto";

-- ── Tipos ───────────────────────────────────────────────────────────
do $$ begin
  create type eje_tematico as enum ('Políticas públicas','Paz y reconciliación','Derechos humanos','Protección','Atención a la ciudadanía','Transversal');
exception when duplicate_object then null; end $$;

do $$ begin
  create type tipo_actividad as enum ('Comité de política pública','Consejo Territorial de Paz','Subcomité de Prevención','Mesa técnica','Jornada o evento','Atención a la ciudadanía','Trámite institucional','Visita territorial','Respuesta a PQRS','Capacitación','Seguimiento a compromisos');
exception when duplicate_object then null; end $$;

do $$ begin
  create type tipo_evidencia as enum ('foto','pdf','audio','archivo');
exception when duplicate_object then null; end $$;

do $$ begin
  create type estado_compromiso as enum ('Pendiente','En trámite','Cumplido');
exception when duplicate_object then null; end $$;

-- ── Perfil contractual ──────────────────────────────────────────────
create table if not exists perfiles (
  id                uuid primary key references auth.users(id) on delete cascade,
  nombre_completo   text not null,
  documento         text,
  municipio         text not null default '',
  departamento      text,
  secretaria        text,
  dependencia       text,
  numero_contrato   text,
  objeto_contrato   text,
  fecha_inicio      date,
  fecha_fin         date,
  valor_mensual     numeric(14,2),
  supervisor_nombre text,
  supervisor_cargo  text,
  codigo_formato    text default 'FT-GD-02',
  creado_en         timestamptz not null default now()
);

-- ── Las 11 obligaciones ─────────────────────────────────────────────
create table if not exists obligaciones (
  id           uuid primary key default gen_random_uuid(),
  perfil_id    uuid not null references perfiles(id) on delete cascade,
  numero       int  not null check (numero between 1 and 11),
  codigo       text generated always as ('O-' || lpad(numero::text, 2, '0')) stored,
  titulo       text not null,
  nombre_corto text,
  eje          eje_tematico,
  meta_mensual int  not null default 1 check (meta_mensual > 0),
  politicas    text[] default '{}',
  entregable   text default 'informe' check (entregable in ('acta','informe')),
  activa       boolean not null default true,
  unique (perfil_id, numero)
);

-- ── Actas ───────────────────────────────────────────────────────────
create table if not exists actas (
  id            uuid primary key default gen_random_uuid(),
  perfil_id     uuid not null references perfiles(id) on delete cascade,
  obligacion_id uuid not null references obligaciones(id) on delete restrict,
  consecutivo   int  not null,
  anio          int  not null,
  instancia     text not null,
  fecha         date not null,
  hora_inicio   time,
  hora_fin      time,
  lugar         text,
  modalidad     text default 'Presencial' check (modalidad in ('Presencial','Virtual','Mixta')),
  convoca       text,
  objetivo      text,
  orden_dia     jsonb not null default '[]'::jsonb,
  desarrollo    jsonb not null default '[]'::jsonb,
  conclusiones  text,
  elaborada_por text,
  estado        text not null default 'borrador' check (estado in ('borrador','aprobada','firmada')),
  creado_en     timestamptz not null default now(),
  unique (perfil_id, anio, consecutivo)
);

-- ── Informes congelados ─────────────────────────────────────────────
create table if not exists informes (
  id                uuid primary key default gen_random_uuid(),
  perfil_id         uuid not null references perfiles(id) on delete cascade,
  periodo           text not null check (periodo ~ '^\d{4}-\d{2}$'),
  tipo              text not null default 'mensual' check (tipo in ('mensual','diapositivas')),
  resumen           jsonb not null default '[]'::jsonb,
  html              text,
  storage_path_pdf  text,
  estado            text not null default 'generado' check (estado in ('generado','radicado','pagado')),
  radicado_en       date,
  creado_en         timestamptz not null default now(),
  unique (perfil_id, periodo, tipo)
);

-- ── Actividades ─────────────────────────────────────────────────────
create table if not exists actividades (
  id                     uuid primary key default gen_random_uuid(),
  perfil_id              uuid not null references perfiles(id) on delete cascade,
  obligacion_id          uuid not null references obligaciones(id) on delete restrict,
  acta_id                uuid references actas(id) on delete set null,
  tipo                   tipo_actividad,
  titulo                 text not null,
  instancia              text,
  fecha                  date not null,
  hora                   time,
  lugar                  text,
  participantes          int not null default 0 check (participantes >= 0),
  radicado               text,
  nota_cruda             text,
  descripcion            text,
  transcripcion_audio    text,
  estado                 text not null default 'borrador' check (estado in ('borrador','confirmada','reportada')),
  reportada_en_informe   uuid references informes(id) on delete set null,
  creado_en              timestamptz not null default now(),
  archivado_en           timestamptz
);
create index if not exists ix_act_perfil_fecha on actividades (perfil_id, fecha desc);
create index if not exists ix_act_obligacion  on actividades (obligacion_id, fecha desc);

-- ── Evidencias ──────────────────────────────────────────────────────
create table if not exists evidencias (
  id            uuid primary key default gen_random_uuid(),
  perfil_id     uuid not null references perfiles(id) on delete cascade,
  actividad_id  uuid references actividades(id) on delete cascade,
  acta_id       uuid references actas(id) on delete cascade,
  tipo          tipo_evidencia not null,
  nombre        text not null,
  descripcion   text,
  storage_path  text not null,
  mime          text,
  bytes         bigint,
  ancho         int,
  alto          int,
  capturada_en  timestamptz,
  orden         int not null default 0,
  creado_en     timestamptz not null default now(),
  constraint evidencia_tiene_dueno check (actividad_id is not null or acta_id is not null)
);
create index if not exists ix_evi_actividad on evidencias (actividad_id, orden);
create index if not exists ix_evi_acta      on evidencias (acta_id, orden);

-- ── Compromisos y asistentes del acta ───────────────────────────────
create table if not exists compromisos (
  id                 uuid primary key default gen_random_uuid(),
  acta_id            uuid not null references actas(id) on delete cascade,
  orden              int not null default 0,
  descripcion        text not null,
  responsable        text,
  entidad            text,
  fecha_limite       date,
  estado             estado_compromiso not null default 'Pendiente',
  cerrado_en         timestamptz,
  observacion_cierre text
);
create index if not exists ix_comp_acta on compromisos (acta_id, orden);

create table if not exists asistentes (
  id       uuid primary key default gen_random_uuid(),
  acta_id  uuid not null references actas(id) on delete cascade,
  orden    int not null default 0,
  nombre   text not null,
  cargo    text,
  entidad  text,
  contacto text,
  sector   text check (sector in ('Institucional','Sociedad civil','Organismo de control','Fuerza pública','Cooperación','Otro'))
);
create index if not exists ix_asis_acta on asistentes (acta_id, orden);

-- ── Vistas del panel de control ─────────────────────────────────────
create or replace view v_semaforo_mensual as
select
  o.perfil_id,
  to_char(a.fecha, 'YYYY-MM')                     as periodo,
  o.numero                                        as obligacion,
  o.codigo,
  o.nombre_corto,
  o.meta_mensual,
  count(a.id)                                     as actividades,
  coalesce(sum(e.n), 0)                           as evidencias,
  least(100, round(count(a.id)::numeric * 100 / o.meta_mensual))::int as cumplimiento,
  case
    when count(a.id) = 0                                    then 'rojo'
    when count(a.id) >= o.meta_mensual                      then 'verde'
    when count(a.id)::numeric / o.meta_mensual >= 0.4       then 'ambar'
    else 'rojo'
  end                                             as semaforo
from obligaciones o
left join actividades a
       on a.obligacion_id = o.id and a.archivado_en is null
left join lateral (
  select count(*) as n from evidencias ev where ev.actividad_id = a.id
) e on true
group by o.perfil_id, periodo, o.numero, o.codigo, o.nombre_corto, o.meta_mensual;

create or replace view v_compromisos_abiertos as
select c.*, ac.instancia, ac.fecha as fecha_acta, ac.perfil_id,
       (current_date - c.fecha_limite) as dias_vencido
from compromisos c
join actas ac on ac.id = c.acta_id
where c.estado <> 'Cumplido'
  and c.fecha_limite is not null
  and c.fecha_limite < current_date;

-- ── Siembra de las 11 obligaciones para un perfil nuevo ─────────────
create or replace function sembrar_obligaciones(p_perfil uuid)
returns void language sql as $$
  insert into obligaciones (perfil_id, numero, titulo, nombre_corto, eje, meta_mensual, entregable)
  values
    (p_perfil, 1,  'Preparar los espacios y realizar seguimiento a los comités de las políticas públicas LGBTI, Discapacidad y Afrodescendientes.', 'Comités de política pública', 'Políticas públicas', 2, 'acta'),
    (p_perfil, 2,  'Apoyar el cumplimiento de las metas establecidas en las políticas públicas de Juventud, Adulto Mayor, Mujer y MIAFF.', 'Metas Juventud · Adulto Mayor · Mujer · MIAFF', 'Políticas públicas', 1, 'informe'),
    (p_perfil, 3,  'Coordinar el Consejo Territorial de Paz, Reconciliación y Convivencia, elaborar las actas y realizar seguimiento a los planes de acción.', 'Consejo Territorial de Paz', 'Paz y reconciliación', 1, 'acta'),
    (p_perfil, 4,  'Realizar seguimiento y gestionar el cumplimiento de las recomendaciones de las Alertas Tempranas emitidas por la Defensoría del Pueblo.', 'Alertas Tempranas (SAT)', 'Derechos humanos', 3, 'informe'),
    (p_perfil, 5,  'Coordinar el Subcomité de Prevención, Protección y Garantías de No Repetición, levantar las actas y hacer seguimiento a los compromisos.', 'Subcomité de Prevención y Protección', 'Derechos humanos', 1, 'acta'),
    (p_perfil, 6,  'Coordinar, hacer seguimiento y evaluar la iniciativa PDET Pilar 8 — Reconciliación, Convivencia y Construcción de Paz.', 'PDET · Pilar 8', 'Paz y reconciliación', 1, 'informe'),
    (p_perfil, 7,  'Atender y orientar a la población migrante que acude a la Secretaría, activando las rutas institucionales correspondientes.', 'Población migrante', 'Atención a la ciudadanía', 4, 'informe'),
    (p_perfil, 8,  'Tramitar ante la Unidad Nacional de Protección las medidas de protección para líderes sociales, defensores de derechos humanos y personas en proceso de reincorporación.', 'Trámites UNP', 'Protección', 2, 'informe'),
    (p_perfil, 9,  'Activar las rutas de protección ante situaciones de riesgo extraordinario o extremo reportadas en el territorio.', 'Rutas de protección', 'Protección', 1, 'informe'),
    (p_perfil, 10, 'Proyectar y dar respuesta a las peticiones, quejas, reclamos y sugerencias asignadas a la Secretaría dentro de los términos de ley.', 'PQRS', 'Atención a la ciudadanía', 4, 'informe'),
    (p_perfil, 11, 'Cumplir las demás obligaciones asignadas por el supervisor del contrato, acordes con la naturaleza del objeto contractual.', 'Obligaciones complementarias', 'Transversal', 2, 'informe')
  on conflict (perfil_id, numero) do nothing;
$$;

-- Consecutivo de acta por perfil y año
create or replace function siguiente_consecutivo(p_perfil uuid, p_anio int)
returns int language sql stable as $$
  select coalesce(max(consecutivo), 0) + 1 from actas where perfil_id = p_perfil and anio = p_anio;
$$;

-- ── Seguridad a nivel de fila ───────────────────────────────────────
alter table perfiles     enable row level security;
alter table obligaciones enable row level security;
alter table actividades  enable row level security;
alter table evidencias   enable row level security;
alter table actas        enable row level security;
alter table compromisos  enable row level security;
alter table asistentes   enable row level security;
alter table informes     enable row level security;

drop policy if exists perfil_propio on perfiles;
create policy perfil_propio on perfiles for all using (id = auth.uid()) with check (id = auth.uid());

do $$
declare t text;
begin
  foreach t in array array['obligaciones','actividades','evidencias','actas','informes'] loop
    execute format('drop policy if exists %I_propias on %I', t, t);
    execute format(
      'create policy %I_propias on %I for all using (perfil_id = auth.uid()) with check (perfil_id = auth.uid())',
      t, t);
  end loop;
end $$;

-- Compromisos y asistentes heredan el dueño del acta
drop policy if exists compromisos_propios on compromisos;
create policy compromisos_propios on compromisos for all
  using (exists (select 1 from actas a where a.id = acta_id and a.perfil_id = auth.uid()))
  with check (exists (select 1 from actas a where a.id = acta_id and a.perfil_id = auth.uid()));

drop policy if exists asistentes_propios on asistentes;
create policy asistentes_propios on asistentes for all
  using (exists (select 1 from actas a where a.id = acta_id and a.perfil_id = auth.uid()))
  with check (exists (select 1 from actas a where a.id = acta_id and a.perfil_id = auth.uid()));

-- ── Storage ─────────────────────────────────────────────────────────
-- Bucket privado 'evidencias'; las rutas empiezan por el uuid del perfil.
insert into storage.buckets (id, name, public)
values ('evidencias', 'evidencias', false)
on conflict (id) do nothing;

drop policy if exists evidencias_propias on storage.objects;
create policy evidencias_propias on storage.objects for all
  using (bucket_id = 'evidencias' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'evidencias' and (storage.foldername(name))[1] = auth.uid()::text);
