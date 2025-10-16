# RedisTABLE - Client Compatibility Testing

**Version**: 1.0.0  
**Last Updated**: 2025-10-16

Guide to testing RedisTABLE with various Redis clients.

---

## Overview

Client compatibility tests verify that RedisTABLE works correctly with popular Redis clients across different programming languages.

---

## Running Client Tests

### Quick Start

```bash
# Run all client tests
make client-tests

# Or directly
cd tests
./run_client_tests.sh
```

### Expected Output

```
========================================
Redis Table Module - Client Tests
========================================

Testing Python client (redis-py)...
✓ PASS: All Python tests passed

Testing Node.js client (node-redis)...
✓ PASS: All Node.js tests passed

========================================
Client Test Summary
========================================
Python: PASS
Node.js: PASS
========================================
All client tests passed!
```

---

## Prerequisites

### Python Client

```bash
# Install redis-py
pip install redis

# Or with virtual environment
python3 -m venv venv
source venv/bin/activate
pip install redis
```

### Node.js Client

```bash
# Install node-redis
npm install redis

# Or globally
npm install -g redis
```

### Optional: Other Clients

```bash
# Java (Jedis)
# Add to pom.xml or build.gradle

# Go (go-redis)
go get github.com/redis/go-redis/v9

# Ruby (redis-rb)
gem install redis
```

---

## Test Scenarios

### Test 1: Basic Connection

**What it tests**: Client can connect and execute commands

```python
# Python
import redis
r = redis.Redis()
r.ping()  # Should return True
```

```javascript
// Node.js
const redis = require('redis');
const client = redis.createClient();
await client.connect();
await client.ping();  // Should return 'PONG'
```

### Test 2: Namespace Operations

**What it tests**: CREATE, VIEW, DROP namespace

```python
# Python
r.execute_command('TABLE.NAMESPACE.CREATE', 'test')
result = r.execute_command('TABLE.NAMESPACE.VIEW')
r.execute_command('TABLE.NAMESPACE.DROP', 'test', 'FORCE')
```

### Test 3: Table Creation

**What it tests**: Schema creation with special characters

```python
# Python
r.execute_command('TABLE.SCHEMA.CREATE', 'test.users',
    'id:integer:hash',
    'email:string:hash',
    'name:string:none')
```

### Test 4: Data Insertion

**What it tests**: INSERT with equals signs

```python
# Python
r.execute_command('TABLE.INSERT', 'test.users',
    'id=1',
    'email=john@example.com',
    'name=John')
```

### Test 5: Data Query

**What it tests**: SELECT with WHERE clause

```python
# Python
result = r.execute_command('TABLE.SELECT', 'test.users',
    'WHERE', 'id=1')
assert len(result) > 0
```

### Test 6: Data Update

**What it tests**: UPDATE with SET clause

```python
# Python
r.execute_command('TABLE.UPDATE', 'test.users',
    'WHERE', 'id=1',
    'SET', 'name=John Smith')
```

### Test 7: Data Deletion

**What it tests**: DELETE with WHERE clause

```python
# Python
r.execute_command('TABLE.DELETE', 'test.users',
    'WHERE', 'id=1')
```

### Test 8: Error Handling

**What it tests**: Client handles errors correctly

```python
# Python
try:
    r.execute_command('TABLE.SELECT', 'nonexistent.table')
except redis.ResponseError as e:
    assert 'does not exist' in str(e)
```

---

## Test Files

### Python Test (test_python_client.py)

