# RedisTABLE - Client Compatibility Guide

**Version**: 1.0.0  
**Last Updated**: 2025-10-16

Guide to using RedisTABLE with various Redis clients.

---

## Overview

RedisTABLE uses **custom command syntax** with special characters (colons, equals, dots). This guide shows how to properly use the module with popular Redis clients following Redis conventions.

---

## Key Principles

### Redis Command Convention

All Redis commands follow this pattern:
```
COMMAND arg1 arg2 arg3 ...
```

### RedisTABLE Commands

```bash
# Namespace commands
TABLE.NAMESPACE.CREATE myapp
TABLE.NAMESPACE.VIEW
TABLE.NAMESPACE.DROP myapp FORCE

# Schema commands
TABLE.SCHEMA.CREATE myapp.users col1:type:index col2:type:index
TABLE.SCHEMA.VIEW myapp.users
TABLE.SCHEMA.ALTER myapp.users ADD COLUMN col:type:index
TABLE.SCHEMA.DROP myapp.users FORCE

# Data commands
TABLE.INSERT myapp.users col1=val1 col2=val2
TABLE.SELECT myapp.users WHERE conditions
TABLE.UPDATE myapp.users WHERE conditions SET col1=val1
TABLE.DELETE myapp.users WHERE conditions
```

### Special Characters

| Character | Usage | Example |
|-----------|-------|---------|
| `.` (dot) | Namespace.table separator | `myapp.users` |
| `:` (colon) | Column definition | `age:integer:hash` |
| `=` (equals) | Value assignment | `age=30` |
| `>`, `<`, `>=`, `<=` | Comparison operators | `age>30` |

---

## Python (redis-py)

### Installation

```bash
pip install redis
```

### Basic Usage

```python
import redis

# Connect to Redis
r = redis.Redis(host='localhost', port=6379, decode_responses=True)

# Create namespace
r.execute_command('TABLE.NAMESPACE.CREATE', 'myapp')

# Create table
r.execute_command('TABLE.SCHEMA.CREATE', 'myapp.users',
    'user_id:integer:hash',
    'email:string:hash',
    'name:string:none',
    'age:integer:none')

# Insert data
r.execute_command('TABLE.INSERT', 'myapp.users',
    'user_id=1',
    'email=john@example.com',
    'name=John',
    'age=30')

# Query data
result = r.execute_command('TABLE.SELECT', 'myapp.users', 'WHERE', 'user_id=1')
print(result)

# Update data
r.execute_command('TABLE.UPDATE', 'myapp.users',
    'WHERE', 'user_id=1',
    'SET', 'age=31')

# Delete data
r.execute_command('TABLE.DELETE', 'myapp.users', 'WHERE', 'user_id=1')
```

### Helper Functions

```python
class RedisTable:
    def __init__(self, redis_client):
        self.redis = redis_client
    
    def create_namespace(self, namespace):
        return self.redis.execute_command('TABLE.NAMESPACE.CREATE', namespace)
    
    def create_table(self, table, **columns):
        """
        Example: create_table('myapp.users',
                             user_id='integer:hash',
                             email='string:hash',
                             name='string:none')
        """
        cols = [f'{k}:{v}' for k, v in columns.items()]
        return self.redis.execute_command('TABLE.SCHEMA.CREATE', table, *cols)
    
    def insert(self, table, **values):
        """
        Example: insert('myapp.users',
                       user_id=1,
                       email='john@example.com',
                       name='John')
        """
        vals = [f'{k}={v}' for k, v in values.items()]
        return self.redis.execute_command('TABLE.INSERT', table, *vals)
    
    def select(self, table, where=None):
        """
        Example: select('myapp.users', where='user_id=1')
        """
        if where:
            return self.redis.execute_command('TABLE.SELECT', table, 'WHERE', where)
        return self.redis.execute_command('TABLE.SELECT', table)
    
    def update(self, table, where, **values):
        """
        Example: update('myapp.users', where='user_id=1', age=31)
        """
        vals = [f'{k}={v}' for k, v in values.items()]
        return self.redis.execute_command('TABLE.UPDATE', table,
                                         'WHERE', where,
                                         'SET', *vals)
    
    def delete(self, table, where=None):
        """
        Example: delete('myapp.users', where='user_id=1')
        """
        if where:
            return self.redis.execute_command('TABLE.DELETE', table, 'WHERE', where)
        return self.redis.execute_command('TABLE.DELETE', table)

# Usage
r = redis.Redis(decode_responses=True)
table = RedisTable(r)

table.create_namespace('myapp')
table.create_table('myapp.users',
                  user_id='integer:hash',
                  email='string:hash',
                  name='string:none')
table.insert('myapp.users', user_id=1, email='john@example.com', name='John')
result = table.select('myapp.users', where='user_id=1')
```

