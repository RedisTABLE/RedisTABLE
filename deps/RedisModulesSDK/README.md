# Redis Modules SDK

This directory contains the Redis Module API header file, bundled with RedisTABLE for self-contained builds.

## Contents

- **redismodule.h** - Redis Module API header file

## Purpose

Following the approach used by other Redis modules, RedisTABLE bundles the Redis Module SDK to provide:

1. **Self-contained builds** - No need to specify external Redis source path
2. **Version control** - Ensures compatibility with a specific Redis API version
3. **Portability** - Build anywhere without Redis source dependencies
4. **CI/CD friendly** - Simplified build configuration

## Usage

The Makefile automatically includes this directory in the compiler's include path:

```makefile
REDIS_MODULE_SDK := $(ROOT)/deps/RedisModulesSDK
REDIS_SRC ?= $(REDIS_MODULE_SDK)
CFLAGS += -I$(REDIS_SRC)
```

When `redis_table.c` includes:
```c
#include "redismodule.h"
```

The compiler finds it at: `deps/RedisModulesSDK/redismodule.h`

## Overriding the SDK

If you need to use a different version of `redismodule.h`, you can override it:

```bash
make build REDIS_SRC=/path/to/redis/src
```

This is useful for:
- Testing with different Redis versions
- Using bleeding-edge Redis features
- Debugging compatibility issues

## Updating the SDK

To update to a newer version of `redismodule.h`:

```bash
# Copy from your Redis installation
cp /path/to/redis/src/redismodule.h deps/RedisModulesSDK/

# Or download from Redis repository
wget https://raw.githubusercontent.com/redis/redis/unstable/src/redismodule.h \
     -O deps/RedisModulesSDK/redismodule.h
```

## Version Information

The bundled `redismodule.h` is compatible with Redis 7.0+.

To check the API version:
```bash
grep "REDISMODULE_APIVER" deps/RedisModulesSDK/redismodule.h
```

## References

- [Redis Modules Documentation](https://redis.io/docs/reference/modules/)
- [Redis Module API Reference](https://redis.io/docs/reference/modules/modules-api-ref/)
- [RedisBloom SDK Approach](https://github.com/redisbloom/redisbloom/tree/master/deps/RedisModulesSDK)

## License

The `redismodule.h` file is part of Redis and is licensed under the BSD 3-Clause License.
See: https://github.com/redis/redis/blob/unstable/COPYING
