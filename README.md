# Simple Drive

A Ruby on Rails API application that provides blob storage services with multiple storage backends.

## Features

- **Multiple Storage Backends**: Support for local filesystem, database, S3-compatible storage, and FTP
- **RESTful API**: Clean HTTP endpoints for blob operations
- **Bearer Token Authentication**: Secure access with token-based authentication
- **Base64 Support**: Store and retrieve binary data as Base64 encoded strings
- **Pagination**: Efficient blob listing with pagination support
- **Modern UI**: Smart dashboard interface with Tailwind CSS
- **Storage Selection**: Choose storage backend per blob when creating
- **SOLID Principles**: Well-structured code following software engineering best practices

## API Endpoints

### Authentication
- `POST /v1/auth/tokens` - Generate a new authentication token

### Blob Operations
- `GET /v1/blobs` - List all blobs (with pagination: ?page=1&per_page=10)
- `POST /v1/blobs` - Store a new blob (with storage backend selection: ?storage_backend=local|database|s3|ftp)
- `GET /v1/blobs/:id` - Retrieve a blob by ID
- `DELETE /v1/blobs/:id` - Delete a blob by ID

### Web UI
- `GET /` - Dashboard home page
- `GET /dashboard` - Dashboard interface
- `GET /v1/storage/backend` - Get current storage backend information

## Storage Backends

### 1. Local File System (Default)
Stores blobs as files in the local filesystem.

**Configuration:**
```yaml
backend: local
local:
  storage_path: /path/to/storage/directory
```

### 2. Database Storage
Stores blobs in a separate database table.

**Configuration:**
```yaml
backend: database
```

### 3. S3 Compatible Storage
Stores blobs using S3-compatible APIs (AWS S3, Minio, Digital Ocean Spaces, etc.).

**Configuration:**
```yaml
backend: s3
s3:
  endpoint: https://s3.amazonaws.com
  bucket: your-bucket-name
  access_key: your-access-key
  secret_key: your-secret-key
  region: us-east-2
```

### 4. FTP Storage
Stores blobs on an FTP server.

**Configuration:**
```yaml
backend: ftp
ftp:
  host: your-ftp-host.com
  username: your-username
  password: your-password
  port: 21
  remote_path: /blobs
  passive: true
```

## Quick Start

1. **Install Dependencies:**
   ```bash
   bundle install
   ```

2. **Setup Database:**
   ```bash
   rails db:create db:migrate
   ```

3. **Create `.env` file** (optional):
   Create a `.env` file in the project root with your storage credentials:
   ```bash
   # Example .env file
   S3_BUCKET=your-bucket-name
   S3_ACCESS_KEY=your-access-key
   S3_SECRET_KEY=your-secret-key
   S3_REGION=us-east-2
   S3_ENDPOINT=https://s3.us-east-2.amazonaws.com
   
   FTP_HOST=your-ftp-host.com
   FTP_USERNAME=your-username
   FTP_PASSWORD=your-password
   FTP_PORT=21
   FTP_REMOTE_PATH=/blobs
   ```

4. **Start the Server:**
   ```bash
   rails server
   ```

5. **Access the Dashboard:**
   Open your browser and go to `http://localhost:3000`

## Usage Examples

### 1. Generate Authentication Token
```bash
curl -X POST http://localhost:3000/v1/auth/tokens
```

### 2. Store a Blob
```bash
# Store with default backend (local)
curl -X POST http://localhost:3000/v1/blobs \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "my-blob-123",
    "data": "SGVsbG8gU2ltcGxlIFN0b3JhZ2UgV29ybGQh"
  }'

# Store with specific backend
curl -X POST "http://localhost:3000/v1/blobs?storage_backend=s3" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "my-s3-blob",
    "data": "SGVsbG8gU2ltcGxlIFN0b3JhZ2UgV29ybGQh"
  }'
```

### 3. List All Blobs (with pagination)
```bash
curl -X GET "http://localhost:3000/v1/blobs?page=1&per_page=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. Retrieve a Blob
```bash
curl -X GET http://localhost:3000/v1/blobs/my-blob-123 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 5. Delete a Blob
```bash
curl -X DELETE http://localhost:3000/v1/blobs/my-blob-123 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Architecture

The application follows Domain-Driven Design (DDD) principles and SOLID design patterns:

- **Domain Layer**: `Blob` and `AuthenticationToken` models
- **Infrastructure Layer**: Storage adapters implementing the Strategy pattern
- **Application Layer**: Services for business logic
- **Interface Layer**: Controllers for API endpoints

### Storage Adapter Pattern

The application uses the Strategy pattern to support multiple storage backends:

```ruby
# Abstract base class
class StorageBackend
  def store(id, data); end
  def retrieve(id); end
  def delete(id); end
  def exists?(id); end
  def size(id); end
end

# Concrete implementations
class S3StorageAdapter < StorageBackend; end
class DatabaseStorageAdapter < StorageBackend; end
class LocalFileStorageAdapter < StorageBackend; end
class FtpStorageAdapter < StorageBackend; end
```

## Development

### Running Tests
```bash
rails test
```

### Code Quality
```bash
bundle exec rubocop
bundle exec brakeman
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `STORAGE_BACKEND` | Storage backend to use | `local` |
| `LOCAL_STORAGE_PATH` | Path for local file storage | `storage/blobs` |
| `S3_ENDPOINT` | S3 endpoint URL | `https://s3.amazonaws.com` |
| `S3_BUCKET` | S3 bucket name | - |
| `S3_ACCESS_KEY` | S3 access key | - |
| `S3_SECRET_KEY` | S3 secret key | - |
| `S3_REGION` | S3 region | `us-east-2` |
| `FTP_HOST` | FTP server host | - |
| `FTP_USERNAME` | FTP username | - |
| `FTP_PASSWORD` | FTP password | - |
| `FTP_PORT` | FTP port | `21` |
| `FTP_REMOTE_PATH` | FTP remote path | `/blobs` |
| `FTP_PASSIVE` | Use passive FTP mode | `true` |