---

## Node.js (node-redis)

### Installation

```bash
npm install redis
```

### Basic Usage

```javascript
const redis = require('redis');

(async () => {
    // Connect to Redis
    const client = redis.createClient();
    await client.connect();
    
    // Create namespace
    await client.sendCommand(['TABLE.NAMESPACE.CREATE', 'myapp']);
    
    // Create table
    await client.sendCommand([
        'TABLE.SCHEMA.CREATE', 'myapp.users',
        'user_id:integer:hash',
        'email:string:hash',
        'name:string:none',
        'age:integer:none'
    ]);
    
    // Insert data
    await client.sendCommand([
        'TABLE.INSERT', 'myapp.users',
        'user_id=1',
        'email=john@example.com',
        'name=John',
        'age=30'
    ]);
    
    // Query data
    const result = await client.sendCommand([
        'TABLE.SELECT', 'myapp.users',
        'WHERE', 'user_id=1'
    ]);
    console.log(result);
    
    // Update data
    await client.sendCommand([
        'TABLE.UPDATE', 'myapp.users',
        'WHERE', 'user_id=1',
        'SET', 'age=31'
    ]);
    
    // Delete data
    await client.sendCommand([
        'TABLE.DELETE', 'myapp.users',
        'WHERE', 'user_id=1'
    ]);
    
    await client.disconnect();
})();
```

### Helper Class

```javascript
class RedisTable {
    constructor(client) {
        this.client = client;
    }
    
    async createNamespace(namespace) {
        return await this.client.sendCommand(['TABLE.NAMESPACE.CREATE', namespace]);
    }
    
    async createTable(table, columns) {
        /**
         * Example: createTable('myapp.users', {
         *     user_id: 'integer:hash',
         *     email: 'string:hash',
         *     name: 'string:none'
         * })
         */
        const cols = Object.entries(columns).map(([k, v]) => `${k}:${v}`);
        return await this.client.sendCommand(['TABLE.SCHEMA.CREATE', table, ...cols]);
    }
    
    async insert(table, values) {
        /**
         * Example: insert('myapp.users', {
         *     user_id: 1,
         *     email: 'john@example.com',
         *     name: 'John'
         * })
         */
        const vals = Object.entries(values).map(([k, v]) => `${k}=${v}`);
        return await this.client.sendCommand(['TABLE.INSERT', table, ...vals]);
    }
    
    async select(table, where = null) {
        /**
         * Example: select('myapp.users', 'user_id=1')
         */
        if (where) {
            return await this.client.sendCommand(['TABLE.SELECT', table, 'WHERE', where]);
        }
        return await this.client.sendCommand(['TABLE.SELECT', table]);
    }
    
    async update(table, where, values) {
        /**
         * Example: update('myapp.users', 'user_id=1', { age: 31 })
         */
        const vals = Object.entries(values).map(([k, v]) => `${k}=${v}`);
        return await this.client.sendCommand([
            'TABLE.UPDATE', table,
            'WHERE', where,
            'SET', ...vals
        ]);
    }
    
    async delete(table, where = null) {
        /**
         * Example: delete('myapp.users', 'user_id=1')
         */
        if (where) {
            return await this.client.sendCommand(['TABLE.DELETE', table, 'WHERE', where]);
        }
        return await this.client.sendCommand(['TABLE.DELETE', table]);
    }
}

// Usage
(async () => {
    const client = redis.createClient();
    await client.connect();
    
    const table = new RedisTable(client);
    
    await table.createNamespace('myapp');
    await table.createTable('myapp.users', {
        user_id: 'integer:hash',
        email: 'string:hash',
        name: 'string:none'
    });
    await table.insert('myapp.users', {
        user_id: 1,
        email: 'john@example.com',
        name: 'John'
    });
    const result = await table.select('myapp.users', 'user_id=1');
    console.log(result);
    
    await client.disconnect();
})();
```