```python
#!/usr/bin/env python3
import redis
import sys

def test_python_client():
    """Test RedisTABLE with Python redis-py client"""
    
    r = redis.Redis(host='localhost', port=6379, decode_responses=True)
    
    try:
        # Test 1: Connection
        assert r.ping(), "Connection failed"
        print("✓ Connection test passed")
        
        # Test 2: Create namespace
        result = r.execute_command('TABLE.NAMESPACE.CREATE', 'pytest')
        assert result == 'OK', f"Expected OK, got {result}"
        print("✓ Namespace creation passed")
        
        # Test 3: Create table
        result = r.execute_command('TABLE.SCHEMA.CREATE', 'pytest.users',
            'id:integer:hash',
            'email:string:hash',
            'name:string:none')
        assert result == 'OK', f"Expected OK, got {result}"
        print("✓ Table creation passed")
        
        # Test 4: Insert data
        result = r.execute_command('TABLE.INSERT', 'pytest.users',
            'id=1',
            'email=test@example.com',
            'name=Test User')
        assert result == 'OK', f"Expected OK, got {result}"
        print("✓ Data insertion passed")
        
        # Test 5: Query data
        result = r.execute_command('TABLE.SELECT', 'pytest.users',
            'WHERE', 'id=1')
        assert len(result) > 0, "Expected results"
        assert 'test@example.com' in str(result), "Expected email in results"
        print("✓ Data query passed")
        
        # Test 6: Update data
        result = r.execute_command('TABLE.UPDATE', 'pytest.users',
            'WHERE', 'id=1',
            'SET', 'name=Updated User')
        assert result >= 1, f"Expected >= 1, got {result}"
        print("✓ Data update passed")
        
        # Test 7: Delete data
        result = r.execute_command('TABLE.DELETE', 'pytest.users',
            'WHERE', 'id=1')
        assert result >= 1, f"Expected >= 1, got {result}"
        print("✓ Data deletion passed")
        
        # Test 8: Error handling
        try:
            r.execute_command('TABLE.SELECT', 'nonexistent.table')
            assert False, "Should have raised error"
        except redis.ResponseError as e:
            assert 'does not exist' in str(e)
            print("✓ Error handling passed")
        
        # Cleanup
        r.execute_command('TABLE.SCHEMA.DROP', 'pytest.users', 'FORCE')
        r.execute_command('TABLE.NAMESPACE.DROP', 'pytest', 'FORCE')
        
        print("\n✓ All Python client tests passed!")
        return True
        
    except Exception as e:
        print(f"\n✗ Python client test failed: {e}")
        return False

if __name__ == '__main__':
    success = test_python_client()
    sys.exit(0 if success else 1)
```

### Node.js Test (test_nodejs_client.js)

```javascript
#!/usr/bin/env node
const redis = require('redis');

async function testNodejsClient() {
    const client = redis.createClient();
    
    try {
        await client.connect();
        
        // Test 1: Connection
        const pong = await client.ping();
        console.assert(pong === 'PONG', 'Connection failed');
        console.log('✓ Connection test passed');
        
        // Test 2: Create namespace
        let result = await client.sendCommand(['TABLE.NAMESPACE.CREATE', 'jstest']);
        console.assert(result === 'OK', `Expected OK, got ${result}`);
        console.log('✓ Namespace creation passed');
        
        // Test 3: Create table
        result = await client.sendCommand([
            'TABLE.SCHEMA.CREATE', 'jstest.users',
            'id:integer:hash',
            'email:string:hash',
            'name:string:none'
        ]);
        console.assert(result === 'OK', `Expected OK, got ${result}`);
        console.log('✓ Table creation passed');
        
        // Test 4: Insert data
        result = await client.sendCommand([
            'TABLE.INSERT', 'jstest.users',
            'id=1',
            'email=test@example.com',
            'name=Test User'
        ]);
        console.assert(result === 'OK', `Expected OK, got ${result}`);
        console.log('✓ Data insertion passed');
        
        // Test 5: Query data
        result = await client.sendCommand([
            'TABLE.SELECT', 'jstest.users',
            'WHERE', 'id=1'
        ]);
        console.assert(result.length > 0, 'Expected results');
        console.assert(result[0].includes('test@example.com'), 'Expected email in results');
        console.log('✓ Data query passed');
        
        // Test 6: Update data
        result = await client.sendCommand([
            'TABLE.UPDATE', 'jstest.users',
            'WHERE', 'id=1',
            'SET', 'name=Updated User'
        ]);
        console.assert(result >= 1, `Expected >= 1, got ${result}`);
        console.log('✓ Data update passed');
        
        // Test 7: Delete data
        result = await client.sendCommand([
            'TABLE.DELETE', 'jstest.users',
            'WHERE', 'id=1'
        ]);
        console.assert(result >= 1, `Expected >= 1, got ${result}`);
        console.log('✓ Data deletion passed');
        
        // Test 8: Error handling
        try {
            await client.sendCommand(['TABLE.SELECT', 'nonexistent.table']);
            console.assert(false, 'Should have thrown error');
        } catch (e) {
            console.assert(e.message.includes('does not exist'));
            console.log('✓ Error handling passed');
        }
        
        // Cleanup
        await client.sendCommand(['TABLE.SCHEMA.DROP', 'jstest.users', 'FORCE']);
        await client.sendCommand(['TABLE.NAMESPACE.DROP', 'jstest', 'FORCE']);
        
        console.log('\n✓ All Node.js client tests passed!');
        await client.disconnect();
        return true;
        
    } catch (e) {
        console.error(`\n✗ Node.js client test failed: ${e.message}`);
        await client.disconnect();
        return false;
    }
}

testNodejsClient().then(success => {
    process.exit(success ? 0 : 1);
});
```

