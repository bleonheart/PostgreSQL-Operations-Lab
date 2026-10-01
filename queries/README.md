# Query Catalog

Every file is intended to answer an operational question or demonstrate a controlled maintenance pattern.

## Operations

| File | Intended question |
| --- | --- |
| `operations/01_unresolved_by_priority.sql` | How many unresolved tickets exist at each priority? |
| `operations/02_sla_breach_risk.sql` | Which tickets are approaching or past their resolution target? |
| `operations/03_agent_workloads.sql` | How much active work is assigned to each agent, including P1 concentration? |
| `operations/04_stale_tickets.sql` | Which unresolved tickets have not been updated for 48 hours? |
| `operations/05_inactive_customers.sql` | Which customer organizations show no recent user or ticket activity? |
| `operations/06_status_history.sql` | What state transitions occurred for a ticket or across the workload? |
| `operations/07_safe_ticket_update.sql` | How can an operator lock, change, verify, and roll back a ticket update safely? |
| `operations/08_transaction_isolation.sql` | How does a repeatable-read operational snapshot start and end? |
| `operations/09_batched_event_retention.sql` | Which old low-severity events would a bounded retention batch delete? |

## Reporting

| File | Intended question |
| --- | --- |
| `reporting/01_ticket_volume_by_day.sql` | How does ticket creation volume change by day? |
| `reporting/02_average_resolution_time.sql` | What are average and median resolution times by priority? |
| `reporting/03_reopened_tickets.sql` | Which tickets are reopened repeatedly and how do they rank? |
| `reporting/04_incident_categories.sql` | Which categories account for the most incidents? |
| `reporting/05_service_incident_frequency.sql` | Which services experience incidents most frequently? |
| `reporting/06_category_tree.sql` | What is the full recursive category hierarchy? |

## Troubleshooting

| File | Intended question |
| --- | --- |
| `troubleshooting/01_duplicate_detection.sql` | Which ticket groups are candidates for duplicate investigation? |
| `troubleshooting/02_long_running_transactions.sql` | Which transactions are oldest and what are they waiting on? |
| `troubleshooting/03_blocking_locks.sql` | Which sessions are blocked and which sessions block them? |

## Optimization

| File | Intended question |
| --- | --- |
| `optimization/01_n_plus_one_replacement.sql` | How can a multi-lookup ticket screen be served by one set-based query? |
| `optimization/02_jsonb_channel_filter.sql` | How is JSONB containment used for synthetic ticket-channel filtering? |
