# RedisTABLE - User Guide

**Version**: 1.0.0  
**Last Updated**: October 2025

A comprehensive guide to using RedisTABLE for SQL-like table operations in Redis.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Namespace Management](#namespace-management)
3. [Schema Management](#schema-management)
4. [Data Operations](#data-operations)
5. [Querying Data](#querying-data)
6. [Index Management](#index-management)
7. [Examples](#examples)
8. [Best Practices](#best-practices)

---

## Getting Started

### Installation

```bash
# Build the module
make build

# Start Redis with module
redis-server --loadmodule ./redistable.so
```

### Basic Workflow

```
1. Create Namespace  → TABLE.NAMESPACE.CREATE
2. Create Table      → TABLE.SCHEMA.CREATE
3. Insert Data       → TABLE.INSERT
4. Query Data        → TABLE.SELECT
5. Update Data       → TABLE.UPDATE
6. Delete Data       → TABLE.DELETE
```

---

## Namespace Management

Namespaces organize tables into logical groups (like databases in SQL).

### Create Namespace

```bash
# Create a namespace
redis-cli TABLE.NAMESPACE.CREATE myapp

# Response: OK
```

### List Namespaces

```bash
# View all namespaces
redis-cli TABLE.NAMESPACE.VIEW

# Response:
# 1) "myapp"
# 2) "analytics"
# 3) "cache"
```

### Drop Namespace

```bash
# Drop namespace (removes all tables)
redis-cli TABLE.NAMESPACE.DROP myapp FORCE

# Response: OK
```

**⚠️ Warning**: `DROP NAMESPACE` deletes all tables in the namespace. Use `FORCE` parameter to confirm.

---

## Schema Management

### Create Table

#### Basic Syntax

```bash
TABLE.SCHEMA.CREATE <namespace.table> col1:type[:index] col2:type[:index] ...
```

#### Data Types

| Type | Description | Example Values |
|------|-------------|----------------|
| `string` | Text data | `"hello"`, `"john@example.com"` |
| `integer` | Whole numbers | `42`, `-10`, `0` |
| `float` | Decimal numbers | `3.14`, `-0.5`, `99.99` |
| `date` | Date (YYYY-MM-DD) | `"2024-01-15"`, `"2025-12-31"` |

#### Index Types

| Type | Description | Performance |
|------|-------------|-------------|
| `hash` | Hash index | O(1) equality lookups |
| `none` | No index | O(n) full scan |
| `btree` | BTree index | Accepted (treated as hash) |

#### Examples

```bash
# Users table with indexes
redis-cli TABLE.SCHEMA.CREATE myapp.users \
  user_id:integer:hash \
  email:string:hash \
  name:string:none \
  age:integer:none \
  created_date:date:none

# Products table
redis-cli TABLE.SCHEMA.CREATE ecommerce.products \
  product_id:integer:hash \
  sku:string:hash \
  name:string:none \
  price:float:none \
  stock:integer:none \
  category:string:hash

# Orders table
redis-cli TABLE.SCHEMA.CREATE ecommerce.orders \
  order_id:integer:hash \
  customer_id:integer:hash \
  order_date:date:none \
  total:float:none \
  status:string:hash
```

### View Table Schema

```bash
# View schema
redis-cli TABLE.SCHEMA.VIEW myapp.users

# Response:
# 1) "user_id"
# 2) "integer"
# 3) "true"
# 4) "email"
# 5) "string"
# 6) "true"
# 7) "name"
# 8) "string"
# 9) "false"
# ...
```

### Alter Table

#### Add Column

```bash
# Add column without index
redis-cli TABLE.SCHEMA.ALTER myapp.users ADD COLUMN phone:string:none

# Add column with index
redis-cli TABLE.SCHEMA.ALTER myapp.users ADD COLUMN country:string:hash
```

#### Drop Column

```bash
# Drop column
redis-cli TABLE.SCHEMA.ALTER myapp.users DROP COLUMN phone
```

#### Add Index

```bash
# Add index to existing column
redis-cli TABLE.SCHEMA.ALTER myapp.users ADD INDEX age:hash
```

#### Drop Index

```bash
# Drop index from column
redis-cli TABLE.SCHEMA.ALTER myapp.users DROP INDEX age
```

**⚠️ Warning**: DROP INDEX has a known race condition. Run during maintenance windows.

### Drop Table

```bash
# Drop table (requires FORCE)
redis-cli TABLE.SCHEMA.DROP myapp.users FORCE

# Response: OK
```

---

## Data Operations

### Insert Data

#### Basic Insert

```bash
# Insert a row
redis-cli TABLE.INSERT myapp.users \
  user_id=1 \
  email=john@example.com \
  name=John \
  age=30 \
  created_date=2024-01-15

# Response: OK
```

#### Insert Multiple Rows

```bash
# Insert row 1
redis-cli TABLE.INSERT myapp.users \
  user_id=1 email=john@example.com name=John age=30

# Insert row 2
redis-cli TABLE.INSERT myapp.users \
  user_id=2 email=jane@example.com name=Jane age=25

# Insert row 3
redis-cli TABLE.INSERT myapp.users \
  user_id=3 email=bob@example.com name=Bob age=35
```

#### Data Type Examples

```bash
# String values
redis-cli TABLE.INSERT myapp.users name="John Doe" email=john@example.com

# Integer values
redis-cli TABLE.INSERT myapp.users user_id=123 age=30

# Float values
redis-cli TABLE.INSERT ecommerce.products price=99.99 discount=0.15

# Date values (YYYY-MM-DD format)
redis-cli TABLE.INSERT myapp.users created_date=2024-01-15
```

### Update Data

#### Basic Update

```bash
# Update with WHERE clause
redis-cli TABLE.UPDATE myapp.users WHERE user_id=1 SET age=31

# Response: (integer) 1  (number of rows updated)
```

#### Update Multiple Columns

```bash
# Update multiple columns
redis-cli TABLE.UPDATE myapp.users WHERE user_id=1 \
  SET age=31 name="John Smith"
```

#### Update Multiple Rows

```bash
# Update all users over 30
redis-cli TABLE.UPDATE myapp.users WHERE age>30 SET status=senior

# Update by category
redis-cli TABLE.UPDATE ecommerce.products WHERE category=Electronics \
  SET discount=0.10
```

### Delete Data

#### Basic Delete

```bash
# Delete specific row
redis-cli TABLE.DELETE myapp.users WHERE user_id=1

# Response: (integer) 1  (number of rows deleted)
```

#### Delete Multiple Rows

```bash
# Delete all users under 18
redis-cli TABLE.DELETE myapp.users WHERE age<18

# Delete by status
redis-cli TABLE.DELETE ecommerce.orders WHERE status=cancelled
```

#### Delete All Rows

```bash
# Delete all rows (use with caution!)
redis-cli TABLE.DELETE myapp.users

# Response: (integer) N  (total rows deleted)
```

**⚠️ Warning**: DELETE without WHERE clause deletes ALL rows.

---

## Querying Data

### Select All Rows

```bash
# Select all rows
redis-cli TABLE.SELECT myapp.users

# Response:
# 1) "user_id:1|email:john@example.com|name:John|age:30"
# 2) "user_id:2|email:jane@example.com|name:Jane|age:25"
# 3) "user_id:3|email:bob@example.com|name:Bob|age:35"
```

### Equality Queries

```bash
# Query by indexed column (fast - O(1))
redis-cli TABLE.SELECT myapp.users WHERE user_id=1

# Query by email
redis-cli TABLE.SELECT myapp.users WHERE email=john@example.com

# Query by category
redis-cli TABLE.SELECT ecommerce.products WHERE category=Electronics
```

### Comparison Queries

```bash
# Greater than
redis-cli TABLE.SELECT myapp.users WHERE age>30

# Less than
redis-cli TABLE.SELECT ecommerce.products WHERE price<100

# Greater or equal
redis-cli TABLE.SELECT myapp.users WHERE age>=25

# Less or equal
redis-cli TABLE.SELECT ecommerce.products WHERE stock<=10
```

**⚠️ Note**: Comparison operators require full table scan (up to scan limit).

### Logical Operators

#### AND Operator

```bash
# Both conditions must match
redis-cli TABLE.SELECT myapp.users WHERE age>25 AND age<35

# Multiple AND conditions
redis-cli TABLE.SELECT ecommerce.products \
  WHERE category=Electronics AND price<1000 AND stock>0
```

#### OR Operator

```bash
# Either condition matches
redis-cli TABLE.SELECT myapp.users WHERE age<20 OR age>60

# Multiple OR conditions
redis-cli TABLE.SELECT ecommerce.products \
  WHERE category=Electronics OR category=Computers OR category=Phones
```

#### Combined AND/OR

```bash
# Complex conditions
redis-cli TABLE.SELECT ecommerce.products \
  WHERE category=Electronics AND price>100 OR category=Computers AND price>500
```

**⚠️ Note**: Operator precedence is left-to-right. Use parentheses in application logic if needed.

---

## Index Management

### Why Index?

```bash
# ✅ FAST: Indexed equality query (O(1))
redis-cli TABLE.SELECT myapp.users WHERE user_id=123
# Uses hash index, instant lookup

# ❌ SLOW: Non-indexed query (O(n))
redis-cli TABLE.SELECT myapp.users WHERE age=30
# Full table scan, checks every row
```

### When to Index

**✅ Index these columns:**
- Primary keys (user_id, product_id, order_id)
- Foreign keys (customer_id, product_id in orders)
- Frequently queried columns (email, username, sku)
- Status/category columns used in filters

**❌ Don't index these columns:**
- Rarely queried columns (notes, description, bio)
- High-cardinality text (full text, long descriptions)
- Columns only used in SELECT (not in WHERE)

### Index Performance

| Query Type | Indexed | Non-Indexed |
|------------|---------|-------------|
| Equality (=) | O(1) - Instant | O(n) - Full scan |
| Comparison (>, <) | O(n) - Full scan | O(n) - Full scan |
| Range (BETWEEN) | O(n) - Full scan | O(n) - Full scan |

### Adding Indexes

```bash
# Add index during table creation
redis-cli TABLE.SCHEMA.CREATE myapp.users \
  user_id:integer:hash \
  email:string:hash

# Add index to existing table
redis-cli TABLE.SCHEMA.ALTER myapp.users ADD INDEX email:hash
```

### Removing Indexes

```bash
# Remove index (use during maintenance windows)
redis-cli TABLE.SCHEMA.ALTER myapp.users DROP INDEX email
```

**⚠️ Warning**: DROP INDEX has a race condition. See [PRODUCTION_NOTES.md](PRODUCTION_NOTES.md).

---

## Examples

### Example 1: User Management System

```bash
# 1. Create namespace
redis-cli TABLE.NAMESPACE.CREATE userapp

# 2. Create users table
redis-cli TABLE.SCHEMA.CREATE userapp.users \
  user_id:integer:hash \
  username:string:hash \
  email:string:hash \
  full_name:string:none \
  age:integer:none \
  country:string:hash \
  created_date:date:none \
  status:string:hash

# 3. Insert users
redis-cli TABLE.INSERT userapp.users \
  user_id=1 username=alice email=alice@example.com \
  full_name="Alice Johnson" age=28 country=USA \
  created_date=2024-01-15 status=active

redis-cli TABLE.INSERT userapp.users \
  user_id=2 username=bob email=bob@example.com \
  full_name="Bob Smith" age=35 country=UK \
  created_date=2024-02-20 status=active

redis-cli TABLE.INSERT userapp.users \
  user_id=3 username=charlie email=charlie@example.com \
  full_name="Charlie Brown" age=22 country=Canada \
  created_date=2024-03-10 status=inactive

# 4. Query users
# Find by username
redis-cli TABLE.SELECT userapp.users WHERE username=alice

# Find by email
redis-cli TABLE.SELECT userapp.users WHERE email=bob@example.com

# Find active users
redis-cli TABLE.SELECT userapp.users WHERE status=active

# Find users by country
redis-cli TABLE.SELECT userapp.users WHERE country=USA

# Find young users
redis-cli TABLE.SELECT userapp.users WHERE age<30

# Find recent users
redis-cli TABLE.SELECT userapp.users WHERE created_date>2024-02-01

# 5. Update user
redis-cli TABLE.UPDATE userapp.users WHERE user_id=1 SET age=29

# 6. Delete inactive users
redis-cli TABLE.DELETE userapp.users WHERE status=inactive
```

### Example 2: E-commerce Product Catalog

```bash
# 1. Create namespace
redis-cli TABLE.NAMESPACE.CREATE ecommerce

# 2. Create products table
redis-cli TABLE.SCHEMA.CREATE ecommerce.products \
  product_id:integer:hash \
  sku:string:hash \
  name:string:none \
  description:string:none \
  price:float:none \
  cost:float:none \
  stock:integer:none \
  category:string:hash \
  brand:string:hash \
  status:string:hash

# 3. Insert products
redis-cli TABLE.INSERT ecommerce.products \
  product_id=101 sku=LAPTOP-001 name="Gaming Laptop" \
  description="High-performance gaming laptop" \
  price=1299.99 cost=899.00 stock=50 \
  category=Electronics brand=TechBrand status=active

redis-cli TABLE.INSERT ecommerce.products \
  product_id=102 sku=MOUSE-001 name="Wireless Mouse" \
  description="Ergonomic wireless mouse" \
  price=29.99 cost=15.00 stock=200 \
  category=Accessories brand=TechBrand status=active

redis-cli TABLE.INSERT ecommerce.products \
  product_id=103 sku=DESK-001 name="Standing Desk" \
  description="Adjustable standing desk" \
  price=499.99 cost=299.00 stock=25 \
  category=Furniture brand=OfficePro status=active

# 4. Query products
# Find by SKU
redis-cli TABLE.SELECT ecommerce.products WHERE sku=LAPTOP-001

# Find by category
redis-cli TABLE.SELECT ecommerce.products WHERE category=Electronics

# Find by brand
redis-cli TABLE.SELECT ecommerce.products WHERE brand=TechBrand

# Find expensive products
redis-cli TABLE.SELECT ecommerce.products WHERE price>500

# Find low stock items
redis-cli TABLE.SELECT ecommerce.products WHERE stock<30

# Find products by category and price
redis-cli TABLE.SELECT ecommerce.products \
  WHERE category=Electronics AND price<1000

# 5. Update product
# Update price
redis-cli TABLE.UPDATE ecommerce.products WHERE product_id=101 \
  SET price=1199.99

# Update stock
redis-cli TABLE.UPDATE ecommerce.products WHERE sku=MOUSE-001 \
  SET stock=180

# Discount all furniture
redis-cli TABLE.UPDATE ecommerce.products WHERE category=Furniture \
  SET price=449.99

# 6. Delete discontinued products
redis-cli TABLE.DELETE ecommerce.products WHERE status=discontinued
```

### Example 3: Order Management

```bash
# 1. Create orders table
redis-cli TABLE.SCHEMA.CREATE ecommerce.orders \
  order_id:integer:hash \
  customer_id:integer:hash \
  product_id:integer:hash \
  quantity:integer:none \
  unit_price:float:none \
  total:float:none \
  order_date:date:none \
  status:string:hash

# 2. Insert orders
redis-cli TABLE.INSERT ecommerce.orders \
  order_id=1001 customer_id=1 product_id=101 \
  quantity=1 unit_price=1299.99 total=1299.99 \
  order_date=2024-10-01 status=completed

redis-cli TABLE.INSERT ecommerce.orders \
  order_id=1002 customer_id=2 product_id=102 \
  quantity=2 unit_price=29.99 total=59.98 \
  order_date=2024-10-05 status=shipped

redis-cli TABLE.INSERT ecommerce.orders \
  order_id=1003 customer_id=1 product_id=103 \
  quantity=1 unit_price=499.99 total=499.99 \
  order_date=2024-10-10 status=pending

# 3. Query orders
# Find customer orders
redis-cli TABLE.SELECT ecommerce.orders WHERE customer_id=1

# Find by status
redis-cli TABLE.SELECT ecommerce.orders WHERE status=pending

# Find recent orders
redis-cli TABLE.SELECT ecommerce.orders WHERE order_date>2024-10-01

# Find large orders
redis-cli TABLE.SELECT ecommerce.orders WHERE total>1000

# 4. Update order status
redis-cli TABLE.UPDATE ecommerce.orders WHERE order_id=1003 \
  SET status=shipped

# 5. Cancel orders
redis-cli TABLE.DELETE ecommerce.orders WHERE status=cancelled
```

---

## Best Practices

### 1. Namespace Organization

```bash
# ✅ DO: Organize by application/domain
TABLE.NAMESPACE.CREATE userapp
TABLE.NAMESPACE.CREATE ecommerce
TABLE.NAMESPACE.CREATE analytics

# ❌ DON'T: Use generic names
TABLE.NAMESPACE.CREATE data
TABLE.NAMESPACE.CREATE tables
```

### 2. Table Naming

```bash
# ✅ DO: Use descriptive names
TABLE.SCHEMA.CREATE myapp.users
TABLE.SCHEMA.CREATE myapp.products
TABLE.SCHEMA.CREATE myapp.orders

# ❌ DON'T: Use abbreviations
TABLE.SCHEMA.CREATE myapp.usr
TABLE.SCHEMA.CREATE myapp.prod
```

### 3. Column Naming

```bash
# ✅ DO: Use clear, consistent names
user_id, email, created_date, first_name

# ❌ DON'T: Use unclear abbreviations
uid, em, dt, fn
```

### 4. Indexing Strategy

```bash
# ✅ DO: Index primary keys and frequently queried columns
TABLE.SCHEMA.CREATE myapp.users \
  user_id:integer:hash \
  email:string:hash \
  name:string:none

# ❌ DON'T: Index everything
TABLE.SCHEMA.CREATE myapp.users \
  user_id:integer:hash \
  email:string:hash \
  name:string:hash \
  bio:string:hash \
  notes:string:hash
```

### 5. Query Optimization

```bash
# ✅ DO: Use equality on indexed columns
TABLE.SELECT users WHERE user_id=123

# ⚠️ AVOID: Comparisons on non-indexed columns
TABLE.SELECT users WHERE age>30

# ✅ BETTER: Add index if frequently queried
TABLE.SCHEMA.ALTER users ADD INDEX age:hash
TABLE.SELECT users WHERE age=30
```

### 6. Schema Changes

```bash
# ✅ DO: Test in staging first
# ✅ DO: Run during maintenance windows
# ✅ DO: Document changes
# ✅ DO: Monitor after changes

# ❌ DON'T: Change schema during peak hours
# ❌ DON'T: Drop indexes without planning
```

### 7. Data Validation

```bash
# ✅ DO: Validate data in application
# - Check required fields
# - Validate data types
# - Enforce constraints

# ❌ DON'T: Rely on Redis for validation
# - No foreign key constraints
# - No unique constraints (except via application logic)
```

### 8. Error Handling

```python
# ✅ DO: Handle errors gracefully
try:
    result = redis.execute_command('TABLE.SELECT', 'users', 'WHERE', 'user_id=123')
except redis.ResponseError as e:
    if 'does not exist' in str(e):
        # Handle missing table
        pass
    elif 'scan limit exceeded' in str(e):
        # Handle scan limit
        pass
    else:
        # Handle other errors
        raise
```

---

## Limitations

### Query Limitations
- Comparison operators (>, <, >=, <=) require full table scan
- Scan limit applies (default 100K rows, configurable)
- No JOIN operations
- No GROUP BY or aggregations
- No ORDER BY (results unordered)

### Data Constraints
- Maximum 64 characters for namespace/table names
- Date format: YYYY-MM-DD only
- Float precision limited by string conversion
- No NULL values (use empty string or omit column)

### Schema Limitations
- No foreign key constraints
- No unique constraints (enforce in application)
- No default values
- No auto-increment (manage in application)

---

## Troubleshooting

### Error: "namespace does not exist"

```bash
# Create namespace first
redis-cli TABLE.NAMESPACE.CREATE myapp
```

### Error: "table schema does not exist"

```bash
# Create table first
redis-cli TABLE.SCHEMA.CREATE myapp.users user_id:integer:hash
```

### Error: "search cannot be done on non-indexed column"

```bash
# Add index to column
redis-cli TABLE.SCHEMA.ALTER myapp.users ADD INDEX age:hash

# Or use comparison operator (full scan)
redis-cli TABLE.SELECT myapp.users WHERE age>30
```

### Error: "query scan limit exceeded"

```bash
# Increase scan limit when loading module
redis-server --loadmodule ./redistable.so max_scan_limit 200000

# Or add more indexes to avoid full scans
```

---

**Document Version**: 1.0.0  
**Module Version**: 1.0.0  
**Last Updated**: October 2025
