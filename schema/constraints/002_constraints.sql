DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'organizations_plan_check') THEN
        ALTER TABLE organizations ADD CONSTRAINT organizations_plan_check CHECK (plan IN ('starter', 'standard', 'premium'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_organization_fk') THEN
        ALTER TABLE users ADD CONSTRAINT users_organization_fk FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'agents_user_fk') THEN
        ALTER TABLE agents ADD CONSTRAINT agents_user_fk FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'priorities_severity_check') THEN
        ALTER TABLE priorities ADD CONSTRAINT priorities_severity_check CHECK (severity BETWEEN 1 AND 4);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'priorities_targets_check') THEN
        ALTER TABLE priorities ADD CONSTRAINT priorities_targets_check CHECK (response_target_minutes > 0 AND resolution_target_minutes >= response_target_minutes);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'categories_parent_fk') THEN
        ALTER TABLE categories ADD CONSTRAINT categories_parent_fk FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'services_tier_check') THEN
        ALTER TABLE services ADD CONSTRAINT services_tier_check CHECK (tier IN ('critical', 'core', 'supporting'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sla_priority_fk') THEN
        ALTER TABLE sla_policies ADD CONSTRAINT sla_priority_fk FOREIGN KEY (priority_id) REFERENCES priorities(id) ON DELETE RESTRICT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sla_plan_check') THEN
        ALTER TABLE sla_policies ADD CONSTRAINT sla_plan_check CHECK (plan IN ('starter', 'standard', 'premium'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sla_targets_check') THEN
        ALTER TABLE sla_policies ADD CONSTRAINT sla_targets_check CHECK (response_target_minutes > 0 AND resolution_target_minutes >= response_target_minutes);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tickets_organization_fk') THEN
        ALTER TABLE tickets ADD CONSTRAINT tickets_organization_fk FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tickets_requester_fk') THEN
        ALTER TABLE tickets ADD CONSTRAINT tickets_requester_fk FOREIGN KEY (requester_user_id) REFERENCES users(id) ON DELETE RESTRICT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tickets_priority_fk') THEN
        ALTER TABLE tickets ADD CONSTRAINT tickets_priority_fk FOREIGN KEY (priority_id) REFERENCES priorities(id) ON DELETE RESTRICT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tickets_category_fk') THEN
        ALTER TABLE tickets ADD CONSTRAINT tickets_category_fk FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tickets_service_fk') THEN
        ALTER TABLE tickets ADD CONSTRAINT tickets_service_fk FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tickets_status_check') THEN
        ALTER TABLE tickets ADD CONSTRAINT tickets_status_check CHECK (status IN ('open', 'pending', 'resolved', 'closed'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tickets_reopened_count_check') THEN
        ALTER TABLE tickets ADD CONSTRAINT tickets_reopened_count_check CHECK (reopened_count >= 0);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tickets_resolution_dates_check') THEN
        ALTER TABLE tickets ADD CONSTRAINT tickets_resolution_dates_check CHECK (resolved_at IS NULL OR resolved_at >= created_at);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'comments_ticket_fk') THEN
        ALTER TABLE ticket_comments ADD CONSTRAINT comments_ticket_fk FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'comments_author_user_fk') THEN
        ALTER TABLE ticket_comments ADD CONSTRAINT comments_author_user_fk FOREIGN KEY (author_user_id) REFERENCES users(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'comments_author_agent_fk') THEN
        ALTER TABLE ticket_comments ADD CONSTRAINT comments_author_agent_fk FOREIGN KEY (author_agent_id) REFERENCES agents(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'comments_one_author_check') THEN
        ALTER TABLE ticket_comments ADD CONSTRAINT comments_one_author_check CHECK (num_nonnulls(author_user_id, author_agent_id) = 1);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'status_history_ticket_fk') THEN
        ALTER TABLE ticket_status_history ADD CONSTRAINT status_history_ticket_fk FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'status_history_agent_fk') THEN
        ALTER TABLE ticket_status_history ADD CONSTRAINT status_history_agent_fk FOREIGN KEY (changed_by_agent_id) REFERENCES agents(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'status_history_from_check') THEN
        ALTER TABLE ticket_status_history ADD CONSTRAINT status_history_from_check CHECK (from_status IS NULL OR from_status IN ('open', 'pending', 'resolved', 'closed'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'status_history_to_check') THEN
        ALTER TABLE ticket_status_history ADD CONSTRAINT status_history_to_check CHECK (to_status IN ('open', 'pending', 'resolved', 'closed'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assignments_ticket_fk') THEN
        ALTER TABLE assignments ADD CONSTRAINT assignments_ticket_fk FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assignments_agent_fk') THEN
        ALTER TABLE assignments ADD CONSTRAINT assignments_agent_fk FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE RESTRICT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assignments_dates_check') THEN
        ALTER TABLE assignments ADD CONSTRAINT assignments_dates_check CHECK (unassigned_at IS NULL OR unassigned_at >= assigned_at);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'incidents_service_fk') THEN
        ALTER TABLE incidents ADD CONSTRAINT incidents_service_fk FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'incidents_category_fk') THEN
        ALTER TABLE incidents ADD CONSTRAINT incidents_category_fk FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'incidents_severity_check') THEN
        ALTER TABLE incidents ADD CONSTRAINT incidents_severity_check CHECK (severity BETWEEN 1 AND 4);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'incidents_status_check') THEN
        ALTER TABLE incidents ADD CONSTRAINT incidents_status_check CHECK (status IN ('investigating', 'identified', 'monitoring', 'resolved'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'incidents_dates_check') THEN
        ALTER TABLE incidents ADD CONSTRAINT incidents_dates_check CHECK (resolved_at IS NULL OR resolved_at >= started_at);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'events_service_fk') THEN
        ALTER TABLE system_events ADD CONSTRAINT events_service_fk FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'events_severity_check') THEN
        ALTER TABLE system_events ADD CONSTRAINT events_severity_check CHECK (severity IN ('debug', 'info', 'warning', 'error', 'critical'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'audit_user_fk') THEN
        ALTER TABLE audit_logs ADD CONSTRAINT audit_user_fk FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'audit_agent_fk') THEN
        ALTER TABLE audit_logs ADD CONSTRAINT audit_agent_fk FOREIGN KEY (actor_agent_id) REFERENCES agents(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'audit_actor_check') THEN
        ALTER TABLE audit_logs ADD CONSTRAINT audit_actor_check CHECK (num_nonnulls(actor_user_id, actor_agent_id) <= 1);
    END IF;
END
$$;