---

## redis-cli

### Basic Usage

```bash
# Create namespace
redis-cli TABLE.NAMESPACE.CREATE myapp

# Create table
redis-cli TABLE.SCHEMA.CREATE myapp.users \
  user_id:integer:hash \
  email:string:hash \
  name:string:none

# Insert data
redis-cli TABLE.INSERT myapp.users \
  user_id=1 \
  email=john@example.com \
  name=John

# Query data
redis-cli TABLE.SELECT myapp.users WHERE user_id=1

# Update data
redis-cli TABLE.UPDATE myapp.users WHERE user_id=1 SET age=31

# Delete data
redis-cli TABLE.DELETE myapp.users WHERE user_id=1
```

### Interactive Mode

```bash
redis-cli
127.0.0.1:6379> TABLE.NAMESPACE.CREATE myapp
OK
127.0.0.1:6379> TABLE.SCHEMA.CREATE myapp.users user_id:integer:hash email:string:hash
OK
127.0.0.1:6379> TABLE.INSERT myapp.users user_id=1 email=john@example.com
OK
127.0.0.1:6379> TABLE.SELECT myapp.users WHERE user_id=1
1) "user_id:1|email:john@example.com"
```

---

## Java (Jedis)

### Installation

```xml
<dependency>
    <groupId>redis.clients</groupId>
    <artifactId>jedis</artifactId>
    <version>5.0.0</version>
</dependency>
```

### Basic Usage

```java
import redis.clients.jedis.Jedis;

public class RedisTableExample {
    public static void main(String[] args) {
        try (Jedis jedis = new Jedis("localhost", 6379)) {
            // Create namespace
            jedis.sendCommand(() -> "TABLE.NAMESPACE.CREATE".getBytes(), "myapp".getBytes());
            
            // Create table
            jedis.sendCommand(() -> "TABLE.SCHEMA.CREATE".getBytes(),
                "myapp.users".getBytes(),
                "user_id:integer:hash".getBytes(),
                "email:string:hash".getBytes(),
                "name:string:none".getBytes());
            
            // Insert data
            jedis.sendCommand(() -> "TABLE.INSERT".getBytes(),
                "myapp.users".getBytes(),
                "user_id=1".getBytes(),
                "email=john@example.com".getBytes(),
                "name=John".getBytes());
            
            // Query data
            Object result = jedis.sendCommand(() -> "TABLE.SELECT".getBytes(),
                "myapp.users".getBytes(),
                "WHERE".getBytes(),
                "user_id=1".getBytes());
            System.out.println(result);
        }
    }
}
```

---

## Go (go-redis)

### Installation

```bash
go get github.com/redis/go-redis/v9
```

### Basic Usage

```go
package main

import (
    "context"
    "fmt"
    "github.com/redis/go-redis/v9"
)

func main() {
    ctx := context.Background()
    
    // Connect to Redis
    rdb := redis.NewClient(&redis.Options{
        Addr: "localhost:6379",
    })
    
    // Create namespace
    rdb.Do(ctx, "TABLE.NAMESPACE.CREATE", "myapp").Result()
    
    // Create table
    rdb.Do(ctx, "TABLE.SCHEMA.CREATE", "myapp.users",
        "user_id:integer:hash",
        "email:string:hash",
        "name:string:none").Result()
    
    // Insert data
    rdb.Do(ctx, "TABLE.INSERT", "myapp.users",
        "user_id=1",
        "email=john@example.com",
        "name=John").Result()
    
    // Query data
    result, err := rdb.Do(ctx, "TABLE.SELECT", "myapp.users",
        "WHERE", "user_id=1").Result()
    if err != nil {
        panic(err)
    }
    fmt.Println(result)
    
    // Update data
    rdb.Do(ctx, "TABLE.UPDATE", "myapp.users",
        "WHERE", "user_id=1",
        "SET", "age=31").Result()
    
    // Delete data
    rdb.Do(ctx, "TABLE.DELETE", "myapp.users",
        "WHERE", "user_id=1").Result()
}
```

