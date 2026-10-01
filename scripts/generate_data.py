#!/usr/bin/env python3
import argparse
import json
import os
import random
import sys
from datetime import datetime, timedelta, timezone

try:
    import psycopg
except ImportError as exc:
    raise SystemExit("psycopg is required; install dependencies with: pip install -r requirements.txt") from exc


BASE_TIME = datetime(2026, 1, 1, 12, 0, tzinfo=timezone.utc)
SUBJECTS = [
    "Unable to authenticate",
    "Intermittent API timeout",
    "Report export delayed",
    "Permission update not applied",
    "Webhook delivery failed",
    "Dashboard data appears stale",
    "Unexpected billing state",
    "Service latency above normal",
]
COMMENT_TEXT = [
    "Synthetic requester update with additional diagnostic context.",
    "Synthetic support response acknowledging the reported behavior.",
    "Synthetic investigation note recording a reproducible observation.",
    "Synthetic follow-up confirming the latest status.",
]
EVENT_TYPES = ["request.completed", "job.failed", "worker.retried", "cache.evicted", "health.degraded"]
EVENT_SEVERITIES = ["info", "info", "warning", "error", "critical"]


def parse_args():
    parser = argparse.ArgumentParser(description="Generate deterministic synthetic PostgreSQL operations lab data.")
    parser.add_argument("--organizations", type=int, default=50)
    parser.add_argument("--users-per-org", type=int, default=20)
    parser.add_argument("--agents", type=int, default=30)
    parser.add_argument("--tickets", type=int, default=20000)
    parser.add_argument("--incidents", type=int, default=300)
    parser.add_argument("--events", type=int, default=3000)
    parser.add_argument("--batch-size", type=int, default=1000)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--reset-generated", action="store_true")
    return parser.parse_args()


def validate_args(args):
    fields = {
        "organizations": (args.organizations, 1, 10000),
        "users_per_org": (args.users_per_org, 1, 10000),
        "agents": (args.agents, 1, 10000),
        "tickets": (args.tickets, 1, 2_000_000),
        "incidents": (args.incidents, 0, 200_000),
        "events": (args.events, 0, 2_000_000),
        "batch_size": (args.batch_size, 1, 10000),
    }
    for name, (value, minimum, maximum) in fields.items():
        if not minimum <= value <= maximum:
            raise ValueError(f"{name} must be between {minimum} and {maximum}")


def batch_insert(cur, query, rows, batch_size):
    for start in range(0, len(rows), batch_size):
        cur.executemany(query, rows[start:start + batch_size])


def get_dimensions(cur):
    cur.execute("SELECT id, code FROM priorities ORDER BY severity")
    priorities = cur.fetchall()
    cur.execute("SELECT id, code FROM categories WHERE active ORDER BY id")
    categories = cur.fetchall()
    cur.execute("SELECT id, service_key FROM services WHERE active ORDER BY id")
    services = cur.fetchall()
    if len(priorities) < 4 or not categories or not services:
        raise RuntimeError("reference data is missing; run seed/001_reference_data.sql first")
    return priorities, categories, services


def reset_generated(cur):
    cur.execute(
        "TRUNCATE audit_logs, system_events, incidents, assignments, ticket_status_history, "
        "ticket_comments, tickets, agents, users, organizations RESTART IDENTITY CASCADE"
    )


def create_organizations(cur, args):
    rows = [("internal-support", "Synthetic Internal Support", "premium", True)]
    plans = ["starter", "standard", "premium"]
    for i in range(1, args.organizations + 1):
        rows.append((f"synthetic-org-{i:04d}", f"Synthetic Organization {i:04d}", plans[(i - 1) % len(plans)], True))
    batch_insert(
        cur,
        "INSERT INTO organizations (slug, name, plan, active) VALUES (%s, %s, %s, %s) "
        "ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, plan = EXCLUDED.plan, active = EXCLUDED.active",
        rows,
        args.batch_size,
    )
    cur.execute("SELECT id, slug FROM organizations WHERE slug = 'internal-support' OR slug LIKE 'synthetic-org-%' ORDER BY slug")
    return cur.fetchall()


