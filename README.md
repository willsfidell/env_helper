# ENV File Processor

This repository contains a script provide functionality to compare and format `.env` files.

## Features

- Compare two `.env` files to find:
  - Keys unique to each file
  - Keys with different values between files
- Format `.env` files with:
  - Alphabetically sorted keys
  - Grouped by prefix (determined by text before underscore or full key if no underscore)
  - Preserved comments associated with their variables
  - Blank lines between different prefix groups

## Implementation

Usage:
```bash
# Compare two .env files
./env_helper.py -c file1.env file2.env

# Format an .env file
./env_helper.py -f file.env
```

## Example

Given this input file (`test1.env`):
```env
# Database configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp
DB_USER=admin
DB_PASSWORD=secret123

# API configuration
API_KEY=abcdef123456
API_URL=https://api.example.com
API_VERSION=v1

# Redis configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# Application settings
APP_NAME=MyApp
APP_ENV=development
APP_DEBUG=true
```

The format command (`-f`) will output:
```env
# API configuration
API_KEY=abcdef123456
API_URL=https://api.example.com
API_VERSION=v1

APP_DEBUG=true
APP_ENV=development
# Application settings
APP_NAME=MyApp

# Database configuration
DB_HOST=localhost
DB_NAME=myapp
DB_PASSWORD=secret123
DB_PORT=5432
DB_USER=admin

# Redis configuration
REDIS_HOST=localhost
REDIS_PORT=6379
```

When comparing two files using the compare command (`-c`), you'll see output like:
```
=== Keys unique to file1.env ===
APP_DEBUG
REDIS_HOST
REDIS_PORT

=== Keys unique to file2.env ===
APP_PORT

=== Keys with different values ===
API_KEY:
  file1.env: abcdef123456
  file2.env: xyz789
DB_HOST:
  file1.env: localhost
  file2.env: 127.0.0.1
```

## License

This project is licensed under the MIT License - see below for details:

```
MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