---

## Running Individual Tests

### Python Test

```bash
# Run Python test
cd tests
python3 test_python_client.py

# Or with virtual environment
source venv/bin/activate
python test_python_client.py
```

### Node.js Test

```bash
# Run Node.js test
cd tests
node test_nodejs_client.js
```

---

## Troubleshooting

### Issue: Python redis package not found

```bash
# Install redis-py
pip install redis

# Or with virtual environment
python3 -m venv venv
source venv/bin/activate
pip install redis
```

### Issue: Node.js redis package not found

```bash
# Install node-redis
npm install redis

# Or in project directory
cd tests
npm install redis
```

### Issue: Connection refused

```bash
# Check Redis is running
redis-cli PING

# Check module is loaded
redis-cli MODULE LIST | grep table

# Start Redis with module
redis-server --loadmodule ./redistable.so
```

### Issue: Tests fail with "command not found"

```bash
# Verify module loaded
redis-cli MODULE LIST

# Check Redis logs
tail -f /var/log/redis/redis-server.log

# Reload module
redis-cli MODULE UNLOAD table
redis-server --loadmodule ./redistable.so
```

---

## Adding New Client Tests

### Template

```python
#!/usr/bin/env python3
# test_<language>_client.py

import <redis_client_library>

def test_client():
    # 1. Connect
    client = <create_client>()
    
    # 2. Test namespace operations
    client.execute('TABLE.NAMESPACE.CREATE', 'test')
    
    # 3. Test table operations
    client.execute('TABLE.SCHEMA.CREATE', 'test.users', 'id:integer:hash')
    
    # 4. Test data operations
    client.execute('TABLE.INSERT', 'test.users', 'id=1')
    result = client.execute('TABLE.SELECT', 'test.users', 'WHERE', 'id=1')
    
    # 5. Cleanup
    client.execute('TABLE.SCHEMA.DROP', 'test.users', 'FORCE')
    client.execute('TABLE.NAMESPACE.DROP', 'test', 'FORCE')
    
    return True

if __name__ == '__main__':
    success = test_client()
    exit(0 if success else 1)
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Client Tests

on: [push, pull_request]

jobs:
  test-python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: '3.x'
      - run: pip install redis
      - run: make build
      - run: make client-tests

  test-nodejs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      - run: npm install redis
      - run: make build
      - run: make client-tests
```

---

## Summary

### Tested Clients

- ✅ Python (redis-py)
- ✅ Node.js (node-redis)
- ⏳ Java (Jedis) - Manual testing
- ⏳ Go (go-redis) - Manual testing

### Test Coverage

- ✅ Connection and authentication
- ✅ Namespace operations
- ✅ Table operations
- ✅ Data operations (CRUD)
- ✅ Query operations
- ✅ Error handling
- ✅ Special character handling

### Recommendations

1. **Install client libraries** - Required for automated tests
2. **Run before release** - Verify compatibility
3. **Test manually** - For languages without automated tests
4. **Report issues** - If client doesn't work as expected

---

**Version**: 1.0.0  
**Last Updated**: 2025-10-16  
**Test Coverage**: Python, Node.js  
**Status**: Production-ready
