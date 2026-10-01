SELECT test_runtime.assert_true(to_regclass('public.organizations') IS NOT NULL, 'organizations table exists');
SELECT test_runtime.assert_true(to_regclass('public.tickets') IS NOT NULL, 'tickets table exists');
SELECT test_runtime.assert_true(to_regclass('public.audit_logs') IS NOT NULL, 'audit_logs table exists');
SELECT test_runtime.assert_true(to_regclass('public.v_open_ticket_worklist') IS NOT NULL, 'worklist view exists');
SELECT test_runtime.assert_true(to_regclass('public.mv_daily_ticket_metrics') IS NOT NULL, 'daily metrics materialized view exists');

SELECT test_runtime.assert_true(
    EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_tickets_open_priority_updated'),
    'partial open-ticket index exists'
);

SELECT test_runtime.assert_true(
    EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'uq_assignments_one_active_ticket'),
    'active assignment uniqueness index exists'
);