def create_users_and_agents(cur, args, organizations):
    org_by_slug = {slug: org_id for org_id, slug in organizations}
    support_org_id = org_by_slug["internal-support"]
    agent_users = []
    for i in range(1, args.agents + 1):
        agent_users.append((support_org_id, f"agent-{i:05d}", f"agent{i:05d}@example.invalid", f"Synthetic Agent {i:05d}", True, BASE_TIME, BASE_TIME))

    customer_users = []
    for org_index in range(1, args.organizations + 1):
        org_id = org_by_slug[f"synthetic-org-{org_index:04d}"]
        for user_index in range(1, args.users_per_org + 1):
            serial = (org_index - 1) * args.users_per_org + user_index
            last_seen = BASE_TIME + timedelta(days=(serial * 7) % 260)
            customer_users.append((org_id, f"customer-{serial:07d}", f"customer{serial:07d}@example.invalid", f"Synthetic User {serial:07d}", True, BASE_TIME, last_seen))

    query = (
        "INSERT INTO users (organization_id, external_ref, email, display_name, active, created_at, last_seen_at) "
        "VALUES (%s, %s, %s, %s, %s, %s, %s) "
        "ON CONFLICT (external_ref) DO UPDATE SET email = EXCLUDED.email, display_name = EXCLUDED.display_name, active = EXCLUDED.active, last_seen_at = EXCLUDED.last_seen_at"
    )
    batch_insert(cur, query, agent_users + customer_users, args.batch_size)

    cur.execute("SELECT id, external_ref FROM users WHERE external_ref LIKE 'agent-%' ORDER BY external_ref")
    agents = cur.fetchall()
    agent_rows = [(user_id, f"team-{((i - 1) % 4) + 1}", True) for i, (user_id, _) in enumerate(agents, 1)]
    batch_insert(
        cur,
        "INSERT INTO agents (user_id, team, active) VALUES (%s, %s, %s) ON CONFLICT (user_id) DO UPDATE SET team = EXCLUDED.team, active = EXCLUDED.active",
        agent_rows,
        args.batch_size,
    )

    cur.execute(
        "SELECT u.id, u.organization_id FROM users u JOIN organizations o ON o.id = u.organization_id "
        "WHERE o.slug LIKE 'synthetic-org-%' ORDER BY u.id"
    )
    customer_user_rows = cur.fetchall()
    cur.execute("SELECT id FROM agents WHERE active ORDER BY id")
    agent_ids = [row[0] for row in cur.fetchall()]
    return customer_user_rows, agent_ids


def create_tickets(cur, args, rng, priorities, categories, services, customer_users):
    priority_ids = [row[0] for row in priorities]
    category_ids = [row[0] for row in categories]
    service_ids = [row[0] for row in services]
    status_choices = ["open", "pending", "resolved", "closed"]
    status_weights = [28, 17, 30, 25]
    rows = []

    for i in range(1, args.tickets + 1):
        user_id, org_id = rng.choice(customer_users)
        priority_id = rng.choices(priority_ids, weights=[4, 16, 55, 25], k=1)[0]
        category_id = rng.choice(category_ids)
        service_id = rng.choice(service_ids)
        status = rng.choices(status_choices, weights=status_weights, k=1)[0]
        created_at = BASE_TIME + timedelta(minutes=rng.randint(0, 60 * 24 * 270))
        first_response_at = created_at + timedelta(minutes=rng.randint(5, 360))
        resolved_at = None
        if status in ("resolved", "closed"):
            resolved_at = created_at + timedelta(minutes=rng.randint(30, 60 * 24 * 8))
        updated_at = resolved_at or created_at + timedelta(minutes=rng.randint(10, 60 * 24 * 10))
        reopened_count = rng.choices([0, 1, 2, 3], weights=[84, 10, 4, 2], k=1)[0]
        metadata = json.dumps({"channel": rng.choice(["portal", "api", "email"]), "synthetic": True, "sequence": i})
        rows.append((
            org_id,
            user_id,
            priority_id,
            category_id,
            service_id,
            status,
            f"Synthetic ticket {i:07d}: {rng.choice(SUBJECTS)}",
            "Synthetic support request generated for database operations testing.",
            metadata,
            created_at,
            updated_at,
            first_response_at,
            resolved_at,
            reopened_count,
        ))

    batch_insert(
        cur,
        "INSERT INTO tickets (organization_id, requester_user_id, priority_id, category_id, service_id, status, subject, description, metadata, created_at, updated_at, first_response_at, resolved_at, reopened_count) "
        "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s::jsonb, %s, %s, %s, %s, %s)",
        rows,
        args.batch_size,
    )
    cur.execute("SELECT id, requester_user_id, status, created_at, resolved_at, reopened_count FROM tickets ORDER BY id")
    return cur.fetchall()


