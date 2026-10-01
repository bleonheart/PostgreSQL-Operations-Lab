WITH RECURSIVE category_tree AS (
    SELECT id, parent_id, code, name, 0 AS depth, name::TEXT AS path
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    SELECT c.id, c.parent_id, c.code, c.name, ct.depth + 1, ct.path || ' > ' || c.name
    FROM categories c
    JOIN category_tree ct ON ct.id = c.parent_id
)
SELECT id, code, name, depth, path
FROM category_tree
ORDER BY path;