---

## Common Patterns

### Pattern 1: Argument Passing

✅ **DO**: Pass arguments as separate array elements
```python
# Python
r.execute_command('TABLE.INSERT', 'users', 'id=1', 'name=John')

# Node.js
client.sendCommand(['TABLE.INSERT', 'users', 'id=1', 'name=John'])
```

❌ **DON'T**: Concatenate into single string
```python
# Python - WRONG
r.execute_command('TABLE.INSERT users id=1 name=John')

# Node.js - WRONG
client.sendCommand('TABLE.INSERT users id=1 name=John')
```

### Pattern 2: Special Characters

✅ **DO**: Keep special characters in arguments
```python
r.execute_command('TABLE.SCHEMA.CREATE', 'myapp.users', 'id:integer:hash')
```

❌ **DON'T**: Escape or modify special characters
```python
# WRONG
r.execute_command('TABLE.SCHEMA.CREATE', 'myapp.users', 'id\\:integer\\:hash')
```

### Pattern 3: WHERE Clauses

✅ **DO**: Pass WHERE as separate argument
```python
r.execute_command('TABLE.SELECT', 'users', 'WHERE', 'id=1')
```

❌ **DON'T**: Combine WHERE with condition
```python
# WRONG
r.execute_command('TABLE.SELECT', 'users', 'WHERE id=1')
```

---

## Testing Client Compatibility

### Test Script

```bash
# Run client compatibility tests
cd tests
./run_client_tests.sh
```

### Manual Testing

```python
# test_client.py
import redis

r = redis.Redis(decode_responses=True)

# Test 1: Create namespace
result = r.execute_command('TABLE.NAMESPACE.CREATE', 'test')
assert result == 'OK', f"Expected OK, got {result}"

# Test 2: Create table
result = r.execute_command('TABLE.SCHEMA.CREATE', 'test.users', 'id:integer:hash')
assert result == 'OK', f"Expected OK, got {result}"

# Test 3: Insert data
result = r.execute_command('TABLE.INSERT', 'test.users', 'id=1')
assert result == 'OK', f"Expected OK, got {result}"

# Test 4: Query data
result = r.execute_command('TABLE.SELECT', 'test.users', 'WHERE', 'id=1')
assert len(result) > 0, "Expected results"

# Cleanup
r.execute_command('TABLE.SCHEMA.DROP', 'test.users', 'FORCE')
r.execute_command('TABLE.NAMESPACE.DROP', 'test', 'FORCE')

print("All tests passed!")
```

---

## Verified Clients

The following clients have been verified to work correctly:

- ✅ **redis-cli** - All versions
- ✅ **redis-py** (Python) - 4.x, 5.x
- ✅ **node-redis** (Node.js) - 4.x
- ✅ **Jedis** (Java) - 5.x
- ✅ **go-redis** (Go) - 9.x

---

## Troubleshooting

### Issue: Command Not Found

```python
# Error: unknown command 'TABLE.NAMESPACE.CREATE'

# Solution: Check module is loaded
r.execute_command('MODULE', 'LIST')
```

### Issue: Arguments Not Parsed Correctly

```python
# Error: wrong number of arguments

# Check: Are you passing arguments as array?
# ✅ Correct
r.execute_command('TABLE.INSERT', 'users', 'id=1', 'name=John')

# ❌ Wrong
r.execute_command('TABLE.INSERT users id=1 name=John')
```

### Issue: Special Characters Causing Errors

```python
# Error: invalid syntax

# Check: Are special characters preserved?
# ✅ Correct
r.execute_command('TABLE.SCHEMA.CREATE', 'users', 'id:integer:hash')

# ❌ Wrong (escaped)
r.execute_command('TABLE.SCHEMA.CREATE', 'users', 'id\\:integer\\:hash')
```

---

## Best Practices

1. **Use execute_command / sendCommand** - Don't use high-level abstractions
2. **Pass arguments as array** - Each argument separate
3. **Preserve special characters** - Don't escape colons, equals, dots
4. **Handle errors** - Check for ResponseError / command errors
5. **Test thoroughly** - Verify commands work before production

---

**Version**: 1.0.0  
**Last Updated**: 2025-10-16  
**Status**: All major clients verified compatible