def create_ticket_activity(cur, args, rng, tickets, agent_ids):
    comments = []
    history = []
    assignments = []
    audit = []

    for ticket_id, requester_id, status, created_at, resolved_at, reopened_count in tickets:
        assigned_agent = rng.choice(agent_ids)
        assignments.append((ticket_id, assigned_agent, created_at + timedelta(minutes=rng.randint(1, 120)), None))

        comment_count = rng.randint(1, 4)
        for offset in range(comment_count):
            comment_time = created_at + timedelta(minutes=10 + offset * rng.randint(10, 240))
            if offset % 2 == 0:
                comments.append((ticket_id, requester_id, None, rng.choice(COMMENT_TEXT), False, comment_time))
            else:
                comments.append((ticket_id, None, assigned_agent, rng.choice(COMMENT_TEXT), rng.random() < 0.3, comment_time))

        history.append((ticket_id, None, "open", assigned_agent, created_at, "Synthetic ticket created"))
        if status == "pending":
            history.append((ticket_id, "open", "pending", assigned_agent, created_at + timedelta(hours=2), "Awaiting synthetic requester input"))
        elif status in ("resolved", "closed"):
            resolution_time = resolved_at or created_at + timedelta(hours=4)
            history.append((ticket_id, "open", "resolved", assigned_agent, resolution_time, "Synthetic resolution recorded"))
            if status == "closed":
                history.append((ticket_id, "resolved", "closed", assigned_agent, resolution_time + timedelta(hours=1), "Synthetic closure recorded"))
        for reopen_index in range(reopened_count):
            reopen_time = (resolved_at or created_at + timedelta(hours=4)) + timedelta(hours=reopen_index + 1)
            history.append((ticket_id, "resolved", "open", assigned_agent, reopen_time, "Synthetic reopen event"))

        if ticket_id % 5 == 0:
            audit.append((None, assigned_agent, "ticket", ticket_id, "update", None, json.dumps({"synthetic": True, "status": status}), created_at))

    batch_insert(
        cur,
        "INSERT INTO ticket_comments (ticket_id, author_user_id, author_agent_id, body, internal, created_at) VALUES (%s, %s, %s, %s, %s, %s)",
        comments,
        args.batch_size,
    )
    batch_insert(
        cur,
        "INSERT INTO ticket_status_history (ticket_id, from_status, to_status, changed_by_agent_id, changed_at, reason) VALUES (%s, %s, %s, %s, %s, %s)",
        history,
        args.batch_size,
    )
    batch_insert(
        cur,
        "INSERT INTO assignments (ticket_id, agent_id, assigned_at, unassigned_at) VALUES (%s, %s, %s, %s)",
        assignments,
        args.batch_size,
    )
    batch_insert(
        cur,
        "INSERT INTO audit_logs (actor_user_id, actor_agent_id, entity_type, entity_id, action, before_data, after_data, created_at) VALUES (%s, %s, %s, %s, %s, %s, %s::jsonb, %s)",
        audit,
        args.batch_size,
    )


