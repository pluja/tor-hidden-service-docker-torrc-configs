# 🧅 Tor Hidden Service Docker Container

A minimal Docker image that runs Tor on Alpine Linux and allows you to easily create hidden services for your Docker containers.

## 🔍 Tech Stack

- **Alpine**: v3.21
- **Tor**: v0.4.8.14-r1

## ✨ Features

- 🏔️ Based on Alpine Linux for minimal image size
- 🧅 Automatically creates Tor hidden services for specified containers
- ⚙️ Easy configuration through environment variables or command-line arguments
- 📝 Automatically displays onion addresses in container logs
- 🔒 Security-focused with minimal dependencies
- 🔄 Automated updates via DependencyBot

## 🚀 Usage

### Basic Usage

```bash
docker run -d --name tor-hidden-service \
  -e HS_WEB=web-container:80:80 \
  ghcr.io/hundehausen/tor-hidden-service:latest
```

### Docker Compose Example

```yaml
services:
  web:
    image: nginx:alpine
    container_name: web-container
    # Your web service configuration...

  tor:
    image: ghcr.io/hundehausen/tor-hidden-service:latest
    container_name: tor-hidden-service
    environment:
      - HS_WEB=web:80:80  # Format: HS_[NAME]=[HOST]:[PORT]:[VIRTUAL_PORT]
    depends_on:
      - web
```

## ⚙️ Configuration

### Environment Variables

You can specify hidden services using environment variables in the format:

```
HS_[SERVICE_NAME]=[TARGET_HOST]:[TARGET_PORT]:[VIRTUAL_PORT]
```

Where:
- `SERVICE_NAME`: A unique name for the service (will be used for the directory name)
- `TARGET_HOST`: The hostname or container name of the service
- `TARGET_PORT`: The port the service is running on
- `VIRTUAL_PORT`: (Optional) The port that will be exposed on the .onion address. If not specified, it will use the same as TARGET_PORT.

Example:
```
HS_WEB=web-container:80:80
HS_API=api-container:8080:80
```

### Command-Line Arguments

You can also specify hidden services as command-line arguments:

```bash
docker run -d --name tor-hidden-service \
  ghcr.io/hundehausen/tor-hidden-service:latest \
  web:web-container:80:80 api:api-container:8080:80
```

## 🔍 Retrieving Onion Addresses

The onion addresses for your hidden services will be displayed in the container logs after Tor starts up:

```bash
docker logs tor-hidden-service
```

You should see output like:

```
======== TOR HIDDEN SERVICES ========
web: 2xxiyj6noereyty4xdxjg5akcop7ylnotvf4fqre57g7xuppy4tixvqd.onion
api: 7gtpkyhhhsbowew7zha6z7h7vlffqkn3nbu2f6hgin4xddq22o7yytyd.onion
====================================
```

You can also retrieve a specific onion address by executing a command in the container:
In that case 'web' is the other containers name.

```bash
docker exec tor-hidden-service cat /var/lib/tor/web/hostname
```

## 🏗️ Building the Image

```bash
docker build -t tor-hidden-service .
```

## 🔒 Security Considerations

- The container runs Tor as the `tor` user, not as root
- Hidden service private keys are stored in `/var/lib/tor/[SERVICE_NAME]/` with proper permissions
- For production use, consider mounting these directories as volumes to persist the onion addresses

## 📋 Health Checks

The container includes a health check that verifies Tor is working correctly by connecting to the Tor network every 5 minutes.

## 📦 Exposed Ports

- `9050`: Tor SOCKS proxy port

## 📄 License

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)

## 👥 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🙏 Acknowledgements

- [Tor Project](https://www.torproject.org/) for their incredible work on privacy tools
- [Alpine Linux](https://alpinelinux.org/) for providing a minimal and secure base image