def create_incidents_and_events(cur, args, rng, categories, services):
    category_ids = [row[0] for row in categories]
    service_ids = [row[0] for row in services]
    incidents = []
    for i in range(1, args.incidents + 1):
        started_at = BASE_TIME + timedelta(minutes=rng.randint(0, 60 * 24 * 270))
        severity = rng.choices([1, 2, 3, 4], weights=[5, 20, 45, 30], k=1)[0]
        status = rng.choice(["investigating", "identified", "monitoring", "resolved"])
        resolved_at = started_at + timedelta(minutes=rng.randint(15, 600)) if status == "resolved" else None
        incidents.append((
            rng.choice(service_ids),
            rng.choice(category_ids),
            severity,
            status,
            f"Synthetic incident {i:05d}",
            "Synthetic incident used to exercise operational queries and incident analysis.",
            json.dumps({"synthetic": True, "sequence": i}),
            started_at,
            resolved_at,
        ))
    batch_insert(
        cur,
        "INSERT INTO incidents (service_id, category_id, severity, status, title, summary, metadata, started_at, resolved_at) VALUES (%s, %s, %s, %s, %s, %s, %s::jsonb, %s, %s)",
        incidents,
        args.batch_size,
    )

    events = []
    for i in range(1, args.events + 1):
        events.append((
            rng.choice(service_ids),
            rng.choice(EVENT_TYPES),
            rng.choice(EVENT_SEVERITIES),
            json.dumps({"synthetic": True, "sequence": i, "duration_ms": rng.randint(1, 5000)}),
            BASE_TIME + timedelta(minutes=rng.randint(0, 60 * 24 * 270)),
        ))
    batch_insert(
        cur,
        "INSERT INTO system_events (service_id, event_type, severity, payload, created_at) VALUES (%s, %s, %s, %s::jsonb, %s)",
        events,
        args.batch_size,
    )


def main():
    args = parse_args()
    try:
        validate_args(args)
    except ValueError as exc:
        print(f"input error: {exc}", file=sys.stderr)
        return 2

    database_url = os.getenv("DATABASE_URL")
    if database_url:
        connection = {"conninfo": database_url, "connect_timeout": 5}
    else:
        required = ["PGHOST", "PGUSER", "PGDATABASE"]
        missing = [name for name in required if not os.getenv(name)]
        if missing:
            print(f"database connection configuration missing: {', '.join(missing)}", file=sys.stderr)
            return 2
        connection = {
            "host": os.environ["PGHOST"],
            "port": int(os.getenv("PGPORT", "5432")),
            "user": os.environ["PGUSER"],
            "dbname": os.environ["PGDATABASE"],
            "connect_timeout": 5,
        }
        if os.getenv("PGPASSWORD"):
            connection["password"] = os.environ["PGPASSWORD"]

    rng = random.Random(args.seed)
    try:
        with psycopg.connect(**connection) as conn:
            with conn.cursor() as cur:
                if args.reset_generated:
                    reset_generated(cur)
                else:
                    cur.execute("SELECT EXISTS (SELECT 1 FROM tickets WHERE metadata @> '{\"synthetic\": true}'::jsonb)")
                    if cur.fetchone()[0]:
                        raise RuntimeError("synthetic data already exists; rerun with --reset-generated to replace it safely")
                priorities, categories, services = get_dimensions(cur)
                organizations = create_organizations(cur, args)
                customer_users, agent_ids = create_users_and_agents(cur, args, organizations)
                tickets = create_tickets(cur, args, rng, priorities, categories, services, customer_users)
                create_ticket_activity(cur, args, rng, tickets, agent_ids)
                create_incidents_and_events(cur, args, rng, categories, services)
                cur.execute("REFRESH MATERIALIZED VIEW mv_daily_ticket_metrics")
        print(
            f"generated organizations={args.organizations} users={args.organizations * args.users_per_org} "
            f"agents={args.agents} tickets={args.tickets} incidents={args.incidents} events={args.events} seed={args.seed}"
        )
        return 0
    except psycopg.Error as exc:
        print(f"database error: {exc}", file=sys.stderr)
        return 1
    except RuntimeError as exc:
        print(f"generation error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
